-- my_moneylaundering/server.lua
-- Server-side logic for the money laundering system

-- ============================================================
-- BALANCE REQUEST
-- ============================================================

RegisterNetEvent('my_moneylaundering:requestBalance')
AddEventHandler('my_moneylaundering:requestBalance', function()
    local src = source
    local dirtyMoney = exports['my_money']:GetMoney(src, 'dirty')
    TriggerClientEvent('my_moneylaundering:receiveBalance', src, dirtyMoney)
end)

-- ============================================================
-- LAUNDER TRANSACTION
-- ============================================================

RegisterNetEvent('my_moneylaundering:launder')
AddEventHandler('my_moneylaundering:launder', function()
    local src = source
    local dirtyMoney = exports['my_money']:GetMoney(src, 'dirty')

    -- Validate minimum amount
    if dirtyMoney < Config.MinDirtyMoney then
        TriggerClientEvent('my_moneylaundering:result', src, false,
            "You don't have enough dirty money. Minimum: $" .. Config.MinDirtyMoney)
        return
    end

    -- Calculate clean payout (30%)
    local cleanAmount = math.floor(dirtyMoney * Config.LaunderRate)

    -- Remove ALL dirty money
    local removed = exports['my_money']:RemoveMoney(src, 'dirty', dirtyMoney)
    if not removed then
        TriggerClientEvent('my_moneylaundering:result', src, false,
            "Transaction failed. Try again.")
        return
    end

    -- Add clean cash
    local added = exports['my_money']:AddMoney(src, 'cash', cleanAmount)
    if not added then
        -- Rollback: give dirty money back
        exports['my_money']:AddMoney(src, 'dirty', dirtyMoney)
        TriggerClientEvent('my_moneylaundering:result', src, false,
            "Transaction failed. Try again.")
        return
    end

    -- Success
    TriggerClientEvent('my_moneylaundering:result', src, true,
        "Money laundered successfully. You received $" .. tostring(cleanAmount) .. " clean cash.")
end)
