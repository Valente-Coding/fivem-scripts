-- Player position cache (stores current position for each connected player)
local playerPositions = {}

-- Client sends position updates periodically
RegisterNetEvent('my_position:updatePosition')
AddEventHandler('my_position:updatePosition', function(x, y, z, heading)
    local _source = source
    
    local posData = {
        x = x,
        y = y,
        z = z,
        heading = heading
    }
    
    playerPositions[_source] = posData
    
    -- Save immediately to persistent storage
    exports['my_datamanager']:SetPlayerDataKey(_source, 'position', posData)
end)

-- Client requests their saved position on spawn
RegisterNetEvent('my_position:requestPosition')
AddEventHandler('my_position:requestPosition', function()
    local _source = source
    
    -- Try to load saved position from datamanager
    local savedPos = exports['my_datamanager']:GetPlayerDataKey(_source, 'position')
    
    if savedPos and savedPos.x and savedPos.y and savedPos.z then
        -- Send saved position to client
        TriggerClientEvent('my_position:loadPosition', _source, savedPos.x, savedPos.y, savedPos.z, savedPos.heading or 0.0)
    else
        -- Send default spawn position
        TriggerClientEvent('my_position:loadPosition', _source, Config.DefaultSpawn.x, Config.DefaultSpawn.y, Config.DefaultSpawn.z, Config.DefaultSpawn.heading)
    end
end)

-- Save position when player disconnects
AddEventHandler('playerDropped', function()
    local _source = source
    
    if playerPositions[_source] then
        -- Save position to datamanager
        exports['my_datamanager']:SetPlayerDataKey(_source, 'position', playerPositions[_source])
        
        -- Clear cache
        playerPositions[_source] = nil
    end
end)

-- Export: Reset player position cache (used by permadeath wipe)
exports('ResetPlayerData', function(source)
    playerPositions[source] = nil
end)

