-- ============================================================
-- INLINE CONFIG (in case config.lua doesn't load)
-- ============================================================
if not Config then
    Config = {}
    Config.AttachKey = 311
    Config.FlatbedDetectDistance = 10.0
    Config.VehicleDetectDistance = 12.0
    Config.FlatbedModels = { "flatbed", "rollback", "trflat" }
    Config.AttachOffset = { x = 0.0, y = -1.95 }
    Config.FlatbedBedHeight = 1.23
    Config.AttachRotation = { x = 0.0, y = 0.0, z = 0.0 }
    Config.Draw3DText = true
    Config.Messages = {
        attached = "~g~Vehicle attached to flatbed!",
        detached = "~y~Vehicle detached from flatbed.",
        noVehicle = "~r~No vehicle nearby to load.",
        tooFar = "~r~You are too far from a flatbed.",
        inVehicle = "~r~Exit your vehicle first!",
        alreadyLoaded = "~y~This flatbed already has a vehicle loaded.",
    }
end

local attachedVehicles = {} -- flatbed entity handle -> attached vehicle entity handle
local nearFlatbed = nil       -- entity handle of nearby flatbed

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

--- Check if a vehicle model is a flatbed
local function IsFlatbedModel(vehicle)
    local model = GetEntityModel(vehicle)
    for _, name in ipairs(Config.FlatbedModels) do
        if model == GetHashKey(name) then
            return true
        end
    end
    return false
end

--- Get the nearest flatbed to the player within range
local function GetNearestFlatbed(playerCoords)
    local closestDist = Config.FlatbedDetectDistance
    local closestFlatbed = nil

    -- Search all nearby vehicles
    local handle, vehicle = FindFirstVehicle()
    local success = true

    repeat
        if DoesEntityExist(vehicle) and IsFlatbedModel(vehicle) then
            local vehCoords = GetEntityCoords(vehicle)
            local dist = #(playerCoords - vehCoords)
            if dist < closestDist then
                closestDist = dist
                closestFlatbed = vehicle
            end
        end
        success, vehicle = FindNextVehicle(handle)
    until not success

    EndFindVehicle(handle)
    return closestFlatbed, closestDist
end

--- Get the nearest non-flatbed vehicle to load (excludes the flatbed itself and already-attached vehicles)
local function GetNearestLoadableVehicle(playerCoords, flatbed)
    local closestDist = Config.VehicleDetectDistance
    local closestVehicle = nil

    local handle, vehicle = FindFirstVehicle()
    local success = true

    repeat
        if DoesEntityExist(vehicle) and vehicle ~= flatbed and not IsFlatbedModel(vehicle) then
            -- Skip vehicles that are already attached to something
            if not IsEntityAttachedToEntity(vehicle, flatbed) then
                local vehCoords = GetEntityCoords(vehicle)
                local dist = #(playerCoords - vehCoords)
                if dist < closestDist then
                    closestDist = dist
                    closestVehicle = vehicle
                end
            end
        end
        success, vehicle = FindNextVehicle(handle)
    until not success

    EndFindVehicle(handle)
    return closestVehicle
end

--- Get the vehicle currently attached to a flatbed
local function GetAttachedVehicle(flatbed)
    local attachedVeh = attachedVehicles[flatbed]
    if attachedVeh then
        if DoesEntityExist(attachedVeh) and IsEntityAttachedToEntity(attachedVeh, flatbed) then
            return attachedVeh
        else
            -- Clean up stale reference
            attachedVehicles[flatbed] = nil
            return nil
        end
    end
    return nil
end

--- Attach a vehicle to the flatbed
local function AttachVehicleToFlatbed(vehicle, flatbed)
    -- Request network control
    local timeout = 0
    NetworkRequestControlOfEntity(vehicle)
    while not NetworkHasControlOfEntity(vehicle) and timeout < 100 do
        Citizen.Wait(10)
        NetworkRequestControlOfEntity(vehicle)
        timeout = timeout + 1
    end

    if not NetworkHasControlOfEntity(vehicle) then
        ShowNotification("~r~Could not get control of the vehicle.")
        return false
    end

    -- Remove any occupants from the vehicle being loaded
    for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        local ped = GetPedInVehicleSeat(vehicle, i)
        if ped ~= 0 then
            TaskLeaveVehicle(ped, vehicle, 16)
        end
    end
    Citizen.Wait(500)

    -- Set up the vehicle
    SetVehicleHandbrake(vehicle, true)
    SetVehicleEngineOn(vehicle, false, true, true)

    local bone = GetEntityBoneIndexByName(flatbed, "chassis")

    -- Step 1: Attach just above the bed (collision off so it doesn't bounce)
    AttachEntityToEntity(
        vehicle, flatbed, bone,
        Config.AttachOffset.x, Config.AttachOffset.y, 1.5,
        Config.AttachRotation.x, Config.AttachRotation.y, Config.AttachRotation.z,
        true, false, false, false, 2, true
    )
    Citizen.Wait(50)

    -- Step 2: Make vehicle invincible, detach and let gravity settle it
    SetEntityInvincible(vehicle, true)
    DetachEntity(vehicle, false, false)
    FreezeEntityPosition(vehicle, false)
    SetEntityCollision(vehicle, true, true)

    -- Wait for the vehicle to settle on the bed surface
    Citizen.Wait(2000)

    -- Step 3: Restore damage and read the settled position, then re-attach
    SetEntityInvincible(vehicle, false)
    local settledCoords = GetEntityCoords(vehicle)
    local relOffset = GetOffsetFromEntityGivenWorldCoords(flatbed, settledCoords.x, settledCoords.y, settledCoords.z)

    AttachEntityToEntity(
        vehicle, flatbed, bone,
        relOffset.x, relOffset.y, relOffset.z,
        Config.AttachRotation.x, Config.AttachRotation.y, Config.AttachRotation.z,
        true, false, true, false, 2, true
    )

    -- Track the attachment
    attachedVehicles[flatbed] = vehicle

    return true
end

--- Detach the vehicle from the flatbed
local function DetachVehicleFromFlatbed(vehicle, flatbed)
    local timeout = 0
    NetworkRequestControlOfEntity(vehicle)
    while not NetworkHasControlOfEntity(vehicle) and timeout < 100 do
        Citizen.Wait(10)
        NetworkRequestControlOfEntity(vehicle)
        timeout = timeout + 1
    end

    DetachEntity(vehicle, true, true)

    -- Restore vehicle to normal state
    FreezeEntityPosition(vehicle, false)
    SetEntityCollision(vehicle, true, true)
    SetEntityInvincible(vehicle, false)
    SetVehicleEngineOn(vehicle, false, false, true) -- Allow engine to be started normally

    -- Place the vehicle on the ground properly
    local flatbedHeading = GetEntityHeading(flatbed)

    -- Calculate position behind the flatbed for drop-off
    local behindOffset = GetOffsetFromEntityInWorldCoords(flatbed, 0.0, -8.0, 0.0)
    SetEntityCoords(vehicle, behindOffset.x, behindOffset.y, behindOffset.z - 0.5, false, false, false, false)
    SetEntityHeading(vehicle, flatbedHeading)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleHandbrake(vehicle, true)

    -- Remove tracking
    attachedVehicles[flatbed] = nil

    return true
end

--- Show a GTA notification
function ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

--- Draw 3D text in the world
local function Draw3DText(coords, text)
    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 2.0)
    if onScreen then
        SetTextScale(0.4, 0.4)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 255)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(screenX, screenY)
    end
end

-- ============================================================
-- MAIN LOOP
-- ============================================================

Citizen.CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        -- Don't run while in vehicle
        if not IsPedInAnyVehicle(playerPed, false) then
            local flatbed, dist = GetNearestFlatbed(playerCoords)

            if flatbed and dist < Config.FlatbedDetectDistance then
                sleep = 0
                nearFlatbed = flatbed
                local attachedVeh = GetAttachedVehicle(flatbed)

                -- Key press detection
                if IsControlJustPressed(0, Config.AttachKey) then
                    if attachedVeh then
                        -- Detach
                        if DetachVehicleFromFlatbed(attachedVeh, flatbed) then
                            ShowNotification(Config.Messages.detached)
                        end
                    else
                        -- Find and attach
                        local vehicle = GetNearestLoadableVehicle(playerCoords, flatbed)
                        if vehicle then
                            if AttachVehicleToFlatbed(vehicle, flatbed) then
                                ShowNotification(Config.Messages.attached)
                            end
                        else
                            ShowNotification(Config.Messages.noVehicle)
                        end
                    end
                end
            else
                nearFlatbed = nil
            end
        end

        Citizen.Wait(sleep)
    end
end)
