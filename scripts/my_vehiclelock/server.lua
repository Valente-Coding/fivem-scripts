-- my_vehiclelock/server.lua
-- Persistent vehicle lock/unlock system
-- Lock state is stored in global_vehicles.json via my_vehicles exports

local function NormalizePlate(plate)
    if not plate then return nil end
    return string.upper(string.gsub(tostring(plate), "%s+", ""))
end

-- ============================================================
-- EVENTS
-- ============================================================

-- Client requests to toggle lock on a vehicle they own
RegisterNetEvent('my_vehiclelock:toggleLock')
AddEventHandler('my_vehiclelock:toggleLock', function(plate)
    local _source = source
    plate = NormalizePlate(plate)
    if not plate then return end

    -- Verify vehicle exists
    local vehicleData = exports['my_vehicles']:GetVehicleData(plate)
    if not vehicleData then return end

    -- Verify the requesting player is the owner
    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if not license or vehicleData.owner ~= license then
        return -- not the owner, ignore
    end

    -- Toggle lock state
    local currentlyLocked = exports['my_vehicles']:GetVehicleLocked(plate)
    local newLocked = not currentlyLocked

    -- Persist to global_vehicles.json
    exports['my_vehicles']:SetVehicleLocked(plate, newLocked)

    -- Broadcast to ALL clients so the lock applies instantly for everyone
    TriggerClientEvent('my_vehiclelock:applyLockState', -1, plate, newLocked)
end)

-- Client requesting to know the current lock states on join
RegisterNetEvent('my_vehiclelock:requestLockStates')
AddEventHandler('my_vehiclelock:requestLockStates', function()
    local _source = source
    local allVehicles = exports['my_vehicles']:GetAllVehicles()
    if not allVehicles then return end

    -- Build a table of plate -> locked for all vehicles that have a lock state
    local lockStates = {}
    for plate, data in pairs(allVehicles) do
        lockStates[plate] = (data.locked == true)
    end

    TriggerClientEvent('my_vehiclelock:loadLockStates', _source, lockStates)
end)
