-- Weapon Shop Client
local isShopOpen = false
local shopBlips = {}
local hasLoadedWeapons = false

-- Request saved weapons/armor when player spawns
AddEventHandler('playerSpawned', function()
    if not hasLoadedWeapons then
        hasLoadedWeapons = true
        -- Small delay to ensure player ped is fully loaded
        Wait(2000)
        TriggerServerEvent('my_weaponShop:requestWeapons')
    end
end)

-- Receive saved weapons/armor from server and restore them
RegisterNetEvent('my_weaponShop:loadWeapons')
AddEventHandler('my_weaponShop:loadWeapons', function(savedWeapons, savedArmor)
    local playerPed = PlayerPedId()

    -- Restore weapons
    if savedWeapons and type(savedWeapons) == 'table' then
        for weaponName, owned in pairs(savedWeapons) do
            if owned then
                local hash = GetHashKey(weaponName)
                if not HasPedGotWeapon(playerPed, hash, false) then
                    GiveWeaponToPed(playerPed, hash, 100, false, true)
                end
            end
        end
    end

    -- Restore armor
    if savedArmor and savedArmor > 0 then
        SetPedArmour(playerPed, savedArmor)
    end
end)

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function DisplayHelpText(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- Get player's current weapons
local function GetPlayerWeapons()
    local playerPed = PlayerPedId()
    local weapons = {}
    for _, weapon in ipairs(Config.Weapons) do
        if not weapon.isArmor then
            if HasPedGotWeapon(playerPed, GetHashKey(weapon.name), false) then
                weapons[weapon.name] = true
            end
        end
    end
    return weapons
end

local function OpenWeaponShop()
    if isShopOpen then return end

    -- Check for weapon license
    TriggerServerEvent('my_weaponShop:checkLicense')
end

-- License check result
RegisterNetEvent('my_weaponShop:licenseResult')
AddEventHandler('my_weaponShop:licenseResult', function(hasLicense)
    if not hasLicense then
        ShowNotification("~r~You need a weapons license!")
        SetNewWaypoint(Config.LicenseCenterLocation.x, Config.LicenseCenterLocation.y)
        ShowNotification("~y~Waypoint set to License Center")
        return
    end

    isShopOpen = true
    local ownedWeapons = GetPlayerWeapons()

    local weapons = {}
    for _, weapon in ipairs(Config.Weapons) do
        table.insert(weapons, {
            name = weapon.name,
            label = weapon.label,
            price = weapon.price,
            ammoPrice = weapon.ammoPrice,
            owned = ownedWeapons[weapon.name] or false,
            isArmor = weapon.isArmor or false
        })
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'openShop', weapons = weapons })
end)

local function CloseWeaponShop()
    if not isShopOpen then return end
    isShopOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeShop' })
end

-- Create blips
CreateThread(function()
    for _, location in ipairs(Config.ShopLocations) do
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, 110)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 1)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Weapon Shop")
        EndTextCommandSetBlipName(blip)
        table.insert(shopBlips, blip)
    end
end)

-- Main loop
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, location in ipairs(Config.ShopLocations) do
            local distance = #(playerCoords - location)

            if distance < 10.0 then
                sleep = 0
                DrawMarker(1, location.x, location.y, location.z, 0, 0, 0, 0, 0, 0,
                    0.5, 0.5, 0.5, 66, 135, 245, 100, false, true, 2, false, nil, nil, false)

                if distance < 1.5 and not isShopOpen then
                    DisplayHelpText("Press ~INPUT_CONTEXT~ to access the Weapon Shop")
                    if IsControlJustPressed(0, 38) then
                        OpenWeaponShop()
                    end
                end
            end
        end

        if isShopOpen and (IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177)) then
            CloseWeaponShop()
        end

        Wait(sleep)
    end
end)

-- NUI Callbacks
RegisterNUICallback('closeShop', function(data, cb)
    CloseWeaponShop()
    cb('ok')
end)

RegisterNUICallback('buyWeapon', function(data, cb)
    TriggerServerEvent('my_weaponShop:buyWeapon', data.name, data.label)
    cb('ok')
end)

RegisterNUICallback('buyAmmo', function(data, cb)
    TriggerServerEvent('my_weaponShop:buyAmmo', data.name, data.label)
    cb('ok')
end)

RegisterNUICallback('buyArmor', function(data, cb)
    TriggerServerEvent('my_weaponShop:buyArmor')
    cb('ok')
end)

-- Server responses
RegisterNetEvent('my_weaponShop:giveWeapon')
AddEventHandler('my_weaponShop:giveWeapon', function(weaponName, ammoCount)
    local playerPed = PlayerPedId()
    GiveWeaponToPed(playerPed, GetHashKey(weaponName), ammoCount, false, true)
    ShowNotification("~g~Weapon purchased!")
    SendNUIMessage({ type = 'updateWeapon', name = weaponName, owned = true })
end)

RegisterNetEvent('my_weaponShop:giveAmmo')
AddEventHandler('my_weaponShop:giveAmmo', function(weaponName, ammoCount)
    local playerPed = PlayerPedId()
    local hash = GetHashKey(weaponName)
    local currentAmmo = GetAmmoInPedWeapon(playerPed, hash)
    SetPedAmmo(playerPed, hash, currentAmmo + ammoCount)
    ShowNotification("~g~Ammo purchased!")
end)

RegisterNetEvent('my_weaponShop:checkAndGiveArmor')
AddEventHandler('my_weaponShop:checkAndGiveArmor', function(price)
    local playerPed = PlayerPedId()
    local currentArmor = GetPedArmour(playerPed)
    
    if currentArmor >= 100 then
        -- Armor is full, add to inventory instead
        TriggerServerEvent('my_weaponShop:addArmorToInventory')
    else
        -- Apply armor directly
        SetPedArmour(playerPed, 100)
        ShowNotification("~g~Armor applied!")
        TriggerEvent('chatMessage', "^2[WeaponShop]^7", "", "Armor equipped for $" .. price)
    end
end)

RegisterNetEvent('my_weaponShop:giveArmor')
AddEventHandler('my_weaponShop:giveArmor', function()
    SetPedArmour(PlayerPedId(), 100)
    ShowNotification("~g~Armor purchased!")
end)

-- Save armor value when player takes damage (periodic sync)
CreateThread(function()
    while true do
        Wait(30000) -- Every 30 seconds
        if hasLoadedWeapons then
            local playerPed = PlayerPedId()
            local currentArmor = GetPedArmour(playerPed)
            TriggerServerEvent('my_weaponShop:syncArmor', currentArmor)
        end
    end
end)

RegisterNetEvent('my_weaponShop:purchaseDenied')
AddEventHandler('my_weaponShop:purchaseDenied', function(reason)
    ShowNotification("~r~" .. reason)
end)

-- Sync current weapons to server periodically (in case weapons are dropped/lost)
CreateThread(function()
    while true do
        Wait(30000) -- Every 30 seconds
        if hasLoadedWeapons then
            local currentWeapons = GetPlayerWeapons()
            TriggerServerEvent('my_weaponShop:syncWeapons', currentWeapons)
        end
    end
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isShopOpen then CloseWeaponShop() end
        for _, blip in pairs(shopBlips) do RemoveBlip(blip) end
        -- Final sync before resource stops
        if hasLoadedWeapons then
            local currentWeapons = GetPlayerWeapons()
            local currentArmor = GetPedArmour(PlayerPedId())
            TriggerServerEvent('my_weaponShop:syncWeapons', currentWeapons)
            TriggerServerEvent('my_weaponShop:syncArmor', currentArmor)
        end
    end
end)
