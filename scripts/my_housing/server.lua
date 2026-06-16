-- Housing System Server
-- Global state: houses stored in housing_data.json within this resource

local Houses = {}
local HouseInventories = {} -- [houseName] = { items = {}, cash = 0, dirty = 0 }
local HousesLoaded = false
local MarketMultiplier = 1.0
local connectedPlayers = {} -- [source] = license

-- Helper: Format number with commas
local function GroupDigits(amount)
    local formatted = tostring(math.floor(amount))
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Helper: Round price to thousands
local function RoundPriceToThousands(price)
    return math.floor((price + 500) / 1000) * 1000
end

-- Helper: Get player source from license
local function GetSourceFromLicense(license)
    for src, lic in pairs(connectedPlayers) do
        if lic == license then
            return src
        end
    end
    return nil
end

-- Save houses to file
local function SaveHouses()
    local data = json.encode(Houses, {indent = true})
    SaveResourceFile(GetCurrentResourceName(), '../saved_data/housing_data.json', data, -1)
end

-- Save house inventories to file
local function SaveHouseInventories()
    local data = json.encode(HouseInventories, {indent = true})
    SaveResourceFile(GetCurrentResourceName(), '../saved_data/housing_inventory.json', data, -1)
end

-- Load house inventories from file
local function LoadHouseInventories()
    local data = LoadResourceFile(GetCurrentResourceName(), '../saved_data/housing_inventory.json')
    if data and data ~= '' then
        HouseInventories = json.decode(data) or {}
    else
        HouseInventories = {}
        SaveHouseInventories()
    end
end

-- Get or create a house inventory entry
local function GetHouseInventory(houseName)
    if not HouseInventories[houseName] then
        HouseInventories[houseName] = { items = {}, cash = 0, dirty = 0 }
    end
    return HouseInventories[houseName]
end

-- Build storage payload to send to client
local function BuildStoragePayload(_source, houseId, house, houseInv)
    local playerInv = exports['my_inventory']:GetInventory(_source) or {}
    local playerCash = exports['my_money']:GetMoney(_source, 'cash') or 0
    local playerDirty = exports['my_money']:GetMoney(_source, 'dirty') or 0

    return {
        houseId = houseId,
        houseName = house.name,
        houseItems = houseInv.items or {},
        houseCash = houseInv.cash or 0,
        houseDirty = houseInv.dirty or 0,
        playerItems = playerInv,
        playerCash = playerCash,
        playerDirty = playerDirty,
        maxItemStacks = Config.HouseStorage.MaxItemStacks,
        maxCash = Config.HouseStorage.MaxCash,
        maxDirty = Config.HouseStorage.MaxDirty,
    }
end

-- Load houses from file or initialize from config
local function LoadHouses()
    local data = LoadResourceFile(GetCurrentResourceName(), '../saved_data/housing_data.json')

    if data and data ~= '' then
        Houses = json.decode(data) or {}

        -- Check for new houses added to config that don't exist in saved data
        local existingNames = {}
        for _, house in ipairs(Houses) do
            existingNames[house.name] = true
        end

        local addedCount = 0
        for _, house in ipairs(Config.DefaultHouses) do
            if not existingNames[house.name] then
                local roundedPrice = RoundPriceToThousands(house.price)
                table.insert(Houses, {
                    id = #Houses + 1,
                    name = house.name,
                    label = house.label,
                    coords = house.coords,
                    price = roundedPrice,
                    market_value = roundedPrice,
                    value_history = {roundedPrice},
                    owner = nil,
                    owner_name = nil,
                    rented = 0,
                    total_earnings = 0,
                    last_rent_time = 0
                })
                addedCount = addedCount + 1
            end
        end

        if addedCount > 0 then
            SaveHouses()
        end
    else
        -- Initialize from config
        Houses = {}
        for i, house in ipairs(Config.DefaultHouses) do
            local roundedPrice = RoundPriceToThousands(house.price)
            table.insert(Houses, {
                id = i,
                name = house.name,
                label = house.label,
                coords = house.coords,
                price = roundedPrice,
                market_value = roundedPrice,
                value_history = {roundedPrice},
                owner = nil,
                owner_name = nil,
                rented = 0,
                total_earnings = 0,
                last_rent_time = 0
            })
        end

        SaveHouses()
    end

    HousesLoaded = true

    -- Broadcast to already-connected clients (for resource restarts)
    TriggerClientEvent('my_housing:receiveHouses', -1, Houses)
end

-- Initialize
CreateThread(function()
    Wait(1000)
    LoadHouses()
    LoadHouseInventories()
    StartMarketUpdateLoop()
    StartRentCollectionLoop()
end)

-- Market update loop
function StartMarketUpdateLoop()
    CreateThread(function()
        while true do
            Wait(Config.MarketUpdateInterval * 60 * 1000)

            local min = Config.MarketFluctuation.min
            local max = Config.MarketFluctuation.max
            MarketMultiplier = math.random() * (max - min) + min

            UpdateHousePrices()
        end
    end)
end

-- Update all house prices based on market multiplier
function UpdateHousePrices()
    for i, house in ipairs(Houses) do
        local newValue = math.floor(house.price * MarketMultiplier)
        local roundedValue = RoundPriceToThousands(newValue)

        local valueHistory = house.value_history or {house.market_value}
        table.insert(valueHistory, roundedValue)

        while #valueHistory > Config.ValueHistoryPoints do
            table.remove(valueHistory, 1)
        end

        Houses[i].market_value = roundedValue
        Houses[i].value_history = valueHistory
    end

    SaveHouses()
    TriggerClientEvent('my_housing:receiveHouses', -1, Houses)
end

-- Rent collection loop
function StartRentCollectionLoop()
    CreateThread(function()
        while true do
            Wait(60 * 1000) -- Check every minute

            local currentTime = os.time()
            local changed = false

            for i, house in ipairs(Houses) do
                if house.owner and house.rented == 1 and house.last_rent_time > 0 then
                    local timeSinceLastRent = currentTime - house.last_rent_time
                    local rentInterval = Config.RentInterval * 60

                    if timeSinceLastRent >= rentInterval then
                        local rentPrice = RoundPriceToThousands(house.market_value * Config.RentMultiplier)

                        Houses[i].total_earnings = (Houses[i].total_earnings or 0) + rentPrice
                        Houses[i].last_rent_time = currentTime
                        changed = true

                        -- Pay owner if online
                        local ownerSource = GetSourceFromLicense(house.owner)
                        if ownerSource then
                            exports['my_money']:AddMoney(ownerSource, 'cash', rentPrice)
                            TriggerClientEvent('my_housing:rentNotification', ownerSource, rentPrice)
                        end
                    end
                end
            end

            if changed then
                SaveHouses()
            end
        end
    end)
end

-- Player dropped: cleanup tracking
AddEventHandler('playerDropped', function(reason)
    connectedPlayers[source] = nil
end)

-- Player requests houses (initial load)
RegisterNetEvent('my_housing:requestHouses')
AddEventHandler('my_housing:requestHouses', function()
    local _source = source
    local license = exports['my_datamanager']:GetPlayerLicense(_source)

    if license then
        connectedPlayers[_source] = license
    end

    while not HousesLoaded do
        Wait(100)
    end

    TriggerClientEvent('my_housing:receiveHouses', _source, Houses, license)
end)

-- Buy house
RegisterNetEvent('my_housing:buyHouse')
AddEventHandler('my_housing:buyHouse', function(houseId)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then return end

    -- Find house
    local house, index = nil, nil
    for i, h in ipairs(Houses) do
        if h.id == houseId then
            house = h
            index = i
            break
        end
    end

    if not house then
        TriggerClientEvent('my_housing:buyResult', _source, false, 'House not found')
        return
    end

    if house.owner then
        TriggerClientEvent('my_housing:buyResult', _source, false, Config.Notifications.alreadyOwned)
        return
    end

    -- Check house limit
    local ownedCount = 0
    for _, h in ipairs(Houses) do
        if h.owner == license then
            ownedCount = ownedCount + 1
        end
    end

    if ownedCount >= Config.MaxHousesPerPlayer then
        TriggerClientEvent('my_housing:buyResult', _source, false,
            'You have reached the maximum limit of ' .. Config.MaxHousesPerPlayer .. ' houses')
        return
    end

    -- Check cash
    local price = house.market_value
    local cash = exports['my_money']:GetMoney(_source, 'cash')

    if cash < price then
        TriggerClientEvent('my_housing:buyResult', _source, false, Config.Notifications.insufficientFunds)
        return
    end

    -- Remove money
    exports['my_money']:RemoveMoney(_source, 'cash', price)

    -- Update ownership
    Houses[index].owner = license
    Houses[index].owner_name = GetPlayerName(_source) or "Unknown"

    SaveHouses()

    -- Sync with ALL clients
    TriggerClientEvent('my_housing:receiveHouses', -1, Houses)

    TriggerClientEvent('my_housing:buyResult', _source, true)
    TriggerClientEvent('my_housing:notify', _source,
        string.format(Config.Notifications.purchaseSuccess, GroupDigits(price)))
end)

-- Sell house
RegisterNetEvent('my_housing:sellHouse')
AddEventHandler('my_housing:sellHouse', function(houseId)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then return end

    local house, index = nil, nil
    for i, h in ipairs(Houses) do
        if h.id == houseId then
            house = h
            index = i
            break
        end
    end

    if not house then
        TriggerClientEvent('my_housing:sellResult', _source, false, 'House not found')
        return
    end

    if house.owner ~= license then
        TriggerClientEvent('my_housing:sellResult', _source, false, 'You do not own this house')
        return
    end

    local sellPrice = house.market_value

    -- Pay cash
    exports['my_money']:AddMoney(_source, 'cash', sellPrice)

    -- Clear ownership
    Houses[index].owner = nil
    Houses[index].owner_name = nil
    Houses[index].rented = 0
    Houses[index].last_rent_time = 0

    -- Return any stored items/money to the player before clearing storage
    local houseInv = GetHouseInventory(house.name)
    if houseInv then
        -- Return stored items
        for itemName, qty in pairs(houseInv.items or {}) do
            if qty > 0 then
                exports['my_inventory']:AddItem(_source, itemName, qty)
            end
        end
        -- Return stored cash
        if (houseInv.cash or 0) > 0 then
            exports['my_money']:AddMoney(_source, 'cash', houseInv.cash)
        end
        -- Return stored dirty money
        if (houseInv.dirty or 0) > 0 then
            exports['my_money']:AddMoney(_source, 'dirty', houseInv.dirty)
        end
        -- Clear house storage
        HouseInventories[house.name] = nil
        SaveHouseInventories()
    end

    SaveHouses()

    TriggerClientEvent('my_housing:receiveHouses', -1, Houses)

    TriggerClientEvent('my_housing:sellResult', _source, true)
    TriggerClientEvent('my_housing:notify', _source,
        string.format(Config.Notifications.sellSuccess, GroupDigits(sellPrice)))
end)

-- Toggle rent status
RegisterNetEvent('my_housing:toggleRent')
AddEventHandler('my_housing:toggleRent', function(houseId, rentStatus)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then return end

    local house, index = nil, nil
    for i, h in ipairs(Houses) do
        if h.id == houseId then
            house = h
            index = i
            break
        end
    end

    if not house then
        TriggerClientEvent('my_housing:toggleRentResult', _source, false, 'House not found')
        return
    end

    if house.owner ~= license then
        TriggerClientEvent('my_housing:toggleRentResult', _source, false, 'You do not own this house')
        return
    end

    -- If enabling rent, check player has at least one non-rented house
    if rentStatus then
        local hasNonRentedHouse = false
        for _, h in ipairs(Houses) do
            if h.owner == license and (h.rented == 0 or h.rented == false) and h.id ~= houseId then
                hasNonRentedHouse = true
                break
            end
        end

        if not hasNonRentedHouse then
            TriggerClientEvent('my_housing:toggleRentResult', _source, false,
                'You need to own at least one non-rented house before renting another')
            return
        end
    end

    Houses[index].rented = rentStatus and 1 or 0

    if rentStatus then
        Houses[index].last_rent_time = os.time()
        TriggerClientEvent('my_housing:notify', _source, Config.Notifications.rentEnabled)
    else
        Houses[index].last_rent_time = 0
        TriggerClientEvent('my_housing:notify', _source, Config.Notifications.rentDisabled)
    end

    SaveHouses()
    TriggerClientEvent('my_housing:receiveHouses', -1, Houses)
    TriggerClientEvent('my_housing:toggleRentResult', _source, true)
end)

-- Rent house (by another player)
RegisterNetEvent('my_housing:rentHouse')
AddEventHandler('my_housing:rentHouse', function(houseId)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then return end

    local house, index = nil, nil
    for i, h in ipairs(Houses) do
        if h.id == houseId then
            house = h
            index = i
            break
        end
    end

    if not house then
        TriggerClientEvent('my_housing:rentResult', _source, false, 'House not found')
        return
    end

    if not house.owner then
        TriggerClientEvent('my_housing:rentResult', _source, false, 'This house is not available for rent')
        return
    end

    if house.rented == 1 then
        TriggerClientEvent('my_housing:rentResult', _source, false, 'This house is already rented')
        return
    end

    -- Calculate rent price
    local rentPrice = RoundPriceToThousands(house.market_value * Config.RentMultiplier)

    -- Check cash
    local cash = exports['my_money']:GetMoney(_source, 'cash')
    if cash < rentPrice then
        TriggerClientEvent('my_housing:rentResult', _source, false, "You don't have enough cash for the first rent payment")
        return
    end

    -- Deduct first payment
    exports['my_money']:RemoveMoney(_source, 'cash', rentPrice)

    -- Update house
    Houses[index].rented = 1
    Houses[index].last_rent_time = os.time()
    Houses[index].total_earnings = (Houses[index].total_earnings or 0) + rentPrice

    -- Pay owner if online
    local ownerSource = GetSourceFromLicense(house.owner)
    if ownerSource then
        exports['my_money']:AddMoney(ownerSource, 'cash', rentPrice)
        TriggerClientEvent('my_housing:notify', ownerSource,
            string.format(Config.Notifications.rentCollected, GroupDigits(rentPrice)))
    end

    SaveHouses()
    TriggerClientEvent('my_housing:receiveHouses', -1, Houses)

    TriggerClientEvent('my_housing:rentResult', _source, true)
    TriggerClientEvent('my_housing:notify', _source,
        "You rented this house for $" .. GroupDigits(rentPrice) .. " per " .. Config.RentInterval .. " minutes")
end)

-- ============================================================
-- House Storage System
-- ============================================================

-- Helper: find house by id and validate ownership + not rented
local function ValidateStorageAccess(_source, houseId)
    local license = connectedPlayers[_source]
    if not license then return nil, nil, 'Not authenticated' end

    local house, index = nil, nil
    for i, h in ipairs(Houses) do
        if h.id == houseId then
            house = h
            index = i
            break
        end
    end

    if not house then return nil, nil, 'House not found' end
    if house.owner ~= license then return nil, nil, 'You do not own this house' end
    if house.rented == 1 or house.rented == true then return nil, nil, Config.Notifications.storageRented end

    return house, index, nil
end

-- Request house storage data (items + money)
RegisterNetEvent('my_housing:requestStorage')
AddEventHandler('my_housing:requestStorage', function(houseId)
    local _source = source
    local house, _, err = ValidateStorageAccess(_source, houseId)
    if not house then
        TriggerClientEvent('my_housing:notify', _source, err)
        return
    end

    local houseInv = GetHouseInventory(house.name)
    TriggerClientEvent('my_housing:receiveStorage', _source, BuildStoragePayload(_source, houseId, house, houseInv))
end)

-- Deposit item into house storage
RegisterNetEvent('my_housing:depositItem')
AddEventHandler('my_housing:depositItem', function(houseId, itemName, amount)
    local _source = source
    amount = tonumber(amount) or 1
    if amount < 1 then return end

    local house, _, err = ValidateStorageAccess(_source, houseId)
    if not house then
        TriggerClientEvent('my_housing:storageError', _source, err)
        return
    end

    -- Check player has the item
    local playerCount = exports['my_inventory']:GetItemCount(_source, itemName)
    if playerCount < amount then
        TriggerClientEvent('my_housing:storageError', _source, 'You don\'t have enough of that item')
        return
    end

    local houseInv = GetHouseInventory(house.name)

    -- Check max stacks
    local currentStacks = 0
    for _ in pairs(houseInv.items) do currentStacks = currentStacks + 1 end
    if not houseInv.items[itemName] and currentStacks >= Config.HouseStorage.MaxItemStacks then
        TriggerClientEvent('my_housing:storageError', _source, Config.Notifications.storageFull)
        return
    end

    -- Transfer
    local removed = exports['my_inventory']:RemoveItem(_source, itemName, amount)
    if not removed then
        TriggerClientEvent('my_housing:storageError', _source, 'Failed to remove item from inventory')
        return
    end

    houseInv.items[itemName] = (houseInv.items[itemName] or 0) + amount
    SaveHouseInventories()

    -- Refresh storage UI
    TriggerClientEvent('my_housing:receiveStorage', _source, BuildStoragePayload(_source, houseId, house, houseInv))
    TriggerClientEvent('my_housing:notify', _source, 'Deposited item into house storage')
end)

-- Withdraw item from house storage
RegisterNetEvent('my_housing:withdrawItem')
AddEventHandler('my_housing:withdrawItem', function(houseId, itemName, amount)
    local _source = source
    amount = tonumber(amount) or 1
    if amount < 1 then return end

    local house, _, err = ValidateStorageAccess(_source, houseId)
    if not house then
        TriggerClientEvent('my_housing:storageError', _source, err)
        return
    end

    local houseInv = GetHouseInventory(house.name)

    if not houseInv.items[itemName] or houseInv.items[itemName] < amount then
        TriggerClientEvent('my_housing:storageError', _source, 'Not enough of that item in storage')
        return
    end

    -- Transfer to player
    local added = exports['my_inventory']:AddItem(_source, itemName, amount)
    if not added then
        TriggerClientEvent('my_housing:storageError', _source, 'Failed to add item to your inventory')
        return
    end

    houseInv.items[itemName] = houseInv.items[itemName] - amount
    if houseInv.items[itemName] <= 0 then houseInv.items[itemName] = nil end
    SaveHouseInventories()

    -- Refresh storage UI
    TriggerClientEvent('my_housing:receiveStorage', _source, BuildStoragePayload(_source, houseId, house, houseInv))
    TriggerClientEvent('my_housing:notify', _source, 'Withdrew item from house storage')
end)

-- Deposit money into house storage
RegisterNetEvent('my_housing:depositMoney')
AddEventHandler('my_housing:depositMoney', function(houseId, moneyType, amount)
    local _source = source
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    if moneyType ~= 'cash' and moneyType ~= 'dirty' then return end

    local house, _, err = ValidateStorageAccess(_source, houseId)
    if not house then
        TriggerClientEvent('my_housing:storageError', _source, err)
        return
    end

    local houseInv = GetHouseInventory(house.name)
    local maxKey = moneyType == 'cash' and 'MaxCash' or 'MaxDirty'
    local currentAmount = moneyType == 'cash' and (houseInv.cash or 0) or (houseInv.dirty or 0)

    if currentAmount + amount > Config.HouseStorage[maxKey] then
        TriggerClientEvent('my_housing:storageError', _source, 'House storage cannot hold that much money')
        return
    end

    -- Check player has the money
    local playerMoney = exports['my_money']:GetMoney(_source, moneyType)
    if playerMoney < amount then
        TriggerClientEvent('my_housing:storageError', _source, 'You don\'t have enough ' .. moneyType .. ' money')
        return
    end

    -- Transfer
    local removed = exports['my_money']:RemoveMoney(_source, moneyType, amount)
    if not removed then
        TriggerClientEvent('my_housing:storageError', _source, 'Failed to remove money')
        return
    end

    if moneyType == 'cash' then
        houseInv.cash = (houseInv.cash or 0) + amount
    else
        houseInv.dirty = (houseInv.dirty or 0) + amount
    end
    SaveHouseInventories()

    -- Refresh storage UI
    TriggerClientEvent('my_housing:receiveStorage', _source, BuildStoragePayload(_source, houseId, house, houseInv))
    TriggerClientEvent('my_housing:notify', _source, string.format(Config.Notifications.storageDeposit, '$' .. GroupDigits(amount) .. ' ' .. moneyType))
end)

-- Withdraw money from house storage
RegisterNetEvent('my_housing:withdrawMoney')
AddEventHandler('my_housing:withdrawMoney', function(houseId, moneyType, amount)
    local _source = source
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    if moneyType ~= 'cash' and moneyType ~= 'dirty' then return end

    local house, _, err = ValidateStorageAccess(_source, houseId)
    if not house then
        TriggerClientEvent('my_housing:storageError', _source, err)
        return
    end

    local houseInv = GetHouseInventory(house.name)
    local currentAmount = moneyType == 'cash' and (houseInv.cash or 0) or (houseInv.dirty or 0)

    if currentAmount < amount then
        TriggerClientEvent('my_housing:storageError', _source, 'Not enough ' .. moneyType .. ' money in storage')
        return
    end

    -- Transfer to player
    local added = exports['my_money']:AddMoney(_source, moneyType, amount)
    if not added then
        TriggerClientEvent('my_housing:storageError', _source, 'Failed to add money to your wallet')
        return
    end

    if moneyType == 'cash' then
        houseInv.cash = (houseInv.cash or 0) - amount
    else
        houseInv.dirty = (houseInv.dirty or 0) - amount
    end
    SaveHouseInventories()

    -- Refresh storage UI
    TriggerClientEvent('my_housing:receiveStorage', _source, BuildStoragePayload(_source, houseId, house, houseInv))
    TriggerClientEvent('my_housing:notify', _source, string.format(Config.Notifications.storageWithdraw, '$' .. GroupDigits(amount) .. ' ' .. moneyType))
end)

-- ============================================================
-- Rest at House (Energy Replenishment)
-- ============================================================

RegisterNetEvent('my_housing:requestRest')
AddEventHandler('my_housing:requestRest', function(houseId)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then
        TriggerClientEvent('my_housing:restFailure', _source, 'Not authenticated.')
        return
    end

    -- Find the house
    local house = nil
    for _, h in ipairs(Houses) do
        if h.id == houseId then
            house = h
            break
        end
    end

    if not house then
        TriggerClientEvent('my_housing:restFailure', _source, 'House not found.')
        return
    end

    -- Must be the owner
    if house.owner ~= license then
        TriggerClientEvent('my_housing:restFailure', _source, 'You do not own this house.')
        return
    end

    -- Must NOT be rented out
    if house.rented == 1 or house.rented == true then
        TriggerClientEvent('my_housing:restFailure', _source, 'You cannot rest here while the house is rented out.')
        return
    end

    -- Advance time to 8AM using my_time
    local currentTime = exports['my_time']:GetCurrentTime()
    if currentTime then
        local targetDay = currentTime.dayOfWeek

        -- If it's already past (or at) the wake-up hour, advance to the next day
        -- If it's past midnight but before wake-up hour, stay on the same day
        if currentTime.hour >= Config.Rest.WakeUpHour then
            targetDay = targetDay + 1
            if targetDay > 7 then targetDay = 1 end
        end

        exports['my_time']:SetSpecificTime(Config.Rest.WakeUpHour, Config.Rest.WakeUpMinute, targetDay)
    end

    -- Refill player energy
    exports['my_energy']:RefillEnergy(_source)

    -- Send success to client
    TriggerClientEvent('my_housing:restSuccess', _source, house.label)

    print('[my_housing] ' .. GetPlayerName(_source) .. ' rested at ' .. house.label)
end)

-- Console command to add new houses from config
RegisterCommand('addnewhouses', function(source, args, rawCommand)
    if source ~= 0 then
        print("^1[Housing] This command can only be used from the server console^7")
        return
    end

    local existingNames = {}
    for _, house in ipairs(Houses) do
        existingNames[house.name] = true
    end

    local addedCount = 0
    local skippedCount = 0

    for _, house in ipairs(Config.DefaultHouses) do
        if not existingNames[house.name] then
            local roundedPrice = RoundPriceToThousands(house.price)
            table.insert(Houses, {
                id = #Houses + 1,
                name = house.name,
                label = house.label,
                coords = house.coords,
                price = roundedPrice,
                market_value = roundedPrice,
                value_history = {roundedPrice},
                owner = nil,
                owner_name = nil,
                rented = 0,
                total_earnings = 0,
                last_rent_time = 0
            })
            addedCount = addedCount + 1
        else
            skippedCount = skippedCount + 1
        end
    end

    SaveHouses()
    TriggerClientEvent('my_housing:receiveHouses', -1, Houses)

    print(string.format("^2[Housing] ^7Added %d new houses, skipped %d existing houses", addedCount, skippedCount))
end, true)

-- Export: Get all houses owned by a specific license
exports('GetPlayerHouses', function(license)
    local owned = {}
    for _, house in ipairs(Houses) do
        if house.owner == license then
            table.insert(owned, {
                id = house.id,
                label = house.label,
                name = house.name,
                rented = house.rented
            })
        end
    end
    return owned
end)

-- Export: Add an item directly into a house's storage (used by external shops)
exports('AddItemToHouseStorage', function(houseId, license, itemName, amount)
    amount = tonumber(amount) or 1

    local house = nil
    for _, h in ipairs(Houses) do
        if h.id == houseId then
            house = h
            break
        end
    end

    if not house then return false, 'House not found' end
    if house.owner ~= license then return false, 'You do not own this house' end
    if house.rented == 1 or house.rented == true then return false, 'This house is currently rented out' end

    local houseInv = GetHouseInventory(house.name)

    local currentStacks = 0
    for _ in pairs(houseInv.items) do currentStacks = currentStacks + 1 end
    if not houseInv.items[itemName] and currentStacks >= Config.HouseStorage.MaxItemStacks then
        return false, 'House storage is full'
    end

    houseInv.items[itemName] = (houseInv.items[itemName] or 0) + amount
    SaveHouseInventories()

    return true
end)

-- Export: Reset all houses owned by a specific license (used by permadeath)
exports('ResetHousesByOwner', function(license)
    local count = 0
    for i, house in ipairs(Houses) do
        if house.owner == license then
            Houses[i].owner = nil
            Houses[i].owner_name = nil
            Houses[i].rented = 0
            Houses[i].last_rent_time = 0
            -- Clear house inventory
            if HouseInventories[house.name] then
                HouseInventories[house.name] = nil
            end
            count = count + 1
        end
    end
    if count > 0 then
        SaveHouses()
        SaveHouseInventories()
        TriggerClientEvent('my_housing:receiveHouses', -1, Houses)
    end
    return count
end)
