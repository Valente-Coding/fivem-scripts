-- Mechanic Skills Client
-- Requests skill data on spawn and shows chat notifications on level up.

CreateThread(function()
    Wait(3000) -- Wait for everything to load
    TriggerServerEvent('my_mechanicskills:requestSkills')
end)

RegisterNetEvent('my_mechanicskills:receiveSkills')
AddEventHandler('my_mechanicskills:receiveSkills', function(skills)
    -- Other resources can hook this event if they want to react to the
    -- player's current skill levels on load (e.g. update a UI).
end)

RegisterNetEvent('my_mechanicskills:updateSkill')
AddEventHandler('my_mechanicskills:updateSkill', function(skillType, level, xp)
    -- Fired whenever a skill's level/xp changes, useful for UI updates.
end)

RegisterNetEvent('my_mechanicskills:levelUp')
AddEventHandler('my_mechanicskills:levelUp', function(skillType, newLevel, levelsGained)
    local label = (Config.Skills[skillType] and Config.Skills[skillType].label) or skillType
    TriggerEvent('chatMessage', "^2[Skills]^7", "", string.format("Your %s skill leveled up to %d!", label, newLevel))
end)
