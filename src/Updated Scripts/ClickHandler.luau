--[[
    ClickHandler.luau
    Handles click events from players
    Calculates aura based on upgrades, multipliers, and prestige
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)
local GamePassService = nil  -- Loaded after init to avoid circular dependency

local ClickHandler = {}

-- Track last click time per player (anti-exploit)
local lastClickTime = {}

-- Remote event for clicks (created on init)
local clickRemote = nil
local updateRemote = nil

-- Calculate aura for a click (before prestige multiplier)
function ClickHandler.CalculateBaseClickAura(player: Player): (number, boolean)
    local data = PlayerDataService.GetPlayerData(player)
    if not data then
        return 0, false
    end
    
    -- Get click power from upgrades
    local clickPowerLevel = data.ClickPower or 1
    local clickPowerData = GameConfig.ClickPowerUpgrades[clickPowerLevel]
    local baseAura = clickPowerData and clickPowerData.Power or 1
    
    -- Get multiplier from upgrades
    local multiplierLevel = data.MultiplierLevel or 0
    local multiplierData = GameConfig.MultiplierUpgrades[multiplierLevel + 1]
    local upgradeMultiplier = multiplierData and multiplierData.Multiplier or 1
    
    -- Apply game pass multipliers (2x Aura, VIP, Temp Boosts)
    local passMultiplier = 1
    if GamePassService then
        passMultiplier = GamePassService.GetPassMultiplier(player)
    end
    
    -- Check for lucky click (game pass can boost this)
    local luckyChance = GameConfig.LuckyClickChance
    if GamePassService then
        luckyChance = GamePassService.GetLuckyChance(player)
    end
    local isLucky = math.random() < luckyChance
    local luckyMultiplier = isLucky and GameConfig.LuckyClickMultiplier or 1
    
    -- Calculate base (before prestige multiplier, which is applied in AddAura)
    local totalBase = math.floor(baseAura * upgradeMultiplier * passMultiplier * luckyMultiplier)
    
    return totalBase, isLucky
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
    
    -- Calculate base aura (prestige multiplier applied in AddAura)
    local baseAura, isLucky = ClickHandler.CalculateBaseClickAura(player)
    
    if baseAura > 0 then
        -- AddAura applies prestige multiplier and returns actual amount
        local actualAura = PlayerDataService.AddAura(player, baseAura)
        PlayerDataService.IncrementClicks(player)
        
        -- Send updated data to client
        local data = PlayerDataService.GetPlayerData(player)
        if data and updateRemote then
            updateRemote:FireClient(player, {
                Aura = data.Aura,
                ClickAura = actualAura,
                IsLucky = isLucky,
                PrestigeLevel = data.PrestigeLevel,
                TotalAuraEarned = data.TotalAuraEarned,
            })
        end
        
        return actualAura, isLucky
    end
    
    return 0, false
end

-- Initialize click handling
function ClickHandler.Initialize()
    -- Load GamePassService (delayed to avoid circular deps)
    GamePassService = require(script.Parent.GamePassService)
    
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
