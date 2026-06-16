-- Vehicle HUD (NUI-based)
-- Sends speed, engine health, body health, and mileage to the HTML UI

local isShowing = false

Citizen.CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            sleep = 100

            if not isShowing then
                isShowing = true
                SendNUIMessage({ type = 'show' })
            end

            local speed    = math.floor(GetEntitySpeed(vehicle) * 3.6)
            local engineHP = math.floor((math.max(GetVehicleEngineHealth(vehicle), 0) / 1000) * 100)
            local bodyHP   = math.floor((math.max(GetVehicleBodyHealth(vehicle), 0) / 1000) * 100)

            -- Mileage (from my_vehicles export if available)
            local mileage = 0
            local plate = string.upper(string.gsub(GetVehicleNumberPlateText(vehicle), '%s+', ''))
            local mileageOk, mileageVal = pcall(function()
                return exports['my_vehicles']:GetVehicleMileage(plate)
            end)
            if mileageOk and mileageVal then
                mileage = mileageVal
            end

            -- Oil level (from my_vehicles export if available)
            local oilLevel = 100
            local oilOk, oilVal = pcall(function()
                return exports['my_vehicles']:GetVehicleOilLevel(plate)
            end)
            if oilOk and oilVal then
                oilLevel = math.floor(oilVal)
            end

            SendNUIMessage({
                type    = 'update',
                speed   = speed,
                health  = engineHP,
                body    = bodyHP,
                mileage = mileage,
                oil     = oilLevel
            })
        else
            if isShowing then
                isShowing = false
                SendNUIMessage({ type = 'hide' })
            end
        end

        Citizen.Wait(sleep)
    end
end)
