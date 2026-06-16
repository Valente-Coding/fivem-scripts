-- Repair Kit Client
local isRepairing = false

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

RegisterCommand('repairkit', function()
    if isRepairing then
        ShowNotification("~r~Already repairing!")
        return
    end

    local playerPed = PlayerPedId()

    -- Must be outside vehicle
    if IsPedInAnyVehicle(playerPed, false) then
        ShowNotification("~r~You must exit the vehicle first")
        return
    end

    -- Check for nearby vehicle
    local coords = GetEntityCoords(playerPed)
    if not IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, Config.MaxDistance) then
        ShowNotification("~r~No vehicle nearby")
        return
    end

    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, Config.MaxDistance, 0, 71)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        ShowNotification("~r~No vehicle found")
        return
    end

    -- Check if vehicle needs repair
    if GetVehicleEngineHealth(vehicle) >= 1000.0 and GetVehicleBodyHealth(vehicle) >= 1000.0 then
        ShowNotification("~g~Vehicle is already in perfect condition")
        return
    end

    -- Get plate and request ownership check + payment
    local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('my_repairkit:request', plate, netId)
end, false)

-- Server approved repair - play animation locally, then broadcast repair
RegisterNetEvent('my_repairkit:approved')
AddEventHandler('my_repairkit:approved', function(netId)
    local playerPed = PlayerPedId()

    isRepairing = true
    ShowNotification("~o~Repairing vehicle... (" .. math.floor(Config.RepairDuration / 1000) .. "s)")

    -- Play repair animation
    TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_BUM_BIN', 0, true)

    Wait(Config.RepairDuration)

    ClearPedTasksImmediately(playerPed)
    isRepairing = false

    -- Tell server to broadcast the repair to ALL clients
    TriggerServerEvent('my_repairkit:doRepair', netId)

    ShowNotification("~g~Vehicle repaired successfully!")
end)

-- All clients receive this to sync the repair
RegisterNetEvent('my_repairkit:syncRepair')
AddEventHandler('my_repairkit:syncRepair', function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
    end
end)

-- Server denied
RegisterNetEvent('my_repairkit:denied')
AddEventHandler('my_repairkit:denied', function(reason)
    ShowNotification("~r~" .. (reason or "Cannot repair"))
end)
