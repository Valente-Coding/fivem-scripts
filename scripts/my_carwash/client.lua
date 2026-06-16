-- Car Wash Client
local washingVehicle = false
local waitingForWash = false

local ptfxData = {
    { dict = 'cut_test', name = 'exp_hydrant', offset = {0.0,0.0,4.0}, rot = {0.0, 180.0, 0.0}, scale = 0.5 },
    { dict = 'cut_test', name = 'exp_hydrant', offset = {-0.5,0.0,4.0}, rot = {0.0, 180.0, 0.0}, scale = 0.5 },
    { dict = 'cut_test', name = 'exp_hydrant', offset = {-1.0,0.0,4.0}, rot = {0.0, 180.0, 0.0}, scale = 0.5 },
    { dict = 'cut_test', name = 'exp_hydrant', offset = {-1.5,0.0,4.0}, rot = {0.0, 180.0, 0.0}, scale = 0.5 },
    { dict = 'cut_test', name = 'exp_hydrant', offset = {-2.0,0.0,4.0}, rot = {0.0, 180.0, 0.0}, scale = 0.5 },
    { dict = 'cut_test', name = 'exp_hydrant', offset = {0.5,0.0,4.0}, rot = {0.0, 180.0, 0.0}, scale = 0.5 },
    { dict = 'cut_test', name = 'exp_hydrant', offset = {1.0,0.0,4.0}, rot = {0.0, 180.0, 0.0}, scale = 0.5 },
    { dict = 'cut_test', name = 'exp_hydrant', offset = {1.5,0.0,4.0}, rot = {0.0, 180.0, 0.0}, scale = 0.5 },
    { dict = 'cut_test', name = 'exp_hydrant', offset = {2.0,0.0,4.0}, rot = {0.0, 180.0, 0.0}, scale = 0.5 },
    { dict = 'scr_fbi5a', name = 'scr_tunnel_vent_bubbles', offset = {0.0,0.0,0.0}, rot = {0.0,180.0,0.0}, scale = 2.0 },
    { dict = 'scr_fbi5a', name = 'scr_tunnel_vent_bubbles', offset = {0.0,-1.0,0.0}, rot = {0.0,180.0,0.0}, scale = 1.0 },
    { dict = 'scr_fbi5a', name = 'scr_tunnel_vent_bubbles', offset = {0.0,1.0,0.0}, rot = {0.0,180.0,0.0}, scale = 1.0 },
    { dict = 'scr_fbi5a', name = 'scr_tunnel_vent_bubbles', offset = {0.0,-2.0,0.0}, rot = {0.0,180.0,0.0}, scale = 1.0 },
    { dict = 'scr_fbi5a', name = 'scr_tunnel_vent_bubbles', offset = {0.0,2.0,0.0}, rot = {0.0,180.0,0.0}, scale = 1.0 },
}

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function ShowHelpNotification(msg)
    AddTextEntry('CarwashHelp', msg)
    DisplayHelpTextThisFrame('CarwashHelp', false)
end

local function RequestNetworkControlOfEntity(entity)
    NetworkRequestControlOfEntity(entity)
    local timeout = 2000
    while timeout > 0 and not NetworkHasControlOfEntity(entity) do
        Wait(100)
        timeout = timeout - 100
    end
    SetEntityAsMissionEntity(entity, true, true)
    timeout = 2000
    while timeout > 0 and not IsEntityAMissionEntity(entity) do
        Wait(100)
        timeout = timeout - 100
    end
end

local function RequestParticleFX(dict)
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do Wait(0) end
end

local function LoadPropDict(model)
    if not IsModelInCdimage(model) then return end
    local time = 30
    while not HasModelLoaded(model) and time > 0 do
        RequestModel(model)
        Wait(100)
        time = time - 1
    end
end

local function CreateProp(model, coords)
    if not HasModelLoaded(model) then LoadPropDict(model) end
    local prop = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityAsMissionEntity(prop, true, true)
    FreezeEntityPosition(prop, true)
    SetEntityCollision(prop, false, true)
    return prop
end

RegisterNetEvent('carwash:DoVehicleWashParticles')
AddEventHandler('carwash:DoVehicleWashParticles', function(vehNet, washer, useProps)
    if NetworkDoesEntityExistWithNetworkId(vehNet) then
        if washer == GetPlayerServerId(PlayerId()) then
            waitingForWash = true
            washer = true
        end

        local vehicle = NetworkGetEntityFromNetworkId(vehNet)
        local ptfxHandles = {}
        local sideProps = nil
        local minOffsets, maxOffsets = GetModelDimensions(GetEntityModel(vehicle))

        if useProps then
            local _, maxPropDim = GetModelDimensions(`prop_carwash_roller_vert`)
            local leftOffset = GetOffsetFromEntityInWorldCoords(vehicle, minOffsets.x, minOffsets.y, minOffsets.z - 0.5)
            leftOffset = vector3(leftOffset.x + maxPropDim.x, leftOffset.y, leftOffset.z)
            local rightOffset = GetOffsetFromEntityInWorldCoords(vehicle, maxOffsets.x, minOffsets.y, minOffsets.z - 0.5)
            rightOffset = vector3(rightOffset.x - maxPropDim.x, rightOffset.y, rightOffset.z)

            sideProps = {
                {prop = CreateProp(`prop_carwash_roller_vert`, leftOffset), offset = vector3(minOffsets.x - (maxPropDim.x - 0.2), minOffsets.y, maxPropDim.z/2)},
                {prop = CreateProp(`prop_carwash_roller_vert`, rightOffset), offset = vector3(maxOffsets.x + (maxPropDim.x - 0.2), minOffsets.y, maxPropDim.z/2)},
            }

            for i = 1, #sideProps do
                CreateThread(function()
                    while sideProps and sideProps[i] and DoesEntityExist(sideProps[i].prop) do
                        if i == 1 then
                            SetEntityHeading(sideProps[i].prop, ((GetEntityHeading(sideProps[i].prop) + 0.75) + 360) % 360)
                        elseif i == 2 then
                            SetEntityHeading(sideProps[i].prop, ((GetEntityHeading(sideProps[i].prop) - 0.75) + 360) % 360)
                        end
                        Wait(0)
                    end
                end)
            end
        end

        for _, ptfx in pairs(ptfxData) do
            RequestParticleFX(ptfx.dict)
            UseParticleFxAssetNextCall(ptfx.dict)
            local created = StartNetworkedParticleFxLoopedOnEntity(ptfx.name, vehicle, ptfx.offset[1], ptfx.offset[2], ptfx.offset[3], ptfx.rot[1], ptfx.rot[2], ptfx.rot[3], ptfx.scale, false, false, false)
            table.insert(ptfxHandles, created)
        end

        local offset = minOffsets.y
        local propOffset = minOffsets.y

        while offset < maxOffsets.y and DoesEntityExist(vehicle) do
            for i = 1, #ptfxHandles do
                SetParticleFxLoopedOffsets(ptfxHandles[i], ptfxData[i].offset[1], offset, ptfxData[i].offset[3], ptfxData[i].rot[1], ptfxData[i].rot[2], ptfxData[i].rot[3])
            end
            if sideProps then
                for i = 1, #sideProps do
                    SetEntityCoordsNoOffset(sideProps[i].prop, GetOffsetFromEntityInWorldCoords(vehicle, sideProps[i].offset.x, propOffset, sideProps[i].offset.z))
                end
                propOffset = propOffset + 0.0055
            end
            offset = offset + 0.0055
            Wait(0)
        end

        if Config.DoublClean then
            while minOffsets.y < offset and DoesEntityExist(vehicle) do
                for i = 1, #ptfxHandles do
                    SetParticleFxLoopedOffsets(ptfxHandles[i], ptfxData[i].offset[1], offset, ptfxData[i].offset[3], ptfxData[i].rot[1], ptfxData[i].rot[2], ptfxData[i].rot[3])
                end
                if sideProps then
                    for i = 1, #sideProps do
                        SetEntityCoordsNoOffset(sideProps[i].prop, GetOffsetFromEntityInWorldCoords(vehicle, sideProps[i].offset.x, propOffset, sideProps[i].offset.z))
                    end
                    propOffset = propOffset - 0.0055
                end
                offset = offset - 0.0055
                Wait(0)
            end
        end

        for i = 1, #ptfxHandles do StopParticleFxLooped(ptfxHandles[i], false) end

        if sideProps then
            for i = 1, #sideProps do DeleteEntity(sideProps[i].prop) end
            sideProps = nil
        end

        if washer == true then
            RequestNetworkControlOfEntity(vehicle)
            SetVehicleDirtLevel(vehicle, 0.0)
            WashDecalsFromVehicle(vehicle, 1.0)
            Wait(1000)
            FreezeEntityPosition(vehicle, false)
            ShowNotification('~g~Vehicle Washed!')
            waitingForWash = false
            washingVehicle = false
        end
    end
end)

local function WashVehicle(vehicle, useProps)
    if washingVehicle then return end
    washingVehicle = true
    TriggerServerEvent('my_carwash:requestWash', VehToNet(vehicle), useProps)
end

RegisterNetEvent('my_carwash:washApproved')
AddEventHandler('my_carwash:washApproved', function(vehNet, useProps)
    local vehicle = NetworkGetEntityFromNetworkId(vehNet)
    if DoesEntityExist(vehicle) then
        FreezeEntityPosition(vehicle, true)
        TriggerServerEvent('carwash:DoVehicleWashParticles', vehNet, useProps)
    else
        washingVehicle = false
    end
end)

RegisterNetEvent('my_carwash:washDenied')
AddEventHandler('my_carwash:washDenied', function()
    ShowNotification('~r~Not enough money for car wash!')
    washingVehicle = false
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) and not washingVehicle then
            local myVehicle = GetVehiclePedIsIn(playerPed)
            if GetPedInVehicleSeat(myVehicle, -1) == playerPed and
               (not Config.OnlyDirtyVehicles or GetVehicleDirtLevel(myVehicle) >= 0.1) then
                local coords = GetEntityCoords(playerPed)
                for _, carwash in pairs(Config.Locations) do
                    local dist = #(coords - carwash.location)
                    if dist <= 10.0 then
                        sleep = 100
                        if dist <= 2.0 then
                            ShowHelpNotification(string.format(Config.ButtonPrompt, Config.Cost))
                            sleep = 0
                            if IsControlJustPressed(0, 38) then
                                WashVehicle(myVehicle, carwash.useProps)
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

local function CreateCarwashBlip(coords, name)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, 100)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 2)
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    return blip
end

if Config.ShowAllBlips then
    for _, carwash in pairs(Config.Locations) do
        if carwash.showBlip then
            CreateCarwashBlip(carwash.location, carwash.name)
        end
    end
else
    CreateThread(function()
        local currentBlip = nil
        local currentBlipLocation = nil

        while true do
            local coords = GetEntityCoords(PlayerPedId())
            local closest = 999999
            local closestCoords, closestName

            for _, carwash in pairs(Config.Locations) do
                local d = #(coords.xy - carwash.location.xy)
                if d < closest and carwash.showBlip then
                    closest = d
                    closestCoords = carwash.location
                    closestName = carwash.name
                end
            end

            if currentBlipLocation ~= closestCoords then
                if DoesBlipExist(currentBlip) then RemoveBlip(currentBlip) end
                currentBlip = CreateCarwashBlip(closestCoords, closestName)
                currentBlipLocation = closestCoords
            end

            Wait(10000)
        end
    end)
end
