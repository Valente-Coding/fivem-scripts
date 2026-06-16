-- my_carlot/client.lua
-- Client-side logic for Sandy Shores Car Lot

-- ============================================================
-- STATE
-- ============================================================

local isUIOpen = false
local isOwned = false
local lotBlip = nil
local salesmanPed = nil
local pendingListPlate = nil  -- plate waiting for confirmation

-- ============================================================
-- UTILITY
-- ============================================================

local function getDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

local function getPlate(vehicle)
    local raw = GetVehicleNumberPlateText(vehicle)
    if not raw then return nil end
    return string.upper(string.gsub(tostring(raw), '%s+', ''))
end

-- ============================================================
-- BLIP
-- ============================================================

local function createBlip()
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
    if lotBlip then
        SetBlipColour(lotBlip, isOwned and Config.Blip.ownedColor or Config.Blip.color)
    end
end

-- ============================================================
-- NUI HELPERS
-- ============================================================

local function openUI(mode, data)
    if isUIOpen then return end
    isUIOpen = true
    SetNuiFocus(true, true)
    local msg = data or {}
    msg.action = 'open'
    msg.mode = mode
    SendNUIMessage(msg)
end

local function closeUI()
    if not isUIOpen then return end
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    pendingListPlate = nil
end

-- ============================================================
-- NPC SALESMAN
-- ============================================================

local function spawnSalesman()
    if salesmanPed and DoesEntityExist(salesmanPed) then return end

    local s = Config.Salesman
    local modelHash = GetHashKey(s.model)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then return end

    salesmanPed = CreatePed(4, modelHash, s.coords.x, s.coords.y, s.coords.z, s.heading, false, true)
    SetEntityHeading(salesmanPed, s.heading)
    FreezeEntityPosition(salesmanPed, true)
    SetEntityInvincible(salesmanPed, true)
    SetBlockingOfNonTemporaryEvents(salesmanPed, true)
    TaskStartScenarioInPlace(salesmanPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
    SetModelAsNoLongerNeeded(modelHash)
end

local function deleteSalesman()
    if salesmanPed and DoesEntityExist(salesmanPed) then
        SetEntityAsMissionEntity(salesmanPed, true, true)
        DeleteEntity(salesmanPed)
    end
    salesmanPed = nil
end

-- ============================================================
-- PURCHASE MARKER & INTERACTION THREAD
-- ============================================================

CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local px, py, pz = table.unpack(GetEntityCoords(playerPed))
        local d = Config.Dealership

        local dist = getDistance(px, py, pz, d.coords.x, d.coords.y, d.coords.z)

        if dist <= 20.0 then
            sleep = 0

            -- Draw marker at purchase location
            DrawMarker(Config.Marker.type,
                d.coords.x, d.coords.y, d.coords.z + Config.Marker.zOffset,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                Config.Marker.scale.x, Config.Marker.scale.y, Config.Marker.scale.z,
                Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
                Config.Marker.bobUpAndDown, false, 2, Config.Marker.rotate, nil, nil, false)

            if dist <= Config.InteractionDistance and not IsPedInAnyVehicle(playerPed, false) then
                if not isOwned then
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to buy this car lot")
                    EndTextCommandDisplayHelp(0, false, true, -1)

                    if IsControlJustReleased(0, 38) and not isUIOpen then
                        openUI('purchase', {
                            dealershipName = Config.Dealership.name,
                            price = Config.Dealership.price,
                            owned = false
                        })
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ============================================================
-- SALESMAN INTERACTION THREAD
-- ============================================================

CreateThread(function()
    while true do
        local sleep = 500

        if isOwned and salesmanPed and DoesEntityExist(salesmanPed) then
            local playerPed = PlayerPedId()
            local px, py, pz = table.unpack(GetEntityCoords(playerPed))
            local s = Config.Salesman
            local dist = getDistance(px, py, pz, s.coords.x, s.coords.y, s.coords.z)

            if dist <= Config.NpcInteractionDistance and not IsPedInAnyVehicle(playerPed, false) then
                sleep = 0
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to manage your car lot")
                EndTextCommandDisplayHelp(0, false, true, -1)

                if IsControlJustReleased(0, 38) and not isUIOpen then
                    TriggerServerEvent('my_carlot:requestListings')
                end
            end
        end

        Wait(sleep)
    end
end)

-- ============================================================
-- VEHICLE LISTING ZONE THREAD
-- ============================================================

CreateThread(function()
    while true do
        local sleep = 500

        if isOwned then
            local playerPed = PlayerPedId()

            if IsPedInAnyVehicle(playerPed, false) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                local px, py, pz = table.unpack(GetEntityCoords(playerPed))
                local lc = Config.LotCenter
                local dist = getDistance(px, py, pz, lc.x, lc.y, lc.z)

                if dist <= Config.LotRadius then
                    -- Check if driver seat
                    if GetPedInVehicleSeat(vehicle, -1) == playerPed then
                        local plate = getPlate(vehicle)
                        if plate and exports['my_vehicles']:DoesPlateExist(plate) then
                            sleep = 0
                            BeginTextCommandDisplayHelp("STRING")
                            AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to place this vehicle for sale")
                            EndTextCommandDisplayHelp(0, false, true, -1)

                            if IsControlJustReleased(0, 38) and not isUIOpen then
                                pendingListPlate = plate
                                TriggerServerEvent('my_carlot:getListingPrice', plate)
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ============================================================
-- INPUT CONTROL THREAD
-- ============================================================

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
                closeUI()
            end
        else
            Wait(500)
        end
    end
end)

-- ============================================================
-- SERVER EVENTS
-- ============================================================

-- Ownership
RegisterNetEvent('my_carlot:ownershipStatus')
AddEventHandler('my_carlot:ownershipStatus', function(owned)
    isOwned = owned
    updateBlipColor()
    if isOwned then
        spawnSalesman()
    else
        deleteSalesman()
    end
end)

RegisterNetEvent('my_carlot:purchaseSuccess')
AddEventHandler('my_carlot:purchaseSuccess', function()
    isOwned = true
    updateBlipColor()
    spawnSalesman()

    SetNotificationTextEntry("STRING")
    AddTextComponentString("~g~Congratulations! You now own ~y~" .. Config.Dealership.name .. "~g~!")
    DrawNotification(false, false)
end)

RegisterNetEvent('my_carlot:purchaseFailure')
AddEventHandler('my_carlot:purchaseFailure', function(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString("~r~" .. (msg or "Purchase failed"))
    DrawNotification(false, false)
end)

-- Listing confirmation prompt
RegisterNetEvent('my_carlot:showListingConfirm')
AddEventHandler('my_carlot:showListingConfirm', function(plate, label, salePrice)
    pendingListPlate = plate
    openUI('confirm', {
        vehicleName = label,
        salePrice = salePrice,
        plate = plate
    })
end)

RegisterNetEvent('my_carlot:listingError')
AddEventHandler('my_carlot:listingError', function(msg)
    closeUI()
    pendingListPlate = nil

    SetNotificationTextEntry("STRING")
    AddTextComponentString("~r~" .. (msg or "Cannot list vehicle"))
    DrawNotification(false, false)
end)

-- Vehicle listed successfully
RegisterNetEvent('my_carlot:vehicleListed')
AddEventHandler('my_carlot:vehicleListed', function(plate, label, salePrice)
    closeUI()
    pendingListPlate = nil

    -- Exit the vehicle and lock it
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        TaskLeaveVehicle(playerPed, vehicle, 0)

        -- Wait for player to exit, then lock
        CreateThread(function()
            Wait(2000)
            if DoesEntityExist(vehicle) then
                SetVehicleDoorsLocked(vehicle, 2)
                SetVehicleDoorsLockedForAllPlayers(vehicle, true)
                FreezeEntityPosition(vehicle, true)
            end
        end)
    end

    SetNotificationTextEntry("STRING")
    AddTextComponentString("~g~Listed ~y~" .. label .. "~g~ for sale at ~y~$" .. salePrice)
    DrawNotification(false, false)
end)

-- Remove listing result
RegisterNetEvent('my_carlot:removeResult')
AddEventHandler('my_carlot:removeResult', function(success, errorMsg, plate)
    if success then
        -- Unlock and unfreeze the vehicle if nearby
        if plate then
            local allVehicles = GetGamePool('CVehicle')
            for _, vehicle in ipairs(allVehicles) do
                if DoesEntityExist(vehicle) then
                    local vPlate = getPlate(vehicle)
                    if vPlate == plate then
                        SetVehicleDoorsLocked(vehicle, 1)
                        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                        FreezeEntityPosition(vehicle, false)
                        break
                    end
                end
            end
        end

        SetNotificationTextEntry("STRING")
        AddTextComponentString("~g~Listing removed successfully.")
        DrawNotification(false, false)

        -- Refresh the management UI
        TriggerServerEvent('my_carlot:requestListings')
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~r~" .. (errorMsg or "Failed to remove listing"))
        DrawNotification(false, false)
    end
end)

-- Receive listings for management UI
RegisterNetEvent('my_carlot:receiveListings')
AddEventHandler('my_carlot:receiveListings', function(listings, salesLog)
    openUI('manage', {
        listings = listings,
        salesLog = salesLog
    })
end)

-- Vehicle sold notification
RegisterNetEvent('my_carlot:vehicleSold')
AddEventHandler('my_carlot:vehicleSold', function(label, price, buyerName)
    SetNotificationTextEntry("STRING")
    AddTextComponentString("~g~Your ~y~" .. label .. "~g~ sold for ~y~$" .. price .. "~g~ to " .. buyerName .. "!")
    DrawNotification(false, false)
end)

-- Pending payments on join
RegisterNetEvent('my_carlot:pendingPaymentReceived')
AddEventHandler('my_carlot:pendingPaymentReceived', function(total, sales)
    SetNotificationTextEntry("STRING")
    AddTextComponentString("~g~You earned ~y~$" .. total .. "~g~ from car lot sales while you were away!")
    DrawNotification(false, false)
end)

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback('confirmPurchase', function(data, cb)
    if not isOwned then
        closeUI()
        TriggerServerEvent('my_carlot:requestPurchase')
    end
    cb({ success = true })
end)

RegisterNUICallback('confirmListing', function(data, cb)
    if pendingListPlate then
        TriggerServerEvent('my_carlot:confirmListVehicle', pendingListPlate)
    end
    cb({ success = true })
end)

RegisterNUICallback('cancelListing', function(data, cb)
    closeUI()
    pendingListPlate = nil
    cb({ success = true })
end)

RegisterNUICallback('removeListing', function(data, cb)
    if data and data.id then
        TriggerServerEvent('my_carlot:removeListing', data.id)
    end
    cb({ success = true })
end)

RegisterNUICallback('close', function(data, cb)
    closeUI()
    cb({ success = true })
end)

-- ============================================================
-- INITIALIZATION
-- ============================================================

CreateThread(function()
    lotBlip = createBlip()
    TriggerServerEvent('my_carlot:checkOwnership')

    -- Check pending payments shortly after joining
    Wait(5000)
    TriggerServerEvent('my_carlot:checkPendingPayments')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if lotBlip then RemoveBlip(lotBlip) end
    deleteSalesman()
end)

-- ============================================================
-- CLEAR AMBIENT NPCS & VEHICLES AROUND LOT (when owned)
-- ============================================================

local CLEAR_RADIUS = 20.0

CreateThread(function()
    while true do
        Wait(4000)

        if not isOwned then
            goto skipClear
        end

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local lotVec = vector3(Config.Dealership.coords.x, Config.Dealership.coords.y, Config.Dealership.coords.z)

        if #(playerCoords - lotVec) >= 100.0 then
            goto skipClear
        end

        local function IsInClearZone(coords)
            return #(coords - lotVec) <= CLEAR_RADIUS
        end

        -- 1) Remove stationary NPCs (skip salesman)
        local allPeds = GetGamePool('CPed')
        for _, ped in ipairs(allPeds) do
            if DoesEntityExist(ped) and not IsPedAPlayer(ped) and ped ~= salesmanPed then
                local pedCoords = GetEntityCoords(ped)
                if IsInClearZone(pedCoords) then
                    if GetEntitySpeed(ped) < 0.5 then
                        SetEntityAsMissionEntity(ped, true, true)
                        DeleteEntity(ped)
                    end
                end
            end
        end

        -- 2) Remove parked NPC vehicles (skip player-owned)
        local allVehicles = GetGamePool('CVehicle')
        for _, vehicle in ipairs(allVehicles) do
            if DoesEntityExist(vehicle) and IsVehicleStopped(vehicle) then
                local vehCoords = GetEntityCoords(vehicle)
                if IsInClearZone(vehCoords) then
                    local plateRaw = GetVehicleNumberPlateText(vehicle)
                    if plateRaw then
                        local plate = string.upper(string.gsub(tostring(plateRaw), '%s+', ''))
                        if exports['my_vehicles']:DoesPlateExist(plate) then
                            goto nextVeh
                        end
                    end

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

        -- 3) Suppress vehicle generators
        RemoveVehiclesFromGeneratorsInArea(
            lotVec.x - CLEAR_RADIUS, lotVec.y - CLEAR_RADIUS, lotVec.z - CLEAR_RADIUS,
            lotVec.x + CLEAR_RADIUS, lotVec.y + CLEAR_RADIUS, lotVec.z + CLEAR_RADIUS,
            0
        )

        ::skipClear::
    end
end)
