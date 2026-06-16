-- Drug Dealer Client (Custom Framework - No ESX)
local dealerPed = nil
local dealerBlip = nil
local isNearDealer = false
local isMenuOpen = false
local dealerLoaded = false
local lastSpawnAttempt = 0

-- Helpers
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

-- Remove dealer and cleanup
local function RemoveDrugDealer()
    if dealerPed and DoesEntityExist(dealerPed) then
        DeleteEntity(dealerPed)
        dealerPed = nil
    end
    if dealerBlip and DoesBlipExist(dealerBlip) then
        RemoveBlip(dealerBlip)
        dealerBlip = nil
    end
    dealerLoaded = false
end

-- Create dealer ped
local function CreateDrugDealer()
    local currentTime = GetGameTimer()
    if (currentTime - lastSpawnAttempt) < 10000 then return end
    lastSpawnAttempt = currentTime

    if dealerPed and DoesEntityExist(dealerPed) then return end

    local modelHash = GetHashKey(Config.DealerModel)
    RequestModel(modelHash)

    local startTime = GetGameTimer()
    while not HasModelLoaded(modelHash) do
        Wait(100)
        if GetGameTimer() - startTime > 10000 then return end
    end

    local x, y, z = Config.DealerLocation.x, Config.DealerLocation.y, Config.DealerLocation.z
    dealerPed = CreatePed(4, modelHash, x, y, z, Config.DealerHeading, false, false)

    if not DoesEntityExist(dealerPed) then
        if Config.Debug then print('[my_drugdealer] Failed to create dealer ped') end
        return
    end

    -- Position correction
    SetEntityCoordsNoOffset(dealerPed, x, y, z - 0.98, true, true, true)

    -- Configure ped
    FreezeEntityPosition(dealerPed, true)
    SetEntityInvincible(dealerPed, true)
    SetBlockingOfNonTemporaryEvents(dealerPed, true)
    SetPedCanRagdoll(dealerPed, false)
    SetPedCanBeTargetted(dealerPed, false)
    SetEntityAsMissionEntity(dealerPed, true, true)

    -- Create blip
    local pedCoords = GetEntityCoords(dealerPed)
    dealerBlip = AddBlipForCoord(pedCoords.x, pedCoords.y, pedCoords.z)
    SetBlipSprite(dealerBlip, Config.DealerBlip.Sprite)
    SetBlipDisplay(dealerBlip, Config.DealerBlip.Display)
    SetBlipScale(dealerBlip, Config.DealerBlip.Scale)
    SetBlipColour(dealerBlip, Config.DealerBlip.Color)
    SetBlipAsShortRange(dealerBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.DealerBlip.Name)
    EndTextCommandSetBlipName(dealerBlip)

    dealerLoaded = true
    SetModelAsNoLongerNeeded(modelHash)

    if Config.Debug then print('[my_drugdealer] Dealer created successfully') end
end

-- Open dealer menu
local function OpenDealerMenu()
    if isMenuOpen then return end
    isMenuOpen = true

    -- Request data from server (server will send back the event to open the NUI)
    TriggerServerEvent('my_drugdealer:requestData')

    -- Play animation
    RequestAnimDict("mp_common")
    local startTime = GetGameTimer()
    while not HasAnimDictLoaded("mp_common") do
        Wait(10)
        if GetGameTimer() - startTime > 5000 then break end
    end
    TaskPlayAnim(PlayerPedId(), "mp_common", "givetake1_a", 8.0, -8.0, -1, 0, 0, false, false, false)
end

-- Close dealer menu
local function CloseDealerMenu()
    isMenuOpen = false
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    ClearPedTasks(PlayerPedId())
end

-- Server sends menu data
RegisterNetEvent('my_drugdealer:openMenu')
AddEventHandler('my_drugdealer:openMenu', function(data)
    SendNUIMessage({
        action = 'open',
        items = data.items,
        playerLevel = data.level,
        playerExp = data.experience,
        maxExp = data.nextLevelXP,
        maxLevel = data.maxLevel,
        dirtyMoney = data.dirtyMoney
    })
    SetNuiFocus(true, true)
end)

-- Server sends updated data after purchase
RegisterNetEvent('my_drugdealer:updateData')
AddEventHandler('my_drugdealer:updateData', function(data)
    if isMenuOpen then
        SendNUIMessage({
            action = 'updateData',
            playerLevel = data.level,
            playerExp = data.experience,
            maxExp = data.nextLevelXP,
            dirtyMoney = data.dirtyMoney
        })
    end
end)

-- Purchase result notification
RegisterNetEvent('my_drugdealer:purchaseResult')
AddEventHandler('my_drugdealer:purchaseResult', function(success, message)
    ShowNotification(message)
end)

-- Level up notification
RegisterNetEvent('my_drugdealer:levelUp')
AddEventHandler('my_drugdealer:levelUp', function(newLevel)
    PlaySoundFrontend(-1, "RANK_UP", "HUD_AWARDS", 1)
    ShowNotification("~p~Drug Dealer Level Up! Now level " .. newLevel)

    if isMenuOpen then
        SendNUIMessage({ action = 'levelUp' })
    end
end)

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    CloseDealerMenu()
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    TriggerServerEvent('my_drugdealer:buyItem', data.name, data.quantity or 1)
    cb('ok')
end)

RegisterNUICallback('buyBulk', function(data, cb)
    TriggerServerEvent('my_drugdealer:buyBulk', data.quantity or 1)
    cb('ok')
end)

-- Spawn dealer on resource start / player spawn
CreateThread(function()
    Wait(5000)
    CreateDrugDealer()
end)

AddEventHandler('playerSpawned', function()
    Wait(3000)
    if not dealerLoaded then
        CreateDrugDealer()
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(5000)
        CreateDrugDealer()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RemoveDrugDealer()
        if isMenuOpen then CloseDealerMenu() end
    end
end)

-- Persistence: keep dealer alive
CreateThread(function()
    while true do
        Wait(30000)
        if NetworkIsPlayerActive(PlayerId()) then
            if not dealerPed or not DoesEntityExist(dealerPed) or IsEntityDead(dealerPed) then
                RemoveDrugDealer()
                Wait(1000)
                CreateDrugDealer()
            end
        end
    end
end)

-- Distance check thread
CreateThread(function()
    while true do
        Wait(1000)
        if dealerLoaded and dealerPed and DoesEntityExist(dealerPed) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dealerCoords = GetEntityCoords(dealerPed)
            isNearDealer = #(playerCoords - dealerCoords) < Config.InteractionDistance
        else
            isNearDealer = false
        end
    end
end)

-- Interaction thread
CreateThread(function()
    while true do
        Wait(0)
        if isNearDealer and not isMenuOpen then
            DisplayHelpText("Press ~INPUT_CONTEXT~ to talk to the dealer")
            if IsControlJustReleased(0, Config.InteractionKey) then
                OpenDealerMenu()
            end
        else
            Wait(500)
        end
    end
end)

-- Close menu if player dies or wanders too far
CreateThread(function()
    while true do
        Wait(1000)
        if isMenuOpen then
            if IsEntityDead(PlayerPedId()) then
                CloseDealerMenu()
            elseif dealerPed and DoesEntityExist(dealerPed) then
                local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(dealerPed))
                if dist > Config.InteractionDistance * 2 then
                    CloseDealerMenu()
                end
            end
        end
    end
end)
