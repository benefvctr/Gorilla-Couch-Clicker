--[[
    Gorilla Couch Clicker - Client Initialization
    This script initializes all client-side controllers
]]

print("[Client] Starting Gorilla Couch Clicker...")

-- Wait for ReplicatedStorage to be ready
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
if not Shared then
    warn("[Client] ERROR: Could not find ReplicatedStorage.Shared!")
    return
end

print("[Client] Found Shared folder, loading controllers...")

-- Load controllers with error handling
local ClickController, UIController

local success1, err1 = pcall(function()
    ClickController = require(script.ClickController)
end)
if not success1 then
    warn("[Client] Failed to load ClickController: " .. tostring(err1))
    return
end
print("[Client] ClickController loaded")

local success2, err2 = pcall(function()
    UIController = require(script.UIController)
end)
if not success2 then
    warn("[Client] Failed to load UIController: " .. tostring(err2))
    return
end
print("[Client] UIController loaded")

-- Initialize controllers with error handling
local success3, err3 = pcall(function()
    ClickController.Initialize()
end)
if not success3 then
    warn("[Client] Failed to initialize ClickController: " .. tostring(err3))
end

local success4, err4 = pcall(function()
    UIController.Initialize()
end)
if not success4 then
    warn("[Client] Failed to initialize UIController: " .. tostring(err4))
end

-- Connect ClickController callbacks to UIController
ClickController.OnAuraUpdated = function(aura)
    UIController.UpdateAura(aura)
end

ClickController.OnPrestigeUpdated = function(level)
    UIController.UpdatePrestige(level)
end

ClickController.OnClickFeedback = function(aura, isLucky)
    UIController.ShowClickFeedback(aura, isLucky)
end

ClickController.OnProgressUpdated = function(playerData)
    -- Cache data in UI controller and update all stats
    UIController.CachePlayerData(playerData)
    UIController.UpdatePrestigeProgress()
    UIController.UpdateClickStats()
end

print("[Client] Gorilla Couch Clicker client initialized! 🦍🛋️")
