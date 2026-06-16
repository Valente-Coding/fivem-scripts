Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        local playerPed = PlayerPedId()
        if IsControlJustPressed(0, Config.LockUnlockKey) then
            local vehicle = GetClosestVehicle(GetEntityCoords(playerPed), Config.LockDistance, 0, 71)
            
            if DoesEntityExist(vehicle) and not IsEntityDeadOrDying(playerPed) then
                local playerCoords = GetEntityCoords(playerPed)
                local vehicleCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -2.5, 0.0)
                
                if #(playerCoords - vehicleCoords) <= Config.LockDistance then
                    TriggerServerEvent('basic_vehicle_lock:toggleLock', VehToNet(vehicle))
                end
            end
        end
    end
end)

RegisterNetEvent('basic_vehicle_lock:updateVehicleState')
AddEventHandler('basic_vehicle_lock:updateVehicleState', function(netId, locked)
    local vehicle = NetToVeh(netId)
    
    if DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(vehicle, locked and 2 or 1)
    end
end)