Config = {}

-- The distance at which the script checks for garage doors
Config.CheckDistance = 20.0

-- Notification message shown when a door is blocked due to wanted level
Config.NotificationMessage = "The garage door remains closed due to your wanted level."

-- List of garage doors that should be blocked when player has wanted level
Config.GarageDoors = {
    {
        name = "Benny's Garage",
        hash = -427498890,
        coords = vector3(-205.6, -1310.6, 31.3)
    },
    {
        name = "LSC Burton",
        hash = -550347177,
        coords = vector3(-356.0905, -134.7714, 38.01)
    },
    {
        name = "LSC La Mesa",
        hash = -550347177,
        coords = vector3(731.8163, -1088.822, 22.16)
    },
    {
        name = "LSC Airport",
        hash = -550347177,
        coords = vector3(-1145.898, -1991.144, 13.16)
    },
    {
        name = "LSC Sandy Shores",
        hash = -822900180,
        coords = vector3(1174.656, 2644.159, 37.73)
    },
    {
        name = "LSC Paleto Bay",
        hash = -822900180,
        coords = vector3(110.8406, 6626.568, 32.26)
    }
}
