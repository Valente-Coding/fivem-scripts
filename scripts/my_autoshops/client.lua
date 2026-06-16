-- Auto Repair Shop Client

local isUIOpen = false
local currentVehicle = nil
local inRepairZone = false
local hasNotified = false
local repairBlips = {}
local nearestShopIndex = nil
local shopVehicleData = {}
local pickupChecked = false

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

-- Create blips for repair shops
CreateThread(function()
    for _, location in ipairs(Config.RepairLocations) do
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, 446)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 47)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Auto Repair Shop")
        EndTextCommandSetBlipName(blip)
        table.insert(repairBlips, blip)
    end
end)

-- Helpers
local function Plate(v)
    return string.upper(string.gsub(GetVehicleNumberPlateText(v), '%s+', ''))
end

local function GetOilLevel(plate)
    local ok, val = pcall(function() return exports['my_vehicles']:GetVehicleOilLevel(plate) end)
    if ok and val then return val end
    return 100.0
end

local function FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%d:%02d", m, s)
end

-- Open repair menu
local function OpenRepairMenu()
    if not currentVehicle or not DoesEntityExist(currentVehicle) then return end

    isUIOpen = true
    local engineDamage = 1000 - GetVehicleEngineHealth(currentVehicle)
    local bodyDamage = 1000 - GetVehicleBodyHealth(currentVehicle)
    local totalDamage = (engineDamage + bodyDamage) / 20
    local repairPrice = math.floor(Config.RepairPrice * (0.5 + totalDamage / 100))
    local taxAmount = math.floor(repairPrice * (Config.SalesTax / 100))
    local totalPrice = repairPrice + taxAmount

    local plate = Plate(currentVehicle)
    local oilLevel = math.floor(GetOilLevel(plate))
    local oilTax = math.floor(Config.OilChangePrice * (Config.SalesTax / 100))
    local oilTotal = Config.OilChangePrice + oilTax
    local oilDepleted = (oilLevel <= 0)

    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openRepair",
        price = totalPrice,
        damage = math.floor(totalDamage),
        tax = taxAmount,
        oilLevel = oilLevel,
        oilPrice = oilTotal,
        oilTax = oilTax,
        needsRepair = (engineDamage > 0 or bodyDamage > 0),
        oilDepleted = oilDepleted,
        dropOffPrice = Config.DropOffPrice,
        dropOffTime = Config.DropOffTime
    })
end

-- Close UI
local function CloseUI()
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "closeUI" })
end

-- Repair the vehicle
local function RepairVehicle()
    if not currentVehicle or not DoesEntityExist(currentVehicle) then return end

    SetVehicleFixed(currentVehicle)
    SetVehicleDeformationFixed(currentVehicle)
    SetVehicleUndriveable(currentVehicle, false)
    SetVehicleEngineOn(currentVehicle, true, true)

    -- Auto-refill oil on repair
    local plate = string.upper(string.gsub(GetVehicleNumberPlateText(currentVehicle), '%s+', ''))
    pcall(function()
        exports['my_vehicles']:SetVehicleOilLevel(plate, 100.0)
        TriggerServerEvent('my_vehicles:updateOilLevel', plate, 100.0)
    end)

    ShowNotification("~g~Your vehicle has been repaired and oil topped off!")
end

-- Key mapping for interaction
RegisterCommand('repairshop_interact', function()
    if inRepairZone and not isUIOpen then
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local engineHealth = GetVehicleEngineHealth(vehicle)
            local bodyHealth = GetVehicleBodyHealth(vehicle)
            local plate = Plate(vehicle)
            local oilLevel = GetOilLevel(plate)
            if engineHealth < 1000.0 or bodyHealth < 1000.0 or oilLevel < 100.0 then
                currentVehicle = vehicle
                OpenRepairMenu()
            else
                ShowNotification("~g~Your vehicle is already in perfect condition")
            end
        elseif nearestShopIndex then
            -- On foot at a shop — try to pick up a vehicle
            local foundPlate = nil
            local foundReady = false
            local foundRemaining = 0
            for plate, data in pairs(shopVehicleData) do
                if data.shopIndex == nearestShopIndex then
                    foundPlate = plate
                    local remaining = math.max(0, math.floor((data.readyGameTime - GetGameTimer()) / 1000))
                    if data.ready or remaining <= 0 then
                        foundReady = true
                    else
                        foundRemaining = remaining
                    end
                    break
                end
            end

            if foundPlate and foundReady then
                TriggerServerEvent('my_autoshops:requestPickup', foundPlate)
            elseif foundPlate then
                ShowNotification("~o~Vehicle not ready yet (" .. FormatTime(foundRemaining) .. " remaining)")
            else
                ShowNotification("~r~No vehicles being repaired at this shop")
            end
        else
            ShowNotification("~r~You need to be in a vehicle")
        end
    end
end)
RegisterKeyMapping('repairshop_interact', 'Interact with auto repair shop', 'keyboard', 'E')

-- Main loop
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local wasInRepairZone = inRepairZone
        inRepairZone = false
        nearestShopIndex = nil

        for i, location in ipairs(Config.RepairLocations) do
            local distance = #(playerCoords - location.coords)

            if distance < Config.DrawDistance then
                sleep = 0
                DrawMarker(1, location.coords.x, location.coords.y, location.coords.z - 1.0,
                    0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.0, 50, 200, 255, 100,
                    false, false, 2, false, nil, nil, false)

                if distance < Config.InteractionDistance then
                    inRepairZone = true
                    nearestShopIndex = i

                    if IsPedInAnyVehicle(playerPed, false) then
                        if not hasNotified then
                            local vehicle = GetVehiclePedIsIn(playerPed, false)
                            if GetVehicleEngineHealth(vehicle) < 1000.0 or GetVehicleBodyHealth(vehicle) < 1000.0 then
                                DisplayHelpText("Press ~INPUT_CONTEXT~ to repair your vehicle")
                            end
                            hasNotified = true
                        end
                    else
                        -- On foot — check for vehicles in this shop
                        if not pickupChecked then
                            TriggerServerEvent('my_autoshops:getMyShopVehicles')
                            pickupChecked = true
                        end

                        -- Show help text based on cached data
                        for plate, data in pairs(shopVehicleData) do
                            if data.shopIndex == i then
                                local remaining = math.max(0, math.floor((data.readyGameTime - GetGameTimer()) / 1000))
                                if data.ready or remaining <= 0 then
                                    DisplayHelpText("Press ~INPUT_CONTEXT~ to pick up your vehicle")
                                else
                                    DisplayHelpText("Vehicle being repaired (" .. FormatTime(remaining) .. " remaining)")
                                end
                                break
                            end
                        end
                    end
                end
            end
        end

        if wasInRepairZone and not inRepairZone then
            hasNotified = false
            pickupChecked = false
            if isUIOpen then CloseUI() end
        end

        -- ESC to close
        if isUIOpen and (IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177)) then
            CloseUI()
        end

        Wait(sleep)
    end
end)

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('repairVehicle', function(data, cb)
    CloseUI()

    if not currentVehicle or not DoesEntityExist(currentVehicle) then
        cb('ok')
        return
    end

    local engineDamage = 1000 - GetVehicleEngineHealth(currentVehicle)
    local bodyDamage = 1000 - GetVehicleBodyHealth(currentVehicle)
    local totalDamage = (engineDamage + bodyDamage) / 20
    local repairPrice = math.floor(Config.RepairPrice * (0.5 + totalDamage / 100))
    local taxAmount = math.floor(repairPrice * (Config.SalesTax / 100))
    local totalPrice = repairPrice + taxAmount

    TriggerServerEvent('my_autoshops:payForRepair', totalPrice)
    cb('ok')
end)

RegisterNUICallback('oilChange', function(data, cb)
    CloseUI()

    if not currentVehicle or not DoesEntityExist(currentVehicle) then
        cb('ok')
        return
    end

    local plate = Plate(currentVehicle)
    TriggerServerEvent('my_autoshops:payForOilChange', plate)
    cb('ok')
end)

RegisterNUICallback('dropOffVehicle', function(data, cb)
    CloseUI()

    if not currentVehicle or not DoesEntityExist(currentVehicle) then
        cb('ok')
        return
    end
    if not nearestShopIndex then
        cb('ok')
        return
    end

    local plate = Plate(currentVehicle)
    TriggerServerEvent('my_autoshops:dropOffVehicle', plate, nearestShopIndex)
    cb('ok')
end)

-- Server responses
RegisterNetEvent('my_autoshops:repairApproved')
AddEventHandler('my_autoshops:repairApproved', function()
    RepairVehicle()
end)

RegisterNetEvent('my_autoshops:repairDenied')
AddEventHandler('my_autoshops:repairDenied', function()
    ShowNotification("~r~You don't have enough money for repairs")
end)

RegisterNetEvent('my_autoshops:oilChangeApproved')
AddEventHandler('my_autoshops:oilChangeApproved', function(plate)
    plate = string.upper(string.gsub(plate, '%s+', ''))
    pcall(function()
        exports['my_vehicles']:SetVehicleOilLevel(plate, 100.0)
        TriggerServerEvent('my_vehicles:updateOilLevel', plate, 100.0)
    end)

    ShowNotification("~g~Oil changed! Oil level is now 100%")
end)

RegisterNetEvent('my_autoshops:oilChangeDenied')
AddEventHandler('my_autoshops:oilChangeDenied', function(reason)
    ShowNotification("~r~" .. (reason or "Cannot perform oil change"))
end)

-- Drop-off responses
RegisterNetEvent('my_autoshops:dropOffApproved')
AddEventHandler('my_autoshops:dropOffApproved', function(plate, shopIndex, readyInSeconds)
    ShowNotification("~g~Vehicle left for repair. Come back in " .. math.ceil(readyInSeconds / 60) .. " minutes.")

    shopVehicleData[plate] = {
        shopIndex = shopIndex,
        readyGameTime = GetGameTimer() + (readyInSeconds * 1000),
        ready = false
    }

    -- Warp player out and delete the vehicle entity
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        TaskLeaveVehicle(ped, veh, 16)

        CreateThread(function()
            Wait(1000)
            if veh and DoesEntityExist(veh) then
                SetEntityAsMissionEntity(veh, true, true)
                DeleteVehicle(veh)
            end
        end)
    end
end)

RegisterNetEvent('my_autoshops:dropOffDenied')
AddEventHandler('my_autoshops:dropOffDenied', function(reason)
    ShowNotification("~r~" .. (reason or "Cannot drop off vehicle"))
end)

RegisterNetEvent('my_autoshops:pickupApproved')
AddEventHandler('my_autoshops:pickupApproved', function(plate)
    plate = string.upper(string.gsub(plate, '%s+', ''))
    shopVehicleData[plate] = nil
    pickupChecked = false
    ShowNotification("~g~Your vehicle has been repaired and is ready!")
end)

RegisterNetEvent('my_autoshops:pickupDenied')
AddEventHandler('my_autoshops:pickupDenied', function(reason)
    ShowNotification("~r~" .. (reason or "Cannot pick up vehicle"))
end)

RegisterNetEvent('my_autoshops:shopVehiclesList')
AddEventHandler('my_autoshops:shopVehiclesList', function(vehicles)
    shopVehicleData = {}
    if not vehicles then return end
    local now = GetGameTimer()
    for _, v in ipairs(vehicles) do
        shopVehicleData[v.plate] = {
            shopIndex = v.shopIndex,
            readyGameTime = now + (v.remaining * 1000),
            ready = v.ready or false
        }
    end
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isUIOpen then CloseUI() end
        for _, blip in pairs(repairBlips) do RemoveBlip(blip) end
    end
end)
