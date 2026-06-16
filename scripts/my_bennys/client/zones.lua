-- Single-location zone system for Benny's Motorworks
-- Uses distance check to Config.Location instead of ox_lib poly zones

local textUiTitle = 'Press ~INPUT_PICKUP~ to customize your vehicle'
local inZone = false
local textShown = false

-- Create blip at Benny's location
CreateThread(function()
    local loc = Config.Location
    local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipSprite(blip, 72)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.BlipLabel or "Benny's Motorworks")
    EndTextCommandSetBlipName(blip)
end)

-- Main interaction thread
CreateThread(function()
    local loc = Config.Location
    local dist_threshold = Config.InteractionDistance or 15.0

    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - loc)

        if dist < dist_threshold then
            -- Player is near Benny's
            if not inZone then
                inZone = true
            end

            -- Show/hide text based on vehicle state
            if cache.vehicle then
                if not textShown then
                    lib.showTextUI(textUiTitle)
                    textShown = true
                end

                -- Press E to open customization menu
                if IsControlJustPressed(0, 38) then
                    SetEntityVelocity(cache.vehicle, 0.0, 0.0, 0.0)
                    lib.hideTextUI()
                    textShown = false
                    require('client.menus.main')()
                end
            else
                if textShown then
                    lib.hideTextUI()
                    textShown = false
                end
            end

            Wait(0)
        elseif dist < 100.0 then
            if inZone then
                inZone = false
                if textShown then
                    lib.hideTextUI()
                    textShown = false
                end
            end
            Wait(500)
        else
            if inZone then
                inZone = false
                if textShown then
                    lib.hideTextUI()
                    textShown = false
                end
            end
            Wait(2000)
        end
    end
end)

-- React to vehicle state changes
lib.onCache("vehicle", function(veh)
    if not inZone then return end
    if veh then
        if not textShown then
            lib.showTextUI(textUiTitle)
            textShown = true
        end
    else
        if textShown then
            lib.hideTextUI()
            textShown = false
        end
    end
end)

-- Save vehicle properties on resource stop (server restart while in menu)
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- If the player is actively in the Benny's menu, save the vehicle's current properties
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        if plate and plate ~= '' then
            local vehiclePropsModule = require('client.utils.vehicleProps')
            local props = vehiclePropsModule.GetAllVehicleProperties(vehicle)
            TriggerServerEvent('my_bennys:server:saveVehicleProps', plate, props)
        end
    end
end)
