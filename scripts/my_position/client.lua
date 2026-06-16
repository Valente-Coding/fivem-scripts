-- Track if we've spawned and teleported
local hasSpawned = false

-- Request saved position when player spawns
AddEventHandler('playerSpawned', function()
    if not hasSpawned then
        hasSpawned = true
        TriggerServerEvent('my_position:requestPosition')
    end
end)

-- Receive position from server and teleport
RegisterNetEvent('my_position:loadPosition')
AddEventHandler('my_position:loadPosition', function(x, y, z, heading)
    -- Wait for player to fully load before teleporting
    Wait(Config.SpawnDelay)
    
    local playerPed = PlayerPedId()
    
    -- Teleport to saved position
    SetEntityCoords(playerPed, x, y, z, false, false, false, true)
    SetEntityHeading(playerPed, heading)
end)

-- Periodically send position updates to server
CreateThread(function()
    while true do
        Wait(Config.UpdateInterval)
        
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        
        -- Send current position to server
        TriggerServerEvent('my_position:updatePosition', coords.x, coords.y, coords.z, heading)
    end
end)


