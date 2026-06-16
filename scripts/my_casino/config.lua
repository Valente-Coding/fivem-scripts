Config = {}

-- Outside door location (where the player interacts to enter)
Config.EntranceDoor = vector3(924.5820, 46.6883, 81.1063)

-- Inside casino location (where the player is teleported to)
Config.InsideCasino = vector4(1089.88, 206.42, -48.99, 340.0)

-- Exit location inside the casino (where the player interacts to leave)
Config.ExitDoor = vector3(1089.88, 206.42, -48.99)

-- Outside location (where the player is teleported when leaving)
Config.OutsideCasino = vector4(924.5820, 46.6883, 81.1063, 180.0)

-- Interaction distance
Config.InteractDistance = 2.0

-- Marker settings
Config.ShowMarker = true
Config.MarkerType = 1          -- Cylinder
Config.MarkerColor = {r = 255, g = 215, b = 0, a = 100}  -- Gold
Config.MarkerSize = vector3(1.0, 1.0, 0.5)

-- Blip settings
Config.ShowBlip = true
Config.BlipSprite = 679        -- Casino chip icon
Config.BlipColor = 46          -- Gold
Config.BlipScale = 0.8
Config.BlipName = "Diamond Casino"

-- Screen fade duration (ms)
Config.FadeDuration = 500

-- Casino interior IPLs to load
Config.IPLs = {
    "hei_dlc_windows_casino",
    "hei_dlc_casino_aircon",
    "vw_dlc_casino_door",
    "hei_dlc_casino_door",
    "vw_casino_main",
    "vw_casino_carpark",
    "vw_casino_garage",
}

-- Interior entity sets to activate (these are Rockstar's built-in casino props/decor)
Config.InteriorEntitySets = {
    "Int01_ba_bar_content",
    "Int01_ba_booze_01",
    "Int01_ba_booze_02",
    "Int01_ba_booze_03",
    "Int01_ba_dry_entrance",
    "int01_ba_equipment_setup",
    "Int01_ba_lights_setup",
    "Int01_ba_security_upgrade",
    "Int01_ba_style01",
    "Int01_ba_DJ01",
    "int01_ba_dj_lights_01",
}

-- ============================================================
-- Casino NPCs
-- ============================================================
Config.SpawnNPCs = true

-- Stagger NPC spawns over this many ms so they don't all pop in at once
Config.SpawnStaggerMs = 150

-- Exclusion zones: NPCs will NOT spawn or wander within these areas
Config.ExclusionZones = {
    {coords = vector3(1100.5007, 220.7430, -48.7487), radius = 5.0},
}

-- Casino-appropriate ped models (well-dressed patrons, staff)
Config.PatronModels = {
    "a_f_y_bevhills_01",
    "a_f_y_bevhills_02",
    "a_f_y_bevhills_03",
    "a_f_y_bevhills_04",
    "a_f_y_vinewood_01",
    "a_f_y_vinewood_02",
    "a_f_y_vinewood_03",
    "a_f_y_vinewood_04",
    "a_m_y_bevhills_01",
    "a_m_y_bevhills_02",
    "a_m_y_vinewood_01",
    "a_m_y_vinewood_02",
    "a_m_y_vinewood_03",
    "a_m_y_vinewood_04",
    "a_f_y_business_01",
    "a_f_y_business_02",
    "a_f_y_business_03",
    "a_f_y_business_04",
    "a_m_y_business_01",
    "a_m_y_business_02",
    "a_m_y_business_03",
    "a_f_y_smartdress_01",
    "a_m_m_bevhills_01",
    "a_m_m_bevhills_02",
    "a_f_m_bevhills_01",
    "a_f_m_bevhills_02",
}

-- Staff/dealer models (suited up)
Config.StaffModels = {
    "s_m_y_casino_01",
    "s_f_y_casino_01",
}

-- NPC types:
--   "static"  = stays in place doing a scenario (bartenders, dealers, security)
--   "wander"  = walks around between waypoints like a real patron
--   "social"  = stands in a group and chats
Config.CasinoNPCs = {
    -- === STAFF (static, scenario-locked) ===
    -- Front desk / reception
    {coords = vector4(1089.24, 206.03, -49.00, 341.2417), type = "static", scenario = "WORLD_HUMAN_CLIPBOARD",       group = "staff"},

    -- Bar staff
    {coords = vector4(1088.43, 228.42, -49.54, 120.0), type = "static", scenario = "WORLD_HUMAN_BARTENDER",       group = "staff"},
    {coords = vector4(1085.87, 226.30, -49.54, 60.0),  type = "static", scenario = "WORLD_HUMAN_BARTENDER",       group = "staff"},

    -- === PATRONS (static - hanging out at specific spots) ===
    -- Main floor - standing / using phone / drinking
    {coords = vector4(1100.04, 213.05, -49.54, 160.0), type = "static", scenario = "WORLD_HUMAN_STAND_IMPATIENT", group = "patron"},
    {coords = vector4(1108.33, 213.12, -49.54, 90.0),  type = "static", scenario = "WORLD_HUMAN_STAND_MOBILE",    group = "patron"},
    {coords = vector4(1098.45, 222.74, -49.54, 315.0), type = "static", scenario = "WORLD_HUMAN_DRINKING",        group = "patron"},
    {coords = vector4(1093.75, 214.60, -49.54, 45.0),  type = "static", scenario = "WORLD_HUMAN_STAND_IMPATIENT", group = "patron"},
    {coords = vector4(1115.42, 225.10, -49.54, 270.0), type = "static", scenario = "WORLD_HUMAN_STAND_MOBILE",    group = "patron"},
    {coords = vector4(1090.62, 230.10, -49.54, 200.0), type = "static", scenario = "WORLD_HUMAN_SMOKING",         group = "patron"},

    -- === PATRONS (stationary - standing around the floor) ===
    {coords = vector4(1101.75, 218.09, -49.54, 240.0), type = "static", scenario = "WORLD_HUMAN_STAND_IMPATIENT", group = "patron"},
    {coords = vector4(1111.21, 222.00, -49.54, 210.0), type = "static", scenario = "WORLD_HUMAN_DRINKING",        group = "patron"},
    {coords = vector4(1096.14, 232.56, -49.54, 0.0),   type = "static", scenario = "WORLD_HUMAN_STAND_MOBILE",    group = "patron"},
    {coords = vector4(1105.60, 206.40, -49.54, 270.0), type = "static", scenario = "WORLD_HUMAN_SMOKING",         group = "patron"},
    {coords = vector4(1084.80, 204.72, -49.54, 340.0), type = "static", scenario = "WORLD_HUMAN_STAND_IMPATIENT", group = "patron"},

    -- === SOCIAL GROUPS (stationary - chatting in place) ===
    {coords = vector4(1113.9731, 230.5786, -49.8408, 165.5162), type = "static", scenario = "WORLD_HUMAN_HANG_OUT_STREET", group = "patron"},
    {coords = vector4(1110.08, 217.88, -49.54, 135.0), type = "static", scenario = "WORLD_HUMAN_HANG_OUT_STREET", group = "patron"},
    {coords = vector4(1082.44, 210.55, -49.54, 355.0), type = "static", scenario = "WORLD_HUMAN_HANG_OUT_STREET", group = "patron"},
}

-- Wander waypoints: wandering NPCs will randomly walk between these
Config.WanderPoints = {
    vector3(1100.04, 213.05, -49.54),
    vector3(1108.33, 213.12, -49.54),
    vector3(1098.45, 222.74, -49.54),
    vector3(1111.21, 222.00, -49.54),
    vector3(1096.14, 232.56, -49.54),
    vector3(1090.62, 230.10, -49.54),
    vector3(1084.80, 204.72, -49.54),
    vector3(1105.60, 206.40, -49.54),
    vector3(1115.42, 225.10, -49.54),
    vector3(1088.43, 228.42, -49.54),
    vector3(1082.44, 210.55, -49.54),
}
