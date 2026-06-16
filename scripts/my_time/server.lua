-- Variables to store current time
local currentHour = Config.DefaultHour
local currentMinute = Config.DefaultMinute
local currentDayOfWeek = Config.DefaultDayOfWeek
local currentDaysPassed = Config.DefaultDaysPassed

local dataFileName = "time_data.json"

-- Function to read time data from file
local function ReadTimeData()
    local data = LoadResourceFile(GetCurrentResourceName(), "../saved_data/" .. dataFileName)
    if data and data ~= "" then
        local success, decoded = pcall(json.decode, data)
        if success and decoded then
            return decoded
        else
            print("[my_time] ERROR: Failed to decode time data, using defaults")
        end
    end
    return nil
end

-- Function to write time data to file
local function WriteTimeData()
    local data = {
        hour = currentHour,
        minute = currentMinute,
        dayOfWeek = currentDayOfWeek,
        daysPassed = currentDaysPassed
    }
    
    local jsonStr = json.encode(data, {indent = true})
    local success = SaveResourceFile(GetCurrentResourceName(), "../saved_data/" .. dataFileName, jsonStr, -1)
    
    if success then
        return true
    else
        return false
    end
end

-- Function to initialize time data
local function InitializeTimeData()
    local data = ReadTimeData()
    
    if data then
        -- Load saved time
        currentHour = data.hour or Config.DefaultHour
        currentMinute = data.minute or Config.DefaultMinute
        currentDayOfWeek = data.dayOfWeek or Config.DefaultDayOfWeek
        currentDaysPassed = data.daysPassed or Config.DefaultDaysPassed
    else
        -- Create new save file with defaults
        WriteTimeData()
    end
end

-- Function to broadcast time update to all clients
local function BroadcastTimeUpdate()
    TriggerClientEvent('my_time:updateTime', -1, {
        hour = currentHour,
        minute = currentMinute,
        dayOfWeek = currentDayOfWeek,
        dayName = Config.DayNames[currentDayOfWeek],
        daysPassed = currentDaysPassed
    })
    
    -- Also sync the game time
    TriggerClientEvent('my_time:syncGameTime', -1, currentHour, currentMinute)
end

-- Function to advance time by minutes (handles hour and day rollover)
local function AdvanceTimeByMinutes(minutes)
    currentMinute = currentMinute + minutes
    
    -- Handle minute overflow
    while currentMinute >= 60 do
        currentMinute = currentMinute - 60
        currentHour = currentHour + 1
        
        -- Handle hour overflow (day change)
        if currentHour >= 24 then
            currentHour = 0
            currentDayOfWeek = currentDayOfWeek + 1
            currentDaysPassed = currentDaysPassed + 1
            
            -- Handle week overflow
            if currentDayOfWeek > 7 then
                currentDayOfWeek = 1
            end
        end
    end
end

-- Initialize on resource start
InitializeTimeData()

-- Thread for automatic time progression and auto-save
CreateThread(function()
    while true do
        Wait(2000) -- Wait 2 seconds
        
        -- Advance time by 1 minute
        AdvanceTimeByMinutes(1)
        
        -- Broadcast update to clients
        BroadcastTimeUpdate()
        
        -- Save time data (consolidated with time progression)
        WriteTimeData()
    end
end)

-- Event handler for client requesting current time
RegisterNetEvent('my_time:requestCurrentTime')
AddEventHandler('my_time:requestCurrentTime', function()
    local source = source
    TriggerClientEvent('my_time:updateTime', source, {
        hour = currentHour,
        minute = currentMinute,
        dayOfWeek = currentDayOfWeek,
        dayName = Config.DayNames[currentDayOfWeek],
        daysPassed = currentDaysPassed
    })
    
    TriggerClientEvent('my_time:syncGameTime', source, currentHour, currentMinute)
end)

-- Command to set specific time
RegisterCommand('settime', function(source, args, rawCommand)
    local hour = tonumber(args[1])
    local minute = tonumber(args[2]) or 0
    local day = tonumber(args[3])
    
    if not hour or hour < 0 or hour > 23 then
        print("[my_time] Invalid hour. Usage: /settime <hour> [minute] [day]")
        return
    end
    
    if minute < 0 or minute > 59 then
        print("[my_time] Invalid minute. Must be between 0-59")
        return
    end
    
    if day and (day < 1 or day > 7) then
        print("[my_time] Invalid day. Must be between 1-7 (1=Mon, 7=Sun)")
        return
    end
    
    currentHour = hour
    currentMinute = minute
    if day then
        currentDayOfWeek = day
    end
    
    -- Broadcast update and save
    BroadcastTimeUpdate()
    WriteTimeData()
    
    print("[my_time] Time set to " .. Config.DayNames[currentDayOfWeek] .. " " .. string.format("%02d:%02d", currentHour, currentMinute))
end, false)

-- Command to advance time by hours
RegisterCommand('advancetime', function(source, args, rawCommand)
    local hours = tonumber(args[1])
    
    if not hours or hours < 1 then
        print("[my_time] Invalid hours. Usage: /advancetime <hours>")
        return
    end
    
    -- Convert hours to minutes and advance
    AdvanceTimeByMinutes(hours * 60)
    
    -- Broadcast update and save
    BroadcastTimeUpdate()
    WriteTimeData()
    
    print("[my_time] Time advanced by " .. hours .. " hour(s) to " .. Config.DayNames[currentDayOfWeek] .. " " .. string.format("%02d:%02d", currentHour, currentMinute))
end, false)

-- Export function to advance time by hours (for other scripts)
exports('AdvanceTimeByHours', function(hours)
    if type(hours) ~= 'number' or hours < 0 then
        print("[my_time] ERROR: AdvanceTimeByHours requires a positive number")
        return false
    end
    
    AdvanceTimeByMinutes(hours * 60)
    BroadcastTimeUpdate()
    WriteTimeData()
    
    return true
end)

-- Export function to set specific time (for other scripts)
exports('SetSpecificTime', function(hour, minute, dayOfWeek)
    if type(hour) ~= 'number' or hour < 0 or hour > 23 then
        print("[my_time] ERROR: SetSpecificTime requires valid hour (0-23)")
        return false
    end
    
    minute = minute or 0
    if type(minute) ~= 'number' or minute < 0 or minute > 59 then
        print("[my_time] ERROR: SetSpecificTime requires valid minute (0-59)")
        return false
    end
    
    currentHour = hour
    currentMinute = minute
    
    if dayOfWeek then
        if type(dayOfWeek) ~= 'number' or dayOfWeek < 1 or dayOfWeek > 7 then
            print("[my_time] ERROR: SetSpecificTime requires valid dayOfWeek (1-7)")
            return false
        end
        
        -- Calculate how many days were advanced and update daysPassed
        if dayOfWeek ~= currentDayOfWeek then
            local daysAdvanced = dayOfWeek - currentDayOfWeek
            if daysAdvanced < 0 then
                daysAdvanced = daysAdvanced + 7  -- wrapped around the week
            end
            currentDaysPassed = currentDaysPassed + daysAdvanced
        end
        
        currentDayOfWeek = dayOfWeek
    end
    
    BroadcastTimeUpdate()
    WriteTimeData()
    
    return true
end)

-- Export function to get current time (for other scripts)
exports('GetCurrentTime', function()
    return {
        hour = currentHour,
        minute = currentMinute,
        dayOfWeek = currentDayOfWeek,
        dayName = Config.DayNames[currentDayOfWeek],
        daysPassed = currentDaysPassed
    }
end)
