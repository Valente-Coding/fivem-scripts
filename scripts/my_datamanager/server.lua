-- Centralized Player Data Manager
-- Handles all player data saving/loading with separate files per data type

local playerDataCache = {}

-- Valid data types whitelist for security
local validDataTypes = {
    money = true,
    position = true,
    vehicles = true,
    time = true,
    licenses = true,
    taxes = true,
    fishing = true,
    deliveries = true,
    trucking = true,
    warehouse = true,
    drugdealer = true,
    drugdistributors = true,
    business = true,
    housing = true,
    stocks = true,
    usedcars = true,
    weapons = true,
    armor = true,
    inventory = true,
    character = true,
    clothing = true,
    energy = true,
    health = true,
    dealership = true,
    garage = true,
    mechanicskills = true
}

-- Validate data type
local function IsValidDataType(dataType)
    return validDataTypes[dataType] == true
end

-- Ensure saved_data folder exists
CreateThread(function()
    local folderCheck = LoadResourceFile(GetCurrentResourceName(), "../saved_data/.gitkeep")
    if not folderCheck then
        SaveResourceFile(GetCurrentResourceName(), "../saved_data/.gitkeep", "", -1)
    end
end)

-- Get player license
local function GetPlayerLicense(source)
    if not source or source == 0 then
        return nil
    end
    
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then
        return nil
    end
    
    for _, id in ipairs(identifiers) do
        if string.match(id, "^license:") then
            return id
        end
    end
    
    return nil
end

-- Load specific data type from file
local function LoadDataFromFile(license, dataType)
    if not IsValidDataType(dataType) then
        print("^1[DataManager] Invalid data type: " .. tostring(dataType) .. "^7")
        return nil
    end
    
    local safeLicense = license:gsub(":", "_")
    local filename = string.format("../saved_data/%s_%s.json", safeLicense, dataType)
    local data = LoadResourceFile(GetCurrentResourceName(), filename)
    
    if data and data ~= "" then
        local success, decoded = pcall(json.decode, data)
        if success and decoded then
            return decoded
        end
    end
    
    return nil
end

-- Save specific data type to file
local function SaveDataToFile(license, dataType, value)
    if not IsValidDataType(dataType) then
        print("^1[DataManager] Invalid data type: " .. tostring(dataType) .. "^7")
        return false
    end
    
    local safeLicense = license:gsub(":", "_")
    local filename = string.format("../saved_data/%s_%s.json", safeLicense, dataType)
    local jsonStr = json.encode(value, {indent = true})
    local success = SaveResourceFile(GetCurrentResourceName(), filename, jsonStr, -1)
    
    if success then
        return true
    else
        print("^1[DataManager] Failed to save " .. dataType .. " for " .. safeLicense .. "^7")
    end
    
    return success
end

-- Initialize player cache if not exists
local function InitPlayerCache(license)
    if not playerDataCache[license] then
        playerDataCache[license] = {}
    end
end

-- Set player data key
local function SetPlayerDataKey(source, key, value)
    local license = GetPlayerLicense(source)
    if not license then
        print("^1[DataManager] Could not find license for player " .. source .. "^7")
        return false
    end
    
    InitPlayerCache(license)
    playerDataCache[license][key] = value
    
    return SaveDataToFile(license, key, value)
end

-- Get player data key
local function GetPlayerDataKey(source, key)
    local license = GetPlayerLicense(source)
    if not license then
        print("^1[DataManager] Could not find license for player " .. source .. "^7")
        return nil
    end
    
    InitPlayerCache(license)
    
    -- Load from cache if available
    if playerDataCache[license][key] ~= nil then
        return playerDataCache[license][key]
    end
    
    -- Load from file
    local data = LoadDataFromFile(license, key)
    if data then
        playerDataCache[license][key] = data
    end
    
    return data
end

-- Delete all player data
local function DeletePlayerData(source)
    local license = GetPlayerLicense(source)
    if not license then
        return false
    end
    
    -- Clear cache
    if playerDataCache[license] then
        -- Delete each data type file
        for dataType, _ in pairs(playerDataCache[license]) do
            SaveDataToFile(license, dataType, {})
        end
        playerDataCache[license] = nil
    end
    
    return true
end

-- Save all cached player data
local function SavePlayerData(source)
    local license = GetPlayerLicense(source)
    if not license then
        return false
    end
    
    if not playerDataCache[license] then
        return true -- Nothing to save
    end
    
    local allSuccess = true
    for dataType, value in pairs(playerDataCache[license]) do
        local success = SaveDataToFile(license, dataType, value)
        if not success then
            allSuccess = false
        end
    end
    
    return allSuccess
end

-- When player disconnects, save their data and clear cache
AddEventHandler('playerDropped', function()
    local source = source
    local license = GetPlayerLicense(source)
    
    if license and playerDataCache[license] then
        local success = SavePlayerData(source)
        if success then
            playerDataCache[license] = nil
        else
            print("^1[DataManager] Failed to save data for " .. license .. ", keeping cache^7")
        end
    end
end)

-- Exports
exports('GetPlayerDataKey', GetPlayerDataKey)
exports('SetPlayerDataKey', SetPlayerDataKey)
exports('SavePlayerData', SavePlayerData)
exports('DeletePlayerData', DeletePlayerData)
exports('GetPlayerLicense', GetPlayerLicense)

