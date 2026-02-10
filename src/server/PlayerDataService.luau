--[[
    PlayerDataService.luau
    Handles saving and loading player data using Roblox DataStoreService
    Manages player sessions and auto-saving
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)

local PlayerDataService = {}

-- Data store reference
local DATA_STORE_NAME = "GorillaCouchClicker_v2"  -- v2 for Aura update
local playerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)

-- Cache of active player data (in-memory)
local playerDataCache = {}

-- Session lock to prevent data duplication
local sessionLocks = {}

-- Get a player's data key
local function getDataKey(player: Player): string
    return "Player_" .. player.UserId
end

-- Deep copy a table
local function deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Load player data from DataStore
function PlayerDataService.LoadPlayerData(player: Player): table
    local dataKey = getDataKey(player)
    local success, data = pcall(function()
        return playerDataStore:GetAsync(dataKey)
    end)
    
    if success then
        if data then
            -- Merge with defaults (in case we added new fields)
            local mergedData = deepCopy(GameConfig.DefaultPlayerData)
            for key, value in pairs(data) do
                mergedData[key] = value
            end
            
            -- Migration: Convert old Points to Aura if needed
            if data.Points and not data.Aura then
                mergedData.Aura = data.Points
                mergedData.TotalAuraEarned = data.TotalPointsEarned or 0
            end
            
            playerDataCache[player.UserId] = mergedData
            print("[PlayerData] Loaded data for " .. player.Name .. " (Prestige: " .. mergedData.PrestigeLevel .. ")")
            return mergedData
        else
            -- New player, use defaults
            playerDataCache[player.UserId] = deepCopy(GameConfig.DefaultPlayerData)
            print("[PlayerData] Created new data for " .. player.Name)
            return playerDataCache[player.UserId]
        end
    else
        warn("[PlayerData] Failed to load data for " .. player.Name .. ": " .. tostring(data))
        -- Return defaults but don't cache (so we don't overwrite real data)
        return deepCopy(GameConfig.DefaultPlayerData)
    end
end

-- Save player data to DataStore
function PlayerDataService.SavePlayerData(player: Player): boolean
    local data = playerDataCache[player.UserId]
    if not data then
        warn("[PlayerData] No cached data for " .. player.Name)
        return false
    end
    
    local dataKey = getDataKey(player)
    local success, err = pcall(function()
        playerDataStore:SetAsync(dataKey, data)
    end)
    
    if success then
        print("[PlayerData] Saved data for " .. player.Name)
        return true
    else
        warn("[PlayerData] Failed to save data for " .. player.Name .. ": " .. tostring(err))
        return false
    end
end

-- Get cached player data (fast, no DataStore call)
function PlayerDataService.GetPlayerData(player: Player): table?
    return playerDataCache[player.UserId]
end

-- Update a specific field in player data
function PlayerDataService.UpdatePlayerData(player: Player, key: string, value: any)
    local data = playerDataCache[player.UserId]
    if data then
        data[key] = value
    end
end

-- Add aura to a player (applies prestige multiplier automatically)
function PlayerDataService.AddAura(player: Player, baseAmount: number): number
    local data = playerDataCache[player.UserId]
    if not data then return 0 end
    
    -- Apply prestige multiplier
    local prestigeMultiplier = GameConfig.GetPrestigeMultiplier(data.PrestigeLevel)
    local actualAmount = math.floor(baseAmount * prestigeMultiplier)
    
    data.Aura = data.Aura + actualAmount
    data.TotalAuraEarned = data.TotalAuraEarned + actualAmount
    data.LifetimeAura = data.LifetimeAura + actualAmount
    
    return actualAmount
end

-- Spend aura (returns true if successful, false if not enough)
function PlayerDataService.SpendAura(player: Player, amount: number): boolean
    local data = playerDataCache[player.UserId]
    if data and data.Aura >= amount then
        data.Aura = data.Aura - amount
        return true
    end
    return false
end

-- Get current aura
function PlayerDataService.GetAura(player: Player): number
    local data = playerDataCache[player.UserId]
    return data and data.Aura or 0
end

-- Increment click counter
function PlayerDataService.IncrementClicks(player: Player)
    local data = playerDataCache[player.UserId]
    if data then
        data.TotalClicks = data.TotalClicks + 1
    end
end

-- Perform prestige reset
function PlayerDataService.PerformPrestige(player: Player): boolean
    local data = playerDataCache[player.UserId]
    if not data then return false end
    
    -- Check if can prestige
    if not GameConfig.CanPrestige(data) then
        return false
    end
    
    -- Store what to keep
    local keptAccessories = GameConfig.Prestige.KeepAccessories and data.Accessories or {}
    local keptCouchTier = GameConfig.Prestige.KeepCouchTier and data.CouchTier or 1
    
    -- Increment prestige
    local newPrestigeLevel = data.PrestigeLevel + 1
    local totalPrestiges = data.TotalPrestiges + 1
    local lifetimeAura = data.LifetimeAura
    local totalClicks = data.TotalClicks
    
    -- Reset to defaults
    local freshData = deepCopy(GameConfig.DefaultPlayerData)
    
    -- Restore persistent data
    freshData.PrestigeLevel = newPrestigeLevel
    freshData.TotalPrestiges = totalPrestiges
    freshData.LifetimeAura = lifetimeAura
    freshData.TotalClicks = totalClicks
    freshData.Accessories = keptAccessories
    freshData.CouchTier = keptCouchTier
    
    -- Update cache
    playerDataCache[player.UserId] = freshData
    
    print("[PlayerData] " .. player.Name .. " prestiged to level " .. newPrestigeLevel)
    return true
end

-- Initialize the service
function PlayerDataService.Initialize()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        PlayerDataService.LoadPlayerData(player)
    end)
    
    -- Handle player leaving (save data)
    Players.PlayerRemoving:Connect(function(player)
        PlayerDataService.SavePlayerData(player)
        playerDataCache[player.UserId] = nil
    end)
    
    -- Handle server shutdown (save all players)
    game:BindToClose(function()
        print("[PlayerData] Server shutting down, saving all player data...")
        for _, player in Players:GetPlayers() do
            PlayerDataService.SavePlayerData(player)
        end
    end)
    
    -- Auto-save loop
    task.spawn(function()
        while true do
            task.wait(GameConfig.AutoSaveInterval)
            for _, player in Players:GetPlayers() do
                PlayerDataService.SavePlayerData(player)
            end
        end
    end)
    
    -- Load data for any players already in game (for Studio testing)
    for _, player in Players:GetPlayers() do
        PlayerDataService.LoadPlayerData(player)
    end
    
    print("[PlayerDataService] Initialized")
end

return PlayerDataService
