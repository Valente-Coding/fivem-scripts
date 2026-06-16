-- Ambient Police Vehicle Script
-- Controls the spawning of random police vehicles and peds in the game world
-- Uses native GTA V spawn points for police stations and parked vehicles

-- Local variables
local enabledRandomCops = Config.EnableRandomCops
local enabledStationPolice = Config.EnableStationPolice
local enabledParkedPoliceVehicles = Config.EnableParkedPoliceVehicles
local enabledPoliceAutomobile = Config.EnablePoliceAutomobile
local enabledPoliceHelicopters = Config.EnablePoliceHelicopters
local enabledBoats = Config.EnableBoats
local trafficDensity = Config.TrafficDensity
local pedDensity = Config.PedDensity
local scenarioPedDensity = Config.ScenarioPedDensity

-- Function to notify player using native FiveM notifications
function Notify(message)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(message)
    DrawNotification(false, false)
end

-- Initial setup when resource starts
CreateThread(function()

    -- Display initialization message
    Wait(2000) -- Wait 2 seconds before showing notification
    
    -- Set initial spawning settings
    SetPoliceVehicleSpawning()
end)

-- Main thread for controlling police vehicles
function SetPoliceVehicleSpawning()
    -- Enable/disable police spawning features based on config
    CreateThread(function()
        -- Set initial values once
        SetCreateRandomCops(enabledRandomCops)
        SetCreateRandomCopsNotOnScenarios(enabledRandomCops)
        SetCreateRandomCopsOnScenarios(enabledStationPolice) -- This spawns cops at police stations
        SetPoliceIgnorePlayer(not enabledPoliceAutomobile)
        SetPoliceRadarBlips(enabledPoliceHelicopters)
        EnableDispatchService(1, enabledPoliceHelicopters) -- 1 = DISPATCH_TYPE_POLICE_HELICOPTER
        EnableDispatchService(2, enabledPoliceAutomobile) -- 2 = DISPATCH_TYPE_POLICE_AUTOMOBILE
        EnableDispatchService(3, enabledPoliceAutomobile) -- 3 = DISPATCH_TYPE_FIRE_DEPARTMENT
        EnableDispatchService(4, enabledPoliceAutomobile) -- 4 = DISPATCH_TYPE_AMBULANCE
        EnableDispatchService(5, enabledPoliceAutomobile) -- 5 = DISPATCH_TYPE_SWAT
        EnableDispatchService(6, enabledBoats)          -- 6 = DISPATCH_TYPE_COAST_GUARD
        EnableDispatchService(7, enabledPoliceAutomobile) -- 7 = DISPATCH_TYPE_ARMY
        
        -- Enable scenario types for parked police vehicles (native spawn points)
        if enabledParkedPoliceVehicles then
            SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_CAR", true)
            SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_BIKE", true)
            SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE", true)
        else
            SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_CAR", false)
            SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_BIKE", false)
            SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE", false)
        end
        
        while true do
            -- Set density multipliers every frame
            SetVehicleDensityMultiplierThisFrame(trafficDensity)
            SetPedDensityMultiplierThisFrame(pedDensity)
            SetScenarioPedDensityMultiplierThisFrame(scenarioPedDensity, scenarioPedDensity)
            
            Wait(0) -- These need to be called every frame
        end
    end)
end

-- Command to toggle police vehicles
RegisterCommand('togglepolicecars', function(source, args, rawCommand)
    enabledRandomCops = not enabledRandomCops
    enabledPoliceAutomobile = enabledRandomCops
    
    -- Apply changes immediately
    SetCreateRandomCops(enabledRandomCops)
    SetCreateRandomCopsNotOnScenarios(enabledRandomCops)
    SetPoliceIgnorePlayer(not enabledPoliceAutomobile)
    EnableDispatchService(2, enabledPoliceAutomobile)
    EnableDispatchService(3, enabledPoliceAutomobile)
    EnableDispatchService(4, enabledPoliceAutomobile)
    EnableDispatchService(5, enabledPoliceAutomobile)
    EnableDispatchService(7, enabledPoliceAutomobile)
    
    if enabledRandomCops then
        Notify("~g~Ambient police vehicles enabled")
    else
        Notify("~r~Ambient police vehicles disabled")
    end
end, false)

-- Command to toggle station police
RegisterCommand('togglestationpolice', function(source, args, rawCommand)
    enabledStationPolice = not enabledStationPolice
    
    -- Apply changes immediately
    SetCreateRandomCopsOnScenarios(enabledStationPolice)
    
    if enabledStationPolice then
        Notify("~g~Police station officers enabled (native)")
    else
        Notify("~r~Police station officers disabled")
    end
end, false)

-- Command to toggle parked police vehicles
RegisterCommand('toggleparkedpolice', function(source, args, rawCommand)
    enabledParkedPoliceVehicles = not enabledParkedPoliceVehicles
    
    -- Apply changes immediately
    if enabledParkedPoliceVehicles then
        SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_CAR", true)
        SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_BIKE", true)
        SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE", true)
        Notify("~g~Parked police vehicles enabled (native)")
    else
        SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_CAR", false)
        SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_BIKE", false)
        SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE", false)
        Notify("~r~Parked police vehicles disabled")
    end
end, false)

-- Command to toggle police helicopters
RegisterCommand('togglepolicehelis', function(source, args, rawCommand)
    enabledPoliceHelicopters = not enabledPoliceHelicopters
    
    -- Apply changes immediately
    SetPoliceRadarBlips(enabledPoliceHelicopters)
    EnableDispatchService(1, enabledPoliceHelicopters)
    
    if enabledPoliceHelicopters then
        Notify("~g~Police helicopters enabled")
    else
        Notify("~r~Police helicopters disabled")
    end
end, false)

-- Command to toggle traffic density
RegisterCommand('settraffic', function(source, args, rawCommand)
    if args[1] and tonumber(args[1]) then
        local density = tonumber(args[1])
        if density >= 0.0 and density <= 1.0 then
            trafficDensity = density
            Notify("Traffic density set to: " .. density)
        else
            Notify("Density must be between 0.0 and 1.0")
        end
    else
        Notify("Usage: /settraffic [0.0-1.0]")
    end
end, false)

-- Command to display current status
RegisterCommand('policestatus', function(source, args, rawCommand)
    local status = "Police Cars: " .. (enabledRandomCops and "~g~ON" or "~r~OFF") ..
                  "~s~\nStation Police: " .. (enabledStationPolice and "~g~ON" or "~r~OFF") ..
                  "~s~\nParked Vehicles: " .. (enabledParkedPoliceVehicles and "~g~ON" or "~r~OFF") ..
                  "~s~\nPolice Helicopters: " .. (enabledPoliceHelicopters and "~g~ON" or "~r~OFF") ..
                  "~s~\nTraffic Density: " .. trafficDensity
                  
    Notify(status)
end, false)

-- Add chat suggestions for the commands
CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/togglepolicecars', 'Toggle ambient police vehicles on streets')
    TriggerEvent('chat:addSuggestion', '/togglestationpolice', 'Toggle police officers at stations (native)')
    TriggerEvent('chat:addSuggestion', '/toggleparkedpolice', 'Toggle parked police vehicles (native)')
    TriggerEvent('chat:addSuggestion', '/togglepolicehelis', 'Toggle police helicopter spawns')
    TriggerEvent('chat:addSuggestion', '/settraffic', 'Set traffic density', {
        { name="density", help="Traffic density (0.0-1.0)" }
    })
    TriggerEvent('chat:addSuggestion', '/policestatus', 'Show current police spawn settings')
end)

