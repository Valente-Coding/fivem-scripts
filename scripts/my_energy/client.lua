-- Request energy from server when player loads
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('my_energy:requestEnergy')
end)

-- Receive energy updates from server
RegisterNetEvent('my_energy:updateEnergy')
AddEventHandler('my_energy:updateEnergy', function(energy)
    SendNUIMessage({
        action = 'updateEnergy',
        energy = energy,
        maxEnergy = Config.MaxEnergy
    })
end)

-- Kill the player when energy reaches 0
RegisterNetEvent('my_energy:killPlayer')
AddEventHandler('my_energy:killPlayer', function()
    local ped = PlayerPedId()
    if not IsEntityDead(ped) then
        SetEntityHealth(ped, 0)
    end
end)
