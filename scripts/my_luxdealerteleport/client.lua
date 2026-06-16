local pointA = vector3(-1224.3748, -348.3473, 36.9064)
local pointB = vector3(-1224.2129, -348.3336, 40.1600)

local triggerDistance = 5.0 -- how close the player needs to be to activate
local cooldown = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 and not cooldown then
            local distA = #(coords - pointA)
            local distB = #(coords - pointB)

            -- Use Z height to determine which level the player is on
            if coords.z < 38.0 and distA < triggerDistance then
                DrawText3D(pointA.x, pointA.y, pointA.z + 1.0, '~g~Press ~b~E ~g~to teleport up')
                if IsControlJustPressed(0, 46) then -- E key
                    cooldown = true
                    SetEntityCoords(vehicle, pointB.x, pointB.y, pointB.z, false, false, false, true)
                    Citizen.Wait(2000)
                    cooldown = false
                end
            elseif coords.z > 38.0 and distB < triggerDistance then
                DrawText3D(pointB.x, pointB.y, pointB.z + 1.0, '~g~Press ~b~E ~g~to teleport down')
                if IsControlJustPressed(0, 46) then -- E key
                    cooldown = true
                    SetEntityCoords(vehicle, pointA.x, pointA.y, pointA.z, false, false, false, true)
                    Citizen.Wait(2000)
                    cooldown = false
                end
            else
                Citizen.Wait(500)
            end
        else
            Citizen.Wait(500)
        end
    end
end)

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 100)
    ClearDrawOrigin()
end
