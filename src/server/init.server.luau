--[[
    Gorilla Couch Clicker - Server Initialization
    This script initializes all server-side services
]]

print("[Server] Starting Gorilla Couch Clicker...")

-- Load and initialize all services
local PlayerDataService = require(script.PlayerDataService)
local ClickHandler = require(script.ClickHandler)
local UpgradeHandler = require(script.UpgradeHandler)
local AutoClickerService = require(script.AutoClickerService)

-- Initialize in order (PlayerDataService first as others depend on it)
PlayerDataService.Initialize()
ClickHandler.Initialize()
UpgradeHandler.Initialize()
AutoClickerService.Initialize()

print("[Server] Gorilla Couch Clicker initialized successfully! 🦍🛋️")
