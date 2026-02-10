--[[
    ClickHandler.luau
    Handles click events from players
    Calculates points based on upgrades and multipliers
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local ClickHandler = {}

-- Track last click time per player (anti-exploit)
local lastClickTime = {}

-- Remote event for clicks (created on init)
local clickRemote = nil
local updateRemote = nil

-- Calculate points for a click
function ClickHandler.CalculateClickPoints(player: Player): (number, boolean)
    local data = PlayerDataService.GetPlayerData(player)
    if not data then
        return 0, false
    end
    
    -- Get click power from upgrades
    local clickPowerLevel = data.ClickPower or 1
    local clickPowerData = GameConfig.ClickPowerUpgrades[clickPowerLevel]
    local basePoints = clickPowerData and clickPowerData.Power or 1
    
    -- Get multiplier from upgrades
    local multiplierLevel = data.MultiplierLevel or 0
    local multiplierData = GameConfig.MultiplierUpgrades[multiplierLevel + 1]
    local multiplier = multiplierData and multiplierData.Multiplier or 1
    
    -- Check for lucky click
    local isLucky = math.random() < GameConfig.LuckyClickChance
    if isLucky then
        multiplier = multiplier * GameConfig.LuckyClickMultiplier
    end
    
    local totalPoints = math.floor(basePoints * multiplier)
    
    return totalPoints, isLucky
end

-- Process a click from a player
function ClickHandler.ProcessClick(player: Player): (number, boolean)?
    -- Anti-exploit: check click cooldown
    local currentTime = tick()
    local lastTime = lastClickTime[player.UserId] or 0
    
    if currentTime - lastTime < GameConfig.ClickCooldown then
        return nil -- Too fast, ignore
    end
    lastClickTime[player.UserId] = currentTime
    
    -- Calculate and award points
    local points, isLucky = ClickHandler.CalculateClickPoints(player)
    
    if points > 0 then
        PlayerDataService.AddPoints(player, points)
        PlayerDataService.IncrementClicks(player)
        
        -- Send updated data to client
        local data = PlayerDataService.GetPlayerData(player)
        if data and updateRemote then
            updateRemote:FireClient(player, {
                Points = data.Points,
                ClickPoints = points,
                IsLucky = isLucky,
            })
        end
    end
    
    return points, isLucky
end

-- Initialize click handling
function ClickHandler.Initialize()
    -- Create RemoteEvent for client-server communication
    clickRemote = Instance.new("RemoteEvent")
    clickRemote.Name = "ClickRemote"
    clickRemote.Parent = ReplicatedStorage
    
    updateRemote = Instance.new("RemoteEvent")
    updateRemote.Name = "UpdateRemote"
    updateRemote.Parent = ReplicatedStorage
    
    -- Listen for clicks from clients
    clickRemote.OnServerEvent:Connect(function(player)
        ClickHandler.ProcessClick(player)
    end)
    
    -- Clean up when player leaves
    Players.PlayerRemoving:Connect(function(player)
        lastClickTime[player.UserId] = nil
    end)
    
    print("[ClickHandler] Initialized")
end

return ClickHandler
