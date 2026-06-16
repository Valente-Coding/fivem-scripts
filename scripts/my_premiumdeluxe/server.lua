-- my_premiumdeluxe/server.lua
-- Server-side logic for dealership purchase system

-- ============================================================
-- OWNERSHIP CHECK
-- ============================================================

RegisterNetEvent('my_premiumdeluxe:checkOwnership')
AddEventHandler('my_premiumdeluxe:checkOwnership', function()
    local source = source

    local data = exports['my_datamanager']:GetPlayerDataKey(source, 'dealership')

    local owned = false
    if data and data.premium_deluxe then
        owned = true
    end

    TriggerClientEvent('my_premiumdeluxe:ownershipStatus', source, owned)
end)

-- ============================================================
-- PURCHASE HANDLER
-- ============================================================

RegisterNetEvent('my_premiumdeluxe:requestPurchase')
AddEventHandler('my_premiumdeluxe:requestPurchase', function()
    local source = source
    local price = Config.Dealership.price

    -- Check if already owned
    local data = exports['my_datamanager']:GetPlayerDataKey(source, 'dealership')
    if data and data.premium_deluxe then
        TriggerClientEvent('my_premiumdeluxe:purchaseFailure', source, "You already own this dealership.")
        return
    end

    -- Check if player has enough money (cash)
    local playerCash = exports['my_money']:GetMoney(source, 'cash')

    if playerCash < price then
        TriggerClientEvent('my_premiumdeluxe:purchaseFailure', source, "Not enough money. You need $" .. price .. ".")
        return
    end

    -- Remove money
    local removed = exports['my_money']:RemoveMoney(source, 'cash', price)

    if not removed then
        TriggerClientEvent('my_premiumdeluxe:purchaseFailure', source, "Payment failed. Please try again.")
        return
    end

    -- Save ownership via datamanager
    local dealershipData = data or {}
    dealershipData.premium_deluxe = true

    local saved = exports['my_datamanager']:SetPlayerDataKey(source, 'dealership', dealershipData)

    if not saved then
        -- Refund if save failed
        exports['my_money']:AddMoney(source, 'cash', price)
        TriggerClientEvent('my_premiumdeluxe:purchaseFailure', source, "Failed to save purchase. You have been refunded.")
        return
    end

    -- Send success to client
    TriggerClientEvent('my_premiumdeluxe:purchaseSuccess', source)

    -- Flash money display
    TriggerClientEvent('my_money:flashMoney', source, 'cash')

    print("[my_premiumdeluxe] " .. GetPlayerName(source) .. " purchased " .. Config.Dealership.name .. " for $" .. price)
end)
