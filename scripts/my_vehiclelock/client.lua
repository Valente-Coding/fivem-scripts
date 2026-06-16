-- my_vehiclelock/client.lua
-- Vehicle Lock/Unlock System
-- Press N near your owned vehicle to toggle lock. State persists via global_vehicles.json.
-- Lock state is applied instantly on all clients.

-- ============================================================
-- CONFIGURATION
-- ============================================================

local LOCK_RANGE    = 15.0       -- max distance to lock/unlock
local HORN_DURATION = 300        -- ms to honk the horn on lock/unlock

-- ============================================================
-- STATE
-- ============================================================

local lockStates   = {}   -- plate -> bool (true = locked)
local myLicense    = nil
local allVehicles  = {}   -- mirror of vehicle registry
local dataReady    = false

-- ============================================================
-- UTILITY
-- ============================================================

local function TrimPlate(plate)
    if not plate then return "" end
    return string.upper(string.gsub(tostring(plate), "%s+", ""))
end

local function ShowSubtitle(text, duration)
    BeginTextCommandPrint("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandPrint(duration or 3000, true)
end

-- Check if a vehicle belongs to this player
local function IsMyVehicle(plate)
    if not myLicense or not plate then return false end
    local data = allVehicles[plate]
    return data and data.owner == myLicense
end

-- Find a spawned vehicle entity by plate in the game pool
local function FindVehicleByPlate(plate)
    plate = TrimPlate(plate)
    local pool = GetGamePool('CVehicle')
    for _, veh in pairs(pool) do
        if DoesEntityExist(veh) then
            local vehPlate = GetVehicleNumberPlateText(veh)
            if vehPlate and TrimPlate(vehPlate) == plate then
                return veh
            end
        end
    end
    return nil
end

-- Find the nearest owned vehicle within range
local function GetNearestOwnedVehicle()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local bestPlate, bestEntity, bestDist = nil, nil, LOCK_RANGE + 1

    local pool = GetGamePool('CVehicle')
    for _, veh in pairs(pool) do
        if DoesEntityExist(veh) then
            local vehPlate = TrimPlate(GetVehicleNumberPlateText(veh))
            if IsMyVehicle(vehPlate) then
                local dist = #(playerCoords - GetEntityCoords(veh))
                if dist < bestDist then
                    bestPlate = vehPlate
                    bestEntity = veh
                    bestDist = dist
                end
            end
        end
    end

    if bestDist <= LOCK_RANGE then
        return bestPlate, bestEntity
    end
    return nil, nil
end

-- Apply lock state to a vehicle entity instantly
local function ApplyLockToEntity(entity, locked)
    if not entity or not DoesEntityExist(entity) then return end
    if locked then
        SetVehicleDoorsLocked(entity, 2)  -- locked
    else
        SetVehicleDoorsLocked(entity, 1)  -- unlocked
    end
end

-- Play a quick horn beep for feedback
local function HonkHorn(entity)
    if not entity or not DoesEntityExist(entity) then return end
    StartVehicleHorn(entity, HORN_DURATION, GetHashKey("NORMAL"), false)
end

-- Flash vehicle lights for visual feedback
local function FlashLights(entity, times)
    if not entity or not DoesEntityExist(entity) then return end
    CreateThread(function()
        for i = 1, (times or 2) do
            SetVehicleLights(entity, 2) -- on
            Wait(120)
            SetVehicleLights(entity, 1) -- off
            Wait(120)
        end
        SetVehicleLights(entity, 0) -- reset to default
    end)
end

-- ============================================================
-- RECEIVE DATA FROM OTHER SCRIPTS
-- ============================================================

-- Listen for the vehicle registry from my_vehicles
RegisterNetEvent('my_vehicles:loadAllVehicles')
AddEventHandler('my_vehicles:loadAllVehicles', function(vehicles, license)
    allVehicles = vehicles or {}
    if license then myLicense = license end
end)

-- Track new vehicles added
RegisterNetEvent('my_vehicles:vehicleAdded')
AddEventHandler('my_vehicles:vehicleAdded', function(plate, vehicleData)
    if not plate or not vehicleData then return end
    allVehicles[plate] = vehicleData
    -- New vehicles default to unlocked
    if lockStates[plate] == nil then
        lockStates[plate] = false
    end

    -- Apply lock state to spawned entity if it exists
    local entity = FindVehicleByPlate(plate)
    if entity then
        ApplyLockToEntity(entity, lockStates[plate])
    end
end)

-- Track removed vehicles
RegisterNetEvent('my_vehicles:vehicleRemoved')
AddEventHandler('my_vehicles:vehicleRemoved', function(plate)
    if not plate then return end
    allVehicles[plate] = nil
    lockStates[plate] = nil
end)

-- ============================================================
-- LOCK STATE FROM SERVER
-- ============================================================

-- Receive initial lock states on join
RegisterNetEvent('my_vehiclelock:loadLockStates')
AddEventHandler('my_vehiclelock:loadLockStates', function(states)
    lockStates = states or {}
    dataReady = true

    -- Apply lock states to any already-spawned vehicles
    local pool = GetGamePool('CVehicle')
    for _, veh in pairs(pool) do
        if DoesEntityExist(veh) then
            local plate = TrimPlate(GetVehicleNumberPlateText(veh))
            if lockStates[plate] ~= nil then
                ApplyLockToEntity(veh, lockStates[plate])
            end
        end
    end
end)

-- Server broadcasts a lock state change (instant for all clients)
RegisterNetEvent('my_vehiclelock:applyLockState')
AddEventHandler('my_vehiclelock:applyLockState', function(plate, locked)
    if not plate then return end
    plate = TrimPlate(plate)
    lockStates[plate] = locked

    -- Find the entity in the game world and apply instantly
    local entity = FindVehicleByPlate(plate)
    if entity then
        ApplyLockToEntity(entity, locked)

        -- Visual/audio feedback for nearby players
        if locked then
            HonkHorn(entity)
            FlashLights(entity, 2)
        else
            FlashLights(entity, 1)
        end
    end
end)

-- ============================================================
-- ENFORCE LOCK STATE ON SPAWNED VEHICLES
-- Periodically checks spawned vehicles and applies the correct
-- lock state. Catches vehicles that were just streamed in.
-- ============================================================

CreateThread(function()
    while true do
        Wait(2000)
        if not dataReady then goto continue end

        local pool = GetGamePool('CVehicle')
        for _, veh in pairs(pool) do
            if DoesEntityExist(veh) then
                local plate = TrimPlate(GetVehicleNumberPlateText(veh))
                if lockStates[plate] ~= nil then
                    local currentStatus = GetVehicleDoorLockStatus(veh)
                    local shouldBeLocked = lockStates[plate]

                    if shouldBeLocked and currentStatus ~= 2 then
                        SetVehicleDoorsLocked(veh, 2)
                    elseif not shouldBeLocked and currentStatus == 2 then
                        SetVehicleDoorsLocked(veh, 1)
                    end
                end
            end
        end

        ::continue::
    end
end)

-- ============================================================
-- LOCK/UNLOCK INPUT (L KEY via RegisterKeyMapping)
-- ============================================================

local function ToggleNearestVehicleLock()
    if not dataReady or not myLicense then
        print('[my_vehiclelock] Not ready yet (dataReady=' .. tostring(dataReady) .. ', myLicense=' .. tostring(myLicense ~= nil) .. ')')
        return
    end

    -- Only allow when player is on foot
    if IsPedInAnyVehicle(PlayerPedId(), false) then return end

    local plate, entity = GetNearestOwnedVehicle()
    if plate and entity then
        -- Request toggle from server (server will broadcast the result)
        TriggerServerEvent('my_vehiclelock:toggleLock', plate)
        local willBeLocked = not lockStates[plate]
        if willBeLocked then
            ShowSubtitle("~r~Vehicle locked")
        else
            ShowSubtitle("~g~Vehicle unlocked")
        end
    end
end

RegisterCommand('vehiclelock', function()
    ToggleNearestVehicleLock()
end, false)

RegisterKeyMapping('vehiclelock', 'Lock/Unlock Vehicle', 'keyboard', 'n')

-- ============================================================
-- INITIALIZATION
-- Request both vehicle data AND lock states.
-- Retries if data is not received within a reasonable time.
-- ============================================================

CreateThread(function()
    Wait(6000) -- let my_vehicles load first

    -- Request vehicle registry (sets myLicense + allVehicles)
    TriggerServerEvent('my_vehicles:requestAllVehicles')
    Wait(2000)

    -- Request lock states
    TriggerServerEvent('my_vehiclelock:requestLockStates')

    -- Retry up to 5 times if data didn't arrive
    for attempt = 1, 5 do
        Wait(3000)
        if dataReady and myLicense then
            print('[my_vehiclelock] Initialized successfully (license=' .. tostring(myLicense) .. ')')
            return
        end

        print('[my_vehiclelock] Retry #' .. attempt .. ' (dataReady=' .. tostring(dataReady) .. ', myLicense=' .. tostring(myLicense ~= nil) .. ')')

        if not myLicense then
            TriggerServerEvent('my_vehicles:requestAllVehicles')
            Wait(1000)
        end

        if not dataReady then
            TriggerServerEvent('my_vehiclelock:requestLockStates')
        end
    end

    print('[my_vehiclelock] WARNING: Initialization incomplete after retries')
end)

-- ============================================================
-- CLEANUP
-- ============================================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    lockStates = {}
end)
