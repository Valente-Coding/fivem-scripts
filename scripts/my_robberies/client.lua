-- Store Robbery Client
local isRobbing = false
local robberyBlips = {}
local canRob = true
local cooldownTime = 0
local createdNPCs = {}
local createdNPCModels = {}
local currentLocation = nil
local currentWeaponHash = nil

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function DisplayHelpText(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

local function LoadAnimDict(dict)
    local attempts = 0
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end
    return HasAnimDictLoaded(dict)
end

local function HasRequiredWeapon()
    local playerPed = PlayerPedId()
    for _, weapon in pairs(Config.AllowedWeapons) do
        if HasPedGotWeapon(playerPed, GetHashKey(weapon), false) then
            return true, weapon
        end
    end
    return false, nil
end

local function IsFemaleModel(modelName)
    local femaleModels = {"s_f_y_shop_mid", "s_f_y_shop_low", "a_f_y_business_01", "a_f_m_business_02"}
    for _, fm in ipairs(femaleModels) do
        if modelName == fm then return true end
    end
    return false
end

local function PlayIdleAnimation(npc, modelName)
    local isFemale = IsFemaleModel(modelName)
    if isFemale then
        if LoadAnimDict("amb@world_human_stand_impatient@female@no_sign@base") then
            TaskPlayAnim(npc, "amb@world_human_stand_impatient@female@no_sign@base", "base", 8.0, 1.0, -1, 1, 0, false, false, false)
        end
    else
        if LoadAnimDict("amb@world_human_stand_impatient@male@no_sign@base") then
            TaskPlayAnim(npc, "amb@world_human_stand_impatient@male@no_sign@base", "base", 8.0, 1.0, -1, 1, 0, false, false, false)
        end
    end
end

local function PlayRobberyNPCAnimation(npc)
    local animations = {
        {dict = "missminuteman_1ig_2", anim = "handsup_base", flags = 49},
        {dict = "random@arrests@busted", anim = "idle_a", flags = 49},
        {dict = "random@mugging3", anim = "handsup_standing_base", flags = 49},
        {dict = "mp_am_hold_up", anim = "handsup_base", flags = 49},
    }

    for _, anim in ipairs(animations) do
        if LoadAnimDict(anim.dict) then
            TaskPlayAnim(npc, anim.dict, anim.anim, 8.0, -8.0, -1, anim.flags, 0, false, false, false)
            Wait(500)
            if IsEntityPlayingAnim(npc, anim.dict, anim.anim, 3) then
                return true
            end
        end
    end

    TaskHandsUp(npc, 60000, PlayerPedId(), -1, true)
    return false
end

local function CreateStoreClerk(location, locationIndex)
    local modelName = location.specificModel or Config.ClerkModels[math.random(#Config.ClerkModels)]
    local modelHash = GetHashKey(modelName)

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(1) end

    local npc = CreatePed(4, modelHash, location.npcPos.x, location.npcPos.y, location.npcPos.z, location.npcPos.w, false, true)
    SetEntityHeading(npc, location.npcPos.w)
    SetEntityAsMissionEntity(npc, true, true)
    SetEntityInvincible(npc, true)
    SetPedFleeAttributes(npc, 0, false)
    SetPedCombatAttributes(npc, 46, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedCanBeTargetted(npc, true)
    SetPedCanRagdoll(npc, true)
    SetPedSuffersCriticalHits(npc, false)
    SetPedSeeingRange(npc, 5.0)
    SetPedHearingRange(npc, 5.0)

    createdNPCs[locationIndex] = npc
    createdNPCModels[locationIndex] = modelName

    PlayIdleAnimation(npc, modelName)
    SetModelAsNoLongerNeeded(modelHash)

    return npc
end

local function CreateRobberyBlips()
    for i, location in pairs(Config.RobberyLocations) do
        local blip = AddBlipForCoord(location.startRobberyPos.x, location.startRobberyPos.y, location.startRobberyPos.z)
        SetBlipSprite(blip, 156)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 1)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Robbery Location")
        EndTextCommandSetBlipName(blip)
        table.insert(robberyBlips, blip)
    end
end

local function StartRobbery(locationIndex)
    local location = Config.RobberyLocations[locationIndex]
    local hasWeapon, weapon = HasRequiredWeapon()

    if not hasWeapon then
        ShowNotification("~r~You don't have the required weapon!")
        SetPlayerWantedLevel(PlayerId(), Config.WantedLevel.WithoutWeapon, false)
        SetPlayerWantedLevelNow(PlayerId(), true)
        return
    end

    if not canRob then
        ShowNotification("~r~Wait " .. cooldownTime .. " more minutes before robbing again!")
        return
    end

    currentWeaponHash = GetHashKey(weapon)
    currentLocation = locationIndex
    isRobbing = true

    local playerPed = PlayerPedId()
    TaskAimGunAtEntity(playerPed, createdNPCs[currentLocation], -1, true)
    SetCurrentPedWeapon(playerPed, currentWeaponHash, true)

    local npc = createdNPCs[locationIndex]
    if DoesEntityExist(npc) then
        ClearPedTasks(npc)
        PlayRobberyNPCAnimation(npc)
        TaskLookAtEntity(npc, playerPed, -1, 2048, 3)
        if IsPedHuman(npc) then
            SetFacialIdleAnimOverride(npc, "mood_stressed_1", 0)
        end
    end

    SetPlayerWantedLevel(PlayerId(), Config.WantedLevel.WithWeapon, false)
    SetPlayerWantedLevelNow(PlayerId(), true)
    ShowNotification("~o~Robbery in progress...")

    Wait(location.timeToRob)

    if isRobbing then
        isRobbing = false
        ClearPedTasks(playerPed)

        if DoesEntityExist(createdNPCs[locationIndex]) then
            ClearPedTasks(createdNPCs[locationIndex])
            ClearFacialIdleAnimOverride(createdNPCs[locationIndex])
            Wait(1000)
            PlayIdleAnimation(createdNPCs[locationIndex], createdNPCModels[locationIndex])
        end

        TriggerServerEvent('my_robberies:giveMoney')

        canRob = false
        cooldownTime = Config.Cooldown

        CreateThread(function()
            while cooldownTime > 0 do
                Wait(60000)
                cooldownTime = cooldownTime - 1
                if cooldownTime <= 0 then
                    canRob = true
                end
            end
        end)
    end
end

CreateThread(function()
    Wait(1000)
    CreateRobberyBlips()

    for i, location in pairs(Config.RobberyLocations) do
        CreateStoreClerk(location, i)
        Wait(100)
    end

    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        local nearestDist, nearestIndex = 9999.0, nil
        for i, location in pairs(Config.RobberyLocations) do
            local d = #(playerCoords - location.startRobberyPos)
            if d < nearestDist then
                nearestDist = d
                nearestIndex = i
            end
        end

        if nearestIndex and not isRobbing then
            local loc = Config.RobberyLocations[nearestIndex]
            if nearestDist < 20.0 then
                sleep = 0
                DrawMarker(1, loc.startRobberyPos.x, loc.startRobberyPos.y, loc.startRobberyPos.z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
                if nearestDist < 2.0 then
                    DisplayHelpText("Press ~INPUT_CONTEXT~ to rob")
                    if IsControlJustReleased(0, 38) then
                        StartRobbery(nearestIndex)
                    end
                end
            else
                sleep = math.min(2000, math.floor(nearestDist * 50))
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, blip in pairs(robberyBlips) do RemoveBlip(blip) end
        for _, npc in pairs(createdNPCs) do
            if DoesEntityExist(npc) then DeleteEntity(npc) end
        end
    end
end)
