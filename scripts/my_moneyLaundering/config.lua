Config = {}

-- Boss ped location (the NPC you interact with)
Config.BossLocation = vector4(1391.4355, 1141.7544, 113.4432, 89.6695)

-- Bodyguard ped locations
Config.BodyGuards = {
    vector4(1391.0039, 1139.4128, 113.4433, 44.2654),
    vector4(1390.0081, 1143.0883, 113.3345, 130.3200)
}

-- Ped models
Config.BossModel = "g_m_importexport_01"
Config.BodyGuardModel = "s_m_y_blackops_01"

-- Interaction settings
Config.InteractionDistance = 2.5  -- Distance to press E

-- Laundering rate: player receives this percentage of their dirty money as clean cash
Config.LaunderRate = 0.30  -- 30%

-- Minimum amount of dirty money required to launder
Config.MinDirtyMoney = 100

-- Cooldown between laundering (seconds) - prevents spam
Config.Cooldown = 60

-- Map blip settings
Config.Blip = {
    sprite = 500,     -- Money bag icon
    color  = 1,       -- Red
    scale  = 0.8,
    name   = "Shady Contact"
}

-- Boss ped scenario (idle animation)
Config.BossScenario = "WORLD_HUMAN_STAND_IMPATIENT"
