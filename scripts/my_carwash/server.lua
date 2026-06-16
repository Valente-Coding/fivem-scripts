-- Car Wash Server

RegisterNetEvent('my_carwash:requestWash')
AddEventHandler('my_carwash:requestWash', function(vehNet, useProps)
    local _source = source

    local playerCash = exports['my_money']:GetMoney(_source, 'cash')
    if playerCash >= Config.Cost then
        local success = exports['my_money']:RemoveMoney(_source, 'cash', Config.Cost)
        if success then
            TriggerClientEvent('my_carwash:washApproved', _source, vehNet, useProps)
        else
            TriggerClientEvent('my_carwash:washDenied', _source)
        end
    else
        TriggerClientEvent('my_carwash:washDenied', _source)
    end
end)

RegisterNetEvent('carwash:DoVehicleWashParticles')
AddEventHandler('carwash:DoVehicleWashParticles', function(vehNet, useProps)
    local src = source
    TriggerClientEvent('carwash:DoVehicleWashParticles', -1, vehNet, src, useProps)
end)

