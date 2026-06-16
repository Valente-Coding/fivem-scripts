-- my_carlot/server.lua
-- Server-side logic for Sandy Shores Car Lot

-- ============================================================
-- DATA
-- ============================================================

local LotData = {
    listings = {},
    salesLog = {},
    pendingPayments = {},
    salesToday = 0,
    lastSaleDate = "",
    nextListingId = 1
}

-- NPC buyer name lists (same pattern as my_usedcars)
local firstMaleNames = {"James","John","Robert","Michael","William","David","Richard","Joseph","Thomas","Christopher","Charles","Daniel","Matthew","Anthony","Mark","Donald","Steven","Paul","Andrew","Joshua","Kenneth","Kevin","Brian","George","Timothy","Ronald","Jason","Edward","Jeffrey","Ryan","Jacob","Gary","Nicholas","Eric","Jonathan","Stephen","Larry","Justin","Scott","Brandon","Benjamin","Samuel","Frank","Gregory","Raymond","Alexander","Patrick","Jack","Dennis","Jerry","Tyler","Aaron","Jose","Henry","Adam","Douglas","Nathan","Peter","Zachary","Kyle"}
local firstFemaleNames = {"Mary","Patricia","Jennifer","Linda","Elizabeth","Barbara","Susan","Jessica","Sarah","Karen","Nancy","Lisa","Betty","Helen","Sandra","Donna","Carol","Ruth","Sharon","Michelle","Laura","Kimberly","Deborah","Dorothy","Amy","Angela","Ashley","Brenda","Emma","Olivia","Cynthia","Marie","Janet","Catherine","Frances","Christine","Samantha","Debra","Rachel","Carolyn","Virginia","Maria","Heather","Diane","Julie","Joyce","Victoria","Kelly","Christina","Joan"}
local lastNames = {"Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis","Rodriguez","Martinez","Hernandez","Lopez","Gonzalez","Wilson","Anderson","Thomas","Taylor","Moore","Jackson","Martin","Lee","Perez","Thompson","White","Harris","Sanchez","Clark","Ramirez","Lewis","Robinson","Walker","Young","Allen","King","Wright","Scott","Torres","Nguyen","Hill","Flores","Green","Adams","Nelson","Baker","Hall","Rivera","Campbell","Mitchell","Carter","Roberts"}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

local function SaveData()
    SaveResourceFile(GetCurrentResourceName(), 'carlot_data.json', json.encode(LotData), -1)
end

local function LoadData()
    local raw = LoadResourceFile(GetCurrentResourceName(), 'carlot_data.json')
    if raw and raw ~= '' then
        local decoded = json.decode(raw)
        if decoded then
            LotData.listings = decoded.listings or {}
            LotData.salesLog = decoded.salesLog or {}
            LotData.pendingPayments = decoded.pendingPayments or {}
            LotData.salesToday = decoded.salesToday or 0
            LotData.lastSaleDate = decoded.lastSaleDate or ""
            LotData.nextListingId = decoded.nextListingId or 1
        end
    end
end

local function GetTodayDate()
    return os.date("%Y-%m-%d")
end

local function ResetDailyCounterIfNeeded()
    local today = GetTodayDate()
    if LotData.lastSaleDate ~= today then
        LotData.salesToday = 0
        LotData.lastSaleDate = today
        SaveData()
    end
end

local function GenerateBuyerName()
    local isMale = math.random(1, 2) == 1
    local first = isMale
        and firstMaleNames[math.random(1, #firstMaleNames)]
        or firstFemaleNames[math.random(1, #firstFemaleNames)]
    local last = lastNames[math.random(1, #lastNames)]
    return first .. " " .. last
end

local function GetListingById(id)
    for i, listing in ipairs(LotData.listings) do
        if listing.id == id then
            return listing, i
        end
    end
    return nil, nil
end

local function GetListingByPlate(plate)
    for i, listing in ipairs(LotData.listings) do
        if listing.plate == plate then
            return listing, i
        end
    end
    return nil, nil
end

local function RemoveListingByIndex(index)
    table.remove(LotData.listings, index)
end

local function FindOnlinePlayerByLicense(license)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local src = tonumber(playerId)
        if src then
            local playerLicense = exports['my_datamanager']:GetPlayerLicense(src)
            if playerLicense == license then
                return src
            end
        end
    end
    return nil
end

local function IsVehicleAlreadyListed(plate)
    for _, listing in ipairs(LotData.listings) do
        if listing.plate == plate then
            return true
        end
    end
    return false
end

-- ============================================================
-- INITIALIZATION
-- ============================================================

CreateThread(function()
    Wait(2000)
    LoadData()
    ResetDailyCounterIfNeeded()
    print("[my_carlot] Loaded " .. #LotData.listings .. " listings, " .. #LotData.salesLog .. " sales in log")
end)

-- ============================================================
-- OWNERSHIP
-- ============================================================

RegisterNetEvent('my_carlot:checkOwnership')
AddEventHandler('my_carlot:checkOwnership', function()
    local _source = source
    local data = exports['my_datamanager']:GetPlayerDataKey(_source, 'dealership')
    local owned = false
    if data and data.carlot then
        owned = true
    end
    TriggerClientEvent('my_carlot:ownershipStatus', _source, owned)
end)

RegisterNetEvent('my_carlot:requestPurchase')
AddEventHandler('my_carlot:requestPurchase', function()
    local _source = source
    local price = Config.Dealership.price

    -- Check if already owned
    local data = exports['my_datamanager']:GetPlayerDataKey(_source, 'dealership')
    if data and data.carlot then
        TriggerClientEvent('my_carlot:purchaseFailure', _source, "You already own this car lot.")
        return
    end

    -- Check cash
    local cash = exports['my_money']:GetMoney(_source, 'cash')
    if cash < price then
        TriggerClientEvent('my_carlot:purchaseFailure', _source, "Not enough money. You need $" .. price .. ".")
        return
    end

    -- Remove money
    local removed = exports['my_money']:RemoveMoney(_source, 'cash', price)
    if not removed then
        TriggerClientEvent('my_carlot:purchaseFailure', _source, "Payment failed. Please try again.")
        return
    end

    -- Save ownership
    local dealershipData = data or {}
    dealershipData.carlot = true
    local saved = exports['my_datamanager']:SetPlayerDataKey(_source, 'dealership', dealershipData)

    if not saved then
        exports['my_money']:AddMoney(_source, 'cash', price)
        TriggerClientEvent('my_carlot:purchaseFailure', _source, "Failed to save purchase. You have been refunded.")
        return
    end

    TriggerClientEvent('my_carlot:purchaseSuccess', _source)
    TriggerClientEvent('my_money:flashMoney', _source, 'cash')
    print("[my_carlot] " .. GetPlayerName(_source) .. " purchased " .. Config.Dealership.name .. " for $" .. price)
end)

-- ============================================================
-- VEHICLE LISTING
-- ============================================================

-- Client requests price preview before listing
RegisterNetEvent('my_carlot:getListingPrice')
AddEventHandler('my_carlot:getListingPrice', function(plate)
    local _source = source
    if not plate or type(plate) ~= 'string' then return end

    plate = string.upper(string.gsub(plate, '%s+', ''))

    -- Check ownership of lot
    local data = exports['my_datamanager']:GetPlayerDataKey(_source, 'dealership')
    if not data or not data.carlot then
        TriggerClientEvent('my_carlot:listingError', _source, "You don't own this car lot.")
        return
    end

    -- Check vehicle ownership
    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    local ownedVehicles = exports['my_vehicles']:GetVehiclesByOwner(license)
    if not ownedVehicles or not ownedVehicles[plate] then
        TriggerClientEvent('my_carlot:listingError', _source, "You don't own this vehicle.")
        return
    end

    -- Check not already listed
    if IsVehicleAlreadyListed(plate) then
        TriggerClientEvent('my_carlot:listingError', _source, "This vehicle is already listed for sale.")
        return
    end

    -- Get market price
    local model = ownedVehicles[plate].model
    local marketPrice = exports['my_dealership']:GetVehiclePrice(model)
    if not marketPrice then
        TriggerClientEvent('my_carlot:listingError', _source, "Cannot determine market value for this vehicle.")
        return
    end

    local salePrice = math.floor(marketPrice * Config.SellPercent)
    local label = exports['my_dealership']:GetVehicleLabel(model) or model

    TriggerClientEvent('my_carlot:showListingConfirm', _source, plate, label, salePrice)
end)

-- Client confirms listing after seeing price
RegisterNetEvent('my_carlot:confirmListVehicle')
AddEventHandler('my_carlot:confirmListVehicle', function(plate)
    local _source = source
    if not plate or type(plate) ~= 'string' then return end

    plate = string.upper(string.gsub(plate, '%s+', ''))

    -- Re-validate everything server-side
    local data = exports['my_datamanager']:GetPlayerDataKey(_source, 'dealership')
    if not data or not data.carlot then
        TriggerClientEvent('my_carlot:listingError', _source, "You don't own this car lot.")
        return
    end

    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    local ownedVehicles = exports['my_vehicles']:GetVehiclesByOwner(license)
    if not ownedVehicles or not ownedVehicles[plate] then
        TriggerClientEvent('my_carlot:listingError', _source, "You don't own this vehicle.")
        return
    end

    if IsVehicleAlreadyListed(plate) then
        TriggerClientEvent('my_carlot:listingError', _source, "This vehicle is already listed.")
        return
    end

    local model = ownedVehicles[plate].model
    local marketPrice = exports['my_dealership']:GetVehiclePrice(model)
    if not marketPrice then
        TriggerClientEvent('my_carlot:listingError', _source, "Cannot determine market value.")
        return
    end

    local salePrice = math.floor(marketPrice * Config.SellPercent)
    local label = exports['my_dealership']:GetVehicleLabel(model) or model

    -- Create listing
    local listing = {
        id = LotData.nextListingId,
        owner = license,
        ownerName = GetPlayerName(_source),
        model = model,
        plate = plate,
        price = salePrice,
        label = label,
        listed_at = os.time()
    }
    table.insert(LotData.listings, listing)
    LotData.nextListingId = LotData.nextListingId + 1
    SaveData()

    TriggerClientEvent('my_carlot:vehicleListed', _source, plate, label, salePrice)
    print("[my_carlot] " .. GetPlayerName(_source) .. " listed " .. label .. " (" .. plate .. ") for $" .. salePrice)
end)

-- ============================================================
-- REMOVE LISTING
-- ============================================================

RegisterNetEvent('my_carlot:removeListing')
AddEventHandler('my_carlot:removeListing', function(listingId)
    local _source = source
    listingId = tonumber(listingId)
    if not listingId then return end

    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    local listing, index = GetListingById(listingId)

    if not listing or listing.owner ~= license then
        TriggerClientEvent('my_carlot:removeResult', _source, false, "Listing not found or not yours.")
        return
    end

    local plate = listing.plate
    RemoveListingByIndex(index)
    SaveData()

    TriggerClientEvent('my_carlot:removeResult', _source, true, nil, plate)
    print("[my_carlot] " .. GetPlayerName(_source) .. " removed listing for " .. listing.label .. " (" .. plate .. ")")
end)

-- ============================================================
-- DATA REQUESTS (for management UI)
-- ============================================================

RegisterNetEvent('my_carlot:requestListings')
AddEventHandler('my_carlot:requestListings', function()
    local _source = source
    local license = exports['my_datamanager']:GetPlayerLicense(_source)

    local myListings = {}
    for _, listing in ipairs(LotData.listings) do
        if listing.owner == license then
            table.insert(myListings, listing)
        end
    end

    local mySales = {}
    for _, sale in ipairs(LotData.salesLog) do
        if sale.owner == license then
            table.insert(mySales, sale)
        end
    end

    TriggerClientEvent('my_carlot:receiveListings', _source, myListings, mySales)
end)

-- ============================================================
-- AUTO-SELL TIMER
-- ============================================================

local function ProcessAutoSales()
    ResetDailyCounterIfNeeded()

    if LotData.salesToday >= Config.MaxSalesPerDay then
        return
    end

    if #LotData.listings == 0 then
        return
    end

    -- Shuffle listings to randomize which sells first
    local shuffled = {}
    for _, l in ipairs(LotData.listings) do
        table.insert(shuffled, l)
    end
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    for _, listing in ipairs(shuffled) do
        if LotData.salesToday >= Config.MaxSalesPerDay then
            break
        end

        if math.random() < Config.SaleChancePerCheck then
            -- This vehicle sells!
            local buyerName = GenerateBuyerName()

            -- Record sale
            local sale = {
                plate = listing.plate,
                model = listing.model,
                label = listing.label,
                price = listing.price,
                buyerName = buyerName,
                sold_at = os.time(),
                owner = listing.owner
            }
            table.insert(LotData.salesLog, sale)

            -- Remove vehicle from registry
            exports['my_vehicles']:RemoveVehicleData(listing.plate)

            -- Remove the listing
            local _, idx = GetListingByPlate(listing.plate)
            if idx then
                RemoveListingByIndex(idx)
            end

            LotData.salesToday = LotData.salesToday + 1

            -- Pay owner (online or pending)
            local ownerSource = FindOnlinePlayerByLicense(listing.owner)
            if ownerSource then
                exports['my_money']:AddMoney(ownerSource, 'cash', listing.price)
                TriggerClientEvent('my_money:flashMoney', ownerSource, 'cash')
                TriggerClientEvent('my_carlot:vehicleSold', ownerSource, listing.label, listing.price, buyerName)
            else
                -- Store pending payment for when owner comes online
                local current = LotData.pendingPayments[listing.owner] or {total = 0, sales = {}}
                current.total = current.total + listing.price
                table.insert(current.sales, {
                    label = listing.label,
                    price = listing.price,
                    buyerName = buyerName
                })
                LotData.pendingPayments[listing.owner] = current
            end

            SaveData()
            print("[my_carlot] AUTO-SALE: " .. listing.label .. " (" .. listing.plate .. ") sold to " .. buyerName .. " for $" .. listing.price)
        end
    end

    SaveData()
end

CreateThread(function()
    Wait(5000) -- Wait for data to load
    while true do
        Wait(Config.SaleCheckInterval * 60 * 1000)
        ProcessAutoSales()
    end
end)

-- ============================================================
-- PENDING PAYMENTS (on player join)
-- ============================================================

RegisterNetEvent('my_carlot:checkPendingPayments')
AddEventHandler('my_carlot:checkPendingPayments', function()
    local _source = source
    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if not license then return end

    -- Clean up orphaned listings: if the player's vehicles no longer exist
    -- in my_vehicles (e.g. after permadeath), remove their stale listings.
    local ownedVehicles = exports['my_vehicles']:GetVehiclesByOwner(license)
    local ownedPlates = {}
    if ownedVehicles then
        for plate, _ in pairs(ownedVehicles) do
            ownedPlates[plate] = true
        end
    end

    local cleaned = false
    for i = #LotData.listings, 1, -1 do
        local listing = LotData.listings[i]
        if listing.owner == license and not ownedPlates[listing.plate] then
            table.remove(LotData.listings, i)
            cleaned = true
        end
    end

    -- If player no longer owns the car lot (character was wiped), clear pending payments
    local dealershipData = exports['my_datamanager']:GetPlayerDataKey(_source, 'dealership')
    local ownsLot = dealershipData and dealershipData.carlot
    if not ownsLot and LotData.pendingPayments[license] then
        LotData.pendingPayments[license] = nil
        cleaned = true
    end

    if cleaned then
        SaveData()
    end

    local pending = LotData.pendingPayments[license]
    if not pending or pending.total <= 0 then return end

    -- Pay the player
    exports['my_money']:AddMoney(_source, 'cash', pending.total)
    TriggerClientEvent('my_money:flashMoney', _source, 'cash')

    -- Notify with details
    TriggerClientEvent('my_carlot:pendingPaymentReceived', _source, pending.total, pending.sales)

    -- Clear pending
    LotData.pendingPayments[license] = nil
    SaveData()

    print("[my_carlot] Paid pending $" .. pending.total .. " to " .. GetPlayerName(_source))
end)

-- Export: remove all listings and pending payments for a given license (called by permadeath)
exports('ResetPlayerData', function(license)
    if not license then return end
    local cleaned = false
    for i = #LotData.listings, 1, -1 do
        if LotData.listings[i].owner == license then
            table.remove(LotData.listings, i)
            cleaned = true
        end
    end
    if LotData.pendingPayments[license] then
        LotData.pendingPayments[license] = nil
        cleaned = true
    end
    if cleaned then
        SaveData()
    end
end)
