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
local GamePassService = require(script.GamePassService)
local VendorHandler = require(script.VendorHandler)
local CouchSpawner = require(script.CouchSpawner)

-- Initialize in order (PlayerDataService first as others depend on it)
PlayerDataService.Initialize()
GamePassService.Initialize()  -- Before handlers that use it
ClickHandler.Initialize()
UpgradeHandler.Initialize()
AutoClickerService.Initialize()
VendorHandler.Initialize()
CouchSpawner.Initialize()  -- Spawns couches for players

print("[Server] Gorilla Couch Clicker initialized successfully! 🦍🛋️")
