RegisterCommand('opendoors', function()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)

        -- Open all doors
        SetVehicleDoorOpen(vehicle, 0, false, true) -- Front left door
        SetVehicleDoorOpen(vehicle, 1, false, true) -- Front right door
        SetVehicleDoorOpen(vehicle, 2, false, true) -- Back left door
        SetVehicleDoorOpen(vehicle, 3, false, true) -- Back right door

        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            multiline = true,
            args = {"System", "All vehicle doors have been opened."}
        })
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", "You are not in a vehicle."}
        })
    end
end)