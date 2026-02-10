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
    ClickPower = 1,
    MultiplierLevel = 0,
    AutoClickerLevel = 0,
    CouchTier = 1,
}

-- Callback for when aura updates (set by UIController)
ClickController.OnAuraUpdated = nil
ClickController.OnClickFeedback = nil
ClickController.OnPrestigeUpdated = nil
ClickController.OnRejection = nil  -- Called when click is rejected (not your couch)

-- Send click to server with the clicked part for ownership validation
function ClickController.SendClick(clickedPart: BasePart?)
    if clickRemote then
        clickRemote:FireServer(clickedPart)
    end
end

-- Handle click on the couch
function ClickController.OnCouchClick(couchModel: Model, clickedPart: BasePart?)
    -- Use primary part if no specific part provided
    local partToSend = clickedPart or couchModel.PrimaryPart or couchModel:FindFirstChild("Seat")
    ClickController.SendClick(partToSend)
    
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
    
    -- Cache upgrade stats for UI display
    if data.ClickPower then
        localPlayerData.ClickPower = data.ClickPower
    end
    if data.MultiplierLevel then
        localPlayerData.MultiplierLevel = data.MultiplierLevel
    end
    if data.AutoClickerLevel then
        localPlayerData.AutoClickerLevel = data.AutoClickerLevel
    end
    if data.CouchTier then
        localPlayerData.CouchTier = data.CouchTier
    end
    
    if data.TotalAuraEarned then
        localPlayerData.TotalAuraEarned = data.TotalAuraEarned
    end
    
    -- Notify UI to update all stats
    if ClickController.OnProgressUpdated then
        ClickController.OnProgressUpdated(localPlayerData)
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
    -- Check for existing ClickDetector (server may have added one)
    local existingClickPart = couchModel:FindFirstChild("ClickPart")
    if existingClickPart then
        local detector = existingClickPart:FindFirstChild("ClickDetector")
        if detector then
            detector.MouseClick:Connect(function()
                ClickController.OnCouchClick(couchModel, existingClickPart)
            end)
            print("[ClickController] Connected to existing ClickDetector for: " .. couchModel.Name)
            return
        end
    end
    
    -- Add ClickDetector to all visible parts in the couch
    for _, part in couchModel:GetDescendants() do
        if part:IsA("BasePart") and part.Transparency < 1 then
            local existingDetector = part:FindFirstChild("ClickDetector")
            if not existingDetector then
                local detector = Instance.new("ClickDetector")
                detector.MaxActivationDistance = 32
                detector.CursorIcon = "rbxasset://SystemCursors/PointingHand"
                detector.Parent = part
                
                detector.MouseClick:Connect(function()
                    ClickController.OnCouchClick(couchModel, part)
                end)
            else
                existingDetector.MouseClick:Connect(function()
                    ClickController.OnCouchClick(couchModel, part)
                end)
            end
        end
    end
    
    print("[ClickController] Click detection set up for: " .. couchModel.Name)
end

-- Check if a model is a couch (has OwnerId attribute)
local function isCouch(model: Model): boolean
    return model:GetAttribute("OwnerId") ~= nil
end

-- Find and set up click detection for all couches
function ClickController.FindPlayerCouch()
    -- Set up existing couches
    for _, child in workspace:GetChildren() do
        if child:IsA("Model") and isCouch(child) then
            ClickController.SetupCouchClickDetection(child)
        end
    end
    
    -- Watch for new couches being added (when players join)
    workspace.ChildAdded:Connect(function(child)
        if child:IsA("Model") and isCouch(child) then
            -- Small delay to ensure model is fully loaded
            task.wait(0.1)
            ClickController.SetupCouchClickDetection(child)
        end
    end)
    
    return nil
end

-- Update couch visuals when tier changes (for a specific player's couch)
function ClickController.UpdateCouchVisuals(ownerPlayer: Player?, tierNumber: number)
    -- Find the couch belonging to the owner
    for _, child in workspace:GetChildren() do
        if child:IsA("Model") and child:GetAttribute("OwnerId") then
            local ownerId = child:GetAttribute("OwnerId")
            -- If no owner specified, update local player's couch
            local targetId = ownerPlayer and ownerPlayer.UserId or player.UserId
            if ownerId == targetId then
                CouchVisuals.ApplyTier(child, tierNumber)
                print("[ClickController] Updated couch to tier " .. tierNumber)
                return
            end
        end
    end
end

-- Initialize click controller
function ClickController.Initialize()
    -- Wait for remotes
    clickRemote = ReplicatedStorage:WaitForChild("ClickRemote", 10)
    updateRemote = ReplicatedStorage:WaitForChild("UpdateRemote", 10)
    local couchUpdateRemote = ReplicatedStorage:WaitForChild("CouchUpdateRemote", 10)
    local rejectRemote = ReplicatedStorage:WaitForChild("ClickRejectRemote", 10)
    
    if not clickRemote or not updateRemote then
        warn("[ClickController] Failed to find remote events!")
        return
    end
    
    -- Listen for updates from server
    updateRemote.OnClientEvent:Connect(function(data)
        ClickController.OnServerUpdate(data)
    end)
    
    -- Listen for click rejection messages
    if rejectRemote then
        rejectRemote.OnClientEvent:Connect(function(message)
            if ClickController.OnRejection then
                ClickController.OnRejection(message)
            end
        end)
    end
    
    -- Listen for couch tier updates
    if couchUpdateRemote then
        couchUpdateRemote.OnClientEvent:Connect(function(player, tierNumber)
            ClickController.UpdateCouchVisuals(tierNumber)
        end)
    end
    
    -- Set up couch click detection
    task.spawn(function()
        -- Wait a moment for workspace to load
        task.wait(1)
        ClickController.FindPlayerCouch()
    end)
    
    print("[ClickController] Initialized")
end

return ClickController
