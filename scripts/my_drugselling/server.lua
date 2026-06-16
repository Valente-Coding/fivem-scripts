-- Drug Selling Server
-- Uses my_drugdealer exports for inventory management

local function getDrugType(drugName)
    if string.find(drugName, "weed") then return "weed"
    elseif string.find(drugName, "cocaine") then return "cocaine"
    elseif string.find(drugName, "meth") then return "meth"
    else return "weed" end
end

-- Check if player has drugs
RegisterNetEvent('my_drugselling:checkDrugs')
AddEventHandler('my_drugselling:checkDrugs', function()
    local _source = source
    local hasDrugs = exports['my_drugdealer']:HasAnyDrugs(_source)
    TriggerClientEvent('my_drugselling:drugCheckResult', _source, hasDrugs)
end)

-- Sell a random drug from inventory
RegisterNetEvent('my_drugselling:sellDrug')
AddEventHandler('my_drugselling:sellDrug', function()
    local _source = source

    local inventory = exports['my_drugdealer']:GetPlayerDrugInventory(_source)
    if not inventory then
        TriggerClientEvent('my_drugselling:saleComplete', _source, { hasDrugsLeft = false })
        return
    end

    -- Find available drugs
    local availableDrugs = {}
    local drugItems = exports['my_drugdealer']:GetDrugItems()
    for _, item in ipairs(drugItems) do
        if inventory[item.name] and inventory[item.name] > 0 then
            table.insert(availableDrugs, item)
        end
    end

    if #availableDrugs == 0 then
        TriggerClientEvent('my_drugselling:saleComplete', _source, { hasDrugsLeft = false })
        return
    end

    -- Pick random drug to sell
    local selectedDrug = availableDrugs[math.random(#availableDrugs)]

    -- Remove from inventory via drugdealer export
    local removed = exports['my_drugdealer']:RemoveDrugFromInventory(_source, selectedDrug.name, 1)
    if not removed then
        TriggerClientEvent('my_drugselling:saleComplete', _source, { hasDrugsLeft = false })
        return
    end

    -- Pay player in dirty money (sell price from config)
    local sellPrice = selectedDrug.sellPrice or (selectedDrug.price * 2)
    exports['my_money']:AddMoney(_source, 'dirty', sellPrice)

    -- Check if player still has drugs
    local stillHasDrugs = exports['my_drugdealer']:HasAnyDrugs(_source)

    -- Police alert chance
    local drugType = getDrugType(selectedDrug.name)
    local alertChance = Config.WantedLevelChance[drugType] or 10
    local wantedLevel = Config.WantedLevelStars[drugType] or 1
    local policeAlerted = (math.random(100) <= alertChance)

    TriggerClientEvent('chatMessage', _source, "^5[DrugSale]^7", "",
        "Sold " .. (selectedDrug.label or selectedDrug.name) .. " for $" .. sellPrice .. " dirty money")

    TriggerClientEvent('my_drugselling:saleComplete', _source, {
        hasDrugsLeft = stillHasDrugs,
        drugSold = selectedDrug.name,
        saleAmount = sellPrice,
        policeAlerted = policeAlerted,
        drugType = drugType,
        wantedLevel = wantedLevel
    })
end)

