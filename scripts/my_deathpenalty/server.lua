-- Permadeath Server
-- When a player dies, ALL their saved data is wiped (money, inventory, vehicles,
-- housing, character, licenses, etc.) — as if they are joining the server for the
-- first time. Whitelisted players are exempt from permadeath.

---------------------------------------------------------------------
-- CONFIGURATION
---------------------------------------------------------------------
local Config = {}

-- Whitelisted license hashes (WITHOUT the "license:" prefix).
-- Players on this list will NOT have permadeath applied.
Config.WhitelistedLicenses = {
    ["99d264d00f97621f27d11304d0fb97a2dc68524c"] = true, -- satanictoast
}

-- All data‑type keys managed by my_datamanager that should be wiped.
Config.DataTypes = {
    "money", "position", "vehicles", "time", "licenses", "taxes",
    "fishing", "deliveries", "trucking", "warehouse", "drugdealer",
    "drugdistributors", "business", "housing", "stocks", "usedcars",
    "weapons", "armor", "inventory", "character", "clothing", "energy", "health"
}

---------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------

-- Return the raw license identifier string for a player, e.g. "license:abc123…"
local function GetPlayerLicense(source)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    for _, id in ipairs(identifiers) do
        if string.match(id, "^license:") then
            return id
        end
    end
    return nil
end

-- Return just the hash part after "license:"
local function GetLicenseHash(license)
    return license and license:gsub("license:", "") or nil
end

-- Check whether a player is whitelisted
local function IsWhitelisted(source)
    local license = GetPlayerLicense(source)
    if not license then return false end
    local hash = GetLicenseHash(license)
    return Config.WhitelistedLicenses[hash] == true
end

---------------------------------------------------------------------
-- PERMADEATH WIPE
---------------------------------------------------------------------
local function WipeAllPlayerData(source)
    local license = GetPlayerLicense(source)
    if not license then
        print("^1[Permadeath] Could not find license for player " .. tostring(source) .. "^7")
        return false
    end

    local playerName = GetPlayerName(source) or "Unknown"
    local safeLicense = license:gsub(":", "_")
    print(("^1[Permadeath] WIPING ALL DATA for %s (%s)^7"):format(playerName, license))

    -- ===================================================================
    -- STEP 1: Clear in-memory caches in resources that cache player data
    -- This MUST happen before file resets, otherwise stale cached data
    -- would be re-saved on the next write cycle.
    -- ===================================================================

    -- Money: reset to default starting values (clears moneyCache)
    pcall(function() exports['my_money']:SetMoney(source, 'cash', 10000) end)
    pcall(function() exports['my_money']:SetMoney(source, 'dirty', 0) end)

    -- Energy: refill to max (clears playerEnergy cache)
    pcall(function() exports['my_energy']:RefillEnergy(source) end)

    -- Business: clear in-memory allPlayerData cache
    pcall(function() exports['my_business']:ResetPlayerData(source) end)

    -- Drug dealer: clear repCache
    pcall(function() exports['my_drugdealer']:ResetPlayerData(source) end)

    -- Stocks: clear portfolio from StockData (uses license, not source)
    pcall(function() exports['my_stocks']:ResetPlayerData(license) end)

    -- Position: clear playerPositions cache
    pcall(function() exports['my_position']:ResetPlayerData(source) end)

    -- ===================================================================
    -- STEP 2: Wipe all per-player data files via my_datamanager
    -- ===================================================================
    for _, dataType in ipairs(Config.DataTypes) do
        exports['my_datamanager']:SetPlayerDataKey(source, dataType, {})
    end

    -- Also clear the datamanager's central cache for this player
    pcall(function() exports['my_datamanager']:DeletePlayerData(source) end)

    -- ===================================================================
    -- STEP 3: Remove global registry entries (vehicles, houses)
    -- ===================================================================

    -- Remove all owned vehicles from the global vehicle registry
    local ok1, err1 = pcall(function()
        local vehicles = exports['my_vehicles']:GetVehiclesByOwner(license)
        if vehicles then
            for plate, _ in pairs(vehicles) do
                exports['my_vehicles']:RemoveVehicleData(plate)
            end
        end
    end)
    if not ok1 then
        print("^3[Permadeath] Vehicle wipe warning: " .. tostring(err1) .. "^7")
    end

    -- Remove all owned houses from the global housing registry
    local ok2, err2 = pcall(function()
        exports['my_housing']:ResetHousesByOwner(license)
    end)
    if not ok2 then
        print("^3[Permadeath] Housing wipe warning: " .. tostring(err2) .. "^7")
    end

    -- Remove car lot listings and pending payments
    local ok3, err3 = pcall(function()
        exports['my_carlot']:ResetPlayerData(license)
    end)
    if not ok3 then
        print("^3[Permadeath] Car lot wipe warning: " .. tostring(err3) .. "^7")
    end

    -- Remove used car listings and offers
    local ok4, err4 = pcall(function()
        exports['my_usedcars']:ResetPlayerData(license)
    end)
    if not ok4 then
        print("^3[Permadeath] Used cars wipe warning: " .. tostring(err4) .. "^7")
    end

    -- Remove vehicles in auto repair shops
    local ok5, err5 = pcall(function()
        exports['my_autoshops']:ResetPlayerData(license)
    end)
    if not ok5 then
        print("^3[Permadeath] Auto shops wipe warning: " .. tostring(err5) .. "^7")
    end

    -- Remove vehicles in tuner garage
    local ok6, err6 = pcall(function()
        exports['my_tunergarage']:ResetPlayerData(license)
    end)
    if not ok6 then
        print("^3[Permadeath] Tuner garage wipe warning: " .. tostring(err6) .. "^7")
    end

    -- ===================================================================
    -- STEP 4: Safety net — overwrite raw JSON files in saved_data
    -- ===================================================================
    pcall(function()
        for _, dataType in ipairs(Config.DataTypes) do
            local filename = ("../saved_data/%s_%s.json"):format(safeLicense, dataType)
            SaveResourceFile(GetCurrentResourceName(), filename, "{}", -1)
        end
    end)

    print(("^2[Permadeath] Wipe complete for %s (%s). They will start fresh on next join.^7"):format(playerName, license))
    return true
end

---------------------------------------------------------------------
-- GATHER PLAYER STATS (before wipe)
---------------------------------------------------------------------
local function GatherPlayerStats(_source)
    local stats = {
        cash = 0,
        dirty = 0,
        vehicles = 0,
        houses = 0,
        totalItems = 0,
        energy = 0,
        businesses = 0,
        licenses = {}
    }

    -- Money
    local ok, result
    ok, result = pcall(function() return exports['my_money']:GetMoney(_source, 'cash') end)
    if ok and result then stats.cash = result end

    ok, result = pcall(function() return exports['my_money']:GetMoney(_source, 'dirty') end)
    if ok and result then stats.dirty = result end

    -- Vehicles
    local license = GetPlayerLicense(_source)
    ok, result = pcall(function() return exports['my_vehicles']:GetVehiclesByOwner(license) end)
    if ok and result then
        local count = 0
        for _ in pairs(result) do count = count + 1 end
        stats.vehicles = count
    end

    -- Houses (count from housing data)
    ok, result = pcall(function()
        local houseData = exports['my_datamanager']:GetPlayerDataKey(_source, 'housing')
        if houseData and houseData.owned then
            local count = 0
            for _ in pairs(houseData.owned) do count = count + 1 end
            return count
        end
        return 0
    end)
    if ok and result then stats.houses = result end

    -- If the above didn't find houses, count from the ResetHousesByOwner-style approach
    if stats.houses == 0 and license then
        -- We can't easily access the Houses table from another resource,
        -- but the housing export returns a count. We'll estimate from the data files.
        ok, result = pcall(function()
            -- The housing system tracks ownership in its own table
            -- We count via the license in the global houses
            local data = exports['my_datamanager']:GetPlayerDataKey(_source, 'housing')
            if data and type(data) == "table" then
                local count = 0
                for k, v in pairs(data) do
                    if v == true or (type(v) == "table") then
                        count = count + 1
                    end
                end
                if count > 0 then return count end
            end
            return 0
        end)
        if ok and result then stats.houses = result end
    end

    -- Inventory
    ok, result = pcall(function() return exports['my_inventory']:GetInventory(_source) end)
    if ok and result then
        local count = 0
        for _, qty in pairs(result) do
            count = count + (qty or 0)
        end
        stats.totalItems = count
    end

    -- Energy
    ok, result = pcall(function() return exports['my_energy']:GetEnergy(_source) end)
    if ok and result then stats.energy = result end

    -- Businesses
    ok, result = pcall(function()
        local businessData = exports['my_datamanager']:GetPlayerDataKey(_source, 'business')
        if businessData and businessData.businesses then
            local count = 0
            for _ in pairs(businessData.businesses) do count = count + 1 end
            return count
        end
        return 0
    end)
    if ok and result then stats.businesses = result end

    -- Licenses
    ok, result = pcall(function()
        local licenseData = exports['my_datamanager']:GetPlayerDataKey(_source, 'licenses')
        if licenseData and type(licenseData) == 'table' then
            local list = {}
            for name, owned in pairs(licenseData) do
                if owned == true then
                    list[#list + 1] = name
                end
            end
            return list
        end
        return {}
    end)
    if ok and result then stats.licenses = result end

    return stats
end

---------------------------------------------------------------------
-- EVENT: Player died
---------------------------------------------------------------------
RegisterNetEvent('my_deathpenalty:onPlayerDied')
AddEventHandler('my_deathpenalty:onPlayerDied', function()
    local _source = source
    local playerName = GetPlayerName(_source) or "Unknown"

    -- Check whitelist
    if IsWhitelisted(_source) then
        print(("^3[Permadeath] %s is WHITELISTED – skipping permadeath.^7"):format(playerName))
        TriggerClientEvent('my_deathpenalty:whitelisted', _source)
        return
    end

    -- Gather stats BEFORE wiping
    local stats = GatherPlayerStats(_source)
    print(("^3[Permadeath] Stats for %s before wipe: Cash=$%s, Dirty=$%s, Vehicles=%s, Houses=%s, Items=%s, Energy=%s, Businesses=%s, Licenses=%s^7"):format(
        playerName, tostring(stats.cash), tostring(stats.dirty), tostring(stats.vehicles), tostring(stats.houses), tostring(stats.totalItems), tostring(stats.energy), tostring(stats.businesses), table.concat(stats.licenses or {}, ', ')
    ))

    -- Wipe everything
    WipeAllPlayerData(_source)

    -- Send stats to client to display death screen
    TriggerClientEvent('my_deathpenalty:showDeathScreen', _source, stats)
end)

---------------------------------------------------------------------
-- EVENT: Player clicks "Restart Journey"
---------------------------------------------------------------------
RegisterNetEvent('my_deathpenalty:restartJourney')
AddEventHandler('my_deathpenalty:restartJourney', function()
    local _source = source

    -- Refill energy
    pcall(function()
        exports['my_energy']:RefillEnergy(_source)
    end)

    -- Tell the client to respawn and go through character creation
    TriggerClientEvent('my_deathpenalty:permadeathRespawn', _source)
end)
