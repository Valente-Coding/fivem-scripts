Config = {}

-- Base repair price (scales with damage)
Config.RepairPrice = 350

-- Repair shop locations (LSC)
Config.RepairLocations = {
    { coords = vector3(-1155.1377, -2006.1425, 13.1803) },
    { coords = vector3(731.4940, -1088.7712, 22.1690) },
    { coords = vector3(-339.0858, -136.8183, 39.0096) },
    { coords = vector3(1174.7692, 2640.1323, 37.7546) },
    { coords = vector3(110.6880, 6626.7266, 31.7872) }
}

-- Marker settings
Config.DrawDistance = 30.0
Config.InteractionDistance = 2.0

-- Oil change price (flat rate)
Config.OilChangePrice = 200

-- Drop-off repair (leave vehicle at shop)
Config.DropOffPrice = 2000
Config.DropOffTime = 300 -- seconds (5 minutes)

-- Sales tax rate (percentage)
Config.SalesTax = 7.5

Config.Debug = false
