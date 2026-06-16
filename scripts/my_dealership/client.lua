-- my_dealership/client.lua
-- Client-side logic for vehicle dealership system

-- Local state
local isNearDealership = false
local isUIOpen = false
local dealershipBlip = nil

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

-- Create dealership blip on map
local function createDealershipBlip()
    -- Validate configs
    if not Config.DealerLocation then
        print("^1[my_dealership ERROR]^7 Config.DealerLocation is missing")
        return nil
    end
    if not Config.Blip then
        print("^1[my_dealership ERROR]^7 Config.Blip is missing")
        return nil
    end
    
    local blip = AddBlipForCoord(Config.DealerLocation.x, Config.DealerLocation.y, Config.DealerLocation.z)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipDisplay(blip, 4) -- Always show on map
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipAsShortRange(blip, true) -- Only show when zoomed in
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.name)
    EndTextCommandSetBlipName(blip)
    
    return blip
end

-- Calculate distance between two 3D points
local function getDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

-- Open dealership UI
local function openDealership()
    if isUIOpen then return end
    
    -- Request vehicles from server (server checks driving license)
    TriggerServerEvent('my_dealership:requestVehicles')
end

-- Receive filtered vehicles from server and show UI
RegisterNetEvent('my_dealership:receiveVehicles')
AddEventHandler('my_dealership:receiveVehicles', function(vehicles, hasDrivingLicense)
    if isUIOpen then return end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    
    -- Send vehicle catalog to UI
    SendNUIMessage({
        action = 'open',
        vehicles = vehicles,
        hasDrivingLicense = hasDrivingLicense
    })
    
    if not hasDrivingLicense then
        -- Brief notification that they need a license for more vehicles
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~y~You need a Driving License to purchase motor vehicles. Visit the License Center!")
        DrawNotification(false, false)
    end
end)

-- Close dealership UI
local function closeDealership()
    if not isUIOpen then return end
    
    isUIOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = 'close'
    })
end

-- ============================================================
-- THREADS
-- ============================================================

-- Main interaction thread - detects E key press at dealership
CreateThread(function()
    while true do
        local sleep = 500 -- Default sleep when not near dealership
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Check distance to dealership
        local distance = getDistance(
            playerCoords.x, playerCoords.y, playerCoords.z,
            Config.DealerLocation.x, Config.DealerLocation.y, Config.DealerLocation.z
        )
        
        if distance <= Config.InteractionDistance then
            isNearDealership = true
            sleep = 0 -- Check every frame when near
            
            -- Draw 3D marker at dealership location
            DrawMarker(
                Config.Marker.type,
                Config.DealerLocation.x,
                Config.DealerLocation.y,
                Config.DealerLocation.z + Config.Marker.zOffset, -- Use configurable Z offset
                0.0, 0.0, 0.0, -- Direction
                0.0, 0.0, 0.0, -- Rotation
                Config.Marker.scale.x,
                Config.Marker.scale.y,
                Config.Marker.scale.z,
                Config.Marker.color.r,
                Config.Marker.color.g,
                Config.Marker.color.b,
                Config.Marker.color.a,
                Config.Marker.bobUpAndDown,
                false, -- Face camera
                2, -- Reserved
                Config.Marker.rotate,
                nil, -- Texture dictionary
                nil, -- Texture name
                false -- Project
            )
            
            -- Draw help text
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to open dealership")
            EndTextCommandDisplayHelp(0, false, true, -1)
            
            -- Check for E key press
            if IsControlJustReleased(0, 38) and not isUIOpen then -- E key
                openDealership()
            end
        else
            isNearDealership = false
        end
        
        Wait(sleep)
    end
end)

-- ESC key handler to close UI
CreateThread(function()
    while true do
        Wait(0)
        
        if isUIOpen then
            -- Disable game controls while UI is open
            DisableControlAction(0, 1, true) -- Mouse look
            DisableControlAction(0, 2, true) -- Mouse look
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 142, true) -- Attack
            DisableControlAction(0, 106, true) -- Vehicle mouse control
            
            -- ESC key to close
            if IsControlJustReleased(0, 322) then -- ESC
                closeDealership()
            end
        else
            Wait(500) -- Reduce checks when UI closed
        end
    end
end)

-- ============================================================
-- EVENTS
-- ============================================================

-- Purchase success - find the vehicle already spawned by vehicleAdded and warp player in.
-- RegisterVehicle broadcasts vehicleAdded to all clients BEFORE this event arrives,
-- so SpawnVehicle has already created the entity with proper tracking and blips.
-- We just need to find it and put the player in it.
RegisterNetEvent('my_dealership:purchaseSuccess')
AddEventHandler('my_dealership:purchaseSuccess', function(data)
    if not data or not data.plate or not data.model then
        print("^1[my_dealership ERROR]^7 Invalid purchase success data")
        return
    end
    
    local plate = data.plate
    local name = data.name or data.model
    
    -- Close UI
    closeDealership()
    
    -- The vehicle was already spawned by my_vehicles:vehicleAdded → SpawnVehicle
    -- (that event fires before this one). Poll the game pool until we find it.
    local vehicle = nil
    local timeout = 0
    
    while timeout < 100 do -- Max 10 seconds
        local allVehicles = GetGamePool('CVehicle')
        for _, veh in pairs(allVehicles) do
            if DoesEntityExist(veh) then
                local vehPlate = GetVehicleNumberPlateText(veh)
                if vehPlate then
                    -- Trim whitespace (GTA pads plates)
                    vehPlate = string.gsub(vehPlate, "^%s*(.-)%s*$", "%1")
                    if vehPlate == plate then
                        vehicle = veh
                        break
                    end
                end
            end
        end
        
        if vehicle then break end
        
        Wait(100)
        timeout = timeout + 1
    end
    
    if not vehicle then
        print("^1[my_dealership ERROR]^7 Vehicle " .. plate .. " did not appear in game pool after purchase")
        return
    end
    
    -- Warp player into the vehicle that SpawnVehicle already created (with blips + tracking)
    local playerPed = PlayerPedId()
    SetVehicleDoorsLocked(vehicle, 1) -- Unlocked
    ClearPedTasksImmediately(playerPed)
    SetPedIntoVehicle(playerPed, vehicle, -1) -- Driver seat
    
    Wait(100)
    
    -- Verify player is in vehicle
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)
    if playerVehicle ~= vehicle then
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
        Wait(100)
    end
    
    -- Turn on engine
    SetVehicleEngineOn(vehicle, true, true, false)
end)

-- Purchase failure - show error
RegisterNetEvent('my_dealership:purchaseFailure')
AddEventHandler('my_dealership:purchaseFailure', function(errorMessage)
    -- Send error to UI
    SendNUIMessage({
        action = 'error',
        message = errorMessage or "Purchase failed"
    })
end)

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

-- Handle purchase request from UI
RegisterNUICallback('purchaseVehicle', function(data, cb)
    if not data or not data.model then
        print("^1[my_dealership ERROR]^7 Invalid NUI callback data")
        cb({ success = false, error = "Invalid data" })
        return
    end
    
    local model = data.model
    
    -- Send purchase request to server
    TriggerServerEvent('my_dealership:purchaseVehicle', model)
    
    cb({ success = true })
end)

-- Handle UI close request
RegisterNUICallback('close', function(data, cb)
    closeDealership()
    cb({ success = true })
end)

-- ============================================================
-- INITIALIZATION
-- ============================================================

-- Create blip on resource start
CreateThread(function()
    dealershipBlip = createDealershipBlip()
end)

-- Cleanup handler - remove blip on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if dealershipBlip then
        RemoveBlip(dealershipBlip)
    end
end)
