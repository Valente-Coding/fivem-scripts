-- Police Hide - Hides minimap when player has a wanted level
local minimapShown = true
local hasWantedLevel = false

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function ToggleMinimap(toggle)
    if toggle and not minimapShown then
        DisplayRadar(true)
        minimapShown = true
    elseif not toggle and minimapShown then
        DisplayRadar(false)
        minimapShown = false
    end
end

local function ShouldHideMinimap(wantedLevel)
    if wantedLevel == 0 then return false end
    return Config.HideAtLevel[wantedLevel] or false
end

CreateThread(function()
    while true do
        Wait(Config.CheckInterval)

        local currentWantedLevel = GetPlayerWantedLevel(PlayerId())
        local wasWanted = hasWantedLevel
        hasWantedLevel = ShouldHideMinimap(currentWantedLevel)

        if hasWantedLevel and not wasWanted then
            if Config.ShowNotifications then
                ShowNotification('~r~You are wanted! Minimap disabled.')
            end
            ToggleMinimap(false)
        elseif not hasWantedLevel and wasWanted then
            if Config.ShowNotifications then
                ShowNotification('~g~No longer wanted. Minimap restored.')
            end
            ToggleMinimap(true)
        end
    end
end)

-- Check on initial spawn
CreateThread(function()
    Wait(2000)
    local currentWantedLevel = GetPlayerWantedLevel(PlayerId())
    hasWantedLevel = ShouldHideMinimap(currentWantedLevel)
    if hasWantedLevel then
        if Config.ShowNotifications then
            ShowNotification('~r~You are wanted! Minimap disabled.')
        end
        ToggleMinimap(false)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DisplayRadar(true)
end)
