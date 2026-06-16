-- my_motels/client.lua
-- Client-side logic for hotel/motel system

-- Local state
local isUIOpen = false
local currentMotel = nil
local motelBlips = {}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

local function getDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

local function createMotelBlip(motel)
    local blip = AddBlipForCoord(motel.reception.x, motel.reception.y, motel.reception.z)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(motel.name)
    EndTextCommandSetBlipName(blip)

    return blip
end

local function openMotelUI(motel)
    if isUIOpen then return end
    currentMotel = motel
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        motelName = motel.name,
        price = motel.price
    })
end

local function closeMotelUI()
    if not isUIOpen then return end
    isUIOpen = false
    currentMotel = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ============================================================
-- THREADS
-- ============================================================

-- Main interaction thread
CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for i, motel in ipairs(Config.Motels) do
            local distance = getDistance(
                playerCoords.x, playerCoords.y, playerCoords.z,
                motel.reception.x, motel.reception.y, motel.reception.z
            )

            if distance <= Config.InteractionDistance then
                sleep = 0

                -- Draw marker
                DrawMarker(Config.Marker.type,
                    motel.reception.x, motel.reception.y, motel.reception.z + Config.Marker.zOffset,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    Config.Marker.scale.x, Config.Marker.scale.y, Config.Marker.scale.z,
                    Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
                    Config.Marker.bobUpAndDown, false, 2, Config.Marker.rotate, nil, nil, false)

                -- Help text
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to check in")
                EndTextCommandDisplayHelp(0, false, true, -1)

                -- E key pressed
                if IsControlJustReleased(0, 38) and not isUIOpen then
                    openMotelUI(motel)
                end
            end
        end

        Wait(sleep)
    end
end)

-- Input control thread (disable controls when UI is open)
CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 106, true)
            if IsControlJustReleased(0, 322) then
                closeMotelUI()
            end
        else
            Wait(500)
        end
    end
end)

-- ============================================================
-- EVENTS
-- ============================================================

RegisterNetEvent('my_motels:checkInSuccess')
AddEventHandler('my_motels:checkInSuccess', function(motelData)
    -- Screen should already be black at this point
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local roomHeading = motelData.room.heading or 0.0

    -- Teleport while screen is black
    if motelData.vehicleAccess and vehicle ~= 0 then
        SetEntityCoords(vehicle, motelData.room.x, motelData.room.y, motelData.room.z, false, false, false, true)
        SetEntityHeading(vehicle, roomHeading)
        SetVehicleOnGroundProperly(vehicle)
    else
        SetEntityCoords(playerPed, motelData.room.x, motelData.room.y, motelData.room.z, false, false, false, true)
        SetEntityHeading(playerPed, roomHeading)
    end

    -- Set random weather
    local weatherList = Config.WeatherTypes
    local randomWeather = weatherList[math.random(#weatherList)]
    SetWeatherTypeNowPersist(randomWeather)

    -- Wait a moment for the teleport to settle
    Wait(1000)

    -- Fade screen back in
    DoScreenFadeIn(Config.FadeDuration)

    -- Notification
    SetNotificationTextEntry("STRING")
    AddTextComponentString("~g~Good morning! You slept at ~y~" .. motelData.name .. "~g~. It's now 8:00 AM.")
    DrawNotification(false, false)
end)

RegisterNetEvent('my_motels:checkInFailure')
AddEventHandler('my_motels:checkInFailure', function(errorMessage)
    -- Fade back in if screen was blacked out
    if IsScreenFadedOut() then
        DoScreenFadeIn(Config.FadeDuration)
    end

    SetNotificationTextEntry("STRING")
    AddTextComponentString("~r~" .. (errorMessage or "Check-in failed"))
    DrawNotification(false, false)
end)

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback('confirmCheckIn', function(data, cb)
    if currentMotel then
        local motelIndex = nil
        for i, motel in ipairs(Config.Motels) do
            if motel.name == currentMotel.name then
                motelIndex = i
                break
            end
        end

        if motelIndex then
            -- Close UI and fade to black FIRST
            closeMotelUI()

            DoScreenFadeOut(Config.FadeDuration)

            -- Wait until fully black, then send to server
            CreateThread(function()
                while not IsScreenFadedOut() do
                    Wait(10)
                end
                -- Now screen is black, request check-in from server
                TriggerServerEvent('my_motels:requestCheckIn', motelIndex)
            end)
        end
    end
    cb({ success = true })
end)

RegisterNUICallback('close', function(data, cb)
    closeMotelUI()
    cb({ success = true })
end)

-- ============================================================
-- INITIALIZATION
-- ============================================================

CreateThread(function()
    for i, motel in ipairs(Config.Motels) do
        motelBlips[i] = createMotelBlip(motel)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, blip in pairs(motelBlips) do
        if blip then RemoveBlip(blip) end
    end
end)
