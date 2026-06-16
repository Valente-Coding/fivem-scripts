Config = {}

-- Mechanic skill categories tracked per player
Config.Skills = {
    engine       = { label = "Engine" },
    transmission = { label = "Transmission" },
    clutch       = { label = "Clutch" },
    suspension   = { label = "Suspension" }
}

Config.StartingLevel = 1
Config.MaxLevel = 3

-- XP required to advance from `level` to `level + 1`
local xpForLevel = {
    [1] = 200, -- level 1 -> 2
    [2] = 500  -- level 2 -> 3
}

Config.XPForLevel = function(level)
    return xpForLevel[level] or math.huge
end

Config.Debug = false