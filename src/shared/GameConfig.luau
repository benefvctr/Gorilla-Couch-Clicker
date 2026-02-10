--[[
    GameConfig.luau
    Central configuration for Gorilla Couch Clicker
    All game balance values, upgrades, and tiers defined here
]]

local GameConfig = {}

-- Starting values for new players
GameConfig.DefaultPlayerData = {
    Points = 0,
    ClickPower = 1,
    AutoClickerLevel = 0,
    MultiplierLevel = 0,
    CouchTier = 1,
    Accessories = {},
    TotalClicks = 0,
    TotalPointsEarned = 0,
}

-- Click Power Upgrades
-- Each level increases points per click
GameConfig.ClickPowerUpgrades = {
    { Level = 1, Power = 1, Cost = 0 },        -- Starting
    { Level = 2, Power = 2, Cost = 50 },
    { Level = 3, Power = 5, Cost = 200 },
    { Level = 4, Power = 10, Cost = 500 },
    { Level = 5, Power = 25, Cost = 1500 },
    { Level = 6, Power = 50, Cost = 5000 },
    { Level = 7, Power = 100, Cost = 15000 },
    { Level = 8, Power = 250, Cost = 50000 },
    { Level = 9, Power = 500, Cost = 150000 },
    { Level = 10, Power = 1000, Cost = 500000 },
}

-- Auto-Clicker Upgrades
-- Automatically earns points per second
GameConfig.AutoClickerUpgrades = {
    { Level = 0, PointsPerSecond = 0, Cost = 0 },      -- None
    { Level = 1, PointsPerSecond = 1, Cost = 100 },
    { Level = 2, PointsPerSecond = 5, Cost = 500 },
    { Level = 3, PointsPerSecond = 15, Cost = 2000 },
    { Level = 4, PointsPerSecond = 50, Cost = 8000 },
    { Level = 5, PointsPerSecond = 150, Cost = 25000 },
    { Level = 6, PointsPerSecond = 500, Cost = 100000 },
    { Level = 7, PointsPerSecond = 1500, Cost = 350000 },
    { Level = 8, PointsPerSecond = 5000, Cost = 1000000 },
}

-- Multiplier Upgrades
-- Multiplies ALL point earnings
GameConfig.MultiplierUpgrades = {
    { Level = 0, Multiplier = 1, Cost = 0 },       -- No multiplier
    { Level = 1, Multiplier = 1.5, Cost = 1000 },
    { Level = 2, Multiplier = 2, Cost = 5000 },
    { Level = 3, Multiplier = 3, Cost = 20000 },
    { Level = 4, Multiplier = 5, Cost = 75000 },
    { Level = 5, Multiplier = 10, Cost = 300000 },
}

-- Couch Tiers (Visual Upgrades)
GameConfig.CouchTiers = {
    {
        Tier = 1,
        Name = "Basic Couch",
        Cost = 0,
        Color = Color3.fromRGB(139, 90, 43),  -- Brown
        Material = Enum.Material.Fabric,
        HasGlow = false,
        HasParticles = false,
    },
    {
        Tier = 2,
        Name = "Leather Couch",
        Cost = 100,
        Color = Color3.fromRGB(61, 38, 20),   -- Dark brown
        Material = Enum.Material.Leather,
        HasGlow = false,
        HasParticles = false,
    },
    {
        Tier = 3,
        Name = "Velvet Couch",
        Cost = 500,
        Color = Color3.fromRGB(128, 0, 128),  -- Purple
        Material = Enum.Material.Fabric,
        HasGlow = false,
        HasParticles = false,
    },
    {
        Tier = 4,
        Name = "Golden Couch",
        Cost = 2500,
        Color = Color3.fromRGB(255, 215, 0),  -- Gold
        Material = Enum.Material.Foil,
        HasGlow = true,
        GlowColor = Color3.fromRGB(255, 200, 50),
        HasParticles = false,
    },
    {
        Tier = 5,
        Name = "Diamond Couch",
        Cost = 10000,
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
        Cost = 50000,
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
        Cost = 250000,
        Color = Color3.fromRGB(20, 0, 40),    -- Deep purple/black
        Material = Enum.Material.Neon,
        HasGlow = true,
        GlowColor = Color3.fromRGB(150, 50, 255),
        HasParticles = true,
        ParticleType = "Cosmic",
        IsAnimated = true,
    },
}

-- Accessories (can be purchased and toggled)
GameConfig.Accessories = {
    {
        Id = "crown",
        Name = "Royal Crown",
        Cost = 5000,
        Description = "A golden crown for your gorilla",
    },
    {
        Id = "sunglasses",
        Name = "Cool Shades",
        Cost = 2000,
        Description = "Stylish sunglasses",
    },
    {
        Id = "boombox",
        Name = "Boombox",
        Cost = 3500,
        Description = "Plays sick beats",
    },
    {
        Id = "money_stack",
        Name = "Money Stacks",
        Cost = 7500,
        Description = "Show off your wealth",
    },
    {
        Id = "fire_aura",
        Name = "Fire Aura",
        Cost = 15000,
        Description = "Surrounded by flames",
    },
    {
        Id = "diamond_aura",
        Name = "Diamond Aura",
        Cost = 25000,
        Description = "Floating diamonds orbit your couch",
    },
}

-- Lucky Click chance (percentage chance for bonus points)
GameConfig.LuckyClickChance = 0.05  -- 5% chance
GameConfig.LuckyClickMultiplier = 10  -- 10x points on lucky click

-- Auto-save interval (seconds)
GameConfig.AutoSaveInterval = 60

-- Click cooldown (seconds) - prevents auto-clicker exploits
GameConfig.ClickCooldown = 0.1

return GameConfig
