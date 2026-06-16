-- Drug Selling Client
local isSelling = false
local hasDrugs = false
local sellingBlips = {}
local customers = {}
local activeCustomers = 0
local saleInProgress = false
local currentSellingLocation = nil
local waitingForCustomerCleanup = false
local lastSpawnPointIndex = 0

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function DisplayHelpText(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

local function CheckPlayerDrugs()
    TriggerServerEvent('my_drugselling:checkDrugs')
end

local function CreateSellingBlips()
    for _, blip in ipairs(sellingBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    sellingBlips = {}

    for _, location in ipairs(Config.SellingLocations) do
        local blip = AddBlipForCoord(location.sellSpot.x, location.sellSpot.y, location.sellSpot.z)
        SetBlipSprite(blip, Config.BlipSprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.BlipScale)
        SetBlipColour(blip, Config.BlipColor)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Drug Selling Spot")
        EndTextCommandSetBlipName(blip)
        table.insert(sellingBlips, blip)
    end
end

local function RemoveAllBlips()
    for _, blip in ipairs(sellingBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    sellingBlips = {}
end

RegisterNetEvent('my_drugselling:drugCheckResult')
AddEventHandler('my_drugselling:drugCheckResult', function(hasDrugsResult)
    hasDrugs = hasDrugsResult
    if hasDrugs and #sellingBlips == 0 then
        CreateSellingBlips()
    elseif not hasDrugs and #sellingBlips > 0 then
        RemoveAllBlips()
    end
end)

local function StartSelling(locationIndex)
    if isSelling then return end
    activeCustomers = 0
    waitingForCustomerCleanup = false
    saleInProgress = false
    for _, customer in pairs(customers) do
        if customer and DoesEntityExist(customer.ped) then DeleteEntity(customer.ped) end
    end
    customers = {}
    isSelling = true
    currentSellingLocation = locationIndex
    ShowNotification("~g~Started selling drugs.")
    Wait(500)
    SpawnCustomer()
end

local function StopSelling(noMoreDrugs)
    if not isSelling then return end
    isSelling = false

    for _, customer in pairs(customers) do
        if customer and DoesEntityExist(customer.ped) then
            customer.state = "returning"
            LeaveArea(customer.ped, customer.spawnPoint)
        end
    end

    if noMoreDrugs then
        ShowNotification("~y~Out of drugs to sell.")
        RemoveAllBlips()
        SetTimeout(15000, function()
            activeCustomers = 0
            waitingForCustomerCleanup = false
            customers = {}
        end)
    else
        ShowNotification("~y~Stopped selling drugs.")
    end
    currentSellingLocation = nil
end

function SpawnCustomer()
    if activeCustomers > 0 or waitingForCustomerCleanup then return end
    saleInProgress = false

    local spawnPoints = Config.SellingLocations[currentSellingLocation].customerSpawns
    local spawnIndex
    repeat
        spawnIndex = math.random(#spawnPoints)
    until spawnIndex ~= lastSpawnPointIndex or #spawnPoints <= 1
    lastSpawnPointIndex = spawnIndex

    local spawnPoint = spawnPoints[spawnIndex]
    local modelName = Config.CustomerModels[math.random(#Config.CustomerModels)]
    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(10) end

    local ped = CreatePed(4, modelHash, spawnPoint.x, spawnPoint.y, spawnPoint.z - 1.0, spawnPoint.w, false, true)
    if DoesEntityExist(ped) then
        SetPedRandomComponentVariation(ped, 0)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetEntityInvincible(ped, false)
        local customerId = #customers + 1
        customers[customerId] = { ped = ped, state = "approaching", spawnPoint = spawnPoint }
        activeCustomers = activeCustomers + 1
        ApproachPlayer(ped, customerId)
    end
    SetModelAsNoLongerNeeded(modelHash)
end

function ApproachPlayer(ped, customerId)
    CreateThread(function()
        while true do
            Wait(500)
            if not customers[customerId] or not DoesEntityExist(customers[customerId].ped) then break end
            if customers[customerId].state ~= "approaching" then break end
            if not isSelling then
                customers[customerId].state = "returning"
                LeaveArea(customers[customerId].ped, customers[customerId].spawnPoint)
                break
            end

            local playerPos = GetEntityCoords(PlayerPedId())
            local customerPos = GetEntityCoords(customers[customerId].ped)
            local distance = #(playerPos - customerPos)

            if distance > 3.0 then
                TaskGoToCoordAnyMeans(ped, playerPos.x, playerPos.y, playerPos.z, 1.0, 0, false, 786603, 0)
            end

            if distance < 2.0 and not saleInProgress and isSelling then
                saleInProgress = true
                customers[customerId].state = "buying"
                TriggerServerEvent('my_drugselling:sellDrug')
                -- Play deal animation
                local playerPed = PlayerPedId()
                RequestAnimDict("mp_common")
                while not HasAnimDictLoaded("mp_common") do Wait(10) end
                TaskPlayAnim(playerPed, "mp_common", "givetake1_a", 8.0, -8.0, -1, 0, 0, false, false, false)
                TaskPlayAnim(ped, "mp_common", "givetake1_a", 8.0, -8.0, -1, 0, 0, false, false, false)
                break
            elseif distance > 20.0 then
                customers[customerId].state = "returning"
                LeaveArea(customers[customerId].ped, customers[customerId].spawnPoint)
                break
            end
        end
    end)
end

function LeaveArea(ped, spawnPoint)
    if not DoesEntityExist(ped) then
        activeCustomers = math.max(0, activeCustomers - 1)
        waitingForCustomerCleanup = false
        if isSelling and activeCustomers == 0 then Wait(Config.CustomerSpawnInterval); SpawnCustomer() end
        return
    end

    waitingForCustomerCleanup = true
    TaskGoToCoordAnyMeans(ped, spawnPoint.x, spawnPoint.y, spawnPoint.z, 1.0, 0, false, 786603, 0)

    CreateThread(function()
        local timeout = 0
        while true do
            Wait(500)
            timeout = timeout + 500
            if not DoesEntityExist(ped) then
                activeCustomers = math.max(0, activeCustomers - 1)
                waitingForCustomerCleanup = false
                if isSelling and activeCustomers == 0 then Wait(Config.CustomerSpawnInterval); SpawnCustomer() end
                break
            end
            local pedPos = GetEntityCoords(ped)
            if #(pedPos - vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z)) < 1.5 or timeout > 30000 then
                DeleteEntity(ped)
                activeCustomers = math.max(0, activeCustomers - 1)
                waitingForCustomerCleanup = false
                if isSelling and activeCustomers == 0 then Wait(Config.CustomerSpawnInterval); SpawnCustomer() end
                break
            end
        end
    end)
end

RegisterNetEvent('my_drugselling:saleComplete')
AddEventHandler('my_drugselling:saleComplete', function(data)
    local buyingCustomerId = nil
    for id, customer in pairs(customers) do
        if customer.state == "buying" and DoesEntityExist(customer.ped) then buyingCustomerId = id; break end
    end

    Wait(1000)

    if data.policeAlerted then
        SetPlayerWantedLevel(PlayerId(), data.wantedLevel or 1, false)
        SetPlayerWantedLevelNow(PlayerId(), false)
        ShowNotification("~r~Someone reported your dealing to the police!")
        if buyingCustomerId and customers[buyingCustomerId] then
            customers[buyingCustomerId].state = "returning"
            LeaveArea(customers[buyingCustomerId].ped, customers[buyingCustomerId].spawnPoint)
        end
        StopSelling(false)
        Wait(1000)
        CheckPlayerDrugs()
        return
    end

    if buyingCustomerId and customers[buyingCustomerId] then
        customers[buyingCustomerId].state = "returning"
        LeaveArea(customers[buyingCustomerId].ped, customers[buyingCustomerId].spawnPoint)
    end

    saleInProgress = false

    if not data.hasDrugsLeft then
        hasDrugs = false
        StopSelling(true)
    end

    Wait(1000)
    CheckPlayerDrugs()
end)

-- Main draw/interaction loop
CreateThread(function()
    while true do
        local sleep = 500
        local playerCoords = GetEntityCoords(PlayerPedId())

        for i, location in ipairs(Config.SellingLocations) do
            local sellingCoords = vector3(location.sellSpot.x, location.sellSpot.y, location.sellSpot.z)
            local distance = #(playerCoords - sellingCoords)

            if hasDrugs and distance < 20.0 then
                sleep = 0
                DrawMarker(1, location.sellSpot.x, location.sellSpot.y, location.sellSpot.z - 0.95,
                    0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
            end

            if distance < 1.5 and hasDrugs then
                sleep = 0
                if not isSelling then
                    DisplayHelpText("Press ~INPUT_CONTEXT~ to start selling drugs")
                    if IsControlJustPressed(0, 38) then StartSelling(i) end
                else
                    DisplayHelpText("Press ~INPUT_CONTEXT~ to stop selling")
                    if IsControlJustPressed(0, 38) then StopSelling(false) end
                end
            end
        end

        -- Auto-stop if too far from selling spot
        if isSelling and currentSellingLocation then
            local sellPos = Config.SellingLocations[currentSellingLocation].sellSpot
            if #(playerCoords - vector3(sellPos.x, sellPos.y, sellPos.z)) > 10.0 then
                StopSelling(false)
            end
        end

        Wait(sleep)
    end
end)

-- Periodic drug check
CreateThread(function()
    Wait(5000)
    CheckPlayerDrugs()
    while true do
        Wait(15000)
        if not isSelling then CheckPlayerDrugs() end
    end
end)

-- Death check
CreateThread(function()
    local isDead = false
    while true do
        Wait(1000)
        if IsEntityDead(PlayerPedId()) and not isDead then
            isDead = true
            if isSelling then StopSelling(false) end
            while IsEntityDead(PlayerPedId()) do Wait(1000) end
            isDead = false
        end
    end
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, customer in pairs(customers) do
            if DoesEntityExist(customer.ped) then DeleteEntity(customer.ped) end
        end
        RemoveAllBlips()
    end
end)
