local lastHealth = -1

CreateThread(function()
    while true do
        Wait(500)

        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        local maxHealth = GetEntityMaxHealth(ped)

        -- GTA health starts at 100 (dead) up to maxHealth
        -- So effective health = (health - 100) out of (maxHealth - 100)
        local effectiveHealth = math.max(0, health - 100)
        local effectiveMax = math.max(1, maxHealth - 100)
        local percent = math.floor((effectiveHealth / effectiveMax) * 100)
        percent = math.min(100, math.max(0, percent))

        if percent ~= lastHealth then
            lastHealth = percent
            SendNUIMessage({
                action = 'updateHealth',
                health = percent
            })
        end
    end
end)
