-- Used Cars Marketplace Client
-- All ESX references removed. Uses native notifications and event pairs.

local isMenuOpen = false
local myPlayerName = nil
local pendingSellData = nil
local pendingBuyVehicle = nil -- { entity = handle, originalPlate = "..." }

-- ============================================================
-- NOTIFICATION HELPERS
-- ============================================================

local function ShowNotification(message)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, true)
end

local function ShowHelpNotification(message)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- ============================================================
-- MENU OPEN/CLOSE
-- ============================================================

function OpenUsedCarsMenu()
    if isMenuOpen then return end
    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMenu',
        minOfferPercent = Config.MinOfferPercent
    })
end

RegisterCommand('usedcars', function()
    TriggerServerEvent('my_usedcars:checkDrivingLicense')
end, false)

RegisterNetEvent('my_usedcars:drivingLicenseResult')
AddEventHandler('my_usedcars:drivingLicenseResult', function(hasLicense)
    if hasLicense then
        OpenUsedCarsMenu()
    else
        ShowNotification('~r~You need a driving license to use the used car marketplace.')
    end
end)

-- ============================================================
-- PLAYER READY
-- ============================================================

CreateThread(function()
    Wait(5000)
    TriggerServerEvent('my_usedcars:playerReady')
end)

-- ============================================================
-- NUI CALLBACKS (fire server events, return cb('ok'))
-- ============================================================

RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    isMenuOpen = false
    cb('ok')
end)

RegisterNUICallback('getPlayerVehicles', function(data, cb)
    TriggerServerEvent('my_usedcars:reqMyListings')
    cb('ok')
end)

RegisterNUICallback('getPlayerOwnedVehicles', function(data, cb)
    TriggerServerEvent('my_usedcars:reqOwnedVehicles')
    cb('ok')
end)

RegisterNUICallback('getUsedCarsForSale', function(data, cb)
    TriggerServerEvent('my_usedcars:reqBrowseVehicles')
    cb('ok')
end)

RegisterNUICallback('addVehicleToSaleList', function(data, cb)
    if not data.vehicle or not data.price then
        cb('ok')
        return
    end
    TriggerServerEvent('my_usedcars:reqAddListing', data.vehicle.model, data.vehicle.plate, data.price)
    cb('ok')
end)

RegisterNUICallback('updateVehiclePrice', function(data, cb)
    TriggerServerEvent('my_usedcars:reqUpdatePrice', data.vehicleId, data.newPrice)
    cb('ok')
end)

RegisterNUICallback('removeVehicle', function(data, cb)
    TriggerServerEvent('my_usedcars:reqRemoveListing', data.vehicleId)
    cb('ok')
end)

RegisterNUICallback('getVehicleOffers', function(data, cb)
    TriggerServerEvent('my_usedcars:reqVehicleOffers', data.vehicleId)
    cb('ok')
end)

RegisterNUICallback('rejectOffer', function(data, cb)
    TriggerServerEvent('my_usedcars:reqRejectOffer', data.vehicleId, data.offerId)
    cb('ok')
end)

RegisterNUICallback('makeOffer', function(data, cb)
    TriggerServerEvent('my_usedcars:reqMakeOffer', data.vehicleId, data.offerPrice)
    cb('ok')
end)

RegisterNUICallback('getVehicleOriginalPrice', function(data, cb)
    TriggerServerEvent('my_usedcars:reqVehiclePrice', data.model)
    cb('ok')
end)

RegisterNUICallback('scheduleMeeting', function(data, cb)
    ScheduleMeeting(data.vehicle, data.offer)
    cb('ok')
end)

RegisterNUICallback('showNotification', function(data, cb)
    ShowNotification(data.message)
    cb('ok')
end)

-- ============================================================
-- SERVER RESPONSE HANDLERS → Forward to NUI
-- ============================================================

RegisterNetEvent('my_usedcars:resMyListings')
AddEventHandler('my_usedcars:resMyListings', function(listings, postLimit)
    SendNUIMessage({
        action = 'myListingsData',
        vehicles = listings,
        postLimit = postLimit
    })
end)

RegisterNetEvent('my_usedcars:resOwnedVehicles')
AddEventHandler('my_usedcars:resOwnedVehicles', function(vehicles)
    SendNUIMessage({
        action = 'ownedVehiclesData',
        vehicles = vehicles
    })
end)

RegisterNetEvent('my_usedcars:resBrowseVehicles')
AddEventHandler('my_usedcars:resBrowseVehicles', function(vehicles)
    SendNUIMessage({
        action = 'browseVehiclesData',
        vehicles = vehicles
    })
end)

RegisterNetEvent('my_usedcars:resAddListing')
AddEventHandler('my_usedcars:resAddListing', function(success, errorCode)
    SendNUIMessage({
        action = 'addListingResult',
        success = success,
        errorCode = errorCode
    })
end)

RegisterNetEvent('my_usedcars:resUpdatePrice')
AddEventHandler('my_usedcars:resUpdatePrice', function(success)
    SendNUIMessage({
        action = 'updatePriceResult',
        success = success
    })
end)

RegisterNetEvent('my_usedcars:resRemoveListing')
AddEventHandler('my_usedcars:resRemoveListing', function(success)
    SendNUIMessage({
        action = 'removeListingResult',
        success = success
    })
end)

RegisterNetEvent('my_usedcars:resVehicleOffers')
AddEventHandler('my_usedcars:resVehicleOffers', function(offers)
    SendNUIMessage({
        action = 'vehicleOffersData',
        offers = offers
    })
end)

RegisterNetEvent('my_usedcars:resRejectOffer')
AddEventHandler('my_usedcars:resRejectOffer', function(success)
    SendNUIMessage({
        action = 'rejectOfferResult',
        success = success
    })
end)

RegisterNetEvent('my_usedcars:resMakeOffer')
AddEventHandler('my_usedcars:resMakeOffer', function(success, errorType)
    SendNUIMessage({
        action = 'makeOfferResult',
        success = success,
        error = errorType
    })
end)

RegisterNetEvent('my_usedcars:resVehiclePrice')
AddEventHandler('my_usedcars:resVehiclePrice', function(price)
    SendNUIMessage({
        action = 'vehiclePriceData',
        originalPrice = price
    })
end)

-- ============================================================
-- SELL VEHICLE MEETING (Player sells to NPC buyer)
-- ============================================================

function ScheduleMeeting(vehicle, offer)
    SetNuiFocus(false, false)
    isMenuOpen = false
    SendNUIMessage({ action = 'closeMenu' })

    CreateThread(function()
        local meetingPoint = Config.MeetingPoints[math.random(1, #Config.MeetingPoints)]

        local blip = AddBlipForCoord(meetingPoint.x, meetingPoint.y, meetingPoint.z)
        SetBlipSprite(blip, Config.BuyerBlip.sprite)
        SetBlipColour(blip, Config.BuyerBlip.color)
        SetBlipScale(blip, Config.BuyerBlip.scale)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(offer.buyer_name .. " Meeting Point")
        EndTextCommandSetBlipName(blip)

        ShowNotification('Meeting scheduled with ' .. offer.buyer_name .. '. Bring your vehicle. You have ' .. Config.BuyerWaitingTime .. ' minutes.')

        local startTimer = GetGameTimer()

        -- Wait for player to get close
        while GetGameTimer() - startTimer < Config.BuyerWaitingTime * 60000 do
            Wait(1000)
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, meetingPoint.x, meetingPoint.y, meetingPoint.z)
            if distance < Config.BuyerSpawnRange then
                break
            end
        end

        if GetGameTimer() - startTimer >= Config.BuyerWaitingTime * 60000 then
            ShowNotification('You did not arrive in time. Meeting cancelled.')
            RemoveBlip(blip)
            return
        end

        -- Spawn buyer NPC
        local buyerModel = offer.gender == "male" and Config.BuyerMaleModels[math.random(1, #Config.BuyerMaleModels)] or Config.BuyerFemaleModels[math.random(1, #Config.BuyerFemaleModels)]

        RequestModel(GetHashKey(buyerModel))
        while not HasModelLoaded(GetHashKey(buyerModel)) do
            Wait(100)
        end

        local buyerPed = CreatePed(4, GetHashKey(buyerModel), meetingPoint.x, meetingPoint.y, meetingPoint.z, meetingPoint.heading, false, true)
        SetEntityAsMissionEntity(buyerPed, true, true)
        SetPedCanRagdoll(buyerPed, false)
        TaskStandStill(buyerPed, -1)
        TaskLookAtEntity(buyerPed, PlayerPedId(), -1, 2048, 3)
        SetPedAsEnemy(buyerPed, false)

        local playerPed = PlayerPedId()
        local playerVehicle = nil
        local vehiclePedWasIn = nil
        local saleStarted = false

        while DoesEntityExist(buyerPed) and not IsEntityDead(buyerPed) and not IsPedFleeing(buyerPed) do
            Wait(5)

            if IsPedInAnyVehicle(playerPed, false) then
                vehiclePedWasIn = GetVehiclePedIsIn(playerPed, false)
            end

            if playerVehicle == nil and not IsPedInAnyVehicle(playerPed, false) then
                if DoesEntityExist(vehiclePedWasIn) then
                    local plate = GetVehicleNumberPlateText(vehiclePedWasIn)
                    if string.lower(string.gsub(plate, " ", "")) == string.lower(string.gsub(vehicle.plate, " ", "")) then
                        playerVehicle = vehiclePedWasIn
                    else
                        vehiclePedWasIn = nil
                    end
                end
            end

            local playerCoords = GetEntityCoords(playerPed)
            if Vdist(playerCoords.x, playerCoords.y, playerCoords.z, meetingPoint.x, meetingPoint.y, meetingPoint.z) < 2.0 then
                ShowHelpNotification('Press ~INPUT_CONTEXT~ to sell your vehicle to ' .. offer.buyer_name .. ' for $' .. offer.offer_price)
                if IsControlJustReleased(0, 38) then -- E key
                    if playerVehicle then
                        saleStarted = true
                        SellVehicleToBuyer(vehicle, offer, buyerPed, playerVehicle)
                        break
                    else
                        ShowNotification('You need to bring the vehicle being sold to the meeting point.')
                    end
                end
            end

            if GetGameTimer() - startTimer > Config.BuyerWaitingTime * 60000 then
                ShowNotification(offer.buyer_name .. ' got tired of waiting.')
                TaskWanderStandard(buyerPed, 10.0, 10)
                SetEntityAsNoLongerNeeded(buyerPed)
                break
            end
        end

        -- Only clean up buyer NPC here if the sale was NOT started.
        -- The sellResult handler takes ownership of the NPC + vehicle after a sale.
        if not saleStarted and DoesEntityExist(buyerPed) then
            SetEntityAsNoLongerNeeded(buyerPed)
        end

        RemoveBlip(blip)
    end)
end

-- Sell result handler registered ONCE (prevents event handler leak)
RegisterNetEvent('my_usedcars:sellResult')
AddEventHandler('my_usedcars:sellResult', function(success, amount, buyerName)
    if not pendingSellData then return end

    local buyerPed = pendingSellData.buyerPed
    local playerVehicle = pendingSellData.playerVehicle
    pendingSellData = nil

    if success then
        ShowNotification('You sold your vehicle for $' .. tostring(amount))

        CreateThread(function()
            if DoesEntityExist(buyerPed) and DoesEntityExist(playerVehicle) then
                -- Unlock the vehicle so the NPC can enter
                SetVehicleDoorsLocked(playerVehicle, 1)
                SetVehicleHasBeenOwnedByPlayer(playerVehicle, false)

                -- Have the NPC enter the driver seat
                TaskEnterVehicle(buyerPed, playerVehicle, 20000, -1, 1.0, 0, 0)

                -- Wait for the NPC to actually get in (up to 20s)
                local enterTimer = GetGameTimer()
                while DoesEntityExist(buyerPed) and DoesEntityExist(playerVehicle) do
                    Wait(500)
                    if IsPedInVehicle(buyerPed, playerVehicle, false) then
                        break
                    end
                    if GetGameTimer() - enterTimer > 20000 then
                        break
                    end
                end

                -- NPC is in (or timed out) — make them drive away
                if DoesEntityExist(buyerPed) and DoesEntityExist(playerVehicle) and IsPedInVehicle(buyerPed, playerVehicle, false) then
                    TaskVehicleDriveWander(buyerPed, playerVehicle, 20.0, 786599)

                    -- Monitor distance — despawn once 200m away
                    while DoesEntityExist(playerVehicle) do
                        Wait(1000)
                        local playerCoords = GetEntityCoords(PlayerPedId())
                        local vehCoords = GetEntityCoords(playerVehicle)
                        local dist = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, vehCoords.x, vehCoords.y, vehCoords.z)
                        if dist > 200.0 then
                            if DoesEntityExist(buyerPed) then
                                SetEntityAsMissionEntity(buyerPed, true, true)
                                DeleteEntity(buyerPed)
                            end
                            if DoesEntityExist(playerVehicle) then
                                SetEntityAsMissionEntity(playerVehicle, true, true)
                                DeleteEntity(playerVehicle)
                            end
                            break
                        end
                    end
                else
                    -- NPC couldn't enter — clean up both
                    if DoesEntityExist(buyerPed) then
                        SetEntityAsMissionEntity(buyerPed, true, true)
                        DeleteEntity(buyerPed)
                    end
                    if DoesEntityExist(playerVehicle) then
                        SetEntityAsMissionEntity(playerVehicle, true, true)
                        DeleteEntity(playerVehicle)
                    end
                end
            end
        end)
    else
        ShowNotification('Failed to complete the sale.')
        -- Clean up on failure
        if DoesEntityExist(buyerPed) then
            SetEntityAsNoLongerNeeded(buyerPed)
        end
        if DoesEntityExist(playerVehicle) then
            SetEntityAsNoLongerNeeded(playerVehicle)
        end
    end
end)

function SellVehicleToBuyer(vehicle, offer, buyerPed, playerVehicle)
    -- Release from my_vehicles tracking BEFORE the server removes the data.
    -- This prevents my_vehicles:vehicleRemoved from instantly deleting the entity.
    exports['my_vehicles']:ReleaseVehicle(vehicle.plate)

    pendingSellData = {
        buyerPed = buyerPed,
        playerVehicle = playerVehicle
    }
    TriggerServerEvent('my_usedcars:sellVehicleToBuyer', vehicle.id, offer.id)
end

-- ============================================================
-- BUY VEHICLE FROM NPC (Player buys NPC-listed vehicle)
-- ============================================================

RegisterNetEvent('my_usedcars:notifyAcceptedOffer')
AddEventHandler('my_usedcars:notifyAcceptedOffer', function(vehicle, offer)
    -- Check if this notification is for us (compare player name)
    if not myPlayerName then
        myPlayerName = GetPlayerName(PlayerId())
    end

    if myPlayerName ~= offer.buyer_name then
        return
    end

    ShowNotification('Your offer of $' .. offer.offer_price .. ' on ' .. (vehicle.label or vehicle.model) .. ' (' .. vehicle.plate .. ') has been accepted! Meeting scheduled.')
    MeetWithNPC(vehicle, offer)
end)

function MeetWithNPC(vehicle, offer)
    SetNuiFocus(false, false)
    isMenuOpen = false
    SendNUIMessage({ action = 'closeMenu' })

    CreateThread(function()
        local meetingPoint = Config.MeetingPoints[math.random(1, #Config.MeetingPoints)]

        local blip = AddBlipForCoord(meetingPoint.x, meetingPoint.y, meetingPoint.z)
        SetBlipSprite(blip, Config.SellerBlip.sprite)
        SetBlipColour(blip, Config.SellerBlip.color)
        SetBlipScale(blip, Config.SellerBlip.scale)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName((vehicle.label or vehicle.model) .. " Meeting Point")
        EndTextCommandSetBlipName(blip)

        -- Wait for player to get in range (with timeout)
        local approachTimer = GetGameTimer()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, meetingPoint.x, meetingPoint.y, meetingPoint.z)

        while distance > Config.BuyerSpawnRange do
            Wait(1000)
            if GetGameTimer() - approachTimer >= Config.BuyerWaitingTime * 60000 then
                ShowNotification('You did not arrive in time. Meeting cancelled.')
                RemoveBlip(blip)
                return
            end
            playerCoords = GetEntityCoords(playerPed)
            distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, meetingPoint.x, meetingPoint.y, meetingPoint.z)
        end

        -- Spawn seller NPC
        local sellerModel = math.random(1, 2) == 1 and Config.BuyerMaleModels[math.random(1, #Config.BuyerMaleModels)] or Config.BuyerFemaleModels[math.random(1, #Config.BuyerFemaleModels)]

        RequestModel(GetHashKey(sellerModel))
        while not HasModelLoaded(GetHashKey(sellerModel)) do
            Wait(100)
        end

        local sellerPed = CreatePed(4, GetHashKey(sellerModel), meetingPoint.x, meetingPoint.y, meetingPoint.z, meetingPoint.heading, false, true)
        SetEntityAsMissionEntity(sellerPed, true, true)
        SetPedCanRagdoll(sellerPed, false)
        TaskStandStill(sellerPed, -1)
        TaskLookAtEntity(sellerPed, PlayerPedId(), -1, 2048, 3)
        SetPedAsEnemy(sellerPed, false)

        -- Spawn the vehicle (wait for clear area)
        RequestModel(GetHashKey(vehicle.model))
        while not HasModelLoaded(GetHashKey(vehicle.model)) do
            Wait(100)
        end

        local vehicleEntity = CreateVehicle(GetHashKey(vehicle.model), meetingPoint.vehicleSpawn.x, meetingPoint.vehicleSpawn.y, meetingPoint.vehicleSpawn.z, meetingPoint.vehicleSpawn.heading, true, false)
        SetVehicleNumberPlateText(vehicleEntity, vehicle.plate)
        SetEntityAsMissionEntity(vehicleEntity, true, true)

        local startTimer = GetGameTimer()
        local purchased = false

        while sellerPed and DoesEntityExist(sellerPed) and not IsEntityDead(sellerPed) and not IsPedFleeing(sellerPed) do
            Wait(5)

            playerCoords = GetEntityCoords(PlayerPedId())
            if Vdist(playerCoords.x, playerCoords.y, playerCoords.z, meetingPoint.x, meetingPoint.y, meetingPoint.z) < 2.0 then
                ShowHelpNotification('Press ~INPUT_CONTEXT~ to buy the vehicle for $' .. offer.offer_price)
                if IsControlJustReleased(0, 38) then -- E key
                    TaskWanderStandard(sellerPed, 10.0, 10)
                    SetEntityAsNoLongerNeeded(sellerPed)
                    sellerPed = nil
                    purchased = true

                    BuyVehicleFromNPC(vehicle, offer, vehicleEntity)
                    break
                end
            end

            if GetGameTimer() - startTimer > Config.BuyerWaitingTime * 60000 then
                ShowNotification('The seller got tired of waiting.')
                TaskWanderStandard(sellerPed, 10.0, 10)
                SetEntityAsNoLongerNeeded(sellerPed)
                sellerPed = nil
                break
            end
        end

        -- Clean up display vehicle if purchase didn't happen (timeout, NPC died/fled)
        if not purchased and DoesEntityExist(vehicleEntity) then
            DeleteEntity(vehicleEntity)
        end

        -- Clean up seller NPC if still exists (NPC died or fled)
        if sellerPed and DoesEntityExist(sellerPed) then
            SetEntityAsNoLongerNeeded(sellerPed)
        end

        RemoveBlip(blip)
    end)
end

function BuyVehicleFromNPC(vehicle, offer, vehicleEntity)
    -- Get the vehicle's actual position so it registers at the correct location
    local coords = GetEntityCoords(vehicleEntity)
    local heading = GetEntityHeading(vehicleEntity)

    -- Capture vehicle properties so colors/state persist across restarts
    SetVehicleModKit(vehicleEntity, 0)
    local colorPrimary, colorSecondary = GetVehicleColours(vehicleEntity)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicleEntity)
    local modColor1Type, modColor1, modColor1Pearl = GetVehicleModColor_1(vehicleEntity)
    local modColor2Type, modColor2 = GetVehicleModColor_2(vehicleEntity)

    local vehicleProps = {
        color1 = colorPrimary,
        color2 = colorSecondary,
        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,
        modColor1 = {modColor1Type, modColor1, modColor1Pearl},
        modColor2 = {modColor2Type, modColor2}
    }

    -- Do NOT delete the preview vehicle here.
    -- The my_vehicles SpawnVehicle function will find it in the game pool via plate
    -- matching and adopt it as the persistent vehicle (zero visual gap, no duplicates).
    SetVehicleDoorsLocked(vehicleEntity, 1) -- Unlock for the new owner

    -- Track the entity so buyResult can update the plate or clean up on failure
    pendingBuyVehicle = {
        entity = vehicleEntity,
        originalPlate = vehicle.plate
    }

    TriggerServerEvent('my_usedcars:buyVehicleFromNPC', vehicle, offer, coords.x, coords.y, coords.z, heading, vehicleProps)
    ShowNotification('Purchasing ' .. (vehicle.label or vehicle.model) .. '...')
end

-- Buy result handler
RegisterNetEvent('my_usedcars:buyResult')
AddEventHandler('my_usedcars:buyResult', function(success, plate)
    local buyData = pendingBuyVehicle
    pendingBuyVehicle = nil

    if success then
        ShowNotification('Vehicle purchase complete! Plate: ' .. tostring(plate))
        -- If the server had to generate a new plate (collision), update the entity
        if buyData and buyData.entity and DoesEntityExist(buyData.entity) then
            local currentPlate = string.upper(string.gsub(GetVehicleNumberPlateText(buyData.entity), '%s+', ''))
            local newPlate = string.upper(string.gsub(tostring(plate), '%s+', ''))
            if currentPlate ~= newPlate then
                SetVehicleNumberPlateText(buyData.entity, plate)
            end
        end
    else
        ShowNotification('Purchase failed: ' .. tostring(plate))
        -- Clean up the unregistered vehicle entity so it doesn't linger
        if buyData and buyData.entity and DoesEntityExist(buyData.entity) then
            SetEntityAsMissionEntity(buyData.entity, true, true)
            DeleteEntity(buyData.entity)
        end
    end
end)

-- ============================================================
-- NOTIFICATION EVENTS
-- ============================================================

RegisterNetEvent('my_usedcars:notifyRejectedOffer')
AddEventHandler('my_usedcars:notifyRejectedOffer', function(vehicleModel, buyerName)
    if not myPlayerName then
        myPlayerName = GetPlayerName(PlayerId())
    end

    if myPlayerName ~= buyerName then
        return
    end

    ShowNotification("Your offer on the " .. vehicleModel .. " was rejected.")
end)

RegisterNetEvent('my_usedcars:notifyNewOffer')
AddEventHandler('my_usedcars:notifyNewOffer', function(buyerName, offerPrice)
    ShowNotification(buyerName .. " made a new offer of $" .. offerPrice .. " on your vehicle.")
end)

-- ============================================================
-- ESC KEY HANDLER
-- ============================================================

CreateThread(function()
    while true do
        if isMenuOpen then
            Wait(0)
            if IsControlJustReleased(0, 322) then -- ESC
                SendNUIMessage({ action = 'closeMenu' })
                SetNuiFocus(false, false)
                isMenuOpen = false
            end
        else
            Wait(500)
        end
    end
end)
