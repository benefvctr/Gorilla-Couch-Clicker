--[[
    VendorHandler.luau
    Handles interactions with physical vendor NPCs in the game world
    Shop vendor = Robux purchases
    Sell vendor = Convert aura to coins, sell items
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductConfig = require(game.ReplicatedStorage.Shared.ProductConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)
local GamePassService = require(script.Parent.GamePassService)

local VendorHandler = {}

-- Remote events
local vendorRemote = nil
local vendorResponseRemote = nil

--============================================
-- SHOP VENDOR (Robux Purchases)
--============================================

-- Get shop items for display
function VendorHandler.GetShopItems(player: Player)
    local items = {
        GamePasses = {},
        DevProducts = {},
    }
    
    -- Add game passes (show ownership status)
    for key, pass in ProductConfig.GamePasses do
        local owned = GamePassService.PlayerOwnsPass(player, key)
        table.insert(items.GamePasses, {
            Key = key,
            Name = pass.Name,
            Description = pass.Description,
            Icon = pass.Icon,
            Owned = owned,
            Id = pass.Id,
        })
    end
    
    -- Add dev products
    for key, product in ProductConfig.DevProducts do
        table.insert(items.DevProducts, {
            Key = key,
            Name = product.Name,
            Description = product.Description,
            Icon = product.Icon,
            Id = product.Id,
        })
    end
    
    return items
end

--============================================
-- SELL VENDOR
--============================================

-- Player data includes a "Coins" field for cosmetic purchases
-- Sell aura to get coins

function VendorHandler.SellAuraForCoins(player: Player, auraAmount: number): (boolean, string, number?)
    local data = PlayerDataService.GetPlayerData(player)
    if not data then
        return false, "Data not loaded", nil
    end
    
    local sellConfig = ProductConfig.SellableItems.AuraToCoins
    
    -- Check minimum
    if auraAmount < sellConfig.MinAmount then
        return false, "Minimum " .. sellConfig.MinAmount .. " aura required", nil
    end
    
    -- Check if player has enough aura
    if data.Aura < auraAmount then
        return false, "Not enough aura", nil
    end
    
    -- Calculate coins
    local coinsEarned = math.floor(auraAmount / sellConfig.ExchangeRate)
    if coinsEarned < 1 then
        return false, "Not enough aura for 1 coin", nil
    end
    
    -- Adjust aura amount to exact exchange (no remainders wasted)
    local actualAuraSpent = coinsEarned * sellConfig.ExchangeRate
    
    -- Perform exchange
    data.Aura = data.Aura - actualAuraSpent
    data.Coins = (data.Coins or 0) + coinsEarned
    
    return true, "Sold " .. actualAuraSpent .. " aura for " .. coinsEarned .. " coins!", coinsEarned
end

-- Get player's coin balance
function VendorHandler.GetCoins(player: Player): number
    local data = PlayerDataService.GetPlayerData(player)
    return data and (data.Coins or 0) or 0
end

--============================================
-- VENDOR INTERACTION
--============================================

-- Process vendor interaction
function VendorHandler.ProcessInteraction(player: Player, vendorType: string, action: string, data: any)
    if vendorType == "Shop" then
        if action == "GetItems" then
            -- Return shop items
            local items = VendorHandler.GetShopItems(player)
            if vendorResponseRemote then
                vendorResponseRemote:FireClient(player, {
                    VendorType = "Shop",
                    Action = "ItemList",
                    Items = items,
                })
            end
            
        elseif action == "BuyGamePass" then
            -- Prompt game pass purchase
            GamePassService.PromptGamePass(player, data)
            
        elseif action == "BuyProduct" then
            -- Prompt dev product purchase
            GamePassService.PromptDevProduct(player, data)
        end
        
    elseif vendorType == "Sell" then
        if action == "GetInfo" then
            -- Return sell info
            local coins = VendorHandler.GetCoins(player)
            local playerData = PlayerDataService.GetPlayerData(player)
            if vendorResponseRemote then
                vendorResponseRemote:FireClient(player, {
                    VendorType = "Sell",
                    Action = "Info",
                    Coins = coins,
                    Aura = playerData and playerData.Aura or 0,
                    ExchangeRate = ProductConfig.SellableItems.AuraToCoins.ExchangeRate,
                    MinAmount = ProductConfig.SellableItems.AuraToCoins.MinAmount,
                })
            end
            
        elseif action == "SellAura" then
            -- Sell aura for coins
            local success, message, coins = VendorHandler.SellAuraForCoins(player, data)
            local playerData = PlayerDataService.GetPlayerData(player)
            if vendorResponseRemote then
                vendorResponseRemote:FireClient(player, {
                    VendorType = "Sell",
                    Action = "SellResult",
                    Success = success,
                    Message = message,
                    Coins = VendorHandler.GetCoins(player),
                    Aura = playerData and playerData.Aura or 0,
                })
            end
        end
    end
end

--============================================
-- PHYSICAL VENDOR SETUP
--============================================

-- Set up click detection on vendor models in workspace
function VendorHandler.SetupVendorClickDetection()
    -- Look for vendor models in workspace
    local function setupVendor(model: Model, vendorType: string)
        for _, part in model:GetDescendants() do
            if part:IsA("BasePart") then
                local detector = part:FindFirstChild("ClickDetector")
                if not detector then
                    detector = Instance.new("ClickDetector")
                    detector.MaxActivationDistance = 15
                    detector.Parent = part
                end
                
                detector.MouseClick:Connect(function(player)
                    VendorHandler.ProcessInteraction(player, vendorType, "GetItems", nil)
                end)
            end
        end
        print("[VendorHandler] Set up " .. vendorType .. " vendor: " .. model.Name)
    end
    
    -- Find Shop vendor
    local shopVendor = workspace:FindFirstChild("Shop") or workspace:FindFirstChild("ShopVendor")
    if shopVendor then
        setupVendor(shopVendor, "Shop")
    end
    
    -- Find Sell vendor
    local sellVendor = workspace:FindFirstChild("Sell") or workspace:FindFirstChild("SellVendor")
    if sellVendor then
        setupVendor(sellVendor, "Sell")
    end
    
    -- Watch for vendors to be added
    workspace.ChildAdded:Connect(function(child)
        if child.Name == "Shop" or child.Name == "ShopVendor" then
            setupVendor(child, "Shop")
        elseif child.Name == "Sell" or child.Name == "SellVendor" then
            setupVendor(child, "Sell")
        end
    end)
end

--============================================
-- INITIALIZATION
--============================================

function VendorHandler.Initialize()
    -- Create remote events
    vendorRemote = Instance.new("RemoteEvent")
    vendorRemote.Name = "VendorRemote"
    vendorRemote.Parent = ReplicatedStorage
    
    vendorResponseRemote = Instance.new("RemoteEvent")
    vendorResponseRemote.Name = "VendorResponseRemote"
    vendorResponseRemote.Parent = ReplicatedStorage
    
    -- Listen for vendor interactions from client
    vendorRemote.OnServerEvent:Connect(function(player, vendorType, action, data)
        VendorHandler.ProcessInteraction(player, vendorType, action, data)
    end)
    
    -- Set up physical vendors (after workspace loads)
    task.spawn(function()
        task.wait(2)  -- Wait for workspace to populate
        VendorHandler.SetupVendorClickDetection()
    end)
    
    print("[VendorHandler] Initialized")
end

return VendorHandler
