Config = {}

-- Interaction settings
Config.InteractionDistance = 2.0

-- Map blip settings
Config.Blip = {
    sprite = 225,           -- Car blip
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

-- Dealership configuration
Config.Dealership = {
    name = "Premium Deluxe Motorsport",
    price = 1500000,
    coords = {x = -1270.4941, y = -369.9997, z = 36.6351}
}
