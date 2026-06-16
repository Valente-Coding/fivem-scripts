-- my_dealership/server.lua
-- Server-side logic for vehicle dealership system

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

-- Generate a random metallic color index (1-94)
local function getRandomColor()
    return math.random(1, 94)
end

-- Generate unique random plate (8 characters alphanumeric)
local function generatePlate()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local plate = ""
    local maxAttempts = 100
    local attempts = 0
    
    repeat
        plate = ""
        for i = 1, 8 do
            local rand = math.random(1, #charset)
            plate = plate .. charset:sub(rand, rand)
        end
        
        attempts = attempts + 1
        
        local inRegistry = exports['my_vehicles']:DoesPlateExist(plate)
        
        if attempts >= maxAttempts then
            print("^1[my_dealership ERROR]^7 Failed to generate unique plate after " .. maxAttempts .. " attempts")
            return nil
        end
        
    until not inRegistry
    
    return plate
end

-- Validate vehicle model exists in config
local function isValidVehicle(model)
    if not model or type(model) ~= "string" then
        return false, nil
    end
    
    for _, vehicle in ipairs(Config.Vehicles) do
        if vehicle.model == model then
            return true, vehicle
        end
    end
    
    return false, nil
end

-- ============================================================
-- EVENTS
-- ============================================================

-- Handle vehicle purchase requests
RegisterNetEvent('my_dealership:purchaseVehicle')
AddEventHandler('my_dealership:purchaseVehicle', function(vehicleModel)
    local _source = source
    
    -- Validate source
    if not _source or _source == 0 then
        print("^1[my_dealership ERROR]^7 Invalid source in purchaseVehicle")
        return
    end
    
    -- Validate vehicle model
    local isValid, vehicleData = isValidVehicle(vehicleModel)
    if not isValid or not vehicleData then
        print("^1[my_dealership ERROR]^7 Invalid vehicle model: " .. tostring(vehicleModel))
        TriggerClientEvent('my_dealership:purchaseFailure', _source, "Invalid vehicle model")
        return
    end
    
    local vehiclePrice = vehicleData.price
    local vehicleName = vehicleData.name
    
    -- Check player has enough cash
    local playerCash = exports['my_money']:GetMoney(_source, 'cash')
    
    if playerCash < vehiclePrice then
        TriggerClientEvent('my_dealership:purchaseFailure', _source, "Insufficient funds. Need $" .. vehiclePrice .. ", have $" .. playerCash)
        return
    end
    
    -- Generate unique plate
    local plate = generatePlate()
    
    if not plate then
        print("^1[my_dealership ERROR]^7 Failed to generate unique plate for player " .. _source)
        TriggerClientEvent('my_dealership:purchaseFailure', _source, "System error - try again")
        return
    end
    
    -- Remove money from player
    local success = exports['my_money']:RemoveMoney(_source, 'cash', vehiclePrice)
    
    if not success then
        print("^1[my_dealership ERROR]^7 Failed to remove money from player " .. _source)
        TriggerClientEvent('my_dealership:purchaseFailure', _source, "Transaction failed")
        return
    end
    
    -- Generate random colors for the vehicle
    local primaryColor = getRandomColor()
    local secondaryColor = getRandomColor()
    
    -- Build vehicle properties with color info
    -- modColor1: {paintType, colorIndex, pearlescent} — paintType 1 = Metallic
    -- modColor2: {paintType, colorIndex}
    local properties = {
        color1 = primaryColor,
        color2 = secondaryColor,
        modColor1 = {1, primaryColor, 0},  -- 1 = Metallic paint type
        modColor2 = {1, secondaryColor},   -- 1 = Metallic paint type
        pearlescentColor = 0,
        wheelColor = 0
    }
    
    -- Get player license
    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if not license then
        -- Refund money if we can't get license
        exports['my_money']:AddMoney(_source, 'cash', vehiclePrice)
        print("^1[my_dealership ERROR]^7 Could not get player license for " .. _source)
        TriggerClientEvent('my_dealership:purchaseFailure', _source, "System error - try again")
        return
    end
    
    -- Register vehicle directly with my_vehicles (server-side, no auth needed)
    local registered = exports['my_vehicles']:RegisterVehicle(
        plate,
        vehicleModel,
        license,
        GetPlayerName(_source),
        Config.SpawnLocation.x,
        Config.SpawnLocation.y,
        Config.SpawnLocation.z,
        Config.SpawnLocation.heading,
        properties
    )
    
    if not registered then
        -- Refund money if registration failed
        exports['my_money']:AddMoney(_source, 'cash', vehiclePrice)
        print("^1[my_dealership ERROR]^7 Failed to register vehicle for player " .. _source)
        TriggerClientEvent('my_dealership:purchaseFailure', _source, "Vehicle registration failed - try again")
        return
    end
    
    
    -- Send success to client with plate, model, name, and properties
    TriggerClientEvent('my_dealership:purchaseSuccess', _source, {
        plate = plate,
        model = vehicleModel,
        name = vehicleName,
        properties = properties
    })
end)

-- ============================================================
-- EXPORTS
-- ============================================================

-- Get dealership vehicles within a price range (for vehicle flipper)
-- Usage: exports['my_dealership']:GetVehiclesByPriceRange(maxPrice, minPrice)
exports('GetVehiclesByPriceRange', function(maxPrice, minPrice)
    -- Default values if not provided
    minPrice = minPrice or 0
    maxPrice = maxPrice or math.huge
    
    -- Filter vehicles by price range
    local filteredVehicles = {}
    
    for _, vehicle in ipairs(Config.Vehicles) do
        if vehicle.price >= minPrice and vehicle.price <= maxPrice then
            table.insert(filteredVehicles, {
                model = vehicle.model,
                label = vehicle.name,  -- vehicle flipper uses 'label' instead of 'name'
                price = vehicle.price
            })
        end
    end
    
    return filteredVehicles
end)

-- Handle request for available vehicles (checks driving license)
RegisterNetEvent('my_dealership:requestVehicles')
AddEventHandler('my_dealership:requestVehicles', function()
    local _source = source
    
    -- Check if player has a driving license
    local hasDrivingLicense = exports['my_licenses']:hasLicense(_source, 'driving')
    
    local vehiclesToSend = {}
    
    if hasDrivingLicense then
        -- Player has license: send all vehicles
        vehiclesToSend = Config.Vehicles
    else
        -- No license: only send Cycles (bicycles)
        for _, vehicle in ipairs(Config.Vehicles) do
            if vehicle.category == "Cycles" then
                table.insert(vehiclesToSend, vehicle)
            end
        end
    end
    
    TriggerClientEvent('my_dealership:receiveVehicles', _source, vehiclesToSend, hasDrivingLicense)
end)

-- Get vehicle price by model name
exports('GetVehiclePrice', function(model)
    if not model or type(model) ~= "string" then return nil end
    model = string.lower(model)
    for _, vehicle in ipairs(Config.Vehicles) do
        if string.lower(vehicle.model) == model then
            return vehicle.price
        end
    end
    return nil
end)

-- Get vehicle label/name by model name
exports('GetVehicleLabel', function(model)
    if not model or type(model) ~= "string" then return nil end
    model = string.lower(model)
    for _, vehicle in ipairs(Config.Vehicles) do
        if string.lower(vehicle.model) == model then
            return vehicle.name
        end
    end
    return nil
end)

-- Get vehicle data (label + price) for multiple models at once
exports('GetMultipleVehicleData', function(models)
    if not models or type(models) ~= "table" then return {} end
    local result = {}
    for _, model in ipairs(models) do
        local lowerModel = string.lower(model)
        for _, vehicle in ipairs(Config.Vehicles) do
            if string.lower(vehicle.model) == lowerModel then
                result[model] = { label = vehicle.name, price = vehicle.price }
                break
            end
        end
    end
    return result
end)

-- Get vehicles by categories (for NPC used car listings)
exports('GetVehiclesByCategories', function(categories)
    if not categories or type(categories) ~= "table" then return {} end
    local result = {}
    for _, vehicle in ipairs(Config.Vehicles) do
        for _, cat in ipairs(categories) do
            if string.lower(vehicle.category or '') == string.lower(cat) then
                table.insert(result, { model = vehicle.model, name = vehicle.name, price = vehicle.price, category = vehicle.category })
                break
            end
        end
    end
    return result
end)

-- ============================================================
-- STARTUP
-- ============================================================

CreateThread(function()
    -- Verify dependencies are loaded
    local dependencies = {'my_datamanager', 'my_money', 'my_vehicles'}
    local allLoaded = true
    
    for _, dep in ipairs(dependencies) do
        local state = GetResourceState(dep)
        if state ~= 'started' then
            print("^1[my_dealership ERROR]^7 Dependency '" .. dep .. "' is not running (state: " .. state .. ")")
            allLoaded = false
        end
    end
    
    if not allLoaded then
        print("^1[my_dealership ERROR]^7 Missing dependencies - dealership will not function correctly")
        print("^1[my_dealership ERROR]^7 Please ensure my_datamanager, my_money, and my_vehicles are started before my_dealership")
        return
    end
    
    -- Validate config vehicles
    local configErrors = {}
    
    if not Config.Vehicles or #Config.Vehicles == 0 then
        table.insert(configErrors, "No vehicles defined in Config.Vehicles")
    else
        for i, vehicle in ipairs(Config.Vehicles) do
            if not vehicle.model or type(vehicle.model) ~= "string" then
                table.insert(configErrors, "Vehicle #" .. i .. " missing valid model")
            end
            if not vehicle.name or type(vehicle.name) ~= "string" then
                table.insert(configErrors, "Vehicle #" .. i .. " missing valid name")
            end
            if not vehicle.price or type(vehicle.price) ~= "number" or vehicle.price <= 0 then
                table.insert(configErrors, "Vehicle #" .. i .. " has invalid price (must be number > 0)")
            end
        end
    end
    
    if #configErrors > 0 then
        print("^1[my_dealership CONFIG ERRORS]^7")
        for _, err in ipairs(configErrors) do
            print("^1  - " .. err .. "^7")
        end
        print("^1[my_dealership]^7 Fix config.lua and restart resource")
        return
    end
end)
