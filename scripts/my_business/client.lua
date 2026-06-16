-- Business Management Client

local Businesses = {}
local MyInstances = {} -- { businessName = { money, dirty_money, staff_level, ... } }
local isBusinessMenuOpen = false
local businessOverviewOpen = false
local blips = {}
local currentBusinessName = nil

-- ========================================
-- HELPERS
-- ========================================

local function ShowNotification(message)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, true)
end

local function DisplayHelpText(text)
    AddTextEntry('BUSINESS_HELP', text)
    DisplayHelpTextThisFrame('BUSINESS_HELP', false)
end

local function GroupDigits(amount)
    local formatted = tostring(math.floor(amount))
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Round to nearest multiple of 5
local function RoundToFive(n)
    return math.floor(n / 5 + 0.5) * 5
end

-- Calculate business income (client-side for UI display)
local function CalculateBusinessIncome(business, instance)
    local staffBonus = (instance.staff_level or 0) * Config.StaffIncomeBonus
    local sizeBonus = (instance.size_level or 0) * Config.SizeIncomeBonus
    local logisticsBonus = (instance.logistics_level or 0) * Config.LogisticsIncomeBonus
    local securityBonus = (instance.security_level or 0) * Config.SecurityIncomeBonus

    local totalMultiplier = Config.BaseIncomeMultiplier + staffBonus + sizeBonus + logisticsBonus + securityBonus
    local normalIncome = RoundToFive(math.floor(business.price * totalMultiplier))

    local income = normalIncome
    local boostedIncome = false
    local nextPayoutInfo = ""

    if instance.dirty_money and instance.dirty_money > 0 then
        local maxAdditionalIncome = RoundToFive(math.floor(normalIncome * 0.5))
        local additionalIncome = math.min(instance.dirty_money, maxAdditionalIncome)
        income = normalIncome + additionalIncome
        boostedIncome = true

        local boostPayouts = math.floor(instance.dirty_money / maxAdditionalIncome)
        local remainderAmount = instance.dirty_money % maxAdditionalIncome

        if remainderAmount > 0 then
            nextPayoutInfo = string.format("Next %d payments: $%s, Final: $%s",
                boostPayouts, GroupDigits(normalIncome + maxAdditionalIncome),
                GroupDigits(normalIncome + remainderAmount))
        else
            nextPayoutInfo = string.format("Next %d payments: $%s",
                boostPayouts, GroupDigits(normalIncome + maxAdditionalIncome))
        end
    end

    return income, boostedIncome, nextPayoutInfo, normalIncome
end

-- Get upgrade info for UI
local function GetBusinessUpgradeInfo(business, instance)
    return {
        staff = {
            level = instance.staff_level or 0,
            maxLevel = Config.MaxStaffLevel,
            cost = math.floor(business.price * Config.UpgradeCostMultiplier.staff),
            bonus = Config.StaffIncomeBonus * 100
        },
        size = {
            level = instance.size_level or 0,
            maxLevel = Config.MaxSizeLevel,
            cost = math.floor(business.price * Config.UpgradeCostMultiplier.size),
            bonus = Config.SizeIncomeBonus * 100
        },
        logistics = {
            level = instance.logistics_level or 0,
            maxLevel = Config.MaxLogisticsLevel,
            cost = math.floor(business.price * Config.UpgradeCostMultiplier.logistics),
            bonus = Config.LogisticsIncomeBonus * 100
        },
        security = {
            level = instance.security_level or 0,
            maxLevel = Config.MaxSecurityLevel,
            cost = math.floor(business.price * Config.UpgradeCostMultiplier.security),
            bonus = Config.SecurityIncomeBonus * 100
        }
    }
end

-- ========================================
-- INITIALIZATION
-- ========================================

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('my_business:requestData')
end)

-- ========================================
-- DATA SYNC
-- ========================================

RegisterNetEvent('my_business:syncData')
AddEventHandler('my_business:syncData', function(businesses, myInstances)
    Businesses = businesses or {}
    MyInstances = myInstances or {}
    CreateBlips()

    -- Refresh open menu if near a business (skip warehouse - it handles its own flow)
    if isBusinessMenuOpen and currentBusinessName and not businessOverviewOpen then
        local savedBusinessName = currentBusinessName
        local business = Businesses[savedBusinessName]
        if business and business.type ~= "warehouse" then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - vector3(business.coords.x, business.coords.y, business.coords.z))
            if distance < 5.0 then
                CloseBusinessMenu()
                Wait(100)
                OpenBusinessMenu(savedBusinessName)
            else
                CloseBusinessMenu()
            end
        end
    end
end)

-- ========================================
-- BLIPS
-- ========================================

function CreateBlips()
    for _, blip in pairs(blips) do
        RemoveBlip(blip)
    end
    blips = {}

    for name, business in pairs(Businesses) do
        local blipConfig
        local playerOwnsThis = MyInstances[name] ~= nil

        if business.type == "warehouse" then
            blipConfig = Config.WarehouseBlip
        elseif playerOwnsThis then
            blipConfig = Config.OwnedBusinessBlip
        else
            blipConfig = Config.BusinessBlip
        end

        local blip = AddBlipForCoord(business.coords.x, business.coords.y, business.coords.z)
        SetBlipSprite(blip, blipConfig.sprite)
        SetBlipDisplay(blip, blipConfig.display)
        SetBlipScale(blip, blipConfig.scale)
        SetBlipColour(blip, blipConfig.color)
        SetBlipAsShortRange(blip, blipConfig.shortRange)
        BeginTextCommandSetBlipName('STRING')
        if playerOwnsThis then
            AddTextComponentSubstringPlayerName(business.label)
        else
            AddTextComponentSubstringPlayerName(business.label .. ' - $' .. GroupDigits(business.price))
        end
        EndTextCommandSetBlipName(blip)

        blips[name] = blip
    end
end

-- ========================================
-- PROXIMITY THREAD
-- ========================================

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local sleep = 1000
        local isNearBusiness = false

        for name, business in pairs(Businesses) do
            local distance = #(playerCoords - vector3(business.coords.x, business.coords.y, business.coords.z))

            if distance < 10.0 then
                sleep = 0
                isNearBusiness = true

                if distance < 1.5 then
                    local playerOwnsThis = MyInstances[name] ~= nil

                    if playerOwnsThis then
                        DisplayHelpText("Press ~INPUT_CONTEXT~ to manage your business")
                    else
                        DisplayHelpText("Press ~INPUT_CONTEXT~ to purchase this business")
                    end

                    if IsControlJustReleased(0, 38) then
                        OpenBusinessMenu(name)
                    end
                end
            end
        end

        -- Close if walked away (but not for overview menu)
        if isBusinessMenuOpen and not isNearBusiness and not businessOverviewOpen then
            CloseBusinessMenu()
        end

        Wait(sleep)
    end
end)

-- ========================================
-- MENU OPEN / CLOSE
-- ========================================

function OpenBusinessMenu(businessName)
    if isBusinessMenuOpen then return end

    local business = Businesses[businessName]
    if not business then return end

    currentBusinessName = businessName

    -- Player owns this business
    if MyInstances[businessName] then
        isBusinessMenuOpen = true
        SetNuiFocus(true, true)

        local instance = MyInstances[businessName]
        local businessData = {
            name = business.name,
            label = business.label,
            description = business.description,
            type = business.type,
            price = business.price,
            coords = business.coords,
            money = instance.money or 0,
            dirty_money = instance.dirty_money or 0,
            staff_level = instance.staff_level or 0,
            size_level = instance.size_level or 0,
            logistics_level = instance.logistics_level or 0,
            security_level = instance.security_level or 0
        }

        if business.type == "warehouse" then
            SendNUIMessage({
                type = 'openWarehouse',
                business = businessData
            })
        else
            local income, boostedIncome, nextPayoutInfo, normalIncome = CalculateBusinessIncome(business, instance)
            local upgradeInfo = GetBusinessUpgradeInfo(business, instance)

            SendNUIMessage({
                type = 'openManage',
                business = businessData,
                income = income,
                upgradeInfo = upgradeInfo,
                boostedIncome = boostedIncome,
                nextPayoutInfo = nextPayoutInfo,
                normalIncome = normalIncome
            })
        end
    else
        -- Check license first via server
        TriggerServerEvent('my_business:checkLicense')
    end
end

-- License check result
RegisterNetEvent('my_business:licenseResult')
AddEventHandler('my_business:licenseResult', function(hasLicense)
    if not currentBusinessName then return end

    local business = Businesses[currentBusinessName]
    if not business then return end

    if hasLicense then
        isBusinessMenuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'openPurchase',
            business = business
        })
    else
        ShowNotification(Config.Notifications.prefix .. Config.Notifications.licenseRequired)
        SetNewWaypoint(Config.LicenseCenterCoords.x, Config.LicenseCenterCoords.y)
    end
end)

function CloseBusinessMenu()
    if not isBusinessMenuOpen then return end

    isBusinessMenuOpen = false
    businessOverviewOpen = false
    currentBusinessName = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
end

-- ========================================
-- NUI CALLBACKS
-- ========================================

RegisterNUICallback('close', function(data, cb)
    CloseBusinessMenu()
    cb('ok')
end)

RegisterNUICallback('forceClose', function(data, cb)
    isBusinessMenuOpen = false
    businessOverviewOpen = false
    currentBusinessName = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
    cb('ok')
end)

-- Purchase
RegisterNUICallback('purchase', function(data, cb)
    TriggerServerEvent('my_business:buyBusiness', data.name)
    cb('ok')
end)

RegisterNetEvent('my_business:buyResult')
AddEventHandler('my_business:buyResult', function(success, message)
    if success then
        CloseBusinessMenu()
    else
        SendNUIMessage({ type = 'purchaseError', message = message })
    end
end)

-- Sell
RegisterNUICallback('sell', function(data, cb)
    TriggerServerEvent('my_business:sellBusiness', data.name)
    cb('ok')
end)

RegisterNetEvent('my_business:sellResult')
AddEventHandler('my_business:sellResult', function(success, sellPrice)
    if success then
        CloseBusinessMenu()
    end
end)

-- Upgrade
RegisterNUICallback('upgrade', function(data, cb)
    TriggerServerEvent('my_business:upgradeBusiness', data.name, data.upgradeType)
    cb('ok')
end)

RegisterNetEvent('my_business:upgradeResult')
AddEventHandler('my_business:upgradeResult', function(success, upgradeTypeOrMessage, newLevel)
    if not success then
        ShowNotification("~r~" .. tostring(upgradeTypeOrMessage))
    end
    -- Success: menu refreshes via syncData
end)

-- Deposit dirty money
RegisterNUICallback('depositDirtyMoney', function(data, cb)
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        SendNUIMessage({ type = 'dirtyMoneyError', message = 'Please enter a valid amount' })
        cb('ok')
        return
    end
    TriggerServerEvent('my_business:depositDirtyMoney', data.business, amount)
    cb('ok')
end)

-- Withdraw dirty money
RegisterNUICallback('withdrawDirtyMoney', function(data, cb)
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        SendNUIMessage({ type = 'dirtyMoneyError', message = 'Please enter a valid amount' })
        cb('ok')
        return
    end
    TriggerServerEvent('my_business:withdrawDirtyMoney', data.business, amount)
    cb('ok')
end)

-- Dirty money result
RegisterNetEvent('my_business:dirtyMoneyResult')
AddEventHandler('my_business:dirtyMoneyResult', function(operation, success, message)
    if not success then
        SendNUIMessage({ type = 'dirtyMoneyError', message = message })
    end
end)

-- Withdraw all dirty money
RegisterNUICallback('withdrawAllDirtyMoney', function(data, cb)
    TriggerServerEvent('my_business:withdrawAllDirtyMoney')
    cb('ok')
end)

RegisterNetEvent('my_business:withdrawAllResult')
AddEventHandler('my_business:withdrawAllResult', function(success, message)
    if not success then
        SendNUIMessage({ type = 'withdrawAllError', message = message })
    else
        CloseBusinessMenu()
    end
end)

-- Calculate distribution
RegisterNUICallback('calculateDistribution', function(data, cb)
    local cycles = tonumber(data.cycles)
    if not cycles or cycles < 1 then
        SendNUIMessage({ type = 'distributionPreview', data = { error = 'Invalid cycle count' } })
        cb('ok')
        return
    end
    TriggerServerEvent('my_business:calculateDistribution', cycles)
    cb('ok')
end)

RegisterNetEvent('my_business:distributionPreview')
AddEventHandler('my_business:distributionPreview', function(result)
    SendNUIMessage({ type = 'distributionPreview', data = result })
end)

-- Execute distribution
RegisterNUICallback('distributeWarehouse', function(data, cb)
    local cycles = tonumber(data.cycles)
    TriggerServerEvent('my_business:distributeWarehouse', cycles)
    cb('ok')
end)

RegisterNetEvent('my_business:distributionResult')
AddEventHandler('my_business:distributionResult', function(success, message)
    if success then
        SendNUIMessage({ type = 'distributionSuccess' })
        CloseBusinessMenu()
    else
        SendNUIMessage({ type = 'distributionError', message = message })
    end
end)

-- View all businesses (NUI callback from overview)
RegisterNUICallback('viewAllBusinesses', function(data, cb)
    TriggerServerEvent('my_business:requestOwnedBusinesses')
    cb('ok')
end)

-- Teleport to business
RegisterNUICallback('teleportToBusiness', function(data, cb)
    local businessName = data.name
    local business = Businesses[businessName]

    if business then
        CloseBusinessMenu()
        SetEntityCoords(PlayerPedId(), business.coords.x, business.coords.y, business.coords.z, false, false, false, true)
        Wait(500)
        OpenBusinessMenu(businessName)
    end
    cb('ok')
end)

-- ========================================
-- BUSINESS OVERVIEW
-- ========================================

-- Receive owned businesses data from server
RegisterNetEvent('my_business:ownedBusinessesData')
AddEventHandler('my_business:ownedBusinessesData', function(businesses, myInstances)
    local businessList = {}
    local totalIncome = 0

    for name, instance in pairs(myInstances) do
        local business = businesses[name]
        if business and business.type ~= "warehouse" then
            local income = CalculateBusinessIncome(business, instance)
            totalIncome = totalIncome + income

            businessList[name] = {
                business = business,
                instance = instance
            }
        end
    end

    if next(businessList) then
        isBusinessMenuOpen = true
        businessOverviewOpen = true
        SetNuiFocus(true, true)

        SendNUIMessage({
            type = 'openOverview',
            businesses = businessList,
            totalIncome = totalIncome,
            isOverview = true
        })
    else
        ShowNotification("~o~You don't own any businesses")
        isBusinessMenuOpen = false
        businessOverviewOpen = false
        SetNuiFocus(false, false)
    end
end)

function OpenBusinessOverview()
    if businessOverviewOpen then return end
    if isBusinessMenuOpen then return end
    TriggerServerEvent('my_business:requestOwnedBusinesses')
end

-- Command
RegisterCommand('mybusinesses', function(source, args)
    if not IsEntityDead(PlayerPedId()) and not isBusinessMenuOpen then
        OpenBusinessOverview()
    end
end, false)

-- ========================================
-- SERVER NOTIFICATIONS
-- ========================================

RegisterNetEvent('my_business:notify')
AddEventHandler('my_business:notify', function(message)
    ShowNotification(Config.Notifications.prefix .. message)
end)
