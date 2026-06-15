local currentVehicle = nil

RegisterCommand('car', function(source, args)
    local model = table.concat(args, " ")
    if IsModelValid(model) and IsModelAVehicle(model) then
        RequestModel(model)

        while not HasModelLoaded(model) do
            Wait(10)
        end

        if currentVehicle ~= nil then
            DeleteEntity(currentVehicle)
        end

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed, false)
        local heading = GetEntityHeading(playerPed)

        currentVehicle = CreateVehicle(model, playerCoords.x, playerCoords.y, playerCoords.z, heading, true, false)
        SetModelAsNoLongerNeeded(model)
        TaskWarpPedIntoVehicle(playerPed, currentVehicle, -1)
    else
        TriggerEvent('chat:addMessage', {args = {"System", "Invalid vehicle model."}})
    end
end, false)

RegisterNetEvent('onResourceStop')
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName and currentVehicle ~= nil then
        DeleteEntity(currentVehicle)
    end
end)