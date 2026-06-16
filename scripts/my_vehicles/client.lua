-- my_vehicles/client.lua
-- Persistent vehicle management — ultra-simple streaming.
-- Spawn at <200m, despawn at >200m, save on player exit only.
-- Zero entity checks while vehicle is in range.

local allVehicles = {}  -- plate -> data (mirror of server)
local spawned     = {}  -- plate -> entity handle
local spawning    = {}  -- plate -> true (lock)
local blips       = {}  -- plate -> blip handle
local myLicense   = nil
local dataReady   = false

-- ============================================================
-- CONFIG
-- ============================================================
local RANGE   = 200.0
local TICK_MS = 2000

local BLIP_SPRITE = 326
local BLIP_COLOR  = 3
local BLIP_SCALE  = 0.7
local BLIP_NAME   = "My Vehicle"

-- Mileage tracking (kilometers)
local currentPlate    = nil   -- plate of vehicle currently being driven
local lastMileagePos  = nil   -- last position for distance calc
local pendingMileage  = 0.0   -- km accumulated since last server sync
local METERS_PER_KM   = 1000.0
local MILEAGE_SYNC_MS = 10000 -- send mileage to server every 10 seconds

-- Oil level tracking (per-vehicle, mirrors server data)
local vehicleOilLevels = {}   -- plate -> current oil level (0-100)

-- ============================================================
-- HELPERS
-- ============================================================

local function Plate(p)
    if not p then return "" end
    return string.upper(string.gsub(tostring(p), '%s+', ''))
end

local function IsOwned(plate)
    if not myLicense or not plate then return false end
    local d = allVehicles[plate]
    return d and d.owner == myLicense
end

local function FindInPool(plate)
    for _, v in pairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(v) and Plate(GetVehicleNumberPlateText(v)) == plate then
            return v
        end
    end
    return nil
end

-- Client-side export so other resources (e.g. my_housing) can check plates
exports('DoesPlateExist', function(plate)
    if not plate then return false end
    return allVehicles[Plate(plate)] ~= nil
end)

-- ============================================================
-- BLIPS
-- ============================================================

local function AddBlip(plate, x, y, z)
    if blips[plate] then return end
    local b = AddBlipForCoord(x, y, z)
    SetBlipSprite(b, BLIP_SPRITE)
    SetBlipColour(b, BLIP_COLOR)
    SetBlipScale(b, BLIP_SCALE)
    SetBlipAsShortRange(b, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(BLIP_NAME)
    EndTextCommandSetBlipName(b)
    blips[plate] = b
end

local function MoveBlip(plate, x, y, z)
    local b = blips[plate]
    if b and DoesBlipExist(b) then SetBlipCoords(b, x, y, z) end
end

local function KillBlip(plate)
    local b = blips[plate]
    if b then
        if DoesBlipExist(b) then RemoveBlip(b) end
        blips[plate] = nil
    end
end

-- Release a vehicle from tracking WITHOUT deleting the entity.
-- Used by my_usedcars so the NPC buyer can drive the vehicle away.
exports('ReleaseVehicle', function(plate)
    if not plate then return false end
    plate = Plate(plate)
    local ent = spawned[plate]
    if ent and DoesEntityExist(ent) then
        SetEntityAsMissionEntity(ent, false, true)
    end
    spawned[plate] = nil
    spawning[plate] = nil
    allVehicles[plate] = nil
    KillBlip(plate)
    return true
end)

-- ============================================================
-- VEHICLE PROPERTIES (full capture)
-- ============================================================

local function GetVehicleProps(veh)
    if not veh or not DoesEntityExist(veh) then return {} end
    SetVehicleModKit(veh, 0)

    local c1, c2 = GetVehicleColours(veh)
    local pearl, wc = GetVehicleExtraColours(veh)
    local mc1t, mc1c, mc1p = GetVehicleModColor_1(veh)
    local mc2t, mc2c = GetVehicleModColor_2(veh)

    local mods = {}
    for i = 0, 49 do
        local v = GetVehicleMod(veh, i)
        if v >= 0 then mods[tostring(i)] = v end
    end

    local extras = {}
    for i = 1, 20 do
        if DoesExtraExist(veh, i) then
            extras[tostring(i)] = IsVehicleExtraTurnedOn(veh, i)
        end
    end

    local neon = {}
    for i = 0, 3 do neon[tostring(i)] = IsVehicleNeonLightEnabled(veh, i) end
    local nR, nG, nB = GetVehicleNeonLightsColour(veh)
    local tsR, tsG, tsB = GetVehicleTyreSmokeColor(veh)

    return {
        color1 = c1, color2 = c2,
        pearlescentColor = pearl, wheelColor = wc,
        dashboardColor = GetVehicleDashboardColor(veh),
        interiorColor  = GetVehicleInteriorColor(veh),
        modColor1 = { mc1t, mc1c, mc1p },
        modColor2 = { mc2t, mc2c },
        customPrimaryColor   = GetIsVehiclePrimaryColourCustom(veh)   and {GetVehicleCustomPrimaryColour(veh)}   or nil,
        customSecondaryColor = GetIsVehicleSecondaryColourCustom(veh) and {GetVehicleCustomSecondaryColour(veh)} or nil,
        bodyHealth   = GetVehicleBodyHealth(veh),
        engineHealth = GetVehicleEngineHealth(veh),
        fuelLevel    = GetVehicleFuelLevel(veh),
        dirtLevel    = GetVehicleDirtLevel(veh),
        tankHealth   = GetVehiclePetrolTankHealth(veh),
        mods = mods,
        wheelType = GetVehicleWheelType(veh),
        turbo             = IsToggleModOn(veh, 18),
        tyreSmokeEnabled  = IsToggleModOn(veh, 20),
        xenonEnabled      = IsToggleModOn(veh, 22),
        tyreSmokeR = tsR, tyreSmokeG = tsG, tyreSmokeB = tsB,
        xenonColor = GetVehicleXenonLightsColor(veh),
        neonEnabled = neon,
        neonR = nR, neonG = nG, neonB = nB,
        windowTint = GetVehicleWindowTint(veh),
        plateIndex = GetVehicleNumberPlateTextIndex(veh),
        livery     = GetVehicleLivery(veh),
        liveryMod  = GetVehicleMod(veh, 48),
        roofLivery = GetVehicleRoofLivery(veh),
        extras = extras,
    }
end

-- ============================================================
-- APPLY VEHICLE PROPERTIES
-- ============================================================

local function ApplyProps(veh, p)
    if not veh or not DoesEntityExist(veh) or not p then return end
    local ok, err = pcall(function()
        SetVehicleModKit(veh, 0)

        if p.color1 and p.color2 then SetVehicleColours(veh, p.color1, p.color2) end
        if p.pearlescentColor and p.wheelColor then SetVehicleExtraColours(veh, p.pearlescentColor, p.wheelColor) end
        if p.dashboardColor then SetVehicleDashboardColor(veh, p.dashboardColor) end
        if p.interiorColor  then SetVehicleInteriorColor(veh, p.interiorColor) end

        if p.modColor1 and type(p.modColor1) == 'table' then
            if #p.modColor1 >= 3 and p.modColor1[2] >= 0 then
                SetVehicleModColor_1(veh, p.modColor1[1], p.modColor1[2], p.modColor1[3])
            elseif #p.modColor1 >= 2 and p.modColor1[2] >= 0 then
                SetVehicleModColor_1(veh, p.modColor1[1], p.modColor1[2], 0)
            end
        end
        if p.modColor2 and type(p.modColor2) == 'table' and #p.modColor2 >= 2 and p.modColor2[2] >= 0 then
            SetVehicleModColor_2(veh, p.modColor2[1], p.modColor2[2])
        end

        if p.customPrimaryColor   and type(p.customPrimaryColor)   == 'table' and #p.customPrimaryColor   >= 3 then SetVehicleCustomPrimaryColour(veh,   p.customPrimaryColor[1],   p.customPrimaryColor[2],   p.customPrimaryColor[3])   end
        if p.customSecondaryColor and type(p.customSecondaryColor) == 'table' and #p.customSecondaryColor >= 3 then SetVehicleCustomSecondaryColour(veh, p.customSecondaryColor[1], p.customSecondaryColor[2], p.customSecondaryColor[3]) end

        local wt = p.wheelType or p.wheels
        if wt then SetVehicleWheelType(veh, wt) end

        if p.mods then
            for k, v in pairs(p.mods) do
                local i = tonumber(k)
                if i then SetVehicleMod(veh, i, v, false) end
            end
        end

        local named = {
            modEngine=11, modBrakes=12, modTransmission=13, modHorns=14,
            modSuspension=15, modArmor=16, modFrontBumper=1, modRearBumper=2,
            modSideSkirt=3, modExhaust=4, modFrame=5, modGrille=6, modHood=7,
            modFender=8, modRightFender=9, modRoof=10, modSpoilers=0,
            modFrontWheels=23, modBackWheels=24, modPlateHolder=25,
            modVanityPlate=26, modTrimA=27, modOrnaments=28, modDashboard=29,
            modDial=30, modDoorSpeaker=31, modSeats=32, modSteeringWheel=33,
            modShifterLeavers=34, modAPlate=35, modSpeakers=36, modTrunk=37,
            modHydrolic=38, modEngineBlock=39, modAirFilter=40, modStruts=41,
            modArchCover=42, modAerials=43, modTrimB=44, modTank=45,
            modWindows=46, modLivery=48,
        }
        for key, idx in pairs(named) do
            if p[key] and p[key] >= 0 then SetVehicleMod(veh, idx, p[key], false) end
        end

        local turbo = p.turbo; if turbo == nil then turbo = p.modTurbo end
        if turbo ~= nil then ToggleVehicleMod(veh, 18, turbo and true or false) end
        if p.tyreSmokeEnabled ~= nil then ToggleVehicleMod(veh, 20, p.tyreSmokeEnabled) end
        if p.tyreSmokeR and p.tyreSmokeG and p.tyreSmokeB then SetVehicleTyreSmokeColor(veh, p.tyreSmokeR, p.tyreSmokeG, p.tyreSmokeB) end

        local xenon = p.xenonEnabled; if xenon == nil then xenon = p.modXenon end
        if xenon ~= nil then ToggleVehicleMod(veh, 22, xenon and true or false) end
        if p.xenonColor then SetVehicleXenonLightsColor(veh, p.xenonColor) end

        if p.neonEnabled and type(p.neonEnabled) == 'table' then
            for i = 0, 3 do
                local val = p.neonEnabled[tostring(i)] or p.neonEnabled[i + 1]
                if val ~= nil then SetVehicleNeonLightEnabled(veh, i, val and true or false) end
            end
        end
        local nr, ng, nb = p.neonR, p.neonG, p.neonB
        if not nr and p.neonColor and type(p.neonColor) == 'table' and #p.neonColor >= 3 then
            nr, ng, nb = p.neonColor[1], p.neonColor[2], p.neonColor[3]
        end
        if nr and ng and nb then SetVehicleNeonLightsColour(veh, nr, ng, nb) end

        if p.windowTint then SetVehicleWindowTint(veh, p.windowTint) end
        if p.plateIndex  then SetVehicleNumberPlateTextIndex(veh, p.plateIndex) end

        if p.livery     and p.livery     >= 0 then SetVehicleLivery(veh, p.livery) end
        if p.liveryMod  and p.liveryMod  >= 0 then SetVehicleMod(veh, 48, p.liveryMod, false) end
        if p.roofLivery and p.roofLivery >= 0 then SetVehicleRoofLivery(veh, p.roofLivery) end

        if p.extras and type(p.extras) == 'table' then
            for id, on in pairs(p.extras) do
                local n = tonumber(id)
                if n and DoesExtraExist(veh, n) then
                    if type(on) == 'number' then
                        if DoesExtraExist(veh, on) then SetVehicleExtra(veh, on, false) end
                    else
                        SetVehicleExtra(veh, n, not on)
                    end
                end
            end
        end

        if p.bodyHealth   then SetVehicleBodyHealth(veh, p.bodyHealth + 0.0) end
        if p.engineHealth then SetVehicleEngineHealth(veh, p.engineHealth + 0.0) end
        if p.fuelLevel    then SetVehicleFuelLevel(veh, p.fuelLevel + 0.0) end
        if p.dirtLevel    then SetVehicleDirtLevel(veh, p.dirtLevel + 0.0) end
        if p.tankHealth   then SetVehiclePetrolTankHealth(veh, p.tankHealth + 0.0) end
    end)
    if not ok then print('^1[my_vehicles] ApplyProps error: ' .. tostring(err) .. '^7') end
end

-- ============================================================
-- SAVE (only called on player exit vehicle & resource stop)
-- ============================================================

local function SaveVehicleState(plate, entity)
    if not entity or not DoesEntityExist(entity) then return end
    if not allVehicles[plate] then return end

    local pos = GetEntityCoords(entity)
    local hdg = GetEntityHeading(entity)
    local props = GetVehicleProps(entity)

    allVehicles[plate].x = pos.x
    allVehicles[plate].y = pos.y
    allVehicles[plate].z = pos.z
    allVehicles[plate].heading = hdg
    allVehicles[plate].properties = props

    TriggerServerEvent('my_vehicles:saveVehicleState', plate, pos.x, pos.y, pos.z, hdg, props, pendingMileage)
    pendingMileage = 0.0
end

-- ============================================================
-- SPAWN / DESPAWN
-- ============================================================

-- Pre-load a model synchronously, returns true if loaded
local function EnsureModel(hash)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) do Wait(100); t = t + 1; if t > 50 then return false end end
    return true
end

-- Create the vehicle entity instantly (model must already be loaded)
local function CreateVeh(plate, data, parked)
    local hash = GetHashKey(data.model)
    if not HasModelLoaded(hash) then return nil end

    local veh = CreateVehicle(hash, data.x, data.y, data.z, data.heading, false, false)
    if not veh or veh == 0 then return nil end

    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleNumberPlateText(veh, plate)
    SetVehicleOnGroundProperly(veh)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    ApplyProps(veh, data.properties)

    if parked then
        SetVehicleHandbrake(veh, true)
        SetVehicleEngineOn(veh, false, true, false)
    end

    return veh
end

local function SpawnVehicle(plate, data, parked)
    if spawning[plate] then return end
    if spawned[plate] then return end

    -- Already in game pool? (used cars / flipper compatibility)
    local existing = FindInPool(plate)
    if existing then
        spawned[plate] = existing
        SetEntityAsMissionEntity(existing, true, true)
        if IsOwned(plate) then AddBlip(plate, data.x, data.y, data.z) end
        return
    end

    spawning[plate] = true
    local hash = GetHashKey(data.model)
    if not EnsureModel(hash) then spawning[plate] = nil; return end

    -- Re-check pool after async load
    existing = FindInPool(plate)
    if existing then
        spawned[plate] = existing
        SetEntityAsMissionEntity(existing, true, true)
        SetModelAsNoLongerNeeded(hash)
        spawning[plate] = nil
        if IsOwned(plate) then AddBlip(plate, data.x, data.y, data.z) end
        return
    end

    local veh = CreateVeh(plate, data, parked)
    SetModelAsNoLongerNeeded(hash)
    if not veh then spawning[plate] = nil; return end

    spawned[plate] = veh
    spawning[plate] = nil
    if IsOwned(plate) then AddBlip(plate, data.x, data.y, data.z) end
end

local function DeleteEnt(ent)
    if not ent or not DoesEntityExist(ent) then return end
    SetEntityAsMissionEntity(ent, true, true)
    DeleteEntity(ent)
end

local function DespawnVehicle(plate)
    DeleteEnt(spawned[plate])
    spawned[plate] = nil
end

-- ============================================================
-- SERVER EVENTS
-- ============================================================

RegisterNetEvent('my_vehicles:loadAllVehicles')
AddEventHandler('my_vehicles:loadAllVehicles', function(vehicles, license)
    allVehicles = vehicles or {}
    if license then myLicense = license end
    dataReady = true
    for plate, d in pairs(allVehicles) do
        if d.owner == myLicense then AddBlip(plate, d.x, d.y, d.z) end
        -- Initialize local oil level cache from server data
        if d.oilLevel ~= nil then
            vehicleOilLevels[plate] = d.oilLevel
        end
    end
end)

RegisterNetEvent('my_vehicles:vehicleAdded')
AddEventHandler('my_vehicles:vehicleAdded', function(plate, data)
    if not plate or not data then return end
    allVehicles[plate] = data

    -- Check pool first (used cars / flipper — vehicle already exists in world)
    local existing = FindInPool(plate)
    if existing then
        spawned[plate] = existing
        SetVehicleHandbrake(existing, false)
        SetEntityAsMissionEntity(existing, true, true)
        if IsOwned(plate) then AddBlip(plate, data.x, data.y, data.z) end
        return
    end

    if IsOwned(plate) then
        local pos = GetEntityCoords(PlayerPedId())
        if #(pos - vector3(data.x, data.y, data.z)) < RANGE then
            SpawnVehicle(plate, data, false)
        end
        AddBlip(plate, data.x, data.y, data.z)
    end
end)

RegisterNetEvent('my_vehicles:vehicleRemoved')
AddEventHandler('my_vehicles:vehicleRemoved', function(plate)
    if not plate then return end
    allVehicles[plate] = nil
    KillBlip(plate)
    DeleteEnt(spawned[plate])
    spawned[plate] = nil
    spawning[plate] = nil
end)

RegisterNetEvent('my_vehicles:propertiesUpdated')
AddEventHandler('my_vehicles:propertiesUpdated', function(plate, properties)
    if not plate or not properties then return end
    plate = Plate(plate)
    if allVehicles[plate] then allVehicles[plate].properties = properties end
end)

-- ============================================================
-- ENTER / EXIT DETECTION  (save on exit only)
-- ============================================================

CreateThread(function()
    local wasIn = false
    while true do
        local ped = PlayerPedId()
        local inVeh = IsPedInAnyVehicle(ped, false)

        -- Entered a vehicle
        if inVeh and not wasIn then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh and DoesEntityExist(veh) then
                local pl = Plate(GetVehicleNumberPlateText(veh))
                if spawned[pl] then
                    if spawned[pl] ~= veh then
                        DeleteEnt(spawned[pl])
                        spawned[pl] = veh
                    end
                    SetVehicleHandbrake(veh, false)
                    KillBlip(pl)
                end
                -- Start mileage tracking for this vehicle
                if allVehicles[pl] then
                    currentPlate = pl
                    lastMileagePos = GetEntityCoords(veh)
                    pendingMileage = 0.0
                end
            end
        end

        -- Exited a vehicle — SAVE
        if not inVeh and wasIn then
            local veh = GetVehiclePedIsIn(ped, true)
            if veh and DoesEntityExist(veh) then
                local pl = Plate(GetVehicleNumberPlateText(veh))
                if allVehicles[pl] then
                    -- Final mileage accumulation before save
                    if currentPlate == pl and lastMileagePos then
                        local curPos = GetEntityCoords(veh)
                        local dist = #(curPos - lastMileagePos)
                        pendingMileage = pendingMileage + (dist / METERS_PER_KM)
                    end
                    SaveVehicleState(pl, veh)
                    if IsOwned(pl) then
                        local pos = GetEntityCoords(veh)
                        AddBlip(pl, pos.x, pos.y, pos.z)
                    end
                end
            end
            currentPlate = nil
            lastMileagePos = nil
        end

        wasIn = inVeh
        Wait(inVeh and 500 or 200)
    end
end)

-- ============================================================
-- MILEAGE TRACKING THREAD
-- Accumulates distance while driving an owned vehicle and
-- syncs to server periodically.
-- ============================================================

CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) and currentPlate and lastMileagePos then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh and DoesEntityExist(veh) and GetPedInVehicleSeat(veh, -1) == ped then
                local curPos = GetEntityCoords(veh)
                local dist = #(curPos - lastMileagePos)
                if dist > 1.0 then -- ignore tiny movements / jitter
                    pendingMileage = pendingMileage + (dist / METERS_PER_KM)
                    lastMileagePos = curPos
                end
            end
        end
    end
end)

-- Periodic server sync of mileage (every 10 seconds while driving)
CreateThread(function()
    while true do
        Wait(MILEAGE_SYNC_MS)
        if currentPlate and pendingMileage > 0.001 then
            TriggerServerEvent('my_vehicles:updateMileage', currentPlate, pendingMileage)
            -- Update local mirror so HUD shows current total
            if allVehicles[currentPlate] then
                allVehicles[currentPlate].mileage = (allVehicles[currentPlate].mileage or 0) + pendingMileage
            end
            pendingMileage = 0.0
        end
    end
end)

-- Export to get mileage for a plate (for other resources / HUD)
exports('GetVehicleMileage', function(plate)
    if not plate then return 0.0 end
    plate = Plate(plate)
    local d = allVehicles[plate]
    if not d then return 0.0 end
    -- Include pending unsaved miles if currently driving this vehicle
    local total = d.mileage or 0
    if currentPlate == plate then
        total = total + pendingMileage
    end
    return total
end)

-- Export to get oil level for a plate (for other resources / HUD)
exports('GetVehicleOilLevel', function(plate)
    if not plate then return 100.0 end
    plate = Plate(plate)
    if vehicleOilLevels[plate] ~= nil then
        return vehicleOilLevels[plate]
    end
    local d = allVehicles[plate]
    if d and d.oilLevel ~= nil then
        return d.oilLevel
    end
    return 100.0
end)

-- Export to set oil level for a plate (for other resources like my_oillevel)
exports('SetVehicleOilLevel', function(plate, level)
    if not plate then return false end
    plate = Plate(plate)
    level = math.max(0.0, math.min(100.0, tonumber(level) or 100.0))
    vehicleOilLevels[plate] = level
    if allVehicles[plate] then
        allVehicles[plate].oilLevel = level
    end
    return true
end)

-- ============================================================
-- STREAMING THREAD
-- Spawn if < 200m, despawn if > 200m.
-- If entity was deleted externally, clear stale handle so next
-- tick re-spawns it via SpawnVehicle (model re-loaded properly).
-- ============================================================

CreateThread(function()
    Wait(5000)
    TriggerServerEvent('my_vehicles:requestAllVehicles')
    Wait(3000)

    while true do
        Wait(TICK_MS)
        if not dataReady then goto continue end

        local pPos = GetEntityCoords(PlayerPedId())
        local pVeh = GetVehiclePedIsIn(PlayerPedId(), false)

        for plate, data in pairs(allVehicles) do
            local ent = spawned[plate]

            if ent then
                if not DoesEntityExist(ent) then
                    -- Entity was deleted externally — clear stale handle
                    spawned[plate] = nil
                else
                    -- Use the entity's ACTUAL position for despawn checks,
                    -- not the stored data position which can be stale
                    -- (e.g. vehicle driven far from its registered location
                    -- before position is saved on exit).
                    local entPos = GetEntityCoords(ent)
                    local dist = #(pPos - entPos)
                    if dist > RANGE and pVeh ~= ent then
                        -- Far away — despawn
                        DespawnVehicle(plate)
                    end
                end
            else
                -- Not spawned — use stored position to decide spawn
                local dist = #(pPos - vector3(data.x, data.y, data.z))
                if dist < RANGE and not spawning[plate] then
                    SpawnVehicle(plate, data, true)
                end
            end
        end

        ::continue::
    end
end)

-- ============================================================
-- CLEANUP ON RESOURCE STOP
-- ============================================================

AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() ~= res then return end

    for plate, ent in pairs(spawned) do
        if ent and DoesEntityExist(ent) then
            SaveVehicleState(plate, ent)
        end
        DeleteEnt(ent)
    end

    for _, b in pairs(blips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    blips = {}
    spawned = {}
    allVehicles = {}
end)
