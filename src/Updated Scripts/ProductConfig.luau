--[[
    ProductConfig.luau
    Configuration for all Robux purchases (Game Passes & Dev Products)
    
    IMPORTANT: Replace the placeholder IDs with real IDs from Roblox Creator Dashboard!
    1. Go to: https://create.roblox.com/dashboard/creations
    2. Select your game → Monetization → Passes (or Dev Products)
    3. Create each item and copy the ID here
]]

local ProductConfig = {}

--============================================
-- GAME PASSES (One-time permanent purchases)
--============================================
-- Create these in: Game Settings → Monetization → Passes

ProductConfig.GamePasses = {
    -- 2x Aura Forever
    DoubleAura = {
        Id = 0,  -- TODO: Replace with real Game Pass ID
        Name = "2x Aura",
        Description = "Permanently double all aura earned!",
        Icon = "💎",
        Effect = "DoubleAura",
        Multiplier = 2,
    },
    
    -- Permanent Auto Clicker
    AutoClicker = {
        Id = 0,  -- TODO: Replace with real Game Pass ID
        Name = "Auto Clicker",
        Description = "Automatically clicks forever! No upgrades needed.",
        Icon = "🤖",
        Effect = "AutoClicker",
        ClicksPerSecond = 5,
    },
    
    -- VIP Pass
    VIP = {
        Id = 0,  -- TODO: Replace with real Game Pass ID
        Name = "VIP",
        Description = "Exclusive VIP perks, chat tag, and badge!",
        Icon = "👑",
        Effect = "VIP",
        Perks = {
            "VIP Chat Tag",
            "Exclusive VIP Aura",
            "1.5x Aura Bonus",
            "Access to VIP Area",
        },
        BonusMultiplier = 1.5,
    },
    
    -- Lucky Boost
    LuckyBoost = {
        Id = 0,  -- TODO: Replace with real Game Pass ID
        Name = "Lucky Boost",
        Description = "Double your lucky click chance! (5% → 10%)",
        Icon = "🍀",
        Effect = "LuckyBoost",
        LuckyChance = 0.10,  -- 10% instead of 5%
    },
    
    -- Triple Prestige
    TriplePrestige = {
        Id = 0,  -- TODO: Replace with real Game Pass ID
        Name = "Triple Prestige",
        Description = "Earn 3x aura per prestige instead of 2x!",
        Icon = "⭐",
        Effect = "TriplePrestige",
        PrestigeMultiplier = 3,  -- Instead of 2
    },
}

--============================================
-- DEV PRODUCTS (Repeatable purchases)
--============================================
-- Create these in: Game Settings → Monetization → Developer Products

ProductConfig.DevProducts = {
    -- Aura Packs
    Aura1K = {
        Id = 0,  -- TODO: Replace with real Dev Product ID
        Name = "1K Aura Pack",
        Description = "Instantly receive 1,000 aura!",
        Icon = "✨",
        Effect = "AddAura",
        Amount = 1000,
    },
    
    Aura10K = {
        Id = 0,  -- TODO: Replace with real Dev Product ID
        Name = "10K Aura Pack",
        Description = "Instantly receive 10,000 aura!",
        Icon = "✨",
        Effect = "AddAura",
        Amount = 10000,
    },
    
    Aura100K = {
        Id = 0,  -- TODO: Replace with real Dev Product ID
        Name = "100K Aura Pack",
        Description = "Instantly receive 100,000 aura!",
        Icon = "💫",
        Effect = "AddAura",
        Amount = 100000,
    },
    
    Aura1M = {
        Id = 0,  -- TODO: Replace with real Dev Product ID
        Name = "1M Aura Pack",
        Description = "Instantly receive 1,000,000 aura!",
        Icon = "🌟",
        Effect = "AddAura",
        Amount = 1000000,
    },
    
    -- Temporary Boosts
    Boost2x30Min = {
        Id = 0,  -- TODO: Replace with real Dev Product ID
        Name = "2x Boost (30 min)",
        Description = "Double aura for 30 minutes!",
        Icon = "⚡",
        Effect = "TempBoost",
        Multiplier = 2,
        Duration = 1800,  -- 30 minutes in seconds
    },
    
    Boost5x10Min = {
        Id = 0,  -- TODO: Replace with real Dev Product ID
        Name = "5x Boost (10 min)",
        Description = "5x aura for 10 minutes!",
        Icon = "🔥",
        Effect = "TempBoost",
        Multiplier = 5,
        Duration = 600,  -- 10 minutes in seconds
    },
    
    -- Instant Prestige
    InstantPrestige = {
        Id = 0,  -- TODO: Replace with real Dev Product ID
        Name = "Instant Prestige",
        Description = "Skip requirements and prestige now!",
        Icon = "⭐",
        Effect = "InstantPrestige",
    },
}

--============================================
-- SELL VENDOR ITEMS
--============================================
-- Items players can sell for aura or other rewards

ProductConfig.SellableItems = {
    -- Sell aura for Coins (secondary currency for cosmetics)
    AuraToCoins = {
        Id = "aura_to_coins",
        Name = "Sell Aura for Coins",
        Description = "Convert your aura into coins for cosmetics!",
        Icon = "🪙",
        ExchangeRate = 100,  -- 100 aura = 1 coin
        MinAmount = 1000,    -- Minimum aura to sell
    },
}

--============================================
-- HELPER FUNCTIONS
--============================================

-- Find a game pass by its ID
function ProductConfig.GetGamePassById(id: number)
    for key, pass in ProductConfig.GamePasses do
        if pass.Id == id then
            return pass, key
        end
    end
    return nil
end

-- Find a dev product by its ID
function ProductConfig.GetDevProductById(id: number)
    for key, product in ProductConfig.DevProducts do
        if product.Id == id then
            return product, key
        end
    end
    return nil
end

-- Get all game pass IDs as a list
function ProductConfig.GetAllGamePassIds(): {number}
    local ids = {}
    for _, pass in ProductConfig.GamePasses do
        if pass.Id > 0 then
            table.insert(ids, pass.Id)
        end
    end
    return ids
end

return ProductConfig
