-- Taxi Server

RegisterNetEvent('my_taxi:startRide')
AddEventHandler('my_taxi:startRide', function(data)
    local _source = source

    if type(data) ~= 'table' or not data.waypoint then
        TriggerClientEvent('my_taxi:rideFailed', _source, Config.Text.noWaypoint)
        return
    end

    local dest = vector3(
        tonumber(data.waypoint.x) or 0.0,
        tonumber(data.waypoint.y) or 0.0,
        tonumber(data.waypoint.z) or 0.0
    )

    local ped = GetPlayerPed(_source)
    if not ped or ped == 0 then
        TriggerClientEvent('my_taxi:rideFailed', _source, Config.Text.noWaypoint)
        return
    end

    local origin = GetEntityCoords(ped)
    local distance = #(origin - dest)
    local fare = math.floor(Config.BaseFare + (distance * Config.PricePerMeter) + 0.5)
    local waitSeconds = distance * Config.WaitSecondsPerMeter

    -- Check if player has enough cash
    local playerCash = exports['my_money']:GetMoney(_source, 'cash')
    if playerCash < fare then
        TriggerClientEvent('my_taxi:rideFailed', _source, Config.Text.noFunds)
        return
    end

    local success = exports['my_money']:RemoveMoney(_source, 'cash', fare)
    if not success then
        TriggerClientEvent('my_taxi:rideFailed', _source, Config.Text.noFunds)
        return
    end

    local waitMs = math.floor(waitSeconds * 1000)

    TriggerClientEvent('my_taxi:beginTeleport', _source, {
        coords = { x = dest.x, y = dest.y, z = dest.z },
        waitMs = waitMs,
    })

    TriggerClientEvent('chatMessage', _source, "^3[Taxi]^7", "", Config.Text.started)
end)

