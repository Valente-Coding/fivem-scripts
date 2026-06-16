-- Convenience Store Server

local function GetItemData(itemName)
    for _, item in ipairs(Config.Items) do
        if item.name == itemName then
            return item
        end
    end
    return nil
end

RegisterNetEvent('my_conveniencestore:buyItem')
AddEventHandler('my_conveniencestore:buyItem', function(itemName)
    local _source = source

    local itemData = GetItemData(itemName)
    if not itemData then
        TriggerClientEvent('my_conveniencestore:purchaseDenied', _source, "Invalid item.")
        return
    end

    -- Deduct cash
    local success = exports['my_money']:RemoveMoney(_source, 'cash', itemData.price)
    if not success then
        TriggerClientEvent('my_conveniencestore:purchaseDenied', _source, "Not enough cash! You need $" .. itemData.price .. ".")
        return
    end

    -- Add to inventory
    exports['my_inventory']:AddItem(_source, itemData.name, 1)

    TriggerClientEvent('my_conveniencestore:purchaseSuccess', _source, itemData.label)
    TriggerClientEvent('chatMessage', _source, "^2[Store]^7", "", "You purchased " .. itemData.label .. " for $" .. itemData.price)
end)
