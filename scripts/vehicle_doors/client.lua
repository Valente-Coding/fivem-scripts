-- Define FiveM globals for the linter
---@type fun(name: string, callback: fun(source: any, args: table), restricted?: boolean): void
RegisterCommand = RegisterCommand

---@type fun(): number
PlayerPedId = PlayerPedId

---@type fun(ped: number, lastVehicle?: boolean): number
GetVehiclePedIsIn = GetVehiclePedIsIn

---@type fun(entity: number): boolean
DoesEntityExist = DoesEntityExist

---@type fun(entity: number): boolean
IsEntityAVehicle = IsEntityAVehicle

---@type fun(vehicle: number, doorIndex: number, loose?: boolean, openInstantly?: boolean): void
SetVehicleDoorOpen = SetVehicleDoorOpen

---@type fun(vehicle: number, doorIndex: number, closeInstantly?: boolean): void
SetVehicleDoorShut = SetVehicleDoorShut

RegisterCommand('opendoor', function(source, args)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
        -- 0 - Front Left Door
        -- 1 - Front Right Door
        -- 2 - Back Left Door
        -- 3 - Back Right Door
        -- 4 - Hood
        -- 5 - Trunk

        local doorIndex = tonumber(args[1])
        if doorIndex and (doorIndex >= 0 and doorIndex <= 5) then
            SetVehicleDoorOpen(vehicle, doorIndex, false, false)
            print("Vehicle door " .. doorIndex .. " opened.")
        else
            print("Invalid door index. Use a number between 0 and 5.")
        end
    else
        print("You are not in a vehicle.")
    end
end, false)

RegisterCommand('closedoor', function(source, args)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
        local doorIndex = tonumber(args[1])
        if doorIndex and (doorIndex >= 0 and doorIndex <= 5) then
            SetVehicleDoorShut(vehicle, doorIndex, false)
            print("Vehicle door " .. doorIndex .. " closed.")
        else
            print("Invalid door index. Use a number between 0 and 5.")
        end
    else
        print("You are not in a vehicle.")
    end
end, false)