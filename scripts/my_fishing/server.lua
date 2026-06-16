-- Fishing Server

-- Check fishing license
RegisterNetEvent('my_fishing:checkLicense')
AddEventHandler('my_fishing:checkLicense', function()
    local _source = source
    local hasLicense = true

    if Config.RequireFishingLicense then
        hasLicense = exports['my_licenses']:hasLicense(_source, 'fishing')
    end

    TriggerClientEvent('my_fishing:licenseResult', _source, hasLicense)
end)

-- Catch fish
RegisterNetEvent('my_fishing:catchFish')
AddEventHandler('my_fishing:catchFish', function()
    local _source = source

    -- Verify license server-side
    if Config.RequireFishingLicense then
        local hasLicense = exports['my_licenses']:hasLicense(_source, 'fishing')
        if not hasLicense then return end
    end

    local amount = 0
    local isRare = false

    if math.random(1, 100) <= Config.RareRewardChance then
        amount = math.random(Config.RareRewardsRange[1], Config.RareRewardsRange[2])
        isRare = true
    else
        amount = math.random(Config.RewardsRange[1], Config.RewardsRange[2])
    end

    -- Add money
    exports['my_money']:AddMoney(_source, 'cash', amount)

    -- Update fishing stats
    local stats = exports['my_datamanager']:GetPlayerDataKey(_source, 'fishing') or { fishCaught = 0, moneyEarned = 0 }
    stats.fishCaught = (stats.fishCaught or 0) + 1
    stats.moneyEarned = (stats.moneyEarned or 0) + amount
    exports['my_datamanager']:SetPlayerDataKey(_source, 'fishing', stats)

    TriggerClientEvent('my_fishing:catchResult', _source, amount, isRare)

    if Config.Debug then
        print(string.format("^3[Fishing] %s caught fish worth $%d%s^7",
            GetPlayerName(_source), amount, isRare and " (RARE)" or ""))
    end
end)

-- Request stats
RegisterNetEvent('my_fishing:requestStats')
AddEventHandler('my_fishing:requestStats', function()
    local _source = source
    local stats = exports['my_datamanager']:GetPlayerDataKey(_source, 'fishing') or { fishCaught = 0, moneyEarned = 0 }
    TriggerClientEvent('my_fishing:receiveStats', _source, stats)
end)

-- Stats command
RegisterCommand('fishingstats', function(source, args, rawCommand)
    if source == 0 then return end
    local stats = exports['my_datamanager']:GetPlayerDataKey(source, 'fishing') or { fishCaught = 0, moneyEarned = 0 }
    TriggerClientEvent('chatMessage', source, "^3[Fishing]^7", "",
        "Fish caught: " .. (stats.fishCaught or 0) .. " | Money earned: $" .. (stats.moneyEarned or 0))
end, false)

