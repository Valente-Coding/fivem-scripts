-- Fishing Client
local isFishing = false
local fishingBlips = {}
local sessionFishCaught = 0
local sessionMoneyEarned = 0
local fishingRodEntity = nil

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

-- Create blips
CreateThread(function()
    for _, spot in ipairs(Config.FishingSpot) do
        local blip = AddBlipForCoord(spot.coords)
        SetBlipSprite(blip, 68)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Fishing Spot")
        EndTextCommandSetBlipName(blip)
        table.insert(fishingBlips, blip)
    end
end)

local function ShowFishingUI()
    TriggerServerEvent('my_fishing:requestStats')
end

local function HideFishingUI()
    SendNUIMessage({ type = "hideUI" })
    sessionFishCaught = 0
    sessionMoneyEarned = 0
end

local function UpdateFishingUI(amount)
    sessionFishCaught = sessionFishCaught + 1
    sessionMoneyEarned = sessionMoneyEarned + amount
    TriggerServerEvent('my_fishing:requestStats')
    SendNUIMessage({ type = "showLastCatch", amount = amount })
end

-- Receive stats from server
RegisterNetEvent('my_fishing:receiveStats')
AddEventHandler('my_fishing:receiveStats', function(stats)
    SendNUIMessage({
        type = "showUI",
        stats = {
            sessionCaught = sessionFishCaught,
            sessionEarned = sessionMoneyEarned,
            totalCaught = stats.fishCaught or 0,
            totalEarned = stats.moneyEarned or 0
        }
    })
end)

local function StopFishing()
    if not isFishing then return end
    isFishing = false

    ClearPedTasks(PlayerPedId())

    -- Remove fishing rod prop
    if fishingRodEntity and DoesEntityExist(fishingRodEntity) then
        DeleteEntity(fishingRodEntity)
        fishingRodEntity = nil
    end

    -- Also try to find and remove
    local rodHash = GetHashKey('prop_fishing_rod_01')
    local rod = GetClosestObjectOfType(GetEntityCoords(PlayerPedId()), 2.0, rodHash, false, false, false)
    if rod ~= 0 then DeleteEntity(rod) end

    ShowNotification("~o~You stopped fishing")
    HideFishingUI()
end

local function StartFishing()
    if isFishing then return end

    -- Check license via server
    TriggerServerEvent('my_fishing:checkLicense')
end

-- License check result
RegisterNetEvent('my_fishing:licenseResult')
AddEventHandler('my_fishing:licenseResult', function(hasLicense)
    if not hasLicense then
        ShowNotification("~r~You need a fishing license! Visit the License Center.")
        SetNewWaypoint(Config.LicenseCenterLocation.x, Config.LicenseCenterLocation.y)
        ShowNotification("~y~Waypoint set to License Center")
        return
    end

    isFishing = true
    local playerPed = PlayerPedId()

    -- Load animation
    RequestAnimDict('amb@world_human_stand_fishing@idle_a')
    local attempts = 0
    while not HasAnimDictLoaded('amb@world_human_stand_fishing@idle_a') and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end

    -- Load fishing rod prop
    local rodHash = GetHashKey('prop_fishing_rod_01')
    RequestModel(rodHash)
    attempts = 0
    while not HasModelLoaded(rodHash) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end

    fishingRodEntity = CreateObject(rodHash, 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(fishingRodEntity, playerPed, GetPedBoneIndex(playerPed, 18905),
        0.1, 0.05, 0, 80.0, 120.0, 160.0, true, true, false, true, 1, true)

    TaskPlayAnim(playerPed, 'amb@world_human_stand_fishing@idle_a', 'idle_c', 8.0, -8.0, -1, 1, 0, false, false, false)

    ShowNotification("~g~You started fishing!")
    ShowFishingUI()

    -- Fishing loop
    CreateThread(function()
        while isFishing do
            Wait(Config.FishingTime)
            if isFishing then
                TriggerServerEvent('my_fishing:catchFish')
            end
        end
    end)
end)

-- Catch result from server
RegisterNetEvent('my_fishing:catchResult')
AddEventHandler('my_fishing:catchResult', function(amount, isRare)
    if isRare then
        ShowNotification("~p~Wow! Rare catch worth $" .. amount .. "!")
    else
        ShowNotification("~g~You caught a fish worth $" .. amount)
    end
    UpdateFishingUI(amount)
end)

-- Main loop
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, spot in ipairs(Config.FishingSpot) do
            local distance = #(playerCoords - spot.coords)

            if distance < 20.0 then
                sleep = 0
                DrawMarker(1, spot.coords.x, spot.coords.y, spot.coords.z - 1.0,
                    0, 0, 0, 0, 0, 0, 2.0, 2.0, 0.5,
                    0, 255, 255, 100,
                    false, true, 2, false, nil, nil, false)

                if distance < spot.radius then
                    if not isFishing then
                        DisplayHelpText(spot.label)
                        if IsControlJustReleased(0, 38) then
                            StartFishing()
                        end
                    else
                        DisplayHelpText("Press ~INPUT_CONTEXT~ to stop fishing")
                        if IsControlJustReleased(0, 38) then
                            StopFishing()
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Stats command
RegisterCommand('fishingstats', function()
    TriggerServerEvent('my_fishing:requestStats')
end, false)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isFishing then StopFishing() end
        for _, blip in pairs(fishingBlips) do RemoveBlip(blip) end
    end
end)
