-- Phone Client
local isPhoneOpen = false

-- ========================================
-- HELPERS
-- ========================================

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

-- ========================================
-- OPEN / CLOSE
-- ========================================

local function OpenPhone()
    if isPhoneOpen then return end
    if IsEntityDead(PlayerPedId()) then return end

    isPhoneOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end

local function ClosePhone()
    if not isPhoneOpen then return end
    isPhoneOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ========================================
-- KEY LISTENER  (N = control 249)
-- ========================================

CreateThread(function()
    while true do
        Wait(0)
        -- N key (default INPUT_PUSH_TO_TALK = 249)
        if IsControlJustPressed(0, Config.OpenKey) then
            if isPhoneOpen then
                ClosePhone()
            else
                OpenPhone()
            end
        end
    end
end)

-- ========================================
-- NUI CALLBACKS
-- ========================================

RegisterNUICallback('closePhone', function(_, cb)
    ClosePhone()
    cb('ok')
end)

RegisterNUICallback('appClick', function(data, cb)
    local app = data.app

    -- Skills are shown inside the phone itself, so don't close it
    if app == 'skills' then
        TriggerServerEvent('my_phone:requestMechanicSkills')
        cb('ok')
        return
    end

    ClosePhone()

    -- Small delay so the phone closes before the next menu opens
    Citizen.SetTimeout(300, function()
        if app == 'inventory' then
            -- Triggers server to send inventory data, which opens the NUI
            TriggerServerEvent('my_inventory:requestData')

        elseif app == 'business' then
            ExecuteCommand('mybusinesses')

        elseif app == 'taxi' then
            ExecuteCommand('taxi')

        elseif app == 'usedcars' then
            ExecuteCommand('usedcars')

        elseif app == 'stocks' then
            ExecuteCommand('stocks')

        elseif app == 'racing' then
            TriggerEvent('my_racing:openMenu')
        end
    end)

    cb('ok')
end)

-- ========================================
-- MECHANIC SKILLS
-- ========================================

RegisterNetEvent('my_phone:receiveMechanicSkills')
AddEventHandler('my_phone:receiveMechanicSkills', function(skills)
    SendNUIMessage({ action = 'showSkills', skills = skills })
end)

-- ========================================
-- COMMAND FALLBACK
-- ========================================

RegisterCommand('phone', function()
    if isPhoneOpen then
        ClosePhone()
    else
        OpenPhone()
    end
end, false)

-- ========================================
-- CLEANUP
-- ========================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isPhoneOpen then ClosePhone() end
    end
end)
