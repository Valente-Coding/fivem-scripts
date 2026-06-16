-- lbg-char-master Server
-- Handles character data persistence via my_datamanager

-- Save character appearance to saved_data
RegisterNetEvent('lbgchar:saveCharacter')
AddEventHandler('lbgchar:saveCharacter', function(characterData)
    local source = source
    if not characterData or type(characterData) ~= "table" then
        TriggerClientEvent('lbgchar:saveComplete', source, false)
        return
    end

    -- Preserve original creation date if updating an existing character
    local existingData = exports['my_datamanager']:GetPlayerDataKey(source, 'character')
    local dateCreated = os.date("!%Y-%m-%dT%H:%M:%SZ")
    if existingData and existingData.date_created then
        dateCreated = existingData.date_created
    end

    local saveData = {
        appearance = characterData,
        date_created = dateCreated,
        last_used = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        version = 1
    }

    local success = exports['my_datamanager']:SetPlayerDataKey(source, 'character', saveData)
    TriggerClientEvent('lbgchar:saveComplete', source, success)

    if success then
        print("^2[lbg-char] Character saved for player " .. source .. "^7")
    else
        print("^1[lbg-char] Failed to save character for player " .. source .. "^7")
    end
end)

-- Client requests their saved character on spawn
RegisterNetEvent('lbgchar:requestCharacter')
AddEventHandler('lbgchar:requestCharacter', function()
    local source = source
    local savedData = exports['my_datamanager']:GetPlayerDataKey(source, 'character')

    if savedData and savedData.appearance then
        -- Update last_used timestamp
        savedData.last_used = os.date("!%Y-%m-%dT%H:%M:%SZ")
        exports['my_datamanager']:SetPlayerDataKey(source, 'character', savedData)

        TriggerClientEvent('lbgchar:loadCharacter', source, savedData.appearance)
        print("^2[lbg-char] Loaded character for player " .. source .. "^7")
    else
        TriggerClientEvent('lbgchar:noCharacter', source)
        print("^3[lbg-char] No character found for player " .. source .. ", opening creator^7")
    end
end)

print("^2[lbg-char] Character creator server loaded^7")
