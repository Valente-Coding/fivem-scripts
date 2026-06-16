-- Client state
local currentContract = nil
local npcPed = nil
local spawnLocationBlip = nil
local vehicleBlip = nil
local vehicleTempBlip = nil
local deliveryBlip = nil
local contractVehicle = nil
local tempVehicle = nil
local isInDeliveryZone = false
local hasSpawnedVehicle = false
local alarmDisabled = false

-- ==================== HELPERS ====================

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function ShowHelpText(msg)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function DeleteVehicleEntity(vehicle)
    if vehicle and DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteEntity(vehicle)
    end
end

local function IsSpawnAreaClear(coords, radius)
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if #(coords - GetEntityCoords(vehicle)) < radius then
            return false
        end
    end
    for _, ped in ipairs(GetGamePool('CPed')) do
        if #(coords - GetEntityCoords(ped)) < radius then
            return false
        end
    end
    return true
end

-- ==================== INITIALIZATION ====================

CreateThread(function()
    local blip = AddBlipForCoord(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z)
    SetBlipSprite(blip, Config.Blips.npc.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blips.npc.scale)
    SetBlipColour(blip, Config.Blips.npc.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blips.npc.label)
    EndTextCommandSetBlipName(blip)
    
    SpawnNPC()
end)

function SpawnNPC()
    local modelHash = GetHashKey(Config.NPC.model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(100) end
    
    npcPed = CreatePed(4, modelHash, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.heading, false, true)
    SetEntityHeading(npcPed, Config.NPC.heading)
    SetEntityAsMissionEntity(npcPed, true, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    SetEntityInvincible(npcPed, true)
    FreezeEntityPosition(npcPed, true)
    SetModelAsNoLongerNeeded(modelHash)
end

function SpawnTempVehicle()
    if tempVehicle and DoesEntityExist(tempVehicle) then
        DeleteVehicleEntity(tempVehicle)
    end
    
    local coords = Config.NPC.tempVehicleSpawnLocation
    local spawnVec = vector3(coords.x, coords.y, coords.z)
    
    CreateThread(function()
        local notified = false
        while not IsSpawnAreaClear(spawnVec, 5.0) do
            if not notified then
                ShowNotification(Config.Locale.spawn_area_blocked)
                notified = true
            end
            Wait(2000)
            if not currentContract then return end
        end
        
        local modelHash = GetHashKey(Config.NPC.tempVehicleModel)
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do Wait(100) end
        
        tempVehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, coords.w, true, false)
        SetVehicleOnGroundProperly(tempVehicle)
        SetEntityAsMissionEntity(tempVehicle, true, true)
        SetModelAsNoLongerNeeded(modelHash)

        vehicleTempBlip = AddBlipForEntity(tempVehicle)
        local tier = GetTierById(currentContract.tierId)
        SetBlipSprite(vehicleTempBlip, tier.blipSprite)
        SetBlipDisplay(vehicleTempBlip, 4)
        SetBlipScale(vehicleTempBlip, 0.8)
        SetBlipColour(vehicleTempBlip, 40)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Temporary Vehicle")
        EndTextCommandSetBlipName(vehicleTempBlip)
    end)
end

function DeleteTempVehicle()
    if vehicleTempBlip then
        RemoveBlip(vehicleTempBlip)
        vehicleTempBlip = nil
    end
    if tempVehicle and DoesEntityExist(tempVehicle) then
        DeleteVehicleEntity(tempVehicle)
        tempVehicle = nil
    end
end

-- ==================== NPC INTERACTION ====================

CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - Config.NPC.coords)
        
        if distance < 20.0 then
            sleep = 0
            DrawMarker(
                Config.NPC.markerType,
                Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                Config.NPC.markerSize.x, Config.NPC.markerSize.y, Config.NPC.markerSize.z,
                Config.NPC.markerColor.r, Config.NPC.markerColor.g, Config.NPC.markerColor.b, Config.NPC.markerColor.a,
                false, true, 2, false, nil, nil, false
            )
            
            if distance < Config.NPC.interactionDistance then
                ShowHelpText(Config.Locale.npc_help)
                if IsControlJustReleased(0, 38) then
                    OpenContractUI()
                end
            end
        end
        Wait(sleep)
    end
end)

function OpenContractUI()
    TriggerServerEvent('vehicleFlipper:requestContractData')
end

-- Receive contract data from server
RegisterNetEvent('vehicleFlipper:receiveContractData')
AddEventHandler('vehicleFlipper:receiveContractData', function(activeContract, cashMoney, dirtyMoney, onCooldown, cooldownTier, remainingSeconds)
    SendNUIMessage({
        action = 'openContractUI',
        tiers = Config.Tiers,
        activeContract = activeContract,
        playerCash = cashMoney,
        playerDirtyMoney = dirtyMoney,
        cooldown = {
            active = onCooldown,
            tierId = cooldownTier,
            remainingSeconds = remainingSeconds
        }
    })
    SetNuiFocus(true, true)
end)

-- ==================== PROXIMITY VEHICLE SPAWN ====================

CreateThread(function()
    while true do
        Wait(2000)
        if currentContract and not hasSpawnedVehicle then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - currentContract.spawnCoords)
            if distance < Config.ProximitySpawnDistance then
                TriggerServerEvent('vehicleFlipper:requestSpawnVehicle')
            end
        end
    end
end)

-- ==================== DELIVERY ZONE DETECTION ====================

CreateThread(function()
    while true do
        local sleep = 1000
        
        if currentContract and contractVehicle and hasSpawnedVehicle then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - Config.NPC.deliveryLocation)
            local playerVehicle = GetVehiclePedIsIn(playerPed, false)
            
            if playerVehicle == contractVehicle and distance < Config.DeliveryRadius then
                sleep = 0
                local wantedLevel = GetPlayerWantedLevel(PlayerId())
                if wantedLevel > 0 then
                    ShowNotification(Config.Locale.wanted_delivery_cancelled)
                    TriggerServerEvent('vehicleFlipper:cancelContract')
                    CleanupMission()
                else
                    if not isInDeliveryZone then
                        isInDeliveryZone = true
                    end
                    ShowHelpText(Config.Locale.delivery_help)
                    if IsControlJustReleased(0, 38) then
                        OpenDeliveryUI()
                    end
                end
            else
                if isInDeliveryZone then
                    isInDeliveryZone = false
                end
            end
        end
        Wait(sleep)
    end
end)

function OpenDeliveryUI()
    if not contractVehicle or not DoesEntityExist(contractVehicle) then return end
    
    local engineHealth = GetVehicleEngineHealth(contractVehicle)
    local bodyHealth = GetVehicleBodyHealth(contractVehicle)
    local enginePercent = math.max(0, math.min(100, (engineHealth / 1000) * 100))
    local bodyPercent = math.max(0, math.min(100, (bodyHealth / 1000) * 100))
    local conditionPercent = (enginePercent * Config.DamageCalculation.engineWeight) + 
                            (bodyPercent * Config.DamageCalculation.bodyWeight)
    
    local tier = GetTierById(currentContract.tierId)
    local basePayout = currentContract.vehiclePrice * tier.rewardMultiplier
    local conditionMultiplier = math.max(Config.DamageCalculation.minimumMultiplier, conditionPercent / 100)
    local finalPayout = math.floor(basePayout * conditionMultiplier)
    
    SendNUIMessage({
        action = 'openDeliveryUI',
        deliveryData = {
            vehicleLabel = currentContract.vehicleLabel,
            vehiclePrice = currentContract.vehiclePrice,
            conditionPercent = conditionPercent,
            tierId = currentContract.tierId,
            sellPayout = finalPayout
        }
    })
    SetNuiFocus(true, true)
end

-- ==================== VEHICLE INTERACTION (LOCKPICKING) ====================

CreateThread(function()
    while true do
        local sleep = 1000
        
        if currentContract and contractVehicle and hasSpawnedVehicle then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local vehicleCoords = GetEntityCoords(contractVehicle)
            local distance = #(playerCoords - vehicleCoords)
            
            if distance < 5.0 then
                sleep = 0
                local vehicleLocked = GetVehicleDoorLockStatus(contractVehicle) == 2
                if vehicleLocked and distance < 2.0 then
                    if alarmDisabled then
                        ShowHelpText("Press ~INPUT_CONTEXT~ to unlock vehicle (~g~alarm disabled~s~)")
                        if IsControlJustReleased(0, 38) then
                            -- Bypass lockpick minigame entirely
                            SetVehicleDoorsLocked(contractVehicle, 1)
                            SetVehicleDoorsLockedForAllPlayers(contractVehicle, false)
                            ShowNotification("~g~Alarm bypassed! Vehicle unlocked silently.")
                            alarmDisabled = false

                            if deliveryBlip then RemoveBlip(deliveryBlip) end
                            deliveryBlip = AddBlipForCoord(Config.NPC.deliveryLocation.x, Config.NPC.deliveryLocation.y, Config.NPC.deliveryLocation.z)
                            local tier = GetTierById(currentContract.tierId)
                            SetBlipSprite(deliveryBlip, 1)
                            SetBlipDisplay(deliveryBlip, 4)
                            SetBlipScale(deliveryBlip, 0.9)
                            SetBlipColour(deliveryBlip, tier.blipColor)
                            SetBlipRoute(deliveryBlip, true)
                            SetBlipRouteColour(deliveryBlip, tier.blipColor)
                            BeginTextCommandSetBlipName("STRING")
                            AddTextComponentString("Delivery Location")
                            EndTextCommandSetBlipName(deliveryBlip)
                        end
                    else
                        ShowHelpText(Config.Locale.lockpick_help)
                        if IsControlJustReleased(0, 38) then
                            OpenLockpickUI()
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

function OpenLockpickUI()
    local tier = GetTierById(currentContract.tierId)
    SendNUIMessage({
        action = 'openLockpickUI',
        lockpickSettings = tier.lockpick
    })
    SetNuiFocus(true, true)
end

-- ==================== NUI CALLBACKS ====================

RegisterNUICallback('requestContract', function(data, cb)
    TriggerServerEvent('vehicleFlipper:requestContract', data.tierId, data.paymentType)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('cancelContract', function(data, cb)
    TriggerServerEvent('vehicleFlipper:cancelContract')
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('lockpickSuccess', function(data, cb)
    SetVehicleDoorsLocked(contractVehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(contractVehicle, false)
    ShowNotification(Config.Locale.lockpick_success)
    
    if deliveryBlip then RemoveBlip(deliveryBlip) end
    
    deliveryBlip = AddBlipForCoord(Config.NPC.deliveryLocation.x, Config.NPC.deliveryLocation.y, Config.NPC.deliveryLocation.z)
    local tier = GetTierById(currentContract.tierId)
    SetBlipSprite(deliveryBlip, 1)
    SetBlipDisplay(deliveryBlip, 4)
    SetBlipScale(deliveryBlip, 0.9)
    SetBlipColour(deliveryBlip, tier.blipColor)
    SetBlipRoute(deliveryBlip, true)
    SetBlipRouteColour(deliveryBlip, tier.blipColor)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery Location")
    EndTextCommandSetBlipName(deliveryBlip)
    
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('lockpickFailed', function(data, cb)
    local tier = GetTierById(currentContract.tierId)
    SetPlayerWantedLevel(PlayerId(), tier.wantedLevel, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
    ShowNotification(Config.Locale.lockpick_failed)
    ShowNotification(Config.Locale.police_called)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('lockpickCancelled', function(data, cb)
    ShowNotification(Config.Locale.lockpick_cancelled)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('deliverKeep', function(data, cb)
    -- Send plate, position, and vehicle properties to server
    local plate = GetVehicleNumberPlateText(contractVehicle)
    local vehCoords = GetEntityCoords(contractVehicle)
    local vehHeading = GetEntityHeading(contractVehicle)
    
    -- Capture vehicle properties so colors/state persist
    SetVehicleModKit(contractVehicle, 0)
    local colorPrimary, colorSecondary = GetVehicleColours(contractVehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(contractVehicle)
    local modColor1Type, modColor1, modColor1Pearl = GetVehicleModColor_1(contractVehicle)
    local modColor2Type, modColor2 = GetVehicleModColor_2(contractVehicle)
    
    local vehProperties = {
        color1 = colorPrimary,
        color2 = colorSecondary,
        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,
        modColor1 = {modColor1Type, modColor1, modColor1Pearl},
        modColor2 = {modColor2Type, modColor2},
        bodyHealth = GetVehicleBodyHealth(contractVehicle),
        engineHealth = GetVehicleEngineHealth(contractVehicle)
    }
    
    TriggerServerEvent('vehicleFlipper:deliverKeep', plate, vehCoords.x, vehCoords.y, vehCoords.z, vehHeading, vehProperties)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('deliverSell', function(data, cb)
    local engineHealth = GetVehicleEngineHealth(contractVehicle)
    local bodyHealth = GetVehicleBodyHealth(contractVehicle)
    local enginePercent = math.max(0, math.min(100, (engineHealth / 1000) * 100))
    local bodyPercent = math.max(0, math.min(100, (bodyHealth / 1000) * 100))
    local conditionPercent = (enginePercent * Config.DamageCalculation.engineWeight) + 
                            (bodyPercent * Config.DamageCalculation.bodyWeight)
    
    TriggerServerEvent('vehicleFlipper:deliverSell', conditionPercent)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ==================== SERVER EVENTS ====================

RegisterNetEvent('vehicleFlipper:contractAccepted')
AddEventHandler('vehicleFlipper:contractAccepted', function(contractData)
    currentContract = contractData
    hasSpawnedVehicle = false
    SpawnTempVehicle()
    
    if spawnLocationBlip then RemoveBlip(spawnLocationBlip) end
    
    spawnLocationBlip = AddBlipForCoord(contractData.spawnCoords.x, contractData.spawnCoords.y, contractData.spawnCoords.z)
    SetBlipSprite(spawnLocationBlip, Config.Blips.spawnLocation.sprite)
    SetBlipDisplay(spawnLocationBlip, 4)
    SetBlipScale(spawnLocationBlip, Config.Blips.spawnLocation.scale)
    SetBlipColour(spawnLocationBlip, Config.Blips.spawnLocation.color)
    SetBlipRoute(spawnLocationBlip, true)
    SetBlipRouteColour(spawnLocationBlip, Config.Blips.spawnLocation.color)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blips.spawnLocation.label)
    EndTextCommandSetBlipName(spawnLocationBlip)
    
    ShowNotification(Config.Locale.contract_started)
end)

RegisterNetEvent('vehicleFlipper:spawnVehicle')
AddEventHandler('vehicleFlipper:spawnVehicle', function(vehicleModel, spawnCoords, spawnHeading)
    if spawnLocationBlip then
        RemoveBlip(spawnLocationBlip)
        spawnLocationBlip = nil
    end
    
    local modelHash = GetHashKey(vehicleModel)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(100) end
    
    contractVehicle = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, false)
    SetVehicleOnGroundProperly(contractVehicle)
    SetVehicleDoorsLocked(contractVehicle, 2)
    SetVehicleEngineOn(contractVehicle, false, true, false)
    SetEntityAsMissionEntity(contractVehicle, true, true)
    SetVehicleNumberPlateText(contractVehicle, GeneratePlate())
    
    vehicleBlip = AddBlipForEntity(contractVehicle)
    local tier = GetTierById(currentContract.tierId)
    SetBlipSprite(vehicleBlip, tier.blipSprite)
    SetBlipDisplay(vehicleBlip, 4)
    SetBlipScale(vehicleBlip, 0.8)
    SetBlipColour(vehicleBlip, tier.blipColor)
    SetBlipRoute(vehicleBlip, true)
    SetBlipRouteColour(vehicleBlip, tier.blipColor)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Target Vehicle")
    EndTextCommandSetBlipName(vehicleBlip)
    
    hasSpawnedVehicle = true
    SetModelAsNoLongerNeeded(modelHash)
    
    TriggerServerEvent('vehicleFlipper:confirmSpawn', NetworkGetNetworkIdFromEntity(contractVehicle))
end)

RegisterNetEvent('vehicleFlipper:updateTimer')
AddEventHandler('vehicleFlipper:updateTimer', function(timeRemaining)
    SendNUIMessage({
        action = 'updateTimer',
        timeRemaining = timeRemaining
    })
end)

RegisterNetEvent('vehicleFlipper:missionExpired')
AddEventHandler('vehicleFlipper:missionExpired', function()
    ShowNotification(Config.Locale.mission_expired)
    CleanupMission()
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, Config.NPC.deliveryLocation.x, Config.NPC.deliveryLocation.y, Config.NPC.deliveryLocation.z)
end)

RegisterNetEvent('vehicleFlipper:missionFailed')
AddEventHandler('vehicleFlipper:missionFailed', function(reason)
    ShowNotification(reason)
    CleanupMission()
end)

RegisterNetEvent('vehicleFlipper:contractCancelled')
AddEventHandler('vehicleFlipper:contractCancelled', function(refundAmount)
    ShowNotification(string.format(Config.Locale.contract_cancelled, refundAmount))
    CleanupMission()
end)

RegisterNetEvent('vehicleFlipper:vehicleKept')
AddEventHandler('vehicleFlipper:vehicleKept', function(plate)
    ShowNotification(string.format(Config.Locale.vehicle_kept, plate))
    CleanupMission(true) -- Keep vehicle
end)

RegisterNetEvent('vehicleFlipper:vehicleSold')
AddEventHandler('vehicleFlipper:vehicleSold', function(amount)
    ShowNotification(string.format(Config.Locale.vehicle_sold, amount))
    currentContract = nil
    
    local playerPed = PlayerPedId()
    TaskLeaveVehicle(playerPed, contractVehicle, 0)
    SetVehicleDoorsLocked(contractVehicle, 2)
    
    if vehicleBlip then RemoveBlip(vehicleBlip) vehicleBlip = nil end
    if deliveryBlip then RemoveBlip(deliveryBlip) deliveryBlip = nil end
    DeleteTempVehicle()
    
    -- Capture vehicle entity in a local so the thread doesn't follow
    -- a reassigned contractVehicle if the player takes a new contract
    local soldVehicle = contractVehicle
    contractVehicle = nil
    
    CreateThread(function()
        while soldVehicle and DoesEntityExist(soldVehicle) do
            Wait(1000)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local vehicleCoords = GetEntityCoords(soldVehicle)
            local distance = #(playerCoords - vehicleCoords)
            if distance > Config.VehicleDespawnDistance then
                DeleteVehicleEntity(soldVehicle)
                break
            end
        end
    end)
end)

-- ==================== CLEANUP ====================

function CleanupMission(keepVehicle)
    if spawnLocationBlip then RemoveBlip(spawnLocationBlip) spawnLocationBlip = nil end
    if vehicleBlip then RemoveBlip(vehicleBlip) vehicleBlip = nil end
    if deliveryBlip then RemoveBlip(deliveryBlip) deliveryBlip = nil end
    DeleteTempVehicle()
    
    if not keepVehicle and contractVehicle and DoesEntityExist(contractVehicle) then
        DeleteVehicleEntity(contractVehicle)
    end
    
    currentContract = nil
    contractVehicle = nil
    isInDeliveryZone = false
    hasSpawnedVehicle = false
    alarmDisabled = false
    
    SendNUIMessage({ action = 'closeUI' })
    SetNuiFocus(false, false)
end

-- ==================== UTILITIES ====================

function GetTierById(tierId)
    for _, tier in ipairs(Config.Tiers) do
        if tier.id == tierId then return tier end
    end
    return nil
end

function GeneratePlate()
    local plate = Config.PlateFormat.prefix or ""
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    if Config.PlateFormat.letters > 0 then
        for i = 1, Config.PlateFormat.letters do
            local rand = math.random(1, #charset)
            plate = plate .. string.sub(charset, rand, rand)
        end
    end
    if Config.PlateFormat.numbers > 0 then
        for i = 1, Config.PlateFormat.numbers do
            plate = plate .. math.random(0, 9)
        end
    end
    return plate
end

-- ==================== ALARM DISABLER ITEM ====================

RegisterNetEvent('my_inventory:onItemUsed')
AddEventHandler('my_inventory:onItemUsed', function(itemName)
    if itemName ~= 'alarm_disabler' then return end

    -- Must have an active contract with a spawned vehicle
    if not currentContract or not contractVehicle or not DoesEntityExist(contractVehicle) then
        ShowNotification("~r~You don't have an active vehicle contract.")
        return
    end

    -- Vehicle must still be locked
    if GetVehicleDoorLockStatus(contractVehicle) ~= 2 then
        ShowNotification("~r~This vehicle is already unlocked.")
        return
    end

    -- Must be near the target vehicle
    local playerCoords = GetEntityCoords(PlayerPedId())
    local vehicleCoords = GetEntityCoords(contractVehicle)
    if #(playerCoords - vehicleCoords) > 5.0 then
        ShowNotification("~r~You must be near the target vehicle.")
        return
    end

    alarmDisabled = true
    ShowNotification("~g~Alarm Disabler activated! Approach the vehicle to unlock it silently.")
end)

-- Force cancel mission (called on player death)
RegisterNetEvent('my_vehicleFlipper:forceCancel')
AddEventHandler('my_vehicleFlipper:forceCancel', function()
    if not currentContract then return end
    TriggerServerEvent('vehicleFlipper:cancelContract')
    CleanupMission()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupMission()
        if npcPed then DeleteEntity(npcPed) end
    end
end)
