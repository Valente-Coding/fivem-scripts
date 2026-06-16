-- my_premiumdeluxe/client.lua
-- Client-side logic for dealership purchase system

-- Local state
local isUIOpen = false
local isOwned = false
local dealershipBlip = nil

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

local function getDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

local function createDealershipBlip()
    local d = Config.Dealership
    local blip = AddBlipForCoord(d.coords.x, d.coords.y, d.coords.z)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(d.name)
    EndTextCommandSetBlipName(blip)

    return blip
end

local function updateBlipColor()
    if dealershipBlip then
        if isOwned then
            SetBlipColour(dealershipBlip, Config.Blip.ownedColor)
        else
            SetBlipColour(dealershipBlip, Config.Blip.color)
        end
    end
end

local function openDealershipUI()
    if isUIOpen then return end
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        dealershipName = Config.Dealership.name,
        price = Config.Dealership.price,
        owned = isOwned
    })
end

local function closeDealershipUI()
    if not isUIOpen then return end
    isUIOpen = false
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
        local d = Config.Dealership

        local distance = getDistance(
            playerCoords.x, playerCoords.y, playerCoords.z,
            d.coords.x, d.coords.y, d.coords.z
        )

        if distance <= Config.InteractionDistance then
            sleep = 0

            -- Draw marker
            DrawMarker(Config.Marker.type,
                d.coords.x, d.coords.y, d.coords.z + Config.Marker.zOffset,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                Config.Marker.scale.x, Config.Marker.scale.y, Config.Marker.scale.z,
                Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
                Config.Marker.bobUpAndDown, false, 2, Config.Marker.rotate, nil, nil, false)

            -- Help text
            if isOwned then
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to view your dealership")
                EndTextCommandDisplayHelp(0, false, true, -1)
            else
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to buy this dealership")
                EndTextCommandDisplayHelp(0, false, true, -1)
            end

            -- E key pressed
            if IsControlJustReleased(0, 38) and not isUIOpen then
                openDealershipUI()
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
                closeDealershipUI()
            end
        else
            Wait(500)
        end
    end
end)

-- ============================================================
-- EVENTS
-- ============================================================

RegisterNetEvent('my_premiumdeluxe:purchaseSuccess')
AddEventHandler('my_premiumdeluxe:purchaseSuccess', function()
    isOwned = true
    updateBlipColor()

    SetNotificationTextEntry("STRING")
    AddTextComponentString("~g~Congratulations! You now own ~y~" .. Config.Dealership.name .. "~g~!")
    DrawNotification(false, false)
end)

RegisterNetEvent('my_premiumdeluxe:purchaseFailure')
AddEventHandler('my_premiumdeluxe:purchaseFailure', function(errorMessage)
    SetNotificationTextEntry("STRING")
    AddTextComponentString("~r~" .. (errorMessage or "Purchase failed"))
    DrawNotification(false, false)
end)

RegisterNetEvent('my_premiumdeluxe:ownershipStatus')
AddEventHandler('my_premiumdeluxe:ownershipStatus', function(owned)
    isOwned = owned
    updateBlipColor()
end)

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback('confirmPurchase', function(data, cb)
    if not isOwned then
        closeDealershipUI()
        TriggerServerEvent('my_premiumdeluxe:requestPurchase')
    end
    cb({ success = true })
end)

RegisterNUICallback('close', function(data, cb)
    closeDealershipUI()
    cb({ success = true })
end)

-- ============================================================
-- INITIALIZATION
-- ============================================================

CreateThread(function()
    dealershipBlip = createDealershipBlip()

    -- Request ownership status from server
    TriggerServerEvent('my_premiumdeluxe:checkOwnership')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if dealershipBlip then
        RemoveBlip(dealershipBlip)
    end
end)

-- ============================================================
-- Clear stationary NPCs and parked NPC vehicles around owned
-- dealership (20m radius) - same logic as my_housing
-- ============================================================
local CLEAR_RADIUS = 20.0

CreateThread(function()
    while true do
        Wait(4000) -- check every 4 seconds

        if not isOwned then
            goto skipClear
        end

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local dealershipVec = vector3(Config.Dealership.coords.x, Config.Dealership.coords.y, Config.Dealership.coords.z)

        -- Only bother if player is within 100m
        if #(playerCoords - dealershipVec) >= 100.0 then
            goto skipClear
        end

        -- Helper: is a coord inside the clear zone?
        local function IsInClearZone(coords)
            return #(coords - dealershipVec) <= CLEAR_RADIUS
        end

        -- 1) Remove stationary NPCs
        local allPeds = GetGamePool('CPed')
        for _, ped in ipairs(allPeds) do
            if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
                local pedCoords = GetEntityCoords(ped)
                if IsInClearZone(pedCoords) then
                    local speed = GetEntitySpeed(ped)
                    if speed < 0.5 then
                        SetEntityAsMissionEntity(ped, true, true)
                        DeleteEntity(ped)
                    end
                end
            end
        end

        -- 2) Remove parked NPC vehicles (stopped, no player inside, not player-owned)
        local allVehicles = GetGamePool('CVehicle')
        for _, vehicle in ipairs(allVehicles) do
            if DoesEntityExist(vehicle) and IsVehicleStopped(vehicle) then
                local vehCoords = GetEntityCoords(vehicle)
                if IsInClearZone(vehCoords) then
                    -- Skip vehicles registered in my_vehicles (player-owned persistent cars)
                    local plateRaw = GetVehicleNumberPlateText(vehicle)
                    if plateRaw then
                        local plate = string.upper(string.gsub(tostring(plateRaw), '%s+', ''))
                        if exports['my_vehicles']:DoesPlateExist(plate) then
                            goto nextVeh
                        end
                    end

                    -- Make sure no player is sitting in the vehicle
                    local hasPlayer = false
                    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
                        local seatPed = GetPedInVehicleSeat(vehicle, seat)
                        if seatPed ~= 0 and IsPedAPlayer(seatPed) then
                            hasPlayer = true
                            break
                        end
                    end

                    if not hasPlayer then
                        SetEntityAsMissionEntity(vehicle, true, true)
                        DeleteEntity(vehicle)
                    end

                    ::nextVeh::
                end
            end
        end

        -- 3) Suppress vehicle generators so parked cars don't respawn
        RemoveVehiclesFromGeneratorsInArea(
            dealershipVec.x - CLEAR_RADIUS, dealershipVec.y - CLEAR_RADIUS, dealershipVec.z - CLEAR_RADIUS,
            dealershipVec.x + CLEAR_RADIUS, dealershipVec.y + CLEAR_RADIUS, dealershipVec.z + CLEAR_RADIUS,
            0
        )

        ::skipClear::
    end
end)

-- Scenario-ped suppression frame loop (prevents new NPCs/vehicles from spawning)
CreateThread(function()
    while true do
        if isOwned then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dealershipVec = vector3(Config.Dealership.coords.x, Config.Dealership.coords.y, Config.Dealership.coords.z)

            if #(playerCoords - dealershipVec) <= CLEAR_RADIUS + 10.0 then
                SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
                SetVehicleDensityMultiplierThisFrame(0.0)
                SetParkedVehicleDensityMultiplierThisFrame(0.0)
                SetRandomVehicleDensityMultiplierThisFrame(0.0)
                Wait(0)
            else
                Wait(500)
            end
        else
            Wait(1000)
        end
    end
end)
