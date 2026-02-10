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
    Aura = 0,
    PrestigeLevel = 0,
    TotalAuraEarned = 0,
}

-- Callback for when aura updates (set by UIController)
ClickController.OnAuraUpdated = nil
ClickController.OnClickFeedback = nil
ClickController.OnPrestigeUpdated = nil

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
    local primaryPart = couchModel.PrimaryPart or couchModel:FindFirstChild("Seat")
    if primaryPart then
        local originalCFrame = primaryPart.CFrame
        
        -- Quick bounce up
        local tweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local bounceTween = TweenService:Create(primaryPart, tweenInfo, {
            CFrame = originalCFrame * CFrame.new(0, 0.3, 0)
        })
        bounceTween:Play()
        
        task.delay(0.08, function()
            local returnTween = TweenService:Create(primaryPart, tweenInfo, {
                CFrame = originalCFrame
            })
            returnTween:Play()
        end)
    end
end

-- Handle update from server
function ClickController.OnServerUpdate(data)
    if data.Aura then
        localPlayerData.Aura = data.Aura
        if ClickController.OnAuraUpdated then
            ClickController.OnAuraUpdated(data.Aura)
        end
    end
    
    if data.PrestigeLevel then
        local prestigeChanged = localPlayerData.PrestigeLevel ~= data.PrestigeLevel
        localPlayerData.PrestigeLevel = data.PrestigeLevel
        if prestigeChanged and ClickController.OnPrestigeUpdated then
            ClickController.OnPrestigeUpdated(data.PrestigeLevel)
        end
    end
    
    if data.TotalAuraEarned then
        localPlayerData.TotalAuraEarned = data.TotalAuraEarned
    end
    
    -- Click feedback (floating +aura)
    if data.ClickAura and ClickController.OnClickFeedback then
        ClickController.OnClickFeedback(data.ClickAura, data.IsLucky)
    end
end

-- Get current aura
function ClickController.GetAura(): number
    return localPlayerData.Aura
end

-- Get current prestige level
function ClickController.GetPrestigeLevel(): number
    return localPlayerData.PrestigeLevel
end

-- Get total aura earned this prestige
function ClickController.GetTotalAuraEarned(): number
    return localPlayerData.TotalAuraEarned
end

-- Set up click detection for a couch model
function ClickController.SetupCouchClickDetection(couchModel: Model)
    -- Add ClickDetector to all parts in the couch
    for _, part in couchModel:GetDescendants() do
        if part:IsA("BasePart") and part.Transparency < 1 then
            local existingDetector = part:FindFirstChild("ClickDetector")
            if not existingDetector then
                local detector = Instance.new("ClickDetector")
                detector.MaxActivationDistance = 32
                detector.CursorIcon = "rbxasset://SystemCursors/PointingHand"
                detector.Parent = part
                
                detector.MouseClick:Connect(function()
                    ClickController.OnCouchClick(couchModel)
                end)
            end
        end
    end
    
    print("[ClickController] Click detection set up for: " .. couchModel.Name)
end

-- Find and set up the player's couch
function ClickController.FindPlayerCouch()
    -- Look for a model named "GorillaCouch" in workspace
    local couch = workspace:FindFirstChild("GorillaCouch") 
        or workspace:FindFirstChild("Couch")
        or workspace:FindFirstChild("PlayerCouch")
    
    if couch and couch:IsA("Model") then
        ClickController.SetupCouchClickDetection(couch)
        return couch
    end
    
    -- If no couch found, wait for one to be added
    workspace.ChildAdded:Connect(function(child)
        if (child.Name == "GorillaCouch" or child.Name == "Couch" or child.Name == "PlayerCouch") 
            and child:IsA("Model") then
            ClickController.SetupCouchClickDetection(child)
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
