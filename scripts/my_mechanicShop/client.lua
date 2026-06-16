-- my_mechanicShop/client.lua

local isUIOpen = false
local shopPed = nil
local shopBlip = nil

-- ============================================================
-- UTILITY
-- ============================================================

local function getDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

local function showNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

-- ============================================================
-- BLIP
-- ============================================================

local function createBlip()
    local c = Config.NPC.coords
    local blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.label)
    EndTextCommandSetBlipName(blip)
    return blip
end

-- ============================================================
-- NPC
-- ============================================================

local function spawnPed()
    if shopPed and DoesEntityExist(shopPed) then return end

    local c = Config.NPC.coords
    local modelHash = GetHashKey(Config.NPC.model)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then return end

    shopPed = CreatePed(4, modelHash, c.x, c.y, c.z - 1.0, Config.NPC.heading, false, true)
    SetEntityHeading(shopPed, Config.NPC.heading)
    FreezeEntityPosition(shopPed, true)
    SetEntityInvincible(shopPed, true)
    SetBlockingOfNonTemporaryEvents(shopPed, true)
    TaskStartScenarioInPlace(shopPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
    SetModelAsNoLongerNeeded(modelHash)
end

local function deletePed()
    if shopPed and DoesEntityExist(shopPed) then
        SetEntityAsMissionEntity(shopPed, true, true)
        DeleteEntity(shopPed)
    end
    shopPed = nil
end

-- ============================================================
-- NUI HELPERS
-- ============================================================

local function openUI()
    if isUIOpen then return end
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', item = Config.MechanicTools })
end

local function closeUI()
    if not isUIOpen then return end
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ============================================================
-- INTERACTION THREAD
-- ============================================================

CreateThread(function()
    spawnPed()
    shopBlip = createBlip()

    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local px, py, pz = table.unpack(GetEntityCoords(playerPed))
        local c = Config.NPC.coords

        local dist = getDistance(px, py, pz, c.x, c.y, c.z)

        if dist <= Config.InteractionDistance and not IsPedInAnyVehicle(playerPed, false) then
            sleep = 0
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to browse the Mechanic Shop")
            EndTextCommandDisplayHelp(0, false, true, -1)

            if IsControlJustReleased(0, 38) and not isUIOpen then
                openUI()
            end
        end

        Wait(sleep)
    end
end)

-- ============================================================
-- INPUT CONTROL THREAD
-- ============================================================

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
                closeUI()
            end
        else
            Wait(500)
        end
    end
end)

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback('buyTools', function(_, cb)
    TriggerServerEvent('my_mechanicshop:buyTools')
    cb('ok')
end)

RegisterNUICallback('selectHouse', function(data, cb)
    if data and data.houseId then
        TriggerServerEvent('my_mechanicshop:confirmPurchase', data.houseId)
    end
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb('ok')
end)

-- ============================================================
-- SERVER EVENTS
-- ============================================================

RegisterNetEvent('my_mechanicshop:showHouses')
AddEventHandler('my_mechanicshop:showHouses', function(houses)
    SendNUIMessage({ action = 'selectHouse', houses = houses })
end)

RegisterNetEvent('my_mechanicshop:notify')
AddEventHandler('my_mechanicshop:notify', function(success, message)
    if success then
        showNotification("~g~" .. message)
        closeUI()
    else
        showNotification("~r~" .. message)
    end
end)

-- ============================================================
-- CLEANUP
-- ============================================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if shopBlip then RemoveBlip(shopBlip) end
    deletePed()
end)
