-- Request money data from server when player is fully loaded
CreateThread(function()
    Wait(3000) -- Wait for everything to load
    TriggerServerEvent('my_money:requestMoney')
end)

-- Update money display
RegisterNetEvent('my_money:updateDisplay')
AddEventHandler('my_money:updateDisplay', function(cash, dirty)
    SendNUIMessage({
        action = 'updateMoney',
        cash = cash,
        dirty = dirty
    })
end)

-- Show notification
function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

-- Flash money on successful transaction
RegisterNetEvent('my_money:flashMoney')
AddEventHandler('my_money:flashMoney', function(moneyType)
    SendNUIMessage({
        action = 'flashMoney',
        type = moneyType
    })
end)


RegisterNetEvent('my_money:transactionResponse')
AddEventHandler('my_money:transactionResponse', function(success, message, moneyType)
    ShowNotification(message)
    
    if success and moneyType then
        TriggerEvent('my_money:flashMoney', moneyType)
    end
end)
