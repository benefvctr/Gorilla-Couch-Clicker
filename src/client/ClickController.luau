--[[
    ClickController.luau
    Handles click detection and sends click events to server
    Also handles visual feedback for clicks
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local CouchVisuals = require(game.ReplicatedStorage.Shared.CouchVisuals)

local ClickController = {}

local player = Players.LocalPlayer
local clickRemote = nil
local updateRemote = nil

-- Current player data (cached locally)
local localPlayerData = {
    Points = 0,
}

-- Callback for when points update (set by UIController)
ClickController.OnPointsUpdated = nil
ClickController.OnClickFeedback = nil

-- Send click to server
function ClickController.SendClick()
    if clickRemote then
        clickRemote:FireServer()
    end
end

-- Handle click on the couch
function ClickController.OnCouchClick(couchModel: Model)
    ClickController.SendClick()
    
    -- Visual feedback (bounce effect on couch)
    if couchModel and couchModel.PrimaryPart then
        local part = couchModel.PrimaryPart
        local originalSize = part.Size
        local originalPosition = part.Position
        
        -- Quick scale up and down
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local scaleTween = TweenService:Create(part, tweenInfo, {
            Size = originalSize * 1.05,
        })
        scaleTween:Play()
        
        task.delay(0.1, function()
            local returnTween = TweenService:Create(part, tweenInfo, {
                Size = originalSize,
            })
            returnTween:Play()
        end)
    end
end

-- Handle update from server
function ClickController.OnServerUpdate(data)
    if data.Points then
        localPlayerData.Points = data.Points
        if ClickController.OnPointsUpdated then
            ClickController.OnPointsUpdated(data.Points)
        end
    end
    
    -- Click feedback (floating +points)
    if data.ClickPoints and ClickController.OnClickFeedback then
        ClickController.OnClickFeedback(data.ClickPoints, data.IsLucky)
    end
    
    -- Auto-income feedback
    if data.AutoIncome and data.AutoIncome > 0 then
        if ClickController.OnPointsUpdated then
            ClickController.OnPointsUpdated(data.Points)
        end
    end
end

-- Get current points
function ClickController.GetPoints(): number
    return localPlayerData.Points
end

-- Set up click detection for a couch model
function ClickController.SetupCouchClickDetection(couchModel: Model)
    -- Add ClickDetector to all parts in the couch
    for _, part in couchModel:GetDescendants() do
        if part:IsA("BasePart") then
            local existingDetector = part:FindFirstChild("ClickDetector")
            if not existingDetector then
                local detector = Instance.new("ClickDetector")
                detector.MaxActivationDistance = 20
                detector.Parent = part
                
                detector.MouseClick:Connect(function()
                    ClickController.OnCouchClick(couchModel)
                end)
            end
        end
    end
end

-- Find and set up the player's couch
function ClickController.FindPlayerCouch()
    -- Look for a model named "Couch" or "GorillaCouuch" in workspace
    local couch = workspace:FindFirstChild("Couch") 
        or workspace:FindFirstChild("GorillaCouch")
        or workspace:FindFirstChild("PlayerCouch")
    
    if couch and couch:IsA("Model") then
        ClickController.SetupCouchClickDetection(couch)
        print("[ClickController] Found and set up couch: " .. couch.Name)
        return couch
    end
    
    -- If no couch found, wait for one to be added
    workspace.ChildAdded:Connect(function(child)
        if (child.Name == "Couch" or child.Name == "GorillaCouch" or child.Name == "PlayerCouch") 
            and child:IsA("Model") then
            ClickController.SetupCouchClickDetection(child)
            print("[ClickController] Couch added and set up: " .. child.Name)
        end
    end)
    
    return nil
end

-- Initialize click controller
function ClickController.Initialize()
    -- Wait for remotes
    clickRemote = ReplicatedStorage:WaitForChild("ClickRemote", 10)
    updateRemote = ReplicatedStorage:WaitForChild("UpdateRemote", 10)
    
    if not clickRemote or not updateRemote then
        warn("[ClickController] Failed to find remote events!")
        return
    end
    
    -- Listen for updates from server
    updateRemote.OnClientEvent:Connect(function(data)
        ClickController.OnServerUpdate(data)
    end)
    
    -- Set up couch click detection
    task.spawn(function()
        -- Wait a moment for workspace to load
        task.wait(1)
        ClickController.FindPlayerCouch()
    end)
    
    print("[ClickController] Initialized")
end

return ClickController
