-- Clean Vehicle Client

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    local attempts = 0
    while not HasAnimDictLoaded(dict) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end
    return HasAnimDictLoaded(dict)
end

local function CleanVehicle(vehicle)
    local playerPed = PlayerPedId()

    -- Freeze player
    FreezeEntityPosition(playerPed, true)

    -- Play cleaning animation
    if LoadAnimDict('mini@repair') then
        TaskPlayAnim(playerPed, 'mini@repair', 'fixing_a_ped', 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    ShowNotification("~o~Cleaning vehicle...")

    -- Wait for cleaning duration
    Wait(Config.CleaningDuration)

    -- Clean the vehicle
    SetVehicleDirtLevel(vehicle, 0.0)
    WashDecalsFromVehicle(vehicle, 1.0)

    -- Stop animation and unfreeze
    ClearPedTasks(playerPed)
    FreezeEntityPosition(playerPed, false)

    ShowNotification("~g~Vehicle cleaned!")
end

RegisterCommand('cleancar', function()
    local playerPed = PlayerPedId()

    -- Check if player is outside vehicle
    if IsPedInAnyVehicle(playerPed, false) then
        ShowNotification("~r~You must be outside the vehicle!")
        return
    end

    -- Find nearest vehicle
    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, Config.MaxDistance, 0, 71)

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        ShowNotification("~r~No vehicle found nearby")
        return
    end

    -- Check distance
    local vehicleCoords = GetEntityCoords(vehicle)
    local distance = #(playerCoords - vehicleCoords)

    if distance > Config.MaxDistance then
        ShowNotification("~r~You are too far from the vehicle")
        return
    end

    -- Get vehicle plate and trim spaces
    local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')

    -- Get vehicle network ID so all clients can sync
    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    -- Check ownership via server
    TriggerServerEvent('my_cleanvehicle:checkOwnership', plate, netId)
end, false)

-- Server confirmed ownership - play animation locally, server will broadcast the clean
RegisterNetEvent('my_cleanvehicle:approved')
AddEventHandler('my_cleanvehicle:approved', function(netId)
    local playerPed = PlayerPedId()

    -- Freeze player and play animation
    FreezeEntityPosition(playerPed, true)

    if LoadAnimDict('mini@repair') then
        TaskPlayAnim(playerPed, 'mini@repair', 'fixing_a_ped', 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    ShowNotification("~o~Cleaning vehicle...")
    Wait(Config.CleaningDuration)

    -- Stop animation and unfreeze
    ClearPedTasks(playerPed)
    FreezeEntityPosition(playerPed, false)

    -- Tell server to broadcast the clean to ALL clients
    TriggerServerEvent('my_cleanvehicle:doClean', netId)

    ShowNotification("~g~Vehicle cleaned!")
end)

-- All clients receive this to sync the clean visuals
RegisterNetEvent('my_cleanvehicle:syncClean')
AddEventHandler('my_cleanvehicle:syncClean', function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetVehicleDirtLevel(vehicle, 0.0)
        WashDecalsFromVehicle(vehicle, 1.0)
    end
end)

-- Server denied ownership
RegisterNetEvent('my_cleanvehicle:denied')
AddEventHandler('my_cleanvehicle:denied', function()
    ShowNotification("~r~This is not your vehicle!")
end)
