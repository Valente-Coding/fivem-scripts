-- my_vehiclecondition/client.lua
-- Press H while on foot near a vehicle to check its
-- Engine, Brakes, Clutch and Suspension condition.
-- Only the owner of the vehicle can check it.

local CHECK_RANGE = 5.0

local function TrimPlate(plate)
    if not plate then return "" end
    return string.upper(string.gsub(tostring(plate), "%s+", ""))
end

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function CheckNearestVehicle()
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then return end

    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, CHECK_RANGE, 0, 71)

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        ShowNotification("~r~No vehicle nearby")
        return
    end

    local plate = TrimPlate(GetVehicleNumberPlateText(vehicle))
    TriggerServerEvent('my_vehiclecondition:check', plate)
end

RegisterCommand('vehiclecondition', function()
    CheckNearestVehicle()
end, false)

RegisterKeyMapping('vehiclecondition', 'Check Vehicle Condition', 'keyboard', 'h')

-- ============================================================
-- SERVER RESPONSES
-- ============================================================

RegisterNetEvent('my_vehiclecondition:denied')
AddEventHandler('my_vehiclecondition:denied', function()
    ShowNotification("~r~You have no business checking this vehicle!")
end)

RegisterNetEvent('my_vehiclecondition:result')
AddEventHandler('my_vehiclecondition:result', function(condition)
    local msg = string.format(
        "~b~Vehicle Condition~s~\nEngine: ~g~%d%%~s~\nBrakes: ~g~%d%%~s~\nClutch: ~g~%d%%~s~\nSuspension: ~g~%d%%~s~",
        condition.engine, condition.brakes, condition.clutch, condition.suspension
    )
    ShowNotification(msg)
end)
