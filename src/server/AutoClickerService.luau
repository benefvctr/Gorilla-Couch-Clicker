--[[
    AutoClickerService.luau
    Handles auto-clicker passive income for players
    Awards points automatically based on auto-clicker level
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local AutoClickerService = {}

-- How often to award auto-click points (in seconds)
local TICK_INTERVAL = 1

-- Reference to update remote (set during init)
local updateRemote = nil

-- Calculate auto-click income per tick
function AutoClickerService.CalculateAutoIncome(player: Player): number
    local data = PlayerDataService.GetPlayerData(player)
    if not data then
        return 0
    end
    
    local autoClickerLevel = data.AutoClickerLevel or 0
    if autoClickerLevel == 0 then
        return 0
    end
    
    local autoClickerData = GameConfig.AutoClickerUpgrades[autoClickerLevel + 1]
    if not autoClickerData then
        return 0
    end
    
    local baseIncome = autoClickerData.PointsPerSecond
    
    -- Apply multiplier
    local multiplierLevel = data.MultiplierLevel or 0
    local multiplierData = GameConfig.MultiplierUpgrades[multiplierLevel + 1]
    local multiplier = multiplierData and multiplierData.Multiplier or 1
    
    return math.floor(baseIncome * multiplier)
end

-- Process auto-click tick for all players
function AutoClickerService.ProcessTick()
    for _, player in Players:GetPlayers() do
        local income = AutoClickerService.CalculateAutoIncome(player)
        if income > 0 then
            PlayerDataService.AddPoints(player, income)
            
            -- Notify client of auto-income
            if updateRemote then
                local data = PlayerDataService.GetPlayerData(player)
                if data then
                    updateRemote:FireClient(player, {
                        Points = data.Points,
                        AutoIncome = income,
                    })
                end
            end
        end
    end
end

-- Initialize auto-clicker service
function AutoClickerService.Initialize()
    -- Get reference to update remote (created by ClickHandler)
    task.spawn(function()
        updateRemote = ReplicatedStorage:WaitForChild("UpdateRemote", 10)
    end)
    
    -- Start tick loop
    task.spawn(function()
        while true do
            task.wait(TICK_INTERVAL)
            AutoClickerService.ProcessTick()
        end
    end)
    
    print("[AutoClickerService] Initialized")
end

return AutoClickerService
