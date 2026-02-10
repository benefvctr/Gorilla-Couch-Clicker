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
local DATA_STORE_NAME = "GorillaCouchClicker_v1"
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
            playerDataCache[player.UserId] = mergedData
            print("[PlayerData] Loaded data for " .. player.Name)
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

-- Add points to a player
function PlayerDataService.AddPoints(player: Player, amount: number)
    local data = playerDataCache[player.UserId]
    if data then
        data.Points = data.Points + amount
        data.TotalPointsEarned = data.TotalPointsEarned + amount
    end
end

-- Spend points (returns true if successful, false if not enough)
function PlayerDataService.SpendPoints(player: Player, amount: number): boolean
    local data = playerDataCache[player.UserId]
    if data and data.Points >= amount then
        data.Points = data.Points - amount
        return true
    end
    return false
end

-- Get current points
function PlayerDataService.GetPoints(player: Player): number
    local data = playerDataCache[player.UserId]
    return data and data.Points or 0
end

-- Increment click counter
function PlayerDataService.IncrementClicks(player: Player)
    local data = playerDataCache[player.UserId]
    if data then
        data.TotalClicks = data.TotalClicks + 1
    end
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
