-- Convenience Store Client
local isShopOpen = false
local shopBlips = {}

-- ── Helpers ──────────────────────────────────────────────────────────────────

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

-- ── Shop open / close ────────────────────────────────────────────────────────

local function OpenShop()
    if isShopOpen then return end
    isShopOpen = true

    local items = {}
    for _, item in ipairs(Config.Items) do
        table.insert(items, {
            name  = item.name,
            label = item.label,
            price = item.price,
        })
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'openShop', items = items })
end

local function CloseShop()
    if not isShopOpen then return end
    isShopOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeShop' })
end

-- ── Blips ────────────────────────────────────────────────────────────────────

CreateThread(function()
    for _, location in ipairs(Config.ShopLocations) do
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blip.name)
        EndTextCommandSetBlipName(blip)
        table.insert(shopBlips, blip)
    end
end)

-- ── Main loop ────────────────────────────────────────────────────────────────

CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed    = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, location in ipairs(Config.ShopLocations) do
            local distance = #(playerCoords - location)

            if distance < Config.MarkerDistance then
                sleep = 0
                DrawMarker(
                    1,
                    location.x, location.y, location.z,
                    0, 0, 0,
                    0, 0, 0,
                    0.5, 0.5, 0.5,
                    30, 180, 30, 120,
                    false, true, 2, false, nil, nil, false
                )

                if distance < Config.InteractDistance and not isShopOpen then
                    DisplayHelpText("Press ~INPUT_CONTEXT~ to browse the Convenience Store")
                    if IsControlJustPressed(0, 38) then -- E
                        OpenShop()
                    end
                end
            end
        end

        -- Close on ESC / Backspace
        if isShopOpen and (IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177)) then
            CloseShop()
        end

        Wait(sleep)
    end
end)

-- ── NUI Callbacks ────────────────────────────────────────────────────────────

RegisterNUICallback('closeShop', function(_, cb)
    CloseShop()
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    TriggerServerEvent('my_conveniencestore:buyItem', data.name)
    cb('ok')
end)

-- ── Server responses ─────────────────────────────────────────────────────────

RegisterNetEvent('my_conveniencestore:purchaseSuccess')
AddEventHandler('my_conveniencestore:purchaseSuccess', function(itemLabel)
    ShowNotification("~g~Purchased " .. itemLabel .. "!")
end)

RegisterNetEvent('my_conveniencestore:purchaseDenied')
AddEventHandler('my_conveniencestore:purchaseDenied', function(reason)
    ShowNotification("~r~" .. reason)
end)

-- ── Item usage (Cleaning Kit & Repair Kit) ──────────────────────────────────

local isCleaning  = false
local isRepairing = false

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    local attempts = 0
    while not HasAnimDictLoaded(dict) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end
    return HasAnimDictLoaded(dict)
end

RegisterNetEvent('my_inventory:onItemUsed')
AddEventHandler('my_inventory:onItemUsed', function(itemName)
    if itemName == 'cleaning_kit' then
        UseCleaningKit()
    elseif itemName == 'repair_kit' then
        UseRepairKit()
    end
end)

-- ── Cleaning Kit ─────────────────────────────────────────────────────────────

function UseCleaningKit()
    if isCleaning then return end

    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) then
        ShowNotification("~r~You must be outside the vehicle!")
        return
    end

    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, 0, 71)

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        ShowNotification("~r~No vehicle found within 5 meters")
        return
    end

    local vehicleCoords = GetEntityCoords(vehicle)
    if #(playerCoords - vehicleCoords) > 5.0 then
        ShowNotification("~r~No vehicle found within 5 meters")
        return
    end

    isCleaning = true
    FreezeEntityPosition(playerPed, true)

    if LoadAnimDict('mini@repair') then
        TaskPlayAnim(playerPed, 'mini@repair', 'fixing_a_ped', 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    ShowNotification("~o~Cleaning vehicle...")
    Wait(5000)

    SetVehicleDirtLevel(vehicle, 0.0)
    WashDecalsFromVehicle(vehicle, 1.0)

    ClearPedTasks(playerPed)
    FreezeEntityPosition(playerPed, false)

    ShowNotification("~g~Vehicle cleaned!")
    isCleaning = false
end

-- ── Repair Kit ───────────────────────────────────────────────────────────────

function UseRepairKit()
    if isRepairing then return end

    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) then
        ShowNotification("~r~You must be outside the vehicle!")
        return
    end

    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, 0, 71)

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        ShowNotification("~r~No vehicle found within 5 meters")
        return
    end

    local vehicleCoords = GetEntityCoords(vehicle)
    if #(playerCoords - vehicleCoords) > 5.0 then
        ShowNotification("~r~No vehicle found within 5 meters")
        return
    end

    if GetVehicleEngineHealth(vehicle) >= 1000.0 and GetVehicleBodyHealth(vehicle) >= 1000.0 then
        ShowNotification("~g~Vehicle is already in perfect condition")
        return
    end

    isRepairing = true
    FreezeEntityPosition(playerPed, true)

    TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_BUM_BIN', 0, true)

    ShowNotification("~o~Repairing vehicle... (5s)")
    Wait(5000)

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)

    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, false)

    ShowNotification("~g~Vehicle repaired!")
    isRepairing = false
end

-- ── Cleanup ──────────────────────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isShopOpen then CloseShop() end
        for _, blip in pairs(shopBlips) do
            RemoveBlip(blip)
        end
    end
end)
