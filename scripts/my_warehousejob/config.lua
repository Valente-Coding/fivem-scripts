Config = {}

Config.JobMenuCoord = vector4(152.8723, -3103.3269, 5.8963, 89.0579)

Config.BoxPickupPoints = {
    vector4(140.4967, -3111.3965, 5.8963, 181.2294),
    vector4(138.7535, -3111.8469, 5.8963, 179.9865),
    vector4(122.7341, -3112.0239, 5.9886, 181.7740),
    vector4(137.5310, -3100.4888, 5.8958, 272.3730),
    vector4(144.2891, -3102.0286, 5.8963, 354.9503),
    vector4(134.6055, -3111.4075, 5.8963, 186.5516)
}

Config.BoxDropoffPoints = {
    vector4(129.8775, -3079.5479, 5.8988, 356.6273),
    vector4(126.4262, -3074.5942, 5.9416, 0.9049),
    vector4(137.3327, -3074.7009, 5.8963, 2.4249),
    vector4(143.4873, -3074.7656, 5.8963, 358.6199),
    vector4(124.7388, -3075.8572, 5.9625, 2.3082)
}

Config.RequiredBoxes = 5
Config.JobTimeLimit = 15    -- minutes

Config.MaxDailyJobs = 5    -- max number of warehouse jobs per in-game day

Config.RequiredJobsForLevel = {
    [2] = 5,
    [3] = 11,
    [4] = 18,
    [5] = 26,
}

-- Payment brackets by level (ensures higher levels always earn more)
Config.PaymentBrackets = {
    [1] = { min = 100,  max = 250 },
    [2] = { min = 300,  max = 400 },
    [3] = { min = 500,  max = 700 },
    [4] = { min = 700,  max = 800 },
    [5] = { min = 800, max = 900 }
}

Config.CarryAnimation = {
    dict = "anim@heists@box_carry@",
    anim = "idle",
    flag = 50,
    prop = "hei_prop_heist_box",
    propPos = { 0.025, 0.08, 0.255 },
    propRot = { -145.0, -50.0, 0.0 }
}
