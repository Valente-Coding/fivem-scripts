-- Garage Block - Prevents garage doors from opening when player has a wanted level
local disabledDoors = {}

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function HasWantedLevel()
    return GetPlayerWantedLevel(PlayerId()) > 0
end

local function HandleDoorControl(doorConfig)
    local doorHash = doorConfig.hash
    local doorCoords = doorConfig.coords
    local playerCoords = GetEntityCoords(PlayerPedId())

    if #(playerCoords - doorCoords) <= Config.CheckDistance then
        if HasWantedLevel() then
            local door = GetClosestObjectOfType(
                doorCoords.x, doorCoords.y, doorCoords.z,
                10.0, doorHash, false, false, false
            )

            if door and DoesEntityExist(door) then
                if not disabledDoors[door] then
                    FreezeEntityPosition(door, true)
                    disabledDoors[door] = true
                    ShowNotification(Config.NotificationMessage)
                end
            end
        else
            local door = GetClosestObjectOfType(
                doorCoords.x, doorCoords.y, doorCoords.z,
                10.0, doorHash, false, false, false
            )

            if door and disabledDoors[door] then
                FreezeEntityPosition(door, false)
                disabledDoors[door] = nil
            end
        end
    end
end

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local isNearDoor = false

        for _, door in pairs(Config.GarageDoors) do
            if #(playerCoords - door.coords) <= Config.CheckDistance then
                isNearDoor = true
                HandleDoorControl(door)
            end
        end

        if isNearDoor then
            Wait(500)
        else
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for door, _ in pairs(disabledDoors) do
        if DoesEntityExist(door) then
            FreezeEntityPosition(door, false)
        end
    end
end)
