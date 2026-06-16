-- my_mechanicShop/server.lua

RegisterNetEvent('my_mechanicshop:buyTools')
AddEventHandler('my_mechanicshop:buyTools', function()
    local _source = source
    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if not license then return end

    local cash = exports['my_money']:GetMoney(_source, 'cash')
    if cash < Config.MechanicTools.price then
        TriggerClientEvent('my_mechanicshop:notify', _source, false,
            'You need $' .. Config.MechanicTools.price .. ' to buy Mechanic Tools')
        return
    end

    local houses = exports['my_housing']:GetPlayerHouses(license)
    local available = {}
    for _, h in ipairs(houses or {}) do
        if h.rented == 0 then
            table.insert(available, h)
        end
    end

    if not houses or #houses == 0 then
        TriggerClientEvent('my_mechanicshop:notify', _source, false,
            'You need to own a house before buying Mechanic Tools')
    elseif #available == 0 then
        TriggerClientEvent('my_mechanicshop:notify', _source, false,
            'All of your houses are currently rented out')
    else
        TriggerClientEvent('my_mechanicshop:showHouses', _source, available)
    end
end)

RegisterNetEvent('my_mechanicshop:confirmPurchase')
AddEventHandler('my_mechanicshop:confirmPurchase', function(houseId)
    local _source = source
    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if not license then return end

    local cash = exports['my_money']:GetMoney(_source, 'cash')
    if cash < Config.MechanicTools.price then
        TriggerClientEvent('my_mechanicshop:notify', _source, false, 'You no longer have enough cash')
        return
    end

    exports['my_money']:RemoveMoney(_source, 'cash', Config.MechanicTools.price)

    local success, err = exports['my_housing']:AddItemToHouseStorage(
        houseId, license, Config.MechanicTools.name, 1)

    if not success then
        exports['my_money']:AddMoney(_source, 'cash', Config.MechanicTools.price)
        TriggerClientEvent('my_mechanicshop:notify', _source, false, err or 'Could not deliver Mechanic Tools')
        return
    end

    TriggerClientEvent('my_mechanicshop:notify', _source, true, 'Mechanic Tools delivered to your house!')
end)
