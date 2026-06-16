-- ============================================================
-- my_blackjack | client.lua
-- Client-side: proximity, NUI, input handling
-- ============================================================

local isSeated = false
local mySeat = nil
local uiOpen = false
local nearTable = false

-- ============================================================
-- BLIP
-- ============================================================

CreateThread(function()
    local blip = AddBlipForCoord(Config.TableLocation.x, Config.TableLocation.y, Config.TableLocation.z)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.name)
    EndTextCommandSetBlipName(blip)
end)

-- ============================================================
-- PROXIMITY LOOP
-- ============================================================

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local dist = #(pos - Config.TableLocation)

        if dist < Config.MarkerDistance then
            sleep = 0
            -- Draw marker
            DrawMarker(
                Config.Marker.type,
                Config.TableLocation.x, Config.TableLocation.y, Config.TableLocation.z - 1.0,
                0, 0, 0, 0, 0, 0,
                Config.Marker.scale.x, Config.Marker.scale.y, Config.Marker.scale.z,
                Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
                false, true, 2, false, nil, nil, false
            )

            if dist < Config.InteractDistance then
                nearTable = true
                if not isSeated then
                    -- Show help text
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to sit at the Blackjack table")
                    EndTextCommandDisplayHelp(0, false, true, -1)

                    if IsControlJustPressed(0, 38) then -- E key
                        TriggerServerEvent('my_blackjack:joinTable')
                    end
                end
            else
                nearTable = false
            end
        else
            nearTable = false
            -- Auto-leave if walked too far while seated
            if isSeated and dist > Config.InteractDistance + 5.0 then
                LeaveTable()
            end
        end

        Wait(sleep)
    end
end)

-- ============================================================
-- SEATED / LEFT EVENTS
-- ============================================================

RegisterNetEvent('my_blackjack:seated')
AddEventHandler('my_blackjack:seated', function(seat)
    isSeated = true
    mySeat = seat
    OpenUI()
end)

RegisterNetEvent('my_blackjack:left')
AddEventHandler('my_blackjack:left', function()
    isSeated = false
    mySeat = nil
    CloseUI()
end)

function LeaveTable()
    if isSeated then
        TriggerServerEvent('my_blackjack:leaveTable')
    end
    isSeated = false
    mySeat = nil
    CloseUI()
end

-- ============================================================
-- UI MANAGEMENT
-- ============================================================

function OpenUI()
    if uiOpen then return end
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end

function CloseUI()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ============================================================
-- STATE SYNC FROM SERVER
-- ============================================================

RegisterNetEvent('my_blackjack:updateState')
AddEventHandler('my_blackjack:updateState', function(state, seat)
    mySeat = seat
    SendNUIMessage({
        action = 'updateState',
        state = state,
        mySeat = seat
    })
end)

RegisterNetEvent('my_blackjack:updateBalance')
AddEventHandler('my_blackjack:updateBalance', function(balance)
    SendNUIMessage({
        action = 'updateBalance',
        balance = balance
    })
end)

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

RegisterNetEvent('my_blackjack:notify')
AddEventHandler('my_blackjack:notify', function(msg)
    SendNUIMessage({
        action = 'notify',
        message = msg
    })
    -- Also show as GTA notification
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end)

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback('placeBet', function(data, cb)
    local amount = tonumber(data.amount)
    if amount then
        TriggerServerEvent('my_blackjack:placeBet', amount)
    end
    cb('ok')
end)

RegisterNUICallback('hit', function(_, cb)
    TriggerServerEvent('my_blackjack:hit')
    cb('ok')
end)

RegisterNUICallback('stand', function(_, cb)
    TriggerServerEvent('my_blackjack:stand')
    cb('ok')
end)

RegisterNUICallback('doubleDown', function(_, cb)
    TriggerServerEvent('my_blackjack:doubleDown')
    cb('ok')
end)

RegisterNUICallback('leaveTable', function(_, cb)
    LeaveTable()
    cb('ok')
end)

RegisterNUICallback('closeUI', function(_, cb)
    LeaveTable()
    cb('ok')
end)

-- ============================================================
-- ESC KEY TO LEAVE
-- ============================================================

CreateThread(function()
    while true do
        Wait(0)
        if uiOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 322, true)  -- ESC
            DisableControlAction(0, 199, true)  -- P

            if IsDisabledControlJustPressed(0, 322) then
                LeaveTable()
            end
        end
    end
end)
