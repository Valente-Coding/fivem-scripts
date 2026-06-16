-- Drug Distributors Server
-- Data structure in datamanager 'drugdistributors' key:
-- { distributorCount = 0, inventory = { large_weed = { amount = 0, profit = 0 }, ... } }

local function GetDistributorData(_source)
    local data = exports['my_datamanager']:GetPlayerDataKey(_source, 'drugdistributors')
    if not data or data.distributorCount == nil then
        data = { distributorCount = 0, inventory = {} }
        for _, drugType in ipairs(Config.DrugTypes) do
            data.inventory[drugType] = { amount = 0, profit = 0 }
        end
        exports['my_datamanager']:SetPlayerDataKey(_source, 'drugdistributors', data)
    end
    -- Ensure all drug types exist
    if not data.inventory then data.inventory = {} end
    for _, drugType in ipairs(Config.DrugTypes) do
        if not data.inventory[drugType] then
            data.inventory[drugType] = { amount = 0, profit = 0 }
        end
    end
    return data
end

local function SaveDistributorData(_source, data)
    exports['my_datamanager']:SetPlayerDataKey(_source, 'drugdistributors', data)
end

local function GetDealerLevel(_source)
    -- Use my_drugdealer's data via datamanager
    local dealerData = exports['my_datamanager']:GetPlayerDataKey(_source, 'drugdealer')
    if dealerData and dealerData.level then
        return dealerData.level
    end
    return 0
end

local function UpdateClientData(_source)
    local data = GetDistributorData(_source)
    local dirtyMoney = exports['my_money']:GetMoney(_source, 'dirty')
    TriggerClientEvent('my_drugdistributors:updateData', _source, {
        distributorCount = data.distributorCount,
        inventory = data.inventory,
        dirtyMoney = dirtyMoney
    })
end

-- Request data to open menu
RegisterNetEvent('my_drugdistributors:requestData')
AddEventHandler('my_drugdistributors:requestData', function()
    local _source = source

    -- Check drug dealer level
    local level = GetDealerLevel(_source)
    if level < Config.RequiredDrugDealerLevel then
        TriggerClientEvent('my_drugdistributors:showNotification', _source,
            '~r~You need drug dealer level ' .. Config.RequiredDrugDealerLevel .. ' to hire distributors.')
        return
    end

    local data = GetDistributorData(_source)
    local dirtyMoney = exports['my_money']:GetMoney(_source, 'dirty')

    TriggerClientEvent('my_drugdistributors:openMenu', _source, {
        distributorCount = data.distributorCount,
        inventory = data.inventory,
        dirtyMoney = dirtyMoney
    })
end)

-- Hire distributor (costs dirty money)
RegisterNetEvent('my_drugdistributors:hireDistributor')
AddEventHandler('my_drugdistributors:hireDistributor', function()
    local _source = source
    local data = GetDistributorData(_source)

    if data.distributorCount >= Config.MaxDistributors then
        TriggerClientEvent('my_drugdistributors:showNotification', _source,
            '~r~Maximum distributors reached (' .. Config.MaxDistributors .. ')')
        return
    end

    local success = exports['my_money']:RemoveMoney(_source, 'dirty', Config.DistributorHireCost)
    if not success then
        TriggerClientEvent('my_drugdistributors:showNotification', _source,
            '~r~Not enough dirty money ($' .. Config.DistributorHireCost .. ' needed)')
        return
    end

    data.distributorCount = data.distributorCount + 1
    SaveDistributorData(_source, data)

    TriggerClientEvent('my_drugdistributors:showNotification', _source,
        '~g~Hired a new distributor for $' .. Config.DistributorHireCost)
    UpdateClientData(_source)
end)

-- Fire distributor
RegisterNetEvent('my_drugdistributors:fireDistributor')
AddEventHandler('my_drugdistributors:fireDistributor', function()
    local _source = source
    local data = GetDistributorData(_source)

    if data.distributorCount <= 0 then
        TriggerClientEvent('my_drugdistributors:showNotification', _source, '~r~No distributors to fire')
        return
    end

    data.distributorCount = data.distributorCount - 1
    SaveDistributorData(_source, data)

    TriggerClientEvent('my_drugdistributors:showNotification', _source, '~y~Fired one distributor')
    UpdateClientData(_source)
end)

-- Deposit drugs from player's drug inventory to distributors
RegisterNetEvent('my_drugdistributors:depositDrugs')
AddEventHandler('my_drugdistributors:depositDrugs', function(drugType, amount)
    local _source = source
    amount = tonumber(amount) or 1
    if amount < 1 then amount = 1 end

    -- Validate drug type
    local valid = false
    for _, dt in ipairs(Config.DrugTypes) do
        if dt == drugType then valid = true break end
    end
    if not valid then return end

    local data = GetDistributorData(_source)
    if data.distributorCount <= 0 then
        TriggerClientEvent('my_drugdistributors:showNotification', _source, '~r~No distributors to give drugs to')
        return
    end

    -- Check player's drug inventory via my_drugdealer
    local playerInventory = exports['my_drugdealer']:GetPlayerDrugInventory(_source)
    local available = (playerInventory and playerInventory[drugType]) or 0

    if available <= 0 then
        TriggerClientEvent('my_drugdistributors:showNotification', _source, '~r~You have no ' .. drugType .. ' to deposit')
        return
    end

    if amount > available then amount = available end

    -- Remove from player inventory
    local removed = exports['my_drugdealer']:RemoveDrugFromInventory(_source, drugType, amount)
    if not removed then
        TriggerClientEvent('my_drugdistributors:showNotification', _source, '~r~Failed to remove drugs')
        return
    end

    -- Add to distributor inventory
    data.inventory[drugType].amount = data.inventory[drugType].amount + amount
    SaveDistributorData(_source, data)

    local label = drugType:gsub("^large_", "Large ")
    TriggerClientEvent('my_drugdistributors:showNotification', _source,
        '~g~Deposited ' .. amount .. ' ' .. label .. ' packages')
    UpdateClientData(_source)
end)

-- Deposit all large drugs
RegisterNetEvent('my_drugdistributors:depositAllDrugs')
AddEventHandler('my_drugdistributors:depositAllDrugs', function()
    local _source = source
    local data = GetDistributorData(_source)

    if data.distributorCount <= 0 then
        TriggerClientEvent('my_drugdistributors:showNotification', _source, '~r~No distributors to give drugs to')
        return
    end

    local playerInventory = exports['my_drugdealer']:GetPlayerDrugInventory(_source)
    if not playerInventory then
        TriggerClientEvent('my_drugdistributors:showNotification', _source, '~r~No drugs to deposit')
        return
    end

    local totalDeposited = 0
    for _, drugType in ipairs(Config.DrugTypes) do
        local available = playerInventory[drugType] or 0
        if available > 0 then
            local removed = exports['my_drugdealer']:RemoveDrugFromInventory(_source, drugType, available)
            if removed then
                data.inventory[drugType].amount = data.inventory[drugType].amount + available
                totalDeposited = totalDeposited + available
            end
        end
    end

    if totalDeposited > 0 then
        SaveDistributorData(_source, data)
        TriggerClientEvent('my_drugdistributors:showNotification', _source,
            '~g~Deposited ' .. totalDeposited .. ' total packages')
    else
        TriggerClientEvent('my_drugdistributors:showNotification', _source, '~r~No large drug packages to deposit')
    end
    UpdateClientData(_source)
end)

-- Withdraw drugs back to player
RegisterNetEvent('my_drugdistributors:withdrawDrugs')
AddEventHandler('my_drugdistributors:withdrawDrugs', function(drugType, amount)
    local _source = source
    amount = tonumber(amount) or 1
    if amount < 1 then amount = 1 end

    local valid = false
    for _, dt in ipairs(Config.DrugTypes) do
        if dt == drugType then valid = true break end
    end
    if not valid then return end

    local data = GetDistributorData(_source)
    local available = data.inventory[drugType].amount or 0

    if available <= 0 then
        TriggerClientEvent('my_drugdistributors:showNotification', _source, '~r~No drugs to withdraw')
        return
    end

    if amount > available then amount = available end

    -- Remove from distributor inventory
    data.inventory[drugType].amount = data.inventory[drugType].amount - amount

    -- Add back to player's inventory via my_inventory
    exports['my_inventory']:AddItem(_source, drugType, amount)

    SaveDistributorData(_source, data)

    local label = drugType:gsub("^large_", "Large ")
    TriggerClientEvent('my_drugdistributors:showNotification', _source,
        '~g~Withdrew ' .. amount .. ' ' .. label .. ' packages')
    UpdateClientData(_source)
end)

-- Withdraw profits as dirty money
RegisterNetEvent('my_drugdistributors:withdrawProfit')
AddEventHandler('my_drugdistributors:withdrawProfit', function()
    local _source = source
    local data = GetDistributorData(_source)

    local totalProfit = 0
    for _, drugType in ipairs(Config.DrugTypes) do
        totalProfit = totalProfit + (data.inventory[drugType].profit or 0)
    end

    if totalProfit <= 0 then
        TriggerClientEvent('my_drugdistributors:showNotification', _source, '~r~No profits to withdraw')
        return
    end

    -- Add dirty money
    exports['my_money']:AddMoney(_source, 'dirty', totalProfit)

    -- Reset profits
    for _, drugType in ipairs(Config.DrugTypes) do
        data.inventory[drugType].profit = 0
    end
    SaveDistributorData(_source, data)

    TriggerClientEvent('my_drugdistributors:showNotification', _source,
        '~g~Withdrew $' .. totalProfit .. ' in profits')
    UpdateClientData(_source)
end)

-- Auto-sell timer: distributors sell drugs periodically
CreateThread(function()
    while true do
        Wait(Config.DistributorSellInterval)

        -- Get all online players
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local pid = tonumber(playerId)
            if pid then
                local data = GetDistributorData(pid)
                if data.distributorCount > 0 then
                    local drugItems = exports['my_drugdealer']:GetDrugItems()
                    local totalSold = 0
                    local totalEarned = 0

                    for _, drugType in ipairs(Config.DrugTypes) do
                        local available = data.inventory[drugType].amount or 0
                        local toSell = math.min(Config.DistributorSellAmount * data.distributorCount, available)

                        if toSell > 0 then
                            -- Get sell price from drugdealer config
                            local sellPrice = 0
                            if drugItems then
                                for _, item in ipairs(drugItems) do
                                    if item.name == drugType then
                                        sellPrice = item.sellPrice or (item.price * 2)
                                        break
                                    end
                                end
                            end

                            -- Fallback prices
                            if sellPrice == 0 then
                                if drugType == "large_weed" then sellPrice = 400
                                elseif drugType == "large_cocaine" then sellPrice = 1200
                                elseif drugType == "large_meth" then sellPrice = 3000
                                end
                            end

                            -- Calculate profit (distributor takes their cut)
                            local profit = math.floor(toSell * sellPrice * (1 - Config.DistributorCutPercentage / 100))

                            data.inventory[drugType].amount = data.inventory[drugType].amount - toSell
                            data.inventory[drugType].profit = data.inventory[drugType].profit + profit

                            totalSold = totalSold + toSell
                            totalEarned = totalEarned + profit
                        end
                    end

                    if totalSold > 0 then
                        TriggerClientEvent('my_drugdistributors:showNotification', pid,
                            '~p~Distributors sold ' .. totalSold .. ' packages for $' .. totalEarned)
                    end

                    SaveDistributorData(pid, data)
                    UpdateClientData(pid)
                end
            end
        end
    end
end)

