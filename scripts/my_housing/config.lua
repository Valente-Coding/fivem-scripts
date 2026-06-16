Config = {}

-- General Settings
Config.Locale = 'en'

-- Performance Settings
Config.Performance = {
    MarkerRefreshRate = 100,
    InteractionRefreshRate = 5,
    DistanceCheckInterval = 2000,
    MovementThreshold = 5.0,
    MaxProcessDistance = 50.0,
}

-- House Settings
Config.MaxHousesPerPlayer = 3
Config.RentMultiplier = 0.01
Config.RentInterval = 30
Config.MarketUpdateInterval = 60
Config.MarketFluctuation = { min = 0.90, max = 1.10 }
Config.ValueHistoryPoints = 10

-- House Storage Settings
Config.HouseStorage = {
    MaxItemStacks = 50,          -- Max different item types a house can hold
    MaxCash = 10000000,          -- Max clean cash a house can store ($10M)
    MaxDirty = 10000000,         -- Max dirty money a house can store ($10M)
}

-- Blip Settings
Config.HouseBlip = {
    sprite = 40,
    color = 0,
    scale = 0.6,
    display = 4,
    shortRange = true
}

Config.OwnedHouseBlip = {
    sprite = 40,
    color = 2,
    scale = 0.6,
    display = 4,
    shortRange = true
}

Config.RentedHouseBlip = {
    sprite = 40,
    color = 5,
    scale = 0.6,
    display = 4,
    shortRange = true
}

Config.NotOwnedHouseBlip = {
    sprite = 40,
    color = 1,
    scale = 0.6,
    display = 4,
    shortRange = true
}

-- Notification Settings
Config.Notifications = {
    prefix = "HOUSING: ",
    purchaseSuccess = "You successfully purchased a house for $%s",
    insufficientFunds = "You don't have enough cash to purchase this house",
    sellSuccess = "You successfully sold your house for $%s",
    rentEnabled = "You enabled renting for your house",
    rentDisabled = "You disabled renting for your house",
    rentPaid = "You paid $%s for your rented house",
    rentCollected = "You collected $%s from your tenants",
    alreadyOwned = "This house is already owned by someone else",
    storageDeposit = "Deposited %s into house storage",
    storageWithdraw = "Withdrew %s from house storage",
    storageRented = "Cannot access storage while house is rented out",
    storageFull = "House storage is full",
}

-- Rest / Sleep Settings (energy replenishment for owned, non-rented houses)
Config.Rest = {
    FadeDuration = 1500,          -- Screen fade duration (ms)
    WakeUpHour = 8,               -- Wake up at 8:00 AM
    WakeUpMinute = 0,
    WeatherTypes = {
        "CLEAR",
        "EXTRASUNNY",
        "CLOUDS",
        "OVERCAST",
        "SMOG",
        "FOGGY",
        "CLEARING"
    }
}

-- Houses
Config.DefaultHouses = {
    {
        name = "NorthConkerAvenue2045",
        label = "2045 North Conker Avenue",
        coords = {x = 372.796, y = 428.327, z = 144.685},
        price = 1500000,
    },
    {
        name = "RichardMajesticApt2",
        label = "Richard Majestic, Apt 2",
        coords = {x = -936.363, y = -379.165, z = 37.961},
        price = 1700000,
    },
    {
        name = "NorthConkerAvenue2044",
        label = "2044 North Conker Avenue",
        coords = {x = 346.964, y = 440.8, z = 146.702},
        price = 1500000,
    },
    {
        name = "WildOatsDrive",
        label = "3655 Wild Oats Drive",
        coords = {x = -176.003, y = 502.696, z = 136.421},
        price = 1500000,
    },
    {
        name = "HillcrestAvenue2862",
        label = "2862 Hillcrest Avenue",
        coords = {x = -686.554, y = 596.58, z = 142.641},
        price = 1500000,
    },
    {
        name = "MadWayneThunder",
        label = "2113 Mad Wayne Thunder",
        coords = {x = -1294.433, y = 454.955, z = 96.462},
        price = 1500000,
    },
    {
        name = "HillcrestAvenue2874",
        label = "2874 Hillcrest Avenue",
        coords = {x = -853.346, y = 696.678, z = 147.782},
        price = 1500000,
    },
    {
        name = "HillcrestAvenue2868",
        label = "2868 Hillcrest Avenue",
        coords = {x = -752.82, y = 620.494, z = 141.588},
        price = 1500000,
    },
    {
        name = "TinselTowersApt12",
        label = "Tinsel Towers, Apt 42",
        coords = {x = -618.299, y = 37.025, z = 42.58},
        price = 1700000,
    },
    {
        name = "House_997_0684",
        label = "House at Galaxy Boulevard",
        coords = {x = 997.0684, y = -729.3065, z = 57.8157},
        price = 60000,
    },
    {
        name = "House_970_8563",
        label = "House at Vinewood Hills",
        coords = {x = 970.8563, y = -701.0776, z = 58.4820},
        price = 80000,
    },
    {
        name = "House_943_5446",
        label = "House at Vinewood Heights",
        coords = {x = 943.5446, y = -653.5113, z = 58.4287},
        price = 70000,
    },
    {
        name = "House_886_7933",
        label = "House at Mirror Park",
        coords = {x = 886.7933, y = -608.1030, z = 58.4451},
        price = 70000,
    },
    {
        name = "House_844_1935",
        label = "House at El Burro Heights",
        coords = {x = 844.1935, y = -562.9882, z = 57.8339},
        price = 75000,
    },
    {
        name = "House_315_9535",
        label = "House at Rockford Hills",
        coords = {x = 315.9535, y = 501.3657, z = 153.1798},
        price = 250000,
    },
    {
        name = "House_119_3956",
        label = "House at Alta",
        coords = {x = 119.3956, y = 494.2162, z = 147.3429},
        price = 180000,
    },
    {
        name = "House_230_4202",
        label = "House at Vinewood",
        coords = {x = -230.4202, y = 488.3306, z = 128.7680},
        price = 200000,
    },
    {
        name = "House_312_1780",
        label = "House at Paleto Bay",
        coords = {x = -312.1780, y = 474.7194, z = 111.8241},
        price = 350000,
    },
    {
        name = "House_355_5244",
        label = "House at Chumash",
        coords = {x = -355.5244, y = 469.8810, z = 112.4893},
        price = 500000,
    },
    {
        name = "House_297_9718",
        label = "House at North Chumash",
        coords = {x = -297.9718, y = 380.2416, z = 112.0956},
        price = 260000,
    },
    {
        name = "House_371_8848",
        label = "House at Great Chaparral",
        coords = {x = -371.8848, y = 343.7934, z = 109.9427},
        price = 300000,
    },
    {
        name = "House_520_5744",
        label = "House at Harmony",
        coords = {x = -520.5744, y = 594.1549, z = 120.8365},
        price = 250000,
    },
    {
        name = "House_339_9535",
        label = "House at Grand Senora Desert",
        coords = {x = -339.9535, y = 625.8067, z = 171.3567},
        price = 700000,
    },
    {
        name = "House_700_7934",
        label = "House at Vinewood Hills Estate",
        coords = {x = -700.7934, y = 647.3782, z = 155.1753},
        price = 1100000,
    },
    {
        name = "House_1496_0587",
        label = "House at Palomino Highlands",
        coords = {x = -1496.0587, y = 437.2909, z = 112.4979},
        price = 450000,
    },
    {
        name = "House_1667_2349",
        label = "House at Pacific Bluffs",
        coords = {x = -1667.2349, y = -441.5058, z = 40.3557},
        price = 650000,
    },
    {
        name = "House_1490_5225",
        label = "House at Banham Canyon",
        coords = {x = -1490.5225, y = -658.6225, z = 29.0251},
        price = 10000,
    },
    {
        name = "House_1459_0474",
        label = "House at Morningwood",
        coords = {x = -1459.0474, y = -659.1971, z = 29.5830},
        price = 10000,
    },
    {
        name = "House_279_8749",
        label = "House at Downtown Vinewood",
        coords = {x = 279.8749, y = -1993.6436, z = 20.8038},
        price = 30000,
    },
    {
        name = "House_291_3394",
        label = "House at Strawberry",
        coords = {x = 291.3394, y = -1980.5107, z = 21.6005},
        price = 25000,
    },
    {
        name = "House_324_0533",
        label = "House at Cypress Flats",
        coords = {x = 324.0533, y = -1937.4679, z = 25.0190},
        price = 45000,
    },
    {
        name = "House_398_4351",
        label = "House at La Mesa",
        coords = {x = 398.4351, y = -1789.3022, z = 29.1593},
        price = 15000,
    },
    {
        name = "House_332_8919",
        label = "House at Davis",
        coords = {x = 332.8919, y = -1741.0638, z = 29.7306},
        price = 45000,
    },
    {
        name = "House_14_1733",
        label = "House at Mission Row",
        coords = {x = -14.1733, y = -1441.8700, z = 31.1015},
        price = 50000,
    },
    {
        name = "House_216_5681",
        label = "House at La Puerta",
        coords = {x = -216.5681, y = -1674.2344, z = 34.4632},
        price = 12000,
    },
    {
        name = "House_33_9881",
        label = "House at Little Seoul",
        coords = {x = -33.9881, y = -1847.2666, z = 26.1936},
        price = 30000,
    },
    {
        name = "House_130_4368",
        label = "House at Vespucci Beach",
        coords = {x = 130.4368, y = -1853.6016, z = 25.2348},
        price = 25000,
    },
    {
        name = "House_222_9197",
        label = "House at Rancho",
        coords = {x = 222.9197, y = -1702.7635, z = 29.6950},
        price = 25000,
    },
    {
        name = "House_151_5635",
        label = "House at Chamberlain Hills",
        coords = {x = 151.5635, y = -72.6534, z = 71.8602},
        price = 20000,
    },
    {
        name = "House_5_8142",
        label = "House at Burton",
        coords = {x = 5.8142, y = -9.2191, z = 70.1162},
        price = 35000,
    },
    {
        name = "House_930_7355",
        label = "House at Downtown",
        coords = {x = 930.7355, y = -245.1552, z = 69.0028},
        price = 40000,
    },
    {
        name = "House_1258_9746",
        label = "House at East Vinewood",
        coords = {x = 1258.9746, y = -1761.5757, z = 49.6583},
        price = 30000,
    },
    {
        name = "House_1230_7291",
        label = "House at El Burro Heights",
        coords = {x = 1230.7291, y = -1590.9597, z = 53.7661},
        price = 35000,
    },
    {
        name = "House_830_6603",
        label = "House at Richman",
        coords = {x = -830.6603, y = 115.0213, z = 55.8298},
        price = 650000,
    },
    {
        name = "House_998_0771",
        label = "House at West Vinewood",
        coords = {x = -998.0771, y = 157.7113, z = 62.3191},
        price = 550000,
    },
    {
        name = "House_902_5498",
        label = "House at Vinewood Hills",
        coords = {x = -902.5498, y = 191.4798, z = 69.4461},
        price = 750000,
    },
    {
        name = "House_1570_6803",
        label = "House at Pacific Bluffs",
        coords = {x = -1570.6803, y = 22.7236, z = 59.5539},
        price = 550000,
    },
    {
        name = "House_1467_4543",
        label = "House at Rockford Hills",
        coords = {x = -1467.4543, y = 35.1820, z = 54.5448},
        price = 750000,
    },
    {
        name = "House_929_8655",
        label = "House at Richman",
        coords = {x = -929.8655, y = 18.8081, z = 48.1326},
        price = 560000,
    },
    {
        name = "House_1117_0",
        label = "House at Mirror Park",
        coords = {x = 903.5582, y = -615.9465, z = 58.4533},
        price = 140000,
    },
    {
        name = "House_1347_8577",
        label = "House at Mirror Park",
        coords = {x = 1347.8577, y = -548.0790, z = 73.8916},
        price = 140000,
    },
    {
        name = "House_1388_3865",
        label = "House at Mirror Park",
        coords = {x = 1388.3865, y = -569.8406, z = 74.4965},
        price = 140000,
    },
    {
        name = "House_1385_4622",
        label = "House at Mirror Park",
        coords = {x = 1385.4622, y = -592.9026, z = 74.4854},
        price = 140000,
    },
    {
        name = "House_1367_2782",
        label = "House at Mirror Park",
        coords = {x = 1367.2782, y = -605.7484, z = 74.7109},
        price = 140000,
    },
    {
        name = "House_1323_7416",
        label = "House at Mirror Park",
        coords = {x = 1323.7416, y = -582.3893, z = 73.2464},
        price = 140000,
    },
    {
        name = "House_1372_6526",
        label = "House at Mirror Park",
        coords = {x = 1372.6526, y = -555.5178, z = 74.6858},
        price = 150000,
    },
    {
        name = "House_1341_8867",
        label = "House at Mirror Park",
        coords = {x = 1341.8867, y = -597.5314, z = 74.7009},
        price = 150000,
    },
}
