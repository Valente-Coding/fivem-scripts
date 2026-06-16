-- Server state tracking
local activeContracts = {} -- [playerId] = contractData
local occupiedSpawns = {} -- [spawnIndex] = {playerId, vehicleNetId, timestamp}
local missionTimers = {} -- [playerId] = true
local playerCooldowns = {} -- [playerId] = {tierId, expiryTime}

-- ==================== UTILITY FUNCTIONS ====================

-- Generate realistic random mileage (km) based on vehicle price.
-- Expensive vehicles are driven far less in real life.
local function GenerateRandomMileage(price)
    price = tonumber(price) or 50000
    local minKm, maxKm
    if price > 1000000 then
        minKm, maxKm = 200, 5000        -- hyper/exotic: barely driven
    elseif price > 400000 then
        minKm, maxKm = 1000, 12000       -- supercars
    elseif price > 150000 then
        minKm, maxKm = 5000, 30000       -- sports / luxury
    elseif price > 50000 then
        minKm, maxKm = 15000, 65000      -- mid-range
    else
        minKm, maxKm = 30000, 130000     -- economy / daily drivers
    end
    return math.random(minKm * 10, maxKm * 10) / 10 -- one decimal place
end

function GetTierById(tierId)
    for _, tier in ipairs(Config.Tiers) do
        if tier.id == tierId then return tier end
    end
    return nil
end

function GetAvailableSpawn()
    local availableSpawns = {}
    for i, spawn in ipairs(Config.SpawnLocations) do
        if not occupiedSpawns[i] then
            table.insert(availableSpawns, {index = i, coords = spawn.coords, heading = spawn.heading})
        end
    end
    if #availableSpawns > 0 then
        return availableSpawns[math.random(#availableSpawns)]
    end
    return nil
end

function IsPlayerOnCooldown(playerId)
    local cooldown = playerCooldowns[playerId]
    if not cooldown then return false, nil, nil end
    local currentTime = os.time()
    if currentTime >= cooldown.expiryTime then
        playerCooldowns[playerId] = nil
        return false, nil, nil
    end
    return true, cooldown.tierId, cooldown.expiryTime - currentTime
end

function SetPlayerCooldown(playerId, tierId)
    if not Config.Cooldowns[tierId] then return end
    local cooldownSeconds = Config.Cooldowns[tierId] * 60
    playerCooldowns[playerId] = {
        tierId = tierId,
        expiryTime = os.time() + cooldownSeconds
    }
end

function CleanupContract(playerId)
    local contract = activeContracts[playerId]
    if contract then
        if contract.spawnIndex then occupiedSpawns[contract.spawnIndex] = nil end
        missionTimers[playerId] = nil
        activeContracts[playerId] = nil
    end
end

function ShuffleTable(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math.random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

-- ==================== DATA REQUESTS ====================

RegisterNetEvent('vehicleFlipper:requestContractData')
AddEventHandler('vehicleFlipper:requestContractData', function()
    local _source = source
    
    local cashMoney = exports['my_money']:GetMoney(_source, 'cash') or 0
    local dirtyMoney = exports['my_money']:GetMoney(_source, 'dirty') or 0
    local onCooldown, cooldownTier, remainingSeconds = IsPlayerOnCooldown(_source)
    
    TriggerClientEvent('vehicleFlipper:receiveContractData', _source,
        activeContracts[_source],
        cashMoney,
        dirtyMoney,
        onCooldown,
        cooldownTier,
        remainingSeconds
    )
end)

-- ==================== CONTRACT MANAGEMENT ====================

RegisterNetEvent('vehicleFlipper:requestContract')
AddEventHandler('vehicleFlipper:requestContract', function(tierId, paymentType)
    local _source = source
    
    -- Check if player already has active contract
    if activeContracts[_source] then
        TriggerClientEvent('chatMessage', _source, "", "", Config.Locale.contract_active)
        return
    end
    
    -- Check cooldown
    local onCooldown, cooldownTier, remainingSeconds = IsPlayerOnCooldown(_source)
    if onCooldown then
        local remainingMinutes = math.ceil(remainingSeconds / 60)
        local tier = GetTierById(cooldownTier)
        local tierName = tier and tier.name or "Unknown"
        TriggerClientEvent('chatMessage', _source, "", "", 
            string.format("Cooldown active from %s contract. Wait %d minutes", tierName, remainingMinutes))
        return
    end
    
    local tier = GetTierById(tierId)
    if not tier then return end
    
    -- Validate payment type: cash or dirty
    if paymentType ~= 'cash' and paymentType ~= 'dirty' then
        paymentType = 'dirty'
    end
    
    -- Check funds
    local playerMoney = exports['my_money']:GetMoney(_source, paymentType) or 0
    if playerMoney < tier.contractPrice then
        TriggerClientEvent('chatMessage', _source, "", "", Config.Locale.no_money)
        return
    end
    
    -- Get available spawn point
    local spawnPoint = GetAvailableSpawn()
    if not spawnPoint then
        TriggerClientEvent('chatMessage', _source, "", "", Config.Locale.no_spawns_available)
        return
    end
    
    -- Get random vehicle from dealership
    local vehicles = exports['my_dealership']:GetVehiclesByPriceRange(tier.maxPrice, tier.minPrice)
    
    if not vehicles or #vehicles == 0 then
        TriggerClientEvent('chatMessage', _source, "", "", "No vehicles available in this tier")
        return
    end
    
    vehicles = ShuffleTable(vehicles)
    local randomVehicle = vehicles[math.random(#vehicles)]
    
    -- Charge contract fee
    if tier.contractPrice > 0 then
        exports['my_money']:RemoveMoney(_source, paymentType, tier.contractPrice)
    end
    
    -- Create contract
    local contract = {
        tierId = tierId,
        vehicleModel = randomVehicle.model,
        vehicleLabel = randomVehicle.label or randomVehicle.model,
        vehiclePrice = randomVehicle.price,
        spawnIndex = spawnPoint.index,
        spawnCoords = spawnPoint.coords,
        spawnHeading = spawnPoint.heading,
        startTime = os.time(),
        vehicleNetId = nil,
        paymentType = paymentType
    }
    
    activeContracts[_source] = contract
    StartMissionTimer(_source)
    TriggerClientEvent('vehicleFlipper:contractAccepted', _source, contract)
end)

RegisterNetEvent('vehicleFlipper:cancelContract')
AddEventHandler('vehicleFlipper:cancelContract', function()
    local _source = source
    local contract = activeContracts[_source]
    if not contract then return end
    
    local tier = GetTierById(contract.tierId)
    if not tier then return end
    
    local refund = math.floor(tier.contractPrice * (Config.CancelRefundPercent / 100))
    if refund > 0 then
        exports['my_money']:AddMoney(_source, contract.paymentType, refund)
    end
    
    CleanupContract(_source)
    TriggerClientEvent('vehicleFlipper:contractCancelled', _source, refund)
end)

-- ==================== VEHICLE SPAWNING ====================

RegisterNetEvent('vehicleFlipper:requestSpawnVehicle')
AddEventHandler('vehicleFlipper:requestSpawnVehicle', function()
    local _source = source
    local contract = activeContracts[_source]
    if not contract or contract.vehicleNetId then return end
    
    TriggerClientEvent('vehicleFlipper:spawnVehicle', _source,
        contract.vehicleModel,
        contract.spawnCoords,
        contract.spawnHeading
    )
end)

RegisterNetEvent('vehicleFlipper:confirmSpawn')
AddEventHandler('vehicleFlipper:confirmSpawn', function(vehicleNetId)
    local _source = source
    local contract = activeContracts[_source]
    if not contract then return end
    
    contract.vehicleNetId = vehicleNetId
    occupiedSpawns[contract.spawnIndex] = {
        playerId = _source,
        vehicleNetId = vehicleNetId,
        timestamp = os.time()
    }
end)

-- ==================== DELIVERY SYSTEM ====================

RegisterNetEvent('vehicleFlipper:deliverKeep')
AddEventHandler('vehicleFlipper:deliverKeep', function(plate, vehX, vehY, vehZ, vehHeading, vehProperties)
    local _source = source
    local contract = activeContracts[_source]
    if not contract then return end
    
    local tier = GetTierById(contract.tierId)
    if not tier then return end
    
    -- Guard against plate collision with existing registered vehicles
    if exports['my_vehicles']:DoesPlateExist(plate) then
        print("^1[vehicleFlipper ERROR]^7 Plate " .. plate .. " already exists in vehicle registry — rejecting keep")
        TriggerClientEvent('chatMessage', _source, "", "", "~r~Vehicle registration failed (plate collision). Try again with a new contract.")
        return
    end
    
    -- Calculate keep fee
    local keepFee = math.floor(contract.vehiclePrice * tier.keepVehicleFeeMultiplier)
    
    -- Check if player has enough cash for keep fee
    local playerCash = exports['my_money']:GetMoney(_source, 'cash') or 0
    if playerCash < keepFee then
        TriggerClientEvent('chatMessage', _source, "", "", Config.Locale.insufficient_funds_keep)
        return
    end
    
    -- Charge keep fee with cash
    exports['my_money']:RemoveMoney(_source, 'cash', keepFee)
    
    -- Register vehicle via my_vehicles
    local license = exports['my_datamanager']:GetPlayerLicense(_source)
    if not license then
        exports['my_money']:AddMoney(_source, 'cash', keepFee)
        TriggerClientEvent('chatMessage', _source, "", "", "Failed to register vehicle")
        return
    end
    
    local success = exports['my_vehicles']:RegisterVehicle(
        plate,
        contract.vehicleModel,
        license,
        GetPlayerName(_source),
        vehX, vehY, vehZ, vehHeading,
        vehProperties or {}
    )
    
    if success then
        -- Add realistic random mileage for the stolen vehicle
        local randomKm = GenerateRandomMileage(contract.vehiclePrice)
        exports['my_vehicles']:UpdateVehicleMileage(plate, randomKm)
        SetPlayerCooldown(_source, contract.tierId)
        TriggerClientEvent('vehicleFlipper:vehicleKept', _source, plate)
        CleanupContract(_source)
    else
        exports['my_money']:AddMoney(_source, 'cash', keepFee)
        TriggerClientEvent('chatMessage', _source, "", "", "Failed to register vehicle")
    end
end)

RegisterNetEvent('vehicleFlipper:deliverSell')
AddEventHandler('vehicleFlipper:deliverSell', function(conditionPercent)
    local _source = source
    local contract = activeContracts[_source]
    if not contract then return end
    
    local tier = GetTierById(contract.tierId)
    if not tier then return end
    
    local basePayout = contract.vehiclePrice * tier.rewardMultiplier
    local conditionMultiplier = math.max(Config.DamageCalculation.minimumMultiplier, conditionPercent / 100)
    local finalPayout = math.floor(basePayout * conditionMultiplier)
    
    -- Pay in dirty money
    exports['my_money']:AddMoney(_source, 'dirty', finalPayout)
    
    SetPlayerCooldown(_source, contract.tierId)
    TriggerClientEvent('vehicleFlipper:vehicleSold', _source, finalPayout)
    CleanupContract(_source)
end)

-- ==================== MISSION TIMER ====================

function StartMissionTimer(playerId)
    local startTime = os.time()
    missionTimers[playerId] = true
    
    local function CheckTimer()
        if not missionTimers[playerId] then return end
        local contract = activeContracts[playerId]
        if not contract then return end
        
        local elapsed = os.time() - startTime
        local remaining = math.floor((Config.MissionDuration / 1000) - elapsed)
        
        if remaining <= 0 then
            TriggerClientEvent('vehicleFlipper:missionExpired', playerId)
            CleanupContract(playerId)
        else
            TriggerClientEvent('vehicleFlipper:updateTimer', playerId, remaining)
            SetTimeout(1000, CheckTimer)
        end
    end
    
    CheckTimer()
end

-- ==================== CLEANUP ====================

AddEventHandler('playerDropped', function()
    local _source = source
    CleanupContract(_source)
    playerCooldowns[_source] = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for playerId, contract in pairs(activeContracts) do
            TriggerClientEvent('vehicleFlipper:missionFailed', playerId, "Resource stopped")
            CleanupContract(playerId)
        end
    end
end)
