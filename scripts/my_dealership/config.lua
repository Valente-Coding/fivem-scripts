Config = {}

-- Dealership interaction location
Config.DealerLocation = {
    x = -57.1711,
    y = -1096.5557,
    z = 26.4224,
    heading = 207.7741
}

-- Vehicle spawn location after purchase
Config.SpawnLocation = {
    x = -30.9492,
    y = -1089.8165,
    z = 25.8186,
    heading = 333.9832
}

-- Interaction settings
Config.InteractionDistance = 2.0 -- Distance to press E

-- Map blip settings
Config.Blip = {
    sprite = 225, -- Car icon (225 = garage/car shop)
    color = 0,    -- White
    scale = 0.8,  -- Size
    name = "Vehicle Dealership"
}

-- 3D marker settings
Config.Marker = {
    type = 27,    -- Cylinder marker (27 = vertical cylinder)
    color = {r = 0, g = 120, b = 255, a = 100}, -- Blue with transparency
    scale = {x = 1.5, y = 1.5, z = 1.0}, -- Width, depth, height
    bobUpAndDown = false,
    rotate = true,
    zOffset = -1.0 -- Z-axis offset to position marker on ground
}

-- Available vehicles for purchase
Config.Vehicles = {
    -- Compacts
    {
        model = "rhapsody",
        name = "Declasse Rhapsody",
        price = 7000,
        category = "Compacts"
    },
    {
        model = "asbo",
        name = "Maxwell Asbo",
        price = 8000,
        category = "Compacts"
    },
    {
        model = "prairie",
        name = "Bollokan Prairie",
        price = 9000,
        category = "Compacts"
    },
    {
        model = "brioso2",
        name = "Grotti Brioso 300",
        price = 11000,
        category = "Compacts"
    },
    {
        model = "panto",
        name = "Benefactor Panto",
        price = 12000,
        category = "Compacts"
    },
    {
        model = "weevil",
        name = "BF Weevil",
        price = 12000,
        category = "Compacts"
    },
    {
        model = "blista",
        name = "Dinka Blista",
        price = 13000,
        category = "Compacts"
    },
    {
        model = "dilettante",
        name = "Karin Dilettante",
        price = 15000,
        category = "Compacts"
    },
    {
        model = "issi2",
        name = "Weeny Issi",
        price = 18000,
        category = "Compacts"
    },
    {
        model = "club",
        name = "BF Club",
        price = 19000,
        category = "Compacts"
    },
    {
        model = "brioso",
        name = "Grotti Brioso R/A",
        price = 20000,
        category = "Compacts"
    },
    {
        model = "issi3",
        name = "Weeny Issi Classic",
        price = 25000,
        category = "Compacts"
    },
    {
        model = "kanjo",
        name = "Dinka Blista Kanjo",
        price = 26000,
        category = "Compacts"
    },
    
    -- Coupes
    {
        model = "kanjosj",
        name = "Dinka Kanjo SJ",
        price = 21000,
        category = "Coupes"
    },
    {
        model = "postlude",
        name = "Dinka Postlude",
        price = 22000,
        category = "Coupes"
    },
    {
        model = "fr36",
        name = "Fathom FR36",
        price = 32000,
        category = "Coupes"
    },
    {
        model = "jackal",
        name = "Ocelot Jackal",
        price = 34000,
        category = "Coupes"
    },
    {
        model = "cogcabrio",
        name = "Enus Cognoscenti Cabrio",
        price = 35000,
        category = "Coupes"
    },
    {
        model = "zion",
        name = "Ubermacht Zion",
        price = 35000,
        category = "Coupes"
    },
    {
        model = "zion2",
        name = "Ubermacht Zion Cabrio",
        price = 37000,
        category = "Coupes"
    },
    {
        model = "previon",
        name = "Karin Previon",
        price = 38000,
        category = "Coupes"
    },
    {
        model = "felon",
        name = "Lampadati Felon",
        price = 40000,
        category = "Coupes"
    },
    {
        model = "felon2",
        name = "Lampadati Felon GT",
        price = 43000,
        category = "Coupes"
    },
    {
        model = "eurosx32",
        name = "Annis Euros X32",
        price = 45000,
        category = "Coupes"
    },
    {
        model = "sentinel2",
        name = "Ubermacht Sentinel",
        price = 48000,
        category = "Coupes"
    },
    {
        model = "sentinel",
        name = "Ubermacht Sentinel XS",
        price = 50000,
        category = "Coupes"
    },
    {
        model = "exemplar",
        name = "Dewbauchee Exemplar",
        price = 50000,
        category = "Coupes"
    },
    {
        model = "oracle2",
        name = "Ubermacht Oracle",
        price = 52000,
        category = "Coupes"
    },
    {
        model = "oracle",
        name = "Ubermacht Oracle XS",
        price = 55000,
        category = "Coupes"
    },
    {
        model = "f620",
        name = "Ocelot F620",
        price = 60000,
        category = "Coupes"
    },
    {
        model = "windsor",
        name = "Enus Windsor",
        price = 120000,
        category = "Coupes"
    },
    {
        model = "windsor2",
        name = "Enus Windsor Drop",
        price = 130000,
        category = "Coupes"
    },
    
    -- Cycles
    {
        model = "bmx",
        name = "BMX",
        price = 500,
        category = "Cycles"
    },
    {
        model = "cruiser",
        name = "Cruiser",
        price = 700,
        category = "Cycles"
    },
    {
        model = "scorcher",
        name = "Scorcher",
        price = 800,
        category = "Cycles"
    },
    {
        model = "fixter",
        name = "Fixter",
        price = 900,
        category = "Cycles"
    },
    {
        model = "tribike",
        name = "Whippet Race Bike",
        price = 1000,
        category = "Cycles"
    },
    {
        model = "tribike2",
        name = "Endurex Race Bike",
        price = 1000,
        category = "Cycles"
    },
    {
        model = "tribike3",
        name = "Tri-Cycles Race Bike",
        price = 1000,
        category = "Cycles"
    },
    {
        model = "inductor",
        name = "Inductor",
        price = 2000,
        category = "Cycles"
    },
    {
        model = "inductor2",
        name = "Junk Energy Inductor",
        price = 2000,
        category = "Cycles"
    },
    
    -- Motorcycles
    {
        model = "faggio2",
        name = "Pegassi Faggio",
        price = 5000,
        category = "Motorcycles"
    },
    {
        model = "faggio",
        name = "Pegassi Faggio Sport",
        price = 8000,
        category = "Motorcycles"
    },
    {
        model = "manchez",
        name = "Maibatsu Manchez",
        price = 11000,
        category = "Motorcycles"
    },
    {
        model = "manchez2",
        name = "Maibatsu Manchez Scout",
        price = 13000,
        category = "Motorcycles"
    },
    {
        model = "enduro",
        name = "Dinka Enduro",
        price = 15000,
        category = "Motorcycles"
    },
    {
        model = "manchez3",
        name = "Maibatsu Manchez Scout C",
        price = 15000,
        category = "Motorcycles"
    },
    {
        model = "bagger",
        name = "Western Bagger",
        price = 16000,
        category = "Motorcycles"
    },
    {
        model = "wolfsbane",
        name = "Western Wolfsbane",
        price = 16000,
        category = "Motorcycles"
    },
    {
        model = "vindicator",
        name = "Dinka Vindicator",
        price = 17000,
        category = "Motorcycles"
    },
    {
        model = "akuma",
        name = "Dinka Akuma",
        price = 18000,
        category = "Motorcycles"
    },
    {
        model = "hexer",
        name = "LCC Hexer",
        price = 18000,
        category = "Motorcycles"
    },
    {
        model = "sanchez2",
        name = "Maibatsu Sanchez",
        price = 18000,
        category = "Motorcycles"
    },
    {
        model = "thrust",
        name = "Dinka Thrust",
        price = 18000,
        category = "Motorcycles"
    },
    {
        model = "sanchez",
        name = "Maibatsu Sanchez (livery)",
        price = 19000,
        category = "Motorcycles"
    },
    {
        model = "zombiea",
        name = "Western Zombie Bobber",
        price = 19000,
        category = "Motorcycles"
    },
    {
        model = "lectro",
        name = "Principe Lectro",
        price = 20000,
        category = "Motorcycles"
    },
    {
        model = "pcj",
        name = "Shitzu PCJ 600",
        price = 20000,
        category = "Motorcycles"
    },
    {
        model = "zombieb",
        name = "Western Zombie Chopper",
        price = 20000,
        category = "Motorcycles"
    },
    {
        model = "bf400",
        name = "Nagasaki BF400",
        price = 21000,
        category = "Motorcycles"
    },
    {
        model = "nemesis",
        name = "Principe Nemesis",
        price = 22000,
        category = "Motorcycles"
    },
    {
        model = "vader",
        name = "Shitzu Vader",
        price = 22000,
        category = "Motorcycles"
    },
    {
        model = "cliffhanger",
        name = "Western Cliffhanger",
        price = 23000,
        category = "Motorcycles"
    },
    {
        model = "esskey",
        name = "Pegassi Esskey",
        price = 23000,
        category = "Motorcycles"
    },
    {
        model = "innovation",
        name = "LCC Innovation",
        price = 23000,
        category = "Motorcycles"
    },
    {
        model = "ruffian",
        name = "Pegassi Ruffian",
        price = 24000,
        category = "Motorcycles"
    },
    {
        model = "diablous",
        name = "Principe Diabolus",
        price = 25000,
        category = "Motorcycles"
    },
    {
        model = "fcr",
        name = "Pegassi FCR 1000",
        price = 25000,
        category = "Motorcycles"
    },
    {
        model = "daemon2",
        name = "Western Daemon",
        price = 28000,
        category = "Motorcycles"
    },
    {
        model = "nightblade",
        name = "Western Nightblade",
        price = 29000,
        category = "Motorcycles"
    },
    {
        model = "shinobi",
        name = "Nagasaki Shinobi",
        price = 29000,
        category = "Motorcycles"
    },
    {
        model = "defiler",
        name = "Shitzu Defiler",
        price = 30000,
        category = "Motorcycles"
    },
    {
        model = "double",
        name = "Dinka Double-T",
        price = 30000,
        category = "Motorcycles"
    },
    {
        model = "vortex",
        name = "Pegassi Vortex",
        price = 30000,
        category = "Motorcycles"
    },
    {
        model = "stryder",
        name = "Nagasaki Stryder",
        price = 31000,
        category = "Motorcycles"
    },
    {
        model = "sovereign",
        name = "Western Sovereign",
        price = 32000,
        category = "Motorcycles"
    },
    {
        model = "bati",
        name = "Pegassi Bati 801",
        price = 35000,
        category = "Motorcycles"
    },
    {
        model = "hakuchou",
        name = "Shitzu Hakuchou",
        price = 35000,
        category = "Motorcycles"
    },
    {
        model = "powersurge",
        name = "Western Powersurge",
        price = 35000,
        category = "Motorcycles"
    },
    {
        model = "carbonrs",
        name = "Nagasaki Carbon RS",
        price = 36000,
        category = "Motorcycles"
    },
    {
        model = "reever",
        name = "Western Reever",
        price = 38000,
        category = "Motorcycles"
    },
    {
        model = "bati2",
        name = "Pegassi Bati 801RR",
        price = 39000,
        category = "Motorcycles"
    },
    {
        model = "chimera",
        name = "Nagasaki Chimera",
        price = 41000,
        category = "Motorcycles"
    },
    
    -- Muscle
    {
        model = "brigham",
        name = "Albany Brigham",
        price = 20000,
        category = "Muscle"
    },
    {
        model = "ratloader2",
        name = "Bravado Rat-Truck",
        price = 20000,
        category = "Muscle"
    },
    {
        model = "tulip",
        name = "Declasse Tulip",
        price = 21000,
        category = "Muscle"
    },
    {
        model = "hermes",
        name = "Albany Hermes",
        price = 22000,
        category = "Muscle"
    },
    {
        model = "slamvan",
        name = "Vapid Slamvan",
        price = 23000,
        category = "Muscle"
    },
    {
        model = "tampa",
        name = "Declasse Tampa",
        price = 23000,
        category = "Muscle"
    },
    {
        model = "vigero",
        name = "Declasse Vigero",
        price = 23000,
        category = "Muscle"
    },
    {
        model = "impaler",
        name = "Declasse Impaler",
        price = 24000,
        category = "Muscle"
    },
    {
        model = "ruiner",
        name = "Imponte Ruiner",
        price = 24000,
        category = "Muscle"
    },
    {
        model = "vamos",
        name = "Declasse Vamos",
        price = 24000,
        category = "Muscle"
    },
    {
        model = "virgo",
        name = "Albany Virgo",
        price = 24000,
        category = "Muscle"
    },
    {
        model = "eudora",
        name = "Willard Eudora",
        price = 25000,
        category = "Muscle"
    },
    {
        model = "gauntlet3",
        name = "Bravado Gauntlet Classic",
        price = 25000,
        category = "Muscle"
    },
    {
        model = "greenwood",
        name = "Bravado Greenwood",
        price = 25000,
        category = "Muscle"
    },
    {
        model = "impaler6",
        name = "Declasse Impaler LX",
        price = 26000,
        category = "Muscle"
    },
    {
        model = "stalion",
        name = "Declasse Stallion",
        price = 26000,
        category = "Muscle"
    },
    {
        model = "tulip2",
        name = "Declasse Tulip M-100",
        price = 26000,
        category = "Muscle"
    },
    {
        model = "virgo3",
        name = "Dundreary Virgo Classic",
        price = 26000,
        category = "Muscle"
    },
    {
        model = "hustler",
        name = "Vapid Hustler",
        price = 27000,
        category = "Muscle"
    },
    {
        model = "tampa4",
        name = "Declasse Tampa GT",
        price = 27000,
        category = "Muscle"
    },
    {
        model = "chino",
        name = "Vapid Chino",
        price = 28000,
        category = "Muscle"
    },
    {
        model = "picador",
        name = "Cheval Picador",
        price = 28000,
        category = "Muscle"
    },
    {
        model = "blade",
        name = "Vapid Blade",
        price = 29000,
        category = "Muscle"
    },
    {
        model = "gauntlet",
        name = "Bravado Gauntlet",
        price = 29000,
        category = "Muscle"
    },
    {
        model = "moonbeam",
        name = "Declasse Moonbeam",
        price = 29000,
        category = "Muscle"
    },
    {
        model = "tahoma",
        name = "Declasse Tahoma Coupe",
        price = 29000,
        category = "Muscle"
    },
    {
        model = "buccaneer",
        name = "Albany Buccaneer",
        price = 30000,
        category = "Muscle"
    },
    {
        model = "faction",
        name = "Willard Faction",
        price = 30000,
        category = "Muscle"
    },
    {
        model = "hotknife",
        name = "Vapid Hotknife",
        price = 30000,
        category = "Muscle"
    },
    {
        model = "clique2",
        name = "Vapid Clique Wagon",
        price = 31000,
        category = "Muscle"
    },
    {
        model = "phoenix",
        name = "Imponte Phoenix",
        price = 31000,
        category = "Muscle"
    },
    {
        model = "yosemite",
        name = "Declasse Yosemite",
        price = 31000,
        category = "Muscle"
    },
    {
        model = "impaler5",
        name = "Declasse Impaler SZ",
        price = 32000,
        category = "Muscle"
    },
    {
        model = "ruiner4",
        name = "Imponte Ruiner ZZ-8",
        price = 32000,
        category = "Muscle"
    },
    {
        model = "dukes",
        name = "Imponte Dukes",
        price = 33000,
        category = "Muscle"
    },
    {
        model = "arbitergt",
        name = "Imponte Arbiter GT",
        price = 34000,
        category = "Muscle"
    },
    {
        model = "nightshade",
        name = "Imponte Nightshade",
        price = 34000,
        category = "Muscle"
    },
    {
        model = "clique",
        name = "Vapid Clique",
        price = 35000,
        category = "Muscle"
    },
    {
        model = "dominator10",
        name = "Vapid Dominator FX",
        price = 35000,
        category = "Muscle"
    },
    {
        model = "sabregt",
        name = "Declasse Sabre Turbo",
        price = 35000,
        category = "Muscle"
    },
    {
        model = "broadway",
        name = "Classique Broadway",
        price = 36000,
        category = "Muscle"
    },
    {
        model = "dominator",
        name = "Vapid Dominator",
        price = 38000,
        category = "Muscle"
    },
    {
        model = "dominator7",
        name = "Vapid Dominator ASP",
        price = 40000,
        category = "Muscle"
    },
    {
        model = "gauntlet4",
        name = "Bravado Gauntlet Hellfire",
        price = 40000,
        category = "Muscle"
    },
    {
        model = "buffalo4",
        name = "Bravado Buffalo STX",
        price = 41000,
        category = "Muscle"
    },
    {
        model = "vigero2",
        name = "Declasse Vigero ZX",
        price = 43000,
        category = "Muscle"
    },
    {
        model = "deviant",
        name = "Schyster Deviant",
        price = 44000,
        category = "Muscle"
    },
    {
        model = "dominator8",
        name = "Vapid Dominator GTT",
        price = 45000,
        category = "Muscle"
    },
    {
        model = "ellie",
        name = "Vapid Ellie",
        price = 45000,
        category = "Muscle"
    },
    {
        model = "buffalo5",
        name = "Bravado Buffalo EVX",
        price = 52000,
        category = "Muscle"
    },
    {
        model = "vigero3",
        name = "Declasse Vigero ZX Convertible",
        price = 58000,
        category = "Muscle"
    },
    {
        model = "dominator3",
        name = "Vapid Dominator GTX",
        price = 60000,
        category = "Muscle"
    },
    {
        model = "coquette3",
        name = "Invetero Coquette BlackFin",
        price = 65000,
        category = "Muscle"
    },
    {
        model = "dominator9",
        name = "Vapid Dominator GT",
        price = 65000,
        category = "Muscle"
    },
    
    -- Off-Road
    {
        model = "blazer",
        name = "Nagasaki Blazer",
        price = 6000,
        category = "Off-Road"
    },
    {
        model = "bodhi2",
        name = "Canis Bodhi",
        price = 13000,
        category = "Off-Road"
    },
    {
        model = "dloader",
        name = "Bravado Duneloader",
        price = 16000,
        category = "Off-Road"
    },
    {
        model = "outlaw",
        name = "Nagasaki Outlaw",
        price = 19000,
        category = "Off-Road"
    },
    {
        model = "bifta",
        name = "BF Bifta",
        price = 21000,
        category = "Off-Road"
    },
    {
        model = "boor",
        name = "Karin Boor",
        price = 22000,
        category = "Off-Road"
    },
    {
        model = "rebel",
        name = "Karin Rusty Rebel",
        price = 22000,
        category = "Off-Road"
    },
    {
        model = "bfinjection",
        name = "BF Injection",
        price = 23000,
        category = "Off-Road"
    },
    {
        model = "dune",
        name = "BF Dune Buggy",
        price = 25000,
        category = "Off-Road"
    },
    {
        model = "kalahari",
        name = "Canis Kalahari",
        price = 25000,
        category = "Off-Road"
    },
    {
        model = "rebel2",
        name = "Karin Rebel",
        price = 25000,
        category = "Off-Road"
    },
    {
        model = "brawler",
        name = "Coil Brawler",
        price = 26000,
        category = "Off-Road"
    },
    {
        model = "l352",
        name = "Declasse Walton L35 Stock",
        price = 26000,
        category = "Off-Road"
    },
    {
        model = "yosemite1500",
        name = "Declasse Yosemite 1500",
        price = 29000,
        category = "Off-Road"
    },
    {
        model = "riata",
        name = "Vapid Riata",
        price = 30000,
        category = "Off-Road"
    },
    {
        model = "trophytruck",
        name = "Vapid Trophy Truck",
        price = 30000,
        category = "Off-Road"
    },
    {
        model = "l35",
        name = "Declasse Walton L35",
        price = 32000,
        category = "Off-Road"
    },
    {
        model = "yosemite3",
        name = "Declasse Yosemite Rancher",
        price = 33000,
        category = "Off-Road"
    },
    {
        model = "hellion",
        name = "Annis Hellion",
        price = 34000,
        category = "Off-Road"
    },
    {
        model = "vagrant",
        name = "Maxwell Vagrant",
        price = 36000,
        category = "Off-Road"
    },
    {
        model = "draugur",
        name = "Declasse Draugur",
        price = 37000,
        category = "Off-Road"
    },
    {
        model = "everon",
        name = "Karin Everon",
        price = 37000,
        category = "Off-Road"
    },
    {
        model = "caracara2",
        name = "Vapid Caracara 4x4",
        price = 38000,
        category = "Off-Road"
    },
    {
        model = "kamacho",
        name = "Canis Kamacho",
        price = 38000,
        category = "Off-Road"
    },
    {
        model = "rancherxl",
        name = "Declasse Rancher XL",
        price = 39000,
        category = "Off-Road"
    },
    {
        model = "freecrawler",
        name = "Canis Freecrawler",
        price = 40000,
        category = "Off-Road"
    },
    {
        model = "ratel",
        name = "Vapid Ratel",
        price = 42000,
        category = "Off-Road"
    },
    {
        model = "dubsta3",
        name = "Benefactor Dubsta 6x6",
        price = 43000,
        category = "Off-Road"
    },
    {
        model = "monstrociti",
        name = "Maibatsu MonstroCiti",
        price = 43000,
        category = "Off-Road"
    },
    {
        model = "sandking2",
        name = "Vapid Sandking SWB",
        price = 43000,
        category = "Off-Road"
    },
    {
        model = "firebolt",
        name = "Vapid Firebolt ASP",
        price = 44000,
        category = "Off-Road"
    },
    {
        model = "sandking",
        name = "Vapid Sandking XL",
        price = 45000,
        category = "Off-Road"
    },
    {
        model = "trophytruck2",
        name = "Vapid Desert Raid",
        price = 45000,
        category = "Off-Road"
    },
    {
        model = "terminus",
        name = "Canis Terminus",
        price = 46000,
        category = "Off-Road"
    },
    {
        model = "monster",
        name = "Vapid Liberator",
        price = 50000,
        category = "Off-Road"
    },
    {
        model = "marshall",
        name = "Cheval Marshall",
        price = 50000,
        category = "Off-Road"
    },
    
    -- Sedans
    {
        model = "warrener",
        name = "Vulcar Warrener",
        price = 6000,
        category = "Sedans"
    },
    {
        model = "ingot",
        name = "Vulcar Ingot",
        price = 8000,
        category = "Sedans"
    },
    {
        model = "warrener2",
        name = "Vulcar Warrener HKR",
        price = 10000,
        category = "Sedans"
    },
    {
        model = "minimus",
        name = "Annis Minimus",
        price = 15000,
        category = "Sedans"
    },
    {
        model = "stanier",
        name = "Vapid Stanier",
        price = 15000,
        category = "Sedans"
    },
    {
        model = "glendale",
        name = "Benefactor Glendale",
        price = 15000,
        category = "Sedans"
    },
    {
        model = "asea",
        name = "Declasse Asea",
        price = 16000,
        category = "Sedans"
    },
    {
        model = "regina",
        name = "Dundreary Regina",
        price = 18000,
        category = "Sedans"
    },
    {
        model = "premier",
        name = "Declasse Premier",
        price = 22000,
        category = "Sedans"
    },
    {
        model = "emperor",
        name = "Albany Emperor",
        price = 25000,
        category = "Sedans"
    },
    {
        model = "stratum",
        name = "Zirconium Stratum",
        price = 26000,
        category = "Sedans"
    },
    {
        model = "chavosv6",
        name = "Dinka Chavos V6",
        price = 27000,
        category = "Sedans"
    },
    {
        model = "asterope",
        name = "Karin Asterope",
        price = 28000,
        category = "Sedans"
    },
    {
        model = "hardy",
        name = "Annis Hardy",
        price = 28000,
        category = "Sedans"
    },
    {
        model = "asterope2",
        name = "Karin Asterope GZ",
        price = 35000,
        category = "Sedans"
    },
    {
        model = "surge",
        name = "Cheval Surge",
        price = 35000,
        category = "Sedans"
    },
    {
        model = "washington",
        name = "Albany Washington",
        price = 35000,
        category = "Sedans"
    },
    {
        model = "intruder",
        name = "Karin Intruder",
        price = 40000,
        category = "Sedans"
    },
    {
        model = "sentinel6",
        name = "Ubermacht Sentinel XS4",
        price = 42000,
        category = "Sedans"
    },
    {
        model = "fugitive",
        name = "Cheval Fugitive",
        price = 45000,
        category = "Sedans"
    },
    {
        model = "primo",
        name = "Albany Primo",
        price = 45000,
        category = "Sedans"
    },
    {
        model = "tailgater",
        name = "Obey Tailgater",
        price = 52000,
        category = "Sedans"
    },
    {
        model = "rhinehart",
        name = "Ubermacht Rhinehart",
        price = 55000,
        category = "Sedans"
    },
    {
        model = "schafter2",
        name = "Benefactor Schafter",
        price = 60000,
        category = "Sedans"
    },
    {
        model = "tailgater2",
        name = "Obey Tailgater S",
        price = 62000,
        category = "Sedans"
    },
    {
        model = "stafford",
        name = "Enus Stafford",
        price = 85000,
        category = "Sedans"
    },
    {
        model = "cinquemila",
        name = "Lampadati Cinquemila",
        price = 100000,
        category = "Sedans"
    },
    {
        model = "vorschlaghammer",
        name = "Benefactor Vorschlaghammer",
        price = 110000,
        category = "Sedans"
    },
    {
        model = "cog55",
        name = "Enus Cognoscenti 55",
        price = 180000,
        category = "Sedans"
    },
    {
        model = "cognoscenti",
        name = "Enus Cognoscenti",
        price = 200000,
        category = "Sedans"
    },
    {
        model = "deity",
        name = "Enus Deity",
        price = 230000,
        category = "Sedans"
    },
    {
        model = "superd",
        name = "Enus Super Diamond",
        price = 450000,
        category = "Sedans"
    },
    
    -- Sports
    {
        model = "blista2",
        name = "Dinka Blista Compact",
        price = 12000,
        category = "Sports"
    },
    {
        model = "sultan2",
        name = "Karin Sultan Classic",
        price = 15000,
        category = "Sports"
    },
    {
        model = "sultan",
        name = "Karin Sultan",
        price = 18000,
        category = "Sports"
    },
    {
        model = "futo",
        name = "Karin Futo",
        price = 22000,
        category = "Sports"
    },
    {
        model = "futo2",
        name = "Karin Futo GTX",
        price = 28000,
        category = "Sports"
    },
    {
        model = "buffalo",
        name = "Bravado Buffalo",
        price = 28000,
        category = "Sports"
    },
    {
        model = "penumbra",
        name = "Maibatsu Penumbra",
        price = 28000,
        category = "Sports"
    },
    {
        model = "euros",
        name = "Annis Euros",
        price = 32000,
        category = "Sports"
    },
    {
        model = "kuruma",
        name = "Karin Kuruma",
        price = 32000,
        category = "Sports"
    },
    {
        model = "issi7",
        name = "Weeny Issi Sport",
        price = 32000,
        category = "Sports"
    },
    {
        model = "calico",
        name = "Karin Calico GTF",
        price = 35000,
        category = "Sports"
    },
    {
        model = "remus",
        name = "Annis Remus",
        price = 35000,
        category = "Sports"
    },
    {
        model = "zr350",
        name = "Annis ZR350",
        price = 35000,
        category = "Sports"
    },
    {
        model = "flashgt",
        name = "Vapid Flash GT",
        price = 38000,
        category = "Sports"
    },
    {
        model = "sultan3",
        name = "Karin Sultan RS Classic",
        price = 38000,
        category = "Sports"
    },
    {
        model = "r300",
        name = "Annis 300R",
        price = 42000,
        category = "Sports"
    },
    {
        model = "fusilade",
        name = "Schyster Fusilade",
        price = 42000,
        category = "Sports"
    },
    {
        model = "penumbra2",
        name = "Maibatsu Penumbra FF",
        price = 42000,
        category = "Sports"
    },
    {
        model = "sugoi",
        name = "Dinka Sugoi",
        price = 42000,
        category = "Sports"
    },
    {
        model = "buffalo2",
        name = "Bravado Buffalo S",
        price = 45000,
        category = "Sports"
    },
    {
        model = "rt3000",
        name = "Dinka RT3000",
        price = 45000,
        category = "Sports"
    },
    {
        model = "coureur",
        name = "Penaud La Coureuse",
        price = 48000,
        category = "Sports"
    },
    {
        model = "omnis",
        name = "Obey Omnis",
        price = 48000,
        category = "Sports"
    },
    {
        model = "gb200",
        name = "Vapid GB200",
        price = 52000,
        category = "Sports"
    },
    {
        model = "elegy",
        name = "Annis Elegy Retro Custom",
        price = 55000,
        category = "Sports"
    },
    {
        model = "raptor",
        name = "BF Raptor",
        price = 55000,
        category = "Sports"
    },
    {
        model = "ruston",
        name = "Hijak Ruston",
        price = 55000,
        category = "Sports"
    },
    {
        model = "s95",
        name = "Karin S95",
        price = 58000,
        category = "Sports"
    },
    {
        model = "alpha",
        name = "Albany Alpha",
        price = 62000,
        category = "Sports"
    },
    {
        model = "jester",
        name = "Dinka Jester",
        price = 62000,
        category = "Sports"
    },
    {
        model = "cypher",
        name = "Ubermacht Cypher",
        price = 64000,
        category = "Sports"
    },
    {
        model = "banshee",
        name = "Bravado Banshee",
        price = 65000,
        category = "Sports"
    },
    {
        model = "coquette4",
        name = "Invetero Coquette D10",
        price = 68000,
        category = "Sports"
    },
    {
        model = "niobe",
        name = "Ubermacht Niobe",
        price = 68000,
        category = "Sports"
    },
    {
        model = "schwarzer",
        name = "Benefactor Schwartzer",
        price = 68000,
        category = "Sports"
    },
    {
        model = "vectre",
        name = "Emperor Vectre",
        price = 68000,
        category = "Sports"
    },
    {
        model = "coquette",
        name = "Invetero Coquette",
        price = 72000,
        category = "Sports"
    },
    {
        model = "growler",
        name = "Pfister Growler",
        price = 72000,
        category = "Sports"
    },
    {
        model = "revolter",
        name = "Ubermacht Revolter",
        price = 75000,
        category = "Sports"
    },
    {
        model = "komoda",
        name = "Lampadati Komoda",
        price = 78000,
        category = "Sports"
    },
    {
        model = "jester3",
        name = "Dinka Jester Classic",
        price = 78000,
        category = "Sports"
    },
    {
        model = "comet2",
        name = "Pfister Comet",
        price = 85000,
        category = "Sports"
    },
    {
        model = "envisage",
        name = "Bollokan Envisage",
        price = 85000,
        category = "Sports"
    },
    {
        model = "jester4",
        name = "Dinka Jester RR",
        price = 85000,
        category = "Sports"
    },
    {
        model = "panthere",
        name = "Toundra Panthere",
        price = 85000,
        category = "Sports"
    },
    {
        model = "raiden",
        name = "Coil Raiden",
        price = 85000,
        category = "Sports"
    },
    {
        model = "sentinel3",
        name = "Ubermacht Sentinel Classic",
        price = 85000,
        category = "Sports"
    },
    {
        model = "drafter",
        name = "Obey 8F Drafter",
        price = 86000,
        category = "Sports"
    },
    {
        model = "jugular",
        name = "Ocelot Jugular",
        price = 88000,
        category = "Sports"
    },
    {
        model = "locust",
        name = "Ocelot Locust",
        price = 92000,
        category = "Sports"
    },
    {
        model = "vstr",
        name = "Albany V-STR",
        price = 92000,
        category = "Sports"
    },
    {
        model = "banshee3",
        name = "Bravado Banshee GTS",
        price = 95000,
        category = "Sports"
    },
    {
        model = "comet3",
        name = "Pfister Comet Retro Custom",
        price = 95000,
        category = "Sports"
    },
    {
        model = "feltzer2",
        name = "Benefactor Feltzer",
        price = 95000,
        category = "Sports"
    },
    {
        model = "verlierer2",
        name = "Bravado Verlierer",
        price = 98000,
        category = "Sports"
    },
    {
        model = "coquette6",
        name = "Invetero Coquette D5",
        price = 108000,
        category = "Sports"
    },
    {
        model = "ninef",
        name = "Obey 9F",
        price = 115000,
        category = "Sports"
    },
    {
        model = "comet6",
        name = "Pfister Comet S2",
        price = 115000,
        category = "Sports"
    },
    {
        model = "elegy2",
        name = "Annis Elegy RH8",
        price = 118000,
        category = "Sports"
    },
    {
        model = "khamelion",
        name = "Hijak Khamelion",
        price = 118000,
        category = "Sports"
    },
    {
        model = "ninef2",
        name = "Obey 9F Cabrio",
        price = 125000,
        category = "Sports"
    },
    {
        model = "omnisegt",
        name = "Obey Omnis e-GT",
        price = 125000,
        category = "Sports"
    },
    {
        model = "comet7",
        name = "Pfister Comet S2 Cabrio",
        price = 125000,
        category = "Sports"
    },
    {
        model = "comet4",
        name = "Pfister Comet Safari",
        price = 135000,
        category = "Sports"
    },
    {
        model = "pariah",
        name = "Ocelot Pariah",
        price = 135000,
        category = "Sports"
    },
    {
        model = "sentinel5",
        name = "Ubermacht Sentinel GTS",
        price = 135000,
        category = "Sports"
    },
    {
        model = "neon",
        name = "Pfister Neon",
        price = 145000,
        category = "Sports"
    },
    {
        model = "schafter3",
        name = "Benefactor Schafter V12",
        price = 145000,
        category = "Sports"
    },
    {
        model = "tenf",
        name = "Obey 10F",
        price = 158000,
        category = "Sports"
    },
    {
        model = "comet5",
        name = "Pfister Comet SR",
        price = 165000,
        category = "Sports"
    },
    {
        model = "furoregt",
        name = "Lampadati Furore GT",
        price = 165000,
        category = "Sports"
    },
    {
        model = "imorgon",
        name = "Overflod Imorgon",
        price = 165000,
        category = "Sports"
    },
    {
        model = "rapidgt",
        name = "Dewbauchee Rapid GT",
        price = 165000,
        category = "Sports"
    },
    {
        model = "schlagen",
        name = "Benefactor Schlagen GT",
        price = 165000,
        category = "Sports"
    },
    {
        model = "rapidgt2",
        name = "Dewbauchee Rapid GT Convertible/Cabrio",
        price = 175000,
        category = "Sports"
    },
    {
        model = "schafter4",
        name = "Benefactor Schafter LWB",
        price = 175000,
        category = "Sports"
    },
    {
        model = "sm722",
        name = "Benefactor SM722",
        price = 180000,
        category = "Sports"
    },
    {
        model = "carbonizzare",
        name = "Grotti Carbonizzare",
        price = 185000,
        category = "Sports"
    },
    {
        model = "massacro",
        name = "Dewbauchee Massacro",
        price = 195000,
        category = "Sports"
    },
    {
        model = "paragon",
        name = "Enus Paragon R",
        price = 195000,
        category = "Sports"
    },
    {
        model = "surano",
        name = "Benefactor Surano",
        price = 195000,
        category = "Sports"
    },
    {
        model = "corsita",
        name = "Lampadati Corsita",
        price = 220000,
        category = "Sports"
    },
    {
        model = "neo",
        name = "Vysser Neo",
        price = 225000,
        category = "Sports"
    },
    {
        model = "paragon3",
        name = "Enus Paragon S",
        price = 225000,
        category = "Sports"
    },
    {
        model = "stingertt",
        name = "Grotti Stinger TT",
        price = 245000,
        category = "Sports"
    },
    {
        model = "bestiagts",
        name = "Grotti Bestia GTS",
        price = 265000,
        category = "Sports"
    },
    {
        model = "italirsx",
        name = "Grotti Itali RSX",
        price = 275000,
        category = "Sports"
    },
    {
        model = "italigto",
        name = "Grotti Itali GTO",
        price = 295000,
        category = "Sports"
    },
    {
        model = "seven70",
        name = "Dewbauchee Seven-70",
        price = 1500000,
        category = "Sports"
    },
    {
        model = "specter",
        name = "Dewbauchee Specter",
        price = 3500000,
        category = "Sports"
    },

    -- Sports Classic
    {
        model = "cheburek",
        name = "RUNE Cheburek",
        price = 8000,
        category = "Sports Classic"
    },
    {
        model = "nebula",
        name = "Vulcar Nebula Turbo",
        price = 12000,
        category = "Sports Classic"
    },
    {
        model = "manana",
        name = "Albany Manana",
        price = 18000,
        category = "Sports Classic"
    },
    {
        model = "fagaloa",
        name = "Vulcar Fagaloa",
        price = 22000,
        category = "Sports Classic"
    },
    {
        model = "dynasty",
        name = "Weeny Dynasty",
        price = 25000,
        category = "Sports Classic"
    },
    {
        model = "retinue",
        name = "Vapid Retinue",
        price = 35000,
        category = "Sports Classic"
    },
    {
        model = "peyote",
        name = "Vapid Peyote",
        price = 38000,
        category = "Sports Classic"
    },
    {
        model = "retinue2",
        name = "Vapid Retinue Mk II",
        price = 42000,
        category = "Sports Classic"
    },
    {
        model = "coquette2",
        name = "Invetero Coquette Classic",
        price = 45000,
        category = "Sports Classic"
    },
    {
        model = "uranus",
        name = "Vapid Uranus LozSpeed",
        price = 45000,
        category = "Sports Classic"
    },
    {
        model = "pigalle",
        name = "Lampadati Pigalle",
        price = 55000,
        category = "Sports Classic"
    },
    {
        model = "michelli",
        name = "Lampadati Michelli GT",
        price = 65000,
        category = "Sports Classic"
    },
    {
        model = "tornado",
        name = "Declasse Tornado",
        price = 75000,
        category = "Sports Classic"
    },
    {
        model = "zion3",
        name = "Ubermacht Zion Classic",
        price = 78000,
        category = "Sports Classic"
    },
    {
        model = "tornado2",
        name = "Declasse Tornado Convertible",
        price = 85000,
        category = "Sports Classic"
    },
    {
        model = "viseris",
        name = "Lampadati Viseris",
        price = 85000,
        category = "Sports Classic"
    },
    {
        model = "astrale",
        name = "Pfister Astrale",
        price = 95000,
        category = "Sports Classic"
    },
    {
        model = "coquette5",
        name = "Invetero Coquette D1",
        price = 95000,
        category = "Sports Classic"
    },
    {
        model = "savestra",
        name = "Annis Savestra",
        price = 125000,
        category = "Sports Classic"
    },
    {
        model = "cheetah2",
        name = "Grotti Cheetah Classic",
        price = 165000,
        category = "Sports Classic"
    },
    {
        model = "swinger",
        name = "Ocelot Swinger",
        price = 165000,
        category = "Sports Classic"
    },
    {
        model = "casco",
        name = "Lampadati Casco",
        price = 285000,
        category = "Sports Classic"
    },
    {
        model = "infernus2",
        name = "Pegassi Infernus Classic",
        price = 285000,
        category = "Sports Classic"
    },
    {
        model = "itali2",
        name = "Grotti Itali Classic",
        price = 425000,
        category = "Sports Classic"
    },
    {
        model = "btype",
        name = "Albany Roosevelt",
        price = 650000,
        category = "Sports Classic"
    },
    {
        model = "torero",
        name = "Pegassi Torero",
        price = 650000,
        category = "Sports Classic"
    },
    {
        model = "stinger",
        name = "Grotti Stinger",
        price = 750000,
        category = "Sports Classic"
    },
    {
        model = "btype3",
        name = "Albany Roosevelt Valor",
        price = 750000,
        category = "Sports Classic"
    },
    {
        model = "stingergt",
        name = "Grotti Stinger GT",
        price = 825000,
        category = "Sports Classic"
    },
    {
        model = "z190",
        name = "Karin 190z",
        price = 925000,
        category = "Sports Classic"
    },
    {
        model = "rapidgt3",
        name = "Dewbauchee Rapid GT Classic",
        price = 985000,
        category = "Sports Classic"
    },
    {
        model = "mamba",
        name = "Declasse Mamba",
        price = 1200000,
        category = "Sports Classic"
    },
    {
        model = "jb7002",
        name = "Dewbauchee JB 700W",
        price = 1250000,
        category = "Sports Classic"
    },
    {
        model = "feltzer3",
        name = "Benefactor Stirling GT",
        price = 1400000,
        category = "Sports Classic"
    },
    {
        model = "monroe",
        name = "Pegassi Monroe",
        price = 2100000,
        category = "Sports Classic"
    },
    {
        model = "turismo2",
        name = "Grotti Turismo Classic",
        price = 2800000,
        category = "Sports Classic"
    },
    {
        model = "gt750",
        name = "Grotti GT750",
        price = 3500000,
        category = "Sports Classic"
    },
    {
        model = "gt500",
        name = "Grotti GT500",
        price = 18000000,
        category = "Sports Classic"
    },
    {
        model = "ztype",
        name = "Truffade Z-Type",
        price = 40000000,
        category = "Sports Classic"
    },
    
    -- Super
    {
        model = "bullet",
        name = "Vapid Bullet",
        price = 145000,
        category = "Super"
    },
    {
        model = "voltic",
        name = "Coil Voltic",
        price = 150000,
        category = "Super"
    },
    {
        model = "vacca",
        name = "Pegassi Vacca",
        price = 240000,
        category = "Super"
    },
    {
        model = "banshee2",
        name = "Bravado Banshee 900R",
        price = 285000,
        category = "Super"
    },
    {
        model = "infernus",
        name = "Pegassi Infernus",
        price = 485000,
        category = "Super"
    },
    {
        model = "turismor",
        name = "Grotti Turismo R",
        price = 500000,
        category = "Super"
    },
    {
        model = "fmj",
        name = "Vapid FMJ",
        price = 585000,
        category = "Super"
    },
    {
        model = "fmj2",
        name = "Vapid FMJ MK V",
        price = 650000,
        category = "Super"
    },
    {
        model = "zentorno",
        name = "Pegassi Zentorno",
        price = 790000,
        category = "Super"
    },
    {
        model = "sultanrs",
        name = "Karin Sultan RS",
        price = 795000,
        category = "Super"
    },
    {
        model = "pfister811",
        name = "Pfister 811",
        price = 845000,
        category = "Super"
    },
    {
        model = "cheetah",
        name = "Grotti Cheetah",
        price = 850000,
        category = "Super"
    },
    {
        model = "penetrator",
        name = "Ocelot Penetrator",
        price = 880000,
        category = "Super"
    },
    {
        model = "entityxf",
        name = "Overflod Entity XF",
        price = 1100000,
        category = "Super"
    },
    {
        model = "italigtb",
        name = "Progen Itali GTB",
        price = 1189000,
        category = "Super"
    },
    {
        model = "emerus",
        name = "Progen Emerus",
        price = 1200000,
        category = "Super"
    },
    {
        model = "gp1",
        name = "Progen GP1",
        price = 1260000,
        category = "Super"
    },
    {
        model = "entity2",
        name = "Overflod Entity XXR",
        price = 1305000,
        category = "Super"
    },
    {
        model = "tempesta",
        name = "Pegassi Tempesta",
        price = 1329000,
        category = "Super"
    },
    {
        model = "xtreme",
        name = "Pfister X-treme",
        price = 1425000,
        category = "Super"
    },
    {
        model = "le7b",
        name = "Annis RE-7B",
        price = 1475000,
        category = "Super"
    },
    {
        model = "vagner",
        name = "Dewbauchee Vagner",
        price = 1535000,
        category = "Super"
    },
    {
        model = "reaper",
        name = "Pegassi Reaper",
        price = 1595000,
        category = "Super"
    },
    {
        model = "sc1",
        name = "Ubermacht SC1",
        price = 1603000,
        category = "Super"
    },
    {
        model = "deveste",
        name = "Principe Deveste Eight",
        price = 1795000,
        category = "Super"
    },
    {
        model = "autarch",
        name = "Overflod Autarch",
        price = 1800000,
        category = "Super"
    },
    {
        model = "suzume",
        name = "Overflod Suzume",
        price = 1885000,
        category = "Super"
    },
    {
        model = "cyclone",
        name = "Coil Cyclone",
        price = 1890000,
        category = "Super"
    },
    {
        model = "luiva",
        name = "Progen Luiva",
        price = 1890000,
        category = "Super"
    },
    {
        model = "zorrusso",
        name = "Pegassi Zorrusso",
        price = 1925000,
        category = "Super"
    },
    {
        model = "osiris",
        name = "Pegassi Osiris",
        price = 1950000,
        category = "Super"
    },
    {
        model = "taipan",
        name = "Cheval Taipan",
        price = 1980000,
        category = "Super"
    },
    {
        model = "cyclone2",
        name = "Coil Cyclone II",
        price = 2200000,
        category = "Super"
    },
    {
        model = "pipistrello",
        name = "Grotti Pipistrello",
        price = 2200000,
        category = "Super"
    },
    {
        model = "t20",
        name = "Progen T20",
        price = 2200000,
        category = "Super"
    },
    {
        model = "turismo3",
        name = "Grotti Turismo Omaggio",
        price = 2245000,
        category = "Super"
    },
    {
        model = "visione",
        name = "Grotti Visione",
        price = 2250000,
        category = "Super"
    },
    {
        model = "tigon",
        name = "Lampadati Tigon",
        price = 2310000,
        category = "Super"
    },
    {
        model = "thrax",
        name = "Truffade Thrax",
        price = 2325000,
        category = "Super"
    },
    {
        model = "entity3",
        name = "Overflod Entity MT",
        price = 2355000,
        category = "Super"
    },
    {
        model = "xa21",
        name = "Ocelot XA-21",
        price = 2375000,
        category = "Super"
    },
    {
        model = "adder",
        name = "Truffade Adder",
        price = 2500000,
        category = "Super"
    },
    {
        model = "nero",
        name = "Truffade Nero",
        price = 2500000,
        category = "Super"
    },
    {
        model = "tyrant",
        name = "Overflod Tyrant",
        price = 2515000,
        category = "Super"
    },
    {
        model = "tyrus",
        name = "Progen Tyrus",
        price = 2550000,
        category = "Super"
    },
    {
        model = "s80",
        name = "Annis S80RR",
        price = 2575000,
        category = "Super"
    },
    {
        model = "nero2",
        name = "Truffade Nero Custom",
        price = 2605000,
        category = "Super"
    },
    {
        model = "prototipo",
        name = "Grotti X80 Proto",
        price = 2700000,
        category = "Super"
    },
    {
        model = "furia",
        name = "Grotti Furia",
        price = 2750000,
        category = "Super"
    },
    {
        model = "ignus",
        name = "Pegassi Ignus",
        price = 2765000,
        category = "Super"
    },
    {
        model = "zeno",
        name = "Overflod Zeno",
        price = 2820000,
        category = "Super"
    },
    {
        model = "tezeract",
        name = "Pegassi Tezeract",
        price = 2825000,
        category = "Super"
    },
    {
        model = "krieger",
        name = "Benefactor Krieger",
        price = 2875000,
        category = "Super"
    },
    {
        model = "torero2",
        name = "Pegassi Torero XO",
        price = 2890000,
        category = "Super"
    },
    {
        model = "lm87",
        name = "Benefactor LM87",
        price = 2915000,
        category = "Super"
    },
    {
        model = "virtue",
        name = "Ocelot Virtue",
        price = 2980000,
        category = "Super"
    },
    {
        model = "champion",
        name = "Dewbauchee Champion",
        price = 3000000,
        category = "Super"
    },
    {
        model = "vigilante",
        name = "Grotti Vigilante",
        price = 3750000,
        category = "Super"
    },
    
    -- SUVs
    {
        model = "habanero",
        name = "Emperor Habanero",
        price = 24000,
        category = "SUVs"
    },
    {
        model = "gresley",
        name = "Bravado Gresley",
        price = 26000,
        category = "SUVs"
    },
    {
        model = "bjxl",
        name = "Karin BeeJay XL",
        price = 28000,
        category = "SUVs"
    },
    {
        model = "seminole",
        name = "Canis Seminole",
        price = 30000,
        category = "SUVs"
    },
    {
        model = "woodlander",
        name = "Karin Woodlander",
        price = 30000,
        category = "SUVs"
    },
    {
        model = "mesa",
        name = "Canis Mesa",
        price = 32000,
        category = "SUVs"
    },
    {
        model = "castigator",
        name = "Canis Castigator",
        price = 34000,
        category = "SUVs"
    },
    {
        model = "aleutian",
        name = "Vapid Aleutian",
        price = 38000,
        category = "SUVs"
    },
    {
        model = "landstalker",
        name = "Dundreary Landstalker",
        price = 38000,
        category = "SUVs"
    },
    {
        model = "issi8",
        name = "Weeny Issi Rally",
        price = 38000,
        category = "SUVs"
    },
    {
        model = "radi",
        name = "Vapid Radius",
        price = 40000,
        category = "SUVs"
    },
    {
        model = "contender",
        name = "Vapid Contender",
        price = 42000,
        category = "SUVs"
    },
    {
        model = "seminole2",
        name = "Canis Seminole Frontier",
        price = 42000,
        category = "SUVs"
    },
    {
        model = "dorado",
        name = "Bravado Dorado",
        price = 44000,
        category = "SUVs"
    },
    {
        model = "vivanite",
        name = "Karin Vivanite",
        price = 44000,
        category = "SUVs"
    },
    {
        model = "everon3",
        name = "Karin Everon RS",
        price = 46000,
        category = "SUVs"
    },
    {
        model = "baller",
        name = "Gallivanter Baller Old",
        price = 48000,
        category = "SUVs"
    },
    {
        model = "fq2",
        name = "Fathom FQ 2",
        price = 48000,
        category = "SUVs"
    },
    {
        model = "cavalcade",
        name = "Albany Cavalcade Old",
        price = 52000,
        category = "SUVs"
    },
    {
        model = "granger",
        name = "Declasse Granger",
        price = 58000,
        category = "SUVs"
    },
    {
        model = "landstalker2",
        name = "Dundreary Landstalker XL",
        price = 58000,
        category = "SUVs"
    },
    {
        model = "serrano",
        name = "Benefactor Serrano",
        price = 58000,
        category = "SUVs"
    },
    {
        model = "astron",
        name = "Pfister Astron",
        price = 62000,
        category = "SUVs"
    },
    {
        model = "patriot",
        name = "Mammoth Patriot",
        price = 62000,
        category = "SUVs"
    },
    {
        model = "granger2",
        name = "Declasse Granger 3600LX",
        price = 68000,
        category = "SUVs"
    },
    {
        model = "astron2",
        name = "Pfister Astron Custom",
        price = 68000,
        category = "SUVs"
    },
    {
        model = "rebla",
        name = "Ubermacht Rebla GTS",
        price = 68000,
        category = "SUVs"
    },
    {
        model = "iwagen",
        name = "Obey I-Wagen",
        price = 72000,
        category = "SUVs"
    },
    {
        model = "xls",
        name = "Benefactor XLS",
        price = 72000,
        category = "SUVs"
    },
    {
        model = "rocoto",
        name = "Obey Rocoto",
        price = 78000,
        category = "SUVs"
    },
    {
        model = "cavalcade2",
        name = "Albany Cavalcade New",
        price = 82000,
        category = "SUVs"
    },
    {
        model = "novak",
        name = "Lampadati Novak",
        price = 85000,
        category = "SUVs"
    },
    {
        model = "baller2",
        name = "Gallivanter Baller New",
        price = 88000,
        category = "SUVs"
    },
    {
        model = "baller3",
        name = "Gallivanter Baller LE",
        price = 95000,
        category = "SUVs"
    },
    {
        model = "cavalcade3",
        name = "Albany Cavalcade XL",
        price = 95000,
        category = "SUVs"
    },
    {
        model = "baller4",
        name = "Gallivanter Baller LE LWB",
        price = 105000,
        category = "SUVs"
    },
    {
        model = "baller7",
        name = "Gallivanter Baller ST",
        price = 115000,
        category = "SUVs"
    },
    {
        model = "baller8",
        name = "Gallivanter Baller ST-D",
        price = 125000,
        category = "SUVs"
    },
    {
        model = "dubsta",
        name = "Benefactor Dubsta",
        price = 130000,
        category = "SUVs"
    },
    {
        model = "dubsta2",
        name = "Benefactor Dubsta2",
        price = 145000,
        category = "SUVs"
    },
    {
        model = "huntley",
        name = "Enus Huntley S",
        price = 185000,
        category = "SUVs"
    },
    {
        model = "toros",
        name = "Pegassi Toros",
        price = 235000,
        category = "SUVs"
    },
    {
        model = "jubilee",
        name = "Enus Jubilee",
        price = 375000,
        category = "SUVs"
    },

    -- Utility
    {
        model = "flatbed",
        name = "MTL Flatbed",
        price = 59000,
        category = "Utility"
    },
}

-- Authorization settings
Config.AuthorizationTimeout = 60000 -- 60 seconds - auto-clear old authorizations
