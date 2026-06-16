Config = {}

-- ============================================================
-- DEALERSHIP (Purchase Location)
-- ============================================================
Config.Dealership = {
    name = "Sandy Shores Car Lot",
    price = 120000,
    coords = {x = 1224.7192, y = 2727.6084, z = 38.0044}
}

-- ============================================================
-- LOT AREA (Where vehicles are placed for sale)
-- ============================================================
Config.LotCenter = {x = 1223.9531, y = 2711.9836, z = 38.0059}
Config.LotRadius = 50.0

-- ============================================================
-- NPC SALESMAN (Spawns after purchase)
-- ============================================================
Config.Salesman = {
    model = 'a_m_y_business_01',
    coords = {x = 1222.1750, y = 2726.6868, z = 37.0042},
    heading = 206.5334
}

-- ============================================================
-- SALE SETTINGS
-- ============================================================
Config.SellPercent = 0.90           -- 90% of market value
Config.SaleCheckInterval = 30       -- Minutes between auto-sell checks
Config.SaleChancePerCheck = 0.03    -- 3% chance per vehicle per check (~1/day)
Config.MaxSalesPerDay = 2           -- Maximum vehicles that can sell in one day

-- ============================================================
-- INTERACTION
-- ============================================================
Config.InteractionDistance = 2.0
Config.NpcInteractionDistance = 2.5

-- ============================================================
-- MAP BLIP
-- ============================================================
Config.Blip = {
    sprite = 225,
    color = 1,          -- Red when not owned
    ownedColor = 2,     -- Green when owned
    scale = 0.9
}

-- ============================================================
-- 3D MARKER (Purchase location)
-- ============================================================
Config.Marker = {
    type = 27,
    color = {r = 255, g = 215, b = 0, a = 100},
    scale = {x = 1.5, y = 1.5, z = 1.0},
    bobUpAndDown = false,
    rotate = true,
    zOffset = -1.0
}
