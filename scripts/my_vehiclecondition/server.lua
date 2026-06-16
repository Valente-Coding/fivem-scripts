-- my_vehiclecondition/server.lua
-- Verifies the requesting player owns the vehicle, then reports its
-- Engine, Brakes, Clutch and Suspension condition.
-- Condition values are hardcoded to 100% for now (testing only).

local function NormalizePlate(plate)
    if not plate then return nil end
    return string.upper(string.gsub(tostring(plate), "%s+", ""))
end

RegisterNetEvent('my_vehiclecondition:check')
AddEventHandler('my_vehiclecondition:check', function(plate)
    local _source = source
    plate = NormalizePlate(plate)
    if not plate then return end

    local vehicleData = exports['my_vehicles']:GetVehicleData(plate)
    if not vehicleData then
        TriggerClientEvent('my_vehiclecondition:denied', _source)
        return
    end

    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if not license or vehicleData.owner ~= license then
        TriggerClientEvent('my_vehiclecondition:denied', _source)
        return
    end

    TriggerClientEvent('my_vehiclecondition:result', _source, {
        engine = 100,
        brakes = 100,
        clutch = 100,
        suspension = 100,
    })
end)
