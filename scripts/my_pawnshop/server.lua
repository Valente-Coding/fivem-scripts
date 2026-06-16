-- Pawn Shop Server
-- Handles selling pawn items and re-adding items when "used" from inventory

-- ============================================================
-- Helpers
-- ============================================================

local function GetPawnItem(itemName)
    return Config.ItemLookup[itemName]
end

--- Determine which shop should buy this item based on price
local function GetShopForItem(itemName)
    local pawnItem = GetPawnItem(itemName)
    if not pawnItem then return nil end

    for _, loc in ipairs(Config.Locations) do
        if pawnItem.price <= loc.maxPrice then
            -- low-end shop handles items up to 50K
            -- if item price > low maxPrice, skip to next (high-end)
            if loc.type == "low" and pawnItem.price <= loc.maxPrice then
                return loc
            elseif loc.type == "high" then
                return loc
            end
        end
    end
    return nil
end

-- ============================================================
-- Item Use Handler  (re-add item + set waypoint)
-- When a pawn item is "used" from inventory, it gets consumed.
-- We immediately give it back and tell the client to set a waypoint.
-- ============================================================

RegisterNetEvent('my_inventory:onItemUsed')
AddEventHandler('my_inventory:onItemUsed', function(_source, itemName)
    local pawnItem = GetPawnItem(itemName)
    if not pawnItem then return end -- not a pawn item, ignore

    -- Re-add the item so it isn't consumed
    exports['my_inventory']:AddItem(_source, itemName, 1)

    -- Refresh inventory UI if it's open
    TriggerClientEvent('my_inventory:updateItems', _source, nil)

    -- Find the correct shop for this item
    local shop = GetShopForItem(itemName)
    if shop then
        TriggerClientEvent('my_pawnshop:setWaypoint', _source, shop.coords.x, shop.coords.y, shop.name, pawnItem.label, pawnItem.price)
    end
end)

-- ============================================================
-- Request sell list  (player opened shop UI)
-- ============================================================

RegisterNetEvent('my_pawnshop:requestSellList')
AddEventHandler('my_pawnshop:requestSellList', function(shopType)
    local _source = source
    local inv = exports['my_inventory']:GetInventory(_source)
    if not inv then inv = {} end

    -- Find the shop config for this type
    local shopConfig = nil
    for _, loc in ipairs(Config.Locations) do
        if loc.type == shopType then
            shopConfig = loc
            break
        end
    end

    if not shopConfig then return end

    -- Build list of items the player has that this shop will buy
    local sellableItems = {}
    for _, pawnItem in ipairs(Config.Items) do
        local qty = inv[pawnItem.name]
        if qty and qty > 0 then
            -- Low-end shop: only items with price <= maxPrice
            -- High-end shop: only items with price > low-end maxPrice
            local canSell = false
            if shopType == "low" then
                canSell = (pawnItem.price <= shopConfig.maxPrice)
            elseif shopType == "high" then
                canSell = (pawnItem.price > 50000) -- items above 50K go to high-end
            end

            if canSell then
                table.insert(sellableItems, {
                    name     = pawnItem.name,
                    label    = pawnItem.label,
                    price    = pawnItem.price,
                    quantity = qty,
                })
            end
        end
    end

    TriggerClientEvent('my_pawnshop:openShop', _source, {
        items    = sellableItems,
        shopName = shopConfig.name,
        shopType = shopType,
    })
end)

-- ============================================================
-- Sell Item
-- ============================================================

RegisterNetEvent('my_pawnshop:sellItem')
AddEventHandler('my_pawnshop:sellItem', function(itemName, shopType)
    local _source = source

    -- Validate item exists in pawn config
    local pawnItem = GetPawnItem(itemName)
    if not pawnItem then
        TriggerClientEvent('my_pawnshop:sellDenied', _source, "Invalid item.")
        return
    end

    -- Validate shop type and price range
    if shopType == "low" and pawnItem.price > 50000 then
        TriggerClientEvent('my_pawnshop:sellDenied', _source, "This shop doesn't buy items that valuable.")
        return
    end
    if shopType == "high" and pawnItem.price <= 50000 then
        TriggerClientEvent('my_pawnshop:sellDenied', _source, "This shop doesn't deal in items this cheap.")
        return
    end

    -- Check player has the item
    local hasItem = exports['my_inventory']:HasItem(_source, itemName, 1)
    if not hasItem then
        TriggerClientEvent('my_pawnshop:sellDenied', _source, "You don't have that item.")
        return
    end

    -- Remove item from inventory
    local removed = exports['my_inventory']:RemoveItem(_source, itemName, 1)
    if not removed then
        TriggerClientEvent('my_pawnshop:sellDenied', _source, "Failed to remove item.")
        return
    end

    -- Give cash to player
    exports['my_money']:AddMoney(_source, 'cash', pawnItem.price)

    TriggerClientEvent('my_pawnshop:sellSuccess', _source, pawnItem.label, pawnItem.price)

    -- Send updated sell list
    -- Re-trigger the request internally
    local inv = exports['my_inventory']:GetInventory(_source)
    if not inv then inv = {} end

    local shopConfig = nil
    for _, loc in ipairs(Config.Locations) do
        if loc.type == shopType then
            shopConfig = loc
            break
        end
    end

    if shopConfig then
        local sellableItems = {}
        for _, pi in ipairs(Config.Items) do
            local qty = inv[pi.name]
            if qty and qty > 0 then
                local canSell = false
                if shopType == "low" then
                    canSell = (pi.price <= shopConfig.maxPrice)
                elseif shopType == "high" then
                    canSell = (pi.price > 50000)
                end
                if canSell then
                    table.insert(sellableItems, {
                        name     = pi.name,
                        label    = pi.label,
                        price    = pi.price,
                        quantity = qty,
                    })
                end
            end
        end
        TriggerClientEvent('my_pawnshop:updateItems', _source, sellableItems)
    end
end)
