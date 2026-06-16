-- Business Management Server

local Businesses = {}
local connectedPlayers = {} -- [source] = license
local allPlayerData = {} -- [license] = { businesses = { name = { money, dirty_money, staff_level, ... } } }

-- Format number with commas
local function GroupDigits(amount)
    local formatted = tostring(math.floor(amount))
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Get or initialize player business data
local function GetPlayerData(license)
    if not allPlayerData[license] then
        allPlayerData[license] = { businesses = {} }
    end
    if not allPlayerData[license].businesses then
        allPlayerData[license].businesses = {}
    end
    return allPlayerData[license]
end

-- Save player business data to datamanager
local function SavePlayerData(source, license)
    local data = allPlayerData[license]
    if data then
        exports['my_datamanager']:SetPlayerDataKey(source, 'business', data)
    end
end

-- Count player's non-warehouse businesses
local function CountPlayerBusinesses(license)
    local data = GetPlayerData(license)
    local count = 0
    for name, _ in pairs(data.businesses) do
        if name ~= "money_warehouse" then
            count = count + 1
        end
    end
    return count
end

-- Round to nearest multiple of 5
local function RoundToFive(n)
    return math.floor(n / 5 + 0.5) * 5
end

-- Calculate business income with dirty money boost
local function CalculateBusinessIncome(baseBusiness, instance)
    local staffBonus = (instance.staff_level or 0) * Config.StaffIncomeBonus
    local sizeBonus = (instance.size_level or 0) * Config.SizeIncomeBonus
    local logisticsBonus = (instance.logistics_level or 0) * Config.LogisticsIncomeBonus
    local securityBonus = (instance.security_level or 0) * Config.SecurityIncomeBonus

    local totalMultiplier = Config.BaseIncomeMultiplier + staffBonus + sizeBonus + logisticsBonus + securityBonus
    local normalIncome = RoundToFive(math.floor(baseBusiness.price * totalMultiplier))

    local income = normalIncome
    local dirtyMoneyUsed = 0

    if instance.dirty_money and instance.dirty_money > 0 then
        local maxAdditionalIncome = RoundToFive(math.floor(normalIncome * 0.5))
        local additionalIncome = math.min(instance.dirty_money, maxAdditionalIncome)
        income = normalIncome + additionalIncome
        dirtyMoneyUsed = additionalIncome
    end

    return income, dirtyMoneyUsed
end

-- Calculate warehouse distribution preview
local function CalculateWarehouseDistribution(license, cycleCount)
    local result = { businesses = {}, totalRequired = 0, error = nil }

    if not cycleCount or cycleCount < Config.MinDistributionCycles or cycleCount > Config.MaxDistributionCycles then
        result.error = string.format("Cycles must be between %d and %d", Config.MinDistributionCycles, Config.MaxDistributionCycles)
        return result
    end

    local playerData = GetPlayerData(license)

    for businessName, instance in pairs(playerData.businesses) do
        local business = Businesses[businessName]
        if business and business.type ~= "warehouse" then
            local staffBonus = (instance.staff_level or 0) * Config.StaffIncomeBonus
            local sizeBonus = (instance.size_level or 0) * Config.SizeIncomeBonus
            local logisticsBonus = (instance.logistics_level or 0) * Config.LogisticsIncomeBonus
            local securityBonus = (instance.security_level or 0) * Config.SecurityIncomeBonus

            local totalMultiplier = Config.BaseIncomeMultiplier + staffBonus + sizeBonus + logisticsBonus + securityBonus
            local normalIncome = RoundToFive(math.floor(business.price * totalMultiplier))

            local amountPerCycle = RoundToFive(math.floor(normalIncome * 0.5))
            local totalAmount = amountPerCycle * cycleCount

            table.insert(result.businesses, {
                name = businessName,
                label = business.label,
                income = normalIncome,
                amountPerCycle = amountPerCycle,
                totalAmount = totalAmount,
                cycles = cycleCount
            })

            result.totalRequired = result.totalRequired + totalAmount
        end
    end

    if #result.businesses == 0 then
        result.error = "You need at least one business (other than warehouse) for distribution"
    end

    return result
end

-- ========================================
-- INITIALIZATION
-- ========================================

CreateThread(function()
    Wait(500)
    for _, business in ipairs(Config.DefaultBusinesses) do
        Businesses[business.name] = {
            name = business.name,
            label = business.label,
            description = business.description,
            type = business.type,
            price = business.price,
            coords = business.coords
        }
    end

    StartIncomeTimer()
end)

-- ========================================
-- INCOME TIMER
-- ========================================

function StartIncomeTimer()
    CreateThread(function()
        while true do
            Wait(Config.IncomeInterval * 60 * 1000)
            GenerateIncome()
        end
    end)
end

function GenerateIncome()
    for playerSource, license in pairs(connectedPlayers) do
        local playerData = GetPlayerData(license)
        local totalIncome = 0
        local totalDirtyUsed = 0
        local businessCount = 0

        for businessName, instance in pairs(playerData.businesses) do
            local baseBusiness = Businesses[businessName]
            if baseBusiness and baseBusiness.type ~= "warehouse" then
                local income, dirtyUsed = CalculateBusinessIncome(baseBusiness, instance)
                totalIncome = totalIncome + income
                totalDirtyUsed = totalDirtyUsed + dirtyUsed
                businessCount = businessCount + 1

                -- Deduct dirty money used for laundering
                if dirtyUsed > 0 then
                    instance.dirty_money = math.max(0, (instance.dirty_money or 0) - dirtyUsed)
                end
            end
        end

        if totalIncome > 0 then
            exports['my_money']:AddMoney(playerSource, 'cash', totalIncome)
            SavePlayerData(playerSource, license)

            local message
            if businessCount == 1 then
                message = string.format(Config.Notifications.incomeReceived, GroupDigits(totalIncome))
            else
                message = string.format("You received $%s income from your %d businesses", GroupDigits(totalIncome), businessCount)
            end
            TriggerClientEvent('my_business:notify', playerSource, message)
            TriggerClientEvent('my_business:syncData', playerSource, Businesses, playerData.businesses)

            if Config.Debug then
                print(string.format("[Business] %s received $%s income (%d businesses, $%s laundered)",
                    license, GroupDigits(totalIncome), businessCount, GroupDigits(totalDirtyUsed)))
            end
        end
    end
end

-- ========================================
-- PLAYER CONNECT / DISCONNECT
-- ========================================

-- Player requests initial data
RegisterNetEvent('my_business:requestData')
AddEventHandler('my_business:requestData', function()
    local _source = source
    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if not license then return end

    connectedPlayers[_source] = license

    local businessData = exports['my_datamanager']:GetPlayerDataKey(_source, 'business') or { businesses = {} }
    if not businessData.businesses then
        businessData.businesses = {}
    end

    allPlayerData[license] = businessData

    TriggerClientEvent('my_business:syncData', _source, Businesses, businessData.businesses)
end)

-- Player dropped
AddEventHandler('playerDropped', function(reason)
    local _source = source
    local license = connectedPlayers[_source]
    if license then
        allPlayerData[license] = nil
        connectedPlayers[_source] = nil
    end
end)

-- ========================================
-- BUSINESS LICENSE CHECK
-- ========================================

RegisterNetEvent('my_business:checkLicense')
AddEventHandler('my_business:checkLicense', function()
    local _source = source
    local hasLicense = exports['my_licenses']:hasLicense(_source, 'business')
    TriggerClientEvent('my_business:licenseResult', _source, hasLicense)
end)

-- ========================================
-- BUY BUSINESS
-- ========================================

RegisterNetEvent('my_business:buyBusiness')
AddEventHandler('my_business:buyBusiness', function(businessName)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then return end

    local business = Businesses[businessName]
    if not business then
        TriggerClientEvent('my_business:buyResult', _source, false, 'Business not found')
        return
    end

    local playerData = GetPlayerData(license)

    -- Already owned check
    if playerData.businesses[businessName] then
        TriggerClientEvent('my_business:buyResult', _source, false, 'You already own this business')
        return
    end

    -- Business limit (excluding warehouse)
    if businessName ~= "money_warehouse" then
        if CountPlayerBusinesses(license) >= Config.MaxBusinessesPerPlayer then
            TriggerClientEvent('my_business:buyResult', _source, false,
                'You have reached the maximum limit of ' .. Config.MaxBusinessesPerPlayer .. ' businesses')
            return
        end
    end

    -- Warehouse limit
    if businessName == "money_warehouse" and playerData.businesses["money_warehouse"] then
        TriggerClientEvent('my_business:buyResult', _source, false, 'You can only own one money warehouse')
        return
    end

    -- License check
    local hasLicense = exports['my_licenses']:hasLicense(_source, 'business')
    if not hasLicense then
        TriggerClientEvent('my_business:buyResult', _source, false, Config.Notifications.licenseRequired)
        return
    end

    -- Check and deduct cash
    local price = business.price
    local cash = exports['my_money']:GetMoney(_source, 'cash')
    if cash < price then
        TriggerClientEvent('my_business:buyResult', _source, false, Config.Notifications.insufficientFunds)
        return
    end

    exports['my_money']:RemoveMoney(_source, 'cash', price)

    -- Create instance
    playerData.businesses[businessName] = {
        money = 0,
        dirty_money = 0,
        staff_level = 0,
        size_level = 0,
        logistics_level = 0,
        security_level = 0
    }

    allPlayerData[license] = playerData
    SavePlayerData(_source, license)

    TriggerClientEvent('my_business:syncData', _source, Businesses, playerData.businesses)
    TriggerClientEvent('my_business:buyResult', _source, true)
    TriggerClientEvent('my_business:notify', _source,
        string.format(Config.Notifications.purchaseSuccess, GroupDigits(price)))
end)

-- ========================================
-- SELL BUSINESS
-- ========================================

RegisterNetEvent('my_business:sellBusiness')
AddEventHandler('my_business:sellBusiness', function(businessName)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then return end

    local business = Businesses[businessName]
    if not business then
        TriggerClientEvent('my_business:sellResult', _source, false)
        return
    end

    local playerData = GetPlayerData(license)
    local instance = playerData.businesses[businessName]

    if not instance then
        TriggerClientEvent('my_business:sellResult', _source, false)
        return
    end

    -- Calculate sell price (90% of price + any business funds)
    local sellPrice = math.floor(business.price * Config.SellMultiplier) + (instance.money or 0)

    -- Pay cash
    exports['my_money']:AddMoney(_source, 'cash', sellPrice)

    -- Remove instance
    playerData.businesses[businessName] = nil

    allPlayerData[license] = playerData
    SavePlayerData(_source, license)

    TriggerClientEvent('my_business:syncData', _source, Businesses, playerData.businesses)
    TriggerClientEvent('my_business:sellResult', _source, true, sellPrice)
    TriggerClientEvent('my_business:notify', _source,
        string.format(Config.Notifications.sellSuccess, GroupDigits(sellPrice)))
end)

-- ========================================
-- UPGRADE BUSINESS
-- ========================================

RegisterNetEvent('my_business:upgradeBusiness')
AddEventHandler('my_business:upgradeBusiness', function(businessName, upgradeType)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then return end

    local business = Businesses[businessName]
    if not business then
        TriggerClientEvent('my_business:upgradeResult', _source, false, 'Business not found')
        return
    end

    local playerData = GetPlayerData(license)
    local instance = playerData.businesses[businessName]

    if not instance then
        TriggerClientEvent('my_business:upgradeResult', _source, false, 'You do not own this business')
        return
    end

    -- Validate upgrade type
    local maxLevel
    if upgradeType == 'staff' then
        maxLevel = Config.MaxStaffLevel
    elseif upgradeType == 'size' then
        maxLevel = Config.MaxSizeLevel
    elseif upgradeType == 'logistics' then
        maxLevel = Config.MaxLogisticsLevel
    elseif upgradeType == 'security' then
        maxLevel = Config.MaxSecurityLevel
    else
        TriggerClientEvent('my_business:upgradeResult', _source, false, 'Invalid upgrade type')
        return
    end

    local currentLevel = instance[upgradeType .. '_level'] or 0
    if currentLevel >= maxLevel then
        TriggerClientEvent('my_business:upgradeResult', _source, false, Config.Notifications.maxUpgradeReached)
        return
    end

    -- Check and deduct cash
    local upgradeCost = math.floor(business.price * Config.UpgradeCostMultiplier[upgradeType])
    local cash = exports['my_money']:GetMoney(_source, 'cash')
    if cash < upgradeCost then
        TriggerClientEvent('my_business:upgradeResult', _source, false, Config.Notifications.upgradeFailure)
        return
    end

    exports['my_money']:RemoveMoney(_source, 'cash', upgradeCost)

    -- Apply upgrade
    instance[upgradeType .. '_level'] = currentLevel + 1

    allPlayerData[license] = playerData
    SavePlayerData(_source, license)

    TriggerClientEvent('my_business:syncData', _source, Businesses, playerData.businesses)
    TriggerClientEvent('my_business:upgradeResult', _source, true, upgradeType, currentLevel + 1)
    TriggerClientEvent('my_business:notify', _source,
        string.format(Config.Notifications.upgradeSuccess, upgradeType, currentLevel + 1))
end)

-- ========================================
-- DIRTY MONEY OPERATIONS
-- ========================================

-- Deposit dirty money into business
RegisterNetEvent('my_business:depositDirtyMoney')
AddEventHandler('my_business:depositDirtyMoney', function(businessName, amount)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then return end

    local business = Businesses[businessName]
    if not business then
        TriggerClientEvent('my_business:dirtyMoneyResult', _source, 'deposit', false, 'Business not found')
        return
    end

    local playerData = GetPlayerData(license)
    local instance = playerData.businesses[businessName]

    if not instance then
        TriggerClientEvent('my_business:dirtyMoneyResult', _source, 'deposit', false, 'You do not own this business')
        return
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('my_business:dirtyMoneyResult', _source, 'deposit', false, 'Invalid amount')
        return
    end

    -- Check player's dirty money
    local dirtyMoney = exports['my_money']:GetMoney(_source, 'dirty')
    if dirtyMoney < amount then
        TriggerClientEvent('my_business:dirtyMoneyResult', _source, 'deposit', false, 'Not enough dirty money')
        return
    end

    -- Transfer
    exports['my_money']:RemoveMoney(_source, 'dirty', amount)
    instance.dirty_money = (instance.dirty_money or 0) + amount

    allPlayerData[license] = playerData
    SavePlayerData(_source, license)

    TriggerClientEvent('my_business:syncData', _source, Businesses, playerData.businesses)
    TriggerClientEvent('my_business:dirtyMoneyResult', _source, 'deposit', true)
    TriggerClientEvent('my_business:notify', _source,
        "Deposited $" .. GroupDigits(amount) .. " dirty money into your business")
end)

-- Withdraw dirty money from business
RegisterNetEvent('my_business:withdrawDirtyMoney')
AddEventHandler('my_business:withdrawDirtyMoney', function(businessName, amount)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then return end

    local business = Businesses[businessName]
    if not business then
        TriggerClientEvent('my_business:dirtyMoneyResult', _source, 'withdraw', false, 'Business not found')
        return
    end

    local playerData = GetPlayerData(license)
    local instance = playerData.businesses[businessName]

    if not instance then
        TriggerClientEvent('my_business:dirtyMoneyResult', _source, 'withdraw', false, 'You do not own this business')
        return
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('my_business:dirtyMoneyResult', _source, 'withdraw', false, 'Invalid amount')
        return
    end

    if not instance.dirty_money or instance.dirty_money < amount then
        TriggerClientEvent('my_business:dirtyMoneyResult', _source, 'withdraw', false, 'Not enough dirty money in business')
        return
    end

    -- Transfer
    instance.dirty_money = instance.dirty_money - amount
    exports['my_money']:AddMoney(_source, 'dirty', amount)

    allPlayerData[license] = playerData
    SavePlayerData(_source, license)

    TriggerClientEvent('my_business:syncData', _source, Businesses, playerData.businesses)
    TriggerClientEvent('my_business:dirtyMoneyResult', _source, 'withdraw', true)
    TriggerClientEvent('my_business:notify', _source,
        "Withdrawn $" .. GroupDigits(amount) .. " dirty money from your business")
end)

-- Withdraw all dirty money from all businesses
RegisterNetEvent('my_business:withdrawAllDirtyMoney')
AddEventHandler('my_business:withdrawAllDirtyMoney', function()
    local _source = source
    local license = connectedPlayers[_source]
    if not license then
        TriggerClientEvent('my_business:withdrawAllResult', _source, false, 'Player data not found')
        return
    end

    local playerData = GetPlayerData(license)
    local totalDirty = 0
    local businessCount = 0

    for _, instance in pairs(playerData.businesses) do
        if instance.dirty_money and instance.dirty_money > 0 then
            totalDirty = totalDirty + instance.dirty_money
            instance.dirty_money = 0
            businessCount = businessCount + 1
        end
    end

    if totalDirty == 0 then
        TriggerClientEvent('my_business:withdrawAllResult', _source, false, 'No dirty money in any business')
        return
    end

    exports['my_money']:AddMoney(_source, 'dirty', totalDirty)

    allPlayerData[license] = playerData
    SavePlayerData(_source, license)

    TriggerClientEvent('my_business:syncData', _source, Businesses, playerData.businesses)
    TriggerClientEvent('my_business:withdrawAllResult', _source, true)
    TriggerClientEvent('my_business:notify', _source,
        string.format("Withdrawn $%s dirty money from %d businesses", GroupDigits(totalDirty), businessCount))
end)

-- ========================================
-- WAREHOUSE DISTRIBUTION
-- ========================================

-- Calculate distribution preview
RegisterNetEvent('my_business:calculateDistribution')
AddEventHandler('my_business:calculateDistribution', function(cycleCount)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then
        TriggerClientEvent('my_business:distributionPreview', _source, { error = 'Player data not found' })
        return
    end

    local playerData = GetPlayerData(license)

    if not playerData.businesses["money_warehouse"] then
        TriggerClientEvent('my_business:distributionPreview', _source, { error = "You don't own a warehouse" })
        return
    end

    local result = CalculateWarehouseDistribution(license, tonumber(cycleCount))
    TriggerClientEvent('my_business:distributionPreview', _source, result)
end)

-- Execute distribution
RegisterNetEvent('my_business:distributeWarehouse')
AddEventHandler('my_business:distributeWarehouse', function(cycleCount)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then
        TriggerClientEvent('my_business:distributionResult', _source, false, 'Player data not found')
        return
    end

    local playerData = GetPlayerData(license)

    if not playerData.businesses["money_warehouse"] then
        TriggerClientEvent('my_business:distributionResult', _source, false, "You don't own a warehouse")
        return
    end

    local distribution = CalculateWarehouseDistribution(license, tonumber(cycleCount))
    if distribution.error then
        TriggerClientEvent('my_business:distributionResult', _source, false, distribution.error)
        return
    end

    -- Check dirty money
    local dirtyMoney = exports['my_money']:GetMoney(_source, 'dirty')
    if dirtyMoney < distribution.totalRequired then
        TriggerClientEvent('my_business:distributionResult', _source, false,
            string.format("Need $%s dirty money, you have $%s",
                GroupDigits(distribution.totalRequired), GroupDigits(dirtyMoney)))
        return
    end

    -- Remove dirty money from player
    exports['my_money']:RemoveMoney(_source, 'dirty', distribution.totalRequired)

    -- Distribute to businesses
    for _, businessData in ipairs(distribution.businesses) do
        local instance = playerData.businesses[businessData.name]
        if instance then
            instance.dirty_money = (instance.dirty_money or 0) + businessData.totalAmount
        end
    end

    allPlayerData[license] = playerData
    SavePlayerData(_source, license)

    TriggerClientEvent('my_business:syncData', _source, Businesses, playerData.businesses)
    TriggerClientEvent('my_business:distributionResult', _source, true)
    TriggerClientEvent('my_business:notify', _source,
        string.format("Distributed $%s across %d businesses for %d cycles",
            GroupDigits(distribution.totalRequired), #distribution.businesses, cycleCount))
end)

-- ========================================
-- OVERVIEW REQUEST
-- ========================================

RegisterNetEvent('my_business:requestOwnedBusinesses')
AddEventHandler('my_business:requestOwnedBusinesses', function()
    local _source = source
    local license = connectedPlayers[_source]
    if not license then return end

    local playerData = GetPlayerData(license)
    TriggerClientEvent('my_business:ownedBusinessesData', _source, Businesses, playerData.businesses)
end)

-- ========================================
-- ADMIN COMMANDS
-- ========================================

RegisterCommand('forceincome', function(source, args, rawCommand)
    if source == 0 then
        GenerateIncome()
    end
end, true)

-- Export: Reset a player's business data (used by permadeath wipe)
exports('ResetPlayerData', function(source)
    local license = connectedPlayers[source]
    if license then
        allPlayerData[license] = { businesses = {} }
        exports['my_datamanager']:SetPlayerDataKey(source, 'business', { businesses = {} })
        -- Re-sync the client so blips update immediately
        TriggerClientEvent('my_business:syncData', source, Businesses, {})
    end
end)

