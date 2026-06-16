-- Drug Distributors Client
local managerPed = nil
local managerBlip = nil
local isMenuOpen = false

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

-- Spawn manager NPC
CreateThread(function()
    local hash = GetHashKey(Config.DistributorManager.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local loc = Config.DistributorManager.location
    managerPed = CreatePed(4, hash, loc.x, loc.y, loc.z, Config.DistributorManager.heading, false, true)
    FreezeEntityPosition(managerPed, true)
    SetEntityInvincible(managerPed, true)
    SetBlockingOfNonTemporaryEvents(managerPed, true)
    SetPedCanRagdoll(managerPed, false)
    SetPedCanBeTargetted(managerPed, false)
    SetModelAsNoLongerNeeded(hash)

    -- Blip
    managerBlip = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipSprite(managerBlip, Config.DistributorManager.blip.sprite)
    SetBlipDisplay(managerBlip, Config.DistributorManager.blip.display)
    SetBlipScale(managerBlip, Config.DistributorManager.blip.scale)
    SetBlipColour(managerBlip, Config.DistributorManager.blip.color)
    SetBlipAsShortRange(managerBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.DistributorManager.blip.name)
    EndTextCommandSetBlipName(managerBlip)
end)

-- Main interaction loop
CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = #(playerCoords - Config.DistributorManager.location)

        if distance < 10.0 then
            sleep = 0
            DrawMarker(1, Config.DistributorManager.location.x, Config.DistributorManager.location.y, Config.DistributorManager.location.z - 0.95,
                0, 0, 0, 0, 0, 0, 0.8, 0.8, 0.5, 200, 0, 0, 100, false, true, 2, false, nil, nil, false)

            if distance < Config.InteractionDistance and not isMenuOpen then
                DisplayHelpText("Press ~INPUT_CONTEXT~ to access drug distributor management")
                if IsControlJustPressed(0, Config.InteractionKey) then
                    TriggerServerEvent('my_drugdistributors:requestData')
                end
            end
        end

        if isMenuOpen and (IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177)) then
            CloseMenu()
        end

        Wait(sleep)
    end
end)

-- Close menu when too far
CreateThread(function()
    while true do
        Wait(1000)
        if isMenuOpen then
            local playerCoords = GetEntityCoords(PlayerPedId())
            if #(playerCoords - Config.DistributorManager.location) > Config.InteractionDistance * 2 then
                CloseMenu()
            end
        end
    end
end)

function CloseMenu()
    if not isMenuOpen then return end
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- Server sends data for menu
RegisterNetEvent('my_drugdistributors:openMenu')
AddEventHandler('my_drugdistributors:openMenu', function(data)
    isMenuOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        distributors = data.distributorCount,
        inventory = data.inventory,
        hireCost = Config.DistributorHireCost,
        playerDirtyMoney = data.dirtyMoney,
        sellInterval = Config.DistributorSellInterval / 60000,
        sellAmount = Config.DistributorSellAmount,
        cutPercentage = Config.DistributorCutPercentage
    })
end)

-- Update data while menu is open
RegisterNetEvent('my_drugdistributors:updateData')
AddEventHandler('my_drugdistributors:updateData', function(data)
    if isMenuOpen then
        SendNUIMessage({
            action = 'update',
            distributors = data.distributorCount,
            inventory = data.inventory,
            playerDirtyMoney = data.dirtyMoney,
            hireCost = Config.DistributorHireCost,
            sellInterval = Config.DistributorSellInterval / 60000,
            sellAmount = Config.DistributorSellAmount,
            cutPercentage = Config.DistributorCutPercentage
        })
    end
end)

RegisterNetEvent('my_drugdistributors:showNotification')
AddEventHandler('my_drugdistributors:showNotification', function(msg)
    ShowNotification(msg)
end)

-- NUI Callbacks
RegisterNUICallback('close', function(_, cb)
    CloseMenu()
    cb('ok')
end)

RegisterNUICallback('hireDistributor', function(_, cb)
    TriggerServerEvent('my_drugdistributors:hireDistributor')
    cb('ok')
end)

RegisterNUICallback('fireDistributor', function(_, cb)
    TriggerServerEvent('my_drugdistributors:fireDistributor')
    cb('ok')
end)

RegisterNUICallback('depositDrugs', function(data, cb)
    TriggerServerEvent('my_drugdistributors:depositDrugs', data.drugType, data.amount)
    cb('ok')
end)

RegisterNUICallback('depositAllDrugs', function(_, cb)
    TriggerServerEvent('my_drugdistributors:depositAllDrugs')
    cb('ok')
end)

RegisterNUICallback('withdrawDrugs', function(data, cb)
    TriggerServerEvent('my_drugdistributors:withdrawDrugs', data.drugType, data.amount)
    cb('ok')
end)

RegisterNUICallback('withdrawProfit', function(_, cb)
    TriggerServerEvent('my_drugdistributors:withdrawProfit')
    cb('ok')
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isMenuOpen then CloseMenu() end
        if managerPed and DoesEntityExist(managerPed) then DeleteEntity(managerPed) end
        if managerBlip and DoesBlipExist(managerBlip) then RemoveBlip(managerBlip) end
    end
end)
