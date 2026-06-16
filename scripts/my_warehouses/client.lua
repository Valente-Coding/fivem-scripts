-- ════════════════════════════════════════════════════════
-- WAREHOUSE EMPIRE — Client
-- Tick engine, NUI bridge, manual delivery driving flow
-- ════════════════════════════════════════════════════════

local warehouses       = {}     -- { [warehouseId] = state, ... }
local currentWarehouse = nil    -- warehouseId of the open NUI
local nuiOpen          = false
local dataLoaded       = false

-- Per-warehouse tick accumulators
local autoPackAccum     = {}
local autoOrderCooldown = {}
local autoDeliverCooldown = {}

-- Manual delivery state
local manualDelivery = nil  -- { warehouseId, payout, boxCount, bonusPct, vehicle, blip, phase, destCoords, destName }

-- Blip tracking
local warehouseBlips = {}

-- Player cash (synced from server)
local playerCash = 0

-- ════════════════════ HELPERS ════════════════════

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

local function GetWarehouseConfig(warehouseId)
    for _, wh in ipairs(Config.Warehouses) do
        if wh.id == warehouseId then return wh end
    end
    return nil
end

-- ════════════════════ GAME LOGIC (mirrors game.js) ════════════════════

local C = Config.Game  -- shorthand

local function getUpgradeDef(id)
    for _, u in ipairs(Config.Upgrades) do
        if u.id == id then return u end
    end
    return nil
end

local function getCapacity(state)
    return C.INITIAL_CAPACITY + (state.upgrades.storage or 0) * C.STORAGE_PER_UPGRADE
end

local function getMatPerBox(state)
    return math.max(1, C.MAT_BASE_COST - (state.upgrades.mat_efficiency or 0))
end

local function getBoxValue(state)
    return C.BOX_BASE_VALUE + (state.upgrades.box_value or 0) * C.BOX_VALUE_PER_UPGRADE
end

local function getMaxDeliveries(state)
    return C.INITIAL_DELIVERY_SLOTS + (state.upgrades.del_slots or 0)
end

local function getDeliverySpeedMult(state)
    return math.pow(C.DELIVERY_SPEED_FACTOR, state.upgrades.del_speed or 0)
end

local function getOrderSpeedMult(state)
    return math.pow(C.ORDER_SPEED_FACTOR, state.upgrades.order_speed or 0)
end

local function getOrderAmount(state)
    return C.BASE_ORDER_AMOUNT + (state.upgrades.order_capacity or 0) * C.ORDER_AMOUNT_PER_UPGRADE
end

local function getAutoPackRate(state)
    return state.upgrades.auto_pack or 0
end

local function getDeliveryBonusMult(boxCount)
    return boxCount * C.MAX_BONUS_MULT / (C.MAX_STORAGE_UPGRADES * C.STORAGE_PER_UPGRADE)
end

local function getDeliveryTime(state, boxCount)
    return (C.BASE_DELIVERY_TIME + boxCount * C.DELIVERY_TIME_PER_BOX) * getDeliverySpeedMult(state)
end

local function getDeliveryPayout(state, boxCount)
    local base = boxCount * getBoxValue(state)
    local bonus = getDeliveryBonusMult(boxCount)
    return math.floor(base * (1 + bonus))
end

local function getManualBonusMult(boxCount)
    return boxCount * C.MANUAL_BONUS_MULT / (C.MAX_STORAGE_UPGRADES * C.STORAGE_PER_UPGRADE)
end

local function getManualPayout(state, boxCount)
    local base = boxCount * getBoxValue(state)
    local bonus = getManualBonusMult(boxCount)
    return math.floor(base * (1 + bonus))
end

local function getUpgradeCost(state, id)
    local def = getUpgradeDef(id)
    if not def then return 999999999 end
    return math.floor(def.baseCost * math.pow(def.mult, state.upgrades[id] or 0))
end

local function uid(state)
    state._nextId = (state._nextId or 0) + 1
    return state._nextId
end

-- ════════════════════ TICK PER WAREHOUSE ════════════════════

local function tickWarehouse(wid, state, dt)
    state.stats.playTime = (state.stats.playTime or 0) + dt

    -- Incoming material orders
    if state.incomingOrders then
        for i = #state.incomingOrders, 1, -1 do
            local o = state.incomingOrders[i]
            o.timeLeft = o.timeLeft - dt
            if o.timeLeft <= 0 then
                state.materials = state.materials + o.amount
                state.stats.totalMaterialsOrdered = (state.stats.totalMaterialsOrdered or 0) + o.amount
                table.remove(state.incomingOrders, i)
            end
        end
    end

    -- Active deliveries (truck-send, timer-based)
    if state.activeDeliveries then
        for i = #state.activeDeliveries, 1, -1 do
            local d = state.activeDeliveries[i]
            d.timeLeft = d.timeLeft - dt
            if d.timeLeft <= 0 then
                state.money = state.money + d.payout
                state.stats.totalMoneyEarned = (state.stats.totalMoneyEarned or 0) + d.payout
                state.stats.totalBoxesDelivered = (state.stats.totalBoxesDelivered or 0) + d.boxes
                state.stats.totalDeliveries = (state.stats.totalDeliveries or 0) + 1
                table.remove(state.activeDeliveries, i)
            end
        end
    end

    -- Auto-Packer
    local autoRate = getAutoPackRate(state)
    if autoRate > 0 then
        autoPackAccum[wid] = (autoPackAccum[wid] or 0) + autoRate * dt
        local whole = math.floor(autoPackAccum[wid])
        if whole > 0 then
            local matPerBox = getMatPerBox(state)
            local canPackMat = math.floor(state.materials / matPerBox)
            local canPackCap = getCapacity(state) - state.boxes
            local actual = math.min(whole, canPackMat, canPackCap)
            if actual > 0 then
                state.materials = state.materials - actual * matPerBox
                state.boxes = state.boxes + actual
                state.stats.totalBoxesPacked = (state.stats.totalBoxesPacked or 0) + actual
                autoPackAccum[wid] = autoPackAccum[wid] - actual
            else
                autoPackAccum[wid] = math.min(autoPackAccum[wid], 1)
            end
        end
    else
        autoPackAccum[wid] = 0
    end

    -- Auto-Order Materials
    if (state.upgrades.auto_order or 0) > 0 then
        autoOrderCooldown[wid] = (autoOrderCooldown[wid] or 0) - dt
        if autoOrderCooldown[wid] <= 0 then
            local orderAmt = getOrderAmount(state)
            local pendingMats = 0
            for _, o in ipairs(state.incomingOrders or {}) do
                pendingMats = pendingMats + o.amount
            end
            if (state.materials + pendingMats) < orderAmt * 2 then
                if state.money >= C.BASE_ORDER_COST then
                    -- Place order
                    state.money = state.money - C.BASE_ORDER_COST
                    state.stats.totalMoneySpent = (state.stats.totalMoneySpent or 0) + C.BASE_ORDER_COST
                    local orderTime = C.BASE_ORDER_TIME * getOrderSpeedMult(state)
                    table.insert(state.incomingOrders, {
                        id = uid(state),
                        type = Config.MaterialOrder.name,
                        amount = orderAmt,
                        timeLeft = orderTime,
                        timeTotal = orderTime,
                        icon = Config.MaterialOrder.icon,
                        color = Config.MaterialOrder.color,
                    })
                    autoOrderCooldown[wid] = 3
                end
            end
        end
    end

    -- Auto-Deliver (truck-send only, not manual)
    if (state.upgrades.auto_deliver or 0) > 0 then
        autoDeliverCooldown[wid] = (autoDeliverCooldown[wid] or 0) - dt
        if autoDeliverCooldown[wid] <= 0 then
            local cap = getCapacity(state)
            local maxDel = getMaxDeliveries(state)
            if state.boxes > 0 and state.boxes >= cap and #(state.activeDeliveries or {}) < maxDel then
                local boxCount = state.boxes
                local deliveryTime = getDeliveryTime(state, boxCount)
                local payout = getDeliveryPayout(state, boxCount)
                state.boxes = 0
                table.insert(state.activeDeliveries, {
                    id = uid(state),
                    type = 'Delivery (' .. boxCount .. ' boxes)',
                    boxes = boxCount,
                    payout = payout,
                    timeLeft = deliveryTime,
                    timeTotal = deliveryTime,
                    icon = 'fa-solid fa-truck-fast',
                    color = 'bg-info',
                })
                autoDeliverCooldown[wid] = 2
            end
        end
    end
end

-- ════════════════════ MAIN TICK THREAD ════════════════════

local lastTickTime = GetGameTimer()

CreateThread(function()
    while true do
        Wait(50) -- ~20 ticks/sec
        if not dataLoaded then goto continue end

        local now = GetGameTimer()
        local dt = math.min((now - lastTickTime) / 1000.0, 0.5)
        lastTickTime = now

        for wid, state in pairs(warehouses) do
            tickWarehouse(wid, state, dt)
        end

        -- Push state to NUI if open
        if nuiOpen and currentWarehouse and warehouses[currentWarehouse] then
            SendNUIMessage({
                action     = 'updateState',
                state      = warehouses[currentWarehouse],
                playerCash = playerCash,
            })
        end

        ::continue::
    end
end)

-- ════════════════════ AUTO-SAVE THREAD ════════════════════

CreateThread(function()
    while true do
        Wait(Config.AutoSaveInterval * 1000)
        if dataLoaded and next(warehouses) then
            TriggerServerEvent('my_warehouses:saveData', warehouses)
        end
    end
end)

-- ════════════════════ DATA LOAD ════════════════════

CreateThread(function()
    Wait(3000)
    TriggerServerEvent('my_warehouses:requestData')
end)

RegisterNetEvent('my_warehouses:receiveData')
AddEventHandler('my_warehouses:receiveData', function(data, cash)
    if type(data) == 'table' then
        warehouses = data
    else
        warehouses = {}
    end
    if cash then playerCash = cash end
    dataLoaded = true
    RefreshBlips()
end)

-- Cash sync from server
RegisterNetEvent('my_warehouses:receiveCash')
AddEventHandler('my_warehouses:receiveCash', function(cash)
    if cash then playerCash = cash end
end)

-- Periodic cash sync (keeps playerCash current even when money changes from other resources)
CreateThread(function()
    while true do
        Wait(5000)
        if dataLoaded then
            TriggerServerEvent('my_warehouses:requestCash')
        end
    end
end)

-- ════════════════════ BLIPS ════════════════════

function RefreshBlips()
    -- Remove old blips
    for _, b in ipairs(warehouseBlips) do
        RemoveBlip(b)
    end
    warehouseBlips = {}

    for _, wh in ipairs(Config.Warehouses) do
        local blip = AddBlipForCoord(wh.coords.x, wh.coords.y, wh.coords.z)
        local owned = warehouses[wh.id] ~= nil
        local cfg = owned and Config.Blips.owned or Config.Blips.available

        SetBlipSprite(blip, cfg.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, cfg.scale)
        SetBlipColour(blip, cfg.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(owned and (cfg.label .. ': ' .. wh.name) or (cfg.label .. ': ' .. wh.name))
        EndTextCommandSetBlipName(blip)

        table.insert(warehouseBlips, blip)
    end
end

-- ════════════════════ MARKER & INTERACTION THREAD ════════════════════

CreateThread(function()
    while true do
        Wait(0)
        if not dataLoaded then goto skip end

        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        for _, wh in ipairs(Config.Warehouses) do
            local dist = #(pCoords - wh.coords)
            if dist < Config.InteractionDistance then
                local owned = warehouses[wh.id] ~= nil

                if owned then
                    DrawText3D(wh.coords.x, wh.coords.y, wh.coords.z, 'Press ~g~E~s~ to manage ~b~' .. wh.name)
                    if IsControlJustReleased(0, 38) then -- E key
                        OpenWarehouseUI(wh.id)
                    end
                else
                    DrawText3D(wh.coords.x, wh.coords.y, wh.coords.z, 'Press ~g~E~s~ to buy ~b~' .. wh.name .. ' ~s~($' .. wh.price .. ')')
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('my_warehouses:buyWarehouse', wh.id)
                    end
                end
            end
        end

        ::skip::
    end
end)

-- ════════════════════ NUI OPEN / CLOSE ════════════════════

function OpenWarehouseUI(warehouseId)
    if nuiOpen then return end
    if not warehouses[warehouseId] then return end
    if manualDelivery then
        ShowNotification('~r~Complete your current delivery first!')
        return
    end

    currentWarehouse = warehouseId
    nuiOpen = true
    SetNuiFocus(true, true)

    local whConfig = GetWarehouseConfig(warehouseId)

    SendNUIMessage({
        action     = 'init',
        config     = Config.Game,
        upgrades   = Config.Upgrades,
        matOrder   = Config.MaterialOrder,
        state      = warehouses[warehouseId],
        whName     = whConfig and whConfig.name or warehouseId,
        playerCash = playerCash,
    })
end

function CloseWarehouseUI()
    if not nuiOpen then return end
    nuiOpen = false
    currentWarehouse = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
end

RegisterNUICallback('closeUI', function(data, cb)
    CloseWarehouseUI()
    cb('ok')
end)

-- ════════════════════ NUI CALLBACKS ════════════════════

RegisterNUICallback('doClick', function(data, cb)
    if not currentWarehouse or not warehouses[currentWarehouse] then cb('{}') return end
    local state = warehouses[currentWarehouse]

    local matPerBox = getMatPerBox(state)
    local clickPower = C.INITIAL_CLICK_POWER + (state.upgrades.click_power or 0)
    local capacity = getCapacity(state)
    local freeSpace = capacity - state.boxes

    if state.materials < matPerBox or freeSpace <= 0 then cb('{}') return end

    local maxByMat = math.floor(state.materials / matPerBox)
    local boxesMade = math.min(clickPower, maxByMat, freeSpace)
    if boxesMade <= 0 then cb('{}') return end

    state.materials = state.materials - boxesMade * matPerBox
    state.boxes = state.boxes + boxesMade
    state.stats.totalBoxesPacked = (state.stats.totalBoxesPacked or 0) + boxesMade
    state.stats.totalClicks = (state.stats.totalClicks or 0) + 1

    cb(json.encode({ boxesMade = boxesMade }))
end)

RegisterNUICallback('orderMaterials', function(data, cb)
    if not currentWarehouse or not warehouses[currentWarehouse] then cb('{}') return end
    local state = warehouses[currentWarehouse]

    if state.money < C.BASE_ORDER_COST then cb(json.encode({ ok = false })) return end

    local amount = getOrderAmount(state)
    state.money = state.money - C.BASE_ORDER_COST
    state.stats.totalMoneySpent = (state.stats.totalMoneySpent or 0) + C.BASE_ORDER_COST

    local orderTime = C.BASE_ORDER_TIME * getOrderSpeedMult(state)
    table.insert(state.incomingOrders, {
        id = uid(state),
        type = Config.MaterialOrder.name,
        amount = amount,
        timeLeft = orderTime,
        timeTotal = orderTime,
        icon = Config.MaterialOrder.icon,
        color = Config.MaterialOrder.color,
    })

    cb(json.encode({ ok = true }))
end)

RegisterNUICallback('sendAllBoxes', function(data, cb)
    if not currentWarehouse or not warehouses[currentWarehouse] then cb('{}') return end
    local state = warehouses[currentWarehouse]

    if state.boxes <= 0 then cb(json.encode({ ok = false })) return end
    if #state.activeDeliveries >= getMaxDeliveries(state) then cb(json.encode({ ok = false })) return end

    local boxCount = state.boxes
    local deliveryTime = getDeliveryTime(state, boxCount)
    local payout = getDeliveryPayout(state, boxCount)
    local bonusPct = math.floor(getDeliveryBonusMult(boxCount) * 100 + 0.5)

    state.boxes = 0
    table.insert(state.activeDeliveries, {
        id = uid(state),
        type = 'Delivery (' .. boxCount .. ' boxes)',
        boxes = boxCount,
        payout = payout,
        timeLeft = deliveryTime,
        timeTotal = deliveryTime,
        icon = 'fa-solid fa-truck-fast',
        color = 'bg-info',
    })

    cb(json.encode({ ok = true, boxCount = boxCount, payout = payout, bonusPct = bonusPct }))
end)

RegisterNUICallback('manualDeliver', function(data, cb)
    if not currentWarehouse or not warehouses[currentWarehouse] then cb('{}') return end
    if manualDelivery then cb(json.encode({ ok = false, msg = 'Already on a delivery' })) return end
    local state = warehouses[currentWarehouse]

    if state.boxes <= 0 then cb(json.encode({ ok = false })) return end

    local boxCount = state.boxes
    local payout = getManualPayout(state, boxCount)
    local bonusPct = math.floor(getManualBonusMult(boxCount) * 100 + 0.5)

    state.boxes = 0

    -- Pick random delivery point
    local dp = Config.DeliveryPoints[math.random(#Config.DeliveryPoints)]

    -- Store delivery state
    manualDelivery = {
        warehouseId = currentWarehouse,
        payout = payout,
        boxCount = boxCount,
        bonusPct = bonusPct,
        destCoords = dp.coords,
        destName = dp.name,
        phase = 'driving_to_dest',  -- driving_to_dest -> delivering -> returning -> parking
        vehicle = nil,
        blip = nil,
    }

    -- Close UI and start the driving flow
    CloseWarehouseUI()

    cb(json.encode({ ok = true, boxCount = boxCount, payout = payout, destName = dp.name }))

    -- Spawn vehicle and warp player
    StartManualDeliveryDrive()
end)

RegisterNUICallback('buyUpgrade', function(data, cb)
    if not currentWarehouse or not warehouses[currentWarehouse] then cb('{}') return end
    local state = warehouses[currentWarehouse]
    local id = data.id

    local def = getUpgradeDef(id)
    if not def then cb(json.encode({ ok = false })) return end

    local level = state.upgrades[id] or 0
    if level >= def.max then cb(json.encode({ ok = false })) return end

    local cost = getUpgradeCost(state, id)
    if state.money < cost then cb(json.encode({ ok = false })) return end

    state.money = state.money - cost
    state.stats.totalMoneySpent = (state.stats.totalMoneySpent or 0) + cost
    state.upgrades[id] = level + 1

    cb(json.encode({ ok = true, newLevel = level + 1 }))
end)

RegisterNUICallback('deposit', function(data, cb)
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 or not currentWarehouse then cb(json.encode({ ok = false })) return end
    TriggerServerEvent('my_warehouses:deposit', currentWarehouse, math.floor(amount))
    cb(json.encode({ pending = true }))
end)

RegisterNUICallback('withdraw', function(data, cb)
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 or not currentWarehouse then cb(json.encode({ ok = false })) return end
    TriggerServerEvent('my_warehouses:withdraw', currentWarehouse, math.floor(amount))
    cb(json.encode({ pending = true }))
end)

-- ════════════════════ SERVER RESULT EVENTS ════════════════════

RegisterNetEvent('my_warehouses:buyResult')
AddEventHandler('my_warehouses:buyResult', function(success, msg, warehouseId, state, cash)
    ShowNotification(success and '~g~' .. msg or '~r~' .. msg)
    if success and warehouseId and state then
        warehouses[warehouseId] = state
        if cash then playerCash = cash end
        RefreshBlips()
    end
end)

RegisterNetEvent('my_warehouses:sellResult')
AddEventHandler('my_warehouses:sellResult', function(success, msg, warehouseId, cash)
    ShowNotification(success and '~g~' .. msg or '~r~' .. msg)
    if success and warehouseId then
        warehouses[warehouseId] = nil
        if cash then playerCash = cash end
        RefreshBlips()
        if currentWarehouse == warehouseId then
            CloseWarehouseUI()
        end
    end
end)

RegisterNetEvent('my_warehouses:depositResult')
AddEventHandler('my_warehouses:depositResult', function(success, msg, warehouseId, newBalance, cash)
    ShowNotification(success and '~g~' .. msg or '~r~' .. msg)
    if success and warehouseId and warehouses[warehouseId] and newBalance then
        warehouses[warehouseId].money = newBalance
    end
    if cash then playerCash = cash end
end)

RegisterNetEvent('my_warehouses:withdrawResult')
AddEventHandler('my_warehouses:withdrawResult', function(success, msg, warehouseId, newBalance, cash)
    ShowNotification(success and '~g~' .. msg or '~r~' .. msg)
    if success and warehouseId and warehouses[warehouseId] and newBalance then
        warehouses[warehouseId].money = newBalance
    end
    if cash then playerCash = cash end
end)

-- Phone withdraw updated the warehouse balance on the server; sync it locally
RegisterNetEvent('my_warehouses:phoneWithdrawSync')
AddEventHandler('my_warehouses:phoneWithdrawSync', function(warehouseId, newBalance, cash)
    if warehouseId and warehouses[warehouseId] and newBalance then
        warehouses[warehouseId].money = newBalance
    end
    if cash then playerCash = cash end
end)

RegisterNetEvent('my_warehouses:manualDeliveryResult')
AddEventHandler('my_warehouses:manualDeliveryResult', function(success, warehouseId, payout)
    if success then
        ShowNotification('~g~Delivery complete! +$' .. payout)
    end
end)

-- ════════════════════ MANUAL DELIVERY DRIVING FLOW ════════════════════

function StartManualDeliveryDrive()
    if not manualDelivery then return end

    local whConfig = GetWarehouseConfig(manualDelivery.warehouseId)
    if not whConfig then
        CancelManualDelivery()
        return
    end

    CreateThread(function()
        -- Request and load model
        local modelHash = GetHashKey(Config.DeliveryVehicle)
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) do
            Wait(100)
            timeout = timeout + 100
            if timeout > 10000 then
                ShowNotification('~r~Failed to load delivery vehicle!')
                CancelManualDelivery()
                return
            end
        end

        -- Spawn vehicle
        local sp = whConfig.vehicleSpawn
        local veh = CreateVehicle(modelHash, sp.x, sp.y, sp.z, sp.w, true, false)
        SetModelAsNoLongerNeeded(modelHash)
        SetVehicleOnGroundProperly(veh)
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleDirtLevel(veh, 0.0)

        -- Warp player in
        local ped = PlayerPedId()
        TaskWarpPedIntoVehicle(ped, veh, -1)
        manualDelivery.vehicle = veh

        -- Create destination blip
        local dp = manualDelivery.destCoords
        local blip = AddBlipForCoord(dp.x, dp.y, dp.z)
        SetBlipSprite(blip, Config.Blips.delivery.sprite)
        SetBlipColour(blip, Config.Blips.delivery.color)
        SetBlipScale(blip, Config.Blips.delivery.scale)
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, Config.Blips.delivery.color)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('Delivery: ' .. manualDelivery.destName)
        EndTextCommandSetBlipName(blip)
        manualDelivery.blip = blip

        ShowNotification('~b~Deliver to: ~w~' .. manualDelivery.destName)

        -- Phase 1: Drive to destination
        manualDelivery.phase = 'driving_to_dest'
        while manualDelivery and manualDelivery.phase == 'driving_to_dest' do
            Wait(0)
            local pPos = GetEntityCoords(PlayerPedId())
            local dist = #(pPos - manualDelivery.destCoords)

            if dist < 20.0 then
                DrawMarker(1, dp.x, dp.y, dp.z - 0.5, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 1.0, 255, 200, 0, 120, false, true, 2, nil, nil, false)
            end

            if dist < 5.0 then
                DrawText3D(dp.x, dp.y, dp.z + 1.0, '~g~Press E~s~ to deliver')
                if IsControlJustReleased(0, 38) then
                    manualDelivery.phase = 'returning'

                    -- Remove destination blip, set return blip
                    if manualDelivery.blip then
                        RemoveBlip(manualDelivery.blip)
                        manualDelivery.blip = nil
                    end

                    local ret = whConfig.returnMarker
                    local rblip = AddBlipForCoord(ret.x, ret.y, ret.z)
                    SetBlipSprite(rblip, Config.Blips.delivery.sprite)
                    SetBlipColour(rblip, 2) -- green for return
                    SetBlipScale(rblip, 1.0)
                    SetBlipRoute(rblip, true)
                    SetBlipRouteColour(rblip, 2)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString('Return to Warehouse')
                    EndTextCommandSetBlipName(rblip)
                    manualDelivery.blip = rblip

                    ShowNotification('~g~Goods delivered! ~b~Return to the warehouse to park the truck.')
                end
            end
        end

        -- Phase 2: Return to warehouse
        while manualDelivery and manualDelivery.phase == 'returning' do
            Wait(0)
            local pPos = GetEntityCoords(PlayerPedId())
            local ret = whConfig.returnMarker
            local dist = #(pPos - ret)

            if dist < 20.0 then
                DrawMarker(1, ret.x, ret.y, ret.z - 0.5, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 1.0, 21, 163, 98, 120, false, true, 2, nil, nil, false)
            end

            if dist < 5.0 then
                DrawText3D(ret.x, ret.y, ret.z + 1.0, '~g~Press E~s~ to park the truck')
                if IsControlJustReleased(0, 38) then
                    -- Complete delivery
                    CompleteManualDelivery()
                end
            end
        end
    end)
end

function CompleteManualDelivery()
    if not manualDelivery then return end

    -- Remove blip
    if manualDelivery.blip then
        RemoveBlip(manualDelivery.blip)
        manualDelivery.blip = nil
    end

    -- Remove vehicle
    if manualDelivery.vehicle and DoesEntityExist(manualDelivery.vehicle) then
        DeleteEntity(manualDelivery.vehicle)
    end

    -- Tell server to credit payout
    TriggerServerEvent('my_warehouses:completeManualDelivery',
        manualDelivery.warehouseId,
        manualDelivery.payout,
        manualDelivery.boxCount
    )

    -- Also credit locally so UI is immediately accurate
    if warehouses[manualDelivery.warehouseId] then
        local state = warehouses[manualDelivery.warehouseId]
        state.money = state.money + manualDelivery.payout
        state.stats.totalMoneyEarned = (state.stats.totalMoneyEarned or 0) + manualDelivery.payout
        state.stats.totalBoxesDelivered = (state.stats.totalBoxesDelivered or 0) + manualDelivery.boxCount
        state.stats.totalDeliveries = (state.stats.totalDeliveries or 0) + 1
    end

    manualDelivery = nil
end

function CancelManualDelivery()
    if not manualDelivery then return end

    -- Return boxes to warehouse
    if warehouses[manualDelivery.warehouseId] then
        warehouses[manualDelivery.warehouseId].boxes = warehouses[manualDelivery.warehouseId].boxes + manualDelivery.boxCount
    end

    if manualDelivery.blip then RemoveBlip(manualDelivery.blip) end
    if manualDelivery.vehicle and DoesEntityExist(manualDelivery.vehicle) then
        DeleteEntity(manualDelivery.vehicle)
    end

    manualDelivery = nil
    ShowNotification('~r~Delivery cancelled. Boxes returned.')
end

-- ════════════════════ CLEANUP ════════════════════

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    -- Clean up blips
    for _, b in ipairs(warehouseBlips) do RemoveBlip(b) end

    -- Clean up manual delivery
    if manualDelivery then
        if manualDelivery.blip then RemoveBlip(manualDelivery.blip) end
        if manualDelivery.vehicle and DoesEntityExist(manualDelivery.vehicle) then
            DeleteEntity(manualDelivery.vehicle)
        end
    end

    -- Close NUI
    if nuiOpen then
        SetNuiFocus(false, false)
    end
end)
