```lua
local function openVehicleDoors()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        for i = 0, 5 do
            SetVehicleDoorOpen(vehicle, i, false, true)
        end
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", "You are not in a vehicle."}
        })
    end
end

RegisterCommand('openvehdoors', function()
    openVehicleDoors()
end, false)
```