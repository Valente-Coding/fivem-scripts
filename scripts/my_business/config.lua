Config = {}

-- General Settings
Config.Locale = 'en'
Config.Debug = false

-- License Settings
Config.LicenseCenterCoords = {x = -545.0279, y = -204.2147, z = 38.2152}

-- Business Settings
Config.MaxBusinessesPerPlayer = 100
Config.SellMultiplier = 0.9
Config.BaseIncomeMultiplier = 0.01
Config.IncomeInterval = 5

-- Upgrade Settings
Config.MaxStaffLevel = 5
Config.MaxSizeLevel = 5
Config.MaxLogisticsLevel = 5
Config.MaxSecurityLevel = 5

Config.StaffIncomeBonus = 0.002
Config.SizeIncomeBonus = 0.003
Config.LogisticsIncomeBonus = 0.002
Config.SecurityIncomeBonus = 0.001

-- Warehouse Settings
Config.MinDistributionCycles = 1
Config.MaxDistributionCycles = 999999

Config.UpgradeCostMultiplier = {
    staff = 0.15,
    size = 0.2,
    logistics = 0.15,
    security = 0.1
}

-- Blip Settings
Config.BusinessBlip = {
    sprite = 375,
    color = 0,
    scale = 0.7,
    display = 4,
    shortRange = true
}

Config.OwnedBusinessBlip = {
    sprite = 375,
    color = 2,
    scale = 0.7,
    display = 4,
    shortRange = true
}

Config.WarehouseBlip = {
    sprite = 500,
    color = 5,
    scale = 0.7,
    display = 4,
    shortRange = true
}

-- Notification Settings
Config.Notifications = {
    prefix = "BUSINESS: ",
    purchaseSuccess = "You successfully purchased a business for $%s",
    insufficientFunds = "You don't have enough cash to purchase this",
    licenseRequired = "You need a Business License. Visit the License Center.",
    sellSuccess = "You successfully sold your business for $%s",
    upgradeSuccess = "You successfully upgraded %s to level %s",
    upgradeFailure = "You don't have enough cash for this upgrade",
    incomeReceived = "You received $%s income from your businesses",
    maxUpgradeReached = "This upgrade is already at maximum level",
}

-- Default Businesses
Config.DefaultBusinesses = {
    {
        name = "gabrielas_market",
        label = "Gabriela's Market",
        description = "A family-owned local market with fresh produce",
        type = "market",
        coords = {x = 53.2214, y = -1479.7489, z = 29.2744},
        price = 25000,
    },
    {
        name = "timmys_flowers",
        label = "Timmy's Flowers",
        description = "A charming flower shop with exotic varieties",
        type = "retail",
        coords = {x = 93.1635, y = -1507.5114, z = 29.2604},
        price = 35000,
    },
    {
        name = "leroys_electricals",
        label = "Leroy's Electricals",
        description = "A small electronics repair and retail shop",
        type = "retail",
        coords = {x = 67.0115, y = -1468.2622, z = 29.2912},
        price = 10000,
    },
    {
        name = "yum_fish",
        label = "Yum Fish",
        description = "A seafood restaurant specializing in fresh catches",
        type = "restaurant",
        coords = {x = 95.4891, y = -1683.1411, z = 29.2481},
        price = 8000,
    },
    {
        name = "family_farmacy",
        label = "Family Farmacy",
        description = "A trusted local pharmacy serving the community",
        type = "retail",
        coords = {x = 214.3271, y = -1834.5851, z = 27.5061},
        price = 45000,
    },
    {
        name = "atomic_car_repairs",
        label = "Atomic Car Repairs",
        description = "A full-service automotive repair shop",
        type = "automotive",
        coords = {x = 485.8577, y = -1875.8058, z = 26.2101},
        price = 200000,
    },
    {
        name = "hotel_laundry",
        label = "Hotel Laundry",
        description = "A commercial laundry service for hotels",
        type = "service",
        coords = {x = 74.2481, y = -1027.6163, z = 29.4753},
        price = 350000,
    },
    {
        name = "ground_and_pound_coffee",
        label = "Ground and Pound Coffee",
        description = "A popular coffee shop with loyal customers",
        type = "cafe",
        coords = {x = 44.7609, y = -803.2190, z = 31.5199},
        price = 80000,
    },
    {
        name = "daily_globe_international",
        label = "Daily Globe International",
        description = "A prestigious international news organization",
        type = "media",
        coords = {x = -317.8320, y = -609.9053, z = 33.5582},
        price = 1300000,
    },
    {
        name = "snr_buns",
        label = "Snr. Buns",
        description = "A bakery known for its signature buns",
        type = "food",
        coords = {x = -512.5884, y = -681.4635, z = 33.1848},
        price = 100000,
    },
    {
        name = "crastenburn_hotels",
        label = "Crastenburn Hotels and Resorts",
        description = "A luxury hotel chain with upscale accommodations",
        type = "accommodation",
        coords = {x = -668.2860, y = -1103.8468, z = 14.6471},
        price = 5000000,
    },
    {
        name = "liquor_hole",
        label = "Liquor Hole",
        description = "A well-stocked liquor store with competitive prices",
        type = "retail",
        coords = {x = -882.0442, y = -1156.9083, z = 5.1824},
        price = 60000,
    },
    {
        name = "la_spada",
        label = "La Spada",
        description = "An upscale Italian restaurant with authentic cuisine",
        type = "restaurant",
        coords = {x = -1038.3130, y = -1397.0701, z = 5.5532},
        price = 550000,
    },
    {
        name = "pot_heads_restaurant",
        label = "Pot Heads Restaurant",
        description = "A quirky restaurant specializing in pot cuisine",
        type = "restaurant",
        coords = {x = -1225.6255, y = -1182.5486, z = 7.7218},
        price = 250000,
    },
    {
        name = "perrera_beach_motel",
        label = "Perrera Beach Motel",
        description = "A beachside motel with ocean views",
        type = "accommodation",
        coords = {x = -1477.9438, y = -673.6569, z = 29.0419},
        price = 130000,
    },
    {
        name = "lombank",
        label = "Lombank",
        description = "A major financial institution with global presence",
        type = "finance",
        coords = {x = -1581.8462, y = -557.9435, z = 34.9528},
        price = 250000000,
    },
    {
        name = "bean_machine_coffee",
        label = "Bean Machine Coffee",
        description = "A trendy coffee shop with specialty brews",
        type = "cafe",
        coords = {x = -1368.0968, y = -209.6774, z = 44.4202},
        price = 100000,
    },
    {
        name = "los_santos_golf_club",
        label = "Los Santos Golf Club",
        description = "An exclusive golf club for the city's elite",
        type = "recreation",
        coords = {x = -1366.5645, y = 56.6984, z = 54.0984},
        price = 3000000,
    },
    {
        name = "dulce_complex",
        label = "Dulce Complex",
        description = "A modern residential complex",
        type = "real_estate",
        coords = {x = -936.2875, y = -1523.5249, z = 5.1754},
        price = 4000000,
    },
    {
        name = "bahama_mamas",
        label = "Bahama Mamas",
        description = "A vibrant nightclub with tropical themes",
        type = "nightclub",
        coords = {x = -1388.4215, y = -585.4996, z = 30.2160},
        price = 700000,
    },
    {
        name = "money_warehouse",
        label = "Money Distribution Warehouse",
        description = "A special facility that automatically distributes dirty money to all your businesses. Deposit dirty money and choose how many payment cycles to distribute across your business empire.",
        type = "warehouse",
        coords = {x = -71.8140, y = -1821.3622, z = 26.9420},
        price = 100000,
    }
}
