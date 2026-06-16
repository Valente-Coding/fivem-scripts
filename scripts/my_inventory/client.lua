-- Inventory Client
local isMenuOpen = false

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

-- Key opening disabled - inventory accessible only through phone
-- CreateThread(function()
--     while true do
--         Wait(0)
--         if IsControlJustPressed(0, Config.OpenKey) and not isMenuOpen then
--             TriggerServerEvent('my_inventory:requestData')
--         end
--         if isMenuOpen and (IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177)) then
--             CloseMenu()
--         end
--     end
-- end)

function CloseMenu()
    if not isMenuOpen then return end
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
end

-- Server sends full item list
RegisterNetEvent('my_inventory:openMenu')
AddEventHandler('my_inventory:openMenu', function(data)
    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type       = 'open',
        items      = data.items,
        categories = data.categories
    })
end)

-- Server sends updated item list (after using an item)
RegisterNetEvent('my_inventory:updateItems')
AddEventHandler('my_inventory:updateItems', function(items)
    if isMenuOpen then
        SendNUIMessage({ type = 'updateItems', items = items })
    end
end)

RegisterNetEvent('my_inventory:notify')
AddEventHandler('my_inventory:notify', function(msg)
    ShowNotification(msg)
end)

-- When an item is used client-side, other scripts can listen for this
RegisterNetEvent('my_inventory:onItemUsed')
AddEventHandler('my_inventory:onItemUsed', function(itemName)
    -- Future: handle client-side effects per item (animations, etc.)
end)

-- Apply armor from inventory
RegisterNetEvent('my_inventory:applyArmor')
AddEventHandler('my_inventory:applyArmor', function()
    local playerPed = PlayerPedId()
    local currentArmor = GetPedArmour(playerPed)
    
    if currentArmor >= 100 then
        ShowNotification("~y~Your armor is already full!")
    else
        SetPedArmour(playerPed, 100)
        ShowNotification("~g~Body Armor equipped!")
    end
end)

-- NUI Callbacks
RegisterNUICallback('useItem', function(data, cb)
    TriggerServerEvent('my_inventory:useItem', data.name)
    cb('ok')
end)

RegisterNUICallback('deleteItem', function(data, cb)
    TriggerServerEvent('my_inventory:deleteItem', data.name)
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    CloseMenu()
    cb('ok')
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isMenuOpen then CloseMenu() end
    end
end)
