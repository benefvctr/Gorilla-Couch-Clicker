--[[
    GamePassService.luau
    Handles all Robux purchases - Game Passes and Developer Products
    Applies effects when players own passes or purchase products
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductConfig = require(game.ReplicatedStorage.Shared.ProductConfig)
local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local GamePassService = {}

-- Cache of which players own which passes
local playerPassCache = {}

-- Active temporary boosts per player
local activeBoosts = {}

-- Remote for updating client about purchases
local purchaseRemote = nil

--============================================
-- GAME PASS CHECKING
--============================================

-- Check if player owns a specific game pass
function GamePassService.PlayerOwnsPass(player: Player, passKey: string): boolean
    local passData = ProductConfig.GamePasses[passKey]
    if not passData or passData.Id == 0 then
        return false
    end
    
    -- Check cache first
    local cache = playerPassCache[player.UserId]
    if cache and cache[passKey] ~= nil then
        return cache[passKey]
    end
    
    -- Query MarketplaceService
    local success, ownsPass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passData.Id)
    end)
    
    if success then
        -- Cache the result
        if not playerPassCache[player.UserId] then
            playerPassCache[player.UserId] = {}
        end
        playerPassCache[player.UserId][passKey] = ownsPass
        return ownsPass
    end
    
    return false
end

-- Check all passes for a player and cache them
function GamePassService.CachePlayerPasses(player: Player)
    playerPassCache[player.UserId] = {}
    
    for passKey, passData in ProductConfig.GamePasses do
        if passData.Id > 0 then
            local success, ownsPass = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passData.Id)
            end)
            if success then
                playerPassCache[player.UserId][passKey] = ownsPass
                if ownsPass then
                    print("[GamePass] " .. player.Name .. " owns: " .. passData.Name)
                end
            end
        end
    end
end

--============================================
-- MULTIPLIER CALCULATIONS
--============================================

-- Get total aura multiplier from passes for a player
function GamePassService.GetPassMultiplier(player: Player): number
    local multiplier = 1
    
    -- Double Aura pass
    if GamePassService.PlayerOwnsPass(player, "DoubleAura") then
        multiplier = multiplier * ProductConfig.GamePasses.DoubleAura.Multiplier
    end
    
    -- VIP bonus
    if GamePassService.PlayerOwnsPass(player, "VIP") then
        multiplier = multiplier * ProductConfig.GamePasses.VIP.BonusMultiplier
    end
    
    -- Temporary boosts
    local boosts = activeBoosts[player.UserId]
    if boosts then
        for _, boost in boosts do
            if boost.ExpiresAt > tick() then
                multiplier = multiplier * boost.Multiplier
            end
        end
    end
    
    return multiplier
end

-- Get lucky click chance (modified by pass)
function GamePassService.GetLuckyChance(player: Player): number
    if GamePassService.PlayerOwnsPass(player, "LuckyBoost") then
        return ProductConfig.GamePasses.LuckyBoost.LuckyChance
    end
    return GameConfig.LuckyClickChance
end

-- Get prestige multiplier (modified by pass)
function GamePassService.GetPrestigeMultiplier(player: Player): number
    if GamePassService.PlayerOwnsPass(player, "TriplePrestige") then
        return ProductConfig.GamePasses.TriplePrestige.PrestigeMultiplier
    end
    return GameConfig.Prestige.AuraMultiplier
end

-- Check if player has auto clicker pass
function GamePassService.HasAutoClickerPass(player: Player): boolean
    return GamePassService.PlayerOwnsPass(player, "AutoClicker")
end

-- Check if player is VIP
function GamePassService.IsVIP(player: Player): boolean
    return GamePassService.PlayerOwnsPass(player, "VIP")
end

--============================================
-- DEV PRODUCT PROCESSING
--============================================

-- Apply a dev product effect
function GamePassService.ApplyDevProduct(player: Player, productKey: string): boolean
    local productData = ProductConfig.DevProducts[productKey]
    if not productData then
        warn("[GamePass] Unknown product: " .. productKey)
        return false
    end
    
    local effect = productData.Effect
    
    if effect == "AddAura" then
        -- Add aura directly (bypasses normal multipliers for purchases)
        local data = PlayerDataService.GetPlayerData(player)
        if data then
            data.Aura = data.Aura + productData.Amount
            print("[GamePass] Added " .. productData.Amount .. " aura to " .. player.Name)
            return true
        end
        
    elseif effect == "TempBoost" then
        -- Add temporary boost
        if not activeBoosts[player.UserId] then
            activeBoosts[player.UserId] = {}
        end
        
        table.insert(activeBoosts[player.UserId], {
            Multiplier = productData.Multiplier,
            ExpiresAt = tick() + productData.Duration,
            Name = productData.Name,
        })
        
        print("[GamePass] " .. player.Name .. " activated " .. productData.Name)
        
        -- Notify client
        if purchaseRemote then
            purchaseRemote:FireClient(player, {
                Type = "TempBoost",
                Name = productData.Name,
                Multiplier = productData.Multiplier,
                Duration = productData.Duration,
            })
        end
        
        return true
        
    elseif effect == "InstantPrestige" then
        -- Force prestige without requirements
        local success = PlayerDataService.PerformPrestige(player)
        if success then
            print("[GamePass] " .. player.Name .. " used Instant Prestige")
        end
        return success
    end
    
    return false
end

--============================================
-- MARKETPLACE CALLBACKS
--============================================

-- Handle dev product purchases
local function processReceipt(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    local productData, productKey = ProductConfig.GetDevProductById(receiptInfo.ProductId)
    if productData then
        local success = GamePassService.ApplyDevProduct(player, productKey)
        if success then
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end
    end
    
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Handle game pass purchases (real-time)
local function onGamePassPurchased(player: Player, passId: number, wasPurchased: boolean)
    if wasPurchased then
        local passData, passKey = ProductConfig.GetGamePassById(passId)
        if passData and passKey then
            -- Update cache
            if not playerPassCache[player.UserId] then
                playerPassCache[player.UserId] = {}
            end
            playerPassCache[player.UserId][passKey] = true
            
            print("[GamePass] " .. player.Name .. " purchased: " .. passData.Name)
            
            -- Notify client
            if purchaseRemote then
                purchaseRemote:FireClient(player, {
                    Type = "GamePass",
                    Name = passData.Name,
                    PassKey = passKey,
                })
            end
        end
    end
end

--============================================
-- VENDOR PROMPT
--============================================

-- Prompt player to purchase a game pass
function GamePassService.PromptGamePass(player: Player, passKey: string)
    local passData = ProductConfig.GamePasses[passKey]
    if passData and passData.Id > 0 then
        MarketplaceService:PromptGamePassPurchase(player, passData.Id)
    else
        warn("[GamePass] Cannot prompt purchase - invalid pass or ID not set: " .. passKey)
    end
end

-- Prompt player to purchase a dev product
function GamePassService.PromptDevProduct(player: Player, productKey: string)
    local productData = ProductConfig.DevProducts[productKey]
    if productData and productData.Id > 0 then
        MarketplaceService:PromptProductPurchase(player, productData.Id)
    else
        warn("[GamePass] Cannot prompt purchase - invalid product or ID not set: " .. productKey)
    end
end

--============================================
-- INITIALIZATION
--============================================

function GamePassService.Initialize()
    -- Create remote for client notifications
    purchaseRemote = Instance.new("RemoteEvent")
    purchaseRemote.Name = "PurchaseRemote"
    purchaseRemote.Parent = ReplicatedStorage
    
    -- Create remote for purchase requests from client
    local purchaseRequestRemote = Instance.new("RemoteEvent")
    purchaseRequestRemote.Name = "PurchaseRequestRemote"
    purchaseRequestRemote.Parent = ReplicatedStorage
    
    purchaseRequestRemote.OnServerEvent:Connect(function(player, purchaseType, itemKey)
        if purchaseType == "GamePass" then
            GamePassService.PromptGamePass(player, itemKey)
        elseif purchaseType == "DevProduct" then
            GamePassService.PromptDevProduct(player, itemKey)
        end
    end)
    
    -- Set up marketplace callbacks
    MarketplaceService.ProcessReceipt = processReceipt
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamePassPurchased)
    
    -- Cache passes for existing players
    for _, player in Players:GetPlayers() do
        task.spawn(function()
            GamePassService.CachePlayerPasses(player)
        end)
    end
    
    -- Cache passes for new players
    Players.PlayerAdded:Connect(function(player)
        task.spawn(function()
            GamePassService.CachePlayerPasses(player)
        end)
    end)
    
    -- Clean up on leave
    Players.PlayerRemoving:Connect(function(player)
        playerPassCache[player.UserId] = nil
        activeBoosts[player.UserId] = nil
    end)
    
    -- Clean up expired boosts periodically
    task.spawn(function()
        while true do
            task.wait(60)
            local now = tick()
            for userId, boosts in activeBoosts do
                for i = #boosts, 1, -1 do
                    if boosts[i].ExpiresAt < now then
                        table.remove(boosts, i)
                    end
                end
            end
        end
    end)
    
    print("[GamePassService] Initialized")
end

return GamePassService
