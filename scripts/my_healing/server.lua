-- Healing Station Server
local costPerPercent = 100

-- Save player health
RegisterNetEvent('my_healing:saveHealth')
AddEventHandler('my_healing:saveHealth', function(healthPercent)
    local _source = source
    if type(healthPercent) ~= 'number' then return end
    healthPercent = math.floor(healthPercent)
    if healthPercent < 0 then healthPercent = 0 end
    if healthPercent > 100 then healthPercent = 100 end
    exports['my_datamanager']:SetPlayerDataKey(_source, 'health', { percent = healthPercent })
end)

-- Load player health on request
RegisterNetEvent('my_healing:requestHealth')
AddEventHandler('my_healing:requestHealth', function()
    local _source = source
    local data = exports['my_datamanager']:GetPlayerDataKey(_source, 'health')
    if data and data.percent then
        TriggerClientEvent('my_healing:loadHealth', _source, data.percent)
    end
end)

-- Save health on disconnect
AddEventHandler('playerDropped', function()
    -- Health is already periodically saved by client, nothing extra needed
end)

-- Heal player (partial or full)
RegisterNetEvent('my_healing:healPlayer')
AddEventHandler('my_healing:healPlayer', function(healPercent)
    local _source = source

    local playerPed = GetPlayerPed(_source)
    if not playerPed or playerPed == 0 then return end

    -- Validate client-sent value (must be 1-100)
    if type(healPercent) ~= 'number' then return end
    healPercent = math.floor(healPercent)
    if healPercent > 100 then healPercent = 100 end

    if healPercent <= 0 then
        TriggerClientEvent('chatMessage', _source, "^3[Healing]^7", "", "You are already at full health.")
        return
    end

    local totalCost = healPercent * costPerPercent

    -- Check if player has enough cash
    local playerCash = exports['my_money']:GetMoney(_source, 'cash')
    if playerCash >= totalCost then
        local success = exports['my_money']:RemoveMoney(_source, 'cash', totalCost)
        if success then
            TriggerClientEvent('my_healing:heal', _source, healPercent)
            TriggerClientEvent('chatMessage', _source, "^2[Healing]^7", "", "Charged $" .. totalCost .. " for healing " .. healPercent .. "% health.")
        else
            TriggerClientEvent('chatMessage', _source, "^1[Healing]^7", "", "Payment failed.")
        end
    else
        TriggerClientEvent('chatMessage', _source, "^1[Healing]^7", "", "You need $" .. totalCost .. " cash to heal.")
    end
end)

