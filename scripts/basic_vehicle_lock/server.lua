local vehiclesLockState = {}

RegisterNetEvent('basic_vehicle_lock:toggleLock')
AddEventHandler('basic_vehicle_lock:toggleLock', function(netId)
    if not vehiclesLockState[netId] then
        vehiclesLockState[netId] = false
    end

    vehiclesLockState[netId] = not vehiclesLockState[netId]
    
    TriggerClientEvent('basic_vehicle_lock:updateVehicleState', -1, netId, vehiclesLockState[netId])
end)