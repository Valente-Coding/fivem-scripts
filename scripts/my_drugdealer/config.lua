Config = {}

-- Main Settings
Config.DealerLocation = vector3(-210.7466, -1606.9053, 35.8693)
Config.DealerHeading = 60.0
Config.DealerModel = "s_m_y_dealer_01"
Config.DealerBlip = {
    Sprite = 140,
    Color = 2,
    Display = 4,
    Scale = 0.8,
    Name = "Drug Dealer"
}

Config.InteractionDistance = 3.0
Config.InteractionKey = 38 -- E key (INPUT_CONTEXT)
Config.Debug = false

-- Drug Items (bought with dirty money)
Config.Items = {
    -- Level 1
    {
        name = "small_weed",
        label = "Small Weed Package",
        price = 50,
        sellPrice = 100,
        requiredLevel = 1,
        description = "A small package of weed."
    },
    -- Level 2
    {
        name = "medium_weed",
        label = "Medium Weed Package",
        price = 100,
        sellPrice = 200,
        requiredLevel = 2,
        description = "A medium package of weed."
    },
    {
        name = "large_weed",
        label = "Large Weed Package",
        price = 200,
        sellPrice = 400,
        requiredLevel = 2,
        description = "A large package of weed."
    },
    -- Level 3
    {
        name = "small_cocaine",
        label = "Small Cocaine Package",
        price = 400,
        sellPrice = 800,
        requiredLevel = 3,
        description = "A small package of cocaine."
    },
    -- Level 4
    {
        name = "medium_cocaine",
        label = "Medium Cocaine Package",
        price = 500,
        sellPrice = 1000,
        requiredLevel = 4,
        description = "A medium package of cocaine."
    },
    {
        name = "large_cocaine",
        label = "Large Cocaine Package",
        price = 600,
        sellPrice = 1200,
        requiredLevel = 4,
        description = "A large package of cocaine."
    },
    -- Level 5
    {
        name = "small_meth",
        label = "Small Meth Package",
        price = 1000,
        sellPrice = 2000,
        requiredLevel = 5,
        description = "A small package of meth."
    },
    {
        name = "medium_meth",
        label = "Medium Meth Package",
        price = 1200,
        sellPrice = 2400,
        requiredLevel = 5,
        description = "A medium package of meth."
    },
    {
        name = "large_meth",
        label = "Large Meth Package",
        price = 1500,
        sellPrice = 3000,
        requiredLevel = 5,
        description = "A large package of meth."
    }
}

-- Reputation / Experience Configuration
Config.Reputation = {
    maxLevel = 5,
    experiencePerPurchase = 10,
    levelThresholds = {
        0,      -- Level 1: 0 XP to start
        300,    -- Level 2: 100 XP required
        900,    -- Level 3: 300 XP required
        2700,    -- Level 4: 600 XP required
        5000    -- Level 5: 1000 XP required
    }
}

-- Interaction Settings
Config.InteractionDistance = 3.0
Config.InteractionKey = 38 -- E key