-- my_vehicles/server.lua
-- Persistent vehicle ownership & storage (JSON file-backed)
-- All exports and events are preserved for compatibility with:
--   my_dealership, my_usedcars, my_vehicleFlipper, my_bennys,
--   my_vehiclelock, my_cleanvehicle, my_repairkit, my_deathpenalty

local vehicles = {} -- plate -> { model, owner, ownerName, x, y, z, heading, properties, locked }
local saveDirty = false

-- ============================================================
-- FILE I/O
-- ============================================================

local FILE_PATH = '../saved_data/global_vehicles.json'

local function Load()
    local raw = LoadResourceFile(GetCurrentResourceName(), FILE_PATH)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and data then
            vehicles = data
            print(('[my_vehicles] Loaded %d vehicles'):format(#(function() local n=0 for _ in pairs(vehicles) do n=n+1 end return tostring(n) end)()))
            return
        end
        print('^1[my_vehicles] Failed to parse global_vehicles.json^7')
    end
    vehicles = {}
end

local function Save()
    local ok, str = pcall(json.encode, vehicles, { indent = true })
    if ok and str then
        SaveResourceFile(GetCurrentResourceName(), FILE_PATH, str, -1)
    end
    saveDirty = false
end

local function MarkDirty()
    saveDirty = true
end

local function Plate(p)
    if not p then return nil end
    return string.upper(string.gsub(tostring(p), '%s+', ''))
end

-- ============================================================
-- EXPORTS  (all signatures preserved)
-- ============================================================

exports('DoesPlateExist', function(plate)
    plate = Plate(plate)
    return plate and vehicles[plate] ~= nil or false
end)

exports('RegisterVehicle', function(plate, model, owner, ownerName, x, y, z, heading, properties)
    if not plate or not model or not owner then return false end
    plate = Plate(plate)
    if vehicles[plate] then return false end

    vehicles[plate] = {
        model      = model,
        owner      = owner,
        ownerName  = ownerName or 'Unknown',
        x          = tonumber(x) or 0.0,
        y          = tonumber(y) or 0.0,
        z          = tonumber(z) or 0.0,
        heading    = tonumber(heading) or 0.0,
        properties = properties or {},
        mileage    = 0.0,
        oilLevel   = 100.0,
    }
    Save()
    TriggerClientEvent('my_vehicles:vehicleAdded', -1, plate, vehicles[plate])
    return true
end)

exports('GetVehiclesByOwner', function(license)
    if not license then return {} end
    local out = {}
    for plate, d in pairs(vehicles) do
        if d.owner == license then out[plate] = d end
    end
    return out
end)

exports('RemoveVehicleData', function(plate)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return false end
    vehicles[plate] = nil
    Save()
    TriggerClientEvent('my_vehicles:vehicleRemoved', -1, plate)
    return true
end)

exports('UpdateVehiclePosition', function(plate, x, y, z, heading)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return false end
    local v = vehicles[plate]
    v.x = tonumber(x) or v.x
    v.y = tonumber(y) or v.y
    v.z = tonumber(z) or v.z
    v.heading = tonumber(heading) or v.heading
    Save()
    return true
end)

exports('UpdateVehicleProperties', function(plate, properties)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return false end
    vehicles[plate].properties = properties
    Save()
    return true
end)

exports('GetAllVehicles', function()
    return vehicles
end)

exports('GetVehicleData', function(plate)
    plate = Plate(plate)
    if not plate then return nil end
    return vehicles[plate] or nil
end)

exports('TransferVehicle', function(plate, newOwner, newName)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return false end
    vehicles[plate].owner = newOwner
    vehicles[plate].ownerName = newName or 'Unknown'
    Save()
    return true
end)

exports('SetVehicleLocked', function(plate, locked)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return false end
    vehicles[plate].locked = locked and true or false
    Save()
    return true
end)

exports('GetVehicleLocked', function(plate)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return false end
    return vehicles[plate].locked == true
end)

exports('UpdateVehicleMileage', function(plate, miles)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return false end
    vehicles[plate].mileage = (vehicles[plate].mileage or 0) + (tonumber(miles) or 0)
    MarkDirty()
    return true
end)

exports('GetVehicleMileage', function(plate)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return 0.0 end
    return vehicles[plate].mileage or 0.0
end)

exports('GetVehicleOilLevel', function(plate)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return 100.0 end
    return vehicles[plate].oilLevel or 100.0
end)

exports('UpdateVehicleOilLevel', function(plate, amount)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return false end
    vehicles[plate].oilLevel = math.max(0.0, math.min(100.0, tonumber(amount) or 100.0))
    MarkDirty()
    return true
end)

exports('AddVehicleOil', function(plate, amount)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return false end
    local current = vehicles[plate].oilLevel or 100.0
    vehicles[plate].oilLevel = math.max(0.0, math.min(100.0, current + (tonumber(amount) or 0)))
    MarkDirty()
    return true
end)

-- ============================================================
-- EVENTS
-- ============================================================

-- Send full registry + player license to requesting client
RegisterNetEvent('my_vehicles:requestAllVehicles')
AddEventHandler('my_vehicles:requestAllVehicles', function()
    local src = source
    local license = exports['my_datamanager']:GetPlayerLicense(src)
    TriggerClientEvent('my_vehicles:loadAllVehicles', src, vehicles, license)
end)

-- Client saves full vehicle state (position + properties) — e.g. on exit vehicle
RegisterNetEvent('my_vehicles:saveVehicleState')
AddEventHandler('my_vehicles:saveVehicleState', function(plate, x, y, z, heading, properties, addMileage)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return end
    local v = vehicles[plate]
    v.x = tonumber(x) or v.x
    v.y = tonumber(y) or v.y
    v.z = tonumber(z) or v.z
    v.heading = tonumber(heading) or v.heading
    if properties then v.properties = properties end
    if addMileage and tonumber(addMileage) and tonumber(addMileage) > 0 then
        v.mileage = (v.mileage or 0) + tonumber(addMileage)
    end
    MarkDirty()
end)

-- Client sends accumulated mileage periodically while driving
RegisterNetEvent('my_vehicles:updateMileage')
AddEventHandler('my_vehicles:updateMileage', function(plate, miles)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return end
    if miles and tonumber(miles) and tonumber(miles) > 0 then
        vehicles[plate].mileage = (vehicles[plate].mileage or 0) + tonumber(miles)
        MarkDirty()
    end
end)

-- Client sends updated oil level periodically while driving
RegisterNetEvent('my_vehicles:updateOilLevel')
AddEventHandler('my_vehicles:updateOilLevel', function(plate, oilLevel)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return end
    if oilLevel and tonumber(oilLevel) then
        vehicles[plate].oilLevel = math.max(0.0, math.min(100.0, tonumber(oilLevel)))
        MarkDirty()
    end
end)

-- Client reports properties only (legacy - kept for compat)
RegisterNetEvent('my_vehicles:reportProperties')
AddEventHandler('my_vehicles:reportProperties', function(plate, properties)
    plate = Plate(plate)
    if not plate or not vehicles[plate] or not properties then return end
    vehicles[plate].properties = properties
    MarkDirty()
end)

-- Vehicle destroyed
RegisterNetEvent('my_vehicles:destroyVehicle')
AddEventHandler('my_vehicles:destroyVehicle', function(plate)
    plate = Plate(plate)
    if not plate or not vehicles[plate] then return end
    vehicles[plate] = nil
    Save()
    TriggerClientEvent('my_vehicles:vehicleRemoved', -1, plate)
end)

-- Flush on player disconnect
AddEventHandler('playerDropped', function()
    if saveDirty then Save() end
end)

-- ============================================================
-- PERIODIC SAVE & INIT
-- ============================================================

CreateThread(function()
    while true do
        Wait(30000)
        if saveDirty then Save() end
    end
end)

CreateThread(function()
    SaveResourceFile(GetCurrentResourceName(), '../saved_data/.gitkeep', '', -1)
    Load()
end)

AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() ~= res then return end
    Wait(200)
    Save()
    print('[my_vehicles] Saved on resource stop')
end)
