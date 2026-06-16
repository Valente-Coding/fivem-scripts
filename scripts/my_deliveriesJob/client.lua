-- Delivery Job Client
local isJobActive = false
local jobData = {
    deliveryPoints = {},
    currentDelivery = 1,
    completedDeliveries = 0,
    startTime = 0,
    currentBlip = nil,
    jobVehicle = nil,
    playerData = nil
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

local function SpawnVehicle(model, coords, heading, cb)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetModelAsNoLongerNeeded(hash)
    if cb then cb(vehicle) end
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

-- Delivery marker management
local currentDeliveryMarker = nil
local isDeliveryMarkerActive = false

local function SetDeliveryMarker(coords)
    currentDeliveryMarker = coords
    isDeliveryMarkerActive = true
end

local function ClearDeliveryMarker()
    currentDeliveryMarker = nil
    isDeliveryMarkerActive = false
end

local function CreateDeliveryBlip(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 162)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, false)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery Point")
    EndTextCommandSetBlipName(blip)
    return blip
end

local function UpdateJobUI()
    if not isJobActive or not jobData.playerData then return end
    local currentTime = GetGameTimer()
    local elapsedTime = math.floor((currentTime - jobData.startTime) / 1000)
    local timeLeft = (Config.JobTimeLimit * 60) - elapsedTime

    if timeLeft <= 0 then
        ShowNotification("~r~Time's up! Job failed.")
        FinishJob(false)
        return
    end

    local minutes = math.floor(timeLeft / 60)
    local seconds = timeLeft % 60
    local timeString = string.format("%02d:%02d", minutes, seconds)

    local nextLevelJobs = 0
    local maxLevel = 5
    if jobData.playerData.level < maxLevel then
        local required = Config.RequiredJobsForLevel[jobData.playerData.level + 1]
        if required then nextLevelJobs = required - jobData.playerData.jobsDone end
    end

    SendNUIMessage({
        type = 'updateUI',
        level = jobData.playerData.level,
        timeLeft = timeString,
        deliveries = jobData.completedDeliveries,
        totalDeliveries = #jobData.deliveryPoints,
        nextLevelJobs = nextLevelJobs,
        maxLevel = (jobData.playerData.level >= maxLevel)
    })
end

local function InitJobUI()
    SendNUIMessage({ type = 'showUI' })
    UpdateJobUI()
    CreateThread(function()
        while isJobActive do
            UpdateJobUI()
            Wait(1000)
        end
    end)
end

local function CloseJobUI()
    SendNUIMessage({ type = 'hideUI' })
end

function DeliverPackage()
    if not isJobActive then return end
    ShowNotification("~g~Delivering package...")
    Wait(1000)
    TriggerServerEvent('my_deliveriesJob:deliveryComplete')
    jobData.completedDeliveries = jobData.completedDeliveries + 1

    ClearDeliveryMarker()
    if jobData.currentBlip then
        RemoveBlip(jobData.currentBlip)
        jobData.currentBlip = nil
    end

    if jobData.completedDeliveries >= #jobData.deliveryPoints then
        FinishJob(true)
    else
        jobData.currentDelivery = jobData.currentDelivery + 1
        local nextPoint = jobData.deliveryPoints[jobData.currentDelivery]
        SetDeliveryMarker(nextPoint)
        jobData.currentBlip = CreateDeliveryBlip(nextPoint)
        UpdateJobUI()
        ShowNotification("~g~Package delivered! Proceed to the next location.")
    end
end

function StartJob(deliveryPoints, playerData)
    if isJobActive then
        ShowNotification("~r~You are already on a delivery job.")
        return
    end

    -- Check if spawn area is clear of players and vehicles within 5m
    local spawnVec = vector3(Config.VehicleSpawnPoint.x, Config.VehicleSpawnPoint.y, Config.VehicleSpawnPoint.z)
    if not IsSpawnAreaClear(spawnVec, 5.0) then
        ShowNotification("~r~Cannot spawn vehicle — area is not clear. Move nearby players or vehicles away.")
        return
    end

    isJobActive = true
    jobData.deliveryPoints = deliveryPoints
    jobData.currentDelivery = 1
    jobData.completedDeliveries = 0
    jobData.startTime = GetGameTimer()
    jobData.playerData = playerData

    SpawnVehicle(Config.VehicleModel, Config.VehicleSpawnPoint, Config.VehicleSpawnPoint.w, function(vehicle)
        jobData.jobVehicle = vehicle
        local plate = GetVehicleNumberPlateText(vehicle)
        ShowNotification("~b~Delivery vehicle spawned. Plate: " .. plate)

        local firstPoint = jobData.deliveryPoints[1]
        SetDeliveryMarker(firstPoint)
        jobData.currentBlip = CreateDeliveryBlip(firstPoint)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        InitJobUI()
    end)
end

function FinishJob(completed)
    if not isJobActive then return end

    ClearDeliveryMarker()
    if jobData.currentBlip then
        RemoveBlip(jobData.currentBlip)
        jobData.currentBlip = nil
    end

    if jobData.jobVehicle and DoesEntityExist(jobData.jobVehicle) then
        DeleteVehicle(jobData.jobVehicle)
        jobData.jobVehicle = nil
    end

    SetEntityCoords(PlayerPedId(), Config.StartPoint.x, Config.StartPoint.y, Config.StartPoint.z)

    if completed then
        TriggerServerEvent('my_deliveriesJob:jobComplete', jobData.completedDeliveries)
    else
        TriggerServerEvent('my_deliveriesJob:cancelJob')
        ShowNotification("~y~Delivery job cancelled.")
        isJobActive = false
        CloseJobUI()
    end
end

-- Open job menu via NUI
local function OpenDeliveryJobMenu(playerData)
    local maxLevel = 5
    local nextLevelJobs = 0
    if playerData.level < maxLevel then
        local required = Config.RequiredJobsForLevel[playerData.level + 1]
        if required then nextLevelJobs = required - playerData.jobsDone end
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openJobMenu',
        level = playerData.level,
        jobsDone = playerData.jobsDone,
        deliveriesDone = playerData.deliveriesDone or 0,
        totalEarnings = playerData.totalEarnings or 0,
        nextLevelJobs = nextLevelJobs,
        maxLevel = (playerData.level >= maxLevel),
        dailyJobsCount = playerData.dailyJobsCount or 0,
        maxDailyJobs = Config.MaxDailyJobs
    })
end

-- Create start blip
CreateThread(function()
    local blip = AddBlipForCoord(Config.StartPoint.x, Config.StartPoint.y, Config.StartPoint.z)
    SetBlipSprite(blip, 280)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery Job")
    EndTextCommandSetBlipName(blip)
end)

-- Start point marker + interaction
CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = #(playerCoords - Config.StartPoint)

        if distance < 10.0 then
            sleep = 0
            DrawMarker(1, Config.StartPoint.x, Config.StartPoint.y, Config.StartPoint.z - 0.95,
                0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.0, 50, 200, 50, 100, false, true, 2, false, nil, nil, false)

            if distance < 1.5 and not isJobActive then
                DisplayHelpText("Press ~INPUT_CONTEXT~ to open Delivery Job menu")
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent('my_deliveriesJob:requestPlayerData')
                end
            end
        end

        Wait(sleep)
    end
end)

-- Delivery marker drawing + interaction
CreateThread(function()
    while true do
        local sleep = 500
        if isJobActive then
            sleep = 0
            if isDeliveryMarkerActive and currentDeliveryMarker then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - currentDeliveryMarker)

                if distance < 50.0 then
                    DrawMarker(1, currentDeliveryMarker.x, currentDeliveryMarker.y, currentDeliveryMarker.z - 0.95,
                        0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.0, 255, 165, 0, 100, false, true, 2, false, nil, nil, false)

                    if distance < 3.0 then
                        if IsPedInAnyVehicle(PlayerPedId(), false) then
                            DisplayHelpText("Press ~INPUT_CONTEXT~ to deliver package~n~Press ~r~BACKSPACE~w~ to cancel")
                            if IsControlJustPressed(0, 38) then DeliverPackage() end
                        else
                            DisplayHelpText("Get in your delivery vehicle~n~Press ~r~BACKSPACE~w~ to cancel")
                        end
                    else
                        DisplayHelpText("Press ~r~BACKSPACE~w~ to cancel delivery")
                    end
                else
                    DisplayHelpText("Press ~r~BACKSPACE~w~ to cancel delivery")
                end
            else
                DisplayHelpText("Press ~r~BACKSPACE~w~ to cancel delivery")
            end
        end
        Wait(sleep)
    end
end)

-- Cancel job loop
CreateThread(function()
    while true do
        if isJobActive then
            if IsControlJustPressed(0, 194) then
                FinishJob(false)
            end
            Wait(0)
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

-- NUI Callbacks
RegisterNUICallback('startJob', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeJobMenu' })
    TriggerServerEvent('my_deliveriesJob:startJob')
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeJobMenu' })
    cb('ok')
end)

-- Server events
RegisterNetEvent('my_deliveriesJob:playerDataResult')
AddEventHandler('my_deliveriesJob:playerDataResult', function(data)
    if data then
        jobData.playerData = data
        OpenDeliveryJobMenu(data)
    else
        ShowNotification("~r~Could not load job data")
    end
end)

RegisterNetEvent('my_deliveriesJob:startJobClient')
AddEventHandler('my_deliveriesJob:startJobClient', function(deliveryPoints, playerData)
    StartJob(deliveryPoints, playerData)
end)

RegisterNetEvent('my_deliveriesJob:startJobDenied')
AddEventHandler('my_deliveriesJob:startJobDenied', function(data)
    jobData.playerData = data
    ShowNotification("~r~You've reached the daily limit of " .. Config.MaxDailyJobs .. " delivery jobs. Come back tomorrow!")
end)

RegisterNetEvent('my_deliveriesJob:jobCompleteClient')
AddEventHandler('my_deliveriesJob:jobCompleteClient', function(payment, leveledUp, updatedData)
    ShowNotification("~g~Job complete! Earned $" .. payment)
    if leveledUp then
        ShowNotification("~b~Level Up! Now level " .. updatedData.level)
    end
    jobData.playerData = updatedData
    isJobActive = false
    CloseJobUI()
end)

-- Force cancel job (called on player death)
RegisterNetEvent('my_deliveriesJob:forceCancel')
AddEventHandler('my_deliveriesJob:forceCancel', function()
    if not isJobActive then return end
    FinishJob(false)
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if isJobActive then
        if jobData.jobVehicle and DoesEntityExist(jobData.jobVehicle) then
            DeleteVehicle(jobData.jobVehicle)
        end
        if jobData.currentBlip then RemoveBlip(jobData.currentBlip) end
        CloseJobUI()
    end
    SetNuiFocus(false, false)
end)
