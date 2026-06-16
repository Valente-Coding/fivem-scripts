-- Warehouse Job Server

-- Pawn item names for random loot rewards
local PawnItems = {
    "old_watch", "silver_ring", "brass_compass", "vintage_lighter", "copper_bracelet",
    "old_coins", "pewter_flask", "broken_necklace", "tarnished_locket", "vintage_cufflinks",
    "old_pocket_watch", "silver_spoon", "bronze_medal", "costume_jewelry", "old_brooch",
    "vintage_postcard", "antique_key", "silver_thimble", "old_harmonica", "brass_buckle",
    "vintage_pen", "copper_ring", "old_figurine", "tin_music_box", "worn_bracelet",
    "vintage_badge", "antique_button", "old_cameo", "silver_chain", "brass_ring",
    "gold_bracelet", "pearl_earrings", "antique_clock", "sapphire_pendant", "ivory_chess_set",
    "gold_ring", "vintage_wine", "crystal_vase", "jade_figurine", "pearl_necklace",
    "gold_cufflinks", "antique_mirror", "silver_candelabra", "ruby_ring", "gold_pocket_watch",
    "antique_compass", "crystal_decanter", "opal_earrings", "gold_chain", "vintage_camera",
    "antique_telescope", "silver_tea_set", "garnet_brooch", "gold_locket", "vintage_typewriter",
    "porcelain_figurine", "amethyst_pendant", "gold_tiara", "antique_globe", "topaz_ring",
    "diamond_ring", "emerald_brooch", "platinum_watch", "diamond_earrings", "gold_bar",
    "emerald_ring", "platinum_bracelet", "antique_painting", "ruby_necklace", "diamond_bracelet",
    "gold_sculpture", "sapphire_necklace", "platinum_ring", "rare_first_edition", "diamond_pendant",
    "gold_ingot", "vintage_rolex", "emerald_necklace", "platinum_chain", "sapphire_earrings",
    "antique_violin", "diamond_cufflinks", "gold_pocket_knife", "ruby_bracelet", "platinum_locket",
    "rare_painting", "diamond_necklace", "black_opal", "tanzanite_set", "emerald_tiara",
    "diamond_watch", "ruby_tiara", "rare_manuscript", "platinum_sculpture", "sapphire_tiara",
    "diamond_brooch", "gold_chalice", "alexandrite_ring", "rare_stamp_collection", "diamond_encrusted_watch",
    "flawless_diamond", "stolen_masterpiece", "royal_crown", "gold_bar_collection", "ancient_artifact"
}

local function TryGiveRandomPawnItem(_source)
    if math.random(1, 100) <= 2 then -- 2% chance
        local itemName = PawnItems[math.random(1, #PawnItems)]
        local itemsToAdd = { { name = itemName, amount = 1 } }
        local giveAlarmDisabler = math.random(1, 100) <= 50

        if giveAlarmDisabler then
            table.insert(itemsToAdd, { name = 'alarm_disabler', amount = 1 })
        end

        -- Add all items in a single inventory write to prevent race conditions
        exports['my_inventory']:AddItems(_source, itemsToAdd)

        TriggerClientEvent('my_inventory:notify', _source, "~y~You found a valuable item: ~w~" .. itemName:gsub("_", " ") .. "~y~!")
        if giveAlarmDisabler then
            TriggerClientEvent('my_inventory:notify', _source, "~y~You also found an ~w~Alarm Disabler~y~!")
        end
    end
end

local function GetCurrentDay()
    return exports['my_time']:GetCurrentTime().daysPassed
end

local function ResetDailyCountIfNewDay(data)
    local currentDay = GetCurrentDay()
    if data.lastJobDay ~= currentDay then
        data.dailyJobsCount = 0
        data.lastJobDay = currentDay
    end
end

local function LoadPlayerData(_source)
    local data = exports['my_datamanager']:GetPlayerDataKey(_source, 'warehouse')
    if not data or not data.level then
        data = { level = 1, jobsDone = 0, boxesCarried = 0, totalEarnings = 0, dailyJobsCount = 0, lastJobDay = GetCurrentDay() }
        exports['my_datamanager']:SetPlayerDataKey(_source, 'warehouse', data)
    end
    return data
end

local function SavePlayerData(_source, data)
    exports['my_datamanager']:SetPlayerDataKey(_source, 'warehouse', data)
end

local function CheckLevelUp(data)
    if data.level >= 5 then return false end
    local nextLevel = data.level + 1
    local requiredJobs = Config.RequiredJobsForLevel[nextLevel]
    if requiredJobs and data.jobsDone >= requiredJobs then
        data.level = nextLevel
        return true
    end
    return false
end

local function CalculatePayment(level)
    local bracket = Config.PaymentBrackets[level] or Config.PaymentBrackets[1]
    return math.random(bracket.min, bracket.max)
end

RegisterNetEvent('my_warehousejob:requestPlayerData')
AddEventHandler('my_warehousejob:requestPlayerData', function()
    local _source = source
    local data = LoadPlayerData(_source)
    ResetDailyCountIfNewDay(data)
    SavePlayerData(_source, data)
    TriggerClientEvent('my_warehousejob:playerDataResult', _source, data)
end)

RegisterNetEvent('my_warehousejob:startJob')
AddEventHandler('my_warehousejob:startJob', function()
    local _source = source
    local data = LoadPlayerData(_source)
    ResetDailyCountIfNewDay(data)
    SavePlayerData(_source, data)

    if data.dailyJobsCount >= Config.MaxDailyJobs then
        TriggerClientEvent('my_warehousejob:startJobDenied', _source, data)
        return
    end

    TriggerClientEvent('my_warehousejob:startJobClient', _source, Config.RequiredBoxes, data)
end)

RegisterNetEvent('my_warehousejob:jobComplete')
AddEventHandler('my_warehousejob:jobComplete', function(numBoxes)
    local _source = source
    local data = LoadPlayerData(_source)
    ResetDailyCountIfNewDay(data)

    local payment = CalculatePayment(data.level)
    data.jobsDone = data.jobsDone + 1
    data.dailyJobsCount = data.dailyJobsCount + 1
    data.boxesCarried = data.boxesCarried + numBoxes
    data.totalEarnings = data.totalEarnings + payment

    exports['my_money']:AddMoney(_source, 'cash', payment)

    local leveledUp = CheckLevelUp(data)
    SavePlayerData(_source, data)

    TriggerClientEvent('my_warehousejob:jobCompleteClient', _source, payment, leveledUp, data)
    TriggerClientEvent('chatMessage', _source, "^2[Warehouse]^7", "", "Job complete! Earned $" .. payment)

    -- 5% chance to find a random pawn item
    TryGiveRandomPawnItem(_source)
end)

RegisterNetEvent('my_warehousejob:cancelJob')
AddEventHandler('my_warehousejob:cancelJob', function()
    -- Nothing to save on cancel
end)

