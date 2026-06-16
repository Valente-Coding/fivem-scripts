-- Clean Vehicle Server

RegisterNetEvent('my_cleanvehicle:checkOwnership')
AddEventHandler('my_cleanvehicle:checkOwnership', function(plate, netId)
    local _source = source

    if not plate or plate == "" then
        TriggerClientEvent('my_cleanvehicle:denied', _source)
        return
    end

    -- Trim plate
    local trimmedPlate = string.gsub(plate, '^%s*(.-)%s*$', '%1')

    -- Check ownership via my_vehicles export
    local vehicleData = exports['my_vehicles']:GetVehicleData(trimmedPlate)

    if not vehicleData then
        TriggerClientEvent('my_cleanvehicle:denied', _source)
        return
    end

    -- Get player license and compare
    local license = exports['my_datamanager']:GetPlayerLicense(_source)

    if license and vehicleData.owner == license then
        TriggerClientEvent('my_cleanvehicle:approved', _source, netId)
    else
        TriggerClientEvent('my_cleanvehicle:denied', _source)
    end
end)

-- Broadcast clean to ALL clients so everyone sees it
RegisterNetEvent('my_cleanvehicle:doClean')
AddEventHandler('my_cleanvehicle:doClean', function(netId)
    TriggerClientEvent('my_cleanvehicle:syncClean', -1, netId)
end)

