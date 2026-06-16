Config = {}

-- Interaction settings
Config.InteractionDistance = 2.0

-- Map blip settings
Config.Blip = {
    sprite = 72,            -- Garage blip
    color = 1,              -- Red when not owned
    ownedColor = 2,         -- Green when owned
    scale = 0.9
}

-- 3D marker settings
Config.Marker = {
    type = 27,
    color = {r = 255, g = 215, b = 0, a = 100},
    scale = {x = 1.5, y = 1.5, z = 1.0},
    bobUpAndDown = false,
    rotate = true,
    zOffset = -1.0
}

-- Garage configuration
Config.Garage = {
    name = "Little Seoul Tuner Garage",
    price = 120000,
    coords = {x = -604.8282, y = -1056.7030, z = 21.7875}
}

-- Mechanic worker configuration
Config.Worker = {
    hireCost = 10000,
    profitMin = 200,
    profitMax = 500,
    interval = 600, -- seconds (10 minutes)

    mechanicModel = "s_m_m_autoshop_02",
    mechanicCoords = {x = -590.2465, y = -1048.5675, z = 21.5600, w = 275.4026},
    carSpawnCoords = {x = -592.2454, y = -1051.4241, z = 21.2952, w = 90.6692},

    carModels = {
        "sultan", "jester", "elegy2", "banshee", "comet2",
        "feltzer2", "futo", "penumbra", "dominator", "gauntlet"
    }
}

-- Drop-off repair configuration (owner only, oil depleted + damaged)
Config.DropOff = {
    vehicleCoords = {x = -595.9141, y = -1061.8027, z = 22.1245, w = 91.1365},
    playerCoords  = {x = -595.0194, y = -1059.3905, z = 22.5600, w = 116.7570},
    repairTime = 300,               -- seconds (5 minutes, online-only)
    interactionDistance = 3.0,
    markerDrawDistance = 30.0
}
