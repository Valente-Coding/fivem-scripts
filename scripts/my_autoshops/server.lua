-- Auto Repair Shop Server

RegisterNetEvent('my_autoshops:payForRepair')
AddEventHandler('my_autoshops:payForRepair', function(price)
    local _source = source

    if not price or type(price) ~= 'number' or price <= 0 then
        TriggerClientEvent('my_autoshops:repairDenied', _source)
        return
    end

    -- Cap the price to prevent exploits
    if price > 10000 then
        price = 10000
    end

    local success = exports['my_money']:RemoveMoney(_source, 'cash', price)

    if success then
        TriggerClientEvent('my_autoshops:repairApproved', _source)
        TriggerClientEvent('chatMessage', _source, "^2[Repair]^7", "", "You paid $" .. price .. " for vehicle repairs")

        if Config.Debug then
            print(string.format("^3[AutoShops] Player %s paid $%s for repairs^7", GetPlayerName(_source), price))
        end
    else
        TriggerClientEvent('my_autoshops:repairDenied', _source)
    end
end)

-- ============================================================
-- OIL CHANGE
-- ============================================================

RegisterNetEvent('my_autoshops:payForOilChange')
AddEventHandler('my_autoshops:payForOilChange', function(plate)
    local _source = source
    if not plate or type(plate) ~= 'string' then
        TriggerClientEvent('my_autoshops:oilChangeDenied', _source, "Invalid vehicle")
        return
    end

    plate = string.upper(string.gsub(plate, '%s+', ''))

    -- Verify vehicle exists
    local vehicleData = exports['my_vehicles']:GetVehicleData(plate)
    if not vehicleData then
        TriggerClientEvent('my_autoshops:oilChangeDenied', _source, "Vehicle not found")
        return
    end

    -- Verify ownership
    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if vehicleData.owner ~= license then
        TriggerClientEvent('my_autoshops:oilChangeDenied', _source, "You don't own this vehicle")
        return
    end

    -- Check if oil is already full
    local currentOil = exports['my_vehicles']:GetVehicleOilLevel(plate)
    if currentOil >= 100.0 then
        TriggerClientEvent('my_autoshops:oilChangeDenied', _source, "Oil is already full")
        return
    end

    -- Charge the player
    local price = Config.OilChangePrice
    local taxAmount = math.floor(price * (Config.SalesTax / 100))
    local totalPrice = price + taxAmount
    local success = exports['my_money']:RemoveMoney(_source, 'cash', totalPrice)

    if success then
        exports['my_vehicles']:UpdateVehicleOilLevel(plate, 100.0)
        TriggerClientEvent('my_autoshops:oilChangeApproved', _source, plate)
        TriggerClientEvent('chatMessage', _source, "^2[Oil Change]^7", "", "You paid $" .. totalPrice .. " for an oil change")

        if Config.Debug then
            print(string.format("^3[AutoShops] Player %s paid $%s for oil change on %s^7", GetPlayerName(_source), totalPrice, plate))
        end
    else
        TriggerClientEvent('my_autoshops:oilChangeDenied', _source, "Not enough cash ($" .. totalPrice .. " needed)")
    end
end)

-- ============================================================
-- DROP-OFF REPAIR SERVICE
-- ============================================================

local vehiclesInShop = {}
local SHOP_DATA_FILE = '../saved_data/shop_vehicles.json'

local function LoadShopData()
    local raw = LoadResourceFile(GetCurrentResourceName(), SHOP_DATA_FILE)
    if raw and raw ~= '' then
        local decoded = json.decode(raw)
        if decoded then
            -- Reset elapsed for all entries (online-only timer)
            for plate, data in pairs(decoded) do
                data.elapsed = 0
                data.ready = false
            end
            vehiclesInShop = decoded
        end
    end
end

local function SaveShopData()
    SaveResourceFile(GetCurrentResourceName(), SHOP_DATA_FILE, json.encode(vehiclesInShop, {indent = true}), -1)
end

LoadShopData()

-- Clean up orphaned shop entries (e.g. vehicles removed by permadeath)
CreateThread(function()
    Wait(3000) -- Wait for my_vehicles to load
    local cleaned = false
    for plate, _ in pairs(vehiclesInShop) do
        local vehicleData = exports['my_vehicles']:GetVehicleData(plate)
        if not vehicleData then
            vehiclesInShop[plate] = nil
            cleaned = true
        end
    end
    if cleaned then
        SaveShopData()
    end
end)

-- Online license cache for timer lookups
local onlineLicenses = {}

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local _source = source
    CreateThread(function()
        Wait(2000)
        local license = exports['my_datamanager']:GetPlayerLicense(_source)
        if license then
            onlineLicenses[_source] = license
        end
    end)
end)

AddEventHandler('playerDropped', function(reason)
    local _source = source
    local license = onlineLicenses[_source]
    onlineLicenses[_source] = nil

    if license then
        -- Reset elapsed for all vehicles owned by this player
        for plate, data in pairs(vehiclesInShop) do
            if data.owner == license then
                data.elapsed = 0
                data.ready = false
            end
        end
        SaveShopData()
    end
end)

-- Rebuild online license cache for players already connected at resource start
CreateThread(function()
    Wait(3000)
    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        if id then
            local license = exports['my_datamanager']:GetPlayerLicense(id)
            if license then
                onlineLicenses[id] = license
            end
        end
    end
end)

-- Timer tick loop — only counts while owner is online
CreateThread(function()
    while true do
        Wait(1000)

        -- Build set of online licenses for fast lookup
        local onlineSet = {}
        for _, license in pairs(onlineLicenses) do
            onlineSet[license] = true
        end

        local changed = false
        for plate, data in pairs(vehiclesInShop) do
            if not data.ready and onlineSet[data.owner] then
                data.elapsed = (data.elapsed or 0) + 1
                if data.elapsed >= Config.DropOffTime then
                    data.ready = true
                end
                changed = true
            end
        end

        if changed then
            SaveShopData()
        end
    end
end)

-- Drop off vehicle
RegisterNetEvent('my_autoshops:dropOffVehicle')
AddEventHandler('my_autoshops:dropOffVehicle', function(plate, shopIndex)
    local _source = source
    if not plate or type(plate) ~= 'string' then
        TriggerClientEvent('my_autoshops:dropOffDenied', _source, "Invalid vehicle")
        return
    end
    if not shopIndex or type(shopIndex) ~= 'number' or shopIndex < 1 or shopIndex > #Config.RepairLocations then
        TriggerClientEvent('my_autoshops:dropOffDenied', _source, "Invalid shop")
        return
    end

    plate = string.upper(string.gsub(plate, '%s+', ''))

    if vehiclesInShop[plate] then
        TriggerClientEvent('my_autoshops:dropOffDenied', _source, "Vehicle is already being repaired")
        return
    end

    local vehicleData = exports['my_vehicles']:GetVehicleData(plate)
    if not vehicleData then
        TriggerClientEvent('my_autoshops:dropOffDenied', _source, "Vehicle not found")
        return
    end

    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if vehicleData.owner ~= license then
        TriggerClientEvent('my_autoshops:dropOffDenied', _source, "You don't own this vehicle")
        return
    end

    local price = Config.DropOffPrice
    local success = exports['my_money']:RemoveMoney(_source, 'cash', price)

    if not success then
        TriggerClientEvent('my_autoshops:dropOffDenied', _source, "Not enough cash ($" .. price .. " needed)")
        return
    end

    vehiclesInShop[plate] = {
        owner = license,
        shopIndex = shopIndex,
        elapsed = 0,
        ready = false
    }
    SaveShopData()

    exports['my_vehicles']:UpdateVehiclePosition(plate, 0.0, 0.0, -1000.0, 0.0)

    TriggerClientEvent('my_autoshops:dropOffApproved', _source, plate, shopIndex, Config.DropOffTime)
    TriggerClientEvent('chatMessage', _source, "^2[Auto Shop]^7", "", "You paid $" .. price .. " to leave your vehicle for repair")

    if Config.Debug then
        print(string.format("^3[AutoShops] Player %s dropped off %s at shop %d for $%s^7", GetPlayerName(_source), plate, shopIndex, price))
    end
end)

-- Pick up vehicle
RegisterNetEvent('my_autoshops:requestPickup')
AddEventHandler('my_autoshops:requestPickup', function(plate)
    local _source = source
    if not plate or type(plate) ~= 'string' then
        TriggerClientEvent('my_autoshops:pickupDenied', _source, "Invalid vehicle")
        return
    end

    plate = string.upper(string.gsub(plate, '%s+', ''))

    local shopData = vehiclesInShop[plate]
    if not shopData then
        TriggerClientEvent('my_autoshops:pickupDenied', _source, "No vehicle found in shop")
        return
    end

    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if shopData.owner ~= license then
        TriggerClientEvent('my_autoshops:pickupDenied', _source, "You don't own this vehicle")
        return
    end

    if not shopData.ready then
        local remaining = Config.DropOffTime - (shopData.elapsed or 0)
        local mins = math.ceil(remaining / 60)
        TriggerClientEvent('my_autoshops:pickupDenied', _source, "Vehicle not ready yet (" .. mins .. " min remaining)")
        return
    end

    -- Repair vehicle properties
    local vehicleData = exports['my_vehicles']:GetVehicleData(plate)
    if vehicleData and vehicleData.properties then
        local props = vehicleData.properties
        props.bodyHealth = 1000.0
        props.engineHealth = 1000.0
        exports['my_vehicles']:UpdateVehicleProperties(plate, props)
    end
    exports['my_vehicles']:UpdateVehicleOilLevel(plate, 100.0)

    -- Move vehicle back to shop location
    local shop = Config.RepairLocations[shopData.shopIndex]
    exports['my_vehicles']:UpdateVehiclePosition(plate, shop.coords.x, shop.coords.y, shop.coords.z, 0.0)

    vehiclesInShop[plate] = nil
    SaveShopData()

    TriggerClientEvent('my_autoshops:pickupApproved', _source, plate)
    TriggerClientEvent('chatMessage', _source, "^2[Auto Shop]^7", "", "Your vehicle has been repaired and is ready!")

    if Config.Debug then
        print(string.format("^3[AutoShops] Player %s picked up %s^7", GetPlayerName(_source), plate))
    end
end)

-- Get vehicles in shop for a player
RegisterNetEvent('my_autoshops:getMyShopVehicles')
AddEventHandler('my_autoshops:getMyShopVehicles', function()
    local _source = source
    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    local result = {}

    -- Clean up orphaned entries for this player while building the list
    local cleaned = false
    for plate, data in pairs(vehiclesInShop) do
        if data.owner == license then
            local vehicleData = exports['my_vehicles']:GetVehicleData(plate)
            if not vehicleData then
                vehiclesInShop[plate] = nil
                cleaned = true
            else
                local remaining = Config.DropOffTime - (data.elapsed or 0)
                if remaining < 0 then remaining = 0 end
                table.insert(result, {
                    plate = plate,
                    shopIndex = data.shopIndex,
                    remaining = remaining,
                    ready = data.ready or false
                })
            end
        end
    end

    if cleaned then
        SaveShopData()
    end

    TriggerClientEvent('my_autoshops:shopVehiclesList', _source, result)
end)

-- Export: remove all shop entries for a given license (called by permadeath)
exports('ResetPlayerData', function(license)
    if not license then return end
    local cleaned = false
    for plate, data in pairs(vehiclesInShop) do
        if data.owner == license then
            vehiclesInShop[plate] = nil
            cleaned = true
        end
    end
    if cleaned then
        SaveShopData()
    end
end)

