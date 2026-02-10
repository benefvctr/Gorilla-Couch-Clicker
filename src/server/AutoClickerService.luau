--[[
    AutoClickerService.luau
    Handles auto-clicker passive income for players
    Awards aura automatically based on auto-clicker level
    Applies prestige multiplier
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local AutoClickerService = {}

-- How often to award auto-click aura (in seconds)
local TICK_INTERVAL = 1

-- Reference to update remote (set during init)
local updateRemote = nil

-- Calculate auto-click income per tick (base, before prestige)
function AutoClickerService.CalculateBaseAutoIncome(player: Player): number
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
    
    local baseIncome = autoClickerData.AuraPerSecond
    
    -- Apply upgrade multiplier (not prestige - that's done in AddAura)
    local multiplierLevel = data.MultiplierLevel or 0
    local multiplierData = GameConfig.MultiplierUpgrades[multiplierLevel + 1]
    local upgradeMultiplier = multiplierData and multiplierData.Multiplier or 1
    
    return math.floor(baseIncome * upgradeMultiplier)
end

-- Process auto-click tick for all players
function AutoClickerService.ProcessTick()
    for _, player in Players:GetPlayers() do
        local baseIncome = AutoClickerService.CalculateBaseAutoIncome(player)
        if baseIncome > 0 then
            -- AddAura applies prestige multiplier
            local actualIncome = PlayerDataService.AddAura(player, baseIncome)
            
            -- Notify client of auto-income
            if updateRemote and actualIncome > 0 then
                local data = PlayerDataService.GetPlayerData(player)
                if data then
                    updateRemote:FireClient(player, {
                        Aura = data.Aura,
                        AutoIncome = actualIncome,
                        PrestigeLevel = data.PrestigeLevel,
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
