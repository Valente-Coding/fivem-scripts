-- Pawn Shop Client
local isShopOpen = false
local currentShopType = nil

-- ============================================================
-- Notifications
-- ============================================================

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function DisplayHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- ============================================================
-- Blips
-- ============================================================

CreateThread(function()
    for _, loc in ipairs(Config.Locations) do
        local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, loc.blipColor)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(loc.name)
        EndTextCommandSetBlipName(blip)
    end
end)

-- ============================================================
-- Shop Interaction Loop
-- ============================================================

CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, loc in ipairs(Config.Locations) do
            local dist = #(playerCoords - loc.coords)

            if dist < Config.MarkerDistance then
                sleep = 0
                local m = Config.Marker
                DrawMarker(
                    m.type,
                    loc.coords.x, loc.coords.y, loc.coords.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    m.scale.x, m.scale.y, m.scale.z,
                    m.color.r, m.color.g, m.color.b, m.color.a,
                    m.bob, true, 2,
                    m.rotate, nil, nil, false
                )

                if dist < Config.InteractDistance then
                    DisplayHelpText("Press ~INPUT_CONTEXT~ to open ~y~" .. loc.name)

                    if IsControlJustPressed(0, 38) and not isShopOpen then -- E key
                        currentShopType = loc.type
                        TriggerServerEvent('my_pawnshop:requestSellList', loc.type)
                    end
                end
            end
        end

        -- Close on ESC / Backspace
        if isShopOpen and (IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177)) then
            CloseShop()
        end

        Wait(sleep)
    end
end)

-- ============================================================
-- Open / Close Shop
-- ============================================================

function CloseShop()
    if not isShopOpen then return end
    isShopOpen = false
    currentShopType = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeShop' })
end

RegisterNetEvent('my_pawnshop:openShop')
AddEventHandler('my_pawnshop:openShop', function(data)
    isShopOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type     = 'openShop',
        items    = data.items,
        shopName = data.shopName,
        shopType = data.shopType,
    })
end)

RegisterNetEvent('my_pawnshop:updateItems')
AddEventHandler('my_pawnshop:updateItems', function(items)
    if isShopOpen then
        SendNUIMessage({ type = 'updateItems', items = items })
    end
end)

-- ============================================================
-- Sell results
-- ============================================================

RegisterNetEvent('my_pawnshop:sellSuccess')
AddEventHandler('my_pawnshop:sellSuccess', function(itemLabel, price)
    ShowNotification("~g~Sold " .. itemLabel .. " for $" .. FormatNumber(price))
end)

RegisterNetEvent('my_pawnshop:sellDenied')
AddEventHandler('my_pawnshop:sellDenied', function(reason)
    ShowNotification("~r~" .. reason)
end)

-- ============================================================
-- Waypoint from using a pawn item in inventory
-- ============================================================

RegisterNetEvent('my_pawnshop:setWaypoint')
AddEventHandler('my_pawnshop:setWaypoint', function(x, y, shopName, itemLabel, price)
    SetNewWaypoint(x, y)
    ShowNotification("~y~" .. itemLabel .. " (~g~$" .. FormatNumber(price) .. "~y~)\nWaypoint set to ~b~" .. shopName)
end)

-- ============================================================
-- NUI Callbacks
-- ============================================================

RegisterNUICallback('sellItem', function(data, cb)
    if currentShopType then
        TriggerServerEvent('my_pawnshop:sellItem', data.name, currentShopType)
    end
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    CloseShop()
    cb('ok')
end)

-- ============================================================
-- Utility
-- ============================================================

function FormatNumber(n)
    local formatted = tostring(n)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

-- ============================================================
-- Cleanup
-- ============================================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isShopOpen then CloseShop() end
    end
end)
