-- ═══════════════════════════════════════════════════
--  MY_RACING  –  Client
-- ═══════════════════════════════════════════════════

local isMenuOpen      = false
local isCreatingTrack = false
local isInRace        = false
local currentLobbyId  = nil

-- Creation state
local creationCheckpoints = {}  -- ordered {x,y,z,h?}
local creationBlips       = {}
local creationMarkers     = {}
local creationName        = ''

-- Race state
local raceTrack           = nil
local raceCheckpoints     = {}   -- combined: checkpoints + optional start at end
local raceCurrentCP       = 0
local raceBlips           = {}
local raceLobbyId         = nil
local raceCountdown       = 0

-- Result display state
local raceResultText      = nil
local raceResultTimer     = 0

-- ========================================
-- HELPERS
-- ========================================

local function ShowNotification(msg)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry('STRING')
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

local function DrawInstructional(text)
    SetTextFont(4)
    SetTextScale(0.4, 0.4)
    SetTextColour(255, 255, 255, 200)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(0.5, 0.93)
end

-- Help text (black box, top-left, supports longer text)
local function ShowHelpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- ========================================
-- INSTRUCTIONAL BUTTONS (Scaleform)
-- ========================================
-- Displays proper GTA-style button prompts at the bottom of the screen.
-- Usage: call SetupInstructionalButtons with a table of {button, label} every frame.

local instructionalScaleform = nil

local function SetupInstructionalButtons(buttons)
    -- buttons = { {button = "~INPUT_PICKUP~", label = "Place Checkpoint"}, ... }
    if not instructionalScaleform then
        instructionalScaleform = RequestScaleformMovie('instructional_buttons')
        while not HasScaleformMovieLoaded(instructionalScaleform) do
            Wait(0)
        end
    end

    PushScaleformMovieFunction(instructionalScaleform, 'CLEAR_ALL')
    PopScaleformMovieFunctionVoid()

    for i, btn in ipairs(buttons) do
        PushScaleformMovieFunction(instructionalScaleform, 'SET_DATA_SLOT')
        PushScaleformMovieFunctionParameterInt(i - 1)
        PushScaleformMovieMethodParameterButtonName(GetControlInstructionalButton(0, btn.control, true))
        PushScaleformMovieFunctionParameterString(btn.label)
        PopScaleformMovieFunctionVoid()
    end

    PushScaleformMovieFunction(instructionalScaleform, 'DRAW_INSTRUCTIONAL_BUTTONS')
    PopScaleformMovieFunctionVoid()

    DrawScaleformMovieFullscreen(instructionalScaleform, 255, 255, 255, 255, 0)
end

-- ========================================
-- MENU (NUI) OPEN / CLOSE
-- ========================================

local function OpenMenu()
    if isMenuOpen then return end
    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    TriggerServerEvent('my_racing:requestTracks')
    TriggerServerEvent('my_racing:requestLobbies')
end

local function CloseMenu()
    if not isMenuOpen then return end
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- Phone triggers this event
RegisterNetEvent('my_racing:openMenu')
AddEventHandler('my_racing:openMenu', function()
    OpenMenu()
end)

RegisterCommand('racing', function()
    OpenMenu()
end, false)

-- ========================================
-- NUI CALLBACKS
-- ========================================

RegisterNUICallback('closeMenu', function(_, cb)
    CloseMenu()
    cb('ok')
end)

RegisterNUICallback('startCreation', function(data, cb)
    CloseMenu()
    creationName = data.name or 'Unnamed Track'
    StartTrackCreation()
    cb('ok')
end)

RegisterNUICallback('deleteTracks', function(data, cb)
    TriggerServerEvent('my_racing:deleteTrack', data.trackId)
    cb('ok')
end)

RegisterNUICallback('createLobby', function(data, cb)
    -- Don't close menu - lobbyUpdate will switch to lobby tab
    TriggerServerEvent('my_racing:createLobby', data.trackId, tonumber(data.betAmount) or 0)
    cb('ok')
end)

RegisterNUICallback('joinLobby', function(data, cb)
    -- Don't close menu - lobbyUpdate will switch to lobby tab
    TriggerServerEvent('my_racing:joinLobby', data.lobbyId)
    cb('ok')
end)

RegisterNUICallback('leaveLobby', function(_, cb)
    TriggerServerEvent('my_racing:leaveLobby')
    currentLobbyId = nil
    cb('ok')
end)

RegisterNUICallback('startRace', function(_, cb)
    TriggerServerEvent('my_racing:startRace')
    cb('ok')
end)

RegisterNUICallback('requestTracks', function(_, cb)
    TriggerServerEvent('my_racing:requestTracks')
    cb('ok')
end)

RegisterNUICallback('requestLobbies', function(_, cb)
    TriggerServerEvent('my_racing:requestLobbies')
    cb('ok')
end)

-- ========================================
-- SERVER -> CLIENT DATA
-- ========================================

RegisterNetEvent('my_racing:receiveTracks')
AddEventHandler('my_racing:receiveTracks', function(data)
    SendNUIMessage({ action = 'updateTracks', tracks = data })
end)

RegisterNetEvent('my_racing:lobbyListUpdate')
AddEventHandler('my_racing:lobbyListUpdate', function(data)
    SendNUIMessage({ action = 'updateLobbies', lobbies = data })
end)

RegisterNetEvent('my_racing:lobbyUpdate')
AddEventHandler('my_racing:lobbyUpdate', function(data)
    currentLobbyId = data.lobbyId
    SendNUIMessage({ action = 'lobbyState', lobby = data })
    -- If menu is already open, just switch tab. If not, open it.
    if isMenuOpen then
        SendNUIMessage({ action = 'switchToLobby' })
    else
        isMenuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'openLobby' })
    end
end)

RegisterNetEvent('my_racing:lobbyClosed')
AddEventHandler('my_racing:lobbyClosed', function()
    currentLobbyId = nil
    ShowNotification('~r~Lobby has been closed.')
    SendNUIMessage({ action = 'lobbyClosed' })
    -- Close the menu and release cursor
    CloseMenu()
end)

RegisterNetEvent('my_racing:notify')
AddEventHandler('my_racing:notify', function(msg)
    ShowNotification(msg)
end)

-- ========================================
-- TRACK CREATION MODE
-- ========================================

function StartTrackCreation()
    if isCreatingTrack then return end
    if isInRace then
        ShowNotification('~r~Cannot create track during a race.')
        return
    end

    isCreatingTrack    = true
    creationCheckpoints = {}
    ClearCreationVisuals()

    ShowNotification('~b~Track Creation Started!')
end

function ClearCreationVisuals()
    for _, b in ipairs(creationBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    creationBlips = {}
end

function FinishTrackCreation(loop)
    if not isCreatingTrack then return end

    if #creationCheckpoints < Config.MinCheckpoints then
        ShowNotification('~r~Need at least ' .. Config.MinCheckpoints .. ' checkpoints (including start).')
        return
    end

    isCreatingTrack = false

    local start = creationCheckpoints[1]
    local cps   = {}
    for i = 2, #creationCheckpoints do
        table.insert(cps, creationCheckpoints[i])
    end

    TriggerServerEvent('my_racing:createTrack', {
        name        = creationName,
        start       = start,
        checkpoints = cps,
        loop        = loop,
    })

    ClearCreationVisuals()
    creationCheckpoints = {}
end

function CancelTrackCreation()
    isCreatingTrack = false
    ClearCreationVisuals()
    creationCheckpoints = {}
    ShowNotification('~r~Track creation cancelled.')
end

-- Creation loop
CreateThread(function()
    while true do
        Wait(0)
        if isCreatingTrack then
            local ped = PlayerPedId()
            local inVeh = IsPedInAnyVehicle(ped, false)

            -- Instructional buttons (scaleform – proper GTA-style button prompts)
            if #creationCheckpoints == 0 then
                SetupInstructionalButtons({
                    { control = Config.Keys.PlaceCheckpoint, label = 'Place START' },
                    { control = Config.Keys.Cancel,          label = 'Cancel' },
                })
            else
                SetupInstructionalButtons({
                    { control = Config.Keys.PlaceCheckpoint, label = 'Place Checkpoint (' .. #creationCheckpoints .. ')' },
                    { control = Config.Keys.FinalizeEnd,     label = 'Finish Here' },
                    { control = Config.Keys.FinalizeLoop,    label = 'Loop to Start' },
                    { control = Config.Keys.Cancel,          label = 'Cancel' },
                })
            end

            -- Draw existing creation checkpoints
            for i, cp in ipairs(creationCheckpoints) do
                local r, g, b = 255, 165, 0
                if i == 1 then r, g, b = 0, 255, 0 end -- start = green

                DrawMarker(1, cp.x, cp.y, cp.z - 1.0, 0, 0, 0, 0, 0, 0,
                    Config.CheckpointRadius * 1.2, Config.CheckpointRadius * 1.2, 4.0,
                    r, g, b, 100, false, false, 2, false, nil, nil, false)

                DrawText3D(cp.x, cp.y, cp.z + 3.0, i == 1 and '~g~START' or ('CP ' .. (i - 1)))
            end

            -- Place checkpoint with E
            if IsControlJustPressed(0, Config.Keys.PlaceCheckpoint) then
                local pos = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)

                local cp = { x = pos.x, y = pos.y, z = pos.z, h = heading }
                table.insert(creationCheckpoints, cp)

                -- Add blip
                local blip = AddBlipForCoord(pos.x, pos.y, pos.z)
                SetBlipSprite(blip, 1)
                if #creationCheckpoints == 1 then
                    SetBlipColour(blip, 2) -- green for start
                    SetBlipDisplay(blip, 4)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentString('Race Start')
                    EndTextCommandSetBlipName(blip)
                else
                    SetBlipColour(blip, 17) -- orange for checkpoints
                    SetBlipDisplay(blip, 4)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentString('Checkpoint ' .. (#creationCheckpoints - 1))
                    EndTextCommandSetBlipName(blip)
                end
                SetBlipScale(blip, 0.7)
                table.insert(creationBlips, blip)

                if #creationCheckpoints == 1 then
                    ShowNotification('~g~Start line placed!')
                    PlaySoundFrontend(-1, 'WAYPOINT_SET', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                else
                    ShowNotification('~y~Checkpoint ' .. (#creationCheckpoints - 1) .. ' placed!')
                    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
                end
            end

            -- Y = finalize (end at last checkpoint)
            if IsControlJustPressed(0, Config.Keys.FinalizeEnd) then
                FinishTrackCreation(false)
            end

            -- U = finalize (loop to start)
            if IsControlJustPressed(0, Config.Keys.FinalizeLoop) then
                FinishTrackCreation(true)
            end

            -- Backspace = cancel
            if IsControlJustPressed(0, Config.Keys.Cancel) then
                CancelTrackCreation()
            end
        end
    end
end)

-- ========================================
-- RACE RUNTIME
-- ========================================

RegisterNetEvent('my_racing:startCountdown')
AddEventHandler('my_racing:startCountdown', function(lobbyId, track, countdownSec, gridPosition)
    -- Close any menu
    CloseMenu()

    gridPosition = gridPosition or 0  -- Default to first position if not provided

    isInRace      = true
    raceLobbyId   = lobbyId
    raceTrack     = track
    raceCurrentCP = 0

    -- Build checkpoint list for the client
    raceCheckpoints = {}
    for _, cp in ipairs(track.checkpoints) do
        table.insert(raceCheckpoints, cp)
    end
    if track.loop then
        -- Add start as final checkpoint
        table.insert(raceCheckpoints, { x = track.start.x, y = track.start.y, z = track.start.z })
    end

    -- Clear any existing race blips
    ClearRaceVisuals()

    -- Fade out screen during teleport for smooth transition
    DoScreenFadeOut(500)
    Wait(500)

    -- Calculate grid position offset (2 cars per row, staggered behind start line)
    local row = math.floor(gridPosition / 2)
    local col = gridPosition % 2
    
    local backwardOffset = row * 8.0  -- 8 units per row
    local sideOffset = (col == 0) and -2.5 or 2.5  -- Left or right of center
    
    -- Calculate offset position based on heading
    local heading = track.start.h or 0.0
    local headingRad = math.rad(heading)
    
    -- Rotate offsets based on heading (backward relative to heading direction)
    local offsetX = track.start.x - (math.sin(headingRad) * backwardOffset) + (math.cos(headingRad) * sideOffset)
    local offsetY = track.start.y + (math.cos(headingRad) * backwardOffset) + (math.sin(headingRad) * sideOffset)
    local offsetZ = track.start.z

    -- Teleport player to start
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        SetEntityCoords(veh, offsetX, offsetY, offsetZ, false, false, false, false)
        SetEntityHeading(veh, heading)
        
        -- Ensure vehicle and player are visible and networked
        SetEntityVisible(veh, true, false)
        SetEntityVisible(ped, true, false)
        SetEntityCollision(veh, true, true)
        NetworkSetEntityInvisibleToNetwork(veh, false)
        
        FreezeEntityPosition(veh, true)
    else
        SetEntityCoords(ped, offsetX, offsetY, offsetZ, false, false, false, false)
        SetEntityHeading(ped, heading)
        
        -- Ensure player is visible
        SetEntityVisible(ped, true, false)
        SetEntityCollision(ped, true, true)
        
        FreezeEntityPosition(ped, true)
    end

    -- Wait for network synchronization (allow time for all players to load at starting grid)
    Wait(1000)

    -- Fade back in - all players should now be visible
    DoScreenFadeIn(500)
    Wait(500)

    -- Countdown
    raceCountdown = countdownSec
    CreateThread(function()
        for i = countdownSec, 1, -1 do
            raceCountdown = i
            PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
            Wait(1000)
        end

        raceCountdown = 0
        PlaySoundFrontend(-1, 'WAYPOINT_SET', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

        -- Unfreeze
        local p2 = PlayerPedId()
        local v2 = GetVehiclePedIsIn(p2, false)
        if v2 ~= 0 then
            FreezeEntityPosition(v2, false)
            -- Ensure still visible after unfreeze
            SetEntityVisible(v2, true, false)
            SetEntityVisible(p2, true, false)
        else
            FreezeEntityPosition(p2, false)
            SetEntityVisible(p2, true, false)
        end

        ShowNotification('~g~GO!')

        -- Add blips for all checkpoints
        for i, cp in ipairs(raceCheckpoints) do
            local blip = AddBlipForCoord(cp.x, cp.y, cp.z)
            SetBlipSprite(blip, 1)
            if i == 1 then
                SetBlipColour(blip, 5) -- yellow – next
            else
                SetBlipColour(blip, 0) -- white
            end
            SetBlipScale(blip, 0.65)
            SetBlipDisplay(blip, 4)
            table.insert(raceBlips, blip)
        end

        -- Set waypoint to first checkpoint
        if raceCheckpoints[1] then
            SetNewWaypoint(raceCheckpoints[1].x, raceCheckpoints[1].y)
        end
    end)
end)

function ClearRaceVisuals()
    for _, b in ipairs(raceBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    raceBlips = {}
end

-- Race draw loop
CreateThread(function()
    while true do
        Wait(0)
        if isInRace then
            -- Draw countdown
            if raceCountdown > 0 then
                DrawInstructional('~y~Race starts in: ~w~' .. raceCountdown)
            else
                -- Draw next checkpoint marker and detect crossing
                local nextIdx = raceCurrentCP + 1
                if nextIdx <= #raceCheckpoints then
                    local cp  = raceCheckpoints[nextIdx]
                    local ped = PlayerPedId()
                    local pos = GetEntityCoords(ped)
                    local dist = #(pos - vector3(cp.x, cp.y, cp.z))

                    -- Cylinder marker at next checkpoint
                    DrawMarker(1, cp.x, cp.y, cp.z - 1.0, 0, 0, 0, 0, 0, 0,
                        Config.CheckpointRadius * 2.0, Config.CheckpointRadius * 2.0, 6.0,
                        255, 204, 0, 120, false, false, 2, false, nil, nil, false)

                    DrawText3D(cp.x, cp.y, cp.z + 4.0, nextIdx == #raceCheckpoints and '~g~FINISH' or ('CP ' .. nextIdx .. '/' .. #raceCheckpoints))

                    -- HUD info
                    DrawInstructional('Checkpoint: ' .. nextIdx .. ' / ' .. #raceCheckpoints .. '   |   Dist: ' .. math.floor(dist) .. 'm')

                    -- Detect crossing
                    if dist < Config.CheckpointRadius then
                        raceCurrentCP = nextIdx
                        TriggerServerEvent('my_racing:checkpointReached', raceLobbyId, nextIdx)
                        PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)

                        -- Update blip colors
                        if raceBlips[nextIdx] then
                            SetBlipColour(raceBlips[nextIdx], 2) -- green = passed
                        end
                        if raceBlips[nextIdx + 1] then
                            SetBlipColour(raceBlips[nextIdx + 1], 5) -- yellow = next
                            local ncp = raceCheckpoints[nextIdx + 1]
                            SetNewWaypoint(ncp.x, ncp.y)
                        end
                    end

                    -- Draw all other checkpoints as markers (dimmed)
                    for i, c in ipairs(raceCheckpoints) do
                        if i ~= nextIdx then
                            local r, g, b, a = 100, 100, 100, 40
                            if i < nextIdx then
                                r, g, b, a = 0, 200, 0, 50 -- passed = dim green
                            end
                            DrawMarker(1, c.x, c.y, c.z - 1.0, 0, 0, 0, 0, 0, 0,
                                Config.CheckpointRadius * 1.0, Config.CheckpointRadius * 1.0, 3.0,
                                r, g, b, a, false, false, 2, false, nil, nil, false)
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('my_racing:checkpointConfirmed')
AddEventHandler('my_racing:checkpointConfirmed', function(idx)
    -- Already handled by client prediction
end)

RegisterNetEvent('my_racing:playerFinished')
AddEventHandler('my_racing:playerFinished', function(name, position)
    ShowNotification('~b~' .. name .. '~w~ finished in position ~y~#' .. position)
end)

RegisterNetEvent('my_racing:raceEnded')
AddEventHandler('my_racing:raceEnded', function(results)
    isInRace      = false
    raceTrack     = nil
    raceCurrentCP = 0
    raceLobbyId   = nil
    currentLobbyId = nil
    ClearRaceVisuals()

    -- Show results as on-screen text (like creation instructions)
    local winnerName = results.winnerName or 'Nobody'
    local pot        = results.pot or 0
    local mySource   = GetPlayerServerId(PlayerId())
    local isWinner   = false

    if results.results then
        for _, r in ipairs(results.results) do
            if r.source == mySource and r.position == 1 then
                isWinner = true
                break
            end
        end
    end

    local msg
    if isWinner then
        msg = '~g~YOU WON! ~w~+$' .. pot
    else
        msg = '~r~You lost. ~w~Winner: ~y~' .. winnerName .. '~w~ ($' .. pot .. ')'
    end

    -- Display the result on screen for several seconds
    raceResultText = msg
    raceResultTimer = GetGameTimer() + 8000 -- show for 8 seconds
end)

-- ========================================
-- RESULT DISPLAY
-- ========================================

CreateThread(function()
    while true do
        Wait(0)
        if raceResultText and GetGameTimer() < raceResultTimer then
            DrawInstructional(raceResultText)
        else
            raceResultText = nil
        end
    end
end)

-- ========================================
-- CLEANUP
-- ========================================

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isMenuOpen then CloseMenu() end
    ClearCreationVisuals()
    ClearRaceVisuals()
    isCreatingTrack = false
    isInRace        = false
end)
