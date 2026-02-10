--[[
    GameConfig.luau
    Central configuration for Gorilla Couch Clicker
    All game balance values, upgrades, and tiers defined here
    
    Currency: AURA (not points!)
]]

local GameConfig = {}

--============================================
-- PRESTIGE SYSTEM
--============================================
-- When you prestige:
-- - Your Aura resets to 0
-- - Your upgrades reset
-- - You gain permanent Aura multiplier (2x per prestige)
-- - All costs increase (3.5x per prestige)
-- - You keep your prestige level and total prestiges

GameConfig.Prestige = {
    -- Minimum aura required to prestige (scales with prestige level)
    BaseRequirement = 100000,  -- 100k aura for first prestige
    RequirementMultiplier = 2.5,  -- Each prestige needs 2.5x more aura
    
    -- Aura earning multiplier per prestige level
    AuraMultiplier = 2.0,  -- 2x aura per prestige (1 prestige = 2x, 2 prestiges = 4x, etc.)
    
    -- Cost scaling per prestige level
    CostMultiplier = 3.5,  -- Costs increase 3.5x per prestige
    
    -- Bonus: Keep couch tier on prestige?
    KeepCouchTier = false,
    
    -- Bonus: Keep accessories on prestige?
    KeepAccessories = true,
}

--============================================
-- DEFAULT PLAYER DATA
--============================================
GameConfig.DefaultPlayerData = {
    -- Currency
    Aura = 0,
    
    -- Upgrades (reset on prestige)
    ClickPower = 1,
    AutoClickerLevel = 0,
    MultiplierLevel = 0,
    CouchTier = 1,
    
    -- Accessories (kept on prestige)
    Accessories = {},
    
    -- Prestige
    PrestigeLevel = 0,
    TotalPrestiges = 0,
    LifetimeAura = 0,  -- Total aura ever earned (across all prestiges)
    
    -- Stats
    TotalClicks = 0,
    TotalAuraEarned = 0,  -- Aura earned this prestige
}

--============================================
-- CLICK POWER UPGRADES
--============================================
-- Each level increases aura per click
-- Costs scale with prestige level
GameConfig.ClickPowerUpgrades = {
    { Level = 1, Power = 1, BaseCost = 0 },        -- Starting
    { Level = 2, Power = 2, BaseCost = 50 },
    { Level = 3, Power = 5, BaseCost = 200 },
    { Level = 4, Power = 10, BaseCost = 500 },
    { Level = 5, Power = 25, BaseCost = 1500 },
    { Level = 6, Power = 50, BaseCost = 5000 },
    { Level = 7, Power = 100, BaseCost = 15000 },
    { Level = 8, Power = 250, BaseCost = 50000 },
    { Level = 9, Power = 500, BaseCost = 150000 },
    { Level = 10, Power = 1000, BaseCost = 500000 },
}

--============================================
-- AUTO-CLICKER UPGRADES
--============================================
-- Automatically earns aura per second
GameConfig.AutoClickerUpgrades = {
    { Level = 0, AuraPerSecond = 0, BaseCost = 0 },      -- None
    { Level = 1, AuraPerSecond = 1, BaseCost = 100 },
    { Level = 2, AuraPerSecond = 5, BaseCost = 500 },
    { Level = 3, AuraPerSecond = 15, BaseCost = 2000 },
    { Level = 4, AuraPerSecond = 50, BaseCost = 8000 },
    { Level = 5, AuraPerSecond = 150, BaseCost = 25000 },
    { Level = 6, AuraPerSecond = 500, BaseCost = 100000 },
    { Level = 7, AuraPerSecond = 1500, BaseCost = 350000 },
    { Level = 8, AuraPerSecond = 5000, BaseCost = 1000000 },
}

--============================================
-- MULTIPLIER UPGRADES
--============================================
-- Multiplies ALL aura earnings (stacks with prestige bonus)
GameConfig.MultiplierUpgrades = {
    { Level = 0, Multiplier = 1, BaseCost = 0 },       -- No multiplier
    { Level = 1, Multiplier = 1.5, BaseCost = 1000 },
    { Level = 2, Multiplier = 2, BaseCost = 5000 },
    { Level = 3, Multiplier = 3, BaseCost = 20000 },
    { Level = 4, Multiplier = 5, BaseCost = 75000 },
    { Level = 5, Multiplier = 10, BaseCost = 300000 },
}

--============================================
-- COUCH TIERS (Visual Upgrades)
--============================================
GameConfig.CouchTiers = {
    {
        Tier = 1,
        Name = "Basic Couch",
        BaseCost = 0,
        Color = Color3.fromRGB(139, 90, 43),  -- Brown
        Material = Enum.Material.Fabric,
        HasGlow = false,
        HasParticles = false,
    },
    {
        Tier = 2,
        Name = "Leather Couch",
        BaseCost = 100,
        Color = Color3.fromRGB(61, 38, 20),   -- Dark brown
        Material = Enum.Material.Leather,
        HasGlow = false,
        HasParticles = false,
    },
    {
        Tier = 3,
        Name = "Velvet Couch",
        BaseCost = 500,
        Color = Color3.fromRGB(128, 0, 128),  -- Purple
        Material = Enum.Material.Fabric,
        HasGlow = false,
        HasParticles = false,
    },
    {
        Tier = 4,
        Name = "Golden Couch",
        BaseCost = 2500,
        Color = Color3.fromRGB(255, 215, 0),  -- Gold
        Material = Enum.Material.Foil,
        HasGlow = true,
        GlowColor = Color3.fromRGB(255, 200, 50),
        HasParticles = false,
    },
    {
        Tier = 5,
        Name = "Diamond Couch",
        BaseCost = 10000,
        Color = Color3.fromRGB(185, 242, 255), -- Light blue
        Material = Enum.Material.Glass,
        HasGlow = true,
        GlowColor = Color3.fromRGB(200, 240, 255),
        HasParticles = true,
        ParticleType = "Sparkle",
    },
    {
        Tier = 6,
        Name = "Rainbow Couch",
        BaseCost = 50000,
        Color = Color3.fromRGB(255, 0, 0),    -- Starting color (animates)
        Material = Enum.Material.Neon,
        HasGlow = true,
        GlowColor = Color3.fromRGB(255, 255, 255),
        HasParticles = true,
        ParticleType = "Rainbow",
        IsAnimated = true,
    },
    {
        Tier = 7,
        Name = "Cosmic Couch",
        BaseCost = 250000,
        Color = Color3.fromRGB(20, 0, 40),    -- Deep purple/black
        Material = Enum.Material.Neon,
        HasGlow = true,
        GlowColor = Color3.fromRGB(150, 50, 255),
        HasParticles = true,
        ParticleType = "Cosmic",
        IsAnimated = true,
    },
}

--============================================
-- ACCESSORIES
--============================================
-- Can be purchased and toggled, kept on prestige
GameConfig.Accessories = {
    {
        Id = "crown",
        Name = "Royal Crown",
        BaseCost = 5000,
        Description = "A golden crown for your gorilla",
    },
    {
        Id = "sunglasses",
        Name = "Cool Shades",
        BaseCost = 2000,
        Description = "Stylish sunglasses",
    },
    {
        Id = "boombox",
        Name = "Boombox",
        BaseCost = 3500,
        Description = "Plays sick beats",
    },
    {
        Id = "money_stack",
        Name = "Money Stacks",
        BaseCost = 7500,
        Description = "Show off your wealth",
    },
    {
        Id = "fire_aura",
        Name = "Fire Aura",
        BaseCost = 15000,
        Description = "Surrounded by flames",
    },
    {
        Id = "diamond_aura",
        Name = "Diamond Aura",
        BaseCost = 25000,
        Description = "Floating diamonds orbit your couch",
    },
}

--============================================
-- GAMEPLAY SETTINGS
--============================================

-- Lucky Click chance (percentage chance for bonus aura)
GameConfig.LuckyClickChance = 0.05  -- 5% chance
GameConfig.LuckyClickMultiplier = 10  -- 10x aura on lucky click

-- Auto-save interval (seconds)
GameConfig.AutoSaveInterval = 60

-- Click cooldown (seconds) - prevents auto-clicker exploits
GameConfig.ClickCooldown = 0.1

--============================================
-- HELPER FUNCTIONS
--============================================

-- Calculate actual cost with prestige scaling
function GameConfig.GetScaledCost(baseCost: number, prestigeLevel: number): number
    if prestigeLevel == 0 then
        return baseCost
    end
    return math.floor(baseCost * (GameConfig.Prestige.CostMultiplier ^ prestigeLevel))
end

-- Calculate prestige aura multiplier
function GameConfig.GetPrestigeMultiplier(prestigeLevel: number): number
    if prestigeLevel == 0 then
        return 1
    end
    return GameConfig.Prestige.AuraMultiplier ^ prestigeLevel
end

-- Calculate aura required for next prestige
function GameConfig.GetPrestigeRequirement(currentPrestigeLevel: number): number
    return math.floor(
        GameConfig.Prestige.BaseRequirement * 
        (GameConfig.Prestige.RequirementMultiplier ^ currentPrestigeLevel)
    )
end

-- Check if player can prestige
function GameConfig.CanPrestige(playerData: table): boolean
    local requirement = GameConfig.GetPrestigeRequirement(playerData.PrestigeLevel)
    return playerData.TotalAuraEarned >= requirement
end

return GameConfig
