local playerEnergy = {}

-- Drain amount per interval: (MaxEnergy / FullDepleteTime) * DrainInterval
local drainPerTick = (Config.MaxEnergy / Config.FullDepleteTime) * Config.DrainInterval

-- ============================================================
-- Player Data Loading / Saving
-- ============================================================

local function LoadPlayerEnergy(source)
    local data = exports['my_datamanager']:GetPlayerDataKey(source, 'energy')
    if data and data.energy then
        playerEnergy[source] = math.max(0, math.min(Config.MaxEnergy, data.energy))
    else
        playerEnergy[source] = Config.DefaultEnergy
    end
    return playerEnergy[source]
end

local function SavePlayerEnergy(source)
    if playerEnergy[source] == nil then return end
    exports['my_datamanager']:SetPlayerDataKey(source, 'energy', {
        energy = playerEnergy[source]
    })
end

-- ============================================================
-- Energy Management Functions
-- ============================================================

local function GetEnergy(source)
    if playerEnergy[source] == nil then
        LoadPlayerEnergy(source)
    end
    return playerEnergy[source] or Config.DefaultEnergy
end

local function SetEnergy(source, amount)
    amount = math.max(0, math.min(Config.MaxEnergy, amount))
    playerEnergy[source] = amount
    TriggerClientEvent('my_energy:updateEnergy', source, amount)
    return amount
end

local function AddEnergy(source, amount)
    local current = GetEnergy(source)
    local newAmount = math.max(0, math.min(Config.MaxEnergy, current + amount))
    playerEnergy[source] = newAmount
    TriggerClientEvent('my_energy:updateEnergy', source, newAmount)
    return newAmount
end

local function RefillEnergy(source)
    return SetEnergy(source, Config.MaxEnergy)
end

-- ============================================================
-- Events
-- ============================================================

-- Player requests their energy on join
RegisterNetEvent('my_energy:requestEnergy')
AddEventHandler('my_energy:requestEnergy', function()
    local source = source
    local energy = LoadPlayerEnergy(source)
    TriggerClientEvent('my_energy:updateEnergy', source, energy)
end)

-- Server event for other scripts to add energy
RegisterNetEvent('my_energy:addEnergy')
AddEventHandler('my_energy:addEnergy', function(amount)
    local source = source
    AddEnergy(source, amount)
end)

-- Server event for other scripts to refill energy
RegisterNetEvent('my_energy:refillEnergy')
AddEventHandler('my_energy:refillEnergy', function()
    local source = source
    RefillEnergy(source)
end)

-- Server event to set energy to a specific value
RegisterNetEvent('my_energy:setEnergy')
AddEventHandler('my_energy:setEnergy', function(amount)
    local source = source
    SetEnergy(source, amount)
end)

-- ============================================================
-- Commands
-- ============================================================

RegisterCommand('setenergy', function(source, args, rawCommand)
    local value = tonumber(args[1])
    if not value then
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, { args = { '^1[Energy]', 'Usage: /setenergy [value]' } })
        else
            print('[Energy] Usage: setenergy [value] [playerID]')
        end
        return
    end

    -- If run from console, require a player ID as second arg
    if source == 0 then
        local targetId = tonumber(args[2])
        if not targetId then
            print('[Energy] Usage from console: setenergy [value] [playerID]')
            return
        end
        SetEnergy(targetId, value)
        print(('[Energy] Set player %d energy to %.1f'):format(targetId, value))
    else
        SetEnergy(source, value)
        TriggerClientEvent('chat:addMessage', source, { args = { '^2[Energy]', ('Energy set to %.1f'):format(value) } })
    end
end, false) -- false = no ACE permission required, any player can use it

-- ============================================================
-- Energy Drain Thread
-- ============================================================

CreateThread(function()
    while true do
        Wait(Config.DrainInterval * 1000)

        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            if src and playerEnergy[src] ~= nil then
                local current = playerEnergy[src]
                if current > 0 then
                    local newEnergy = math.max(0, current - drainPerTick)
                    playerEnergy[src] = newEnergy
                    TriggerClientEvent('my_energy:updateEnergy', src, newEnergy)

                    -- Kill the player when energy reaches 0
                    if newEnergy <= 0 then
                        TriggerClientEvent('my_energy:killPlayer', src)
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- Auto-Save Thread
-- ============================================================

CreateThread(function()
    while true do
        Wait(Config.SaveInterval * 1000)

        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            if src and playerEnergy[src] ~= nil then
                SavePlayerEnergy(src)
            end
        end
    end
end)

-- ============================================================
-- Player Disconnect - Save and Cleanup
-- ============================================================

AddEventHandler('playerDropped', function()
    local source = source
    if playerEnergy[source] ~= nil then
        SavePlayerEnergy(source)
        playerEnergy[source] = nil
    end
end)

-- ============================================================
-- Exports for other scripts
-- ============================================================

exports('GetEnergy', GetEnergy)
exports('SetEnergy', SetEnergy)
exports('AddEnergy', AddEnergy)
exports('RefillEnergy', RefillEnergy)

print("^2[my_energy] Energy system loaded^7")
