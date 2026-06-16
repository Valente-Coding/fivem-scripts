Config = {}

-- ============================================================
-- Shop Locations
-- ============================================================
Config.Locations = {
    {
        name      = "Pawn & Jewelry",
        coords    = vector3(183.2289, -1319.6383, 29.3190),
        type      = "low",
        maxPrice  = 50000,
        blipColor = 46, -- orange
    },
    {
        name      = "Vinewood Pawn & Jewelry",
        coords    = vector3(-1459.7491, -414.8354, 35.7106),
        type      = "high",
        maxPrice  = 1000000,
        blipColor = 5, -- yellow
    },
}

-- ============================================================
-- Blip Settings
-- ============================================================
Config.Blip = {
    sprite = 267,  -- jewelry / pawn
    scale  = 0.7,
    name   = "Pawn Shop",
}

-- ============================================================
-- Interaction Settings
-- ============================================================
Config.MarkerDistance   = 15.0
Config.InteractDistance = 2.0

Config.Marker = {
    type   = 20,
    scale  = vector3(0.5, 0.5, 0.5),
    color  = { r = 245, g = 158, b = 11, a = 200 }, -- amber
    bob    = true,
    rotate = true,
}

-- ============================================================
-- Pawn Shop Items  (name must match my_inventory Config.Items)
-- price = what the pawn shop pays the player
-- ============================================================
Config.Items = {
    -- Tier 1: $500 - $5,000
    { name = "old_watch",              label = "Old Watch",              price = 500 },
    { name = "silver_ring",            label = "Silver Ring",            price = 650 },
    { name = "brass_compass",          label = "Brass Compass",         price = 800 },
    { name = "vintage_lighter",        label = "Vintage Lighter",        price = 900 },
    { name = "copper_bracelet",        label = "Copper Bracelet",        price = 1000 },
    { name = "old_coins",              label = "Old Coins",              price = 1100 },
    { name = "pewter_flask",           label = "Pewter Flask",           price = 1200 },
    { name = "broken_necklace",        label = "Broken Necklace",        price = 1350 },
    { name = "tarnished_locket",       label = "Tarnished Locket",       price = 1500 },
    { name = "vintage_cufflinks",      label = "Vintage Cufflinks",      price = 1650 },
    { name = "old_pocket_watch",       label = "Old Pocket Watch",       price = 1800 },
    { name = "silver_spoon",           label = "Silver Spoon",           price = 2000 },
    { name = "bronze_medal",           label = "Bronze Medal",           price = 2100 },
    { name = "costume_jewelry",        label = "Costume Jewelry",        price = 2250 },
    { name = "old_brooch",             label = "Old Brooch",             price = 2400 },
    { name = "vintage_postcard",       label = "Vintage Postcard",       price = 2500 },
    { name = "antique_key",            label = "Antique Key",            price = 2700 },
    { name = "silver_thimble",         label = "Silver Thimble",         price = 2900 },
    { name = "old_harmonica",          label = "Old Harmonica",          price = 3000 },
    { name = "brass_buckle",           label = "Brass Buckle",           price = 3200 },
    { name = "vintage_pen",            label = "Vintage Pen",            price = 3400 },
    { name = "copper_ring",            label = "Copper Ring",            price = 3500 },
    { name = "old_figurine",           label = "Old Figurine",           price = 3700 },
    { name = "tin_music_box",          label = "Tin Music Box",          price = 3900 },
    { name = "worn_bracelet",          label = "Worn Bracelet",          price = 4100 },
    { name = "vintage_badge",          label = "Vintage Badge",          price = 4300 },
    { name = "antique_button",         label = "Antique Button",         price = 4500 },
    { name = "old_cameo",              label = "Old Cameo",              price = 4700 },
    { name = "silver_chain",           label = "Silver Chain",           price = 4850 },
    { name = "brass_ring",             label = "Brass Ring",             price = 5000 },

    -- Tier 2: $5,001 - $25,000
    { name = "gold_bracelet",          label = "Gold Bracelet",          price = 5500 },
    { name = "pearl_earrings",         label = "Pearl Earrings",         price = 6000 },
    { name = "antique_clock",          label = "Antique Clock",          price = 6500 },
    { name = "sapphire_pendant",       label = "Sapphire Pendant",       price = 7000 },
    { name = "ivory_chess_set",        label = "Ivory Chess Set",        price = 7500 },
    { name = "gold_ring",              label = "Gold Ring",              price = 8000 },
    { name = "vintage_wine",           label = "Vintage Wine",           price = 8500 },
    { name = "crystal_vase",           label = "Crystal Vase",           price = 9000 },
    { name = "jade_figurine",          label = "Jade Figurine",          price = 9500 },
    { name = "pearl_necklace",         label = "Pearl Necklace",         price = 10000 },
    { name = "gold_cufflinks",         label = "Gold Cufflinks",         price = 10500 },
    { name = "antique_mirror",         label = "Antique Mirror",         price = 11000 },
    { name = "silver_candelabra",      label = "Silver Candelabra",      price = 11500 },
    { name = "ruby_ring",              label = "Ruby Ring",              price = 12000 },
    { name = "gold_pocket_watch",      label = "Gold Pocket Watch",      price = 13000 },
    { name = "antique_compass",        label = "Antique Compass",        price = 14000 },
    { name = "crystal_decanter",       label = "Crystal Decanter",       price = 15000 },
    { name = "opal_earrings",          label = "Opal Earrings",          price = 16000 },
    { name = "gold_chain",             label = "Gold Chain",             price = 17000 },
    { name = "vintage_camera",         label = "Vintage Camera",         price = 18000 },
    { name = "antique_telescope",      label = "Antique Telescope",      price = 19000 },
    { name = "silver_tea_set",         label = "Silver Tea Set",         price = 20000 },
    { name = "garnet_brooch",          label = "Garnet Brooch",          price = 21000 },
    { name = "gold_locket",            label = "Gold Locket",            price = 22000 },
    { name = "vintage_typewriter",     label = "Vintage Typewriter",     price = 23000 },
    { name = "porcelain_figurine",     label = "Porcelain Figurine",     price = 23500 },
    { name = "amethyst_pendant",       label = "Amethyst Pendant",       price = 24000 },
    { name = "gold_tiara",             label = "Gold Tiara",             price = 24500 },
    { name = "antique_globe",          label = "Antique Globe",          price = 24800 },
    { name = "topaz_ring",             label = "Topaz Ring",             price = 25000 },

    -- Tier 3: $25,001 - $50,000
    { name = "diamond_ring",           label = "Diamond Ring",           price = 26000 },
    { name = "emerald_brooch",         label = "Emerald Brooch",         price = 27000 },
    { name = "platinum_watch",         label = "Platinum Watch",         price = 28000 },
    { name = "diamond_earrings",       label = "Diamond Earrings",       price = 29000 },
    { name = "gold_bar",               label = "Gold Bar",               price = 30000 },
    { name = "emerald_ring",           label = "Emerald Ring",           price = 31000 },
    { name = "platinum_bracelet",      label = "Platinum Bracelet",      price = 32000 },
    { name = "antique_painting",       label = "Antique Painting",       price = 33000 },
    { name = "ruby_necklace",          label = "Ruby Necklace",          price = 34000 },
    { name = "diamond_bracelet",       label = "Diamond Bracelet",       price = 35000 },
    { name = "gold_sculpture",         label = "Gold Sculpture",         price = 36000 },
    { name = "sapphire_necklace",      label = "Sapphire Necklace",      price = 37000 },
    { name = "platinum_ring",          label = "Platinum Ring",          price = 38000 },
    { name = "rare_first_edition",     label = "Rare First Edition",     price = 39000 },
    { name = "diamond_pendant",        label = "Diamond Pendant",        price = 40000 },
    { name = "gold_ingot",             label = "Gold Ingot",             price = 41000 },
    { name = "vintage_rolex",          label = "Vintage Rolex",          price = 42000 },
    { name = "emerald_necklace",       label = "Emerald Necklace",       price = 43000 },
    { name = "platinum_chain",         label = "Platinum Chain",         price = 44000 },
    { name = "sapphire_earrings",      label = "Sapphire Earrings",      price = 45000 },
    { name = "antique_violin",         label = "Antique Violin",         price = 46000 },
    { name = "diamond_cufflinks",      label = "Diamond Cufflinks",      price = 47000 },
    { name = "gold_pocket_knife",      label = "Gold Pocket Knife",      price = 48000 },
    { name = "ruby_bracelet",          label = "Ruby Bracelet",          price = 49000 },
    { name = "platinum_locket",        label = "Platinum Locket",        price = 50000 },

    -- Tier 4: $50,001 - $200,000  (High-end shop only)
    { name = "rare_painting",          label = "Rare Painting",          price = 55000 },
    { name = "diamond_necklace",       label = "Diamond Necklace",       price = 65000 },
    { name = "black_opal",             label = "Black Opal",             price = 75000 },
    { name = "tanzanite_set",          label = "Tanzanite Set",          price = 85000 },
    { name = "emerald_tiara",          label = "Emerald Tiara",          price = 95000 },
    { name = "diamond_watch",          label = "Diamond Watch",          price = 105000 },
    { name = "ruby_tiara",             label = "Ruby Tiara",             price = 115000 },
    { name = "rare_manuscript",        label = "Rare Manuscript",        price = 125000 },
    { name = "platinum_sculpture",     label = "Platinum Sculpture",     price = 140000 },
    { name = "sapphire_tiara",         label = "Sapphire Tiara",         price = 150000 },
    { name = "diamond_brooch",         label = "Diamond Brooch",         price = 160000 },
    { name = "gold_chalice",           label = "Gold Chalice",           price = 170000 },
    { name = "alexandrite_ring",       label = "Alexandrite Ring",       price = 180000 },
    { name = "rare_stamp_collection",  label = "Rare Stamp Collection",  price = 190000 },
    { name = "diamond_encrusted_watch",label = "Diamond Encrusted Watch",price = 200000 },

    -- Tier 5: $500,000 - $1,000,000  (High-end shop only)
    { name = "flawless_diamond",       label = "Flawless Diamond",       price = 500000 },
    { name = "stolen_masterpiece",     label = "Stolen Masterpiece",     price = 650000 },
    { name = "royal_crown",            label = "Royal Crown",            price = 750000 },
    { name = "gold_bar_collection",    label = "Gold Bar Collection",    price = 850000 },
    { name = "ancient_artifact",       label = "Ancient Artifact",       price = 1000000 },
}

-- Build a quick lookup by item name for server/client use
Config.ItemLookup = {}
for _, item in ipairs(Config.Items) do
    Config.ItemLookup[item.name] = item
end
