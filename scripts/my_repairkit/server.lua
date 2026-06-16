-- Repair Kit Server

RegisterNetEvent('my_repairkit:request')
AddEventHandler('my_repairkit:request', function(plate, netId)
    local _source = source

    if not plate or plate == "" then
        TriggerClientEvent('my_repairkit:denied', _source, "Invalid vehicle")
        return
    end

    local trimmedPlate = string.gsub(plate, '^%s*(.-)%s*$', '%1')

    -- Check ownership via my_vehicles
    local vehicleData = exports['my_vehicles']:GetVehicleData(trimmedPlate)
    if not vehicleData then
        TriggerClientEvent('my_repairkit:denied', _source, "This vehicle is not registered")
        return
    end

    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if not license or vehicleData.owner ~= license then
        TriggerClientEvent('my_repairkit:denied', _source, "You can only repair vehicles you own")
        return
    end

    -- Charge for the repair kit
    local success = exports['my_money']:RemoveMoney(_source, 'cash', Config.RepairPrice)
    if not success then
        TriggerClientEvent('my_repairkit:denied', _source, "Not enough cash ($" .. Config.RepairPrice .. " needed)")
        return
    end

    TriggerClientEvent('my_repairkit:approved', _source, netId)
    TriggerClientEvent('chatMessage', _source, "^2[RepairKit]^7", "", "You paid $" .. Config.RepairPrice .. " for a repair kit")
end)

-- Broadcast repair to ALL clients so everyone sees it
RegisterNetEvent('my_repairkit:doRepair')
AddEventHandler('my_repairkit:doRepair', function(netId)
    TriggerClientEvent('my_repairkit:syncRepair', -1, netId)
end)

