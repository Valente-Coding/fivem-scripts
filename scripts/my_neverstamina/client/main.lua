-- Never Deplete Stamina Script

CreateThread(function()
    while true do
        Wait(1000) -- Reduced from 100ms to 1000ms - stamina doesn't need to be restored 10 times per second
        RestorePlayerStamina(PlayerId(), 1.0)
    end
end)
