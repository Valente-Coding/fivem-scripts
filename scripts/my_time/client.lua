-- Request current time from server when resource starts
CreateThread(function()
    Wait(1000) -- Wait for UI to load
    TriggerServerEvent('my_time:requestCurrentTime')
end)

-- Event handler to update time display in UI
RegisterNetEvent('my_time:updateTime')
AddEventHandler('my_time:updateTime', function(timeData)
    -- Send update to NUI
    SendNUIMessage({
        type = 'updateTime',
        day = timeData.dayName,
        hour = string.format("%02d", timeData.hour),
        minute = string.format("%02d", timeData.minute),
        daysPassed = timeData.daysPassed
    })
end)

-- Event handler to sync game time
RegisterNetEvent('my_time:syncGameTime')
AddEventHandler('my_time:syncGameTime', function(hour, minute)
    NetworkOverrideClockTime(hour, minute, 0)
end)

