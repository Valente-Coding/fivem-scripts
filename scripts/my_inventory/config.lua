Config = {}

Config.OpenKey = 289 -- F2
Config.OpenKeyLabel = "F2"

-- Item definitions
-- usable: whether the player can "use" this item from inventory
-- category: grouping for the UI
Config.Items = {
    -- Drugs (from drugdealer) - NOT usable
    { name = "small_weed",     label = "Small Weed",     category = "drugs", usable = false },
    { name = "medium_weed",    label = "Medium Weed",    category = "drugs", usable = false },
    { name = "large_weed",     label = "Large Weed",     category = "drugs", usable = false },
    { name = "small_cocaine",  label = "Small Cocaine",  category = "drugs", usable = false },
    { name = "medium_cocaine", label = "Medium Cocaine",  category = "drugs", usable = false },
    { name = "large_cocaine",  label = "Large Cocaine",  category = "drugs", usable = false },
    { name = "small_meth",     label = "Small Meth",     category = "drugs", usable = false },
    { name = "medium_meth",    label = "Medium Meth",    category = "drugs", usable = false },
    { name = "large_meth",     label = "Large Meth",     category = "drugs", usable = false },

    -- Tools
    { name = "repair_kit",      label = "Repair Kit",      category = "tools", usable = true },
    { name = "cleaning_kit",    label = "Cleaning Kit",    category = "tools", usable = true },
    { name = "alarm_disabler",  label = "Alarm Disabler",  category = "tools", usable = true },
    
    -- Combat
    { name = "armor",            label = "Body Armor",       category = "combat", usable = true },

    -- Valuables (Pawn Shop Items) - usable sets waypoint to pawn shop
    -- Tier 1: $500 - $5,000
    { name = "old_watch",              label = "Old Watch",              category = "pawn", usable = true },
    { name = "silver_ring",            label = "Silver Ring",            category = "pawn", usable = true },
    { name = "brass_compass",          label = "Brass Compass",          category = "pawn", usable = true },
    { name = "vintage_lighter",        label = "Vintage Lighter",        category = "pawn", usable = true },
    { name = "copper_bracelet",        label = "Copper Bracelet",        category = "pawn", usable = true },
    { name = "old_coins",              label = "Old Coins",              category = "pawn", usable = true },
    { name = "pewter_flask",           label = "Pewter Flask",           category = "pawn", usable = true },
    { name = "broken_necklace",        label = "Broken Necklace",        category = "pawn", usable = true },
    { name = "tarnished_locket",       label = "Tarnished Locket",       category = "pawn", usable = true },
    { name = "vintage_cufflinks",      label = "Vintage Cufflinks",      category = "pawn", usable = true },
    { name = "old_pocket_watch",       label = "Old Pocket Watch",       category = "pawn", usable = true },
    { name = "silver_spoon",           label = "Silver Spoon",           category = "pawn", usable = true },
    { name = "bronze_medal",           label = "Bronze Medal",           category = "pawn", usable = true },
    { name = "costume_jewelry",        label = "Costume Jewelry",        category = "pawn", usable = true },
    { name = "old_brooch",             label = "Old Brooch",             category = "pawn", usable = true },
    { name = "vintage_postcard",       label = "Vintage Postcard",       category = "pawn", usable = true },
    { name = "antique_key",            label = "Antique Key",            category = "pawn", usable = true },
    { name = "silver_thimble",         label = "Silver Thimble",         category = "pawn", usable = true },
    { name = "old_harmonica",          label = "Old Harmonica",          category = "pawn", usable = true },
    { name = "brass_buckle",           label = "Brass Buckle",           category = "pawn", usable = true },
    { name = "vintage_pen",            label = "Vintage Pen",            category = "pawn", usable = true },
    { name = "copper_ring",            label = "Copper Ring",            category = "pawn", usable = true },
    { name = "old_figurine",           label = "Old Figurine",           category = "pawn", usable = true },
    { name = "tin_music_box",          label = "Tin Music Box",          category = "pawn", usable = true },
    { name = "worn_bracelet",          label = "Worn Bracelet",          category = "pawn", usable = true },
    { name = "vintage_badge",          label = "Vintage Badge",          category = "pawn", usable = true },
    { name = "antique_button",         label = "Antique Button",         category = "pawn", usable = true },
    { name = "old_cameo",              label = "Old Cameo",              category = "pawn", usable = true },
    { name = "silver_chain",           label = "Silver Chain",           category = "pawn", usable = true },
    { name = "brass_ring",             label = "Brass Ring",             category = "pawn", usable = true },

    -- Tier 2: $5,001 - $25,000
    { name = "gold_bracelet",          label = "Gold Bracelet",          category = "pawn", usable = true },
    { name = "pearl_earrings",         label = "Pearl Earrings",         category = "pawn", usable = true },
    { name = "antique_clock",          label = "Antique Clock",          category = "pawn", usable = true },
    { name = "sapphire_pendant",       label = "Sapphire Pendant",       category = "pawn", usable = true },
    { name = "ivory_chess_set",        label = "Ivory Chess Set",        category = "pawn", usable = true },
    { name = "gold_ring",              label = "Gold Ring",              category = "pawn", usable = true },
    { name = "vintage_wine",           label = "Vintage Wine",           category = "pawn", usable = true },
    { name = "crystal_vase",           label = "Crystal Vase",           category = "pawn", usable = true },
    { name = "jade_figurine",          label = "Jade Figurine",          category = "pawn", usable = true },
    { name = "pearl_necklace",         label = "Pearl Necklace",         category = "pawn", usable = true },
    { name = "gold_cufflinks",         label = "Gold Cufflinks",         category = "pawn", usable = true },
    { name = "antique_mirror",         label = "Antique Mirror",         category = "pawn", usable = true },
    { name = "silver_candelabra",      label = "Silver Candelabra",      category = "pawn", usable = true },
    { name = "ruby_ring",              label = "Ruby Ring",              category = "pawn", usable = true },
    { name = "gold_pocket_watch",      label = "Gold Pocket Watch",      category = "pawn", usable = true },
    { name = "antique_compass",        label = "Antique Compass",        category = "pawn", usable = true },
    { name = "crystal_decanter",       label = "Crystal Decanter",       category = "pawn", usable = true },
    { name = "opal_earrings",          label = "Opal Earrings",          category = "pawn", usable = true },
    { name = "gold_chain",             label = "Gold Chain",             category = "pawn", usable = true },
    { name = "vintage_camera",         label = "Vintage Camera",         category = "pawn", usable = true },
    { name = "antique_telescope",      label = "Antique Telescope",      category = "pawn", usable = true },
    { name = "silver_tea_set",         label = "Silver Tea Set",         category = "pawn", usable = true },
    { name = "garnet_brooch",          label = "Garnet Brooch",          category = "pawn", usable = true },
    { name = "gold_locket",            label = "Gold Locket",            category = "pawn", usable = true },
    { name = "vintage_typewriter",     label = "Vintage Typewriter",     category = "pawn", usable = true },
    { name = "porcelain_figurine",     label = "Porcelain Figurine",     category = "pawn", usable = true },
    { name = "amethyst_pendant",       label = "Amethyst Pendant",       category = "pawn", usable = true },
    { name = "gold_tiara",             label = "Gold Tiara",             category = "pawn", usable = true },
    { name = "antique_globe",          label = "Antique Globe",          category = "pawn", usable = true },
    { name = "topaz_ring",             label = "Topaz Ring",             category = "pawn", usable = true },

    -- Tier 3: $25,001 - $50,000
    { name = "diamond_ring",           label = "Diamond Ring",           category = "pawn", usable = true },
    { name = "emerald_brooch",         label = "Emerald Brooch",         category = "pawn", usable = true },
    { name = "platinum_watch",         label = "Platinum Watch",         category = "pawn", usable = true },
    { name = "diamond_earrings",       label = "Diamond Earrings",       category = "pawn", usable = true },
    { name = "gold_bar",               label = "Gold Bar",               category = "pawn", usable = true },
    { name = "emerald_ring",           label = "Emerald Ring",           category = "pawn", usable = true },
    { name = "platinum_bracelet",      label = "Platinum Bracelet",      category = "pawn", usable = true },
    { name = "antique_painting",       label = "Antique Painting",       category = "pawn", usable = true },
    { name = "ruby_necklace",          label = "Ruby Necklace",          category = "pawn", usable = true },
    { name = "diamond_bracelet",       label = "Diamond Bracelet",       category = "pawn", usable = true },
    { name = "gold_sculpture",         label = "Gold Sculpture",         category = "pawn", usable = true },
    { name = "sapphire_necklace",      label = "Sapphire Necklace",      category = "pawn", usable = true },
    { name = "platinum_ring",          label = "Platinum Ring",          category = "pawn", usable = true },
    { name = "rare_first_edition",     label = "Rare First Edition",     category = "pawn", usable = true },
    { name = "diamond_pendant",        label = "Diamond Pendant",        category = "pawn", usable = true },
    { name = "gold_ingot",             label = "Gold Ingot",             category = "pawn", usable = true },
    { name = "vintage_rolex",          label = "Vintage Rolex",          category = "pawn", usable = true },
    { name = "emerald_necklace",       label = "Emerald Necklace",       category = "pawn", usable = true },
    { name = "platinum_chain",         label = "Platinum Chain",         category = "pawn", usable = true },
    { name = "sapphire_earrings",      label = "Sapphire Earrings",      category = "pawn", usable = true },
    { name = "antique_violin",         label = "Antique Violin",         category = "pawn", usable = true },
    { name = "diamond_cufflinks",      label = "Diamond Cufflinks",      category = "pawn", usable = true },
    { name = "gold_pocket_knife",      label = "Gold Pocket Knife",      category = "pawn", usable = true },
    { name = "ruby_bracelet",          label = "Ruby Bracelet",          category = "pawn", usable = true },
    { name = "platinum_locket",        label = "Platinum Locket",        category = "pawn", usable = true },

    -- Tier 4: $50,001 - $200,000
    { name = "rare_painting",          label = "Rare Painting",          category = "pawn", usable = true },
    { name = "diamond_necklace",       label = "Diamond Necklace",       category = "pawn", usable = true },
    { name = "black_opal",             label = "Black Opal",             category = "pawn", usable = true },
    { name = "tanzanite_set",          label = "Tanzanite Set",          category = "pawn", usable = true },
    { name = "emerald_tiara",          label = "Emerald Tiara",          category = "pawn", usable = true },
    { name = "diamond_watch",          label = "Diamond Watch",          category = "pawn", usable = true },
    { name = "ruby_tiara",             label = "Ruby Tiara",             category = "pawn", usable = true },
    { name = "rare_manuscript",        label = "Rare Manuscript",        category = "pawn", usable = true },
    { name = "platinum_sculpture",     label = "Platinum Sculpture",     category = "pawn", usable = true },
    { name = "sapphire_tiara",         label = "Sapphire Tiara",         category = "pawn", usable = true },
    { name = "diamond_brooch",         label = "Diamond Brooch",         category = "pawn", usable = true },
    { name = "gold_chalice",           label = "Gold Chalice",           category = "pawn", usable = true },
    { name = "alexandrite_ring",       label = "Alexandrite Ring",       category = "pawn", usable = true },
    { name = "rare_stamp_collection",  label = "Rare Stamp Collection",  category = "pawn", usable = true },
    { name = "diamond_encrusted_watch",label = "Diamond Encrusted Watch",category = "pawn", usable = true },

    -- Tier 5: $500,000 - $1,000,000
    { name = "flawless_diamond",       label = "Flawless Diamond",       category = "pawn", usable = true },
    { name = "stolen_masterpiece",     label = "Stolen Masterpiece",     category = "pawn", usable = true },
    { name = "royal_crown",            label = "Royal Crown",            category = "pawn", usable = true },
    { name = "gold_bar_collection",    label = "Gold Bar Collection",    category = "pawn", usable = true },
    { name = "ancient_artifact",       label = "Ancient Artifact",       category = "pawn", usable = true },
}

-- Category display order and labels
Config.Categories = {
    { id = "drugs",        label = "Drugs",        icon = "💊" },
    { id = "tools",        label = "Tools",        icon = "🔧" },
    { id = "combat",       label = "Combat",       icon = "🛡️" },
    { id = "pawn",         label = "Valuables",    icon = "💎" },
}
