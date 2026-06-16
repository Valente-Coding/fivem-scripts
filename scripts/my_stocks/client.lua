-- Stock Market Client
-- No ESX dependency - uses event pairs for all server communication

local isUIOpen = false

-- Notification helper
local function ShowNotification(message)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, true)
end

-- Open stock market UI
RegisterCommand('stocks', function()
    if isUIOpen then return end
    TriggerServerEvent('my_stocks:requestData')
end, false)

-- Receive data from server
RegisterNetEvent('my_stocks:receiveData')
AddEventHandler('my_stocks:receiveData', function(data)
    if not data then
        ShowNotification("~r~Failed to load stock market data")
        return
    end

    if not isUIOpen then
        isUIOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            stocks = data.stocks,
            portfolio = data.portfolio,
            cashMoney = data.cashMoney,
            sectorColors = data.sectorColors
        })
    else
        SendNUIMessage({
            action = 'updateData',
            stocks = data.stocks,
            portfolio = data.portfolio,
            cashMoney = data.cashMoney
        })
    end
end)

-- Operation result
RegisterNetEvent('my_stocks:operationResult')
AddEventHandler('my_stocks:operationResult', function(success, message)
    ShowNotification(message)
    SendNUIMessage({ action = 'operationResult', success = success, message = message })
end)

-- Price history result
RegisterNetEvent('my_stocks:priceHistoryResult')
AddEventHandler('my_stocks:priceHistoryResult', function(history)
    SendNUIMessage({ action = 'priceHistory', history = history })
end)

-- Server notification
RegisterNetEvent('my_stocks:notify')
AddEventHandler('my_stocks:notify', function(message)
    ShowNotification(message)
end)

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    isUIOpen = false
    cb('ok')
end)

RegisterNUICallback('buyShares', function(data, cb)
    local companyId = tonumber(data.companyId)
    local shares = tonumber(data.shares)
    if not companyId or not shares then
        ShowNotification("~r~Invalid data")
        cb('ok')
        return
    end
    TriggerServerEvent('my_stocks:buyShares', companyId, shares)
    cb('ok')
end)

RegisterNUICallback('sellShares', function(data, cb)
    local companyId = tonumber(data.companyId)
    local shares = tonumber(data.shares)
    if not companyId or not shares then
        ShowNotification("~r~Invalid data")
        cb('ok')
        return
    end
    TriggerServerEvent('my_stocks:sellShares', companyId, shares)
    cb('ok')
end)

RegisterNUICallback('getPriceHistory', function(data, cb)
    local companyId = tonumber(data.companyId)
    if not companyId then
        cb('ok')
        return
    end
    TriggerServerEvent('my_stocks:getPriceHistory', companyId)
    cb('ok')
end)

RegisterNUICallback('refreshData', function(data, cb)
    TriggerServerEvent('my_stocks:refreshData')
    cb('ok')
end)

-- Close UI with ESC key
CreateThread(function()
    while true do
        if isUIOpen then
            Wait(0)
            if IsControlJustReleased(0, 322) then
                SendNUIMessage({ action = 'close' })
                SetNuiFocus(false, false)
                isUIOpen = false
            end
        else
            Wait(500)
        end
    end
end)
