--[[
    UIController.luau
    Manages all UI elements for the clicker game
    Points display, upgrade shop, notifications
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
local pointsLabel = nil
local clickFeedbackContainer = nil
local shopFrame = nil

-- Remote events
local upgradeRemote = nil
local upgradeResponseRemote = nil

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
    
    -- Points Display (top center)
    local pointsFrame = Instance.new("Frame")
    pointsFrame.Name = "PointsFrame"
    pointsFrame.Size = UDim2.new(0, 300, 0, 80)
    pointsFrame.Position = UDim2.new(0.5, -150, 0, 20)
    pointsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    pointsFrame.BorderSizePixel = 0
    pointsFrame.Parent = mainGui
    
    local pointsCorner = Instance.new("UICorner")
    pointsCorner.CornerRadius = UDim.new(0, 12)
    pointsCorner.Parent = pointsFrame
    
    local pointsStroke = Instance.new("UIStroke")
    pointsStroke.Color = Color3.fromRGB(255, 215, 0)
    pointsStroke.Thickness = 2
    pointsStroke.Parent = pointsFrame
    
    pointsLabel = Instance.new("TextLabel")
    pointsLabel.Name = "PointsLabel"
    pointsLabel.Size = UDim2.new(1, -20, 1, -10)
    pointsLabel.Position = UDim2.new(0, 10, 0, 5)
    pointsLabel.BackgroundTransparency = 1
    pointsLabel.Text = "0"
    pointsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    pointsLabel.TextScaled = true
    pointsLabel.Font = Enum.Font.GothamBold
    pointsLabel.Parent = pointsFrame
    
    local pointsTitle = Instance.new("TextLabel")
    pointsTitle.Name = "PointsTitle"
    pointsTitle.Size = UDim2.new(1, 0, 0, 20)
    pointsTitle.Position = UDim2.new(0, 0, 0, -25)
    pointsTitle.BackgroundTransparency = 1
    pointsTitle.Text = "🪙 POINTS"
    pointsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    pointsTitle.TextSize = 14
    pointsTitle.Font = Enum.Font.GothamBold
    pointsTitle.Parent = pointsFrame
    
    -- Click feedback container
    clickFeedbackContainer = Instance.new("Frame")
    clickFeedbackContainer.Name = "ClickFeedback"
    clickFeedbackContainer.Size = UDim2.new(1, 0, 1, 0)
    clickFeedbackContainer.BackgroundTransparency = 1
    clickFeedbackContainer.Parent = mainGui
    
    -- Shop Button (bottom right)
    local shopButton = Instance.new("TextButton")
    shopButton.Name = "ShopButton"
    shopButton.Size = UDim2.new(0, 120, 0, 50)
    shopButton.Position = UDim2.new(1, -140, 1, -70)
    shopButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    shopButton.Text = "🛒 SHOP"
    shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    shopButton.TextSize = 18
    shopButton.Font = Enum.Font.GothamBold
    shopButton.Parent = mainGui
    
    local shopCorner = Instance.new("UICorner")
    shopCorner.CornerRadius = UDim.new(0, 8)
    shopCorner.Parent = shopButton
    
    shopButton.MouseButton1Click:Connect(function()
        UIController.ToggleShop()
    end)
    
    -- Create shop (hidden by default)
    UIController.CreateShop()
    
    -- Click anywhere instruction
    local instructionLabel = Instance.new("TextLabel")
    instructionLabel.Name = "Instruction"
    instructionLabel.Size = UDim2.new(0, 400, 0, 30)
    instructionLabel.Position = UDim2.new(0.5, -200, 1, -120)
    instructionLabel.BackgroundTransparency = 1
    instructionLabel.Text = "👆 Click the Gorilla Couch to earn points!"
    instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    instructionLabel.TextSize = 16
    instructionLabel.Font = Enum.Font.Gotham
    instructionLabel.Parent = mainGui
end

-- Create shop UI
function UIController.CreateShop()
    shopFrame = Instance.new("Frame")
    shopFrame.Name = "ShopFrame"
    shopFrame.Size = UDim2.new(0, 400, 0, 500)
    shopFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    shopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    shopFrame.BorderSizePixel = 0
    shopFrame.Visible = false
    shopFrame.Parent = mainGui
    
    local shopCorner = Instance.new("UICorner")
    shopCorner.CornerRadius = UDim.new(0, 16)
    shopCorner.Parent = shopFrame
    
    local shopStroke = Instance.new("UIStroke")
    shopStroke.Color = Color3.fromRGB(100, 100, 120)
    shopStroke.Thickness = 2
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
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = shopFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
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
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = shopFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = scrollFrame
    
    -- Add upgrade buttons
    UIController.CreateUpgradeButton(scrollFrame, "⚡ Click Power", "ClickPower", 
        "Increase points per click", GameConfig.ClickPowerUpgrades)
    UIController.CreateUpgradeButton(scrollFrame, "🤖 Auto-Clicker", "AutoClicker", 
        "Earn points automatically", GameConfig.AutoClickerUpgrades)
    UIController.CreateUpgradeButton(scrollFrame, "✨ Multiplier", "Multiplier", 
        "Multiply all earnings", GameConfig.MultiplierUpgrades)
    
    -- Add couch tier section
    local tierLabel = Instance.new("TextLabel")
    tierLabel.Name = "TierSectionLabel"
    tierLabel.Size = UDim2.new(1, 0, 0, 30)
    tierLabel.BackgroundTransparency = 1
    tierLabel.Text = "🛋️ COUCH UPGRADES"
    tierLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    tierLabel.TextSize = 16
    tierLabel.Font = Enum.Font.GothamBold
    tierLabel.Parent = scrollFrame
    
    for i, tier in GameConfig.CouchTiers do
        if i > 1 then -- Skip first tier (free)
            UIController.CreateTierButton(scrollFrame, tier)
        end
    end
end

-- Create an upgrade button
function UIController.CreateUpgradeButton(parent, title: string, upgradeType: string, description: string, upgradeTable)
    local button = Instance.new("TextButton")
    button.Name = upgradeType .. "Button"
    button.Size = UDim2.new(1, 0, 0, 70)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    button.AutoButtonColor = true
    button.Text = ""
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.6, 0, 0, 25)
    titleLabel.Position = UDim2.new(0, 10, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = button
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.6, 0, 0, 20)
    descLabel.Position = UDim2.new(0, 10, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    descLabel.TextSize = 12
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Font = Enum.Font.Gotham
    descLabel.Parent = button
    
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(0.35, 0, 1, 0)
    costLabel.Position = UDim2.new(0.65, 0, 0, 0)
    costLabel.BackgroundTransparency = 1
    costLabel.Text = "🪙 ---"
    costLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    costLabel.TextSize = 14
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
    button.Size = UDim2.new(1, 0, 0, 60)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    button.AutoButtonColor = true
    button.Text = ""
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Color preview
    local colorPreview = Instance.new("Frame")
    colorPreview.Size = UDim2.new(0, 40, 0, 40)
    colorPreview.Position = UDim2.new(0, 10, 0.5, -20)
    colorPreview.BackgroundColor3 = tierData.Color
    colorPreview.Parent = button
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 6)
    previewCorner.Parent = colorPreview
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.5, 0, 0, 25)
    titleLabel.Position = UDim2.new(0, 60, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tierData.Name
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = button
    
    local costLabel = Instance.new("TextLabel")
    costLabel.Size = UDim2.new(0.3, 0, 1, 0)
    costLabel.Position = UDim2.new(0.7, 0, 0, 0)
    costLabel.BackgroundTransparency = 1
    costLabel.Text = "🪙 " .. UIController.FormatNumber(tierData.Cost)
    costLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
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

-- Update points display
function UIController.UpdatePoints(points: number)
    if pointsLabel then
        pointsLabel.Text = UIController.FormatNumber(points)
        
        -- Pulse animation
        local tween = TweenService:Create(
            pointsLabel,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { TextSize = 50 }
        )
        tween:Play()
        
        task.delay(0.1, function()
            local returnTween = TweenService:Create(
                pointsLabel,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { TextSize = 36 }
            )
            returnTween:Play()
        end)
    end
end

-- Show floating click feedback
function UIController.ShowClickFeedback(points: number, isLucky: boolean)
    if not clickFeedbackContainer then return end
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 150, 0, 40)
    label.Position = UDim2.new(0.5, -75 + math.random(-50, 50), 0.5, math.random(-20, 20))
    label.BackgroundTransparency = 1
    label.Text = "+" .. UIController.FormatNumber(points)
    label.TextColor3 = isLucky and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextSize = isLucky and 32 or 24
    label.Font = Enum.Font.GothamBold
    label.Parent = clickFeedbackContainer
    
    if isLucky then
        label.Text = "🍀 +" .. UIController.FormatNumber(points) .. " LUCKY!"
    end
    
    -- Animate up and fade
    local startPos = label.Position
    local endPos = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset - 80)
    
    local moveTween = TweenService:Create(
        label,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = endPos }
    )
    local fadeTween = TweenService:Create(
        label,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { TextTransparency = 1, TextStrokeTransparency = 1 }
    )
    
    moveTween:Play()
    fadeTween:Play()
    
    task.delay(1.1, function()
        label:Destroy()
    end)
end

-- Handle upgrade response
function UIController.OnUpgradeResponse(data)
    if data.Success then
        -- Update points display if we have new data
        if data.PlayerData and data.PlayerData.Points then
            UIController.UpdatePoints(data.PlayerData.Points)
        end
        -- TODO: Show success notification
    else
        -- TODO: Show error notification
        warn("[UI] Upgrade failed: " .. tostring(data.Message))
    end
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
    ClickController.OnPointsUpdated = function(points)
        UIController.UpdatePoints(points)
    end
    
    ClickController.OnClickFeedback = function(points, isLucky)
        UIController.ShowClickFeedback(points, isLucky)
    end
    
    print("[UIController] Initialized")
end

return UIController
