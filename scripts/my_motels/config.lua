Config = {}

-- Interaction settings
Config.InteractionDistance = 2.0

-- Map blip settings
Config.Blip = {
    sprite = 475,
    color = 5,
    scale = 0.8
}

-- 3D marker settings
Config.Marker = {
    type = 27,
    color = {r = 255, g = 150, b = 50, a = 100},
    scale = {x = 1.5, y = 1.5, z = 1.0},
    bobUpAndDown = false,
    rotate = true,
    zOffset = -1.0
}

-- Screen fade duration (ms)
Config.FadeDuration = 1500

-- Time to set after sleeping (8:00 AM)
Config.WakeUpHour = 8
Config.WakeUpMinute = 0

-- Possible weather types to randomly pick after sleeping
Config.WeatherTypes = {
    "CLEAR",
    "EXTRASUNNY",
    "CLOUDS",
    "OVERCAST",
    "SMOG",
    "FOGGY",
    "CLEARING"
}

-- Motel locations
Config.Motels = {
    {
        name = "The Pink Cage",
        price = 100,
        reception = {x = 313.0740, y = -225.4964, z = 54.2212},
        room = {x = 311.6368, y = -203.6905, z = 54.2218}
    },
    {
        name = "Perrera Beach",
        price = 150,
        reception = {x = -1493.9482, y = -674.1467, z = 28.6047},
        room = {x = -1471.5781, y = -668.1516, z = 29.5831}
    },
    {
        name = "Castenburg Hotels and Resorts",
        price = 500,
        reception = {x = -642.5031, y = -1132.6962, z = 11.9869},
        room = {x = -643.2257, y = -1133.3484, z = 11.2850, heading = 331.8894},
        vehicleAccess = true -- Player will be teleported with their vehicle
    },
    {
        name = "BilingsGate Motel",
        price = 100,
        reception = {x = 570.3508, y = -1746.9006, z = 29.2154},
        room = {x = 550.9393, y = -1775.8628, z = 29.3116}
    }
}
