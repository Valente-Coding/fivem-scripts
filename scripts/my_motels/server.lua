-- my_motels/server.lua
-- Server-side logic for hotel/motel system

-- ============================================================
-- CHECK-IN HANDLER
-- ============================================================

RegisterNetEvent('my_motels:requestCheckIn')
AddEventHandler('my_motels:requestCheckIn', function(motelIndex)
    local source = source

    -- Validate motel index
    if not motelIndex or not Config.Motels[motelIndex] then
        TriggerClientEvent('my_motels:checkInFailure', source, "Invalid motel.")
        return
    end

    local motel = Config.Motels[motelIndex]

    -- Check if player has enough money (cash only)
    local playerCash = exports['my_money']:GetMoney(source, 'cash')

    if playerCash < motel.price then
        TriggerClientEvent('my_motels:checkInFailure', source, "Not enough money. You need $" .. motel.price .. ".")
        return
    end

    -- Remove money
    local removed = exports['my_money']:RemoveMoney(source, 'cash', motel.price)

    if not removed then
        TriggerClientEvent('my_motels:checkInFailure', source, "Payment failed. Please try again.")
        return
    end

    -- Advance time to 8AM using my_time
    local currentTime = exports['my_time']:GetCurrentTime()

    if currentTime then
        local targetDay = currentTime.dayOfWeek

        -- If it's already past (or at) the wake-up hour, advance to the next day
        -- If it's past midnight but before wake-up hour, stay on the same day
        if currentTime.hour >= Config.WakeUpHour then
            targetDay = targetDay + 1
            if targetDay > 7 then
                targetDay = 1
            end
        end

        exports['my_time']:SetSpecificTime(Config.WakeUpHour, Config.WakeUpMinute, targetDay)
    end

    -- Refill player energy
    exports['my_energy']:RefillEnergy(source)

    -- Send success to client with motel data
    TriggerClientEvent('my_motels:checkInSuccess', source, {
        name = motel.name,
        room = motel.room,
        vehicleAccess = motel.vehicleAccess or false
    })

    -- Flash money display
    TriggerClientEvent('my_money:flashMoney', source, 'cash')

    print("[my_motels] " .. GetPlayerName(source) .. " checked in at " .. motel.name .. " for $" .. motel.price)
end)
