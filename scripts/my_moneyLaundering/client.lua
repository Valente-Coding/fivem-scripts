-- my_moneylaundering/client.lua
-- Client-side logic for the money laundering system

-- Local state
local isUIOpen = false
local bossBlip = nil
local bossPed = nil
local bodyguardPeds = {}
local lastLaunderTime = 0

-- ============================================================
-- PED SPAWNING
-- ============================================================

-- Load a model by hash, with timeout
local function loadModel(modelName)
    local model = GetHashKey(modelName)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    if not HasModelLoaded(model) then
        print("^1[my_moneylaundering ERROR]^7 Failed to load model: " .. modelName)
        return nil
    end
    return model
end

-- Spawn the boss ped
local function spawnBossPed()
    if bossPed and DoesEntityExist(bossPed) then return end

    local model = loadModel(Config.BossModel)
    if not model then return end

    local loc = Config.BossLocation
    bossPed = CreatePed(4, model, loc.x, loc.y, loc.z, loc.w, false, true)
    SetEntityHeading(bossPed, loc.w)
    FreezeEntityPosition(bossPed, true)
    SetEntityInvincible(bossPed, true)
    SetBlockingOfNonTemporaryEvents(bossPed, true)
    SetPedFleeAttributes(bossPed, 0, false)
    SetPedCombatAttributes(bossPed, 46, true)    -- ignore all events
    SetPedConfigFlag(bossPed, 17, true)           -- never leaves group
    SetPedConfigFlag(bossPed, 281, true)          -- no writhe
    SetPedCanRagdoll(bossPed, false)
    SetPedCanRagdollFromPlayerImpact(bossPed, false)
    SetPedSuffersCriticalHits(bossPed, false)
    SetEntityProofs(bossPed, true, true, true, true, true, true, true, true)
    SetPedRelationshipGroupHash(bossPed, GetHashKey("YOURGANG"))
    TaskStartScenarioInPlace(bossPed, Config.BossScenario, 0, true)
    SetModelAsNoLongerNeeded(model)
end

-- Spawn bodyguard peds
local function spawnBodyguards()
    local model = loadModel(Config.BodyGuardModel)
    if not model then return end

    for i, loc in ipairs(Config.BodyGuards) do
        if not bodyguardPeds[i] or not DoesEntityExist(bodyguardPeds[i]) then
            local ped = CreatePed(4, model, loc.x, loc.y, loc.z, loc.w, false, true)
            SetEntityHeading(ped, loc.w)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedFleeAttributes(ped, 0, false)
            SetPedCombatAttributes(ped, 46, true)
            SetPedConfigFlag(ped, 17, true)
            SetPedConfigFlag(ped, 281, true)
            SetPedCanRagdoll(ped, false)
            SetPedCanRagdollFromPlayerImpact(ped, false)
            SetPedSuffersCriticalHits(ped, false)
            SetEntityProofs(ped, true, true, true, true, true, true, true, true)
            SetPedRelationshipGroupHash(ped, GetHashKey("YOURGANG"))
            GiveWeaponToPed(ped, GetHashKey("WEAPON_CARBINERIFLE"), 999, false, true)
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_GUARD_STAND", 0, true)
            bodyguardPeds[i] = ped
        end
    end

    SetModelAsNoLongerNeeded(model)
end

-- ============================================================
-- BLIP
-- ============================================================

local function createBlip()
    if bossBlip then return end

    local loc = Config.BossLocation
    bossBlip = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipSprite(bossBlip, Config.Blip.sprite)
    SetBlipDisplay(bossBlip, 4)
    SetBlipScale(bossBlip, Config.Blip.scale)
    SetBlipColour(bossBlip, Config.Blip.color)
    SetBlipAsShortRange(bossBlip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.name)
    EndTextCommandSetBlipName(bossBlip)
end

-- ============================================================
-- UI HELPERS
-- ============================================================

local function openUI()
    if isUIOpen then return end

    -- Cooldown check
    local now = GetGameTimer() / 1000
    if (now - lastLaunderTime) < Config.Cooldown and lastLaunderTime > 0 then
        local remaining = math.ceil(Config.Cooldown - (now - lastLaunderTime))
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~r~The boss is busy. Come back in " .. remaining .. "s.")
        DrawNotification(false, false)
        return
    end

    -- Request dirty money balance from server
    TriggerServerEvent('my_moneylaundering:requestBalance')
end

-- Server responds with the player's dirty money balance
RegisterNetEvent('my_moneylaundering:receiveBalance')
AddEventHandler('my_moneylaundering:receiveBalance', function(dirtyMoney)
    if isUIOpen then return end

    local cleanAmount = math.floor(dirtyMoney * Config.LaunderRate)

    isUIOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        dirtyMoney = dirtyMoney,
        cleanAmount = cleanAmount,
        launderRate = Config.LaunderRate * 100,
        minRequired = Config.MinDirtyMoney
    })
end)

local function closeUI()
    if not isUIOpen then return end

    isUIOpen = false
    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'close'
    })
end

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

-- Close button
RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb('ok')
end)

-- Launder button
RegisterNUICallback('launder', function(data, cb)
    closeUI()
    lastLaunderTime = GetGameTimer() / 1000
    TriggerServerEvent('my_moneylaundering:launder')
    cb('ok')
end)

-- ============================================================
-- SERVER RESPONSE
-- ============================================================

RegisterNetEvent('my_moneylaundering:result')
AddEventHandler('my_moneylaundering:result', function(success, message)
    SendNUIMessage({
        action = 'feedback',
        success = success,
        message = message
    })
end)

-- ============================================================
-- 3D TEXT HELPER
-- ============================================================

local function drawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- ============================================================
-- MAIN THREAD
-- ============================================================

Citizen.CreateThread(function()
    createBlip()
    spawnBossPed()
    spawnBodyguards()

    while true do
        Citizen.Wait(0)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local bossCoords = Config.BossLocation

        local dist = #(playerCoords - vector3(bossCoords.x, bossCoords.y, bossCoords.z))

        if dist < Config.InteractionDistance then
            drawText3D(bossCoords.x, bossCoords.y, bossCoords.z + 1.0, "~w~Press ~g~E ~w~to talk")

            if IsControlJustPressed(0, 38) then -- E key
                openUI()
            end
        elseif dist > 100.0 then
            Citizen.Wait(2000)
        elseif dist > 30.0 then
            Citizen.Wait(500)
        end

        -- Re-spawn peds if they somehow despawned
        if dist < 80.0 then
            if not bossPed or not DoesEntityExist(bossPed) then
                spawnBossPed()
            end
            for i, ped in ipairs(bodyguardPeds) do
                if not DoesEntityExist(ped) then
                    spawnBodyguards()
                    break
                end
            end
        end
    end
end)

-- ============================================================
-- CLEANUP
-- ============================================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if isUIOpen then closeUI() end
    if bossPed and DoesEntityExist(bossPed) then DeleteEntity(bossPed) end
    for _, ped in ipairs(bodyguardPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    bodyguardPeds = {}
    if bossBlip and DoesBlipExist(bossBlip) then RemoveBlip(bossBlip) end
end)
