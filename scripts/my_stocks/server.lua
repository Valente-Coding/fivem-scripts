-- Stock Market Server
-- All data stored in stock_data.json within this resource
-- No ESX, no MySQL - uses my_money for cash, my_time for game clock

local StockData = {
    companies = {},
    portfolios = {}         -- { license = { companyIdStr = { shares_owned, total_invested } } }
}
local connectedPlayers = {} -- [source] = license
local lastDividendHour = -1

-- Helper: Format number with commas
local function GroupDigits(amount)
    local formatted = tostring(math.floor(amount))
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Save stock data to file
local function SaveStockData()
    local data = json.encode(StockData)
    SaveResourceFile(GetCurrentResourceName(), 'stock_data.json', data, -1)
end

-- Load stock data from file or initialize from config
local function LoadStockData()
    local data = LoadResourceFile(GetCurrentResourceName(), 'stock_data.json')

    if data and data ~= '' then
        StockData = json.decode(data) or { companies = {}, portfolios = {} }

        if not StockData.portfolios then StockData.portfolios = {} end

        -- Check for new companies added to config
        local existingTickers = {}
        for _, c in ipairs(StockData.companies) do
            existingTickers[c.ticker] = true
        end

        local addedCount = 0
        for _, c in ipairs(Config.DefaultCompanies) do
            if not existingTickers[c.ticker] then
                table.insert(StockData.companies, {
                    id = #StockData.companies + 1,
                    name = c.name,
                    ticker = c.ticker,
                    sector = c.sector,
                    current_price = c.starting_price,
                    starting_price = c.starting_price,
                    max_shares = c.max_shares,
                    shares_sold = 0,
                    dividend_per_share = c.dividend_per_share,
                    volatility = c.volatility,
                    rubberband_strength = c.rubberband_strength,
                    price_history = {}
                })
                addedCount = addedCount + 1
            end
        end

        if addedCount > 0 then
            SaveStockData()
        end

    else
        -- Initialize from config
        StockData = { companies = {}, portfolios = {} }

        for i, c in ipairs(Config.DefaultCompanies) do
            table.insert(StockData.companies, {
                id = i,
                name = c.name,
                ticker = c.ticker,
                sector = c.sector,
                current_price = c.starting_price,
                starting_price = c.starting_price,
                max_shares = c.max_shares,
                shares_sold = 0,
                dividend_per_share = c.dividend_per_share,
                volatility = c.volatility,
                rubberband_strength = c.rubberband_strength,
                price_history = {}
            })
        end

        SaveStockData()
    end
end

-- Build data package for a specific player
local function BuildDataForPlayer(source, license)
    local portfolio = {}
    local playerPortfolio = StockData.portfolios[license] or {}

    for companyIdStr, holding in pairs(playerPortfolio) do
        local companyId = tonumber(companyIdStr)
        for _, company in ipairs(StockData.companies) do
            if company.id == companyId then
                table.insert(portfolio, {
                    company_id = company.id,
                    shares_owned = holding.shares_owned,
                    total_invested = holding.total_invested,
                    name = company.name,
                    ticker = company.ticker,
                    sector = company.sector,
                    current_price = company.current_price,
                    dividend_per_share = company.dividend_per_share
                })
                break
            end
        end
    end

    local cashMoney = exports['my_money']:GetMoney(source, 'cash')

    return {
        stocks = StockData.companies,
        portfolio = portfolio,
        cashMoney = cashMoney,
        sectorColors = Config.SectorColors
    }
end

-- Initialize
CreateThread(function()
    Wait(1000)
    LoadStockData()
    StartPriceFluctuation()
    StartDividendLoop()
end)

-- Player tracking
AddEventHandler('playerDropped', function(reason)
    connectedPlayers[source] = nil
end)

-- Request stock data
RegisterNetEvent('my_stocks:requestData')
AddEventHandler('my_stocks:requestData', function()
    local _source = source
    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if not license then return end

    connectedPlayers[_source] = license

    local data = BuildDataForPlayer(_source, license)
    TriggerClientEvent('my_stocks:receiveData', _source, data)
end)

-- Refresh data
RegisterNetEvent('my_stocks:refreshData')
AddEventHandler('my_stocks:refreshData', function()
    local _source = source
    local license = connectedPlayers[_source]
    if not license then return end

    local data = BuildDataForPlayer(_source, license)
    TriggerClientEvent('my_stocks:receiveData', _source, data)
end)

-- Buy shares
RegisterNetEvent('my_stocks:buyShares')
AddEventHandler('my_stocks:buyShares', function(companyId, shares)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then return end

    shares = tonumber(shares)
    companyId = tonumber(companyId)

    if not shares or shares <= 0 then
        TriggerClientEvent('my_stocks:operationResult', _source, false, 'Invalid share amount')
        return
    end

    -- Find company
    local company = nil
    for _, c in ipairs(StockData.companies) do
        if c.id == companyId then
            company = c
            break
        end
    end

    if not company then
        TriggerClientEvent('my_stocks:operationResult', _source, false, 'Company not found')
        return
    end

    local availableShares = company.max_shares - company.shares_sold
    if shares > availableShares then
        TriggerClientEvent('my_stocks:operationResult', _source, false, 'Not enough shares available')
        return
    end

    local totalCost = shares * company.current_price
    local cash = exports['my_money']:GetMoney(_source, 'cash')

    if cash < totalCost then
        TriggerClientEvent('my_stocks:operationResult', _source, false, 'Insufficient cash')
        return
    end

    -- Remove money
    exports['my_money']:RemoveMoney(_source, 'cash', totalCost)

    -- Update portfolio
    if not StockData.portfolios[license] then
        StockData.portfolios[license] = {}
    end

    local companyIdStr = tostring(companyId)
    local holding = StockData.portfolios[license][companyIdStr]

    if holding then
        holding.shares_owned = holding.shares_owned + shares
        holding.total_invested = holding.total_invested + totalCost
    else
        StockData.portfolios[license][companyIdStr] = {
            shares_owned = shares,
            total_invested = totalCost
        }
    end

    -- Update shares_sold
    company.shares_sold = company.shares_sold + shares

    SaveStockData()

    TriggerClientEvent('my_stocks:operationResult', _source, true,
        'Successfully purchased ' .. shares .. ' shares of ' .. company.ticker)

    local data = BuildDataForPlayer(_source, license)
    TriggerClientEvent('my_stocks:receiveData', _source, data)
end)

-- Sell shares
RegisterNetEvent('my_stocks:sellShares')
AddEventHandler('my_stocks:sellShares', function(companyId, shares)
    local _source = source
    local license = connectedPlayers[_source]
    if not license then return end

    shares = tonumber(shares)
    companyId = tonumber(companyId)

    if not shares or shares <= 0 then
        TriggerClientEvent('my_stocks:operationResult', _source, false, 'Invalid share amount')
        return
    end

    local companyIdStr = tostring(companyId)
    local playerPortfolio = StockData.portfolios[license]

    if not playerPortfolio or not playerPortfolio[companyIdStr] then
        TriggerClientEvent('my_stocks:operationResult', _source, false, "You don't own shares in this company")
        return
    end

    local holding = playerPortfolio[companyIdStr]

    if shares > holding.shares_owned then
        TriggerClientEvent('my_stocks:operationResult', _source, false, "You don't own enough shares")
        return
    end

    -- Find company
    local company = nil
    for _, c in ipairs(StockData.companies) do
        if c.id == companyId then
            company = c
            break
        end
    end

    if not company then
        TriggerClientEvent('my_stocks:operationResult', _source, false, 'Company not found')
        return
    end

    local saleProceeds = shares * company.current_price

    -- Update portfolio
    if shares == holding.shares_owned then
        playerPortfolio[companyIdStr] = nil
    else
        local investmentPerShare = holding.total_invested / holding.shares_owned
        holding.shares_owned = holding.shares_owned - shares
        holding.total_invested = holding.shares_owned * investmentPerShare
    end

    -- Update shares_sold
    company.shares_sold = company.shares_sold - shares

    -- Add money
    exports['my_money']:AddMoney(_source, 'cash', saleProceeds)

    SaveStockData()

    TriggerClientEvent('my_stocks:operationResult', _source, true,
        'Successfully sold ' .. shares .. ' shares of ' .. company.ticker .. ' for $' .. GroupDigits(saleProceeds))

    local data = BuildDataForPlayer(_source, license)
    TriggerClientEvent('my_stocks:receiveData', _source, data)
end)

-- Get price history
RegisterNetEvent('my_stocks:getPriceHistory')
AddEventHandler('my_stocks:getPriceHistory', function(companyId)
    local _source = source
    companyId = tonumber(companyId)

    local history = {}
    for _, company in ipairs(StockData.companies) do
        if company.id == companyId then
            history = company.price_history or {}
            break
        end
    end

    TriggerClientEvent('my_stocks:priceHistoryResult', _source, history)
end)

-- Price fluctuation system with rubberband mechanics
function StartPriceFluctuation()
    CreateThread(function()
        Wait(10000)

        while true do
            Wait(Config.PriceUpdateInterval)

            for _, company in ipairs(StockData.companies) do
                local deviation = ((company.current_price - company.starting_price) / company.starting_price) * 100

                local minChange = -(company.volatility * 0.5)
                local maxChange = company.volatility
                local randomChange = minChange + (math.random() * (maxChange - minChange))

                local rubberbandForce = -deviation * company.rubberband_strength

                local totalChange = randomChange + rubberbandForce
                local newPrice = company.current_price * (1 + (totalChange / 100))
                newPrice = math.max(newPrice, 1)
                newPrice = math.floor(newPrice + 0.5)

                company.current_price = newPrice

                if not company.price_history then
                    company.price_history = {}
                end
                table.insert(company.price_history, {
                    price = newPrice,
                    timestamp = os.time()
                })

                while #company.price_history > Config.MaxHistoryRecords do
                    table.remove(company.price_history, 1)
                end
            end

            SaveStockData()
        end
    end)
end

-- Dividend payment system using in-game time
function StartDividendLoop()
    CreateThread(function()
        Wait(5000)

        while true do
            Wait(60000)

            local currentHour, currentMinute = exports['my_time']:GetCurrentTime()

            for _, schedule in ipairs(Config.DividendSchedule) do
                if currentHour == schedule.h and lastDividendHour ~= currentHour then
                    lastDividendHour = currentHour
                    ProcessDividends()
                end
            end
        end
    end)
end

function ProcessDividends()
    for src, license in pairs(connectedPlayers) do
        local portfolio = StockData.portfolios[license]
        if portfolio then
            local playerDividend = 0

            for companyIdStr, holding in pairs(portfolio) do
                local companyId = tonumber(companyIdStr)
                for _, company in ipairs(StockData.companies) do
                    if company.id == companyId then
                        playerDividend = playerDividend + (holding.shares_owned * company.dividend_per_share)
                        break
                    end
                end
            end

            if playerDividend > 0 then
                exports['my_money']:AddMoney(src, 'cash', playerDividend)
                TriggerClientEvent('my_stocks:notify', src,
                    'Dividend Payment: $' .. GroupDigits(playerDividend) .. ' deposited to your cash')
            end
        end
    end
end

-- Export: Reset a player's stock portfolio (used by permadeath wipe)
exports('ResetPlayerData', function(license)
    if StockData.portfolios[license] then
        -- Return shares to the market
        for companyIdStr, holding in pairs(StockData.portfolios[license]) do
            local companyId = tonumber(companyIdStr)
            for _, company in ipairs(StockData.companies) do
                if company.id == companyId then
                    company.shares_sold = math.max(0, (company.shares_sold or 0) - (holding.shares_owned or 0))
                    break
                end
            end
        end
        StockData.portfolios[license] = nil
        SaveStockData()
    end
end)

