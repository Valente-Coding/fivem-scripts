-- Drug Dealer Server (Custom Framework - No ESX, No Database)
-- Uses: my_datamanager for reputation, my_inventory for items, my_money for dirty money

local repCache = {} -- { [source] = { experience, level } }

-- Get reputation data for a player
local function GetReputation(source)
    if repCache[source] then return repCache[source] end

    local data = exports['my_datamanager']:GetPlayerDataKey(source, 'drugdealer')

    if data and data.level then
        repCache[source] = data
    else
        repCache[source] = { experience = 0, level = 1 }
        exports['my_datamanager']:SetPlayerDataKey(source, 'drugdealer', repCache[source])
    end

    return repCache[source]
end

-- Save reputation data
local function SaveReputation(source)
    if repCache[source] then
        exports['my_datamanager']:SetPlayerDataKey(source, 'drugdealer', repCache[source])
    end
end

-- Calculate level from experience
local function CalculateLevel(experience)
    local level = 1
    for i = 1, Config.Reputation.maxLevel do
        if experience >= Config.Reputation.levelThresholds[i] then
            level = i
        else
            break
        end
    end
    return level
end

-- Get the XP threshold for the next level
local function GetNextLevelXP(level)
    if level >= Config.Reputation.maxLevel then
        return Config.Reputation.levelThresholds[Config.Reputation.maxLevel]
    end
    return Config.Reputation.levelThresholds[level + 1]
end

-- Add experience to a player
local function AddExperience(source, amount)
    local rep = GetReputation(source)
    local oldLevel = rep.level
    rep.experience = rep.experience + amount
    rep.level = CalculateLevel(rep.experience)
    SaveReputation(source)

    if rep.level > oldLevel then
        TriggerClientEvent('my_drugdealer:levelUp', source, rep.level)
    end

    -- Send updated data to client
    local dirtyMoney = exports['my_money']:GetMoney(source, 'dirty')
    TriggerClientEvent('my_drugdealer:updateData', source, {
        level = rep.level,
        experience = rep.experience,
        nextLevelXP = GetNextLevelXP(rep.level),
        dirtyMoney = dirtyMoney
    })
end

-- Find item config by name
local function GetItemConfig(itemName)
    for i = 1, #Config.Items do
        if Config.Items[i].name == itemName then
            return Config.Items[i]
        end
    end
    return nil
end

-- Client requests data to open the menu
RegisterNetEvent('my_drugdealer:requestData')
AddEventHandler('my_drugdealer:requestData', function()
    local _source = source
    local rep = GetReputation(_source)
    local dirtyMoney = exports['my_money']:GetMoney(_source, 'dirty')

    TriggerClientEvent('my_drugdealer:openMenu', _source, {
        items = Config.Items,
        level = rep.level,
        experience = rep.experience,
        nextLevelXP = GetNextLevelXP(rep.level),
        maxLevel = Config.Reputation.maxLevel,
        dirtyMoney = dirtyMoney
    })
end)

-- Buy item from dealer
RegisterNetEvent('my_drugdealer:buyItem')
AddEventHandler('my_drugdealer:buyItem', function(itemName, quantity)
    local _source = source

    -- Validate quantity
    quantity = tonumber(quantity) or 1
    if quantity < 1 then quantity = 1 end
    if quantity > 100 then quantity = 100 end

    -- Find item in config
    local itemConfig = GetItemConfig(itemName)
    if not itemConfig then
        TriggerClientEvent('my_drugdealer:purchaseResult', _source, false, "~r~Item not found")
        return
    end

    -- Check player level
    local rep = GetReputation(_source)
    if rep.level < itemConfig.requiredLevel then
        TriggerClientEvent('my_drugdealer:purchaseResult', _source, false, "~r~You need level " .. itemConfig.requiredLevel)
        return
    end

    -- Calculate total cost
    local totalCost = itemConfig.price * quantity

    -- Check dirty money
    local dirtyMoney = exports['my_money']:GetMoney(_source, 'dirty')
    if dirtyMoney < totalCost then
        TriggerClientEvent('my_drugdealer:purchaseResult', _source, false, "~r~Not enough dirty money")
        return
    end

    -- Remove dirty money
    local removed = exports['my_money']:RemoveMoney(_source, 'dirty', totalCost)
    if not removed then
        TriggerClientEvent('my_drugdealer:purchaseResult', _source, false, "~r~Payment failed")
        return
    end

    -- Add items to inventory
    exports['my_inventory']:AddItem(_source, itemName, quantity)

    -- Add experience
    AddExperience(_source, Config.Reputation.experiencePerPurchase * quantity)

    -- Notify
    local label = quantity > 1 and (quantity .. "x " .. itemConfig.label) or itemConfig.label
    TriggerClientEvent('my_drugdealer:purchaseResult', _source, true, "~g~Bought " .. label .. " for ~s~$" .. totalCost)
end)

-- Buy bulk (all large packages at once) - Level 5 only
RegisterNetEvent('my_drugdealer:buyBulk')
AddEventHandler('my_drugdealer:buyBulk', function(quantity)
    local _source = source

    -- Validate quantity
    quantity = tonumber(quantity) or 1
    if quantity < 1 then quantity = 1 end
    if quantity > 100 then quantity = 100 end

    -- Check player level (must be 5)
    local rep = GetReputation(_source)
    if rep.level < 5 then
        TriggerClientEvent('my_drugdealer:purchaseResult', _source, false, "~r~You need level 5 for bulk orders")
        return
    end

    -- Find large drug configs
    local largeWeed = GetItemConfig('large_weed')
    local largeCocaine = GetItemConfig('large_cocaine')
    local largeMeth = GetItemConfig('large_meth')

    if not largeWeed or not largeCocaine or not largeMeth then
        TriggerClientEvent('my_drugdealer:purchaseResult', _source, false, "~r~Bulk order items not available")
        return
    end

    -- Calculate total cost
    local totalCost = (largeWeed.price + largeCocaine.price + largeMeth.price) * quantity

    -- Check dirty money
    local dirtyMoney = exports['my_money']:GetMoney(_source, 'dirty')
    if dirtyMoney < totalCost then
        TriggerClientEvent('my_drugdealer:purchaseResult', _source, false, "~r~Not enough dirty money")
        return
    end

    -- Remove dirty money
    local removed = exports['my_money']:RemoveMoney(_source, 'dirty', totalCost)
    if not removed then
        TriggerClientEvent('my_drugdealer:purchaseResult', _source, false, "~r~Payment failed")
        return
    end

    -- Add all items to inventory
    exports['my_inventory']:AddItem(_source, 'large_weed', quantity)
    exports['my_inventory']:AddItem(_source, 'large_cocaine', quantity)
    exports['my_inventory']:AddItem(_source, 'large_meth', quantity)

    -- Add experience (3x quantity since buying 3 items)
    AddExperience(_source, Config.Reputation.experiencePerPurchase * quantity * 3)

    -- Notify
    TriggerClientEvent('my_drugdealer:purchaseResult', _source, true, 
        "~g~Bulk order complete! ~s~" .. quantity .. "x of each large package for $" .. totalCost)
end)

-- Clear cache on disconnect
AddEventHandler('playerDropped', function()
    local _source = source
    repCache[_source] = nil
end)

-- =====================
-- EXPORTS for my_drugselling and other scripts
-- =====================

-- Check if player has any drug items
exports('HasAnyDrugs', function(source)
    for _, item in ipairs(Config.Items) do
        local count = exports['my_inventory']:GetItemCount(source, item.name)
        if count and count > 0 then
            return true
        end
    end
    return false
end)

-- Get player's drug inventory { [name] = count }
exports('GetPlayerDrugInventory', function(source)
    local drugInv = {}
    for _, item in ipairs(Config.Items) do
        local count = exports['my_inventory']:GetItemCount(source, item.name)
        if count and count > 0 then
            drugInv[item.name] = count
        end
    end
    return drugInv
end)

-- Get all drug item configs
exports('GetDrugItems', function()
    return Config.Items
end)

-- Remove a drug from player inventory
exports('RemoveDrugFromInventory', function(source, itemName, amount)
    amount = amount or 1
    local count = exports['my_inventory']:GetItemCount(source, itemName)
    if count and count >= amount then
        return exports['my_inventory']:RemoveItem(source, itemName, amount)
    end
    return false
end)

-- Get player reputation data
exports('GetReputation', function(source)
    return GetReputation(source)
end)

-- Export: Reset player drug dealer reputation (used by permadeath wipe)
exports('ResetPlayerData', function(source)
    repCache[source] = { experience = 0, level = 1 }
    exports['my_datamanager']:SetPlayerDataKey(source, 'drugdealer', repCache[source])
end)

