Config = {}

Config.PostsPerPlayerWithoutLicense = 1
Config.PostsPerPlayerWithLicense = 10

Config.OfferTimer = 90000 -- Time between offer checks in milliseconds
Config.OfferTypes = {
    {priceDifferencePercent = 10, chance = 10, maxOffers = 3, chanceForFullPrice = 10, maxDiscount = 30},
    {priceDifferencePercent = 25, chance = 30, maxOffers = 10, chanceForFullPrice = 50, maxDiscount = 20},
    {priceDifferencePercent = 50, chance = 90, maxOffers = 20, chanceForFullPrice = 90, maxDiscount = 10},
}

Config.MeetingPoints = {
    {x = 261.2625, y = -776.3900, z = 30.6306, heading = 62.5626, vehicleSpawn = {x = 258.1111, y = -777.4037, z = 30.2372, heading = 40.4269}},
    {x = 42.5093, y = -844.2104, z = 30.8529, heading = 118.3304, vehicleSpawn = {x = 40.6932, y = -841.7465, z = 30.5114, heading = 159.8661}},
    {x = -294.2904, y = -987.0370, z = 31.0806, heading = 12.8692, vehicleSpawn = {x = -297.6506, y = -990.0378, z = 30.7055, heading = 340.6179}},
    {x = -317.0770, y = -713.5136, z = 32.8760, heading = 58.0687, vehicleSpawn = {x = -318.7021, y = -709.2964, z = 32.5392, heading = 91.5279}},
    {x = -474.5193, y = -609.9325, z = 31.3243, heading = 151.3444, vehicleSpawn = {x = -470.9622, y = -613.9595, z = 30.7986, heading = 179.8401}},
    {x = -725.8715, y = -64.8726, z = 41.7548, heading = 64.3939, vehicleSpawn = {x = -727.7195, y = -68.6298, z = 41.3750, heading = 26.7492}},
    {x = 355.2383, y = 277.2339, z = 103.2486, heading = 314.7522, vehicleSpawn = {x = 357.2280, y = 282.5652, z = 103.0290, heading = 248.2425}},
    {x = 648.8849, y = 273.5305, z = 103.2953, heading = 56.5329, vehicleSpawn = {x = 646.9783, y = 280.4271, z = 102.7826, heading = 148.4228}},
    {x = 1141.4629, y = -285.0427, z = 69.0468, heading = 272.7328, vehicleSpawn = {x = 1145.3094, y = -282.2060, z = 68.5981, heading = 270.1580}},
    {x = 1033.9208, y = -789.9857, z = 57.9013, heading = 346.1826, vehicleSpawn = {x = 1030.3182, y = -788.0658, z = 57.4985, heading = 309.2131}},
    {x = 540.5012, y = -1793.7460, z = 29.2628, heading = 309.3819, vehicleSpawn = {x = 545.4448, y = -1794.7301, z = 28.8204, heading = 324.9413}},
    {x = 220.4795, y = -1526.6965, z = 29.1518, heading = 303.9860, vehicleSpawn = {x = 224.2249, y = -1527.3788, z = 28.7913, heading = 307.3022}},
}

Config.NPCUsedCarsTimer = 60000 -- Time between NPC used car posting checks in milliseconds
Config.NPCUsedCarsExpireTime = 1800 -- 30 minutes in seconds before NPC cars expire
Config.NPCUsedCarsChance = 70 -- Percentage chance (0-100) that an NPC will post their car for sale each timer interval
Config.NPCUsedCarsMaxForSale = 30 -- Maximum number of NPC used cars available for sale at any time
Config.NPCUsedCarsMinDiscount = 0 -- Minimum discount percentage for NPC used cars
Config.NPCUsedCarsMaxDiscount = 30 -- Maximum discount percentage for NPC used cars
Config.MinOfferPercent = 70 -- Minimum offer percentage of asking price that will be accepted
Config.NPCOfferTypes = {
    {priceDifferencePercent = 10, chance = 80},
    {priceDifferencePercent = 25, chance = 30},
    {priceDifferencePercent = 50, chance = 10},
}
Config.NPCUsedCarsCategories = {
    "compacts",
    "coupes",
    "motorcycles",
    "muscle",
    "offroad",
    "sedans",
    "sports",
    "sportsclassic",
    "super",
    "suvs",
}

Config.BuyerBlip = {
    sprite = 792,
    color = 18,
    scale = 1.0,
}

Config.SellerBlip = {
    sprite = 792,
    color = 2,
    scale = 1.0,
}

Config.BuyerWaitingTime = 10 -- in minutes
Config.BuyerSpawnRange = 100 -- in meters
Config.BuyerMaleModels = {
    "a_m_m_acult_01",
    "a_m_m_afriamer_01",
    "a_m_m_beach_01",
    "a_m_m_beach_02",
    "a_m_m_bevhills_01",
    "a_m_m_bevhills_02",
    "a_m_m_business_01",
    "a_m_m_eastsa_01",
    "a_m_m_eastsa_02",
    "a_m_m_farmer_01",
    "a_m_m_fatlatin_01",
    "a_m_m_genfat_01",
    "a_m_m_genfat_02",
    "a_m_m_golfer_01",
    "a_m_m_hasjew_01",
    "a_m_m_hillbilly_01",
    "a_m_m_hillbilly_02",
    "a_m_m_indian_01",
    "a_m_m_ktown_01",
    "a_m_m_malibu_01",
    "a_m_m_mexcntry_01",
    "a_m_m_mexlabor_01",
    "a_m_m_og_boss_01",
    "a_m_m_paparazzi_01",
    "a_m_m_polynesian_01",
    "a_m_m_prolhost_01",
    "a_m_m_rurmeth_01",
    "a_m_m_salton_01",
    "a_m_m_salton_02",
    "a_m_m_salton_03",
    "a_m_m_salton_04",
    "a_m_m_skater_01",
    "a_m_m_skidrow_01",
    "a_m_m_socenlat_01",
    "a_m_m_soucent_01",
    "a_m_m_soucent_02",
    "a_m_m_soucent_03",
    "a_m_m_soucent_04",
    "a_m_m_stlat_02",
    "a_m_m_tennis_01",
    "a_m_m_tourist_01",
    "a_m_m_tramp_01",
    "a_m_m_trampbeac_01",
    "a_m_m_tranvest_01",
    "a_m_m_tranvest_02"
}

Config.BuyerFemaleModels = {
    "a_f_m_beach_01",
    "a_f_m_bevhills_01",
    "a_f_m_bevhills_02",
    "a_f_m_bodybuild_01",
    "a_f_m_business_02",
    "a_f_m_downtown_01",
    "a_f_m_eastsa_01",
    "a_f_m_eastsa_02",
    "a_f_m_fatbla_01",
    "a_f_m_fatcult_01",
    "a_f_m_fatwhite_01",
    "a_f_m_ktown_01",
    "a_f_m_ktown_02",
    "a_f_m_prolhost_01",
    "a_f_m_salton_01",
    "a_f_m_skidrow_01",
    "a_f_m_soucentmc_01",
    "a_f_m_soucent_01",
    "a_f_m_soucent_02",
    "a_f_m_tourist_01",
    "a_f_m_tramp_01",
    "a_f_m_trampbeac_01",
    "a_f_y_beach_01",
    "a_f_y_bevhills_01",
    "a_f_y_bevhills_02",
    "a_f_y_bevhills_03",
    "a_f_y_bevhills_04",
    "a_f_y_business_01",
    "a_f_y_business_02",
    "a_f_y_business_03",
    "a_f_y_business_04",
    "a_f_y_eastsa_01",
    "a_f_y_eastsa_02",
    "a_f_y_eastsa_03",
    "a_f_y_epsilon_01",
    "a_f_y_fitness_01",
    "a_f_y_fitness_02",
    "a_f_y_genhot_01",
    "a_f_y_golfer_01",
    "a_f_y_hiker_01",
    "a_f_y_hippie_01",
    "a_f_y_hipster_01",
    "a_f_y_hipster_02",
    "a_f_y_hipster_03",
    "a_f_y_hipster_04",
    "a_f_y_indian_01",
    "a_f_y_juggalo_01",
    "a_f_y_runner_01",
    "a_f_y_rurmeth_01",
    "a_f_y_scdressy_01",
    "a_f_y_skater_01",
    "a_f_y_soucent_01",
    "a_f_y_soucent_02",
    "a_f_y_soucent_03",
    "a_f_y_tennis_01",
    "a_f_y_topless_01",
    "a_f_y_tourist_01",
    "a_f_y_tourist_02",
    "a_f_y_vinewood_01",
    "a_f_y_vinewood_02",
    "a_f_y_vinewood_03",
    "a_f_y_vinewood_04"
}
