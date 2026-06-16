-- Taxi Client
local uiOpen = false

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function drawCenteredText(msg)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.0, 0.45)
    SetTextColour(255, 255, 255, 200)
    SetTextCentre(true)
    SetTextEdge(1, 0, 0, 0, 255)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayText(0.5, 0.9)
end

local function findSafeCoord(target)
    local x, y, z = target.x, target.y, target.z
    local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z + 50.0, false)
    if foundGround then
        return vector3(x, y, groundZ + 1.0), nil
    end

    local nodeFound, nodeCoord, heading = GetClosestVehicleNodeWithHeading(x, y, z, 1, 3.0, 0)
    if nodeFound then
        return vector3(nodeCoord.x, nodeCoord.y, nodeCoord.z + 1.0), heading
    end

    return vector3(x, y, z + 1.0), nil
end

local function closeUi()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })
    uiOpen = false
end

CreateThread(function()
    Wait(300)
    closeUi()
end)

CreateThread(function()
    while true do
        Wait(0)
        if uiOpen then
            if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then
                closeUi()
            end
        else
            Wait(200)
        end
    end
end)

local function openUi(distance, fare, waitSeconds)
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        title = Config.Text.title,
        distanceLabel = Config.Text.distance,
        fareLabel = Config.Text.fare,
        waitLabel = Config.Text.wait,
        cancel = Config.Text.cancel,
        distance = math.floor(distance + 0.5),
        fare = math.floor(fare + 0.5),
        wait = math.floor(waitSeconds + 0.5)
    })
end

local function findWaypoint()
    local handle = GetFirstBlipInfoId(8)
    if not DoesBlipExist(handle) then return nil end
    local coords = GetBlipInfoIdCoord(handle)
    return vector3(coords.x, coords.y, coords.z)
end

local function computeRide()
    local waypoint = findWaypoint()
    if not waypoint then
        ShowNotification(Config.Text.noWaypoint)
        return nil
    end

    local ped = PlayerPedId()
    local origin = GetEntityCoords(ped)
    local distance = #(origin - waypoint)
    local fare = Config.BaseFare + (distance * Config.PricePerMeter)
    local waitSeconds = distance * Config.WaitSecondsPerMeter

    return {
        waypoint = waypoint,
        distance = distance,
        fare = fare,
        waitSeconds = waitSeconds
    }
end

RegisterCommand(Config.Command, function()
    if uiOpen then
        closeUi()
        return
    end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        ShowNotification(Config.Text.inVehicle)
        return
    end

    local ride = computeRide()
    if not ride then return end

    openUi(ride.distance, ride.fare, ride.waitSeconds)
end, false)

RegisterNUICallback('selectPayment', function(data, cb)
    cb({})
    local choice = data and data.method

    if choice ~= 'confirm' then
        closeUi()
        return
    end

    local ride = computeRide()
    if not ride then
        closeUi()
        return
    end

    closeUi()
    SetNewWaypoint(ride.waypoint.x, ride.waypoint.y)
    TriggerServerEvent('my_taxi:startRide', {
        waypoint = { x = ride.waypoint.x, y = ride.waypoint.y, z = ride.waypoint.z }
    })
end)

RegisterNUICallback('closeUi', function(_, cb)
    cb({})
    if uiOpen then closeUi() end
end)

RegisterCommand(Config.Command .. 'close', function()
    closeUi()
end, false)

RegisterNetEvent('my_taxi:rideFailed')
AddEventHandler('my_taxi:rideFailed', function(message)
    ShowNotification(message or Config.Text.noFunds)
end)

RegisterNetEvent('my_taxi:beginTeleport')
AddEventHandler('my_taxi:beginTeleport', function(payload)
    if not payload or not payload.coords or not payload.waitMs then return end

    local ped = PlayerPedId()
    local waitMs = payload.waitMs
    local target = payload.coords
    local safeCoord, heading = findSafeCoord(target)
    heading = heading or GetEntityHeading(ped)

    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do Wait(50) end

    local startTime = GetGameTimer()
    local endTime = startTime + waitMs

    DoScreenFadeIn(0)
    while GetGameTimer() < endTime do
        Wait(0)
        HideHudAndRadarThisFrame()
        DrawRect(0.5, 0.5, 1.0, 1.0, 0, 0, 0, 255)
        local remaining = math.max(0, math.ceil((endTime - GetGameTimer()) / 1000))
        local msg = string.format(Config.Text.waitProgress or 'Traveling... %ss', remaining)
        drawCenteredText(msg)
    end

    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        SetEntityCoords(vehicle, safeCoord.x, safeCoord.y, safeCoord.z, false, false, false, false)
        SetEntityHeading(vehicle, heading)
    else
        SetEntityCoordsNoOffset(ped, safeCoord.x, safeCoord.y, safeCoord.z, false, false, false)
        SetEntityHeading(ped, heading)
    end

    Wait(300)
    DoScreenFadeIn(1000)
    ShowNotification(Config.Text.teleported)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    closeUi()
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    closeUi()
end)
