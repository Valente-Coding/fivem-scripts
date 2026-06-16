-- Warehouse Job Client
local isJobActive = false
local playerData = nil
local mainBlip = nil
local jobData = {
    pickupPoint = nil,
    dropoffPoint = nil,
    boxesCarried = 0,
    totalBoxes = 0,
    startTime = 0,
    currentBlip = nil,
    isCarrying = false,
    boxObject = nil
}

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

local function SpawnObject(model, coords, cb)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    local obj = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, true, true, true)
    SetModelAsNoLongerNeeded(hash)
    if cb then cb(obj) end
end

local function PlayPickupAnimation()
    local playerPed = PlayerPedId()
    RequestAnimDict(Config.CarryAnimation.dict)
    while not HasAnimDictLoaded(Config.CarryAnimation.dict) do Wait(100) end
    TaskPlayAnim(playerPed, Config.CarryAnimation.dict, Config.CarryAnimation.anim,
        8.0, -8.0, -1, Config.CarryAnimation.flag, 0, false, false, false)
end

local function UpdateJobUI()
    if not isJobActive then return end
    local currentTime = GetGameTimer()
    local elapsedTime = math.floor((currentTime - jobData.startTime) / 1000)
    local timeLeft = (Config.JobTimeLimit * 60) - elapsedTime
    local minutes = math.floor(timeLeft / 60)
    local seconds = timeLeft % 60
    local timeString = string.format("%02d:%02d", minutes, seconds)

    local maxLevel = 5
    local nextLevelJobs = 0
    if playerData and playerData.level < maxLevel then
        local required = Config.RequiredJobsForLevel[playerData.level + 1]
        if required then nextLevelJobs = required - playerData.jobsDone end
    end

    SendNUIMessage({
        type = 'updateHUD',
        level = playerData and playerData.level or 1,
        timeLeft = timeString,
        boxes = jobData.boxesCarried,
        totalBoxes = jobData.totalBoxes,
        nextLevelJobs = nextLevelJobs,
        maxLevel = (playerData and playerData.level >= maxLevel)
    })
end

local function InitJobUI()
    SendNUIMessage({ type = 'showHUD' })
    UpdateJobUI()
    CreateThread(function()
        while isJobActive do UpdateJobUI(); Wait(1000) end
    end)
end

local function CloseJobUI()
    SendNUIMessage({ type = 'hideHUD' })
end

local function PickUpBox()
    if jobData.isCarrying then
        ShowNotification("~r~Already carrying a box!")
        return
    end

    PlayPickupAnimation()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    SpawnObject(Config.CarryAnimation.prop, coords, function(obj)
        jobData.boxObject = obj
        AttachEntityToEntity(obj, playerPed, GetPedBoneIndex(playerPed, 60309),
            Config.CarryAnimation.propPos[1], Config.CarryAnimation.propPos[2], Config.CarryAnimation.propPos[3],
            Config.CarryAnimation.propRot[1], Config.CarryAnimation.propRot[2], Config.CarryAnimation.propRot[3],
            true, true, false, true, 0, true)
    end)

    jobData.isCarrying = true

    -- Update blip to dropoff
    if jobData.currentBlip then RemoveBlip(jobData.currentBlip) end
    jobData.currentBlip = AddBlipForCoord(jobData.dropoffPoint.x, jobData.dropoffPoint.y, jobData.dropoffPoint.z)
    SetBlipSprite(jobData.currentBlip, 501)
    SetBlipColour(jobData.currentBlip, 5)
    SetBlipAsShortRange(jobData.currentBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Box Dropoff")
    EndTextCommandSetBlipName(jobData.currentBlip)

    ShowNotification("~b~Box picked up! Deliver to the marked location.")
end

local function DropOffBox()
    if not jobData.isCarrying then return end

    ClearPedTasks(PlayerPedId())
    if jobData.boxObject then
        DetachEntity(jobData.boxObject, true, true)
        DeleteEntity(jobData.boxObject)
        jobData.boxObject = nil
    end

    jobData.isCarrying = false
    jobData.boxesCarried = jobData.boxesCarried + 1
    UpdateJobUI()

    if jobData.boxesCarried >= jobData.totalBoxes then
        FinishJob(true)
    else
        -- New random pickup/dropoff
        jobData.pickupPoint = Config.BoxPickupPoints[math.random(#Config.BoxPickupPoints)]
        jobData.dropoffPoint = Config.BoxDropoffPoints[math.random(#Config.BoxDropoffPoints)]

        if jobData.currentBlip then RemoveBlip(jobData.currentBlip) end
        jobData.currentBlip = AddBlipForCoord(jobData.pickupPoint.x, jobData.pickupPoint.y, jobData.pickupPoint.z)
        SetBlipSprite(jobData.currentBlip, 478)
        SetBlipColour(jobData.currentBlip, 5)
        SetBlipAsShortRange(jobData.currentBlip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Box Pickup")
        EndTextCommandSetBlipName(jobData.currentBlip)

        ShowNotification("~g~Box delivered! " .. (jobData.totalBoxes - jobData.boxesCarried) .. " more to go.")
    end
end

function FinishJob(completed)
    if not isJobActive then return end

    if jobData.currentBlip then
        RemoveBlip(jobData.currentBlip)
        jobData.currentBlip = nil
    end

    if jobData.isCarrying and jobData.boxObject then
        ClearPedTasks(PlayerPedId())
        DetachEntity(jobData.boxObject, true, true)
        DeleteEntity(jobData.boxObject)
        jobData.boxObject = nil
        jobData.isCarrying = false
    end

    -- Restore the main job blip color
    if mainBlip then
        SetBlipColour(mainBlip, 5)
    end

    CloseJobUI()
    isJobActive = false

    if completed then
        TriggerServerEvent('my_warehousejob:jobComplete', jobData.boxesCarried)
    else
        TriggerServerEvent('my_warehousejob:cancelJob')
        ShowNotification("~y~Warehouse job cancelled.")
    end
end

function StartWarehouseJob(totalBoxes)
    jobData.boxesCarried = 0
    jobData.totalBoxes = totalBoxes
    jobData.startTime = GetGameTimer()
    jobData.pickupPoint = Config.BoxPickupPoints[math.random(#Config.BoxPickupPoints)]
    jobData.dropoffPoint = Config.BoxDropoffPoints[math.random(#Config.BoxDropoffPoints)]

    jobData.currentBlip = AddBlipForCoord(jobData.pickupPoint.x, jobData.pickupPoint.y, jobData.pickupPoint.z)
    SetBlipSprite(jobData.currentBlip, 478)
    SetBlipColour(jobData.currentBlip, 5)
    SetBlipAsShortRange(jobData.currentBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Box Pickup")
    EndTextCommandSetBlipName(jobData.currentBlip)

    -- Grey out the main job blip so it doesn't get confused with mission blips
    if mainBlip then
        SetBlipColour(mainBlip, 20)
    end

    InitJobUI()
    ShowNotification("~b~Warehouse job started! Go pick up boxes.")
end

-- Blip
CreateThread(function()
    mainBlip = AddBlipForCoord(Config.JobMenuCoord.x, Config.JobMenuCoord.y, Config.JobMenuCoord.z)
    SetBlipSprite(mainBlip, 478)
    SetBlipDisplay(mainBlip, 4)
    SetBlipScale(mainBlip, 0.8)
    SetBlipColour(mainBlip, 5)
    SetBlipAsShortRange(mainBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Warehouse Job")
    EndTextCommandSetBlipName(mainBlip)
end)

-- Menu marker loop
CreateThread(function()
    while true do
        local sleep = 1000
        if not isJobActive then
            local coords = GetEntityCoords(PlayerPedId())
            local pos = vector3(Config.JobMenuCoord.x, Config.JobMenuCoord.y, Config.JobMenuCoord.z)
            local dist = #(coords - pos)

            if dist < 20.0 then
                sleep = 0
                DrawMarker(1, pos.x, pos.y, pos.z - 1.0, 0, 0, 0, 0, 0, 0,
                    1.5, 1.5, 1.0, 0, 150, 255, 100, false, true, 2, false, nil, nil, false)
                if dist < 1.5 then
                    DisplayHelpText("Press ~INPUT_CONTEXT~ to open Warehouse Job menu")
                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('my_warehousejob:requestPlayerData')
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Job interaction loop
CreateThread(function()
    while true do
        if isJobActive then
            Wait(0)
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local actionText = nil

            -- Cancel key check
            if IsControlJustPressed(0, 194) then
                FinishJob(false)
            end

            -- Pickup zone
            if not jobData.isCarrying and jobData.pickupPoint then
                local pickupPos = vector3(jobData.pickupPoint.x, jobData.pickupPoint.y, jobData.pickupPoint.z)
                local pickupDist = #(coords - pickupPos)
                if pickupDist < 20.0 then
                    DrawMarker(1, pickupPos.x, pickupPos.y, pickupPos.z - 1.0, 0, 0, 0, 0, 0, 0,
                        1.5, 1.5, 1.0, 0, 255, 0, 100, false, true, 2, false, nil, nil, false)
                    if pickupDist < 1.5 then
                        actionText = "Press ~INPUT_CONTEXT~ to pick up box"
                        if IsControlJustPressed(0, 38) then PickUpBox() end
                    end
                end
            end

            -- Dropoff zone
            if jobData.isCarrying and jobData.dropoffPoint then
                local dropPos = vector3(jobData.dropoffPoint.x, jobData.dropoffPoint.y, jobData.dropoffPoint.z)
                local dropDist = #(coords - dropPos)
                if dropDist < 20.0 then
                    DrawMarker(1, dropPos.x, dropPos.y, dropPos.z - 1.0, 0, 0, 0, 0, 0, 0,
                        1.5, 1.5, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
                    if dropDist < 1.5 then
                        actionText = "Press ~INPUT_CONTEXT~ to drop off box"
                        if IsControlJustPressed(0, 38) then DropOffBox() end
                    end
                end
            end

            -- Single help text per frame to prevent sound spam
            if actionText then
                DisplayHelpText(actionText .. "~n~Press ~r~BACKSPACE~w~ to cancel")
            else
                DisplayHelpText("Press ~r~BACKSPACE~w~ to cancel job")
            end
        else
            Wait(1000)
        end
    end
end)

-- Timer check
CreateThread(function()
    while true do
        if isJobActive then
            local currentTime = GetGameTimer()
            local elapsedTime = math.floor((currentTime - jobData.startTime) / 1000)
            local timeLeft = (Config.JobTimeLimit * 60) - elapsedTime
            if timeLeft <= 0 then
                ShowNotification("~r~Time's up! Job failed.")
                FinishJob(false)
            end
            Wait(5000)
        else
            Wait(10000)
        end
    end
end)

-- NUI
RegisterNUICallback('startJob', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeMenu' })
    TriggerServerEvent('my_warehousejob:startJob')
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeMenu' })
    cb('ok')
end)

-- Server events
RegisterNetEvent('my_warehousejob:playerDataResult')
AddEventHandler('my_warehousejob:playerDataResult', function(data)
    playerData = data
    local maxLevel = 5
    local nextLevelJobs = 0
    if data.level < maxLevel then
        local required = Config.RequiredJobsForLevel[data.level + 1]
        if required then nextLevelJobs = required - data.jobsDone end
    end
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openMenu',
        level = data.level,
        jobsDone = data.jobsDone,
        boxesCarried = data.boxesCarried or 0,
        totalEarnings = data.totalEarnings or 0,
        nextLevelJobs = nextLevelJobs,
        maxLevel = (data.level >= maxLevel),
        dailyJobsCount = data.dailyJobsCount or 0,
        maxDailyJobs = Config.MaxDailyJobs
    })
end)

RegisterNetEvent('my_warehousejob:startJobClient')
AddEventHandler('my_warehousejob:startJobClient', function(totalBoxes, data)
    playerData = data
    isJobActive = true
    StartWarehouseJob(totalBoxes)
end)

RegisterNetEvent('my_warehousejob:startJobDenied')
AddEventHandler('my_warehousejob:startJobDenied', function(data)
    playerData = data
    ShowNotification("~r~You've reached the daily limit of " .. Config.MaxDailyJobs .. " warehouse jobs. Come back tomorrow!")
end)

RegisterNetEvent('my_warehousejob:jobCompleteClient')
AddEventHandler('my_warehousejob:jobCompleteClient', function(payment, leveledUp, updatedData)
    ShowNotification("~g~Warehouse job complete! Earned $" .. payment)
    if leveledUp then
        ShowNotification("~b~Level Up! Now level " .. updatedData.level)
    end
    playerData = updatedData
end)

-- Force cancel job (called on player death)
RegisterNetEvent('my_warehousejob:forceCancel')
AddEventHandler('my_warehousejob:forceCancel', function()
    if not isJobActive then return end
    FinishJob(false)
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if isJobActive then
        if jobData.currentBlip then RemoveBlip(jobData.currentBlip) end
        if jobData.isCarrying and jobData.boxObject then
            ClearPedTasks(PlayerPedId())
            DetachEntity(jobData.boxObject, true, true)
            DeleteEntity(jobData.boxObject)
        end
        CloseJobUI()
    end
    SetNuiFocus(false, false)
end)
