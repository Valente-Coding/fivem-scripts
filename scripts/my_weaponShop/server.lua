-- Weapon Shop Server

local function GetWeaponData(weaponName)
    for _, weapon in ipairs(Config.Weapons) do
        if weapon.name == weaponName then return weapon end
    end
    return nil
end

-- Load saved weapons and armor when player requests them
RegisterNetEvent('my_weaponShop:requestWeapons')
AddEventHandler('my_weaponShop:requestWeapons', function()
    local _source = source
    local savedWeapons = exports['my_datamanager']:GetPlayerDataKey(_source, 'weapons') or {}
    local savedArmor = exports['my_datamanager']:GetPlayerDataKey(_source, 'armor') or 0
    TriggerClientEvent('my_weaponShop:loadWeapons', _source, savedWeapons, savedArmor)
end)

-- Check weapon license
RegisterNetEvent('my_weaponShop:checkLicense')
AddEventHandler('my_weaponShop:checkLicense', function()
    local _source = source
    local hasLicense = exports['my_licenses']:hasLicense(_source, 'weapon')
    TriggerClientEvent('my_weaponShop:licenseResult', _source, hasLicense)
end)

-- Buy weapon
RegisterNetEvent('my_weaponShop:buyWeapon')
AddEventHandler('my_weaponShop:buyWeapon', function(weaponName, weaponLabel)
    local _source = source

    local weaponData = GetWeaponData(weaponName)
    if not weaponData then
        TriggerClientEvent('my_weaponShop:purchaseDenied', _source, "Weapon not available")
        return
    end

    -- Check license
    local hasLicense = exports['my_licenses']:hasLicense(_source, 'weapon')
    if not hasLicense then
        TriggerClientEvent('my_weaponShop:purchaseDenied', _source, "You need a weapons license")
        return
    end

    -- Charge money
    local success = exports['my_money']:RemoveMoney(_source, 'cash', weaponData.price)
    if not success then
        TriggerClientEvent('my_weaponShop:purchaseDenied', _source, "Not enough cash ($" .. weaponData.price .. " needed)")
        return
    end

    -- Track owned weapons in datamanager
    local weaponsData = exports['my_datamanager']:GetPlayerDataKey(_source, 'weapons') or {}
    weaponsData[weaponName] = true
    exports['my_datamanager']:SetPlayerDataKey(_source, 'weapons', weaponsData)

    TriggerClientEvent('my_weaponShop:giveWeapon', _source, weaponName, 100)
    TriggerClientEvent('chatMessage', _source, "^2[WeaponShop]^7", "", "You purchased a " .. (weaponLabel or weaponName) .. " for $" .. weaponData.price)
end)

-- Buy ammo
RegisterNetEvent('my_weaponShop:buyAmmo')
AddEventHandler('my_weaponShop:buyAmmo', function(weaponName, weaponLabel)
    local _source = source

    local weaponData = GetWeaponData(weaponName)
    if not weaponData or weaponData.ammoPrice <= 0 then
        TriggerClientEvent('my_weaponShop:purchaseDenied', _source, "Invalid weapon or no ammo available")
        return
    end

    local success = exports['my_money']:RemoveMoney(_source, 'cash', weaponData.ammoPrice)
    if not success then
        TriggerClientEvent('my_weaponShop:purchaseDenied', _source, "Not enough cash ($" .. weaponData.ammoPrice .. " needed)")
        return
    end

    TriggerClientEvent('my_weaponShop:giveAmmo', _source, weaponName, weaponData.ammoAmount)
end)

-- Add armor to inventory
RegisterNetEvent('my_weaponShop:addArmorToInventory')
AddEventHandler('my_weaponShop:addArmorToInventory', function()
    local _source = source
    local armorData = GetWeaponData("ITEM_ARMOR")
    
    exports['my_inventory']:AddItem(_source, 'armor', 1)
    TriggerClientEvent('chatMessage', _source, "^2[WeaponShop]^7", "", "Your armor is full! Body Armor added to inventory for $" .. armorData.price)
end)

-- Sync armor value from client periodically
RegisterNetEvent('my_weaponShop:syncArmor')
AddEventHandler('my_weaponShop:syncArmor', function(armorValue)
    local _source = source
    if type(armorValue) == 'number' and armorValue >= 0 and armorValue <= 100 then
        exports['my_datamanager']:SetPlayerDataKey(_source, 'armor', armorValue)
    end
end)

-- Sync weapons from client (removes weapons player no longer has)
RegisterNetEvent('my_weaponShop:syncWeapons')
AddEventHandler('my_weaponShop:syncWeapons', function(currentWeapons)
    local _source = source
    if type(currentWeapons) == 'table' then
        exports['my_datamanager']:SetPlayerDataKey(_source, 'weapons', currentWeapons)
    end
end)

-- Buy armor
RegisterNetEvent('my_weaponShop:buyArmor')
AddEventHandler('my_weaponShop:buyArmor', function()
    local _source = source

    local armorData = GetWeaponData("ITEM_ARMOR")
    if not armorData then
        TriggerClientEvent('my_weaponShop:purchaseDenied', _source, "Armor not available")
        return
    end

    local success = exports['my_money']:RemoveMoney(_source, 'cash', armorData.price)
    if not success then
        TriggerClientEvent('my_weaponShop:purchaseDenied', _source, "Not enough cash ($" .. armorData.price .. " needed)")
        return
    end

    -- Save armor to datamanager for persistence
    exports['my_datamanager']:SetPlayerDataKey(_source, 'armor', 100)

    -- Check if player armor is already full
    TriggerClientEvent('my_weaponShop:checkAndGiveArmor', _source, armorData.price)
end)

