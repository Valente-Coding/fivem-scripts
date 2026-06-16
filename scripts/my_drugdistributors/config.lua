Config = {}

Config.Debug = false

-- Distributor Manager NPC
Config.DistributorManager = {
    location = vector3(-209.0765, -1600.4235, 33.8693),
    heading = 74.2700,
    model = "s_m_y_dealer_01",
    blip = {
        sprite = 500,
        color = 5,
        display = 4,
        scale = 0.8,
        name = "Drug Distributor Manager"
    }
}

-- Distributor Settings
Config.MaxDistributors = 20
Config.DistributorHireCost = 20000
Config.DistributorSellInterval = 600000 -- 10 minutes in milliseconds
Config.DistributorSellAmount = 1
Config.DistributorCutPercentage = 20

-- Required drug dealer level
Config.RequiredDrugDealerLevel = 5

-- UI Settings
Config.InteractionKey = 38 -- E key
Config.InteractionDistance = 3.0

-- Drug Types (large packages only)
Config.DrugTypes = {
    "large_weed",
    "large_cocaine",
    "large_meth"
}
