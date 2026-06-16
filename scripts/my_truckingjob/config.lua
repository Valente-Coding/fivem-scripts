Config = {}

Config.JobMenuCoord = vector3(-322.7776, -1399.1753, 31.7683)
Config.TruckSpawnCoord = vector4(-331.6531, -1400.0969, 30.3818, 214.7585)

Config.DeliveryCoords = {
    vector3(-326.5839, -1489.4310, 30.0690),
    vector3(-525.8328, -35.6983, 44.0140),
    vector3(-706.2498, -117.1924, 37.1036),
    vector3(90.7419, -215.3215, 53.9883),
    vector3(365.8245, -821.0516, 28.7908),
    vector3(332.4014, -1006.4673, 28.8002),
    vector3(-14.4015, -1094.9735, 26.1709),
    vector3(1136.4663, -295.0246, 68.3075),
    vector3(1163.2141, -337.0189, 68.0299),
    vector3(-1534.0732, -434.9851, 34.9393),
    vector3(-1508.0826, -382.5987, 40.4669),
    vector3(-557.8559, 302.3248, 82.7030),
    vector3(365.8462, 330.4352, 103.0579),
    vector3(-1817.2443, 802.6585, 137.9903),
}

Config.Levels = {
    [1] = { jobsRequired = 0 },
    [2] = { jobsRequired = 5 },
    [3] = { jobsRequired = 11 },
    [4] = { jobsRequired = 18 },
    [5] = { jobsRequired = 26 },
}

-- Payment brackets by level (ensures higher levels always earn more)
Config.PaymentBrackets = {
    [1] = { min = 300,  max = 600 },
    [2] = { min = 650,  max = 1000 },
    [3] = { min = 1050, max = 1500 },
    [4] = { min = 1550, max = 2100 },
    [5] = { min = 2150, max = 2800 }
}

Config.JobTimeLimit = 15    -- minutes

Config.MaxDailyJobs = 5    -- max number of trucking jobs per in-game day
