-- In-memory cache to prevent duplicate requests (data manager handles caching)
local moneyCache = {}

-- Get player identifier safely
local function GetPlayerLicense(source)
    return exports['my_datamanager']:GetPlayerLicense(source)
end

-- Get player money
local function GetMoney(source)
    if not moneyCache[source] then
        local moneyData = exports['my_datamanager']:GetPlayerDataKey(source, 'money')
        
        if moneyData and moneyData.cash then
            moneyCache[source] = moneyData
        else
            -- Create new player data with defaults
            moneyCache[source] = {
                cash = Config.DefaultMoney.cash,
                dirty = Config.DefaultMoney.dirty
            }
            exports['my_datamanager']:SetPlayerDataKey(source, 'money', moneyCache[source])
        end
    end
    
    return moneyCache[source]
end

-- Set player money
local function SetMoney(source, cash, dirty)
    moneyCache[source] = {
        cash = cash,
        dirty = dirty
    }
    
    -- Save using data manager
    exports['my_datamanager']:SetPlayerDataKey(source, 'money', moneyCache[source])
end

-- Update client display
local function UpdateDisplay(source)
    local money = GetMoney(source)
    TriggerClientEvent('my_money:updateDisplay', source, money.cash, money.dirty)
end

-- Player connecting - preload their data
AddEventHandler('playerConnecting', function()
    local _source = source
    CreateThread(function()
        Wait(1000) -- Wait for player to be ready
        GetMoney(_source) -- Load into cache
    end)
end)

-- Player dropped - clear cache
AddEventHandler('playerDropped', function()
    local _source = source
    if moneyCache[_source] then
        moneyCache[_source] = nil
    end
end)

-- Request money event
RegisterNetEvent('my_money:requestMoney')
AddEventHandler('my_money:requestMoney', function()
    local _source = source
    UpdateDisplay(_source)
end)

-- Admin command: Remove money
RegisterCommand('removemoney', function(source, args, rawCommand)
    if source == 0 then
        print("^1ERROR^7: This command must be run in-game")
        return
    end
    
    local moneyType = args[1]
    local amount = tonumber(args[2])
    
    if not moneyType or not amount or amount <= 0 then
        TriggerClientEvent('chatMessage', source, "^1USAGE^7", "", "/removemoney <cash|dirty> <amount>")
        return
    end
    
    local money = GetMoney(source)
    local success = false
    
    if moneyType == 'cash' then
        if money.cash >= amount then
            money.cash = money.cash - amount
            success = true
        end
    elseif moneyType == 'dirty' then
        if money.dirty >= amount then
            money.dirty = money.dirty - amount
            success = true
        end
    else
        TriggerClientEvent('chatMessage', source, "^1ERROR^7", "", "Invalid type. Use: cash or dirty")
        return
    end
    
    if success then
        SetMoney(source, money.cash, money.dirty)
        UpdateDisplay(source)
        TriggerClientEvent('my_money:transactionResponse', source, true, "~r~Removed $" .. amount .. " " .. moneyType, moneyType)
    else
        TriggerClientEvent('my_money:transactionResponse', source, false, "~r~Insufficient funds", nil)
    end
end, false)

-- Admin command: Set money (self)
RegisterCommand('setmoney', function(source, args, rawCommand)
    if source == 0 then
        print("^1ERROR^7: This command must be run in-game")
        return
    end
    
    local moneyType = args[1]
    local amount = tonumber(args[2])
    
    if not moneyType or not amount or amount < 0 then
        TriggerClientEvent('chatMessage', source, "^1USAGE^7", "", "/setmoney <cash|dirty> <amount>")
        return
    end
    
    local money = GetMoney(source)
    
    if moneyType == 'cash' then
        money.cash = amount
    elseif moneyType == 'dirty' then
        money.dirty = amount
    else
        TriggerClientEvent('chatMessage', source, "^1ERROR^7", "", "Invalid type. Use: cash or dirty")
        return
    end
    
    SetMoney(source, money.cash, money.dirty)
    UpdateDisplay(source)
    TriggerClientEvent('my_money:transactionResponse', source, true, "~b~Set " .. moneyType .. " to $" .. amount, moneyType)
end, false)

-- Admin command: Set money for a player
RegisterCommand('setplayermoney', function(source, args, rawCommand)
    local targetId = tonumber(args[1])
    local moneyType = args[2]
    local amount = tonumber(args[3])

    local function Reply(msg)
        if source == 0 then
            print(msg)
        else
            TriggerClientEvent('chatMessage', source, "^3ADMIN^7", "", msg)
        end
    end

    if not targetId or not moneyType or not amount or amount < 0 then
        Reply("/setplayermoney <playerID> <cash|dirty> <amount>")
        return
    end

    if moneyType ~= 'cash' and moneyType ~= 'dirty' then
        Reply("Invalid type. Use: cash or dirty")
        return
    end

    local targetName = GetPlayerName(targetId)
    if not targetName then
        Reply("Player ID " .. targetId .. " not found")
        return
    end

    local money = GetMoney(targetId)
    if moneyType == 'cash' then
        money.cash = amount
    else
        money.dirty = amount
    end

    SetMoney(targetId, money.cash, money.dirty)
    UpdateDisplay(targetId)

    Reply("Set " .. targetName .. "'s " .. moneyType .. " to $" .. amount .. " (ID: " .. targetId .. ")")
    TriggerClientEvent('my_money:transactionResponse', targetId, true, "~b~" .. moneyType .. " set to $" .. amount, moneyType)
end, true) -- ACE restricted

-- Admin command: Give money to a player
RegisterCommand('givemoney', function(source, args, rawCommand)
    -- Allow from console (source == 0) or in-game
    local targetId = tonumber(args[1])
    local moneyType = args[2]
    local amount = tonumber(args[3])

    local function Reply(msg)
        if source == 0 then
            print(msg)
        else
            TriggerClientEvent('chatMessage', source, "^3ADMIN^7", "", msg)
        end
    end

    if not targetId or not moneyType or not amount or amount <= 0 then
        Reply("/givemoney <playerID> <cash|dirty> <amount>")
        return
    end

    if moneyType ~= 'cash' and moneyType ~= 'dirty' then
        Reply("Invalid type. Use: cash or dirty")
        return
    end

    local targetName = GetPlayerName(targetId)
    if not targetName then
        Reply("Player ID " .. targetId .. " not found")
        return
    end

    local money = GetMoney(targetId)
    if moneyType == 'cash' then
        money.cash = money.cash + amount
    else
        money.dirty = money.dirty + amount
    end

    SetMoney(targetId, money.cash, money.dirty)
    UpdateDisplay(targetId)

    Reply("Gave $" .. amount .. " " .. moneyType .. " to " .. targetName .. " (ID: " .. targetId .. ")")
    TriggerClientEvent('my_money:transactionResponse', targetId, true, "~g~Received $" .. amount .. " " .. moneyType, moneyType)
end, true) -- ACE restricted

-- Export function: Add money
exports('AddMoney', function(source, moneyType, amount)
    -- Validate inputs
    if not source or source == 0 then
        print("^1[Money] ERROR: Invalid source in AddMoney^7")
        return false
    end
    
    if type(amount) ~= 'number' or amount <= 0 or amount ~= amount then
        print("^1[Money] ERROR: Invalid amount in AddMoney^7")
        return false
    end
    
    if moneyType ~= 'cash' and moneyType ~= 'dirty' then
        print("^1[Money] ERROR: Invalid money type in AddMoney^7")
        return false
    end
    
    local money = GetMoney(source)
    
    if moneyType == 'cash' then
        money.cash = money.cash + amount
    elseif moneyType == 'dirty' then
        money.dirty = money.dirty + amount
    end
    
    SetMoney(source, money.cash, money.dirty)
    UpdateDisplay(source)
    return true
end)

-- Export function: Remove money
exports('RemoveMoney', function(source, moneyType, amount)
    -- Validate inputs
    if not source or source == 0 then
        print("^1[Money] ERROR: Invalid source in RemoveMoney^7")
        return false
    end
    
    if type(amount) ~= 'number' or amount <= 0 or amount ~= amount then
        print("^1[Money] ERROR: Invalid amount in RemoveMoney^7")
        return false
    end
    
    if moneyType ~= 'cash' and moneyType ~= 'dirty' then
        print("^1[Money] ERROR: Invalid money type in RemoveMoney^7")
        return false
    end
    
    local money = GetMoney(source)
    
    if moneyType == 'cash' then
        if money.cash >= amount then
            money.cash = money.cash - amount
        else
            return false
        end
    elseif moneyType == 'dirty' then
        if money.dirty >= amount then
            money.dirty = money.dirty - amount
        else
            return false
        end
    end
    
    SetMoney(source, money.cash, money.dirty)
    UpdateDisplay(source)
    return true
end)

-- Export function: Set money
exports('SetMoney', function(source, moneyType, amount)
    -- Validate inputs
    if not source or source == 0 then
        print("^1[Money] ERROR: Invalid source in SetMoney^7")
        return false
    end
    
    if type(amount) ~= 'number' or amount < 0 or amount ~= amount then
        print("^1[Money] ERROR: Invalid amount in SetMoney^7")
        return false
    end
    
    if moneyType ~= 'cash' and moneyType ~= 'dirty' then
        print("^1[Money] ERROR: Invalid money type in SetMoney^7")
        return false
    end
    
    local money = GetMoney(source)
    
    if moneyType == 'cash' then
        money.cash = amount
    elseif moneyType == 'dirty' then
        money.dirty = amount
    end
    
    SetMoney(source, money.cash, money.dirty)
    UpdateDisplay(source)
    return true
end)

-- Export function: Get money
exports('GetMoney', function(source, moneyType)
    -- Validate inputs
    if not source or source == 0 then
        print("^1[Money] ERROR: Invalid source in GetMoney^7")
        return 0
    end
    
    if moneyType ~= 'cash' and moneyType ~= 'dirty' then
        print("^1[Money] ERROR: Invalid money type in GetMoney^7")
        return 0
    end
    
    local money = GetMoney(source)
    
    if moneyType == 'cash' then
        return money.cash
    elseif moneyType == 'dirty' then
        return money.dirty
    else
        return 0
    end
end)