-- my_oillevel/client.lua
-- Oil drain per km, fault effects (speed cap, stalling, smoke), oil bottle usage

local isFaulty          = false  -- currently in fault state
local savedEngineHealth = nil    -- saved real engine health before fault
local faultyEngineHealth = nil   -- randomized engine health while faulty
local isStalling        = false  -- stall in progress
local lastDrainPos      = nil    -- last position for drain calc
local oilSyncPending    = false  -- flag for pending server sync
local isRefilling       = false  -- oil bottle animation in progress
local lowOilWarned      = false  -- debounce low-oil notification

-- ============================================================
-- HELPERS
-- ============================================================

local function Plate(p)
    if not p then return "" end
    return string.upper(string.gsub(tostring(p), '%s+', ''))
end

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function GetOilLevel(plate)
    local ok, val = pcall(function()
        return exports['my_vehicles']:GetVehicleOilLevel(plate)
    end)
    if ok and val then return val end
    return 100.0
end

local function SetOilLevel(plate, level)
    level = math.max(0.0, math.min(Config.MaxOil, level))
    pcall(function()
        exports['my_vehicles']:SetVehicleOilLevel(plate, level)
    end)
    return level
end

local function IsOwnedVehicle(plate)
    local ok, data = pcall(function()
        return exports['my_vehicles']:DoesPlateExist(plate)
    end)
    return ok and data
end

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    local attempts = 0
    while not HasAnimDictLoaded(dict) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end
    return HasAnimDictLoaded(dict)
end

-- ============================================================
-- ENGINE SMOKE (uses GTA's built-in engine damage smoke)
-- Below 300 = white smoke, below 100 = black smoke from hood
-- ============================================================

local function StartSmoke(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    savedEngineHealth = GetVehicleEngineHealth(vehicle)
    local pct = Config.OilDepletedEngineHealthMin + math.random() * (Config.OilDepletedEngineHealthMax - Config.OilDepletedEngineHealthMin)
    faultyEngineHealth = (pct / 100.0) * 1000.0
    SetVehicleEngineHealth(vehicle, faultyEngineHealth)
end

local function StopSmoke(vehicle)
    if vehicle and DoesEntityExist(vehicle) and savedEngineHealth then
        SetVehicleEngineHealth(vehicle, savedEngineHealth)
    end
    savedEngineHealth = nil
    faultyEngineHealth = nil
end

-- ============================================================
-- FAULT STATE MANAGEMENT
-- ============================================================

local function EnterFaultState(vehicle)
    if isFaulty then return end
    isFaulty = true

    if vehicle and DoesEntityExist(vehicle) then
        SetVehicleMaxSpeed(vehicle, Config.FaultySpeedCap / 3.6)
        StartSmoke(vehicle)
    end

    ShowNotification("~r~WARNING: Engine oil depleted! Vehicle is breaking down!")

    -- Per-frame loop to enforce power/torque reduction and engine smoke
    CreateThread(function()
        while isFaulty do
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh and veh ~= 0 and DoesEntityExist(veh) then
                SetVehicleEnginePowerMultiplier(veh, Config.FaultyPowerMultiplier)
                SetVehicleEngineTorqueMultiplier(veh, Config.FaultyTorqueMultiplier)
                -- Keep engine health at the randomized faulty value so smoke keeps rendering
                SetVehicleEngineHealth(veh, faultyEngineHealth)
            end
            Wait(0)
        end
    end)
end

local function ExitFaultState(vehicle)
    if not isFaulty then return end
    isFaulty = false
    isStalling = false

    if vehicle and DoesEntityExist(vehicle) then
        SetVehicleMaxSpeed(vehicle, 0.0)
        SetVehicleEnginePowerMultiplier(vehicle, 1.0)
        SetVehicleEngineTorqueMultiplier(vehicle, 1.0)
    end

    StopSmoke(vehicle)
end

-- ============================================================
-- OIL DRAIN LOOP
-- Runs every Config.DrainCheckInterval ms while player is
-- driving an owned vehicle. Drains oil based on distance.
-- ============================================================

CreateThread(function()
    while true do
        Wait(Config.DrainCheckInterval)

        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            lastDrainPos = nil
            goto continue
        end

        local vehicle = GetVehiclePedIsIn(ped, false)
        if not vehicle or vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
            lastDrainPos = nil
            goto continue
        end

        local plate = Plate(GetVehicleNumberPlateText(vehicle))
        if not IsOwnedVehicle(plate) then
            lastDrainPos = nil
            goto continue
        end

        local curPos = GetEntityCoords(vehicle)

        if lastDrainPos then
            local dist = #(curPos - lastDrainPos)
            if dist > 1.0 then -- ignore jitter
                local km = dist / 1000.0
                local drain = km * Config.OilDrainPerKm
                local currentOil = GetOilLevel(plate)
                local newOil = SetOilLevel(plate, currentOil - drain)

                -- Low oil warning (once)
                if newOil <= Config.LowOilThreshold and newOil > Config.CriticalOilThreshold and not lowOilWarned then
                    lowOilWarned = true
                    ShowNotification("~o~WARNING: Oil level is low! Get an oil change soon.")
                end

                -- Reset warning flag when above threshold
                if newOil > Config.LowOilThreshold then
                    lowOilWarned = false
                end

                lastDrainPos = curPos
            end
        else
            lastDrainPos = curPos
        end

        ::continue::
    end
end)

-- ============================================================
-- OIL SYNC LOOP
-- Pushes current oil level to server periodically.
-- ============================================================

CreateThread(function()
    while true do
        Wait(Config.OilSyncInterval)

        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then goto continue end

        local vehicle = GetVehiclePedIsIn(ped, false)
        if not vehicle or vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then goto continue end

        local plate = Plate(GetVehicleNumberPlateText(vehicle))
        if not IsOwnedVehicle(plate) then goto continue end

        local oil = GetOilLevel(plate)
        TriggerServerEvent('my_vehicles:updateOilLevel', plate, oil)

        ::continue::
    end
end)

-- ============================================================
-- FAULT EFFECTS LOOP
-- When oil = 0: speed cap, random stalling, smoke
-- ============================================================

CreateThread(function()
    while true do
        Wait(Config.FaultTickInterval)

        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            if isFaulty then
                local lastVeh = GetVehiclePedIsIn(ped, true)
                ExitFaultState(lastVeh)
            end
            goto continue
        end

        local vehicle = GetVehiclePedIsIn(ped, false)
        if not vehicle or vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
            goto continue
        end

        local plate = Plate(GetVehicleNumberPlateText(vehicle))
        if not IsOwnedVehicle(plate) then
            if isFaulty then ExitFaultState(vehicle) end
            goto continue
        end

        local oil = GetOilLevel(plate)

        if oil <= Config.CriticalOilThreshold then
            -- Enter fault state if not already
            if not isFaulty then
                EnterFaultState(vehicle)
            end

            -- Keep speed cap enforced (in case game resets it)
            SetVehicleMaxSpeed(vehicle, Config.FaultySpeedCap / 3.6)

            -- Engine chugging / misfiring
            if not isStalling and math.random() < Config.StallChance then
                isStalling = true
                CreateThread(function()
                    local chugs = math.random(Config.ChugCountMin, Config.ChugCountMax)
                    for i = 1, chugs do
                        if not isFaulty or not vehicle or not DoesEntityExist(vehicle) then break end
                        SetVehicleEngineOn(vehicle, false, true, true)
                        Wait(math.random(Config.ChugOffMin, Config.ChugOffMax))
                        if not isFaulty or not vehicle or not DoesEntityExist(vehicle) then break end
                        SetVehicleEngineOn(vehicle, true, false, true)
                        Wait(math.random(Config.ChugOnMin, Config.ChugOnMax))
                    end
                    isStalling = false
                end)
            end
        else
            -- Oil is above critical — exit fault state if active
            if isFaulty then
                ExitFaultState(vehicle)
            end
        end

        ::continue::
    end
end)

-- ============================================================
-- OIL BOTTLE USAGE (from inventory)
-- ============================================================

RegisterNetEvent('my_inventory:onItemUsed')
AddEventHandler('my_inventory:onItemUsed', function(itemName)
    if itemName == 'oil_bottle' then
        UseOilBottle()
    end
end)

function UseOilBottle()
    if isRefilling then return end

    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        ShowNotification("~r~You must be outside the vehicle!")
        return
    end

    local pCoords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(pCoords.x, pCoords.y, pCoords.z, Config.UseDistance, 0, 71)

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        ShowNotification("~r~No vehicle found within " .. Config.UseDistance .. " meters")
        return
    end

    local vehCoords = GetEntityCoords(vehicle)
    if #(pCoords - vehCoords) > Config.UseDistance then
        ShowNotification("~r~No vehicle found within " .. Config.UseDistance .. " meters")
        return
    end

    local plate = Plate(GetVehicleNumberPlateText(vehicle))
    if not IsOwnedVehicle(plate) then
        ShowNotification("~r~You don't own this vehicle")
        return
    end

    local currentOil = GetOilLevel(plate)
    if currentOil >= Config.MaxOil then
        ShowNotification("~g~Oil level is already full!")
        return
    end

    isRefilling = true
    FreezeEntityPosition(ped, true)

    if LoadAnimDict('mini@repair') then
        TaskPlayAnim(ped, 'mini@repair', 'fixing_a_ped', 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    ShowNotification("~o~Adding motor oil...")
    Wait(Config.RefillAnimDuration)

    -- Apply oil
    local newOil = SetOilLevel(plate, currentOil + Config.OilBottleRefillAmount)

    -- Exit fault state if oil is back above critical
    if isFaulty and newOil > Config.CriticalOilThreshold then
        ExitFaultState(vehicle)
    end

    -- Sync to server
    TriggerServerEvent('my_vehicles:updateOilLevel', plate, newOil)

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)

    ShowNotification("~g~Oil added! Level: " .. math.floor(newOil) .. "%")
    isRefilling = false
end

-- ============================================================
-- COMMAND: /setoil <level>
-- ============================================================

RegisterCommand('setoil', function(source, args, rawCommand)
    local level = tonumber(args[1])
    if not level then
        ShowNotification("~r~Usage: /setoil <level 0-100>")
        return
    end

    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        ShowNotification("~r~You must be in a vehicle!")
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle or vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        ShowNotification("~r~You must be the driver!")
        return
    end

    local plate = Plate(GetVehicleNumberPlateText(vehicle))
    if not IsOwnedVehicle(plate) then
        ShowNotification("~r~You don't own this vehicle!")
        return
    end

    TriggerServerEvent('my_oillevel:requestSetOil', plate, level)
end, false)

-- ============================================================
-- SERVER OIL LEVEL UPDATE (from /setoil command)
-- ============================================================

RegisterNetEvent('my_oillevel:oilLevelUpdated')
AddEventHandler('my_oillevel:oilLevelUpdated', function(plate, level)
    -- Update client-side cache so HUD and drain loop see the new value
    SetOilLevel(Plate(plate), level)

    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle or vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then return end

    local vehPlate = Plate(GetVehicleNumberPlateText(vehicle))
    if vehPlate ~= Plate(plate) then return end

    if level > Config.CriticalOilThreshold and isFaulty then
        ExitFaultState(vehicle)
    elseif level <= Config.CriticalOilThreshold and not isFaulty then
        EnterFaultState(vehicle)
    end
end)

-- ============================================================
-- CLEANUP ON RESOURCE STOP
-- ============================================================

AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() ~= res then return end

    -- Restore engine power on current vehicle
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh and DoesEntityExist(veh) then
        SetVehicleMaxSpeed(veh, 0.0)
        SetVehicleEnginePowerMultiplier(veh, 1.0)
        SetVehicleEngineTorqueMultiplier(veh, 1.0)
    end

    -- Stop smoke (restore engine health)
    StopSmoke(veh)

    -- Final oil sync
    if veh and veh ~= 0 then
        local plate = Plate(GetVehicleNumberPlateText(veh))
        if plate and plate ~= "" then
            local oil = GetOilLevel(plate)
            TriggerServerEvent('my_vehicles:updateOilLevel', plate, oil)
        end
    end

    isFaulty = false
    isStalling = false
end)
