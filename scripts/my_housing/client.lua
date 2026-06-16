-- Housing System Client (merged main.lua + ui.lua)
-- No ESX dependency - uses my_money, my_datamanager

local Houses = {}
local CurrentHouse = nil
local UIActive = false
local BlipsInitialized = false
local myLicense = nil

-- Notification helper
local function ShowNotification(message)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, true)
end

-- Help text helper
local function ShowHelpNotification(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- Format number with commas
local function FormatNumber(amount)
    local formatted = tostring(math.floor(amount))
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Round to tens
local function RoundToTens(value)
    return math.floor((value + 5) / 10) * 10
end

-- Initialize
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('my_housing:requestHouses')
    StartMainThread()
end)

-- Receive houses from server
RegisterNetEvent('my_housing:receiveHouses')
AddEventHandler('my_housing:receiveHouses', function(houses, license)
    -- Preserve existing blip references before updating
    local oldBlips = {}
    for _, oldHouse in pairs(Houses) do
        if oldHouse.blip then
            oldBlips[oldHouse.id] = oldHouse.blip
        end
    end

    Houses = houses or {}

    -- Restore blip references
    for _, house in pairs(Houses) do
        if oldBlips[house.id] then
            house.blip = oldBlips[house.id]
        end
    end

    if license then
        myLicense = license
    end

    if BlipsInitialized then
        RefreshBlips()
    else
        CreateBlips()
        BlipsInitialized = true
    end
end)

-- Create blips for all houses
function CreateBlips()
    for _, house in pairs(Houses) do
        -- Skip if blip already exists
        if house.blip and DoesBlipExist(house.blip) then
            goto continue
        end

        local blipColor, blipSprite, blipScale, blipDisplay, blipShortRange, blipText

        if house.owner and myLicense and house.owner == myLicense then
            -- Player owns this house
            if house.rented == 1 or house.rented == true then
                -- Rented out - YELLOW
                blipColor = Config.RentedHouseBlip.color
                blipSprite = Config.RentedHouseBlip.sprite
                blipScale = Config.RentedHouseBlip.scale
                blipDisplay = Config.RentedHouseBlip.display
                blipShortRange = Config.RentedHouseBlip.shortRange
                blipText = "House For Rent"
            else
                -- Not rented - GREEN
                blipColor = Config.OwnedHouseBlip.color
                blipSprite = Config.OwnedHouseBlip.sprite
                blipScale = Config.OwnedHouseBlip.scale
                blipDisplay = Config.OwnedHouseBlip.display
                blipShortRange = Config.OwnedHouseBlip.shortRange
                blipText = "House Owned"
            end
        elseif house.owner and house.owner ~= myLicense then
            -- Someone else owns it - RED
            blipColor = Config.NotOwnedHouseBlip.color
            blipSprite = Config.NotOwnedHouseBlip.sprite
            blipScale = Config.NotOwnedHouseBlip.scale
            blipDisplay = Config.NotOwnedHouseBlip.display
            blipShortRange = Config.NotOwnedHouseBlip.shortRange
            blipText = "House Not Available"
        else
            -- No owner - WHITE with price
            blipColor = Config.HouseBlip.color
            blipSprite = Config.HouseBlip.sprite
            blipScale = Config.HouseBlip.scale
            blipDisplay = Config.HouseBlip.display
            blipShortRange = Config.HouseBlip.shortRange
            local formattedPrice = string.format("$%s", FormatNumber(house.market_value or house.price))
            blipText = "House For Sale - " .. formattedPrice
        end

        local blip = AddBlipForCoord(house.coords.x, house.coords.y, house.coords.z)
        SetBlipSprite(blip, blipSprite)
        SetBlipDisplay(blip, blipDisplay)
        SetBlipScale(blip, blipScale)
        SetBlipColour(blip, blipColor)
        SetBlipAsShortRange(blip, blipShortRange)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(blipText)
        EndTextCommandSetBlipName(blip)

        house.blip = blip

        ::continue::
    end
end

-- Refresh all blips
function RefreshBlips()
    for _, house in pairs(Houses) do
        if house.blip then
            if DoesBlipExist(house.blip) then
                RemoveBlip(house.blip)
            end
            house.blip = nil
        end
    end

    Wait(0)
    CreateBlips()
end

-- Main proximity/interaction thread
function StartMainThread()
    CreateThread(function()
        local lastCoords = vector3(0, 0, 0)
        local lastCheck = 0
        local nearbyHouses = {}

        while true do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local currentTime = GetGameTimer()
            local sleep = 500
            local closestHouse = nil
            local closestDistance = 1000.0

            CurrentHouse = nil

            -- Only recalculate nearby houses if player moved significantly or time elapsed
            local distanceMoved = #(playerCoords - lastCoords)
            if distanceMoved > Config.Performance.MovementThreshold or (currentTime - lastCheck) > Config.Performance.DistanceCheckInterval then
                lastCoords = playerCoords
                lastCheck = currentTime
                nearbyHouses = {}

                for _, house in pairs(Houses) do
                    local distance = #(playerCoords - vector3(house.coords.x, house.coords.y, house.coords.z))
                    if distance < Config.Performance.MaxProcessDistance then
                        nearbyHouses[#nearbyHouses + 1] = {house = house, distance = distance}
                    end
                end
            end

            -- Draw markers and check interactions for nearby houses
            for _, houseData in ipairs(nearbyHouses) do
                local house = houseData.house
                local distance = #(playerCoords - vector3(house.coords.x, house.coords.y, house.coords.z))

                if distance < 20.0 then
                    sleep = 0
                    DrawMarker(1, house.coords.x, house.coords.y, house.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.5, 0, 127, 255, 100, false, true, 2, false, nil, nil, false)
                end

                if distance < closestDistance and distance < 1.5 then
                    closestDistance = distance
                    closestHouse = house
                end
            end

            -- Handle interaction with closest house
            if closestHouse then
                sleep = 0
                CurrentHouse = closestHouse

                if closestHouse.owner and myLicense and closestHouse.owner == myLicense then
                    ShowHelpNotification("Press ~INPUT_CONTEXT~ to manage your property")
                elseif not closestHouse.owner then
                    ShowHelpNotification("Press ~INPUT_CONTEXT~ to purchase this property")
                else
                    ShowHelpNotification("This property is unavailable")
                end

                if IsControlJustReleased(0, 38) then
                    OpenHouseMenu(closestHouse)
                end
            end

            Wait(sleep)
        end
    end)
end

-- Key press handler for UI
CreateThread(function()
    while true do
        if UIActive then
            Wait(0)

            if IsControlJustReleased(0, 177) then -- Backspace
                CloseHousingUI()
            end

            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 106, true)
        else
            Wait(100)
        end
    end
end)

-- Open house menu
function OpenHouseMenu(house)
    OpenHousingUI(house)
end

-- Open housing UI
function OpenHousingUI(house)
    UIActive = true

    local isOwner = house.owner and myLicense and house.owner == myLicense
    local isAvailableForPurchase = not house.owner
    local isAvailableForRent = house.owner and house.rented ~= 1
    local canAccessStorage = isOwner and (house.rented == 0 or house.rented == false)

    local rentPrice = RoundToTens(house.price * Config.RentMultiplier)
    local valueHistory = json.encode(house.value_history or {house.market_value})

    SendNUIMessage({
        type = 'open',
        house = {
            id = house.id,
            name = house.name,
            label = house.label,
            price = house.market_value,
            basePrice = house.price,
            owner = house.owner_name,
            isRented = house.rented,
            totalEarnings = house.total_earnings or 0,
            rentPrice = rentPrice,
            valueHistory = valueHistory
        },
        player = {
            isOwner = isOwner,
            canBuy = isAvailableForPurchase,
            canRent = isAvailableForRent,
            canAccessStorage = canAccessStorage
        }
    })

    SetNuiFocus(true, true)

    -- If owner with storage access, request storage data
    if canAccessStorage then
        TriggerServerEvent('my_housing:requestStorage', house.id)
    end
end

-- Close housing UI
function CloseHousingUI()
    UIActive = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
end

-- NUI Callbacks
RegisterNUICallback('buyHouse', function(data, cb)
    TriggerServerEvent('my_housing:buyHouse', data.houseId)
    cb('ok')
end)

RegisterNUICallback('sellHouse', function(data, cb)
    TriggerServerEvent('my_housing:sellHouse', data.houseId)
    cb('ok')
end)

RegisterNUICallback('toggleRent', function(data, cb)
    TriggerServerEvent('my_housing:toggleRent', data.houseId, data.rentStatus)
    cb('ok')
end)

RegisterNUICallback('rentHouse', function(data, cb)
    TriggerServerEvent('my_housing:rentHouse', data.houseId)
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    CloseHousingUI()
    cb('ok')
end)

-- Rest at house (energy replenishment)
RegisterNUICallback('restAtHouse', function(data, cb)
    if not data.houseId then cb('ok') return end

    -- Close UI and fade to black
    CloseHousingUI()
    DoScreenFadeOut(Config.Rest.FadeDuration)

    -- Wait until screen is fully black, then request rest from server
    CreateThread(function()
        while not IsScreenFadedOut() do
            Wait(10)
        end
        TriggerServerEvent('my_housing:requestRest', data.houseId)
    end)

    cb('ok')
end)

-- Storage NUI Callbacks
RegisterNUICallback('depositItem', function(data, cb)
    TriggerServerEvent('my_housing:depositItem', data.houseId, data.itemName, data.amount)
    cb('ok')
end)

RegisterNUICallback('withdrawItem', function(data, cb)
    TriggerServerEvent('my_housing:withdrawItem', data.houseId, data.itemName, data.amount)
    cb('ok')
end)

RegisterNUICallback('depositMoney', function(data, cb)
    TriggerServerEvent('my_housing:depositMoney', data.houseId, data.moneyType, data.amount)
    cb('ok')
end)

RegisterNUICallback('withdrawMoney', function(data, cb)
    TriggerServerEvent('my_housing:withdrawMoney', data.houseId, data.moneyType, data.amount)
    cb('ok')
end)

-- Receive house storage data from server
RegisterNetEvent('my_housing:receiveStorage')
AddEventHandler('my_housing:receiveStorage', function(storageData)
    if UIActive then
        SendNUIMessage({
            type = 'updateStorage',
            storage = storageData
        })
    end
end)

-- Storage error
RegisterNetEvent('my_housing:storageError')
AddEventHandler('my_housing:storageError', function(message)
    ShowNotification('~r~' .. message)
    if UIActive then
        SendNUIMessage({ type = 'storageError', message = message })
    end
end)

-- Server result events
RegisterNetEvent('my_housing:buyResult')
AddEventHandler('my_housing:buyResult', function(success, message)
    if success then
        CloseHousingUI()
    else
        SendNUIMessage({ type = 'error', message = message })
    end
end)

RegisterNetEvent('my_housing:sellResult')
AddEventHandler('my_housing:sellResult', function(success, message)
    if success then
        CloseHousingUI()
    else
        SendNUIMessage({ type = 'error', message = message })
    end
end)

RegisterNetEvent('my_housing:toggleRentResult')
AddEventHandler('my_housing:toggleRentResult', function(success, message)
    if not success then
        SendNUIMessage({ type = 'toggleRentError', message = message })
    end
end)

RegisterNetEvent('my_housing:rentResult')
AddEventHandler('my_housing:rentResult', function(success, message)
    if success then
        CloseHousingUI()
    else
        SendNUIMessage({ type = 'error', message = message })
    end
end)

-- Rest success
RegisterNetEvent('my_housing:restSuccess')
AddEventHandler('my_housing:restSuccess', function(houseName)
    -- Set random weather while screen is still black
    local weatherList = Config.Rest.WeatherTypes
    local randomWeather = weatherList[math.random(#weatherList)]
    SetWeatherTypeNowPersist(randomWeather)

    Wait(500)

    -- Fade back in
    DoScreenFadeIn(Config.Rest.FadeDuration)

    -- Notification
    SetNotificationTextEntry('STRING')
    AddTextComponentString('~g~Feeling refreshed! You rested at ~y~' .. houseName .. '~g~. It\'s now 8:00 AM.')
    DrawNotification(false, false)
end)

-- Rest failure
RegisterNetEvent('my_housing:restFailure')
AddEventHandler('my_housing:restFailure', function(errorMessage)
    -- Fade back in if screen was blacked out
    if IsScreenFadedOut() then
        DoScreenFadeIn(Config.Rest.FadeDuration)
    end

    SetNotificationTextEntry('STRING')
    AddTextComponentString('~r~' .. (errorMessage or 'Could not rest here.'))
    DrawNotification(false, false)
end)

-- Server notification
RegisterNetEvent('my_housing:notify')
AddEventHandler('my_housing:notify', function(message)
    ShowNotification(Config.Notifications.prefix .. message)
end)

-- Rent collection notification (matches warehouse job completion style)
RegisterNetEvent('my_housing:rentNotification')
AddEventHandler('my_housing:rentNotification', function(amount)
    ShowNotification("~g~Rent collected! Earned $" .. amount)
end)

-- ============================================================
-- Clear stationary NPCs and parked NPC vehicles around owned
-- non-rented houses (20m radius)
-- ============================================================
local CLEAR_RADIUS = 20.0

CreateThread(function()
    while true do
        Wait(4000) -- check every 4 seconds

        if not myLicense or not Houses then
            goto skipClear
        end

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        -- Collect owned, non-rented house coords near the player
        local activeHouseCoords = {}
        for _, house in pairs(Houses) do
            if house.owner and house.owner == myLicense
               and (house.rented == 0 or house.rented == false or house.rented == nil) then
                local houseVec = vector3(house.coords.x, house.coords.y, house.coords.z)
                -- Only bother if player is within 100m (optimisation)
                if #(playerCoords - houseVec) < 100.0 then
                    activeHouseCoords[#activeHouseCoords + 1] = houseVec
                end
            end
        end

        if #activeHouseCoords == 0 then
            goto skipClear
        end

        -- Helper: is a coord inside the clear zone of any active house?
        local function IsInClearZone(coords)
            for _, hc in ipairs(activeHouseCoords) do
                if #(coords - hc) <= CLEAR_RADIUS then
                    return true
                end
            end
            return false
        end

        -- 1) Remove stationary NPCs
        local allPeds = GetGamePool('CPed')
        for _, ped in ipairs(allPeds) do
            if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
                local pedCoords = GetEntityCoords(ped)
                if IsInClearZone(pedCoords) then
                    local speed = GetEntitySpeed(ped)
                    -- Stationary = essentially not moving (speed < 0.5 m/s)
                    if speed < 0.5 then
                        SetEntityAsMissionEntity(ped, true, true)
                        DeleteEntity(ped)
                    end
                end
            end
        end

        -- 2) Remove parked NPC vehicles (stopped, no player inside, not player-owned)
        local allVehicles = GetGamePool('CVehicle')
        for _, vehicle in ipairs(allVehicles) do
            if DoesEntityExist(vehicle) and IsVehicleStopped(vehicle) then
                local vehCoords = GetEntityCoords(vehicle)
                if IsInClearZone(vehCoords) then
                    -- Skip vehicles registered in my_vehicles (player-owned persistent cars)
                    local plateRaw = GetVehicleNumberPlateText(vehicle)
                    if plateRaw then
                        local plate = string.upper(string.gsub(tostring(plateRaw), '%s+', ''))
                        if exports['my_vehicles']:DoesPlateExist(plate) then
                            goto nextVeh
                        end
                    end

                    -- Make sure no player is sitting in the vehicle
                    local hasPlayer = false
                    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
                        local seatPed = GetPedInVehicleSeat(vehicle, seat)
                        if seatPed ~= 0 and IsPedAPlayer(seatPed) then
                            hasPlayer = true
                            break
                        end
                    end

                    if not hasPlayer then
                        SetEntityAsMissionEntity(vehicle, true, true)
                        DeleteEntity(vehicle)
                    end

                    ::nextVeh::
                end
            end
        end

        -- 3) Suppress vehicle generators so parked cars don't respawn
        for _, hc in ipairs(activeHouseCoords) do
            RemoveVehiclesFromGeneratorsInArea(
                hc.x - CLEAR_RADIUS, hc.y - CLEAR_RADIUS, hc.z - CLEAR_RADIUS,
                hc.x + CLEAR_RADIUS, hc.y + CLEAR_RADIUS, hc.z + CLEAR_RADIUS,
                0
            )
        end

        ::skipClear::
    end
end)

-- Scenario-ped suppression frame loop (prevents new standing/sitting NPCs from spawning)
CreateThread(function()
    while true do
        if myLicense and Houses then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local nearOwnedHouse = false

            for _, house in pairs(Houses) do
                if house.owner and house.owner == myLicense
                   and (house.rented == 0 or house.rented == false or house.rented == nil) then
                    local houseVec = vector3(house.coords.x, house.coords.y, house.coords.z)
                    if #(playerCoords - houseVec) <= CLEAR_RADIUS + 10.0 then
                        nearOwnedHouse = true
                        break
                    end
                end
            end

            if nearOwnedHouse then
                -- Suppress scenario peds/vehicles this frame so they don't keep spawning
                SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
                SetVehicleDensityMultiplierThisFrame(0.0)
                SetParkedVehicleDensityMultiplierThisFrame(0.0)
                SetRandomVehicleDensityMultiplierThisFrame(0.0)
                Wait(0) -- must run every frame for the multipliers to take effect
            else
                Wait(500)
            end
        else
            Wait(1000)
        end
    end
end)

-- Blip refresh command
RegisterCommand('refreshhouseblips', function()
    RefreshBlips()
end, false)
