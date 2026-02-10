--[[
    AutoClickerService.luau
    Handles auto-clicker passive income for players
    Awards aura automatically based on auto-clicker level
    Applies prestige multiplier
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local ProductConfig = require(game.ReplicatedStorage.Shared.ProductConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)
local GamePassService = nil  -- Loaded after init

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
    
    local baseIncome = 0
    
    -- Check for game pass auto clicker first
    if GamePassService and GamePassService.HasAutoClickerPass(player) then
        -- Game pass auto clicker: uses click power directly
        local clickPowerLevel = data.ClickPower or 1
        local clickPowerData = GameConfig.ClickPowerUpgrades[clickPowerLevel]
        local clickPower = clickPowerData and clickPowerData.Power or 1
        local clicksPerSecond = ProductConfig.GamePasses.AutoClicker.ClicksPerSecond
        baseIncome = clickPower * clicksPerSecond
    else
        -- Regular upgrade-based auto clicker
        local autoClickerLevel = data.AutoClickerLevel or 0
        if autoClickerLevel == 0 then
            return 0
        end
        
        local autoClickerData = GameConfig.AutoClickerUpgrades[autoClickerLevel + 1]
        if not autoClickerData then
            return 0
        end
        
        baseIncome = autoClickerData.AuraPerSecond
    end
    
    -- Apply upgrade multiplier (not prestige - that's done in AddAura)
    local multiplierLevel = data.MultiplierLevel or 0
    local multiplierData = GameConfig.MultiplierUpgrades[multiplierLevel + 1]
    local upgradeMultiplier = multiplierData and multiplierData.Multiplier or 1
    
    -- Apply game pass multipliers
    local passMultiplier = 1
    if GamePassService then
        passMultiplier = GamePassService.GetPassMultiplier(player)
    end
    
    return math.floor(baseIncome * upgradeMultiplier * passMultiplier)
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
    -- Load GamePassService
    GamePassService = require(script.Parent.GamePassService)
    
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
