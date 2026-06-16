-- Example server-side script
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- Wait for 5 seconds
        print("Server script is running")
    end
end)