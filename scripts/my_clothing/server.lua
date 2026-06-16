-- ═══════════════════════════════════════════════════════════════════════════════
-- my_clothing - Server
-- Handles clothing purchase, money deduction, and persistence
-- Uses my_datamanager for all data storage (saved_data folder)
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- PURCHASE OUTFIT
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('my_clothing:purchase')
AddEventHandler('my_clothing:purchase', function(clothingData)
    local source = source

    -- Validate input
    if type(clothingData) ~= "table" then
        print("^1[Clothing] Invalid data type from player " .. source .. ": " .. type(clothingData) .. "^7")
        TriggerClientEvent('my_clothing:purchaseResult', source, false, "Invalid clothing data.")
        return
    end

    -- Sanitize the clothing data
    local cleanData = {}
    for _, entry in pairs(clothingData) do
        if type(entry) == "table" and entry.kind and entry.id then
            cleanData[#cleanData + 1] = {
                kind = tostring(entry.kind),
                id = tonumber(entry.id) or 0,
                drawable = tonumber(entry.drawable) or 0,
                texture = tonumber(entry.texture) or 0
            }
        end
    end

    if #cleanData == 0 then
        print("^1[Clothing] Empty cleaned data from player " .. source .. "^7")
        TriggerClientEvent('my_clothing:purchaseResult', source, false, "No clothing data received.")
        return
    end

    print("^3[Clothing] Purchase attempt from player " .. source .. " - " .. #cleanData .. " pieces^7")

    -- Check and deduct money
    local removed = exports['my_money']:RemoveMoney(source, 'cash', Config.Price)
    if not removed then
        TriggerClientEvent('my_clothing:purchaseResult', source, false,
            "Not enough cash! You need $" .. Config.Price .. ".")
        return
    end

    -- Save clothing data via my_datamanager (central saved_data folder)
    local saved = exports['my_datamanager']:SetPlayerDataKey(source, 'clothing', cleanData)
    if not saved then
        -- Refund on failure
        exports['my_money']:AddMoney(source, 'cash', Config.Price)
        TriggerClientEvent('my_clothing:purchaseResult', source, false,
            "Failed to save outfit. Money refunded.")
        return
    end

    -- Success
    TriggerClientEvent('my_clothing:purchaseResult', source, true,
        "Outfit saved! (-$" .. Config.Price .. ")")
    print("^2[Clothing] Player " .. source .. " purchased outfit ($" .. Config.Price .. ")^7")
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- LOAD CLOTHING ON SPAWN
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('my_clothing:requestClothing')
AddEventHandler('my_clothing:requestClothing', function()
    local source = source

    local clothing = exports['my_datamanager']:GetPlayerDataKey(source, 'clothing')
    if clothing then
        TriggerClientEvent('my_clothing:loadClothing', source, clothing)
        print("^2[Clothing] Loaded clothing for player " .. source .. "^7")
    end
end)

print("^2[Clothing] Clothing shop server loaded^7")
