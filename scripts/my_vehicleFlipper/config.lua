Config = {}

-- NPC Configuration
Config.NPC = {
    coords = vector3(1208.6155, -3114.9727, 5.5569),
    heading = 271.6936,
    model = 's_m_m_autoshop_01',
    markerType = 27,
    markerColor = {r = 220, g = 50, b = 50, a = 100},
    markerSize = {x = 1.0, y = 1.0, z = 1.0},
    interactionDistance = 1.2,
    deliveryLocation = vector3(1203.8518, -3117.1685, 5.5403),
    tempVehicleModel = "blista",
    tempVehicleSpawnLocation = vector4(1196.7822, -3105.3691, 5.8507, 0.2782),
}

-- Global Mission Settings
Config.MissionDuration = 1800000 -- 30 minutes in milliseconds
Config.DeliveryRadius = 7.0
Config.CancelRefundPercent = 50
Config.ProximitySpawnDistance = 100.0
Config.VehicleDespawnDistance = 50.0

-- Cooldown Configuration (in minutes)
Config.Cooldowns = {
    [1] = 0,
    [2] = 10,
    [3] = 120
}

-- Damage Penalty Configuration
Config.DamageCalculation = {
    engineWeight = 0.6,
    bodyWeight = 0.4,
    minimumMultiplier = 0.5
}

-- Contract Tiers
Config.Tiers = {
    {
        id = 1,
        name = "Street Amateur",
        description = "Low to mid-range vehicles for beginners",
        minPrice = 26000,
        maxPrice = 100000,
        contractPrice = 5000,
        wantedLevel = 2,
        keepVehicleFeeMultiplier = 0.40,
        rewardMultiplier = 0.20,
        lockpick = {
            stages = 4,
            indicatorSpeed = 1.5,
            successZoneSize = 100
        },
        blipColor = 2,
        blipSprite = 326
    },
    {
        id = 2,
        name = "Professional Thief",
        description = "Sports cars and luxury vehicles",
        minPrice = 110000,
        maxPrice = 400000,
        contractPrice = 20000,
        wantedLevel = 3,
        keepVehicleFeeMultiplier = 0.40,
        rewardMultiplier = 0.20,
        lockpick = {
            stages = 8,
            indicatorSpeed = 1.5,
            successZoneSize = 70
        },
        blipColor = 47,
        blipSprite = 326
    },
    {
        id = 3,
        name = "Elite Operator",
        description = "High-end supercars and exotic vehicles",
        minPrice = 420000,
        maxPrice = 10000000,
        contractPrice = 80000,
        wantedLevel = 4,
        keepVehicleFeeMultiplier = 0.40,
        rewardMultiplier = 0.20,
        lockpick = {
            stages = 10,
            indicatorSpeed = 1.5,
            successZoneSize = 60
        },
        blipColor = 1,
        blipSprite = 326
    }
}

-- Vehicle Spawn Locations
Config.SpawnLocations = {
    {coords = vector3(-1184.2020, 326.1053, 70.1750), heading = 17.6817},
    {coords = vector3(-1205.9259, 320.1293, 70.4613), heading = 195.1615},
    {coords = vector3(-1391.8721, 80.7316, 53.4535), heading = 314.9323},
    {coords = vector3(-1870.3865, 191.0651, 83.8716), heading = 36.7753},
    {coords = vector3(-1934.8312, 182.6320, 84.1581), heading = 123.9420},
    {coords = vector3(-1989.4164, 296.3040, 91.3415), heading = 193.4890},
    {coords = vector3(-1858.7117, 328.4783, 88.2274), heading = 244.3274},
    {coords = vector3(-1794.4615, 347.9786, 88.1317), heading = 250.3867},
    {coords = vector3(-1943.1473, 385.0820, 96.0562), heading = 278.6653},
    {coords = vector3(-1910.2332, 406.6918, 95.8728), heading = 97.3640},
    {coords = vector3(-1885.2649, 622.9408, 129.5762), heading = 128.2701},
    {coords = vector3(-586.2554, 528.3542, 107.3354), heading = 221.6052},
    {coords = vector3(-1271.1893, 506.9263, 96.8747), heading = 178.2570},
    {coords = vector3(-869.0621, 318.4782, 83.5547), heading = 4.3159},
    {coords = vector3(-889.2078, 364.0840, 84.6076), heading = 1.6744},
    {coords = vector3(-1129.9161, 307.8975, 65.7625), heading = 168.1084},
    {coords = vector3(-1205.7174, 269.8027, 69.1251), heading = 261.5269},
    {coords = vector3(-1529.8446, 85.3010, 56.2489), heading = 339.1727},
    {coords = vector3(-1568.7090, 32.6548, 58.6909), heading = 256.4320},
    {coords = vector3(-1571.0363, -85.3780, 53.7106), heading = 277.7913},
    {coords = vector3(-128.9651, 1002.5933, 235.3093), heading = 15.8098},
    {coords = vector3(-163.4263, 928.6794, 235.2316), heading = 226.5076},
    {coords = vector3(-1375.0085, 453.2778, 104.5769), heading = 261.5457},
    {coords = vector3(315.0320, 567.7413, 154.0230), heading = 210.2742},
    {coords = vector3(319.0664, 497.0699, 152.2502), heading = 101.9418},
    {coords = vector3(64.7512, 456.0088, 146.3990), heading = 31.6936},
    {coords = vector3(55.9563, 467.8873, 146.3710), heading = 274.6314},
    {coords = vector3(-78.3937, 496.7294, 144.0307), heading = 337.1714},
    {coords = vector3(-123.1739, 509.1587, 142.5838), heading = 167.3375},
    {coords = vector3(-370.3651, 351.0523, 108.9202), heading = 110.6231},
    {coords = vector3(-404.2358, 337.0561, 108.2949), heading = 178.5672},
    {coords = vector3(-473.3662, 352.8577, 103.5806), heading = 149.9020},
    {coords = vector3(-359.0368, 513.6817, 119.2844), heading = 319.6052},
    {coords = vector3(-398.8503, 519.0386, 120.1045), heading = 172.3384},
    {coords = vector3(-542.5972, 544.8939, 110.1008), heading = 79.8550},
    {coords = vector3(-484.2513, 798.7479, 180.5021), heading = 340.6140},
    {coords = vector3(-551.1077, 830.8937, 197.3605), heading = 338.6435},
    {coords = vector3(-667.7462, 753.4286, 173.8356), heading = 29.8895},
    {coords = vector3(-695.4375, 704.9927, 156.8538), heading = 320.9599},
    {coords = vector3(-742.9911, 601.7471, 141.6195), heading = 62.6623},
    {coords = vector3(-753.8148, 627.3825, 142.1844), heading = 203.4808},
    {coords = vector3(-768.0120, 671.4154, 144.4091), heading = 39.3551},
    {coords = vector3(-1359.1130, 553.0984, 129.5138), heading = 54.5833},
    {coords = vector3(-1453.0778, 533.7262, 118.7851), heading = 75.4932},
    {coords = vector3(-1210.7821, 556.7115, 98.6832), heading = 2.7172},
    {coords = vector3(-1154.9221, 575.6596, 101.4101), heading = 192.0510},
    {coords = vector3(-1107.1497, 552.2207, 102.1586), heading = 211.1841},
    {coords = vector3(-871.3345, 499.9972, 89.5257), heading = 275.5409},
    {coords = vector3(-861.2972, 463.7256, 87.3297), heading = 139.1831},
    {coords = vector3(-845.3624, 458.9959, 87.3047), heading = 101.8446},
    {coords = vector3(-807.5854, 424.4561, 91.1449), heading = 339.0071},
    {coords = vector3(-634.0143, 526.8312, 109.2634), heading = 11.7801},
    {coords = vector3(-993.7186, 489.5850, 81.8431), heading = 165.2137},
    {coords = vector3(-1113.5936, 490.5027, 81.7679), heading = 167.0420},
    {coords = vector3(-1074.8909, 464.8119, 77.2745), heading = 147.3126},
    {coords = vector3(-1096.6871, 440.6773, 74.8624), heading = 226.9269},
    {coords = vector3(1295.1683, -567.9190, 71.2152), heading = 335.2992},
    {coords = vector3(1379.5773, -598.1265, 74.3379), heading = 51.1895},
    {coords = vector3(1391.4170, -576.3590, 74.3388), heading = 294.7092},
    {coords = vector3(1362.4240, -553.1705, 74.3380), heading = 335.0030},
    {coords = vector3(936.2535, -50.6206, 78.7641), heading = 229.7344},
    {coords = vector3(856.2175, -19.8374, 78.7640), heading = 54.6698},
    {coords = vector3(-950.4185, -899.7085, 1.7395), heading = 200.5609},
    {coords = vector3(-947.4933, -1096.9666, 1.7265), heading = 297.4934},
    {coords = vector3(-960.7030, -1101.1217, 1.7265), heading = 192.7092},
    {coords = vector3(-978.7848, -1114.4785, 1.7262), heading = 213.8935},
    {coords = vector3(-1048.5380, -1152.6177, 1.7349), heading = 28.6458},
    {coords = vector3(-1119.8781, -1237.2917, 2.5898), heading = 300.9724},
    {coords = vector3(-1131.1235, -1172.3086, 1.9328), heading = 123.5252},
    {coords = vector3(-1136.7281, -1165.5653, 2.2738), heading = 69.4528},
    {coords = vector3(-1165.6089, -1115.9362, 1.8620), heading = 26.6794},
    {coords = vector3(-1210.0493, -1025.3740, 1.7260), heading = 249.6346},
    {coords = vector3(-1135.6256, -1061.1066, 1.7266), heading = 293.3383},
    {coords = vector3(-1022.9092, -1015.4169, 1.7261), heading = 269.8819},
    {coords = vector3(-1038.4479, -1232.4188, 5.4228), heading = 291.6032},
    {coords = vector3(118.0150, -1898.2733, 23.0542), heading = 157.2944},
    {coords = vector3(168.4981, -1928.0640, 20.5888), heading = 27.3327},
    {coords = vector3(99.9366, -1974.7601, 20.4358), heading = 354.0358},
    {coords = vector3(41.5425, -1920.8408, 21.6607), heading = 315.6242},
    {coords = vector3(16.9639, -1884.4304, 23.2800), heading = 101.9074},
    {coords = vector3(24.0930, -1909.2133, 22.2147), heading = 127.1666},
    {coords = vector3(42.1128, -1840.7031, 23.2261), heading = 252.3538},
    {coords = vector3(322.4721, -1744.2571, 29.3669), heading = 48.4724},
    {coords = vector3(308.7965, -1744.2505, 29.2658), heading = 265.8176},
    {coords = vector3(302.1878, -1754.5426, 29.1614), heading = 36.9321},
    {coords = vector3(267.2500, -1745.6001, 29.5159), heading = 210.8549},
    {coords = vector3(210.9302, -1882.7025, 24.4259), heading = 136.7873},
    {coords = vector3(184.8656, -1867.0182, 24.4533), heading = 158.4576},
    {coords = vector3(226.8201, -1686.9553, 29.2966), heading = 217.8236},
    {coords = vector3(188.0194, -1694.1335, 29.1396), heading = 230.9920},
    {coords = vector3(1224.4312, -727.6890, 60.4964), heading = 174.6441},
    {coords = vector3(1221.2166, -704.2518, 60.7062), heading = 278.1375},
    {coords = vector3(1239.5405, -585.9667, 69.3291), heading = 66.4288},
    {coords = vector3(1256.0688, -624.5583, 69.3612), heading = 299.8860},
    {coords = vector3(1271.4879, -658.6450, 67.7370), heading = 118.2627},
    {coords = vector3(1274.6145, -672.6793, 65.9313), heading = 273.0399},
    {coords = vector3(1257.8688, -444.1426, 69.9834), heading = 101.9606},
    {coords = vector3(1258.2518, -420.0527, 69.4277), heading = 293.5235},
    {coords = vector3(950.3969, -653.7749, 57.9580), heading = 309.2754},
    {coords = vector3(919.7287, -637.3405, 57.8632), heading = 138.4845},
    {coords = vector3(914.0032, -626.1549, 58.0487), heading = 88.2694},
    {coords = vector3(856.9849, -520.4924, 57.3268), heading = 44.9494},
    {coords = vector3(943.5834, -468.5078, 61.2522), heading = 213.2399},
    {coords = vector3(971.7474, -451.6881, 62.4026), heading = 268.2471},
    {coords = vector3(1057.1722, -387.2164, 67.3776), heading = 220.1440},
    {coords = vector3(1008.1524, -591.0432, 58.9947), heading = 110.8084},
    {coords = vector3(916.5397, -524.1575, 58.9359), heading = 3.5537},
    {coords = vector3(946.6933, -510.3105, 60.2125), heading = 233.0208},
    {coords = vector3(977.4597, -526.1912, 60.1193), heading = 207.0429},
    {coords = vector3(844.8137, -191.9947, 72.6371), heading = 38.0966},
    {coords = vector3(522.1528, -1822.5161, 28.5031), heading = 234.2069},
    {coords = vector3(506.0708, -1842.7488, 27.6064), heading = 308.7126},
    {coords = vector3(432.0124, -1737.3484, 29.2469), heading = 48.7180},
    {coords = vector3(399.8630, -1753.6260, 29.2841), heading = 232.1299},
    {coords = vector3(375.2509, -1832.5363, 28.6895), heading = 225.0302},
    {coords = vector3(364.9791, -1809.4471, 29.0746), heading = 169.8366},
    {coords = vector3(275.4138, -1935.6316, 25.1721), heading = 233.3475},
    {coords = vector3(315.1719, -1941.5481, 24.6452), heading = 50.6392},
    {coords = vector3(299.5100, -1976.2478, 22.3236), heading = 236.0105},
    {coords = vector3(243.4547, -2032.7407, 18.3054), heading = 47.6073},
    {coords = vector3(1416.5551, -1503.3585, 60.1610), heading = 332.0409},
    {coords = vector3(1395.6708, -1533.1389, 57.5875), heading = 255.4763},
    {coords = vector3(1372.8932, -1522.7465, 57.0466), heading = 195.7837},
    {coords = vector3(1273.2607, -1609.9583, 54.1519), heading = 20.3144},
    {coords = vector3(1261.4694, -1632.6107, 53.5465), heading = 216.3149},
    {coords = vector3(1166.9800, -1646.3206, 36.9196), heading = 353.6617},
    {coords = vector3(1153.8761, -1651.8915, 36.5290), heading = 189.9301},
    {coords = vector3(1332.1897, -1731.5212, 56.1254), heading = 175.6534},
}

-- Plate Generation Format
Config.PlateFormat = {
    prefix = "",
    letters = 3,
    numbers = 3
}

-- Blip Configuration
Config.Blips = {
    npc = {
        sprite = 227,
        color = 1,
        scale = 0.9,
        label = "Vehicle Contracts"
    },
    spawnLocation = {
        sprite = 225,
        color = 5,
        scale = 0.8,
        label = "Target Vehicle Location"
    }
}

-- Text/Notification Messages
Config.Locale = {
    npc_help = "Press ~INPUT_CONTEXT~ to access ~r~Vehicle Contracts~s~",
    no_money = "You don't have enough money for this contract tier",
    contract_active = "You already have an active contract",
    no_spawns_available = "All vehicle locations are currently occupied. Try again later",
    contract_started = "Contract accepted. Use the temporary vehicle outside to locate the target vehicle.",
    vehicle_nearby = "Target vehicle detected nearby",
    lockpick_help = "Press ~INPUT_CONTEXT~ to attempt lockpicking",
    lockpick_success = "Vehicle unlocked successfully",
    lockpick_failed = "~r~Lockpick failed! The vehicle is still locked.",
    lockpick_cancelled = "~y~Lockpick cancelled. The vehicle is still locked.",
    police_called = "~r~The police have been called to your location!",
    mission_expired = "Contract expired. Vehicle location lost",
    vehicle_destroyed = "Contract vehicle destroyed. Mission failed",
    delivery_help = "Press ~INPUT_CONTEXT~ to complete delivery",
    contract_cancelled = "Contract cancelled. Refund: $%s",
    vehicle_kept = "Vehicle registered to you. Plate: %s",
    vehicle_sold = "Vehicle sold. Dirty money received: $%s",
    exit_vehicle_sell = "Exit the vehicle and move away to complete sale",
    insufficient_funds_keep = "Not enough cash to keep this vehicle",
    wanted_delivery_cancelled = "Contract cancelled! Cannot deliver with active wanted level",
    spawn_area_blocked = "~r~Cannot spawn vehicle — area is not clear. Move nearby players or vehicles away."
}
