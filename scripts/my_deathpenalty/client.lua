-- Permadeath Client
-- When a player dies, triggers a full data wipe on the server.
-- Whitelisted players are respawned normally without data loss.
-- Non-whitelisted players see a stats rundown and must click "Restart Journey".

local respawnCoords = vector3(342.5592, -1398.0648, 32.5093)
local respawnHeading = 70.0
local isDead = false
local deathTimer = 0
local isWhitelisted = false
local isPermadeath = false -- true when death screen is shown, waiting for button
local respawnCooldown = 0   -- timestamp: ignore deaths until this time
local RESPAWN_DELAY = 10 -- seconds before respawn (whitelisted only)
local RESPAWN_COOLDOWN_MS = 15000 -- ignore deaths for 15s after respawn

-- Disable ALL automatic respawn systems so deaths are handled
-- exclusively by this resource.
local function DisableAutoRespawn()
    -- Disable spawnmanager if available (pcall in case it doesn't exist)
    pcall(function() exports.spawnmanager:setAutoSpawn(false) end)
end

-- Disable on resource start (retry until spawnmanager is ready)
CreateThread(function()
    for i = 1, 10 do
        DisableAutoRespawn()
        Wait(1000)
    end
end)

-- Also disable after every spawn (basic-gamemode may re-enable it)
AddEventHandler('playerSpawned', function()
    DisableAutoRespawn()
end)

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

-- Server tells us this player is whitelisted — do a normal respawn instead
RegisterNetEvent('my_deathpenalty:whitelisted')
AddEventHandler('my_deathpenalty:whitelisted', function()
    isWhitelisted = true
end)

-- Server sends us the death screen with stats
RegisterNetEvent('my_deathpenalty:showDeathScreen')
AddEventHandler('my_deathpenalty:showDeathScreen', function(stats)
    isPermadeath = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showDeathScreen',
        stats = stats
    })
end)

-- NUI callback: player clicked "Restart Journey"
RegisterNUICallback('restartJourney', function(data, cb)
    cb('ok')
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideDeathScreen' })

    -- Tell the server we're ready to restart (server refills energy, etc.)
    TriggerServerEvent('my_deathpenalty:restartJourney')
end)

-- Server tells us data has been wiped — respawn from scratch
RegisterNetEvent('my_deathpenalty:permadeathRespawn')
AddEventHandler('my_deathpenalty:permadeathRespawn', function()
    -- Ensure the death screen NUI is fully dismissed
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideDeathScreen' })

    isPermadeath = false
    DoRespawn(true)
end)

-- Monitor for player death
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()

        if IsEntityDead(playerPed) and not isDead and GetGameTimer() > respawnCooldown then
            isDead = true
            isWhitelisted = false
            isPermadeath = false
            deathTimer = GetGameTimer()

            -- Cancel any active jobs/missions
            TriggerEvent('my_truckingjob:forceCancel')
            TriggerEvent('my_deliveriesJob:forceCancel')
            TriggerEvent('my_warehousejob:forceCancel')
            TriggerEvent('my_vehicleFlipper:forceCancel')

            -- Notify server – server decides whether to wipe or whitelist
            TriggerServerEvent('my_deathpenalty:onPlayerDied')
        end

        if isDead then
            -- Block the GTA engine's built-in respawn every frame
            SetFadeOutAfterDeath(false)
            IgnoreNextRestart(true)

            if isPermadeath then
                -- Death screen NUI is showing — just wait for the button click
                Wait(500)
            elseif isWhitelisted then
                -- Whitelisted: show a timer and auto-respawn
                local elapsed = (GetGameTimer() - deathTimer) / 1000
                local remaining = math.ceil(RESPAWN_DELAY - elapsed)

                if remaining > 0 then
                    SetTextFont(4)
                    SetTextScale(0.0, 0.5)
                    SetTextColour(255, 255, 255, 255)
                    SetTextDropshadow(0, 0, 0, 0, 255)
                    SetTextEdge(1, 0, 0, 0, 255)
                    SetTextOutline()
                    SetTextCentre(true)
                    SetTextEntry("STRING")
                    AddTextComponentString("~r~YOU DIED~s~\nRespawning in " .. remaining .. "s")
                    DrawText(0.5, 0.4)
                else
                    DoRespawn(false)
                end
                Wait(0)
            else
                -- Waiting for server response
                Wait(100)
            end
        else
            Wait(500)
        end
    end
end)

function DoRespawn(wasPermadeath)
    isDead = false
    isWhitelisted = false
    isPermadeath = false

    -- Prevent the death loop from re-triggering during character creation
    respawnCooldown = GetGameTimer() + RESPAWN_COOLDOWN_MS

    -- Re-enable the GTA engine's respawn natives before we resurrect
    SetFadeOutAfterDeath(true)
    IgnoreNextRestart(false)

    local playerPed = PlayerPedId()

    -- Screen fade out
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do Wait(50) end

    -- Revive and respawn at default spawn point
    local playerId = PlayerId()
    NetworkResurrectLocalPlayer(respawnCoords.x, respawnCoords.y, respawnCoords.z, respawnHeading, true, false)

    playerPed = PlayerPedId()
    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
    ClearPedBloodDamage(playerPed)
    SetPlayerInvincible(playerId, false)

    -- Save full health
    TriggerServerEvent('my_healing:saveHealth', 100)

    -- Screen fade in
    DoScreenFadeIn(800)

    if wasPermadeath then
        ShowNotification("~r~PERMADEATH: ~s~Starting fresh. Create a new character.")
        -- Re-trigger character creation flow
        Citizen.Wait(1500)
        TriggerServerEvent('lbgchar:requestCharacter')
    else
        ShowNotification("~g~You have been respawned.")
    end
end
