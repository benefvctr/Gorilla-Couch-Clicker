--[[
    Gorilla Couch Clicker - Client Initialization
    This script initializes all client-side controllers
]]

print("[Client] Starting Gorilla Couch Clicker...")

-- Load and initialize all controllers
local ClickController = require(script.ClickController)
local UIController = require(script.UIController)

-- Initialize controllers
ClickController.Initialize()
UIController.Initialize()

print("[Client] Gorilla Couch Clicker client initialized! 🦍🛋️")
