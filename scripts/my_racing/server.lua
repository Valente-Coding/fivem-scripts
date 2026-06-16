-- ═══════════════════════════════════════════════════
--  MY_RACING  –  Server
-- ═══════════════════════════════════════════════════

local tracks  = {}   -- array of track objects
local lobbies = {}   -- lobbyId -> lobby object
local activeRaces = {} -- lobbyId -> race state
local nextLobbyId = 1

-- ========================================
-- HELPERS
-- ========================================

local function GetLicense(src)
    return exports['my_datamanager']:GetPlayerLicense(src)
end

local function IsAdmin(src)
    local lic = GetLicense(src)
    if not lic then return false end
    for _, admin in ipairs(Config.AdminLicenses) do
        if admin == lic then return true end
    end
    return false
end

local function Notify(src, msg)
    TriggerClientEvent('my_racing:notify', src, msg)
end

local function GenerateTrackId()
    return 'track_' .. os.time() .. '_' .. math.random(1000, 9999)
end

-- ========================================
-- PERSISTENCE  (resource-scoped file)
-- ========================================

local TRACKS_FILE = 'data/tracks.json'

local function LoadTracks()
    local raw = LoadResourceFile(GetCurrentResourceName(), TRACKS_FILE)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then
            tracks = data
            return
        end
    end
    tracks = {}
end

local function SaveTracks()
    local raw = json.encode(tracks, { indent = true })
    SaveResourceFile(GetCurrentResourceName(), TRACKS_FILE, raw, -1)
end

CreateThread(function()
    LoadTracks()
end)

-- ========================================
-- TRACK CRUD
-- ========================================

RegisterNetEvent('my_racing:requestTracks')
AddEventHandler('my_racing:requestTracks', function()
    local src = source
    TriggerClientEvent('my_racing:receiveTracks', src, tracks)
end)

RegisterNetEvent('my_racing:createTrack')
AddEventHandler('my_racing:createTrack', function(trackData)
    local src = source
    local lic = GetLicense(src)
    if not lic then Notify(src, 'Could not verify identity.') return end

    if not trackData or not trackData.name or not trackData.start or not trackData.checkpoints then
        Notify(src, 'Invalid track data.')
        return
    end

    if #trackData.checkpoints < (Config.MinCheckpoints - 1) then
        Notify(src, 'Need at least ' .. Config.MinCheckpoints .. ' checkpoints (including start).')
        return
    end

    local track = {
        id              = GenerateTrackId(),
        name            = tostring(trackData.name):sub(1, 40),
        creator_license = lic,
        creator_name    = GetPlayerName(src) or 'Unknown',
        createdAt       = os.time(),
        start           = trackData.start,       -- {x,y,z,h}
        checkpoints     = trackData.checkpoints, -- [{x,y,z}, ...]
        loop            = trackData.loop == true,
    }

    table.insert(tracks, track)
    SaveTracks()

    Notify(src, 'Track "' .. track.name .. '" created!')
    -- Broadcast updated list
    TriggerClientEvent('my_racing:receiveTracks', -1, tracks)
end)

RegisterNetEvent('my_racing:deleteTrack')
AddEventHandler('my_racing:deleteTrack', function(trackId)
    local src = source
    local lic = GetLicense(src)
    if not lic then return end

    for i, t in ipairs(tracks) do
        if t.id == trackId then
            if t.creator_license == lic or IsAdmin(src) then
                table.remove(tracks, i)
                SaveTracks()
                Notify(src, 'Track deleted.')
                TriggerClientEvent('my_racing:receiveTracks', -1, tracks)
            else
                Notify(src, 'You do not own this track.')
            end
            return
        end
    end
    Notify(src, 'Track not found.')
end)

-- ========================================
-- LOBBY MANAGEMENT
-- ========================================

local function GetLobbyByPlayer(src)
    for id, lobby in pairs(lobbies) do
        if lobby.host == src then return id, lobby end
        for _, p in ipairs(lobby.players) do
            if p.source == src then return id, lobby end
        end
    end
    return nil, nil
end

local function BroadcastLobbyUpdate(lobbyId)
    local lobby = lobbies[lobbyId]
    if not lobby then return end

    local playerList = {}
    for _, p in ipairs(lobby.players) do
        table.insert(playerList, { name = p.name, source = p.source })
    end

    local payload = {
        lobbyId    = lobbyId,
        trackId    = lobby.trackId,
        trackName  = lobby.trackName,
        host       = lobby.host,
        hostName   = lobby.hostName,
        betAmount  = lobby.betAmount,
        players    = playerList,
        pot        = lobby.pot,
    }

    for _, p in ipairs(lobby.players) do
        TriggerClientEvent('my_racing:lobbyUpdate', p.source, payload)
    end
end

local function RefundPlayer(src, amount)
    if amount > 0 then
        exports['my_money']:AddMoney(src, Config.BetCurrency, amount)
        Notify(src, 'Refunded $' .. amount)
    end
end

RegisterNetEvent('my_racing:createLobby')
AddEventHandler('my_racing:createLobby', function(trackId, betAmount)
    local src = source
    betAmount = tonumber(betAmount) or 0
    if betAmount < 0 then betAmount = 0 end
    if betAmount < Config.MinBet then
        Notify(src, 'Minimum bet is $' .. Config.MinBet)
        return
    end

    -- Check player not already in a lobby
    local existId = GetLobbyByPlayer(src)
    if existId then
        Notify(src, 'You are already in a lobby. Leave first.')
        return
    end

    -- Find track
    local track = nil
    for _, t in ipairs(tracks) do
        if t.id == trackId then track = t break end
    end
    if not track then Notify(src, 'Track not found.') return end

    -- Escrow bet
    if betAmount > 0 then
        local ok = exports['my_money']:RemoveMoney(src, Config.BetCurrency, betAmount)
        if not ok then
            Notify(src, 'Insufficient funds for $' .. betAmount .. ' bet.')
            return
        end
    end

    local lobbyId = nextLobbyId
    nextLobbyId = nextLobbyId + 1

    lobbies[lobbyId] = {
        trackId   = trackId,
        trackName = track.name,
        host      = src,
        hostName  = GetPlayerName(src) or 'Unknown',
        betAmount = betAmount,
        pot       = betAmount,
        players   = {
            { source = src, name = GetPlayerName(src) or 'Unknown', escrow = betAmount }
        },
        started   = false,
    }

    Notify(src, 'Lobby created! Waiting for players...')
    BroadcastLobbyUpdate(lobbyId)
    -- Also tell all clients that a lobby is available
    TriggerClientEvent('my_racing:lobbyListUpdate', -1, GetPublicLobbies())
end)

function GetPublicLobbies()
    local list = {}
    for id, lobby in pairs(lobbies) do
        if not lobby.started then
            table.insert(list, {
                lobbyId   = id,
                trackName = lobby.trackName,
                hostName  = lobby.hostName,
                betAmount = lobby.betAmount,
                players   = #lobby.players,
            })
        end
    end
    return list
end

RegisterNetEvent('my_racing:requestLobbies')
AddEventHandler('my_racing:requestLobbies', function()
    TriggerClientEvent('my_racing:lobbyListUpdate', source, GetPublicLobbies())
end)

RegisterNetEvent('my_racing:joinLobby')
AddEventHandler('my_racing:joinLobby', function(lobbyId)
    local src = source
    local lobby = lobbies[lobbyId]
    if not lobby then Notify(src, 'Lobby no longer exists.') return end
    if lobby.started then Notify(src, 'Race already started.') return end

    -- Already in a lobby?
    local existId = GetLobbyByPlayer(src)
    if existId then
        Notify(src, 'Leave your current lobby first.')
        return
    end

    -- Max players check
    if Config.MaxLobbyPlayers > 0 and #lobby.players >= Config.MaxLobbyPlayers then
        Notify(src, 'Lobby is full.')
        return
    end

    -- Escrow bet
    if lobby.betAmount > 0 then
        local ok = exports['my_money']:RemoveMoney(src, Config.BetCurrency, lobby.betAmount)
        if not ok then
            Notify(src, 'Insufficient funds for $' .. lobby.betAmount .. ' bet.')
            return
        end
    end

    table.insert(lobby.players, {
        source = src,
        name   = GetPlayerName(src) or 'Unknown',
        escrow = lobby.betAmount,
    })
    lobby.pot = lobby.pot + lobby.betAmount

    Notify(src, 'Joined lobby! Bet: $' .. lobby.betAmount)
    BroadcastLobbyUpdate(lobbyId)
    TriggerClientEvent('my_racing:lobbyListUpdate', -1, GetPublicLobbies())
end)

RegisterNetEvent('my_racing:leaveLobby')
AddEventHandler('my_racing:leaveLobby', function()
    local src = source
    local lobbyId, lobby = GetLobbyByPlayer(src)
    if not lobbyId then return end

    if lobby.started then
        Notify(src, 'Cannot leave during a race.')
        return
    end

    -- Refund and remove
    for i, p in ipairs(lobby.players) do
        if p.source == src then
            RefundPlayer(src, p.escrow)
            lobby.pot = lobby.pot - p.escrow
            table.remove(lobby.players, i)
            break
        end
    end

    -- If host left or lobby empty, disband
    if #lobby.players == 0 or lobby.host == src then
        -- Refund remaining
        for _, p in ipairs(lobby.players) do
            RefundPlayer(p.source, p.escrow)
            TriggerClientEvent('my_racing:lobbyClosed', p.source)
        end
        lobbies[lobbyId] = nil
        TriggerClientEvent('my_racing:lobbyClosed', src)
        Notify(src, 'Lobby disbanded.')
    else
        TriggerClientEvent('my_racing:lobbyClosed', src)
        BroadcastLobbyUpdate(lobbyId)
    end

    TriggerClientEvent('my_racing:lobbyListUpdate', -1, GetPublicLobbies())
end)

-- ========================================
-- RACE START & FINISH
-- ========================================

RegisterNetEvent('my_racing:startRace')
AddEventHandler('my_racing:startRace', function()
    local src = source
    local lobbyId, lobby = GetLobbyByPlayer(src)
    if not lobbyId or not lobby then return end
    if lobby.host ~= src then Notify(src, 'Only the host can start.') return end
    if lobby.started then Notify(src, 'Already started.') return end
    if #lobby.players < 1 then Notify(src, 'Need at least 1 player.') return end

    lobby.started = true

    -- Find track data
    local track = nil
    for _, t in ipairs(tracks) do
        if t.id == lobby.trackId then track = t break end
    end
    if not track then
        Notify(src, 'Track data missing!')
        return
    end

    -- Init race state
    activeRaces[lobbyId] = {
        track       = track,
        playerState = {},  -- src -> { checkpoint = 0, finished = false, finishTime = 0 }
        startTime   = 0,
        finished    = {},
    }

    for _, p in ipairs(lobby.players) do
        activeRaces[lobbyId].playerState[p.source] = {
            checkpoint = 0,
            finished   = false,
            finishTime = 0,
        }
    end

    -- Tell clients to start countdown and race (with their grid position)
    for i, p in ipairs(lobby.players) do
        local gridPosition = i - 1  -- 0-indexed for first player at front
        TriggerClientEvent('my_racing:startCountdown', p.source, lobbyId, track, Config.CountdownSeconds, gridPosition)
    end

    -- Record start time after countdown
    SetTimeout(Config.CountdownSeconds * 1000, function()
        if activeRaces[lobbyId] then
            activeRaces[lobbyId].startTime = GetGameTimer()
        end
    end)

    TriggerClientEvent('my_racing:lobbyListUpdate', -1, GetPublicLobbies())
end)

RegisterNetEvent('my_racing:checkpointReached')
AddEventHandler('my_racing:checkpointReached', function(lobbyId, checkpointIndex)
    local src = source
    local race = activeRaces[lobbyId]
    if not race then return end

    local ps = race.playerState[src]
    if not ps or ps.finished then return end

    -- Validate sequential progression
    if checkpointIndex ~= ps.checkpoint + 1 then return end

    ps.checkpoint = checkpointIndex

    local totalCheckpoints = #race.track.checkpoints
    local needFinishAtStart = race.track.loop

    -- Determine total target
    local target = totalCheckpoints
    if needFinishAtStart then
        target = totalCheckpoints + 1  -- extra checkpoint = start
    end

    if checkpointIndex >= target then
        ps.finished   = true
        ps.finishTime = GetGameTimer()
        table.insert(race.finished, src)

        -- Notify all players
        local lobby = lobbies[lobbyId]
        if lobby then
            local name = GetPlayerName(src) or 'Unknown'
            local pos  = #race.finished

            for _, p in ipairs(lobby.players) do
                TriggerClientEvent('my_racing:playerFinished', p.source, name, pos)
            end
        end

        -- Check if first finisher (winner)
        if #race.finished == 1 then
            -- This is the winner – we'll wait briefly for everyone else or end
            -- Set a timeout to end race after 30 seconds
            SetTimeout(30000, function()
                EndRace(lobbyId)
            end)
        end

        -- Check if all finished
        local allDone = true
        for _, state in pairs(race.playerState) do
            if not state.finished then allDone = false break end
        end
        if allDone then
            EndRace(lobbyId)
        end
    else
        -- Notify player of progress
        TriggerClientEvent('my_racing:checkpointConfirmed', src, checkpointIndex)
    end
end)

function EndRace(lobbyId)
    local race  = activeRaces[lobbyId]
    local lobby = lobbies[lobbyId]
    if not race or not lobby then return end
    if race.ended then return end
    race.ended = true

    local winner = race.finished[1]
    local pot    = lobby.pot

    if winner and pot > 0 then
        exports['my_money']:AddMoney(winner, Config.BetCurrency, pot)
    end

    -- Build results
    local results = {}
    for i, src in ipairs(race.finished) do
        table.insert(results, {
            position = i,
            name     = GetPlayerName(src) or 'Unknown',
            source   = src,
        })
    end

    -- DNF players
    for _, p in ipairs(lobby.players) do
        local ps = race.playerState[p.source]
        if ps and not ps.finished then
            table.insert(results, {
                position = #results + 1,
                name     = p.name,
                source   = p.source,
                dnf      = true,
            })
        end
    end

    local winnerName = winner and (GetPlayerName(winner) or 'Unknown') or 'Nobody'

    for _, p in ipairs(lobby.players) do
        TriggerClientEvent('my_racing:raceEnded', p.source, {
            results    = results,
            winnerName = winnerName,
            pot        = pot,
        })
        -- Close the lobby for each player
        TriggerClientEvent('my_racing:lobbyClosed', p.source)
    end

    -- Cleanup
    activeRaces[lobbyId] = nil
    lobbies[lobbyId]     = nil
    TriggerClientEvent('my_racing:lobbyListUpdate', -1, GetPublicLobbies())
    TriggerClientEvent('my_racing:lobbyListUpdate', -1, GetPublicLobbies())
end

-- ========================================
-- DISCONNECT HANDLING
-- ========================================

AddEventHandler('playerDropped', function()
    local src = source
    local lobbyId, lobby = GetLobbyByPlayer(src)
    if not lobbyId or not lobby then return end

    if lobby.started then
        -- Mark as DNF in active race
        local race = activeRaces[lobbyId]
        if race and race.playerState[src] then
            race.playerState[src].finished   = true
            race.playerState[src].finishTime = GetGameTimer()
            -- Don't add to finished (they don't win)
        end

        -- Check if all done
        if race then
            local allDone = true
            for _, state in pairs(race.playerState) do
                if not state.finished then allDone = false break end
            end
            if allDone then EndRace(lobbyId) end
        end
    else
        -- Refund and remove from pre-race lobby
        for i, p in ipairs(lobby.players) do
            if p.source == src then
                lobby.pot = lobby.pot - p.escrow
                -- Can't refund a dropped player, so pot shrinks
                table.remove(lobby.players, i)
                break
            end
        end

        if #lobby.players == 0 or lobby.host == src then
            for _, p in ipairs(lobby.players) do
                RefundPlayer(p.source, p.escrow)
                TriggerClientEvent('my_racing:lobbyClosed', p.source)
            end
            lobbies[lobbyId] = nil
        else
            BroadcastLobbyUpdate(lobbyId)
        end
        TriggerClientEvent('my_racing:lobbyListUpdate', -1, GetPublicLobbies())
    end
end)

-- ========================================
-- CLEANUP ON RESOURCE STOP
-- ========================================

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    -- Refund all active lobbies
    for _, lobby in pairs(lobbies) do
        if not lobby.started then
            for _, p in ipairs(lobby.players) do
                RefundPlayer(p.source, p.escrow)
            end
        end
    end
end)

