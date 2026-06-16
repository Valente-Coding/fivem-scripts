-- my_tunergarage/client.lua
-- Client-side logic for garage purchase and worker system

-- Local state
local isUIOpen = false
local isOwned = false
local hasWorker = false
local localPendingProfit = 0
local garageBlip = nil

-- Worker entity handles (excluded from cleanup)
local mechanicPed = nil
local mechanicProp = nil
local customerCar = nil

-- Drop-off repair state
local repairVehicleEntity = nil   -- entity handle for the vehicle sitting at the repair spot
local dropOffVehicleData = {}     -- [plate] = {model, readyGameTime, ready}
local dropOffPickupChecked = false
local isDropOffProcessing = false

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

local function getDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function Plate(v)
    return string.upper(string.gsub(GetVehicleNumberPlateText(v), '%s+', ''))
end

local function GetOilLevel(plate)
    local ok, val = pcall(function() return exports['my_vehicles']:GetVehicleOilLevel(plate) end)
    if ok and val then return val end
    return 100.0
end

local function FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%d:%02d", m, s)
end

-- Capture visible vehicle appearance (colors, mods, livery, etc.)
local function GetVehicleAppearance(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return nil end
    local a = {}

    a.colorPrimary, a.colorSecondary = GetVehicleColours(vehicle)
    a.pearlescentColor, a.wheelColor = GetVehicleExtraColours(vehicle)

    if GetIsVehiclePrimaryColourCustom(vehicle) then
        a.customPrimaryColor = {GetVehicleCustomPrimaryColour(vehicle)}
    end
    if GetIsVehicleSecondaryColourCustom(vehicle) then
        a.customSecondaryColor = {GetVehicleCustomSecondaryColour(vehicle)}
    end

    a.wheelType = GetVehicleWheelType(vehicle)
    a.windowTint = GetVehicleWindowTint(vehicle)
    a.livery = GetVehicleLivery(vehicle)
    a.plateType = GetVehicleNumberPlateTextIndex(vehicle)

    -- Mods (0-16 visual, 23-24 wheels)
    SetVehicleModKit(vehicle, 0)
    a.mods = {}
    for i = 0, 16 do a.mods[i] = GetVehicleMod(vehicle, i) end
    a.mods[23] = GetVehicleMod(vehicle, 23)
    a.mods[24] = GetVehicleMod(vehicle, 24)

    a.modTurbo = IsToggleModOn(vehicle, 18)
    a.modSmoke = IsToggleModOn(vehicle, 20)
    a.modXenon = IsToggleModOn(vehicle, 22)

    a.neonEnabled = {
        IsVehicleNeonLightEnabled(vehicle, 0),
        IsVehicleNeonLightEnabled(vehicle, 1),
        IsVehicleNeonLightEnabled(vehicle, 2),
        IsVehicleNeonLightEnabled(vehicle, 3)
    }
    a.neonColor = {GetVehicleNeonLightsColour(vehicle)}
    a.tyreSmokeColor = {GetVehicleTyreSmokeColor(vehicle)}

    a.extras = {}
    for i = 0, 12 do
        if DoesExtraExist(vehicle, i) then
            a.extras[i] = IsVehicleExtraTurnedOn(vehicle, i)
        end
    end

    return a
end

-- Apply saved appearance to a vehicle
local function SetVehicleAppearance(vehicle, a)
    if not vehicle or not DoesEntityExist(vehicle) or not a then return end

    if a.colorPrimary then SetVehicleColours(vehicle, a.colorPrimary, a.colorSecondary) end
    if a.customPrimaryColor then SetVehicleCustomPrimaryColour(vehicle, a.customPrimaryColor[1], a.customPrimaryColor[2], a.customPrimaryColor[3]) end
    if a.customSecondaryColor then SetVehicleCustomSecondaryColour(vehicle, a.customSecondaryColor[1], a.customSecondaryColor[2], a.customSecondaryColor[3]) end
    if a.pearlescentColor then SetVehicleExtraColours(vehicle, a.pearlescentColor, a.wheelColor) end
    if a.wheelType then SetVehicleWheelType(vehicle, a.wheelType) end

    SetVehicleModKit(vehicle, 0)
    if a.mods then
        for modType, modIndex in pairs(a.mods) do
            if modIndex ~= -1 then SetVehicleMod(vehicle, modType, modIndex, false) end
        end
    end

    if a.modTurbo then ToggleVehicleMod(vehicle, 18, true) end
    if a.modSmoke then ToggleVehicleMod(vehicle, 20, true) end
    if a.modXenon then ToggleVehicleMod(vehicle, 22, true) end

    if a.neonEnabled then
        for i = 0, 3 do SetVehicleNeonLightEnabled(vehicle, i, a.neonEnabled[i + 1] or false) end
    end
    if a.neonColor then SetVehicleNeonLightsColour(vehicle, a.neonColor[1], a.neonColor[2], a.neonColor[3]) end
    if a.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, a.tyreSmokeColor[1], a.tyreSmokeColor[2], a.tyreSmokeColor[3]) end

    if a.windowTint then SetVehicleWindowTint(vehicle, a.windowTint) end
    if a.livery and a.livery ~= -1 then SetVehicleLivery(vehicle, a.livery) end
    if a.plateType then SetVehicleNumberPlateTextIndex(vehicle, a.plateType) end

    if a.extras then
        for id, enabled in pairs(a.extras) do
            SetVehicleExtra(vehicle, id, not enabled)
        end
    end
end

local function createGarageBlip()
    local g = Config.Garage
    local blip = AddBlipForCoord(g.coords.x, g.coords.y, g.coords.z)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(g.name)
    EndTextCommandSetBlipName(blip)

    return blip
end

local function updateBlipColor()
    if garageBlip then
        if isOwned then
            SetBlipColour(garageBlip, Config.Blip.ownedColor)
        else
            SetBlipColour(garageBlip, Config.Blip.color)
        end
    end
end

-- ============================================================
-- NUI HELPERS
-- ============================================================

local function openGarageUI()
    if isUIOpen then return end
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        garageName = Config.Garage.name,
        price = Config.Garage.price,
        owned = isOwned
    })
end

local function openManagementUI()
    if isUIOpen then return end
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openManagement',
        garageName = Config.Garage.name,
        hasWorker = hasWorker,
        pendingProfit = localPendingProfit,
        hireCost = Config.Worker.hireCost
    })
end

local function closeGarageUI()
    if not isUIOpen then return end
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ============================================================
-- MECHANIC NPC SPAWNING
-- ============================================================

local function loadModel(modelName)
    local model = GetHashKey(modelName)
    if not IsModelValid(model) then
        print("[my_tunergarage] ERROR: Model '" .. modelName .. "' is not valid!")
        return nil
    end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 10000 do
        Wait(10)
        timeout = timeout + 10
    end
    if not HasModelLoaded(model) then
        print("[my_tunergarage] ERROR: Model '" .. modelName .. "' failed to load after timeout")
        return nil
    end
    return model
end

local function spawnMechanic()
    if mechanicPed and DoesEntityExist(mechanicPed) then return end

    local c = Config.Worker.mechanicCoords
    local model = loadModel(Config.Worker.mechanicModel)
    if not model then
        print("[my_tunergarage] Failed to load mechanic model: " .. Config.Worker.mechanicModel)
        return
    end

    mechanicPed = CreatePed(4, model, c.x, c.y, c.z, c.w, false, true)
    SetEntityAsMissionEntity(mechanicPed, true, true)
    SetEntityHeading(mechanicPed, c.w)
    FreezeEntityPosition(mechanicPed, true)
    SetEntityInvincible(mechanicPed, true)
    SetBlockingOfNonTemporaryEvents(mechanicPed, true)
    SetPedCanRagdoll(mechanicPed, false)
    SetPedFleeAttributes(mechanicPed, 0, false)
    TaskStartScenarioInPlace(mechanicPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
    SetModelAsNoLongerNeeded(model)
end

local function despawnMechanic()
    if mechanicPed and DoesEntityExist(mechanicPed) then
        SetEntityAsMissionEntity(mechanicPed, true, true)
        DeleteEntity(mechanicPed)
    end
    mechanicPed = nil
end

-- ============================================================
-- CUSTOMER CAR SPAWNING
-- ============================================================

local function placeVehicleOnGround(vehicle, x, y, z)
    -- Wait a frame for the entity to fully stream in
    Wait(0)
    if not DoesEntityExist(vehicle) then return end

    -- Unfreeze temporarily so ground-placement physics can work
    FreezeEntityPosition(vehicle, false)
    SetVehicleOnGroundProperly(vehicle)
    Wait(0)

    -- Verify with GetGroundZFor_3dCoord as fallback
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 5.0, false)
    if found and DoesEntityExist(vehicle) then
        local vehPos = GetEntityCoords(vehicle)
        -- If the vehicle is too far from the real ground, reposition it
        if math.abs(vehPos.z - groundZ) > 0.5 then
            SetEntityCoords(vehicle, x, y, groundZ + 0.5, false, false, false, false)
            SetVehicleOnGroundProperly(vehicle)
            Wait(0)
        end
    end

    FreezeEntityPosition(vehicle, true)
end

local function spawnCustomerCar()
    -- Delete old car if exists
    if customerCar and DoesEntityExist(customerCar) then
        SetEntityAsMissionEntity(customerCar, true, true)
        DeleteEntity(customerCar)
        customerCar = nil
    end

    local c = Config.Worker.carSpawnCoords
    local models = Config.Worker.carModels
    local modelName = models[math.random(#models)]
    local model = loadModel(modelName)
    if not model then return end

    customerCar = CreateVehicle(model, c.x, c.y, c.z + 0.5, c.w, false, false)
    SetEntityAsMissionEntity(customerCar, true, true)
    SetVehicleDoorsLocked(customerCar, 2)
    placeVehicleOnGround(customerCar, c.x, c.y, c.z)
    SetModelAsNoLongerNeeded(model)
end

local function despawnCustomerCar()
    if customerCar and DoesEntityExist(customerCar) then
        SetEntityAsMissionEntity(customerCar, true, true)
        DeleteEntity(customerCar)
    end
    customerCar = nil
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
        local g = Config.Garage

        local distance = getDistance(
            playerCoords.x, playerCoords.y, playerCoords.z,
            g.coords.x, g.coords.y, g.coords.z
        )

        if distance <= Config.InteractionDistance then
            sleep = 0

            -- Draw marker
            DrawMarker(Config.Marker.type,
                g.coords.x, g.coords.y, g.coords.z + Config.Marker.zOffset,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                Config.Marker.scale.x, Config.Marker.scale.y, Config.Marker.scale.z,
                Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
                Config.Marker.bobUpAndDown, false, 2, Config.Marker.rotate, nil, nil, false)

            -- Help text
            if isOwned then
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to manage your garage")
                EndTextCommandDisplayHelp(0, false, true, -1)
            else
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to buy this garage")
                EndTextCommandDisplayHelp(0, false, true, -1)
            end

            -- E key pressed
            if IsControlJustReleased(0, 38) and not isUIOpen then
                if isOwned then
                    openManagementUI()
                else
                    openGarageUI()
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
                closeGarageUI()
            end
        else
            Wait(500)
        end
    end
end)

-- ============================================================
-- EVENTS
-- ============================================================

RegisterNetEvent('my_tunergarage:purchaseSuccess')
AddEventHandler('my_tunergarage:purchaseSuccess', function()
    isOwned = true
    updateBlipColor()
    ShowNotification("~g~Congratulations! You now own ~y~" .. Config.Garage.name .. "~g~!")
end)

RegisterNetEvent('my_tunergarage:purchaseFailure')
AddEventHandler('my_tunergarage:purchaseFailure', function(errorMessage)
    ShowNotification("~r~" .. (errorMessage or "Purchase failed"))
end)

RegisterNetEvent('my_tunergarage:ownershipStatus')
AddEventHandler('my_tunergarage:ownershipStatus', function(owned, workerHired, profit)
    isOwned = owned
    hasWorker = workerHired or false
    localPendingProfit = profit or 0
    updateBlipColor()

    -- Spawn mechanic + initial car if worker is hired
    if isOwned and hasWorker then
        spawnMechanic()
        spawnCustomerCar()
    end
end)

-- Worker hire events
RegisterNetEvent('my_tunergarage:hireSuccess')
AddEventHandler('my_tunergarage:hireSuccess', function()
    hasWorker = true
    ShowNotification("~g~Mechanic hired! They will start working on cars shortly.")
    spawnMechanic()
    spawnCustomerCar()
end)

RegisterNetEvent('my_tunergarage:hireFailure')
AddEventHandler('my_tunergarage:hireFailure', function(errorMessage)
    ShowNotification("~r~" .. (errorMessage or "Failed to hire mechanic"))
end)

-- Profit collected
RegisterNetEvent('my_tunergarage:profitCollected')
AddEventHandler('my_tunergarage:profitCollected', function(amount)
    if amount > 0 then
        localPendingProfit = 0
        ShowNotification("~g~Collected ~y~$" .. amount .. "~g~ from your mechanic!")
    else
        ShowNotification("~o~No profit to collect yet.")
    end
end)

-- Worker completed a car — swap the vehicle and update profit
RegisterNetEvent('my_tunergarage:workerCompletedCar')
AddEventHandler('my_tunergarage:workerCompletedCar', function(carProfit, totalProfit)
    localPendingProfit = totalProfit or (localPendingProfit + (carProfit or 0))
    ShowNotification("~g~Your mechanic finished a job! ~y~+$" .. (carProfit or 0))

    -- Swap to a new car
    spawnCustomerCar()
end)

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

-- ============================================================
-- DROP-OFF REPAIR INTERACTION
-- ============================================================

local function spawnRepairVehicle(modelHash, plate, appearance)
    -- Clean up any existing repair entity first
    if repairVehicleEntity and DoesEntityExist(repairVehicleEntity) then
        SetEntityAsMissionEntity(repairVehicleEntity, true, true)
        DeleteEntity(repairVehicleEntity)
        repairVehicleEntity = nil
    end

    local c = Config.DropOff.vehicleCoords
    local model = modelHash
    if type(model) == 'string' then model = GetHashKey(model) end
    if not model then return end

    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 10000 do
        Wait(10)
        timeout = timeout + 10
    end
    if not HasModelLoaded(model) then return end

    repairVehicleEntity = CreateVehicle(model, c.x, c.y, c.z + 0.5, c.w, false, false)
    SetEntityAsMissionEntity(repairVehicleEntity, true, true)
    SetEntityHeading(repairVehicleEntity, c.w)
    SetVehicleDoorsLocked(repairVehicleEntity, 2)
    SetEntityInvincible(repairVehicleEntity, true)
    SetVehicleNumberPlateText(repairVehicleEntity, plate)

    -- Restore saved appearance (colors, mods, livery, etc.)
    if appearance then
        SetVehicleAppearance(repairVehicleEntity, appearance)
    end

    placeVehicleOnGround(repairVehicleEntity, c.x, c.y, c.z)
    SetModelAsNoLongerNeeded(model)
end

local function despawnRepairVehicle()
    if repairVehicleEntity and DoesEntityExist(repairVehicleEntity) then
        SetEntityAsMissionEntity(repairVehicleEntity, true, true)
        DeleteEntity(repairVehicleEntity)
    end
    repairVehicleEntity = nil
end

-- Drop-off interaction thread
CreateThread(function()
    while true do
        local sleep = 500
        if not isOwned then
            Wait(sleep)
            goto continue
        end

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local d = Config.DropOff.vehicleCoords
        local dropOffVec = vector3(d.x, d.y, d.z)
        local distance = #(playerCoords - dropOffVec)

        if distance <= Config.DropOff.markerDrawDistance then
            -- Draw marker at drop-off point
            DrawMarker(1, d.x, d.y, d.z - 1.0,
                0, 0, 0, 0, 0, 0, 2.0, 2.0, 1.0,
                255, 120, 0, 80,
                false, false, 2, false, nil, nil, false)
        end

        if distance <= Config.DropOff.interactionDistance then
            sleep = 0

            if IsPedInAnyVehicle(playerPed, false) then
                -- In vehicle — check for drop-off eligibility
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                if vehicle and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed then
                    local plate = Plate(vehicle)
                    local oilLevel = GetOilLevel(plate)
                    local engineHealth = GetVehicleEngineHealth(vehicle)
                    local bodyHealth = GetVehicleBodyHealth(vehicle)

                    if oilLevel <= 0 and (engineHealth < 1000.0 or bodyHealth < 1000.0) then
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to leave your vehicle for repair (~5 min)")
                        EndTextCommandDisplayHelp(0, false, true, -1)

                        if IsControlJustReleased(0, 38) and not isDropOffProcessing then
                            isDropOffProcessing = true
                            TriggerServerEvent('my_tunergarage:dropOffVehicle', plate)
                        end
                    end
                end
            else
                -- On foot — check for pickup
                if not dropOffPickupChecked then
                    TriggerServerEvent('my_tunergarage:getMyGarageVehicles')
                    dropOffPickupChecked = true
                end

                for plate, vData in pairs(dropOffVehicleData) do
                    local remaining = math.max(0, math.floor((vData.readyGameTime - GetGameTimer()) / 1000))
                    if vData.ready or remaining <= 0 then
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to pick up your repaired vehicle")
                        EndTextCommandDisplayHelp(0, false, true, -1)

                        if IsControlJustReleased(0, 38) then
                            TriggerServerEvent('my_tunergarage:requestPickup', plate)
                        end
                    else
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("Vehicle being repaired (" .. FormatTime(remaining) .. " remaining)")
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    end
                    break
                end
            end
        else
            if distance > Config.DropOff.interactionDistance + 5.0 then
                dropOffPickupChecked = false
            end
        end

        Wait(sleep)
        ::continue::
    end
end)

-- Drop-off events
RegisterNetEvent('my_tunergarage:dropOffApproved')
AddEventHandler('my_tunergarage:dropOffApproved', function(plate, readyInSeconds)
    isDropOffProcessing = false
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle and vehicle ~= 0 then
        local modelHash = GetEntityModel(vehicle)
        local appearance = GetVehicleAppearance(vehicle)

        -- Warp player out
        TaskLeaveVehicle(ped, vehicle, 16)
        Wait(800)

        -- Delete the original entity — we'll recreate it at the repair spot
        -- This avoids duplicates from entity handle issues
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteEntity(vehicle)

        -- Cache data client-side (including appearance for respawns)
        dropOffVehicleData[plate] = {
            model = modelHash,
            appearance = appearance,
            readyGameTime = GetGameTimer() + (readyInSeconds * 1000),
            ready = false
        }

        -- Spawn a clean copy at the repair spot with the correct appearance
        spawnRepairVehicle(modelHash, plate, appearance)

        -- Teleport player
        local pc = Config.DropOff.playerCoords
        SetEntityCoords(ped, pc.x, pc.y, pc.z, false, false, false, true)
        SetEntityHeading(ped, pc.w)
    end

    ShowNotification("~g~Vehicle left for repair. Come back in ~y~" .. math.ceil(readyInSeconds / 60) .. " minutes~g~.")
end)

RegisterNetEvent('my_tunergarage:dropOffDenied')
AddEventHandler('my_tunergarage:dropOffDenied', function(reason)
    isDropOffProcessing = false
    ShowNotification("~r~" .. (reason or "Cannot drop off vehicle"))
end)

RegisterNetEvent('my_tunergarage:pickupApproved')
AddEventHandler('my_tunergarage:pickupApproved', function(plate)
    plate = string.upper(string.gsub(plate, '%s+', ''))
    dropOffVehicleData[plate] = nil
    dropOffPickupChecked = false

    -- Unlock and unfreeze the repair vehicle so the player can drive it
    if repairVehicleEntity and DoesEntityExist(repairVehicleEntity) then
        SetVehicleDoorsLocked(repairVehicleEntity, 1)
        FreezeEntityPosition(repairVehicleEntity, false)
        SetEntityInvincible(repairVehicleEntity, false)
        SetVehicleFixed(repairVehicleEntity)
        SetVehicleEngineHealth(repairVehicleEntity, 1000.0)
        SetVehicleBodyHealth(repairVehicleEntity, 1000.0)
        SetVehicleDeformationFixed(repairVehicleEntity)
        SetVehicleUndriveable(repairVehicleEntity, false)
        SetVehicleEngineOn(repairVehicleEntity, true, true)

        -- Restore oil client-side
        local vehPlate = Plate(repairVehicleEntity)
        pcall(function()
            exports['my_vehicles']:SetVehicleOilLevel(vehPlate, 100.0)
            TriggerServerEvent('my_vehicles:updateOilLevel', vehPlate, 100.0)
        end)

        repairVehicleEntity = nil
    end

    ShowNotification("~g~Your vehicle has been repaired and is ready!")
end)

RegisterNetEvent('my_tunergarage:pickupDenied')
AddEventHandler('my_tunergarage:pickupDenied', function(reason)
    ShowNotification("~r~" .. (reason or "Cannot pick up vehicle"))
end)

RegisterNetEvent('my_tunergarage:garageVehiclesList')
AddEventHandler('my_tunergarage:garageVehiclesList', function(vehicles)
    dropOffVehicleData = {}
    if not vehicles then return end
    local now = GetGameTimer()
    for _, v in ipairs(vehicles) do
        dropOffVehicleData[v.plate] = {
            model = v.model,
            readyGameTime = now + (v.remaining * 1000),
            ready = v.ready or false
        }
    end
end)

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback('confirmPurchase', function(data, cb)
    if not isOwned then
        closeGarageUI()
        TriggerServerEvent('my_tunergarage:requestPurchase')
    end
    cb({ success = true })
end)

RegisterNUICallback('hireWorker', function(data, cb)
    closeGarageUI()
    TriggerServerEvent('my_tunergarage:hireWorker')
    cb({ success = true })
end)

RegisterNUICallback('collectProfit', function(data, cb)
    closeGarageUI()
    TriggerServerEvent('my_tunergarage:collectProfit')
    cb({ success = true })
end)

RegisterNUICallback('close', function(data, cb)
    closeGarageUI()
    cb({ success = true })
end)

-- ============================================================
-- INITIALIZATION
-- ============================================================

CreateThread(function()
    garageBlip = createGarageBlip()

    -- Request ownership status from server
    TriggerServerEvent('my_tunergarage:checkOwnership')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if garageBlip then
        RemoveBlip(garageBlip)
    end
    despawnMechanic()
    despawnCustomerCar()
    despawnRepairVehicle()
end)

-- ============================================================
-- Clear stationary NPCs and parked NPC vehicles around owned
-- garage (20m radius) - same logic as my_housing
-- Excludes mechanicPed and customerCar from cleanup
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
        local garageVec = vector3(Config.Garage.coords.x, Config.Garage.coords.y, Config.Garage.coords.z)

        -- Only bother if player is within 100m
        if #(playerCoords - garageVec) >= 100.0 then
            goto skipClear
        end

        -- Helper: is a coord inside the clear zone?
        local function IsInClearZone(coords)
            return #(coords - garageVec) <= CLEAR_RADIUS
        end

        -- 1) Remove stationary NPCs (skip our mechanic)
        local allPeds = GetGamePool('CPed')
        for _, ped in ipairs(allPeds) do
            if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
                -- Skip our mechanic ped
                if mechanicPed and ped == mechanicPed then
                    goto nextPed
                end

                local pedCoords = GetEntityCoords(ped)
                if IsInClearZone(pedCoords) then
                    local speed = GetEntitySpeed(ped)
                    if speed < 0.5 then
                        SetEntityAsMissionEntity(ped, true, true)
                        DeleteEntity(ped)
                    end
                end
            end

            ::nextPed::
        end

        -- 2) Remove parked NPC vehicles (skip our customer car + player-owned)
        local allVehicles = GetGamePool('CVehicle')
        for _, vehicle in ipairs(allVehicles) do
            if DoesEntityExist(vehicle) and IsVehicleStopped(vehicle) then
                -- Skip our customer car
                if customerCar and vehicle == customerCar then
                    goto nextVeh
                end

                -- Skip repair vehicle
                if repairVehicleEntity and vehicle == repairVehicleEntity then
                    goto nextVeh
                end

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
                end
            end

            ::nextVeh::
        end

        -- 3) Suppress vehicle generators so parked cars don't respawn
        RemoveVehiclesFromGeneratorsInArea(
            garageVec.x - CLEAR_RADIUS, garageVec.y - CLEAR_RADIUS, garageVec.z - CLEAR_RADIUS,
            garageVec.x + CLEAR_RADIUS, garageVec.y + CLEAR_RADIUS, garageVec.z + CLEAR_RADIUS,
            0
        )

        ::skipClear::
    end
end)

-- Proximity respawn: if mechanic/car were deleted by the game, recreate when player is near
CreateThread(function()
    while true do
        Wait(5000)
        if isOwned and hasWorker then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local garageVec = vector3(Config.Garage.coords.x, Config.Garage.coords.y, Config.Garage.coords.z)
            if #(playerCoords - garageVec) <= 50.0 then
                if not mechanicPed or not DoesEntityExist(mechanicPed) then
                    spawnMechanic()
                end
                if not customerCar or not DoesEntityExist(customerCar) then
                    spawnCustomerCar()
                end
            end
        end

        -- Respawn repair vehicle if it was streamed out
        if isOwned then
            local playerCoords2 = GetEntityCoords(PlayerPedId())
            local dCoords = Config.DropOff.vehicleCoords
            local dropVec = vector3(dCoords.x, dCoords.y, dCoords.z)
            if #(playerCoords2 - dropVec) <= 80.0 then
                if next(dropOffVehicleData) and (not repairVehicleEntity or not DoesEntityExist(repairVehicleEntity)) then
                    for plate, vData in pairs(dropOffVehicleData) do
                        if vData.model then
                            spawnRepairVehicle(vData.model, plate, vData.appearance)
                        end
                        break
                    end
                end
            elseif repairVehicleEntity and DoesEntityExist(repairVehicleEntity) then
                despawnRepairVehicle()
            end
        end
    end
end)

-- Scenario-ped suppression frame loop (prevents new NPCs/vehicles from spawning)
CreateThread(function()
    while true do
        if isOwned then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local garageVec = vector3(Config.Garage.coords.x, Config.Garage.coords.y, Config.Garage.coords.z)

            if #(playerCoords - garageVec) <= CLEAR_RADIUS + 10.0 then
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
