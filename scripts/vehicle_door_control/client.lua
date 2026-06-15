-- RegisterCommand to open a vehicle door
RegisterCommand('opendoor', function(source, args)
    local playerPed = PlayerPedId() -- Get the player's ped
    local vehicle = GetVehiclePedIsIn(playerPed, false) -- Check if the player is in a vehicle

    if DoesEntityExist(vehicle) then -- Ensure the vehicle exists
        local doorIndex = tonumber(args[1]) or 0 -- Default to the driver's door if no argument is given

        if doorIndex >= 0 and doorIndex <= 5 then
            SetVehicleDoorOpen(vehicle, doorIndex, false, true) -- Open the specified door
            TriggerEvent('chat:addMessage', {
                args = { '^2Vehicle Door Control:', 'Door ' .. doorIndex .. ' opened.' }
            })
        else
            TriggerEvent('chat:addMessage', {
                args = { '^1Vehicle Door Control:', 'Invalid door index. Please use a number between 0 and 5.' }
            })
        end
    else
        TriggerEvent('chat:addMessage', {
            args = { '^1Vehicle Door Control:', 'You are not in a vehicle.' }
        })
    end
end, false)

-- RegisterCommand to close a vehicle door
RegisterCommand('closedoor', function(source, args)
    local playerPed = PlayerPedId() -- Get the player's ped
    local vehicle = GetVehiclePedIsIn(playerPed, false) -- Check if the player is in a vehicle

    if DoesEntityExist(vehicle) then -- Ensure the vehicle exists
        local doorIndex = tonumber(args[1]) or 0 -- Default to the driver's door if no argument is given

        if doorIndex >= 0 and doorIndex <= 5 then
            SetVehicleDoorShut(vehicle, doorIndex, false) -- Close the specified door
            TriggerEvent('chat:addMessage', {
                args = { '^2Vehicle Door Control:', 'Door ' .. doorIndex .. ' closed.' }
            })
        else
            TriggerEvent('chat:addMessage', {
                args = { '^1Vehicle Door Control:', 'Invalid door index. Please use a number between 0 and 5.' }
            })
        end
    else
        TriggerEvent('chat:addMessage', {
            args = { '^1Vehicle Door Control:', 'You are not in a vehicle.' }
        })
    end
end, false)

--- @lint ignore undefined_var RegisterCommand
--- @lint ignore undefined_var PlayerPedId
--- @lint ignore undefined_var GetVehiclePedIsIn
--- @lint ignore undefined_var DoesEntityExist
--- @lint ignore undefined_var SetVehicleDoorOpen
--- @lint ignore undefined_var TriggerEvent
--- @lint ignore undefined_var SetVehicleDoorShut