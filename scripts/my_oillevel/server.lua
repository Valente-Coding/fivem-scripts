-- my_oillevel/server.lua
-- Server-side: convenience exports

-- ============================================================
-- CONVENIENCE EXPORTS
-- ============================================================

exports('GetOilLevel', function(plate)
    return exports['my_vehicles']:GetVehicleOilLevel(plate)
end)

exports('SetOilLevel', function(plate, amount)
    return exports['my_vehicles']:UpdateVehicleOilLevel(plate, amount)
end)

exports('AddOil', function(plate, amount)
    return exports['my_vehicles']:AddVehicleOil(plate, amount)
end)

-- ============================================================
-- COMMAND: /setoil <level> (in-game, uses current vehicle)
-- Console: setoil <plate> <level>
-- ============================================================

local function NormalizePlate(p)
    if not p then return nil end
    return string.upper(string.gsub(tostring(p), '%s+', ''))
end

-- Server event triggered by the client command
RegisterNetEvent('my_oillevel:requestSetOil')
AddEventHandler('my_oillevel:requestSetOil', function(plate, level)
    local source = source
    plate = NormalizePlate(plate)
    level = tonumber(level)

    if not plate or plate == '' or not level then return end
    level = math.max(0.0, math.min(100.0, level))

    local exists = exports['my_vehicles']:DoesPlateExist(plate)
    if not exists then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1[Oil]', 'Vehicle with plate "' .. plate .. '" not found.' } })
        return
    end

    exports['my_vehicles']:UpdateVehicleOilLevel(plate, level)
    TriggerClientEvent('chat:addMessage', source, { args = { '^2[Oil]', 'Oil level set to ' .. level .. '%' } })
    TriggerClientEvent('my_oillevel:oilLevelUpdated', source, plate, level)
end)

-- Console-only: setoil <plate> <level>
RegisterCommand('setoil', function(source, args, rawCommand)
    if source ~= 0 then return end -- in-game players use client-side command

    local plate = NormalizePlate(args[1])
    local level = tonumber(args[2])

    if not plate or plate == '' or not level then
        print('[Oil] Usage: setoil <plate> <level 0-100>')
        return
    end

    level = math.max(0.0, math.min(100.0, level))

    local exists = exports['my_vehicles']:DoesPlateExist(plate)
    if not exists then
        print('[Oil] Vehicle with plate "' .. plate .. '" not found.')
        return
    end

    exports['my_vehicles']:UpdateVehicleOilLevel(plate, level)
    print('[Oil] Oil level for ' .. plate .. ' set to ' .. level .. '%')
    TriggerClientEvent('my_oillevel:oilLevelUpdated', -1, plate, level)
end, false)
