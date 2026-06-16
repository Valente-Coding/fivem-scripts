-- Store Robbery Server

RegisterNetEvent('my_robberies:giveMoney')
AddEventHandler('my_robberies:giveMoney', function()
    local _source = source
    local moneyAmount = math.random(Config.MinMoney, Config.MaxMoney)

    local success = exports['my_money']:AddMoney(_source, 'cash', moneyAmount)
    if success then
        TriggerClientEvent('chatMessage', _source, "^2[Robbery]^7", "", "You stole $" .. moneyAmount)
    end

    if Config.Debug then
        print(string.format("^3[Robberies] Player %s robbed $%s^7", GetPlayerName(_source), moneyAmount))
    end
end)

