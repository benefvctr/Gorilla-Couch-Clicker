--[[
    CouchSpawner.luau
    Spawns and manages per-player Gorilla Couches
    Each player gets their own couch that only they can click
    
    SETUP: Place your custom couch model in ServerStorage named "CouchTemplate"
           Make sure it has a PrimaryPart set (the main seat/body)
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local CouchVisuals = require(game.ReplicatedStorage.Shared.CouchVisuals)

local CouchSpawner = {}

-- ⚠️ DEBUG: Set to true to SEE the click hitbox (green transparent box)
local DEBUG_SHOW_HITBOX = true  -- Change to false when done testing!

-- Store player couches
local playerCouches = {}

-- Spawn positions in a circle around center
local SPAWN_RADIUS = 25
local CENTER_POSITION = Vector3.new(0, 0, 0)

-- Template couch (loaded on init)
local couchTemplate = nil

-- Calculate bounding box of a model
local function getModelBoundingBox(model: Model): (Vector3, Vector3)
    local minPos = Vector3.new(math.huge, math.huge, math.huge)
    local maxPos = Vector3.new(-math.huge, -math.huge, -math.huge)
    
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            local halfSize = part.Size / 2
            local partMin = part.Position - halfSize
            local partMax = part.Position + halfSize
            
            minPos = Vector3.new(
                math.min(minPos.X, partMin.X),
                math.min(minPos.Y, partMin.Y),
                math.min(minPos.Z, partMin.Z)
            )
            maxPos = Vector3.new(
                math.max(maxPos.X, partMax.X),
                math.max(maxPos.Y, partMax.Y),
                math.max(maxPos.Z, partMax.Z)
            )
        end
    end
    
    local center = (minPos + maxPos) / 2
    local size = maxPos - minPos
    
    -- Add some padding
    size = size + Vector3.new(2, 2, 2)
    
    return center, size
end

-- Get spawn position for player (arranged in a circle)
local function getSpawnPosition(playerIndex: number, totalPlayers: number): Vector3
    -- Arrange in a circle, with first player at front
    local angle = (playerIndex - 1) * (2 * math.pi / math.max(totalPlayers, 8))
    local x = CENTER_POSITION.X + SPAWN_RADIUS * math.sin(angle)
    local z = CENTER_POSITION.Z + SPAWN_RADIUS * math.cos(angle)
    return Vector3.new(x, 2, z) -- Y=2 puts seat just above ground
end

-- Create a fallback couch if no template exists
local function createFallbackCouch(player: Player, position: Vector3): Model
    local couch = Instance.new("Model")
    couch.Name = player.Name .. "'s Couch"
    
    -- Store owner info
    couch:SetAttribute("OwnerId", player.UserId)
    couch:SetAttribute("OwnerName", player.Name)
    
    -- Create basic couch parts
    local seat = Instance.new("Part")
    seat.Name = "Seat"
    seat.Size = Vector3.new(8, 2, 4)
    seat.Position = position
    seat.Anchored = true
    seat.Color = Color3.fromRGB(139, 90, 43)
    seat.Material = Enum.Material.Fabric
    seat.Parent = couch
    
    local backrest = Instance.new("Part")
    backrest.Name = "Backrest"
    backrest.Size = Vector3.new(8, 4, 1)
    backrest.Position = position + Vector3.new(0, 2, -1.5)
    backrest.Anchored = true
    backrest.Color = Color3.fromRGB(139, 90, 43)
    backrest.Material = Enum.Material.Fabric
    backrest.Parent = couch
    
    local leftArm = Instance.new("Part")
    leftArm.Name = "LeftArm"
    leftArm.Size = Vector3.new(1, 3, 4)
    leftArm.Position = position + Vector3.new(-4, 1, 0)
    leftArm.Anchored = true
    leftArm.Color = Color3.fromRGB(139, 90, 43)
    leftArm.Material = Enum.Material.Fabric
    leftArm.Parent = couch
    
    local rightArm = Instance.new("Part")
    rightArm.Name = "RightArm"
    rightArm.Size = Vector3.new(1, 3, 4)
    rightArm.Position = position + Vector3.new(4, 1, 0)
    rightArm.Anchored = true
    rightArm.Color = Color3.fromRGB(139, 90, 43)
    rightArm.Material = Enum.Material.Fabric
    rightArm.Parent = couch
    
    local gorillaBody = Instance.new("Part")
    gorillaBody.Name = "GorillaBody"
    gorillaBody.Shape = Enum.PartType.Ball
    gorillaBody.Size = Vector3.new(3, 3, 3)
    gorillaBody.Position = position + Vector3.new(0, 3, 0)
    gorillaBody.Anchored = true
    gorillaBody.Color = Color3.fromRGB(90, 90, 90)
    gorillaBody.Material = Enum.Material.SmoothPlastic
    gorillaBody.Parent = couch
    
    local gorillaHead = Instance.new("Part")
    gorillaHead.Name = "GorillaHead"
    gorillaHead.Shape = Enum.PartType.Ball
    gorillaHead.Size = Vector3.new(2, 2, 2)
    gorillaHead.Position = position + Vector3.new(0, 5, 0.5)
    gorillaHead.Anchored = true
    gorillaHead.Color = Color3.fromRGB(100, 100, 100)
    gorillaBody.Material = Enum.Material.SmoothPlastic
    gorillaHead.Parent = couch
    
    couch.PrimaryPart = seat
    return couch
end

-- Create a couch model for a player (clones template or uses fallback)
local function createCouchModel(player: Player, position: Vector3): Model
    local couch
    
    -- Try to clone the template
    if couchTemplate then
        couch = couchTemplate:Clone()
        couch.Name = player.Name .. "'s Couch"
        
        -- Move couch to spawn position
        if couch.PrimaryPart then
            local offset = position - couch.PrimaryPart.Position
            for _, part in couch:GetDescendants() do
                if part:IsA("BasePart") then
                    part.Position = part.Position + offset
                end
            end
        end
        
        print("[CouchSpawner] Cloned custom CouchTemplate for " .. player.Name)
    else
        -- No template found, use fallback
        couch = createFallbackCouch(player, position)
        warn("[CouchSpawner] No CouchTemplate in ServerStorage, using fallback for " .. player.Name)
    end
    
    -- Store owner info (always set these)
    couch:SetAttribute("OwnerId", player.UserId)
    couch:SetAttribute("OwnerName", player.Name)
    
    -- Add click detection if not present
    local hasClickDetector = false
    for _, desc in couch:GetDescendants() do
        if desc:IsA("ClickDetector") then
            hasClickDetector = true
            break
        end
    end
    
    if not hasClickDetector then
        -- Calculate bounding box to auto-size the click area
        local center, size = getModelBoundingBox(couch)
        
        -- Add click part covering the entire couch
        local clickPart = Instance.new("Part")
        clickPart.Name = "ClickPart"
        clickPart.Size = size
        clickPart.Position = center
        clickPart.Anchored = true
        clickPart.CanCollide = false
        clickPart.Parent = couch
        
        -- Debug mode: show hitbox as green transparent box
        if DEBUG_SHOW_HITBOX then
            clickPart.Transparency = 0.7
            clickPart.Color = Color3.fromRGB(0, 255, 0)
            clickPart.Material = Enum.Material.Neon
            print("[CouchSpawner] DEBUG: Hitbox visible - Size:", size, "Center:", center)
        else
            clickPart.Transparency = 1
        end
        
        local clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 20
        clickDetector.Parent = clickPart
    end
    
    -- Add name tag if not present
    local hasNameTag = couch:FindFirstChild("NameTag")
    if not hasNameTag then
        local billboardPart = Instance.new("Part")
        billboardPart.Name = "NameTag"
        billboardPart.Size = Vector3.new(1, 1, 1)
        billboardPart.Position = position + Vector3.new(0, 8, 0)
        billboardPart.Anchored = true
        billboardPart.Transparency = 1
        billboardPart.CanCollide = false
        billboardPart.Parent = couch
        
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 0, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = billboardPart
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = "🦍 " .. player.Name .. "'s Couch"
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = billboard
    else
        -- Update existing name tag text
        local billboard = hasNameTag:FindFirstChildWhichIsA("BillboardGui")
        if billboard then
            local label = billboard:FindFirstChildWhichIsA("TextLabel")
            if label then
                label.Text = "🦍 " .. player.Name .. "'s Couch"
            end
        end
    end
    
    return couch
end

-- Spawn couch for a player
function CouchSpawner.SpawnCouchForPlayer(player: Player)
    -- Remove existing couch if any
    if playerCouches[player.UserId] then
        playerCouches[player.UserId]:Destroy()
    end
    
    -- Calculate position
    local playerCount = 0
    for _ in pairs(playerCouches) do
        playerCount = playerCount + 1
    end
    local position = getSpawnPosition(playerCount + 1, #Players:GetPlayers())
    
    -- Create couch
    local couch = createCouchModel(player, position)
    couch.Parent = workspace
    
    -- Store reference
    playerCouches[player.UserId] = couch
    
    print("[CouchSpawner] Spawned couch for " .. player.Name .. " at " .. tostring(position))
    
    return couch
end

-- Get a player's couch
function CouchSpawner.GetPlayerCouch(player: Player): Model?
    return playerCouches[player.UserId]
end

-- Get couch owner from a couch model
function CouchSpawner.GetCouchOwner(couch: Model): Player?
    local ownerId = couch:GetAttribute("OwnerId")
    if ownerId then
        return Players:GetPlayerByUserId(ownerId)
    end
    return nil
end

-- Check if a player owns a couch
function CouchSpawner.IsOwner(player: Player, couch: Model): boolean
    local ownerId = couch:GetAttribute("OwnerId")
    return ownerId == player.UserId
end

-- Remove couch when player leaves
function CouchSpawner.RemovePlayerCouch(player: Player)
    local couch = playerCouches[player.UserId]
    if couch then
        couch:Destroy()
        playerCouches[player.UserId] = nil
        print("[CouchSpawner] Removed couch for " .. player.Name)
    end
end

-- Update couch visuals for a player (when they buy tiers)
function CouchSpawner.UpdateCouchTier(player: Player, tierNumber: number)
    local couch = playerCouches[player.UserId]
    if couch then
        CouchVisuals.ApplyTier(couch, tierNumber)
        print("[CouchSpawner] Updated " .. player.Name .. "'s couch to tier " .. tierNumber)
    end
end

-- Rearrange all couches (when players join/leave)
local function rearrangeCouches()
    local players = Players:GetPlayers()
    local index = 1
    
    for userId, couch in pairs(playerCouches) do
        local player = Players:GetPlayerByUserId(userId)
        if player and couch and couch.Parent then
            local position = getSpawnPosition(index, #players)
            
            -- Move all parts relative to new position
            local primaryPart = couch.PrimaryPart
            if primaryPart then
                local offset = position - primaryPart.Position
                for _, part in couch:GetDescendants() do
                    if part:IsA("BasePart") then
                        part.Position = part.Position + offset
                    end
                end
            end
            
            index = index + 1
        end
    end
end

-- Initialize spawner
function CouchSpawner.Initialize()
    -- Try to load custom couch template from ServerStorage
    couchTemplate = ServerStorage:FindFirstChild("CouchTemplate")
    
    if couchTemplate then
        print("[CouchSpawner] Found CouchTemplate in ServerStorage ✓")
    else
        warn("[CouchSpawner] No CouchTemplate in ServerStorage - using fallback couch")
        warn("[CouchSpawner] To use your own model: put it in ServerStorage and name it 'CouchTemplate'")
    end
    
    -- Spawn couch for existing players
    for _, player in Players:GetPlayers() do
        CouchSpawner.SpawnCouchForPlayer(player)
    end
    
    -- Spawn couch when new players join
    Players.PlayerAdded:Connect(function(player)
        -- Wait for character to load
        player.CharacterAdded:Wait()
        task.wait(1) -- Small delay to ensure everything is ready
        
        CouchSpawner.SpawnCouchForPlayer(player)
        rearrangeCouches()
    end)
    
    -- Remove couch when player leaves
    Players.PlayerRemoving:Connect(function(player)
        CouchSpawner.RemovePlayerCouch(player)
        task.wait(0.1)
        rearrangeCouches()
    end)
    
    print("[CouchSpawner] Initialized")
end

return CouchSpawner
