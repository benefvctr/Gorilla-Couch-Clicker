--[[
    UpgradeHandler.luau
    Handles upgrade purchases for players
    Click power, auto-clickers, multipliers, couch tiers, accessories
    All costs scale with prestige level
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local UpgradeHandler = {}

-- Remote events
local upgradeRemote = nil
local upgradeResponseRemote = nil
local couchUpdateRemote = nil

-- Upgrade types
local UpgradeTypes = {
    CLICK_POWER = "ClickPower",
    AUTO_CLICKER = "AutoClicker",
    MULTIPLIER = "Multiplier",
    COUCH_TIER = "CouchTier",
    ACCESSORY = "Accessory",
    PRESTIGE = "Prestige",
}

-- Get scaled cost for an upgrade
local function getScaledCost(baseCost: number, player: Player): number
    local data = PlayerDataService.GetPlayerData(player)
    local prestigeLevel = data and data.PrestigeLevel or 0
    return GameConfig.GetScaledCost(baseCost, prestigeLevel)
end

-- Purchase click power upgrade
function UpgradeHandler.PurchaseClickPower(player: Player): (boolean, string)
    local data = PlayerDataService.GetPlayerData(player)
    if not data then
        return false, "Data not loaded"
    end
    
    local currentLevel = data.ClickPower or 1
    local nextLevel = currentLevel + 1
    local nextUpgrade = GameConfig.ClickPowerUpgrades[nextLevel]
    
    if not nextUpgrade then
        return false, "Max level reached"
    end
    
    local cost = getScaledCost(nextUpgrade.BaseCost, player)
    if not PlayerDataService.SpendAura(player, cost) then
        return false, "Not enough aura"
    end
    
    PlayerDataService.UpdatePlayerData(player, "ClickPower", nextLevel)
    return true, "Upgraded to level " .. nextLevel
end

-- Purchase auto-clicker upgrade
function UpgradeHandler.PurchaseAutoClicker(player: Player): (boolean, string)
    local data = PlayerDataService.GetPlayerData(player)
    if not data then
        return false, "Data not loaded"
    end
    
    local currentLevel = data.AutoClickerLevel or 0
    local nextLevel = currentLevel + 1
    local nextUpgrade = GameConfig.AutoClickerUpgrades[nextLevel + 1]
    
    if not nextUpgrade then
        return false, "Max level reached"
    end
    
    local cost = getScaledCost(nextUpgrade.BaseCost, player)
    if not PlayerDataService.SpendAura(player, cost) then
        return false, "Not enough aura"
    end
    
    PlayerDataService.UpdatePlayerData(player, "AutoClickerLevel", nextLevel)
    return true, "Upgraded to level " .. nextLevel
end

-- Purchase multiplier upgrade
function UpgradeHandler.PurchaseMultiplier(player: Player): (boolean, string)
    local data = PlayerDataService.GetPlayerData(player)
    if not data then
        return false, "Data not loaded"
    end
    
    local currentLevel = data.MultiplierLevel or 0
    local nextLevel = currentLevel + 1
    local nextUpgrade = GameConfig.MultiplierUpgrades[nextLevel + 1]
    
    if not nextUpgrade then
        return false, "Max level reached"
    end
    
    local cost = getScaledCost(nextUpgrade.BaseCost, player)
    if not PlayerDataService.SpendAura(player, cost) then
        return false, "Not enough aura"
    end
    
    PlayerDataService.UpdatePlayerData(player, "MultiplierLevel", nextLevel)
    return true, "Upgraded to level " .. nextLevel
end

-- Purchase couch tier upgrade
function UpgradeHandler.PurchaseCouchTier(player: Player, tierNumber: number): (boolean, string)
    local data = PlayerDataService.GetPlayerData(player)
    if not data then
        return false, "Data not loaded"
    end
    
    local tierData = GameConfig.CouchTiers[tierNumber]
    if not tierData then
        return false, "Invalid tier"
    end
    
    if data.CouchTier >= tierNumber then
        return false, "Already owned"
    end
    
    -- Must purchase tiers in order
    if tierNumber > data.CouchTier + 1 then
        return false, "Must purchase previous tier first"
    end
    
    local cost = getScaledCost(tierData.BaseCost, player)
    if not PlayerDataService.SpendAura(player, cost) then
        return false, "Not enough aura"
    end
    
    PlayerDataService.UpdatePlayerData(player, "CouchTier", tierNumber)
    
    -- Notify all clients to update couch visuals
    if couchUpdateRemote then
        couchUpdateRemote:FireAllClients(player, tierNumber)
    end
    
    return true, "Unlocked " .. tierData.Name
end

-- Purchase accessory
function UpgradeHandler.PurchaseAccessory(player: Player, accessoryId: string): (boolean, string)
    local data = PlayerDataService.GetPlayerData(player)
    if not data then
        return false, "Data not loaded"
    end
    
    -- Find accessory in config
    local accessoryData = nil
    for _, acc in GameConfig.Accessories do
        if acc.Id == accessoryId then
            accessoryData = acc
            break
        end
    end
    
    if not accessoryData then
        return false, "Invalid accessory"
    end
    
    -- Check if already owned
    local ownedAccessories = data.Accessories or {}
    for _, ownedId in ownedAccessories do
        if ownedId == accessoryId then
            return false, "Already owned"
        end
    end
    
    local cost = getScaledCost(accessoryData.BaseCost, player)
    if not PlayerDataService.SpendAura(player, cost) then
        return false, "Not enough aura"
    end
    
    -- Add to owned accessories
    table.insert(ownedAccessories, accessoryId)
    PlayerDataService.UpdatePlayerData(player, "Accessories", ownedAccessories)
    return true, "Unlocked " .. accessoryData.Name
end

-- Perform prestige
function UpgradeHandler.PerformPrestige(player: Player): (boolean, string)
    local data = PlayerDataService.GetPlayerData(player)
    if not data then
        return false, "Data not loaded"
    end
    
    if not GameConfig.CanPrestige(data) then
        local requirement = GameConfig.GetPrestigeRequirement(data.PrestigeLevel)
        return false, "Need " .. requirement .. " total aura earned this prestige"
    end
    
    local success = PlayerDataService.PerformPrestige(player)
    if success then
        local newData = PlayerDataService.GetPlayerData(player)
        local newMultiplier = GameConfig.GetPrestigeMultiplier(newData.PrestigeLevel)
        return true, "Prestige " .. newData.PrestigeLevel .. "! Now earning " .. newMultiplier .. "x aura!"
    end
    
    return false, "Prestige failed"
end

-- Process upgrade request
function UpgradeHandler.ProcessUpgrade(player: Player, upgradeType: string, upgradeData: any): (boolean, string)
    local success, message
    
    if upgradeType == UpgradeTypes.CLICK_POWER then
        success, message = UpgradeHandler.PurchaseClickPower(player)
    elseif upgradeType == UpgradeTypes.AUTO_CLICKER then
        success, message = UpgradeHandler.PurchaseAutoClicker(player)
    elseif upgradeType == UpgradeTypes.MULTIPLIER then
        success, message = UpgradeHandler.PurchaseMultiplier(player)
    elseif upgradeType == UpgradeTypes.COUCH_TIER then
        success, message = UpgradeHandler.PurchaseCouchTier(player, upgradeData)
    elseif upgradeType == UpgradeTypes.ACCESSORY then
        success, message = UpgradeHandler.PurchaseAccessory(player, upgradeData)
    elseif upgradeType == UpgradeTypes.PRESTIGE then
        success, message = UpgradeHandler.PerformPrestige(player)
    else
        success, message = false, "Unknown upgrade type"
    end
    
    -- Send response to client
    if upgradeResponseRemote then
        local data = PlayerDataService.GetPlayerData(player)
        upgradeResponseRemote:FireClient(player, {
            Success = success,
            Message = message,
            PlayerData = data,
        })
    end
    
    return success, message
end

-- Initialize upgrade handling
function UpgradeHandler.Initialize()
    -- Create RemoteEvent for upgrades
    upgradeRemote = Instance.new("RemoteEvent")
    upgradeRemote.Name = "UpgradeRemote"
    upgradeRemote.Parent = ReplicatedStorage
    
    upgradeResponseRemote = Instance.new("RemoteEvent")
    upgradeResponseRemote.Name = "UpgradeResponseRemote"
    upgradeResponseRemote.Parent = ReplicatedStorage
    
    couchUpdateRemote = Instance.new("RemoteEvent")
    couchUpdateRemote.Name = "CouchUpdateRemote"
    couchUpdateRemote.Parent = ReplicatedStorage
    
    -- Listen for upgrade requests
    upgradeRemote.OnServerEvent:Connect(function(player, upgradeType, upgradeData)
        UpgradeHandler.ProcessUpgrade(player, upgradeType, upgradeData)
    end)
    
    print("[UpgradeHandler] Initialized")
end

return UpgradeHandler
