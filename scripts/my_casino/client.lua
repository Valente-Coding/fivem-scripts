-- Diamond Casino Entry Script

local insideCasino = false
local iplsLoaded = false
local spawnedNPCs = {}
local wanderThreads = {}
local casinoInteriorId = nil
local relationshipGroup = nil

-- ============================================================
-- Helper Functions
-- ============================================================

local function ShowHelpNotification(msg)
    AddTextEntry('CasinoHelp', msg)
    DisplayHelpTextThisFrame('CasinoHelp', false)
end

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function DrawMarkerAt(coords)
    if not Config.ShowMarker then return end
    DrawMarker(
        Config.MarkerType,
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z,
        Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, Config.MarkerColor.a,
        false, false, 2, false, nil, nil, false
    )
end

local function LoadIPLs()
    if iplsLoaded then return end
    for _, ipl in ipairs(Config.IPLs) do
        if not IsIplActive(ipl) then
            RequestIpl(ipl)
        end
    end
    iplsLoaded = true
end

-- Activate the casino's built-in interior entity sets (decor, props, lights)
local function SetupCasinoInterior()
    -- Get the interior ID at the casino main floor
    casinoInteriorId = GetInteriorAtCoords(1100.0, 220.0, -50.0)
    if casinoInteriorId == 0 then return end

    -- Activate Rockstar's built-in entity sets for the interior
    if Config.InteriorEntitySets then
        for _, entitySet in ipairs(Config.InteriorEntitySets) do
            if IsInteriorEntitySetActive(casinoInteriorId, entitySet) == false then
                ActivateInteriorEntitySet(casinoInteriorId, entitySet)
            end
        end
    end

    RefreshInterior(casinoInteriorId)
end

-- Set up a relationship group so casino NPCs are friendly/neutral
local function SetupRelationships()
    local _, hash = AddRelationshipGroup("CASINO_AMBIENT")
    SetRelationshipBetweenGroups(1, hash, GetHashKey("PLAYER"))   -- respect
    SetRelationshipBetweenGroups(1, GetHashKey("PLAYER"), hash)   -- respect back
    SetRelationshipBetweenGroups(1, hash, hash)                   -- respect each other
    relationshipGroup = hash
end

local function DoScreenFade(fadeOut, fadeIn, callback)
    DoScreenFadeOut(Config.FadeDuration)
    Wait(Config.FadeDuration)

    if callback then callback() end

    Wait(500)
    DoScreenFadeIn(Config.FadeDuration)
end

local function TeleportPlayer(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w)
    Wait(100)
end

-- ============================================================
-- Casino Blip
-- ============================================================

local function CreateCasinoBlip()
    if not Config.ShowBlip then return end

    local blip = AddBlipForCoord(Config.EntranceDoor.x, Config.EntranceDoor.y, Config.EntranceDoor.z)
    SetBlipSprite(blip, Config.BlipSprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.BlipScale)
    SetBlipColour(blip, Config.BlipColor)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.BlipName)
    EndTextCommandSetBlipName(blip)
end

-- ============================================================
-- Casino NPCs
-- ============================================================

local function LoadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 5000
    while not HasModelLoaded(hash) and timeout > 0 do
        Wait(100)
        timeout = timeout - 100
    end
    return hash
end

-- Check if a position falls inside any exclusion zone
local function IsInExclusionZone(pos)
    if not Config.ExclusionZones then return false end
    for _, zone in ipairs(Config.ExclusionZones) do
        if #(vector3(pos.x, pos.y, pos.z) - zone.coords) < zone.radius then
            return true
        end
    end
    return false
end

-- Give a wandering ped a task to walk to a random waypoint, pause, then walk again
local function StartWanderLoop(ped)
    local threadId = CreateThread(function()
        while DoesEntityExist(ped) and not IsEntityDead(ped) do
            -- Pick a random destination that isn't in an exclusion zone
            local dest = nil
            local attempts = 0
            repeat
                dest = Config.WanderPoints[math.random(#Config.WanderPoints)]
                attempts = attempts + 1
            until not IsInExclusionZone(dest) or attempts > 20

            -- Walk to the destination at a casual pace (1.0 = walk speed)
            TaskGoStraightToCoord(ped, dest.x, dest.y, dest.z, 1.0, -1, 0.0, 0.0)
            
            -- Wait until they arrive or time out
            local timeout = 30000
            while timeout > 0 do
                Wait(1000)
                timeout = timeout - 1000
                local pedCoords = GetEntityCoords(ped)
                if #(pedCoords - dest) < 1.5 then break end
                if not DoesEntityExist(ped) then return end
            end

            -- Pause at the destination with a random idle scenario
            local idleScenarios = {
                "WORLD_HUMAN_STAND_IMPATIENT",
                "WORLD_HUMAN_STAND_MOBILE",
                "WORLD_HUMAN_HANG_OUT_STREET",
                "WORLD_HUMAN_SMOKING",
                "WORLD_HUMAN_DRINKING",
            }
            local scenario = idleScenarios[math.random(#idleScenarios)]
            TaskStartScenarioInPlace(ped, scenario, 0, true)

            -- Stay idle for 8-20 seconds then move again
            Wait(math.random(8000, 20000))
            ClearPedTasks(ped)
            Wait(500)
        end
    end)
    table.insert(wanderThreads, threadId)
end

local function SpawnCasinoNPCs()
    if not Config.SpawnNPCs then return end
    if #spawnedNPCs > 0 then return end -- already spawned

    SetupRelationships()

    for i, npcData in ipairs(Config.CasinoNPCs) do
        -- Skip this spawn point if it's inside an exclusion zone
        if IsInExclusionZone(npcData.coords) then
            goto continue
        end

        -- Pick model based on group
        local models = Config.PatronModels
        if npcData.group == "staff" and Config.StaffModels and #Config.StaffModels > 0 then
            models = Config.StaffModels
        end
        local modelName = models[math.random(#models)]
        local hash = LoadModel(modelName)

        if HasModelLoaded(hash) then
            local c = npcData.coords
            -- Snap spawn Z to actual ground level so NPCs don't float
            local spawnZ = c.z
            local found, groundZ = GetGroundZFor_3dCoord(c.x, c.y, c.z + 2.0, false)
            if found then
                spawnZ = groundZ
            end
            local ped = CreatePed(4, hash, c.x, c.y, spawnZ, c.w, false, true)

            -- Ensure all body parts (arms, etc.) render correctly
            SetPedDefaultComponentVariation(ped)

            -- Basic setup
            SetEntityAsMissionEntity(ped, true, true)
            SetPedFleeAttributes(ped, 0, false)
            SetPedCombatAttributes(ped, 17, true)
            SetPedDropsWeaponsWhenDead(ped, false)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, false)
            SetPedCanRagdollFromPlayerImpact(ped, false)
            SetPedRagdollOnCollision(ped, false)

            -- Relationship group so they stay friendly
            if relationshipGroup then
                SetPedRelationshipGroupHash(ped, relationshipGroup)
            end

            -- Perception setup (staff aware, patrons less so)
            if npcData.group == "staff" then
                SetBlockingOfNonTemporaryEvents(ped, true)
                SetPedSeeingRange(ped, 10.0)
                SetPedHearingRange(ped, 10.0)
            else
                SetBlockingOfNonTemporaryEvents(ped, true)
                SetPedSeeingRange(ped, 5.0)
                SetPedHearingRange(ped, 5.0)
            end
            SetPedAlertness(ped, 0)
            SetPedKeepTask(ped, true)

            -- Assign behavior based on type
            if npcData.type == "wander" then
                -- Wanderer: walks between waypoints
                StartWanderLoop(ped)
            elseif npcData.type == "social" or npcData.type == "static" then
                -- Static/Social: play scenario in place
                if npcData.scenario then
                    TaskStartScenarioInPlace(ped, npcData.scenario, 0, true)
                end
            end

            table.insert(spawnedNPCs, ped)
            SetModelAsNoLongerNeeded(hash)
        end

        -- Stagger spawns so they don't all pop in at once
        Wait(Config.SpawnStaggerMs or 100)
        ::continue::
    end
end

local function DespawnCasinoNPCs()
    -- Kill wander threads by letting them exit naturally (peds won't exist)
    for _, ped in ipairs(spawnedNPCs) do
        if DoesEntityExist(ped) then
            DeletePed(ped)
            DeleteEntity(ped)
        end
    end
    spawnedNPCs = {}
    wanderThreads = {}
end

-- ============================================================
-- Enter / Exit Logic
-- ============================================================

local function EnterCasino()
    LoadIPLs()
    DoScreenFade(true, true, function()
        TeleportPlayer(Config.InsideCasino)
        SetupCasinoInterior()
        insideCasino = true
    end)
    SpawnCasinoNPCs()
    ShowNotification("~g~Welcome to The Diamond Casino & Resort!")
end

local function ExitCasino()
    DoScreenFade(true, true, function()
        TeleportPlayer(Config.OutsideCasino)
        insideCasino = false
    end)
    DespawnCasinoNPCs()
end

-- Check if the player is physically near the casino interior (e.g. after script restart)
local function IsPlayerInsideCasino()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local casinoCenter = vector3(1100.0, 220.0, -50.0)
    return #(playerCoords - casinoCenter) < 80.0
end

-- ============================================================
-- Main Thread
-- ============================================================

CreateThread(function()
    -- Load IPLs on resource start so the interior is ready
    LoadIPLs()

    -- Create map blip
    CreateCasinoBlip()

    -- If player is already inside the casino (e.g. script restart), restore state
    if IsPlayerInsideCasino() then
        insideCasino = true
        SetupCasinoInterior()
        SpawnCasinoNPCs()
        ShowNotification("~g~Casino NPCs restored after script restart.")
    end

    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)

        if not insideCasino then
            -- Check distance to entrance
            local distEntrance = #(playerCoords - Config.EntranceDoor)

            if distEntrance < 10.0 then
                sleep = 0
                DrawMarkerAt(Config.EntranceDoor)

                if distEntrance < Config.InteractDistance then
                    ShowHelpNotification("Press ~INPUT_CONTEXT~ to enter the Diamond Casino")

                    if IsControlJustReleased(0, 38) then -- E key
                        EnterCasino()
                    end
                end
            end
        else
            -- Check distance to exit
            local distExit = #(playerCoords - Config.ExitDoor)

            if distExit < 10.0 then
                sleep = 0
                DrawMarkerAt(Config.ExitDoor)

                if distExit < Config.InteractDistance then
                    ShowHelpNotification("Press ~INPUT_CONTEXT~ to exit the Diamond Casino")

                    if IsControlJustReleased(0, 38) then -- E key
                        ExitCasino()
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Cleanup NPCs when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DespawnCasinoNPCs()
    end
end)
