-- Used Cars Marketplace Server
-- All data stored in usedcars_data.json (listings + offers)
-- Uses my_vehicles, my_dealership, my_money, my_licenses exports

-- Check if player has a driving license before allowing app access
RegisterNetEvent('my_usedcars:checkDrivingLicense')
AddEventHandler('my_usedcars:checkDrivingLicense', function()
    local _source = source
    local hasDriving = exports['my_licenses']:hasLicense(_source, 'driving')
    TriggerClientEvent('my_usedcars:drivingLicenseResult', _source, hasDriving)
end)

local UsedCarsData = {
    listings = {},       -- Array of listing objects
    offers = {},         -- Array of offer objects
    nextListingId = 1,
    nextOfferId = 1
}

local connectedPlayers = {} -- [source] = { license = "...", name = "..." }
local listOfOriginalPrices = {} -- [model] = price (cached from dealership)
local dealershipVehicles = {} -- Vehicles available for NPC listings

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

-- Generate realistic random mileage (km) based on vehicle price.
-- Expensive vehicles are driven far less in real life.
local function GenerateRandomMileage(price)
    price = tonumber(price) or 50000
    local minKm, maxKm
    if price > 1000000 then
        minKm, maxKm = 200, 5000        -- hyper/exotic: barely driven
    elseif price > 400000 then
        minKm, maxKm = 1000, 12000       -- supercars
    elseif price > 150000 then
        minKm, maxKm = 5000, 30000       -- sports / luxury
    elseif price > 50000 then
        minKm, maxKm = 15000, 65000      -- mid-range
    else
        minKm, maxKm = 30000, 130000     -- economy / daily drivers
    end
    return math.random(minKm * 10, maxKm * 10) / 10 -- one decimal place
end

local function GroupDigits(amount)
    local formatted = tostring(math.floor(amount))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function SaveData()
    SaveResourceFile(GetCurrentResourceName(), 'usedcars_data.json', json.encode(UsedCarsData), -1)
end

local function LoadData()
    local data = LoadResourceFile(GetCurrentResourceName(), 'usedcars_data.json')
    if data and data ~= '' then
        local decoded = json.decode(data)
        if decoded then
            UsedCarsData = decoded
            -- Ensure structure integrity
            UsedCarsData.listings = UsedCarsData.listings or {}
            UsedCarsData.offers = UsedCarsData.offers or {}
            UsedCarsData.nextListingId = UsedCarsData.nextListingId or 1
            UsedCarsData.nextOfferId = UsedCarsData.nextOfferId or 1
            -- Normalize all listing models to lowercase for dealership compatibility
            for _, listing in ipairs(UsedCarsData.listings) do
                if listing.model then
                    listing.model = string.lower(listing.model)
                end
            end
        end
    end
end

local function GeneratePlate()
    local maxAttempts = 100
    local attempts = 0
    
    repeat
        local plate = ""
        local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for i = 1, 3 do
            local rand = math.random(1, #charset)
            plate = plate .. string.sub(charset, rand, rand)
        end
        for i = 1, 3 do
            plate = plate .. math.random(0, 9)
        end
        
        attempts = attempts + 1
        
        -- Check against my_vehicles registry to prevent plate collisions
        local exists = exports['my_vehicles']:DoesPlateExist(plate)
        if not exists then
            return plate
        end
        
        if attempts >= maxAttempts then
            print("^1[my_usedcars ERROR]^7 Failed to generate unique plate after " .. maxAttempts .. " attempts")
            return nil
        end
    until false
end

local function GetListingById(id)
    for i, listing in ipairs(UsedCarsData.listings) do
        if listing.id == id then
            return listing, i
        end
    end
    return nil, nil
end

local function GetOffersForVehicle(vehicleId)
    local result = {}
    for _, offer in ipairs(UsedCarsData.offers) do
        if offer.vehicleId == vehicleId then
            table.insert(result, offer)
        end
    end
    return result
end

local function RemoveOffersForVehicle(vehicleId)
    local newOffers = {}
    for _, offer in ipairs(UsedCarsData.offers) do
        if offer.vehicleId ~= vehicleId then
            table.insert(newOffers, offer)
        end
    end
    UsedCarsData.offers = newOffers
end

local function RemoveOfferById(offerId)
    local newOffers = {}
    for _, offer in ipairs(UsedCarsData.offers) do
        if offer.id ~= offerId then
            table.insert(newOffers, offer)
        end
    end
    UsedCarsData.offers = newOffers
end

local function RemoveListingById(id)
    local newListings = {}
    for _, listing in ipairs(UsedCarsData.listings) do
        if listing.id ~= id then
            table.insert(newListings, listing)
        end
    end
    UsedCarsData.listings = newListings
end

local function CountPlayerListings(license)
    local count = 0
    for _, listing in ipairs(UsedCarsData.listings) do
        if listing.owner == license then
            count = count + 1
        end
    end
    return count
end

local function CountNPCListings()
    local count = 0
    for _, listing in ipairs(UsedCarsData.listings) do
        if listing.owner == nil then
            count = count + 1
        end
    end
    return count
end

local function GetOriginalPrice(model)
    if not model then return nil end
    model = string.lower(model)
    if listOfOriginalPrices[model] then
        return listOfOriginalPrices[model]
    end
    local price = exports['my_dealership']:GetVehiclePrice(model)
    if price then
        listOfOriginalPrices[model] = price
    end
    return price
end

local function GetVehicleLabel(model)
    if not model then return model end
    model = string.lower(model)
    local vehicleData = exports['my_dealership']:GetMultipleVehicleData({model})
    if vehicleData and vehicleData[model] and vehicleData[model].label then
        return vehicleData[model].label
    end
    return model
end

local function EnrichListings(listings)
    -- Add labels and original prices to listings
    local models = {}
    for _, listing in ipairs(listings) do
        table.insert(models, string.lower(listing.model))
    end
    local vehicleData = exports['my_dealership']:GetMultipleVehicleData(models)
    for _, listing in ipairs(listings) do
        local data = vehicleData[string.lower(listing.model)]
        if data then
            listing.label = data.label
            listing.originalPrice = data.price
        else
            listing.label = listing.model
            listing.originalPrice = nil
        end
    end
    return listings
end

-- Name generation for NPC buyers
local listOfFirstMaleNames = {"James", "John", "Robert", "Michael", "William", "David", "Richard", "Joseph", "Thomas", "Christopher", "Charles", "Daniel", "Matthew", "Anthony", "Mark", "Donald", "Steven", "Paul", "Andrew", "Joshua", "Kenneth", "Kevin", "Brian", "George", "Timothy", "Ronald", "Jason", "Edward", "Jeffrey", "Ryan", "Jacob", "Gary", "Nicholas", "Eric", "Jonathan", "Stephen", "Larry", "Justin", "Scott", "Brandon", "Benjamin", "Samuel", "Frank", "Gregory", "Raymond", "Alexander", "Patrick", "Jack", "Dennis", "Jerry", "Tyler", "Aaron", "Jose", "Henry", "Adam", "Douglas", "Nathan", "Peter", "Zachary", "Kyle", "Walter", "Harold", "Jeremy", "Ethan", "Carl", "Arthur", "Roger", "Jordan", "Mason", "Noah", "Wayne", "Ralph", "Roy", "Eugene", "Louis", "Philip", "Bobby", "Sean"}
local listOfFirstFemaleNames = {"Mary", "Patricia", "Jennifer", "Linda", "Elizabeth", "Barbara", "Susan", "Jessica", "Sarah", "Karen", "Nancy", "Lisa", "Betty", "Helen", "Sandra", "Donna", "Carol", "Ruth", "Sharon", "Michelle", "Laura", "Kimberly", "Deborah", "Dorothy", "Amy", "Angela", "Ashley", "Brenda", "Emma", "Olivia", "Cynthia", "Marie", "Janet", "Catherine", "Frances", "Christine", "Samantha", "Debra", "Rachel", "Carolyn", "Virginia", "Maria", "Heather", "Diane", "Julie", "Joyce", "Victoria", "Kelly", "Christina", "Joan", "Evelyn", "Lauren", "Judith", "Megan", "Cheryl", "Andrea", "Hannah", "Jacqueline", "Martha", "Gloria", "Teresa", "Sara", "Janice", "Julia"}
local listOfLastNames = {"Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker", "Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores", "Green", "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell", "Carter", "Roberts", "Gomez", "Phillips", "Evans", "Turner", "Diaz", "Parker", "Cruz", "Edwards", "Collins", "Reyes", "Stewart", "Morris", "Morales", "Murphy", "Cook", "Rogers", "Gutierrez", "Ortiz", "Morgan", "Cooper", "Peterson", "Bailey", "Reed", "Kelly", "Howard", "Ramos", "Kim", "Cox", "Ward", "Richardson", "Watson", "Brooks", "Chavez", "Wood", "James", "Bennett", "Gray", "Mendoza", "Ruiz", "Hughes", "Price", "Alvarez", "Castillo", "Sanders", "Patel", "Myers", "Long", "Ross", "Foster", "Jimenez"}

local function GenerateRandomBuyerName()
    local gender = math.random(1, 2) == 1 and "male" or "female"
    local firstName = gender == "male" and listOfFirstMaleNames[math.random(1, #listOfFirstMaleNames)] or listOfFirstFemaleNames[math.random(1, #listOfFirstFemaleNames)]
    local lastName = listOfLastNames[math.random(1, #listOfLastNames)]
    return {fullName = firstName .. ' ' .. lastName, gender = gender}
end

-- ============================================================
-- INITIALIZATION
-- ============================================================

CreateThread(function()
    Wait(2000) -- Wait for dependencies
    LoadData()

    -- Load dealership vehicles for NPC listings
    dealershipVehicles = exports['my_dealership']:GetVehiclesByCategories(Config.NPCUsedCarsCategories)
end)

-- Player tracking
AddEventHandler('playerDropped', function()
    connectedPlayers[source] = nil
end)

-- ============================================================
-- CLIENT REQUEST EVENTS
-- ============================================================

-- Get player's listed vehicles + post limit
RegisterNetEvent('my_usedcars:reqMyListings')
AddEventHandler('my_usedcars:reqMyListings', function()
    local _source = source
    local playerData = connectedPlayers[_source]
    if not playerData then return end

    local license = playerData.license
    local myListings = {}
    for _, listing in ipairs(UsedCarsData.listings) do
        if listing.owner == license then
            table.insert(myListings, {
                id = listing.id,
                owner = listing.owner,
                model = listing.model,
                plate = listing.plate,
                price = listing.price,
                listed_at = listing.listed_at
            })
        end
    end

    myListings = EnrichListings(myListings)

    local hasLicense = exports['my_licenses']:hasLicense(_source, 'usedcars')
    local postLimit = hasLicense and Config.PostsPerPlayerWithLicense or Config.PostsPerPlayerWithoutLicense

    TriggerClientEvent('my_usedcars:resMyListings', _source, myListings, postLimit)
end)

-- Get player's owned vehicles (not already listed)
RegisterNetEvent('my_usedcars:reqOwnedVehicles')
AddEventHandler('my_usedcars:reqOwnedVehicles', function()
    local _source = source
    local playerData = connectedPlayers[_source]
    if not playerData then return end

    local license = playerData.license
    local ownedVehicles = exports['my_vehicles']:GetVehiclesByOwner(license)
    if not ownedVehicles then
        TriggerClientEvent('my_usedcars:resOwnedVehicles', _source, {})
        return
    end

    -- Build list of plates already listed
    local listedPlates = {}
    for _, listing in ipairs(UsedCarsData.listings) do
        if listing.owner == license then
            listedPlates[listing.plate] = true
        end
    end

    -- Build vehicle list excluding already-listed ones
    local vehicles = {}
    local models = {}
    for plate, vehData in pairs(ownedVehicles) do
        if not listedPlates[plate] then
            table.insert(vehicles, {
                model = vehData.model,
                plate = plate
            })
            table.insert(models, vehData.model)
        end
    end

    -- Add labels and prices (normalize to lowercase for dealership lookup)
    local normalizedModels = {}
    for _, m in ipairs(models) do
        table.insert(normalizedModels, string.lower(m))
    end
    local vehicleDataMap = exports['my_dealership']:GetMultipleVehicleData(normalizedModels)
    for _, vehicle in ipairs(vehicles) do
        local data = vehicleDataMap[string.lower(vehicle.model)]
        if data then
            vehicle.label = data.label
            vehicle.originalPrice = data.price
        else
            vehicle.label = vehicle.model
            vehicle.originalPrice = nil
        end
    end

    TriggerClientEvent('my_usedcars:resOwnedVehicles', _source, vehicles)
end)

-- Get NPC vehicles for sale (browse tab)
RegisterNetEvent('my_usedcars:reqBrowseVehicles')
AddEventHandler('my_usedcars:reqBrowseVehicles', function()
    local _source = source
    local npcListings = {}
    for _, listing in ipairs(UsedCarsData.listings) do
        if listing.owner == nil then
            table.insert(npcListings, {
                id = listing.id,
                owner = listing.owner,
                model = listing.model,
                plate = listing.plate,
                price = listing.price,
                listed_at = listing.listed_at
            })
        end
    end

    npcListings = EnrichListings(npcListings)
    TriggerClientEvent('my_usedcars:resBrowseVehicles', _source, npcListings)
end)

-- Add vehicle to sale list
RegisterNetEvent('my_usedcars:reqAddListing')
AddEventHandler('my_usedcars:reqAddListing', function(vehicleModel, vehiclePlate, price)
    local _source = source
    local playerData = connectedPlayers[_source]
    if not playerData then return end

    local license = playerData.license
    price = tonumber(price)
    if not price or price <= 0 then
        TriggerClientEvent('my_usedcars:resAddListing', _source, false, 'invalid_price')
        return
    end

    -- Check listing limit
    local hasLicense = exports['my_licenses']:hasLicense(_source, 'usedcars')
    local maxPosts = hasLicense and Config.PostsPerPlayerWithLicense or Config.PostsPerPlayerWithoutLicense
    local currentCount = CountPlayerListings(license)

    if currentCount >= maxPosts then
        TriggerClientEvent('my_usedcars:resAddListing', _source, false, 'limit_reached')
        return
    end

    -- Verify player owns the vehicle
    local ownedVehicles = exports['my_vehicles']:GetVehiclesByOwner(license)
    if not ownedVehicles or not ownedVehicles[vehiclePlate] then
        TriggerClientEvent('my_usedcars:resAddListing', _source, false, 'not_owned')
        return
    end

    -- Check not already listed
    for _, listing in ipairs(UsedCarsData.listings) do
        if listing.plate == vehiclePlate then
            TriggerClientEvent('my_usedcars:resAddListing', _source, false, 'already_listed')
            return
        end
    end

    -- Add listing
    local newListing = {
        id = UsedCarsData.nextListingId,
        owner = license,
        model = vehicleModel,
        plate = vehiclePlate,
        price = price,
        listed_at = os.time()
    }
    table.insert(UsedCarsData.listings, newListing)
    UsedCarsData.nextListingId = UsedCarsData.nextListingId + 1
    SaveData()

    TriggerClientEvent('my_usedcars:resAddListing', _source, true)
end)

-- Update vehicle price
RegisterNetEvent('my_usedcars:reqUpdatePrice')
AddEventHandler('my_usedcars:reqUpdatePrice', function(vehicleId, newPrice)
    local _source = source
    local playerData = connectedPlayers[_source]
    if not playerData then return end

    vehicleId = tonumber(vehicleId)
    newPrice = tonumber(newPrice)
    if not vehicleId or not newPrice or newPrice <= 0 then
        TriggerClientEvent('my_usedcars:resUpdatePrice', _source, false)
        return
    end

    local listing = GetListingById(vehicleId)
    if not listing or listing.owner ~= playerData.license then
        TriggerClientEvent('my_usedcars:resUpdatePrice', _source, false)
        return
    end

    listing.price = newPrice
    SaveData()
    TriggerClientEvent('my_usedcars:resUpdatePrice', _source, true)
end)

-- Remove vehicle from listings
RegisterNetEvent('my_usedcars:reqRemoveListing')
AddEventHandler('my_usedcars:reqRemoveListing', function(vehicleId)
    local _source = source
    local playerData = connectedPlayers[_source]
    if not playerData then return end

    vehicleId = tonumber(vehicleId)
    local listing = GetListingById(vehicleId)
    if not listing or listing.owner ~= playerData.license then
        TriggerClientEvent('my_usedcars:resRemoveListing', _source, false)
        return
    end

    RemoveOffersForVehicle(vehicleId)
    RemoveListingById(vehicleId)
    SaveData()
    TriggerClientEvent('my_usedcars:resRemoveListing', _source, true)
end)

-- Get offers for a vehicle
RegisterNetEvent('my_usedcars:reqVehicleOffers')
AddEventHandler('my_usedcars:reqVehicleOffers', function(vehicleId)
    local _source = source
    vehicleId = tonumber(vehicleId)
    local offers = GetOffersForVehicle(vehicleId)
    TriggerClientEvent('my_usedcars:resVehicleOffers', _source, offers)
end)

-- Reject an offer
RegisterNetEvent('my_usedcars:reqRejectOffer')
AddEventHandler('my_usedcars:reqRejectOffer', function(vehicleId, offerId)
    local _source = source
    vehicleId = tonumber(vehicleId)
    offerId = tonumber(offerId)

    RemoveOfferById(offerId)
    SaveData()
    TriggerClientEvent('my_usedcars:resRejectOffer', _source, true)
end)

-- Make an offer on an NPC vehicle
RegisterNetEvent('my_usedcars:reqMakeOffer')
AddEventHandler('my_usedcars:reqMakeOffer', function(vehicleId, offerPrice)
    local _source = source
    local playerData = connectedPlayers[_source]
    if not playerData then return end

    vehicleId = tonumber(vehicleId)
    offerPrice = tonumber(offerPrice)
    if not vehicleId or not offerPrice or offerPrice <= 0 then
        TriggerClientEvent('my_usedcars:resMakeOffer', _source, false)
        return
    end

    local listing = GetListingById(vehicleId)
    if not listing then
        TriggerClientEvent('my_usedcars:resMakeOffer', _source, false)
        return
    end

    -- Validate minimum offer
    local minimumOffer = math.floor(listing.price * (Config.MinOfferPercent / 100))
    if offerPrice < minimumOffer then
        TriggerClientEvent('my_usedcars:resMakeOffer', _source, false)
        return
    end

    -- Check if player has enough cash
    local cash = exports['my_money']:GetMoney(_source, 'cash')
    if cash < offerPrice then
        TriggerClientEvent('my_usedcars:resMakeOffer', _source, false, 'insufficient_funds')
        return
    end

    -- Check if player already has an offer
    local existingOffer = nil
    for _, offer in ipairs(UsedCarsData.offers) do
        if offer.vehicleId == vehicleId and offer.buyer_name == playerData.name then
            existingOffer = offer
            break
        end
    end

    if existingOffer then
        existingOffer.offer_price = offerPrice
    else
        local newOffer = {
            id = UsedCarsData.nextOfferId,
            vehicleId = vehicleId,
            buyer_name = playerData.name,
            offer_price = offerPrice,
            gender = nil -- Player offers don't need gender
        }
        table.insert(UsedCarsData.offers, newOffer)
        UsedCarsData.nextOfferId = UsedCarsData.nextOfferId + 1
    end

    SaveData()
    TriggerClientEvent('my_usedcars:resMakeOffer', _source, true)
end)

-- Get vehicle original price
RegisterNetEvent('my_usedcars:reqVehiclePrice')
AddEventHandler('my_usedcars:reqVehiclePrice', function(model)
    local _source = source
    local price = GetOriginalPrice(model)
    TriggerClientEvent('my_usedcars:resVehiclePrice', _source, price)
end)

-- Sell vehicle to NPC buyer (player accepts offer, meets buyer, completes sale)
RegisterNetEvent('my_usedcars:sellVehicleToBuyer')
AddEventHandler('my_usedcars:sellVehicleToBuyer', function(vehicleId, offerId)
    local _source = source
    local playerData = connectedPlayers[_source]
    if not playerData then return end

    vehicleId = tonumber(vehicleId)
    offerId = tonumber(offerId)

    local listing = GetListingById(vehicleId)
    if not listing then
        TriggerClientEvent('my_usedcars:sellResult', _source, false)
        return
    end

    -- Verify ownership
    if listing.owner ~= playerData.license then
        TriggerClientEvent('my_usedcars:sellResult', _source, false)
        return
    end

    -- Find the offer
    local offer = nil
    for _, o in ipairs(UsedCarsData.offers) do
        if o.id == offerId then
            offer = o
            break
        end
    end

    if not offer then
        TriggerClientEvent('my_usedcars:sellResult', _source, false)
        return
    end

    -- Pay the seller (cash instead of bank)
    exports['my_money']:AddMoney(_source, 'cash', offer.offer_price)

    -- Remove vehicle from global registry silently (no client broadcast)
    -- The NPC buyer will drive the vehicle away, then it auto-despawns
    exports['my_vehicles']:RemoveVehicleData(listing.plate)

    -- Remove listing and all its offers
    RemoveOffersForVehicle(vehicleId)
    RemoveListingById(vehicleId)
    SaveData()

    TriggerClientEvent('my_usedcars:sellResult', _source, true, offer.offer_price, offer.buyer_name)
end)

-- Buy vehicle from NPC seller
RegisterNetEvent('my_usedcars:buyVehicleFromNPC')
AddEventHandler('my_usedcars:buyVehicleFromNPC', function(vehicle, offer, vehX, vehY, vehZ, vehHeading, vehProperties)
    local _source = source
    local playerData = connectedPlayers[_source]
    if not playerData then
        TriggerClientEvent('my_usedcars:buyResult', _source, false, 'Player data not found')
        return
    end

    local price = offer.offer_price
    local cash = exports['my_money']:GetMoney(_source, 'cash')

    if cash < price then
        TriggerClientEvent('my_usedcars:buyResult', _source, false, 'Not enough cash')
        return
    end

    -- Deduct money
    exports['my_money']:RemoveMoney(_source, 'cash', price)

    -- Use the listing plate, but if it collides (another vehicle registered
    -- with the same plate since listing was created), generate a fresh one.
    local plate = vehicle.plate
    if exports['my_vehicles']:DoesPlateExist(plate) then
        plate = GeneratePlate()
        if not plate then
            exports['my_money']:AddMoney(_source, 'cash', price)
            TriggerClientEvent('my_usedcars:buyResult', _source, false, 'Could not generate plate')
            return
        end
    end

    -- Register the vehicle with my_vehicles using actual position and properties from client
    local registered = exports['my_vehicles']:RegisterVehicle(
        plate,
        string.lower(vehicle.model),
        playerData.license,
        playerData.name,
        tonumber(vehX) or 0.0, tonumber(vehY) or 0.0, tonumber(vehZ) or 0.0, tonumber(vehHeading) or 0.0,
        vehProperties or {}
    )

    if registered then
        -- Add realistic random mileage for the used car
        local originalPrice = GetOriginalPrice(vehicle.model) or price
        local randomKm = GenerateRandomMileage(originalPrice)
        exports['my_vehicles']:UpdateVehicleMileage(plate, randomKm)
        TriggerClientEvent('my_usedcars:buyResult', _source, true, plate)
    else
        -- Refund if registration failed
        exports['my_money']:AddMoney(_source, 'cash', price)
        TriggerClientEvent('my_usedcars:buyResult', _source, false, 'Registration failed')
    end
end)

-- Player connects - track them and clean up orphaned listings
RegisterNetEvent('my_usedcars:playerReady')
AddEventHandler('my_usedcars:playerReady', function()
    local _source = source
    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if not license then return end

    connectedPlayers[_source] = {
        license = license,
        name = GetPlayerName(_source) or 'Unknown'
    }

    -- Clean up orphaned listings: if the player's character was deleted,
    -- their vehicles no longer exist in my_vehicles but old listings remain.
    local ownedVehicles = exports['my_vehicles']:GetVehiclesByOwner(license)
    local ownedPlates = {}
    if ownedVehicles then
        for plate, _ in pairs(ownedVehicles) do
            ownedPlates[plate] = true
        end
    end

    local cleaned = false
    for i = #UsedCarsData.listings, 1, -1 do
        local listing = UsedCarsData.listings[i]
        if listing.owner == license and not ownedPlates[listing.plate] then
            RemoveOffersForVehicle(listing.id)
            RemoveListingById(listing.id)
            cleaned = true
        end
    end

    if cleaned then
        SaveData()
    end
end)

-- Export: remove all listings and offers for a given license (called by permadeath)
exports('ResetPlayerData', function(license)
    if not license then return end
    local cleaned = false
    for i = #UsedCarsData.listings, 1, -1 do
        local listing = UsedCarsData.listings[i]
        if listing.owner == license then
            RemoveOffersForVehicle(listing.id)
            RemoveListingById(listing.id)
            cleaned = true
        end
    end
    if cleaned then
        SaveData()
    end
end)

-- Check if player has enough money (for client-side validation)
RegisterNetEvent('my_usedcars:checkMoney')
AddEventHandler('my_usedcars:checkMoney', function(amount)
    local _source = source
    amount = tonumber(amount)
    if not amount then return end

    local cash = exports['my_money']:GetMoney(_source, 'cash')
    TriggerClientEvent('my_usedcars:moneyCheck', _source, cash >= amount)
end)

-- ============================================================
-- NPC OFFER GENERATION TIMER
-- ============================================================

CreateThread(function()
    Wait(10000) -- Initial delay

    while true do
        Wait(Config.OfferTimer)

        -- Process player-listed vehicles: generate NPC offers
        for _, listing in ipairs(UsedCarsData.listings) do
            if listing.owner ~= nil then
                local marketPrice = GetOriginalPrice(listing.model) or listing.price
                local priceDifferencePercent = 100 - math.floor((listing.price / marketPrice) * 100)

                local typeOfOffer = nil
                for index, offerConfig in ipairs(Config.OfferTypes) do
                    if index > 1 and priceDifferencePercent > Config.OfferTypes[index-1].priceDifferencePercent and priceDifferencePercent <= offerConfig.priceDifferencePercent then
                        typeOfOffer = offerConfig
                    elseif index == 1 and priceDifferencePercent <= offerConfig.priceDifferencePercent then
                        typeOfOffer = offerConfig
                    elseif priceDifferencePercent > offerConfig.priceDifferencePercent then
                        typeOfOffer = offerConfig
                    end
                end

                if typeOfOffer then
                    local randomChance = math.random(0, 100)
                    if randomChance <= typeOfOffer.chance then
                        local offerCount = #GetOffersForVehicle(listing.id)
                        if offerCount < typeOfOffer.maxOffers then
                            local maxDiscountAmount = math.floor((typeOfOffer.maxDiscount / 100) * listing.price)
                            local discountAmount = math.random(0, maxDiscountAmount)
                            local offerPrice = listing.price - discountAmount

                            if math.random(0, 100) <= typeOfOffer.chanceForFullPrice then
                                offerPrice = listing.price
                            end

                            local buyerInfo = GenerateRandomBuyerName()
                            local newOffer = {
                                id = UsedCarsData.nextOfferId,
                                vehicleId = listing.id,
                                buyer_name = buyerInfo.fullName,
                                offer_price = offerPrice,
                                gender = buyerInfo.gender
                            }
                            table.insert(UsedCarsData.offers, newOffer)
                            UsedCarsData.nextOfferId = UsedCarsData.nextOfferId + 1
                            SaveData()

                            -- Notify only the owner if online
                            local vehicleLabel = GetVehicleLabel(listing.model) or listing.model
                            for src, pData in pairs(connectedPlayers) do
                                if pData.license == listing.owner then
                                    TriggerClientEvent('my_usedcars:notifyNewOffer', src, buyerInfo.fullName, offerPrice)
                                    TriggerClientEvent('chatMessage', src, "^2[Used Cars]^7", "", buyerInfo.fullName .. " made a new offer of $" .. GroupDigits(offerPrice) .. " on your " .. vehicleLabel .. "!")
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Process NPC-listed vehicles: check player offers
        for _, listing in ipairs(UsedCarsData.listings) do
            if listing.owner == nil then
                local offers = GetOffersForVehicle(listing.id)
                for _, offer in ipairs(offers) do
                    local priceDifferencePercent = 100 - math.floor((offer.offer_price / listing.price) * 100)
                    local typeOfNPCOffer = nil

                    for index, npcOfferConfig in ipairs(Config.NPCOfferTypes) do
                        if index > 1 and priceDifferencePercent > Config.NPCOfferTypes[index-1].priceDifferencePercent and priceDifferencePercent <= npcOfferConfig.priceDifferencePercent then
                            typeOfNPCOffer = npcOfferConfig
                        elseif index == 1 and priceDifferencePercent <= npcOfferConfig.priceDifferencePercent then
                            typeOfNPCOffer = npcOfferConfig
                        elseif priceDifferencePercent > npcOfferConfig.priceDifferencePercent then
                            typeOfNPCOffer = npcOfferConfig
                        end
                    end

                    if typeOfNPCOffer then
                        local randomChance = math.random(1, 100)
                        if randomChance <= typeOfNPCOffer.chance then
                            -- NPC accepts the offer
                            RemoveOffersForVehicle(listing.id)
                            RemoveListingById(listing.id)
                            SaveData()

                            listing.label = GetVehicleLabel(listing.model)
                            TriggerClientEvent('my_usedcars:notifyAcceptedOffer', -1, listing, offer)
                        else
                            -- NPC rejects - remove offer and listing
                            RemoveOffersForVehicle(listing.id)
                            RemoveListingById(listing.id)
                            SaveData()

                            local vehicleLabel = GetVehicleLabel(listing.model)
                            TriggerClientEvent('my_usedcars:notifyRejectedOffer', -1, vehicleLabel, offer.buyer_name)
                        end
                        break -- Only process first offer per listing per cycle
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- NPC VEHICLE LISTING TIMER
-- ============================================================

CreateThread(function()
    Wait(15000) -- Initial delay

    while true do
        Wait(Config.NPCUsedCarsTimer)

        local npcCount = CountNPCListings()
        if npcCount < Config.NPCUsedCarsMaxForSale then
            local randomChance = math.random(1, 100)
            if randomChance <= Config.NPCUsedCarsChance and #dealershipVehicles > 0 then
                local vehicle = dealershipVehicles[math.random(1, #dealershipVehicles)]
                if vehicle then
                    local discount = math.random(Config.NPCUsedCarsMinDiscount, Config.NPCUsedCarsMaxDiscount)
                    local salePrice = vehicle.price - math.floor(vehicle.price * (discount / 100))

                    local newListing = {
                        id = UsedCarsData.nextListingId,
                        owner = nil, -- NPC listing
                        model = string.lower(vehicle.model),
                        plate = GeneratePlate(),
                        price = salePrice,
                        listed_at = os.time()
                    }
                    table.insert(UsedCarsData.listings, newListing)
                    UsedCarsData.nextListingId = UsedCarsData.nextListingId + 1
                    SaveData()
                end
            end
        end
    end
end)

-- ============================================================
-- NPC VEHICLE EXPIRY TIMER
-- ============================================================

CreateThread(function()
    Wait(20000) -- Initial delay

    while true do
        Wait(60000) -- Check every minute

        local currentTime = os.time()
        local expired = false

        for _, listing in ipairs(UsedCarsData.listings) do
            if listing.owner == nil and listing.listed_at then
                local timePassed = currentTime - listing.listed_at
                if timePassed >= Config.NPCUsedCarsExpireTime then
                    RemoveOffersForVehicle(listing.id)
                    RemoveListingById(listing.id)
                    expired = true
                end
            end
        end

        if expired then
            SaveData()
        end
    end
end)

