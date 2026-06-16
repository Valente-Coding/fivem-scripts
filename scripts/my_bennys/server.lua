-- my_bennys/server.lua
-- Vehicle customization payment handler
-- Uses my_money exports for clean money only (no dirty money)

---@return number
local function getModPrice(mod, level)
    if mod == 'cosmetic' or mod == 'colors' or mod == 18 then
        return Config.Prices[mod] --[[@as number]]
    else
        return Config.Prices[mod][level]
    end
end

---@param source number
---@param amount number
---@return boolean
local function removeMoney(source, amount)
    if not amount or amount <= 0 then return true end

    local currentCash = exports['my_money']:GetMoney(source, 'cash')
    if currentCash >= amount then
        return exports['my_money']:RemoveMoney(source, 'cash', amount)
    end

    return false
end

-- Event-based callback system (replaces ox_lib callbacks)
local callbacks = {}

callbacks['my_bennys:server:pay'] = function(source, mod, level)
    local price = getModPrice(mod, level)
    return removeMoney(source, price)
end

callbacks['my_bennys:server:repair'] = function(source, bodyHealth)
    local price = math.ceil(1000 - bodyHealth)
    return removeMoney(source, price)
end

RegisterNetEvent('my_bennys:callback')
AddEventHandler('my_bennys:callback', function(name, id, ...)
    local src = source
    if callbacks[name] then
        local result = callbacks[name](src, ...)
        TriggerClientEvent('my_bennys:callbackResult', src, id, result)
    end
end)

-- Save vehicle properties after customization
RegisterNetEvent('my_bennys:server:saveVehicleProps')
AddEventHandler('my_bennys:server:saveVehicleProps', function(plate, properties)
    local src = source
    if not plate or not properties then return end

    -- Normalize plate
    plate = string.upper(string.gsub(tostring(plate), "%s+", ""))

    -- Check if vehicle exists in registry and save
    local vehicleData = exports['my_vehicles']:GetVehicleData(plate)
    if vehicleData then
        exports['my_vehicles']:UpdateVehicleProperties(plate, properties)
        -- Notify the client to update its local vehicle data cache
        -- so respawned vehicles use the latest properties
        TriggerClientEvent('my_vehicles:propertiesUpdated', src, plate, properties)
        print(('[my_bennys] Saved vehicle mods for plate: %s'):format(plate))
    else
        print(('[my_bennys] WARNING: Vehicle not found in registry for plate: %s'):format(plate))
    end
end)
