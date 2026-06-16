-- Inventory Server
-- Stores player inventory in saved_data via my_datamanager (key: 'inventory')
-- Data structure: { "item_name" = quantity, ... }

-- ============================================================
-- Internal helpers
-- ============================================================

local function GetInventory(_source)
    local data = exports['my_datamanager']:GetPlayerDataKey(_source, 'inventory')
    if not data then
        data = {}
        exports['my_datamanager']:SetPlayerDataKey(_source, 'inventory', data)
    end
    return data
end

local function SaveInventory(_source, data)
    exports['my_datamanager']:SetPlayerDataKey(_source, 'inventory', data)
end

local function GetItemConfig(itemName)
    for _, item in ipairs(Config.Items) do
        if item.name == itemName then return item end
    end
    return nil
end

-- Build a rich item list for the UI (only items the player actually has)
local function BuildItemList(_source)
    local inv = GetInventory(_source)
    local items = {}
    for _, cfg in ipairs(Config.Items) do
        local qty = inv[cfg.name]
        if qty and qty > 0 then
            table.insert(items, {
                name     = cfg.name,
                label    = cfg.label,
                category = cfg.category,
                usable   = cfg.usable,
                quantity = qty
            })
        end
    end
    return items
end

-- ============================================================
-- Client requests
-- ============================================================

RegisterNetEvent('my_inventory:requestData')
AddEventHandler('my_inventory:requestData', function()
    local _source = source
    local items = BuildItemList(_source)
    TriggerClientEvent('my_inventory:openMenu', _source, {
        items = items,
        categories = Config.Categories
    })
end)

RegisterNetEvent('my_inventory:useItem')
AddEventHandler('my_inventory:useItem', function(itemName)
    local _source = source
    local cfg = GetItemConfig(itemName)
    if not cfg then
        TriggerClientEvent('my_inventory:notify', _source, '~r~Unknown item.')
        return
    end
    if not cfg.usable then
        TriggerClientEvent('my_inventory:notify', _source, '~r~This item cannot be used.')
        return
    end

    local inv = GetInventory(_source)
    if not inv[itemName] or inv[itemName] <= 0 then
        TriggerClientEvent('my_inventory:notify', _source, '~r~You don\'t have any ' .. cfg.label)
        return
    end

    -- Remove one
    inv[itemName] = inv[itemName] - 1
    if inv[itemName] <= 0 then inv[itemName] = nil end
    SaveInventory(_source, inv)

    -- Trigger a global event so any script can listen for item usage
    TriggerEvent('my_inventory:onItemUsed', _source, itemName)
    TriggerClientEvent('my_inventory:onItemUsed', _source, itemName)

    -- Special handling for armor item
    if itemName == 'armor' then
        TriggerClientEvent('my_inventory:applyArmor', _source)
    end

    TriggerClientEvent('my_inventory:notify', _source, '~g~Used ' .. cfg.label)

    -- Send updated list
    local items = BuildItemList(_source)
    TriggerClientEvent('my_inventory:updateItems', _source, items)
end)

RegisterNetEvent('my_inventory:deleteItem')
AddEventHandler('my_inventory:deleteItem', function(itemName)
    local _source = source
    local cfg = GetItemConfig(itemName)
    if not cfg then
        TriggerClientEvent('my_inventory:notify', _source, '~r~Unknown item.')
        return
    end

    local inv = GetInventory(_source)
    if not inv[itemName] or inv[itemName] <= 0 then
        TriggerClientEvent('my_inventory:notify', _source, '~r~You don\'t have any ' .. cfg.label)
        return
    end

    local quantity = inv[itemName]
    -- Remove all of this item
    inv[itemName] = nil
    SaveInventory(_source, inv)

    TriggerClientEvent('my_inventory:notify', _source, '~r~Deleted ' .. quantity .. 'x ' .. cfg.label)

    -- Send updated list
    local items = BuildItemList(_source)
    TriggerClientEvent('my_inventory:updateItems', _source, items)
end)

-- ============================================================
-- Exports for other scripts
-- ============================================================

-- Add item(s) to a player's inventory
exports('AddItem', function(_source, itemName, amount)
    amount = tonumber(amount) or 1
    if amount < 1 then return false end
    local inv = GetInventory(_source)
    inv[itemName] = (inv[itemName] or 0) + amount
    SaveInventory(_source, inv)
    return true
end)

-- Add multiple items in a single read-modify-write cycle (prevents race conditions)
exports('AddItems', function(_source, items)
    if not items or #items == 0 then return false end
    local inv = GetInventory(_source)
    for _, entry in ipairs(items) do
        local itemName = entry.name or entry[1]
        local amount = tonumber(entry.amount or entry[2]) or 1
        if amount >= 1 then
            inv[itemName] = (inv[itemName] or 0) + amount
        end
    end
    SaveInventory(_source, inv)
    return true
end)

-- Remove item(s) from a player's inventory
exports('RemoveItem', function(_source, itemName, amount)
    amount = tonumber(amount) or 1
    if amount < 1 then return false end
    local inv = GetInventory(_source)
    if not inv[itemName] or inv[itemName] < amount then
        return false
    end
    inv[itemName] = inv[itemName] - amount
    if inv[itemName] <= 0 then inv[itemName] = nil end
    SaveInventory(_source, inv)
    return true
end)

-- Get quantity of a specific item
exports('GetItemCount', function(_source, itemName)
    local inv = GetInventory(_source)
    return inv[itemName] or 0
end)

-- Get the full inventory table { item = qty, ... }
exports('GetInventory', function(_source)
    return GetInventory(_source)
end)

-- Check if player has at least 'amount' of an item
exports('HasItem', function(_source, itemName, amount)
    amount = amount or 1
    local inv = GetInventory(_source)
    return (inv[itemName] or 0) >= amount
end)

-- Check if player has any items in a given category
exports('HasAnyInCategory', function(_source, category)
    local inv = GetInventory(_source)
    for _, cfg in ipairs(Config.Items) do
        if cfg.category == category and inv[cfg.name] and inv[cfg.name] > 0 then
            return true
        end
    end
    return false
end)

-- Get all items in a category with their quantities
exports('GetCategoryItems', function(_source, category)
    local inv = GetInventory(_source)
    local results = {}
    for _, cfg in ipairs(Config.Items) do
        if cfg.category == category then
            local qty = inv[cfg.name] or 0
            if qty > 0 then
                results[cfg.name] = qty
            end
        end
    end
    return results
end)

-- Get item config (label, category, usable) for a given item name
exports('GetItemConfig', function(itemName)
    return GetItemConfig(itemName)
end)

-- ============================================================
-- Admin command: Give alarm disablers to a player
-- Usage: /givealarm <playerID> [amount]
-- ============================================================
RegisterCommand('givealarm', function(source, args, rawCommand)
    local targetId = tonumber(args[1])
    local amount   = tonumber(args[2]) or 1

    local function Reply(msg)
        if source == 0 then
            print(msg)
        else
            TriggerClientEvent('chatMessage', source, "^3ADMIN^7", "", msg)
        end
    end

    if not targetId then
        Reply("/givealarm <playerID> [amount]  — default amount is 1")
        return
    end

    if amount < 1 then
        Reply("Amount must be at least 1.")
        return
    end

    local targetName = GetPlayerName(targetId)
    if not targetName then
        Reply("Player ID " .. targetId .. " not found.")
        return
    end

    local inv = GetInventory(targetId)
    inv['alarm_disabler'] = (inv['alarm_disabler'] or 0) + amount
    SaveInventory(targetId, inv)

    Reply("Gave " .. amount .. "x Alarm Disabler to " .. targetName .. " (ID: " .. targetId .. ")")
    TriggerClientEvent('my_inventory:notify', targetId, "~g~You received " .. amount .. "x ~w~Alarm Disabler~g~ from an admin.")
end, true) -- ACE restricted

