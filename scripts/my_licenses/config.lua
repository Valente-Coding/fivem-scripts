Config = {}

-- Townhall location (where players can buy licenses)
Config.LicenseCenterLocation = vector3(-545.0279, -204.2147, 38.2152)

-- License types and their prices
Config.Licenses = {
    fishing = {
        label = "Fishing License",
        price = 5000,
        description = "A permit allowing you to legally fish in San Andreas waters."
    },
    weapon = {
        label = "Weapons License",
        price = 10000,
        description = "Allows the legal purchase and possession of firearms from authorized dealers."
    },
    business = {
        label = "Business License",
        price = 20000,
        description = "Official permit to operate a legitimate business in San Andreas."
    },
    usedcars = {
        label = "Used Car Dealer License",
        price = 15000,
        description = "Allows you to list more vehicles for sale on the used car market."
    },
    driving = {
        label = "Driving License",
        price = 5000,
        description = "Required to purchase and operate motor vehicles. Without this, only bicycles are available."
    }
}

-- Blip settings
Config.Blip = {
    sprite = 525,
    color = 2,
    scale = 0.8,
    label = "License Center"
}

Config.Debug = false
