Config = {}

-- Price to change clothes ($100 as requested)
Config.Price = 100

-- Interaction settings
Config.InteractDistance = 2.0
Config.DrawDistance = 10.0

-- Marker appearance
Config.MarkerType = 1
Config.MarkerSize = { x = 1.5, y = 1.5, z = 1.0 }
Config.MarkerColor = { r = 102, g = 102, b = 204 }

-- Blip settings
Config.Blip = {
    sprite = 73,        -- Clothing store icon
    color = 47,         -- Light pink
    scale = 0.8,
    name = "Clothing Store"
}

-- Shop locations (same as original esx_clotheshop)
Config.Shops = {
    vector3(72.3, -1399.1, 28.4),
    vector3(-703.8, -152.3, 36.4),
    vector3(-167.9, -299.0, 38.7),
    vector3(428.7, -800.1, 28.5),
    vector3(-829.4, -1073.7, 10.3),
    vector3(-1447.8, -242.5, 48.8),
    vector3(11.6, 6514.2, 30.9),
    vector3(123.6, -219.4, 53.6),
    vector3(1696.3, 4829.3, 41.1),
    vector3(618.1, 2759.6, 41.1),
    vector3(1190.6, 2713.4, 37.2),
    vector3(-1193.4, -772.3, 16.3),
    vector3(-3172.5, 1048.1, 19.9),
    vector3(-1108.4, 2708.9, 18.1)
}

-- Ped components to customize (clothing pieces)
-- id = GTA component ID, name = display name in menu
Config.Components = {
    { id = 1,  name = "Masks" },
    { id = 11, name = "Tops / Jackets" },
    { id = 8,  name = "Undershirts" },
    { id = 3,  name = "Torso" },
    { id = 4,  name = "Pants / Legs" },
    { id = 6,  name = "Shoes" },
    { id = 5,  name = "Bags / Parachute" },
    { id = 7,  name = "Accessories" },
    { id = 9,  name = "Body Armor" },
    { id = 10, name = "Decals" },
}

-- Ped props to customize (wearable accessories)
-- id = GTA prop ID, name = display name in menu
Config.Props = {
    { id = 0, name = "Hats / Helmets" },
    { id = 1, name = "Glasses" },
    { id = 2, name = "Ear Accessories" },
    { id = 6, name = "Watches" },
    { id = 7, name = "Bracelets" },
}
