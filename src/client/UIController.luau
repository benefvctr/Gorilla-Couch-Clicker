--[[
    UIController.luau
    Manages all UI elements for the clicker game
    Aura display, prestige info, upgrade shop, notifications
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local ClickController = require(script.Parent.ClickController)

local UIController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI References
local mainGui = nil
local auraLabel = nil
local prestigeLabel = nil
local prestigeMultLabel = nil
local clickFeedbackContainer = nil
local shopFrame = nil

-- Remote events
local upgradeRemote = nil
local upgradeResponseRemote = nil

-- Current cached player data for UI
local cachedPlayerData = nil

-- Format large numbers with abbreviations
function UIController.FormatNumber(num: number): string
    if num >= 1000000000000 then
        return string.format("%.2fT", num / 1000000000000)
    elseif num >= 1000000000 then
        return string.format("%.2fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.2fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.2fK", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

-- Create the main UI
function UIController.CreateUI()
    -- Main ScreenGui
    mainGui = Instance.new("ScreenGui")
    mainGui.Name = "GorillaClickerUI"
    mainGui.ResetOnSpawn = false
    mainGui.Parent = playerGui
    
    -- Aura Display (top center)
    local auraFrame = Instance.new("Frame")
    auraFrame.Name = "AuraFrame"
    auraFrame.Size = UDim2.new(0, 320, 0, 100)
    auraFrame.Position = UDim2.new(0.5, -160, 0, 20)
    auraFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 30)
    auraFrame.BorderSizePixel = 0
    auraFrame.Parent = mainGui
    
    local auraCorner = Instance.new("UICorner")
    auraCorner.CornerRadius = UDim.new(0, 16)
    auraCorner.Parent = auraFrame
    
    local auraStroke = Instance.new("UIStroke")
    auraStroke.Color = Color3.fromRGB(150, 100, 255)
    auraStroke.Thickness = 3
    auraStroke.Parent = auraFrame
    
    local auraGradient = Instance.new("UIGradient")
    auraGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 10, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 20, 60)),
    })
    auraGradient.Rotation = 90
    auraGradient.Parent = auraFrame
    
    local auraTitle = Instance.new("TextLabel")
    auraTitle.Name = "AuraTitle"
    auraTitle.Size = UDim2.new(1, 0, 0, 25)
    auraTitle.Position = UDim2.new(0, 0, 0, 5)
    auraTitle.BackgroundTransparency = 1
    auraTitle.Text = "✨ AURA ✨"
    auraTitle.TextColor3 = Color3.fromRGB(200, 150, 255)
    auraTitle.TextSize = 16
    auraTitle.Font = Enum.Font.GothamBold
    auraTitle.Parent = auraFrame
    
    auraLabel = Instance.new("TextLabel")
    auraLabel.Name = "AuraLabel"
    auraLabel.Size = UDim2.new(1, -20, 0, 45)
    auraLabel.Position = UDim2.new(0, 10, 0, 28)
    auraLabel.BackgroundTransparency = 1
    auraLabel.Text = "0"
    auraLabel.TextColor3 = Color3.fromRGB(255, 200, 255)
    auraLabel.TextScaled = true
    auraLabel.Font = Enum.Font.GothamBold
    auraLabel.Parent = auraFrame
    
    -- Prestige info row
    prestigeLabel = Instance.new("TextLabel")
    prestigeLabel.Name = "PrestigeLabel"
    prestigeLabel.Size = UDim2.new(0.5, -5, 0, 20)
    prestigeLabel.Position = UDim2.new(0, 10, 1, -25)
    prestigeLabel.BackgroundTransparency = 1
    prestigeLabel.Text = "⭐ Prestige: 0"
    prestigeLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
    prestigeLabel.TextSize = 12
    prestigeLabel.TextXAlignment = Enum.TextXAlignment.Left
    prestigeLabel.Font = Enum.Font.GothamBold
    prestigeLabel.Parent = auraFrame
    
    prestigeMultLabel = Instance.new("TextLabel")
    prestigeMultLabel.Name = "MultiplierLabel"
    prestigeMultLabel.Size = UDim2.new(0.5, -5, 0, 20)
    prestigeMultLabel.Position = UDim2.new(0.5, 0, 1, -25)
    prestigeMultLabel.BackgroundTransparency = 1
    prestigeMultLabel.Text = "🚀 1x Aura"
    prestigeMultLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    prestigeMultLabel.TextSize = 12
    prestigeMultLabel.TextXAlignment = Enum.TextXAlignment.Right
    prestigeMultLabel.Font = Enum.Font.GothamBold
    prestigeMultLabel.Parent = auraFrame
    
    -- Click feedback container
    clickFeedbackContainer = Instance.new("Frame")
    clickFeedbackContainer.Name = "ClickFeedback"
    clickFeedbackContainer.Size = UDim2.new(1, 0, 1, 0)
    clickFeedbackContainer.BackgroundTransparency = 1
    clickFeedbackContainer.Parent = mainGui
    
    -- Shop Button (bottom right)
    local shopButton = Instance.new("TextButton")
    shopButton.Name = "ShopButton"
    shopButton.Size = UDim2.new(0, 130, 0, 55)
    shopButton.Position = UDim2.new(1, -150, 1, -75)
    shopButton.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
    shopButton.Text = "🛒 SHOP"
    shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    shopButton.TextSize = 20
    shopButton.Font = Enum.Font.GothamBold
    shopButton.Parent = mainGui
    
    local shopCorner = Instance.new("UICorner")
    shopCorner.CornerRadius = UDim.new(0, 12)
    shopCorner.Parent = shopButton
    
    local shopStroke = Instance.new("UIStroke")
    shopStroke.Color = Color3.fromRGB(150, 100, 200)
    shopStroke.Thickness = 2
    shopStroke.Parent = shopButton
    
    shopButton.MouseButton1Click:Connect(function()
        UIController.ToggleShop()
    end)
    
    -- Prestige Button (bottom left)
    local prestigeButton = Instance.new("TextButton")
    prestigeButton.Name = "PrestigeButton"
    prestigeButton.Size = UDim2.new(0, 130, 0, 55)
    prestigeButton.Position = UDim2.new(0, 20, 1, -75)
    prestigeButton.BackgroundColor3 = Color3.fromRGB(120, 80, 20)
    prestigeButton.Text = "⭐ PRESTIGE"
    prestigeButton.TextColor3 = Color3.fromRGB(255, 215, 0)
    prestigeButton.TextSize = 16
    prestigeButton.Font = Enum.Font.GothamBold
    prestigeButton.Parent = mainGui
    
    local prestigeBtnCorner = Instance.new("UICorner")
    prestigeBtnCorner.CornerRadius = UDim.new(0, 12)
    prestigeBtnCorner.Parent = prestigeButton
    
    local prestigeBtnStroke = Instance.new("UIStroke")
    prestigeBtnStroke.Color = Color3.fromRGB(255, 180, 50)
    prestigeBtnStroke.Thickness = 2
    prestigeBtnStroke.Parent = prestigeButton
    
    prestigeButton.MouseButton1Click:Connect(function()
        if upgradeRemote then
            upgradeRemote:FireServer("Prestige")
        end
    end)
    
    -- Create shop (hidden by default)
    UIController.CreateShop()
    
    -- Click instruction
    local instructionLabel = Instance.new("TextLabel")
    instructionLabel.Name = "Instruction"
    instructionLabel.Size = UDim2.new(0, 450, 0, 35)
    instructionLabel.Position = UDim2.new(0.5, -225, 1, -130)
    instructionLabel.BackgroundTransparency = 1
    instructionLabel.Text = "👆 Click the Gorilla Couch to earn Aura!"
    instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    instructionLabel.TextStrokeTransparency = 0.5
    instructionLabel.TextSize = 18
    instructionLabel.Font = Enum.Font.GothamBold
    instructionLabel.Parent = mainGui
end

-- Create shop UI
function UIController.CreateShop()
    shopFrame = Instance.new("Frame")
    shopFrame.Name = "ShopFrame"
    shopFrame.Size = UDim2.new(0, 420, 0, 520)
    shopFrame.Position = UDim2.new(0.5, -210, 0.5, -260)
    shopFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
    shopFrame.BorderSizePixel = 0
    shopFrame.Visible = false
    shopFrame.Parent = mainGui
    
    local shopCorner = Instance.new("UICorner")
    shopCorner.CornerRadius = UDim.new(0, 20)
    shopCorner.Parent = shopFrame
    
    local shopStroke = Instance.new("UIStroke")
    shopStroke.Color = Color3.fromRGB(120, 80, 180)
    shopStroke.Thickness = 3
    shopStroke.Parent = shopFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -80, 0, 50)
    titleLabel.Position = UDim2.new(0, 20, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🛒 UPGRADE SHOP"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 24
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = shopFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 45, 0, 45)
    closeButton.Position = UDim2.new(1, -55, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(150, 40, 60)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 24
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = shopFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        UIController.ToggleShop()
    end)
    
    -- Scrolling frame for upgrades
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "UpgradeList"
    scrollFrame.Size = UDim2.new(1, -40, 1, -80)
    scrollFrame.Position = UDim2.new(0, 20, 0, 70)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 80, 180)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = shopFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 12)
    listLayout.Parent = scrollFrame
    
    -- Section: Power Upgrades
    UIController.CreateSectionLabel(scrollFrame, "⚡ POWER UPGRADES")
    UIController.CreateUpgradeButton(scrollFrame, "⚡ Click Power", "ClickPower", 
        "More aura per click")
    UIController.CreateUpgradeButton(scrollFrame, "🤖 Auto-Clicker", "AutoClicker", 
        "Earn aura automatically")
    UIController.CreateUpgradeButton(scrollFrame, "✨ Multiplier", "Multiplier", 
        "Multiply all earnings")
    
    -- Section: Couch Upgrades
    UIController.CreateSectionLabel(scrollFrame, "🛋️ COUCH TIERS")
    
    for i, tier in GameConfig.CouchTiers do
        if i > 1 then -- Skip first tier (free)
            UIController.CreateTierButton(scrollFrame, tier)
        end
    end
end

-- Create section label
function UIController.CreateSectionLabel(parent, text: string)
    local label = Instance.new("TextLabel")
    label.Name = "Section_" .. text
    label.Size = UDim2.new(1, 0, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 150, 255)
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.Parent = parent
end

-- Create an upgrade button
function UIController.CreateUpgradeButton(parent, title: string, upgradeType: string, description: string)
    local button = Instance.new("TextButton")
    button.Name = upgradeType .. "Button"
    button.Size = UDim2.new(1, 0, 0, 75)
    button.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
    button.AutoButtonColor = true
    button.Text = ""
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 60, 120)
    stroke.Thickness = 1
    stroke.Parent = button
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.65, 0, 0, 28)
    titleLabel.Position = UDim2.new(0, 15, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = button
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.65, 0, 0, 20)
    descLabel.Position = UDim2.new(0, 15, 0, 40)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.TextColor3 = Color3.fromRGB(150, 140, 170)
    descLabel.TextSize = 13
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Font = Enum.Font.Gotham
    descLabel.Parent = button
    
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(0.32, 0, 1, 0)
    costLabel.Position = UDim2.new(0.68, 0, 0, 0)
    costLabel.BackgroundTransparency = 1
    costLabel.Text = "✨ ---"
    costLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
    costLabel.TextSize = 15
    costLabel.Font = Enum.Font.GothamBold
    costLabel.Parent = button
    
    button.MouseButton1Click:Connect(function()
        if upgradeRemote then
            upgradeRemote:FireServer(upgradeType)
        end
    end)
end

-- Create a couch tier button
function UIController.CreateTierButton(parent, tierData)
    local button = Instance.new("TextButton")
    button.Name = "Tier" .. tierData.Tier .. "Button"
    button.Size = UDim2.new(1, 0, 0, 65)
    button.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
    button.AutoButtonColor = true
    button.Text = ""
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 60, 120)
    stroke.Thickness = 1
    stroke.Parent = button
    
    -- Color preview
    local colorPreview = Instance.new("Frame")
    colorPreview.Size = UDim2.new(0, 45, 0, 45)
    colorPreview.Position = UDim2.new(0, 10, 0.5, -22)
    colorPreview.BackgroundColor3 = tierData.Color
    colorPreview.Parent = button
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 8)
    previewCorner.Parent = colorPreview
    
    if tierData.HasGlow then
        local glow = Instance.new("UIStroke")
        glow.Color = tierData.GlowColor or tierData.Color
        glow.Thickness = 2
        glow.Parent = colorPreview
    end
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.45, 0, 0, 28)
    titleLabel.Position = UDim2.new(0, 65, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tierData.Name
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 15
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = button
    
    local costLabel = Instance.new("TextLabel")
    costLabel.Size = UDim2.new(0.3, 0, 1, 0)
    costLabel.Position = UDim2.new(0.7, 0, 0, 0)
    costLabel.BackgroundTransparency = 1
    costLabel.Text = "✨ " .. UIController.FormatNumber(tierData.BaseCost)
    costLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
    costLabel.TextSize = 14
    costLabel.Font = Enum.Font.GothamBold
    costLabel.Parent = button
    
    button.MouseButton1Click:Connect(function()
        if upgradeRemote then
            upgradeRemote:FireServer("CouchTier", tierData.Tier)
        end
    end)
end

-- Toggle shop visibility
function UIController.ToggleShop()
    if shopFrame then
        shopFrame.Visible = not shopFrame.Visible
    end
end

-- Update aura display
function UIController.UpdateAura(aura: number)
    if auraLabel then
        auraLabel.Text = UIController.FormatNumber(aura)
        
        -- Pulse animation
        local originalColor = auraLabel.TextColor3
        auraLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        local tween = TweenService:Create(
            auraLabel,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { TextColor3 = originalColor }
        )
        tween:Play()
    end
end

-- Update prestige display
function UIController.UpdatePrestige(prestigeLevel: number)
    if prestigeLabel then
        prestigeLabel.Text = "⭐ Prestige: " .. prestigeLevel
    end
    if prestigeMultLabel then
        local mult = GameConfig.GetPrestigeMultiplier(prestigeLevel)
        prestigeMultLabel.Text = "🚀 " .. mult .. "x Aura"
    end
end

-- Show floating click feedback
function UIController.ShowClickFeedback(aura: number, isLucky: boolean)
    if not clickFeedbackContainer then return end
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 180, 0, 45)
    label.Position = UDim2.new(0.5, -90 + math.random(-60, 60), 0.45, math.random(-30, 30))
    label.BackgroundTransparency = 1
    label.Text = "+" .. UIController.FormatNumber(aura)
    label.TextColor3 = isLucky and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(200, 150, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(20, 10, 40)
    label.TextSize = isLucky and 36 or 28
    label.Font = Enum.Font.GothamBold
    label.Parent = clickFeedbackContainer
    
    if isLucky then
        label.Text = "🍀 +" .. UIController.FormatNumber(aura) .. " LUCKY!"
    end
    
    -- Animate up and fade
    local startPos = label.Position
    local endPos = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset - 100)
    
    local moveTween = TweenService:Create(
        label,
        TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = endPos }
    )
    local fadeTween = TweenService:Create(
        label,
        TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { TextTransparency = 1, TextStrokeTransparency = 1 }
    )
    
    moveTween:Play()
    fadeTween:Play()
    
    task.delay(1.3, function()
        label:Destroy()
    end)
end

-- Handle upgrade response
function UIController.OnUpgradeResponse(data)
    cachedPlayerData = data.PlayerData
    
    if data.Success then
        -- Update displays
        if data.PlayerData then
            if data.PlayerData.Aura then
                UIController.UpdateAura(data.PlayerData.Aura)
            end
            if data.PlayerData.PrestigeLevel then
                UIController.UpdatePrestige(data.PlayerData.PrestigeLevel)
            end
        end
        
        -- Show success message if it's a prestige
        if data.Message and string.find(data.Message, "Prestige") then
            UIController.ShowPrestigeEffect()
        end
    else
        -- TODO: Show error notification
        warn("[UI] Upgrade failed: " .. tostring(data.Message))
    end
end

-- Show prestige celebration effect
function UIController.ShowPrestigeEffect()
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    overlay.BackgroundTransparency = 0.8
    overlay.Parent = mainGui
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 0, 100)
    text.Position = UDim2.new(0, 0, 0.4, 0)
    text.BackgroundTransparency = 1
    text.Text = "⭐ PRESTIGE! ⭐"
    text.TextColor3 = Color3.fromRGB(255, 215, 0)
    text.TextStrokeTransparency = 0
    text.TextSize = 60
    text.Font = Enum.Font.GothamBold
    text.Parent = overlay
    
    local fadeTween = TweenService:Create(
        overlay,
        TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }
    )
    local textFade = TweenService:Create(
        text,
        TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { TextTransparency = 1, TextStrokeTransparency = 1 }
    )
    
    fadeTween:Play()
    textFade:Play()
    
    task.delay(2.1, function()
        overlay:Destroy()
    end)
end

-- Initialize UI
function UIController.Initialize()
    -- Wait for remotes
    upgradeRemote = ReplicatedStorage:WaitForChild("UpgradeRemote", 10)
    upgradeResponseRemote = ReplicatedStorage:WaitForChild("UpgradeResponseRemote", 10)
    
    if upgradeResponseRemote then
        upgradeResponseRemote.OnClientEvent:Connect(function(data)
            UIController.OnUpgradeResponse(data)
        end)
    end
    
    -- Create UI
    UIController.CreateUI()
    
    -- Connect to ClickController callbacks
    ClickController.OnAuraUpdated = function(aura)
        UIController.UpdateAura(aura)
    end
    
    ClickController.OnClickFeedback = function(aura, isLucky)
        UIController.ShowClickFeedback(aura, isLucky)
    end
    
    ClickController.OnPrestigeUpdated = function(level)
        UIController.UpdatePrestige(level)
    end
    
    print("[UIController] Initialized")
end

return UIController
