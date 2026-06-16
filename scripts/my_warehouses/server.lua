-- ════════════════════════════════════════════════════════
-- WAREHOUSE EMPIRE — Server
-- Persistence via my_datamanager, money via my_money
-- ════════════════════════════════════════════════════════

local warehouseCache = {} -- warehouseCache[source] = { [warehouseId] = state, ... }

-- ════════════════════ HELPERS ════════════════════

local function GetPlayerLicense(source)
    return exports['my_datamanager']:GetPlayerLicense(source)
end

local function LoadPlayerData(source)
    if warehouseCache[source] then return warehouseCache[source] end

    local data = exports['my_datamanager']:GetPlayerDataKey(source, 'warehouse')
    if data and type(data) == 'table' then
        warehouseCache[source] = data
    else
        warehouseCache[source] = {}
    end

    return warehouseCache[source]
end

local function SavePlayerData(source)
    if not warehouseCache[source] then return end
    exports['my_datamanager']:SetPlayerDataKey(source, 'warehouse', warehouseCache[source])
end

local function CountOwnedWarehouses(source)
    local data = LoadPlayerData(source)
    local count = 0
    for _ in pairs(data) do count = count + 1 end
    return count
end

local function GetPlayerCash(source)
    return exports['my_money']:GetMoney(source, 'cash') or 0
end

local function CreateDefaultState()
    local state = {}
    -- Deep copy the default state
    for k, v in pairs(Config.DefaultWarehouseState) do
        if type(v) == 'table' then
            state[k] = {}
            for k2, v2 in pairs(v) do
                state[k][k2] = v2
            end
        else
            state[k] = v
        end
    end
    state.upgrades = Config.BuildDefaultUpgrades()
    return state
end

-- ════════════════════ EVENTS ════════════════════

-- Player requests all their warehouse data on load
RegisterNetEvent('my_warehouses:requestData')
AddEventHandler('my_warehouses:requestData', function()
    local _source = source
    local data = LoadPlayerData(_source)
    TriggerClientEvent('my_warehouses:receiveData', _source, data, GetPlayerCash(_source))
end)

-- Client auto-saves all warehouse states every N seconds
RegisterNetEvent('my_warehouses:saveData')
AddEventHandler('my_warehouses:saveData', function(data)
    local _source = source
    if type(data) ~= 'table' then return end

    -- Validate: only accept warehouses the player actually owns
    local existing = LoadPlayerData(_source)
    for wid, state in pairs(data) do
        if existing[wid] then
            existing[wid] = state
        end
    end

    warehouseCache[_source] = existing
    SavePlayerData(_source)
end)

-- Player wants to buy a warehouse
RegisterNetEvent('my_warehouses:buyWarehouse')
AddEventHandler('my_warehouses:buyWarehouse', function(warehouseId)
    local _source = source
    local data = LoadPlayerData(_source)

    -- Find config entry
    local whConfig = nil
    for _, wh in ipairs(Config.Warehouses) do
        if wh.id == warehouseId then
            whConfig = wh
            break
        end
    end

    if not whConfig then
        TriggerClientEvent('my_warehouses:buyResult', _source, false, 'Invalid warehouse.')
        return
    end

    -- Already owns it?
    if data[warehouseId] then
        TriggerClientEvent('my_warehouses:buyResult', _source, false, 'You already own this warehouse.')
        return
    end

    -- Max check
    if CountOwnedWarehouses(_source) >= Config.MaxOwnedWarehouses then
        TriggerClientEvent('my_warehouses:buyResult', _source, false, 'You own the maximum number of warehouses.')
        return
    end

    -- Money check
    local hasMoney = exports['my_money']:RemoveMoney(_source, 'cash', whConfig.price)
    if not hasMoney then
        TriggerClientEvent('my_warehouses:buyResult', _source, false, 'Not enough cash.')
        return
    end

    -- Create default state
    data[warehouseId] = CreateDefaultState()
    warehouseCache[_source] = data
    SavePlayerData(_source)

    TriggerClientEvent('my_warehouses:buyResult', _source, true, 'Warehouse purchased!', warehouseId, data[warehouseId], GetPlayerCash(_source))
end)

-- Player sells a warehouse
RegisterNetEvent('my_warehouses:sellWarehouse')
AddEventHandler('my_warehouses:sellWarehouse', function(warehouseId)
    local _source = source
    local data = LoadPlayerData(_source)

    if not data[warehouseId] then
        TriggerClientEvent('my_warehouses:sellResult', _source, false, 'You do not own this warehouse.')
        return
    end

    -- Find config for refund
    local whConfig = nil
    for _, wh in ipairs(Config.Warehouses) do
        if wh.id == warehouseId then whConfig = wh break end
    end

    -- Refund remaining warehouse balance + 50% of purchase price
    local refund = math.floor((whConfig and whConfig.price or 0) * 0.5) + math.floor(data[warehouseId].money or 0)
    if refund > 0 then
        exports['my_money']:AddMoney(_source, 'cash', refund)
    end

    data[warehouseId] = nil
    warehouseCache[_source] = data
    SavePlayerData(_source)

    TriggerClientEvent('my_warehouses:sellResult', _source, true, 'Warehouse sold! Refund: $' .. refund, warehouseId, GetPlayerCash(_source))
end)

-- Player deposits real cash into warehouse balance
RegisterNetEvent('my_warehouses:deposit')
AddEventHandler('my_warehouses:deposit', function(warehouseId, amount)
    local _source = source
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    amount = math.floor(amount)

    local data = LoadPlayerData(_source)
    if not data[warehouseId] then return end

    local removed = exports['my_money']:RemoveMoney(_source, 'cash', amount)
    if not removed then
        TriggerClientEvent('my_warehouses:depositResult', _source, false, 'Not enough cash.', warehouseId)
        return
    end

    data[warehouseId].money = (data[warehouseId].money or 0) + amount
    SavePlayerData(_source)

    TriggerClientEvent('my_warehouses:depositResult', _source, true, 'Deposited $' .. amount, warehouseId, data[warehouseId].money, GetPlayerCash(_source))
end)

-- Player withdraws warehouse balance to real cash
RegisterNetEvent('my_warehouses:withdraw')
AddEventHandler('my_warehouses:withdraw', function(warehouseId, amount)
    local _source = source
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    amount = math.floor(amount)

    local data = LoadPlayerData(_source)
    if not data[warehouseId] then return end

    local balance = data[warehouseId].money or 0
    if balance < amount then
        TriggerClientEvent('my_warehouses:withdrawResult', _source, false, 'Not enough warehouse balance.', warehouseId)
        return
    end

    data[warehouseId].money = balance - amount
    exports['my_money']:AddMoney(_source, 'cash', amount)
    SavePlayerData(_source)

    TriggerClientEvent('my_warehouses:withdrawResult', _source, true, 'Withdrew $' .. amount, warehouseId, data[warehouseId].money, GetPlayerCash(_source))
end)

-- Manual delivery completion (validated server-side)
RegisterNetEvent('my_warehouses:completeManualDelivery')
AddEventHandler('my_warehouses:completeManualDelivery', function(warehouseId, payout, boxCount)
    local _source = source
    payout = tonumber(payout)
    boxCount = tonumber(boxCount)
    if not payout or not boxCount or payout <= 0 or boxCount <= 0 then return end

    local data = LoadPlayerData(_source)
    if not data[warehouseId] then return end

    -- Credit payout to warehouse balance
    data[warehouseId].money = (data[warehouseId].money or 0) + payout
    data[warehouseId].stats.totalMoneyEarned = (data[warehouseId].stats.totalMoneyEarned or 0) + payout
    data[warehouseId].stats.totalBoxesDelivered = (data[warehouseId].stats.totalBoxesDelivered or 0) + boxCount
    data[warehouseId].stats.totalDeliveries = (data[warehouseId].stats.totalDeliveries or 0) + 1
    SavePlayerData(_source)

    TriggerClientEvent('my_warehouses:manualDeliveryResult', _source, true, warehouseId, payout)
end)

-- ════════════════════ PHONE INTEGRATION ════════════════════

-- Phone requests list of owned warehouses with balances
RegisterNetEvent('my_warehouses:phoneRequestBalances')
AddEventHandler('my_warehouses:phoneRequestBalances', function()
    local _source = source
    local data = LoadPlayerData(_source)
    local list = {}

    for wid, state in pairs(data) do
        -- Find display name from config
        local name = wid
        for _, wh in ipairs(Config.Warehouses) do
            if wh.id == wid then name = wh.name break end
        end
        table.insert(list, {
            id      = wid,
            name    = name,
            balance = math.floor(state.money or 0),
        })
    end

    TriggerClientEvent('my_warehouses:phoneBalances', _source, list)
end)

-- Phone: withdraw from a specific warehouse
RegisterNetEvent('my_warehouses:phoneWithdraw')
AddEventHandler('my_warehouses:phoneWithdraw', function(warehouseId, amount)
    local _source = source
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    amount = math.floor(amount)

    local data = LoadPlayerData(_source)
    if not data[warehouseId] then
        TriggerClientEvent('my_warehouses:phoneWithdrawResult', _source, false, 'Warehouse not found.')
        return
    end

    local balance = data[warehouseId].money or 0
    if balance < amount then
        TriggerClientEvent('my_warehouses:phoneWithdrawResult', _source, false, 'Not enough balance.')
        return
    end

    data[warehouseId].money = balance - amount
    exports['my_money']:AddMoney(_source, 'cash', amount)
    SavePlayerData(_source)

    -- Send back updated list
    local list = {}
    for wid, state in pairs(data) do
        local name = wid
        for _, wh in ipairs(Config.Warehouses) do
            if wh.id == wid then name = wh.name break end
        end
        table.insert(list, {
            id      = wid,
            name    = name,
            balance = math.floor(state.money or 0),
        })
    end

    -- Sync the warehouses client's local state
    TriggerClientEvent('my_warehouses:phoneWithdrawSync', _source, warehouseId, data[warehouseId].money, GetPlayerCash(_source))

    TriggerClientEvent('my_warehouses:phoneWithdrawResult', _source, true, 'Withdrew $' .. amount, list)
end)

-- Player requests current cash balance (lightweight sync)
RegisterNetEvent('my_warehouses:requestCash')
AddEventHandler('my_warehouses:requestCash', function()
    local _source = source
    TriggerClientEvent('my_warehouses:receiveCash', _source, GetPlayerCash(_source))
end)

-- ════════════════════ CLEANUP ════════════════════

-- Preload on connect
AddEventHandler('playerConnecting', function()
    local _source = source
    CreateThread(function()
        Wait(2000)
        LoadPlayerData(_source)
    end)
end)

-- Save and clear on disconnect
AddEventHandler('playerDropped', function()
    local _source = source
    if warehouseCache[_source] then
        SavePlayerData(_source)
        warehouseCache[_source] = nil
    end
end)

-- Periodic full save (safety net)
CreateThread(function()
    while true do
        Wait(60000) -- every 60 seconds
        for src, _ in pairs(warehouseCache) do
            SavePlayerData(src)
        end
    end
end)
