--[[
    UpgradeHandler.luau
    Handles upgrade purchases for players
    Click power, auto-clickers, multipliers, couch tiers, accessories
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local UpgradeHandler = {}

-- Remote events
local upgradeRemote = nil
local upgradeResponseRemote = nil

-- Upgrade types
local UpgradeTypes = {
    CLICK_POWER = "ClickPower",
    AUTO_CLICKER = "AutoClicker",
    MULTIPLIER = "Multiplier",
    COUCH_TIER = "CouchTier",
    ACCESSORY = "Accessory",
}

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
    
    if not PlayerDataService.SpendPoints(player, nextUpgrade.Cost) then
        return false, "Not enough points"
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
    
    if not PlayerDataService.SpendPoints(player, nextUpgrade.Cost) then
        return false, "Not enough points"
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
    
    if not PlayerDataService.SpendPoints(player, nextUpgrade.Cost) then
        return false, "Not enough points"
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
    
    if not PlayerDataService.SpendPoints(player, tierData.Cost) then
        return false, "Not enough points"
    end
    
    PlayerDataService.UpdatePlayerData(player, "CouchTier", tierNumber)
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
    
    if not PlayerDataService.SpendPoints(player, accessoryData.Cost) then
        return false, "Not enough points"
    end
    
    -- Add to owned accessories
    table.insert(ownedAccessories, accessoryId)
    PlayerDataService.UpdatePlayerData(player, "Accessories", ownedAccessories)
    return true, "Unlocked " .. accessoryData.Name
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
    
    -- Listen for upgrade requests
    upgradeRemote.OnServerEvent:Connect(function(player, upgradeType, upgradeData)
        UpgradeHandler.ProcessUpgrade(player, upgradeType, upgradeData)
    end)
    
    print("[UpgradeHandler] Initialized")
end

return UpgradeHandler
