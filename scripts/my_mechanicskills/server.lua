-- Mechanic Skills Server
-- Tracks per-player Engine, Transmission, Clutch and Suspension levels.
-- Other resources read/modify these through exports (see bottom of file).

local playerSkills = {}

-- ============================================================
-- Helpers
-- ============================================================

local function IsValidSkill(skillType)
    return Config.Skills[skillType] ~= nil
end

local function DefaultSkillData()
    return { level = Config.StartingLevel, xp = 0 }
end

local function LoadPlayerSkills(source)
    local data = exports['my_datamanager']:GetPlayerDataKey(source, 'mechanicskills')
    local skills = {}

    for skillType, _ in pairs(Config.Skills) do
        if data and data[skillType] then
            skills[skillType] = {
                level = data[skillType].level or Config.StartingLevel,
                xp = data[skillType].xp or 0
            }
        else
            skills[skillType] = DefaultSkillData()
        end
    end

    playerSkills[source] = skills
    return skills
end

local function SavePlayerSkills(source)
    if not playerSkills[source] then return end
    exports['my_datamanager']:SetPlayerDataKey(source, 'mechanicskills', playerSkills[source])
end

local function GetPlayerSkills(source)
    if not playerSkills[source] then
        LoadPlayerSkills(source)
    end
    return playerSkills[source]
end

-- ============================================================
-- Core API
-- ============================================================

-- Returns { level, xp, xpNeeded } for the given skill, or nil if invalid
local function GetSkillData(source, skillType)
    if not IsValidSkill(skillType) then return nil end

    local skill = GetPlayerSkills(source)[skillType]
    return {
        level = skill.level,
        xp = skill.xp,
        xpNeeded = Config.XPForLevel(skill.level)
    }
end

-- Returns just the numeric level for the given skill, or nil if invalid
local function GetLevel(source, skillType)
    if not IsValidSkill(skillType) then return nil end
    return GetPlayerSkills(source)[skillType].level
end

-- Returns a table of { engine = {...}, transmission = {...}, clutch = {...}, suspension = {...} }
local function GetAllSkills(source)
    local skills = GetPlayerSkills(source)
    local result = {}

    for skillType, data in pairs(skills) do
        result[skillType] = {
            level = data.level,
            xp = data.xp,
            xpNeeded = Config.XPForLevel(data.level)
        }
    end

    return result
end

-- Sets a skill to an exact level (clamped 1..MaxLevel) and resets its XP
local function SetLevel(source, skillType, level)
    if not IsValidSkill(skillType) then return nil end
    if type(level) ~= 'number' then return nil end

    level = math.max(1, math.min(Config.MaxLevel, math.floor(level)))

    local skills = GetPlayerSkills(source)
    skills[skillType].level = level
    skills[skillType].xp = 0

    SavePlayerSkills(source)
    TriggerClientEvent('my_mechanicskills:updateSkill', source, skillType, skills[skillType].level, skills[skillType].xp)

    return level
end

-- Adds (or subtracts) whole levels to a skill, clamped to 1..MaxLevel
local function AddLevel(source, skillType, amount)
    if not IsValidSkill(skillType) then return nil end
    if type(amount) ~= 'number' then return nil end

    local skills = GetPlayerSkills(source)
    return SetLevel(source, skillType, skills[skillType].level + amount)
end

-- Adds XP to a skill, automatically handling level ups (can gain multiple levels at once)
-- Returns: newLevel, leveledUp (bool), levelsGained (number)
local function AddXP(source, skillType, amount)
    if not IsValidSkill(skillType) then return nil end
    if type(amount) ~= 'number' or amount <= 0 then return nil end

    local skills = GetPlayerSkills(source)
    local skill = skills[skillType]
    local leveledUp = false
    local levelsGained = 0

    skill.xp = skill.xp + amount

    while skill.level < Config.MaxLevel do
        local needed = Config.XPForLevel(skill.level)
        if skill.xp >= needed then
            skill.xp = skill.xp - needed
            skill.level = skill.level + 1
            leveledUp = true
            levelsGained = levelsGained + 1
        else
            break
        end
    end

    -- Don't accumulate XP once max level is reached
    if skill.level >= Config.MaxLevel then
        skill.xp = 0
    end

    SavePlayerSkills(source)
    TriggerClientEvent('my_mechanicskills:updateSkill', source, skillType, skill.level, skill.xp)

    if leveledUp then
        TriggerClientEvent('my_mechanicskills:levelUp', source, skillType, skill.level, levelsGained)
    end

    return skill.level, leveledUp, levelsGained
end

-- Returns skill data formatted for UI display (label, level, xp, xpNeeded, maxLevel)
local function GetSkillsForDisplay(source)
    local skills = GetAllSkills(source)
    local result = {}

    for skillType, data in pairs(skills) do
        result[skillType] = {
            label = Config.Skills[skillType].label,
            level = data.level,
            xp = data.xp,
            xpNeeded = data.xpNeeded,
            maxLevel = Config.MaxLevel
        }
    end

    return result
end

-- ============================================================
-- Player Connect / Disconnect
-- ============================================================

AddEventHandler('playerConnecting', function()
    local _source = source
    CreateThread(function()
        Wait(1000) -- Wait for player to be ready
        LoadPlayerSkills(_source)
    end)
end)

AddEventHandler('playerDropped', function()
    local _source = source
    if playerSkills[_source] then
        SavePlayerSkills(_source)
        playerSkills[_source] = nil
    end
end)

-- Periodic autosave
CreateThread(function()
    while true do
        Wait(5 * 60 * 1000)

        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            if src and playerSkills[src] then
                SavePlayerSkills(src)
            end
        end
    end
end)

-- ============================================================
-- Client requests
-- ============================================================

RegisterNetEvent('my_mechanicskills:requestSkills')
AddEventHandler('my_mechanicskills:requestSkills', function()
    local _source = source
    TriggerClientEvent('my_mechanicskills:receiveSkills', _source, GetAllSkills(_source))
end)

-- ============================================================
-- Commands
-- ============================================================

RegisterCommand('myskills', function(source, args, rawCommand)
    if source == 0 then return end

    local skills = GetAllSkills(source)
    for skillType, data in pairs(skills) do
        local label = Config.Skills[skillType].label
        TriggerClientEvent('chatMessage', source, "^3[Skills]^7", "",
            string.format("%s: Level %d (%d/%d XP)", label, data.level, data.xp, data.xpNeeded))
    end
end, false)

-- Admin command: set a player's skill to an exact level
RegisterCommand('setmechanicskill', function(source, args, rawCommand)
    local function Reply(msg)
        if source == 0 then print(msg) else TriggerClientEvent('chatMessage', source, "^3ADMIN^7", "", msg) end
    end

    local targetId = tonumber(args[1])
    local skillType = args[2]
    local level = tonumber(args[3])

    if not targetId or not skillType or not level then
        Reply("/setmechanicskill <playerID> <engine|transmission|clutch|suspension> <level>")
        return
    end

    if not IsValidSkill(skillType) then
        Reply("Invalid skill. Use: engine, transmission, clutch, suspension")
        return
    end

    local newLevel = SetLevel(targetId, skillType, level)
    if newLevel then
        Reply(string.format("Set %s's %s level to %d", GetPlayerName(targetId) or tostring(targetId), Config.Skills[skillType].label, newLevel))
    end
end, true) -- ACE restricted

-- Admin command: give a player XP towards a skill
RegisterCommand('addmechanicxp', function(source, args, rawCommand)
    local function Reply(msg)
        if source == 0 then print(msg) else TriggerClientEvent('chatMessage', source, "^3ADMIN^7", "", msg) end
    end

    local targetId = tonumber(args[1])
    local skillType = args[2]
    local amount = tonumber(args[3])

    if not targetId or not skillType or not amount then
        Reply("/addmechanicxp <playerID> <engine|transmission|clutch|suspension> <amount>")
        return
    end

    if not IsValidSkill(skillType) then
        Reply("Invalid skill. Use: engine, transmission, clutch, suspension")
        return
    end

    local newLevel = AddXP(targetId, skillType, amount)
    if newLevel then
        Reply(string.format("Gave %s %d %s XP (now level %d)", GetPlayerName(targetId) or tostring(targetId), amount, Config.Skills[skillType].label, newLevel))
    end
end, true) -- ACE restricted

-- ============================================================
-- Exports for other resources
-- ============================================================

exports('GetLevel', GetLevel)
exports('GetSkillData', GetSkillData)
exports('GetAllSkills', GetAllSkills)
exports('GetSkillsForDisplay', GetSkillsForDisplay)
exports('AddXP', AddXP)
exports('AddLevel', AddLevel)
exports('SetLevel', SetLevel)

print("^2[my_mechanicskills] Mechanic skills system loaded^7")
