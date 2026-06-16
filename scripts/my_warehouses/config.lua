Config = {}

-- ════════════════════ GENERAL ════════════════════

Config.MaxOwnedWarehouses   = 5         -- max warehouses a player can own
Config.AutoSaveInterval     = 10        -- seconds between auto-saves to server
Config.InteractionDistance   = 1.5       -- distance to interact with markers
Config.MarkerType           = 20        -- marker visual type (20 = upside down cone)
Config.MarkerColor          = {r = 21, g = 163, b = 98, a = 180}
Config.DeliveryVehicle      = 'mule'    -- default delivery truck model

-- ════════════════════ BLIPS ════════════════════

Config.Blips = {
    owned = {
        sprite = 473,   -- warehouse icon
        color  = 2,     -- green
        scale  = 0.85,
        label  = 'My Warehouse',
    },
    available = {
        sprite = 473,
        color  = 0,     -- white
        scale  = 0.7,
        label  = 'Warehouse (For Sale)',
    },
    delivery = {
        sprite = 1,     -- standard blip
        color  = 5,     -- yellow
        scale  = 1.0,
        label  = 'Delivery Point',
    },
}

-- ════════════════════ WAREHOUSE LOCATIONS ════════════════════

Config.Warehouses = {
    {
        id           = 'warehouse_tracktor',
        name         = 'Tractor Parts Warehouse',
        price        = 100000,
        coords       = vector3(927.1158, -1560.2072, 30.9384),
        vehicleSpawn = vector4(919.1094, -1564.0961, 30.7610, 83.3023),
        returnMarker = vector3(919.1094, -1564.0961, 30.7610),
    },
    {
        id           = 'warehouse_cypress',
        name         = 'Cypress Flats Depot',
        price        = 100000,
        coords       = vector3(1019.0464, -2511.6931, 28.4805),
        vehicleSpawn = vector4(1009.4478, -2523.3420, 28.3091, 352.2664),
        returnMarker = vector3(1009.4478, -2523.3420, 28.3091),
    },
    {
        id           = 'warehouse_rusty',
        name         = 'Rusty Storage Facility',
        price        = 100000,
        coords       = vector3(257.2175, -3062.4014, 5.8630),
        vehicleSpawn = vector4(252.5904, -3059.9775, 5.7770, 129.7451),
        returnMarker = vector3(252.5904, -3059.9775, 5.7770),
    },
    {
        id           = 'warehouse_sandy',
        name         = 'Sandy Shores Warehouse',
        price        = 50000,
        coords       = vector3(636.6058, 2785.5146, 42.0099),
        vehicleSpawn = vector4(646.7418, 2783.3015, 41.9277, 185.5750),
        returnMarker = vector3(646.7418, 2783.3015, 41.9277),
    },
}

-- ════════════════════ DELIVERY POINTS ════════════════════

Config.DeliveryPoints = {
    { coords = vector3(-326.5839, -1489.4310, 30.0690),   name = 'La Mesa Drop-off' },
    { coords = vector3(-525.8328, -35.6983, 44.0140),     name = 'Burton Depot' },
    { coords = vector3(-706.2498, -117.1924, 37.1036),    name = 'West Vinewood' },
    { coords = vector3(90.7419, -215.3215, 53.9883),      name = 'Pillbox Hill' },
    { coords = vector3(365.8245, -821.0516, 28.7908),     name = 'Mission Row' },
    { coords = vector3(332.4014, -1006.4673, 28.8002),    name = 'Textile City' },
    { coords = vector3(-14.4015, -1094.9735, 26.1709),    name = 'Strawberry' },
    { coords = vector3(1136.4663, -295.0246, 68.3075),    name = 'Mirror Park North' },
    { coords = vector3(1163.2141, -337.0189, 68.0299),    name = 'Mirror Park South' },
    { coords = vector3(-1534.0732, -434.9851, 34.9393),   name = 'Del Perro' },
    { coords = vector3(-1508.0826, -382.5987, 40.4669),   name = 'Del Perro Heights' },
    { coords = vector3(-557.8559, 302.3248, 82.7030),     name = 'Morningwood' },
    { coords = vector3(365.8462, 330.4352, 103.0579),     name = 'Vinewood Hills' },
    { coords = vector3(-1817.2443, 802.6585, 137.9903),   name = 'Pacific Bluffs' },
}

-- ════════════════════ GAME BALANCE CONSTANTS ════════════════════

Config.Game = {
    INITIAL_CAPACITY         = 0,
    INITIAL_CLICK_POWER      = 0,
    INITIAL_DELIVERY_SLOTS   = 0,
    MAX_STORAGE_UPGRADES     = 20,
    STORAGE_PER_UPGRADE      = 100,
    MAX_BONUS_MULT           = 0.5,
    MANUAL_BONUS_MULT        = 0.75,
    BOX_BASE_VALUE           = 0,
    BOX_VALUE_PER_UPGRADE    = 2,
    BASE_ORDER_AMOUNT        = 1000,
    ORDER_AMOUNT_PER_UPGRADE = 500,
    BASE_ORDER_COST          = 200,
    BASE_ORDER_TIME          = 120,
    BASE_DELIVERY_TIME       = 30,
    DELIVERY_TIME_PER_BOX    = 0.5,
    DELIVERY_SPEED_FACTOR    = 0.85,
    ORDER_SPEED_FACTOR       = 0.85,
    MAT_BASE_COST            = 5,
}

-- ════════════════════ MATERIAL ORDER ════════════════════

Config.MaterialOrder = {
    id    = 'supply',
    name  = 'Supply Shipment',
    icon  = 'fa-solid fa-truck-ramp-box',
    color = 'bg-info',
}

-- ════════════════════ UPGRADES ════════════════════

Config.Upgrades = {
    -- Packaging
    { id = 'click_power',    cat = 'packaging',  name = 'Better Tools',         icon = 'fa-solid fa-screwdriver-wrench', color = 'bg-primary',  desc = '+1 box per click',                     baseCost = 50,    mult = 1.5, max = 10, initialLevel = 1 },
    { id = 'mat_efficiency', cat = 'packaging',  name = 'Material Efficiency',  icon = 'fa-solid fa-recycle',            color = 'bg-success',  desc = '-1 material cost per box (min 1)',      baseCost = 20000, mult = 3.5, max = 4,  initialLevel = 0 },
    { id = 'auto_pack',      cat = 'packaging',  name = 'Auto-Packer',          icon = 'fa-solid fa-robot',              color = 'bg-info',     desc = 'Packs 1 box/s per level automatically', baseCost = 20000, mult = 1,   max = 10, initialLevel = 0 },

    -- Warehouse
    { id = 'storage',        cat = 'warehouse',  name = 'Expand Warehouse',     icon = 'fa-solid fa-warehouse',          color = 'bg-warning',  desc = '+100 box capacity',                     baseCost = 150,   mult = 1.6, max = 20, initialLevel = 1 },
    { id = 'box_value',      cat = 'warehouse',  name = 'Premium Packaging',    icon = 'fa-solid fa-gem',                color = 'bg-danger',   desc = '+$2 per box value',                     baseCost = 500,   mult = 2,   max = 10, initialLevel = 1 },

    -- Delivery
    { id = 'del_slots',      cat = 'delivery',   name = 'Extra Truck Slot',     icon = 'fa-solid fa-truck-moving',       color = 'bg-primary',  desc = '+1 simultaneous delivery slot',          baseCost = 800,   mult = 2.2, max = 10, initialLevel = 1 },
    { id = 'del_speed',      cat = 'delivery',   name = 'Faster Routes',        icon = 'fa-solid fa-gauge-high',         color = 'bg-success',  desc = '-15% delivery time per level',           baseCost = 600,   mult = 2.0, max = 8,  initialLevel = 0 },
    { id = 'order_speed',    cat = 'delivery',   name = 'Express Shipping',     icon = 'fa-solid fa-truck-fast',         color = 'bg-warning',  desc = '-15% material order time per level',     baseCost = 400,   mult = 1.8, max = 8,  initialLevel = 0 },
    { id = 'order_capacity', cat = 'delivery',   name = 'Bigger Shipments',     icon = 'fa-solid fa-boxes-stacked',      color = 'bg-danger',   desc = '+500 materials per order',               baseCost = 1500,  mult = 2.5, max = 10, initialLevel = 0 },

    -- Automation
    { id = 'auto_order',     cat = 'automation',  name = 'Auto-Order Materials', icon = 'fa-solid fa-cart-shopping',     color = 'bg-warning',  desc = 'Auto orders when stock < 2x order amount', baseCost = 5000,  mult = 1.0, max = 1,  initialLevel = 0 },
    { id = 'auto_deliver',   cat = 'automation',  name = 'Auto-Deliver',         icon = 'fa-solid fa-paper-plane',       color = 'bg-info',     desc = 'Auto sends when the warehouse is full',    baseCost = 50000, mult = 1.0, max = 1,  initialLevel = 0 },
}

-- ════════════════════ DEFAULT WAREHOUSE STATE ════════════════════
-- Used when a player buys a new warehouse

Config.DefaultWarehouseState = {
    money           = 0,
    materials       = 0,
    boxes           = 0,
    incomingOrders  = {},
    activeDeliveries = {},
    upgrades        = {},       -- filled automatically from Config.Upgrades initialLevel
    stats           = {
        totalClicks          = 0,
        totalBoxesPacked     = 0,
        totalBoxesDelivered  = 0,
        totalMoneyEarned     = 0,
        totalMoneySpent      = 0,
        totalMaterialsOrdered = 0,
        totalDeliveries      = 0,
        maxCombo             = 1,
        playTime             = 0,
    },
    _nextId         = 1,
}

-- Helper: build initial upgrades table from definitions
function Config.BuildDefaultUpgrades()
    local ups = {}
    for _, u in ipairs(Config.Upgrades) do
        ups[u.id] = u.initialLevel
    end
    return ups
end
