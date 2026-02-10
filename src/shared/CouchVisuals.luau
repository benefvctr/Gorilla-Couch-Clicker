--[[
    CouchVisuals.luau
    Handles visual updates for the Gorilla Couch
    Changes colors, materials, particles, and glow effects
]]

local TweenService = game:GetService("TweenService")
local GameConfig = require(script.Parent.GameConfig)

local CouchVisuals = {}

-- Rainbow colors for animated tier
local RAINBOW_COLORS = {
    Color3.fromRGB(255, 0, 0),     -- Red
    Color3.fromRGB(255, 127, 0),   -- Orange
    Color3.fromRGB(255, 255, 0),   -- Yellow
    Color3.fromRGB(0, 255, 0),     -- Green
    Color3.fromRGB(0, 0, 255),     -- Blue
    Color3.fromRGB(75, 0, 130),    -- Indigo
    Color3.fromRGB(148, 0, 211),   -- Violet
}

-- Apply a tier's visual style to a couch model
function CouchVisuals.ApplyTier(couchModel: Model, tierNumber: number)
    local tierData = GameConfig.CouchTiers[tierNumber]
    if not tierData then
        warn("Invalid tier number: " .. tostring(tierNumber))
        return
    end
    
    -- Get all parts in the couch model
    for _, part in couchModel:GetDescendants() do
        if part:IsA("BasePart") then
            -- Apply color and material
            part.Color = tierData.Color
            part.Material = tierData.Material
            
            -- Handle glow effect
            local existingLight = part:FindFirstChild("TierGlow")
            if tierData.HasGlow then
                local light = existingLight or Instance.new("PointLight")
                light.Name = "TierGlow"
                light.Color = tierData.GlowColor or tierData.Color
                light.Brightness = 2
                light.Range = 15
                light.Parent = part
            elseif existingLight then
                existingLight:Destroy()
            end
        end
    end
    
    -- Handle particles
    local primaryPart = couchModel.PrimaryPart or couchModel:FindFirstChildWhichIsA("BasePart")
    if primaryPart then
        CouchVisuals.UpdateParticles(primaryPart, tierData)
    end
end

-- Update particle effects on a part
function CouchVisuals.UpdateParticles(part: BasePart, tierData: table)
    -- Remove existing particles
    local existingParticles = part:FindFirstChild("TierParticles")
    if existingParticles then
        existingParticles:Destroy()
    end
    
    if not tierData.HasParticles then
        return
    end
    
    local attachment = Instance.new("Attachment")
    attachment.Name = "TierParticles"
    attachment.Parent = part
    
    if tierData.ParticleType == "Sparkle" then
        local sparkles = Instance.new("ParticleEmitter")
        sparkles.Name = "Sparkles"
        sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        sparkles.LightEmission = 1
        sparkles.Size = NumberSequence.new(0.2, 0)
        sparkles.Lifetime = NumberRange.new(0.5, 1)
        sparkles.Rate = 20
        sparkles.Speed = NumberRange.new(2, 5)
        sparkles.SpreadAngle = Vector2.new(180, 180)
        sparkles.Parent = attachment
        
    elseif tierData.ParticleType == "Rainbow" then
        local particles = Instance.new("ParticleEmitter")
        particles.Name = "RainbowParticles"
        particles.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255)),
        })
        particles.LightEmission = 1
        particles.Size = NumberSequence.new(0.3, 0)
        particles.Lifetime = NumberRange.new(1, 2)
        particles.Rate = 30
        particles.Speed = NumberRange.new(3, 6)
        particles.SpreadAngle = Vector2.new(180, 180)
        particles.Parent = attachment
        
    elseif tierData.ParticleType == "Cosmic" then
        -- Stars
        local stars = Instance.new("ParticleEmitter")
        stars.Name = "CosmicStars"
        stars.Color = ColorSequence.new(Color3.fromRGB(200, 150, 255))
        stars.LightEmission = 1
        stars.Size = NumberSequence.new(0.1, 0.3, 0)
        stars.Lifetime = NumberRange.new(2, 4)
        stars.Rate = 15
        stars.Speed = NumberRange.new(1, 3)
        stars.SpreadAngle = Vector2.new(180, 180)
        stars.Parent = attachment
        
        -- Nebula glow
        local nebula = Instance.new("ParticleEmitter")
        nebula.Name = "Nebula"
        nebula.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 0, 200)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 50, 150)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 100, 200)),
        })
        nebula.Transparency = NumberSequence.new(0.5, 1)
        nebula.LightEmission = 0.5
        nebula.Size = NumberSequence.new(2, 4)
        nebula.Lifetime = NumberRange.new(3, 5)
        nebula.Rate = 5
        nebula.Speed = NumberRange.new(0.5, 1)
        nebula.SpreadAngle = Vector2.new(180, 180)
        nebula.Parent = attachment
    end
end

-- Animate rainbow color cycling (call this in a loop for rainbow tier)
function CouchVisuals.AnimateRainbow(couchModel: Model)
    local colorIndex = 1
    
    while couchModel and couchModel.Parent do
        local nextIndex = (colorIndex % #RAINBOW_COLORS) + 1
        local currentColor = RAINBOW_COLORS[colorIndex]
        local nextColor = RAINBOW_COLORS[nextIndex]
        
        -- Tween all parts to next color
        for _, part in couchModel:GetDescendants() do
            if part:IsA("BasePart") then
                local tween = TweenService:Create(
                    part,
                    TweenInfo.new(0.5, Enum.EasingStyle.Linear),
                    { Color = nextColor }
                )
                tween:Play()
            end
        end
        
        colorIndex = nextIndex
        task.wait(0.5)
    end
end

-- Create click feedback effect (floating +points text, particles)
function CouchVisuals.CreateClickEffect(position: Vector3, points: number, isLucky: boolean)
    -- This will be called from client to show visual feedback
    -- Creates a billboardgui with floating text
    
    local part = Instance.new("Part")
    part.Name = "ClickEffect"
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Size = Vector3.new(1, 1, 1)
    part.Position = position + Vector3.new(0, 3, 0)
    part.Parent = workspace
    
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "+" .. tostring(points)
    label.TextColor3 = isLucky and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
    
    if isLucky then
        label.Text = "🍀 +" .. tostring(points) .. " LUCKY!"
        label.TextColor3 = Color3.fromRGB(255, 215, 0)
    end
    
    -- Animate upward and fade out
    local tween = TweenService:Create(
        part,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = part.Position + Vector3.new(0, 3, 0) }
    )
    local fadeTween = TweenService:Create(
        label,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { TextTransparency = 1, TextStrokeTransparency = 1 }
    )
    
    tween:Play()
    fadeTween:Play()
    
    task.delay(1.1, function()
        part:Destroy()
    end)
end

return CouchVisuals
