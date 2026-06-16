-- License Center Server

-- Check if player has a specific license
local function HasLicense(source, licenseType)
    local licenseData = exports['my_datamanager']:GetPlayerDataKey(source, 'licenses')
    if not licenseData then return false end
    return licenseData[licenseType] == true
end

-- Give license to player
local function GiveLicense(source, licenseType)
    if HasLicense(source, licenseType) then
        return false, "You already have this license"
    end

    local licenseData = exports['my_datamanager']:GetPlayerDataKey(source, 'licenses') or {}
    licenseData[licenseType] = true
    exports['my_datamanager']:SetPlayerDataKey(source, 'licenses', licenseData)

    return true, "License purchased successfully"
end

-- Export for other resources
exports('hasLicense', function(source, licenseType)
    return HasLicense(source, licenseType)
end)

-- Request player's licenses
RegisterNetEvent('my_licenses:requestLicenses')
AddEventHandler('my_licenses:requestLicenses', function()
    local _source = source
    local licenseData = exports['my_datamanager']:GetPlayerDataKey(_source, 'licenses') or {}
    TriggerClientEvent('my_licenses:showCenter', _source, licenseData)
end)

-- Purchase license
RegisterNetEvent('my_licenses:purchase')
AddEventHandler('my_licenses:purchase', function(licenseType)
    local _source = source

    -- Validate license type
    local licenseConfig = Config.Licenses[licenseType]
    if not licenseConfig then
        TriggerClientEvent('my_licenses:purchaseResult', _source, false, "Invalid license type", licenseType)
        return
    end

    -- Check if already owned
    if HasLicense(_source, licenseType) then
        TriggerClientEvent('my_licenses:purchaseResult', _source, false, "You already own this license", licenseType)
        return
    end

    -- Try to charge
    local price = licenseConfig.price
    local success = exports['my_money']:RemoveMoney(_source, 'cash', price)

    if not success then
        TriggerClientEvent('my_licenses:purchaseResult', _source, false, "You don't have enough money ($" .. price .. " needed)", licenseType)
        return
    end

    -- Grant license
    local granted, message = GiveLicense(_source, licenseType)

    if granted then
        TriggerClientEvent('my_licenses:purchaseResult', _source, true, "You purchased a " .. licenseConfig.label .. " for $" .. price, licenseType)
        TriggerClientEvent('chatMessage', _source, "^2[Licenses]^7", "", "You purchased a " .. licenseConfig.label)

        if Config.Debug then
            print(string.format("^2[Licenses] %s purchased %s license^7", GetPlayerName(_source), licenseType))
        end
    else
        -- Refund if grant failed
        exports['my_money']:AddMoney(_source, 'cash', price)
        TriggerClientEvent('my_licenses:purchaseResult', _source, false, message, licenseType)
    end
end)

-- Admin command: Grant license
RegisterCommand('grantlicense', function(source, args, rawCommand)
    if source ~= 0 then return end -- Console only

    local playerId = tonumber(args[1])
    local licenseType = args[2]

    if not playerId or not licenseType then
        print("^1USAGE: grantlicense <playerid> <type>^7")
        print("^3Types: fishing, weapon, business, usedcars, driving^7")
        return
    end

    if not Config.Licenses[licenseType] then
        print("^1Invalid license type: " .. licenseType .. "^7")
        return
    end

    local success, message = GiveLicense(playerId, licenseType)
    if success then
        print("^2[Licenses] Granted " .. licenseType .. " license to player " .. playerId .. "^7")
        TriggerClientEvent('chatMessage', playerId, "^2[Licenses]^7", "", "You've been granted a " .. Config.Licenses[licenseType].label)
    else
        print("^1[Licenses] Failed: " .. message .. "^7")
    end
end, false)

