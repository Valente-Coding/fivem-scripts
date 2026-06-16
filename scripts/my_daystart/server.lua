-- /daystart – sets the server time to 8:00 AM and refills the player's energy to 100%

RegisterCommand('daystart', function(source, args, rawCommand)
    -- Set server time to 08:00
    local timeOk = exports['my_time']:SetSpecificTime(8, 0)

    if source > 0 then
        -- Refill the player's energy
        exports['my_energy']:RefillEnergy(source)

        TriggerClientEvent('chat:addMessage', source, {
            args = { '^2[DayStart]', 'Time set to 8:00 AM and energy fully restored!' }
        })
    else
        -- Ran from server console – no player to refill
        print('[DayStart] Time set to 8:00 AM (energy refill skipped – no player context)')
    end
end, false) -- false = no ACE permission required

print('^2[my_daystart] /daystart command loaded^7')
