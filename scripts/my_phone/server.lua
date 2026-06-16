-- Phone Server
-- Bridges phone NUI requests to other resources' exports.

RegisterNetEvent('my_phone:requestMechanicSkills')
AddEventHandler('my_phone:requestMechanicSkills', function()
    local _source = source
    local skills = exports['my_mechanicskills']:GetSkillsForDisplay(_source)
    TriggerClientEvent('my_phone:receiveMechanicSkills', _source, skills)
end)
