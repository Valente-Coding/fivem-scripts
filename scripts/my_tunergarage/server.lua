-- my_tunergarage/server.lua
-- Server-side logic for garage purchase and worker system

-- ============================================================
-- PLAYER TRACKING & PROFIT ACCUMULATOR
-- ============================================================

local connectedPlayers = {} -- [source] = license
local pendingProfit = {}    -- [license] = number (transient, resets on restart)

local function GetLicense(source)
    return exports['my_datamanager']:GetPlayerLicense(source)
end

-- Track connected players
AddEventHandler('playerConnecting', function()
    local _source = source
    CreateThread(function()
        Wait(2000)
        local license = GetLicense(_source)
        if license then
            connectedPlayers[_source] = license
        end
    end)
end)

AddEventHandler('playerDropped', function()
    local _source = source
    local license = connectedPlayers[_source]
    connectedPlayers[_source] = nil

    -- Reset drop-off repair timer for vehicles owned by this player
    if license then
        for plate, data in pairs(vehiclesInShop) do
            if data.owner == license then
                data.elapsed = 0
                data.ready = false
            end
        end
        SaveShopData()
    end
end)

-- Rebuild on resource start for players already connected
CreateThread(function()
    Wait(3000)
    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        if id then
            local license = GetLicense(id)
            if license then
                connectedPlayers[id] = license
            end
        end
    end
end)

-- ============================================================
-- OWNERSHIP CHECK (extended with worker + profit)
-- ============================================================

RegisterNetEvent('my_tunergarage:checkOwnership')
AddEventHandler('my_tunergarage:checkOwnership', function()
    local source = source

    local data = exports['my_datamanager']:GetPlayerDataKey(source, 'garage')

    local owned = false
    local hasWorker = false
    if data and data.little_seoul_tuner then
        owned = true
        if data.little_seoul_tuner_worker then
            hasWorker = true
        end
    end

    local license = GetLicense(source)
    local profit = 0
    if license and pendingProfit[license] then
        profit = pendingProfit[license]
    end

    TriggerClientEvent('my_tunergarage:ownershipStatus', source, owned, hasWorker, profit)
end)

-- ============================================================
-- PURCHASE HANDLER
-- ============================================================

RegisterNetEvent('my_tunergarage:requestPurchase')
AddEventHandler('my_tunergarage:requestPurchase', function()
    local source = source
    local price = Config.Garage.price

    -- Check if already owned
    local data = exports['my_datamanager']:GetPlayerDataKey(source, 'garage')
    if data and data.little_seoul_tuner then
        TriggerClientEvent('my_tunergarage:purchaseFailure', source, "You already own this garage.")
        return
    end

    -- Check if player has enough money (cash)
    local playerCash = exports['my_money']:GetMoney(source, 'cash')

    if playerCash < price then
        TriggerClientEvent('my_tunergarage:purchaseFailure', source, "Not enough money. You need $" .. price .. ".")
        return
    end

    -- Remove money
    local removed = exports['my_money']:RemoveMoney(source, 'cash', price)

    if not removed then
        TriggerClientEvent('my_tunergarage:purchaseFailure', source, "Payment failed. Please try again.")
        return
    end

    -- Save ownership via datamanager
    local garageData = data or {}
    garageData.little_seoul_tuner = true

    local saved = exports['my_datamanager']:SetPlayerDataKey(source, 'garage', garageData)

    if not saved then
        -- Refund if save failed
        exports['my_money']:AddMoney(source, 'cash', price)
        TriggerClientEvent('my_tunergarage:purchaseFailure', source, "Failed to save purchase. You have been refunded.")
        return
    end

    -- Send success to client
    TriggerClientEvent('my_tunergarage:purchaseSuccess', source)

    -- Flash money display
    TriggerClientEvent('my_money:flashMoney', source, 'cash')

    print("[my_tunergarage] " .. GetPlayerName(source) .. " purchased " .. Config.Garage.name .. " for $" .. price)
end)

-- ============================================================
-- HIRE WORKER
-- ============================================================

RegisterNetEvent('my_tunergarage:hireWorker')
AddEventHandler('my_tunergarage:hireWorker', function()
    local source = source
    local cost = Config.Worker.hireCost

    -- Check ownership
    local data = exports['my_datamanager']:GetPlayerDataKey(source, 'garage')
    if not data or not data.little_seoul_tuner then
        TriggerClientEvent('my_tunergarage:hireFailure', source, "You don't own this garage.")
        return
    end

    -- Check if already hired
    if data.little_seoul_tuner_worker then
        TriggerClientEvent('my_tunergarage:hireFailure', source, "You already have a mechanic working here.")
        return
    end

    -- Check money
    local playerCash = exports['my_money']:GetMoney(source, 'cash')
    if playerCash < cost then
        TriggerClientEvent('my_tunergarage:hireFailure', source, "Not enough money. You need $" .. cost .. ".")
        return
    end

    -- Deduct money
    local removed = exports['my_money']:RemoveMoney(source, 'cash', cost)
    if not removed then
        TriggerClientEvent('my_tunergarage:hireFailure', source, "Payment failed. Please try again.")
        return
    end

    -- Save worker flag
    data.little_seoul_tuner_worker = true
    local saved = exports['my_datamanager']:SetPlayerDataKey(source, 'garage', data)

    if not saved then
        exports['my_money']:AddMoney(source, 'cash', cost)
        TriggerClientEvent('my_tunergarage:hireFailure', source, "Failed to save. You have been refunded.")
        return
    end

    TriggerClientEvent('my_tunergarage:hireSuccess', source)
    TriggerClientEvent('my_money:flashMoney', source, 'cash')

    print("[my_tunergarage] " .. GetPlayerName(source) .. " hired a mechanic for $" .. cost)
end)

-- ============================================================
-- COLLECT PROFIT
-- ============================================================

RegisterNetEvent('my_tunergarage:collectProfit')
AddEventHandler('my_tunergarage:collectProfit', function()
    local source = source

    -- Validate ownership + worker
    local data = exports['my_datamanager']:GetPlayerDataKey(source, 'garage')
    if not data or not data.little_seoul_tuner or not data.little_seoul_tuner_worker then
        return
    end

    local license = GetLicense(source)
    if not license then return end

    local profit = pendingProfit[license] or 0
    if profit <= 0 then
        TriggerClientEvent('my_tunergarage:profitCollected', source, 0)
        return
    end

    -- Add money to player
    exports['my_money']:AddMoney(source, 'cash', profit)
    pendingProfit[license] = 0

    TriggerClientEvent('my_tunergarage:profitCollected', source, profit)
    TriggerClientEvent('my_money:flashMoney', source, 'cash')

    print("[my_tunergarage] " .. GetPlayerName(source) .. " collected $" .. profit .. " from mechanic")
end)

-- ============================================================
-- INCOME TIMER — runs every Config.Worker.interval seconds
-- ============================================================

CreateThread(function()
    while true do
        Wait(Config.Worker.interval * 1000)

        for playerSource, license in pairs(connectedPlayers) do
            -- Check if this player owns the garage and has a worker
            local data = exports['my_datamanager']:GetPlayerDataKey(playerSource, 'garage')
            if data and data.little_seoul_tuner and data.little_seoul_tuner_worker then
                local profit = math.random(Config.Worker.profitMin, Config.Worker.profitMax)
                pendingProfit[license] = (pendingProfit[license] or 0) + profit

                -- Notify client to swap the car and update profit display
                TriggerClientEvent('my_tunergarage:workerCompletedCar', playerSource, profit, pendingProfit[license])
            end
        end
    end
end)

-- ============================================================
-- DROP-OFF REPAIR SERVICE (owner only, free, oil depleted)
-- ============================================================

local vehiclesInShop = {}
local SHOP_DATA_FILE = '../saved_data/tunergarage_vehicles.json'

local function LoadShopData()
    local raw = LoadResourceFile(GetCurrentResourceName(), SHOP_DATA_FILE)
    if raw and raw ~= '' then
        local decoded = json.decode(raw)
        if decoded then
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

-- Drop-off repair timer — 1-second tick, only counts while owner is online
CreateThread(function()
    while true do
        Wait(1000)

        local onlineSet = {}
        for _, license in pairs(connectedPlayers) do
            onlineSet[license] = true
        end

        local changed = false
        for plate, data in pairs(vehiclesInShop) do
            if not data.ready and onlineSet[data.owner] then
                data.elapsed = (data.elapsed or 0) + 1
                if data.elapsed >= Config.DropOff.repairTime then
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
RegisterNetEvent('my_tunergarage:dropOffVehicle')
AddEventHandler('my_tunergarage:dropOffVehicle', function(plate)
    local _source = source
    if not plate or type(plate) ~= 'string' then
        TriggerClientEvent('my_tunergarage:dropOffDenied', _source, "Invalid vehicle")
        return
    end

    plate = string.upper(string.gsub(plate, '%s+', ''))

    -- Check garage ownership
    local garageData = exports['my_datamanager']:GetPlayerDataKey(_source, 'garage')
    if not garageData or not garageData.little_seoul_tuner then
        TriggerClientEvent('my_tunergarage:dropOffDenied', _source, "You don't own this garage")
        return
    end

    -- Check if already in repair
    if vehiclesInShop[plate] then
        TriggerClientEvent('my_tunergarage:dropOffDenied', _source, "Vehicle is already being repaired")
        return
    end

    -- Verify vehicle ownership
    local vehicleData = exports['my_vehicles']:GetVehicleData(plate)
    if not vehicleData then
        TriggerClientEvent('my_tunergarage:dropOffDenied', _source, "Vehicle not found")
        return
    end

    local license = GetLicense(_source)
    if vehicleData.owner ~= license then
        TriggerClientEvent('my_tunergarage:dropOffDenied', _source, "You don't own this vehicle")
        return
    end

    -- Check oil is depleted
    local oilLevel = exports['my_vehicles']:GetVehicleOilLevel(plate)
    if oilLevel and oilLevel > 0 then
        TriggerClientEvent('my_tunergarage:dropOffDenied', _source, "Vehicle oil is not depleted")
        return
    end

    -- Store in shop
    vehiclesInShop[plate] = {
        owner = license,
        model = vehicleData.model or vehicleData.properties and vehicleData.properties.model,
        elapsed = 0,
        ready = false
    }
    SaveShopData()

    -- Update vehicle position to the drop-off coords
    local c = Config.DropOff.vehicleCoords
    exports['my_vehicles']:UpdateVehiclePosition(plate, c.x, c.y, c.z, c.w)

    TriggerClientEvent('my_tunergarage:dropOffApproved', _source, plate, Config.DropOff.repairTime)

    print("[my_tunergarage] " .. GetPlayerName(_source) .. " dropped off " .. plate .. " for repair")
end)

-- Pick up vehicle
RegisterNetEvent('my_tunergarage:requestPickup')
AddEventHandler('my_tunergarage:requestPickup', function(plate)
    local _source = source
    if not plate or type(plate) ~= 'string' then
        TriggerClientEvent('my_tunergarage:pickupDenied', _source, "Invalid vehicle")
        return
    end

    plate = string.upper(string.gsub(plate, '%s+', ''))

    local shopData = vehiclesInShop[plate]
    if not shopData then
        TriggerClientEvent('my_tunergarage:pickupDenied', _source, "No vehicle found in repair")
        return
    end

    local license = GetLicense(_source)
    if shopData.owner ~= license then
        TriggerClientEvent('my_tunergarage:pickupDenied', _source, "You don't own this vehicle")
        return
    end

    if not shopData.ready then
        local remaining = Config.DropOff.repairTime - (shopData.elapsed or 0)
        local mins = math.ceil(remaining / 60)
        TriggerClientEvent('my_tunergarage:pickupDenied', _source, "Vehicle not ready yet (" .. mins .. " min remaining)")
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

    -- Remove from shop
    vehiclesInShop[plate] = nil
    SaveShopData()

    TriggerClientEvent('my_tunergarage:pickupApproved', _source, plate)

    print("[my_tunergarage] " .. GetPlayerName(_source) .. " picked up " .. plate .. " after repair")
end)

-- Get player's vehicles in the garage shop
RegisterNetEvent('my_tunergarage:getMyGarageVehicles')
AddEventHandler('my_tunergarage:getMyGarageVehicles', function()
    local _source = source
    local license = GetLicense(_source)
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
                local remaining = Config.DropOff.repairTime - (data.elapsed or 0)
                if remaining < 0 then remaining = 0 end
                table.insert(result, {
                    plate = plate,
                    model = data.model,
                    remaining = remaining,
                    ready = data.ready or false
                })
            end
        end
    end

    if cleaned then
        SaveShopData()
    end

    TriggerClientEvent('my_tunergarage:garageVehiclesList', _source, result)
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
