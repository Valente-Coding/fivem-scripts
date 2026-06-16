-- Trucking Job Client
local isJobActive = false
local playerData = nil
local activeTruck = nil
local activeTrailer = nil
local activeBlip = nil

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

local function SpawnVehicle(model, coords, heading, cb)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetModelAsNoLongerNeeded(hash)
    if cb then cb(vehicle) end
end

local function OpenTruckingJobMenu()
    TriggerServerEvent('my_truckingjob:requestPlayerData')
end

local function DisplayMenu(data)
    playerData = data
    local maxLevel = 5
    local isMax = data.level >= maxLevel
    local nextLevelJobs = 0
    if not isMax then
        local nextLevelData = Config.Levels[data.level + 1]
        if nextLevelData then
            nextLevelJobs = nextLevelData.jobsRequired - data.jobsDone
            if nextLevelJobs < 0 then nextLevelJobs = 0 end
        end
    end
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openMenu',
        level = data.level,
        jobsDone = data.jobsDone,
        deliveriesDone = data.jobsDone,
        totalEarnings = data.totalEarnings,
        nextLevelJobs = nextLevelJobs,
        maxLevel = isMax,
        dailyJobsCount = data.dailyJobsCount or 0,
        maxDailyJobs = Config.MaxDailyJobs
    })
end

-- Blips
CreateThread(function()
    local blip = AddBlipForCoord(Config.JobMenuCoord.x, Config.JobMenuCoord.y, Config.JobMenuCoord.z)
    SetBlipSprite(blip, 477)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Trucking Job")
    EndTextCommandSetBlipName(blip)
end)

-- Menu marker
CreateThread(function()
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())
        local dist = #(coords - Config.JobMenuCoord)

        if dist < 20.0 then
            sleep = 0
            DrawMarker(1, Config.JobMenuCoord.x, Config.JobMenuCoord.y, Config.JobMenuCoord.z - 1.0,
                0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.0, 0, 150, 255, 100, false, true, 2, false, nil, nil, false)

            if dist < 2.0 and not isJobActive then
                DisplayHelpText("Press ~INPUT_CONTEXT~ to open Trucking Job menu")
                if IsControlJustPressed(0, 38) then
                    OpenTruckingJobMenu()
                end
            end
        end

        Wait(sleep)
    end
end)

-- NUI callbacks
RegisterNUICallback('startJob', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeMenu' })
    TriggerServerEvent('my_truckingjob:requestStartJob')
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeMenu' })
    cb('ok')
end)

-- Server responses
RegisterNetEvent('my_truckingjob:playerDataResult')
AddEventHandler('my_truckingjob:playerDataResult', function(data)
    DisplayMenu(data)
end)

RegisterNetEvent('my_truckingjob:setPlayerData')
AddEventHandler('my_truckingjob:setPlayerData', function(data)
    playerData = data
end)

RegisterNetEvent('my_truckingjob:startJobResult')
AddEventHandler('my_truckingjob:startJobResult', function(allowed, data)
    playerData = data
    if not allowed then
        ShowNotification("~r~You've reached the daily limit of " .. Config.MaxDailyJobs .. " trucking jobs. Come back tomorrow!")
        return
    end
    isJobActive = true
    StartTruckingJob()
end)

RegisterNetEvent('my_truckingjob:jobCompleteClient')
AddEventHandler('my_truckingjob:jobCompleteClient', function(payment, leveledUp, updatedData)
    ShowNotification("~g~Delivery complete! Earned $" .. payment)
    if leveledUp then
        ShowNotification("~b~Level Up! Now level " .. updatedData.level)
    end
    playerData = updatedData
end)

function StartTruckingJob()
    -- Check if spawn area is clear of players and vehicles within 5m
    local spawnVec = vector3(Config.TruckSpawnCoord.x, Config.TruckSpawnCoord.y, Config.TruckSpawnCoord.z)
    if not IsSpawnAreaClear(spawnVec, 5.0) then
        ShowNotification("~r~Cannot spawn truck — area is not clear. Move nearby players or vehicles away.")
        isJobActive = false
        return
    end

    local delivery = Config.DeliveryCoords[math.random(#Config.DeliveryCoords)]

    SpawnVehicle('phantom', Config.TruckSpawnCoord, Config.TruckSpawnCoord.w, function(truck)
        SpawnVehicle('trailers2', Config.TruckSpawnCoord, Config.TruckSpawnCoord.w, function(trailer)
            AttachVehicleToTrailer(truck, trailer, 1.0)
            TaskWarpPedIntoVehicle(PlayerPedId(), truck, -1)

            ShowNotification("~b~Truck spawned! Follow the GPS to the delivery point.")

            activeTruck = truck
            activeTrailer = trailer

            local blip = AddBlipForCoord(delivery.x, delivery.y, delivery.z)
            activeBlip = blip
            SetBlipSprite(blip, 162)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.8)
            SetBlipColour(blip, 5)
            SetBlipAsShortRange(blip, false)
            SetBlipRoute(blip, true)
            SetBlipRouteColour(blip, 5)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Delivery Point")
            EndTextCommandSetBlipName(blip)

            local jobStartTime = GetGameTimer()
            InitJobUI(jobStartTime)
            WaitForDelivery(truck, trailer, delivery, blip, jobStartTime)
        end)
    end)
end

function InitJobUI(startTime)
    SendNUIMessage({ type = 'showHUD' })
    CreateThread(function()
        while isJobActive do
            UpdateJobUI(startTime)
            Wait(1000)
        end
    end)
end

function UpdateJobUI(startTime)
    if not isJobActive then return end
    local currentTime = GetGameTimer()
    local elapsedTime = math.floor((currentTime - startTime) / 1000)
    local timeLeft = (Config.JobTimeLimit * 60) - elapsedTime

    if timeLeft <= 0 then return end

    local minutes = math.floor(timeLeft / 60)
    local seconds = timeLeft % 60
    local timeString = string.format("%02d:%02d", minutes, seconds)
    local maxLevel = 5
    local level = playerData and playerData.level or 1
    local isMax = level >= maxLevel
    local nextLevelJobs = 0
    if not isMax and playerData then
        local nextLevelData = Config.Levels[level + 1]
        if nextLevelData then
            nextLevelJobs = nextLevelData.jobsRequired - playerData.jobsDone
            if nextLevelJobs < 0 then nextLevelJobs = 0 end
        end
    end

    SendNUIMessage({
        type = 'updateHUD',
        level = level,
        maxLevel = isMax,
        timeLeft = timeString,
        nextLevelJobs = nextLevelJobs
    })
end

function CloseJobUI()
    SendNUIMessage({ type = 'hideHUD' })
end

function WaitForDelivery(truck, trailer, delivery, blip, jobStartTime)
    local delivered = false
    local wasInVehicle = true
    local hasArrivedNotification = false

    -- Cancel thread
    CreateThread(function()
        while not delivered and isJobActive do
            Wait(0)
            if IsControlJustPressed(0, 194) then
                isJobActive = false
                if DoesEntityExist(truck) then DeleteVehicle(truck) end
                if DoesEntityExist(trailer) then DeleteVehicle(trailer) end
                RemoveBlip(blip)
                ShowNotification("~y~Delivery canceled!")
                SetEntityCoords(PlayerPedId(), Config.JobMenuCoord.x, Config.JobMenuCoord.y, Config.JobMenuCoord.z)
                CloseJobUI()
                break
            end
        end
    end)

    -- Delivery marker draw + help text
    CreateThread(function()
        while not delivered and isJobActive do
            Wait(0)
            DrawMarker(1, delivery.x, delivery.y, delivery.z - 1.0,
                0, 0, 0, 0, 0, 0, 5.0, 5.0, 1.0, 0, 255, 0, 100, false, true, 2, false, nil, nil, false)

            local truckDist = #(GetEntityCoords(truck) - delivery)
            local trailerDist = #(GetEntityCoords(trailer) - delivery)
            if truckDist < 8.0 and trailerDist < 8.0 and IsPedInVehicle(PlayerPedId(), truck, false) then
                DisplayHelpText("~g~Exit the truck~s~ to complete delivery~n~Press ~r~BACKSPACE~w~ to cancel")
            else
                DisplayHelpText("Press ~r~BACKSPACE~w~ to cancel delivery")
            end
        end
    end)

    -- Main delivery logic
    CreateThread(function()
        while not delivered and isJobActive do
            Wait(100)

            if not DoesEntityExist(truck) or not DoesEntityExist(trailer) then
                isJobActive = false
                ShowNotification("~r~Job failed. Vehicle was destroyed!")
                RemoveBlip(blip)
                if DoesEntityExist(truck) then DeleteVehicle(truck) end
                if DoesEntityExist(trailer) then DeleteVehicle(trailer) end
                SetEntityCoords(PlayerPedId(), Config.JobMenuCoord.x, Config.JobMenuCoord.y, Config.JobMenuCoord.z)
                CloseJobUI()
                break
            end

            -- Timer check
            local currentTime = GetGameTimer()
            local elapsedTime = math.floor((currentTime - jobStartTime) / 1000)
            local timeLeft = (Config.JobTimeLimit * 60) - elapsedTime
            if timeLeft <= 0 then
                isJobActive = false
                ShowNotification("~r~Time's up! Job failed.")
                RemoveBlip(blip)
                DeleteVehicle(truck)
                DeleteVehicle(trailer)
                SetEntityCoords(PlayerPedId(), Config.JobMenuCoord.x, Config.JobMenuCoord.y, Config.JobMenuCoord.z)
                CloseJobUI()
                break
            end

            local coords = GetEntityCoords(PlayerPedId())
            local truckCoords = GetEntityCoords(truck)
            local trailerCoords = GetEntityCoords(trailer)
            local isInVehicle = IsPedInVehicle(PlayerPedId(), truck, false)

            -- Trailer detach warning
            if not IsVehicleAttachedToTrailer(truck) then
                ShowNotification("~y~Reconnect your trailer!")
                Wait(5000)
            end

            -- Delivery zone check
            if #(truckCoords - delivery) < 8.0 and #(trailerCoords - delivery) < 8.0 then
                if isInVehicle then
                    if not hasArrivedNotification then
                        ShowNotification("~b~You've arrived! Exit the vehicle to complete the delivery.")
                        hasArrivedNotification = true
                    end
                end

                if wasInVehicle and not isInVehicle then
                    delivered = true
                    isJobActive = false
                    RemoveBlip(blip)

                    TriggerServerEvent('my_truckingjob:jobCompleted')
                    CloseJobUI()
                    Wait(500)
                    DeleteVehicle(truck)
                    DeleteVehicle(trailer)
                    SetEntityCoords(PlayerPedId(), Config.JobMenuCoord.x, Config.JobMenuCoord.y, Config.JobMenuCoord.z)
                    break
                end
            end

            wasInVehicle = isInVehicle
        end
    end)
end

-- Force cancel job (called on player death)
RegisterNetEvent('my_truckingjob:forceCancel')
AddEventHandler('my_truckingjob:forceCancel', function()
    if not isJobActive then return end
    isJobActive = false
    if activeTruck and DoesEntityExist(activeTruck) then DeleteVehicle(activeTruck) end
    if activeTrailer and DoesEntityExist(activeTrailer) then DeleteVehicle(activeTrailer) end
    if activeBlip then RemoveBlip(activeBlip) end
    activeTruck = nil
    activeTrailer = nil
    activeBlip = nil
    CloseJobUI()
    SetNuiFocus(false, false)
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if activeTruck and DoesEntityExist(activeTruck) then DeleteVehicle(activeTruck) end
        if activeTrailer and DoesEntityExist(activeTrailer) then DeleteVehicle(activeTrailer) end
        if activeBlip then RemoveBlip(activeBlip) end
        activeTruck = nil
        activeTrailer = nil
        activeBlip = nil
        isJobActive = false
        CloseJobUI()
        SetNuiFocus(false, false)
    end
end)
