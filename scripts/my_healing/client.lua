-- Healing Station Client
local healingPoint = vector3(342.5592, -1398.0648, 32.5093)
local isAtHealingPoint = false
local healingBlip = nil
local hasSpawned = false
local showingUI = false

local function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

local function CreateHealingBlip()
    healingBlip = AddBlipForCoord(healingPoint.x, healingPoint.y, healingPoint.z)
    SetBlipSprite(healingBlip, 489)
    SetBlipDisplay(healingBlip, 4)
    SetBlipScale(healingBlip, 1.0)
    SetBlipColour(healingBlip, 1)
    SetBlipAsShortRange(healingBlip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Healing Station")
    EndTextCommandSetBlipName(healingBlip)
end

local function DisplayHelpText(text)
    SetTextComponentFormat('STRING')
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

local function GetHealthPercent()
    local playerPed = PlayerPedId()
    local currentHealth = GetEntityHealth(playerPed)
    local maxHealth = GetEntityMaxHealth(playerPed)
    local adjustedCurrent = currentHealth - 100
    local adjustedMax = maxHealth - 100
    if adjustedMax <= 0 then return 100 end
    return math.floor((adjustedCurrent / adjustedMax) * 100)
end

local function GetMissingPercent()
    return 100 - GetHealthPercent()
end

-- Send NUI message to open healing UI
local function OpenHealingUI()
    if showingUI then return end
    showingUI = true
    local missing = GetMissingPercent()
    SendNUIMessage({
        action = "open",
        missingPercent = missing,
        costPerPercent = 100
    })
    SetNuiFocus(true, true)
end

local function CloseHealingUI()
    if not showingUI then return end
    showingUI = false
    SendNUIMessage({ action = "close" })
    SetNuiFocus(false, false)
end

-- NUI Callbacks
RegisterNUICallback('heal', function(data, cb)
    local healPercent = tonumber(data.percent)
    if not healPercent or healPercent <= 0 then
        cb({ ok = false })
        return
    end
    local missing = GetMissingPercent()
    if healPercent > missing then healPercent = missing end
    TriggerServerEvent('my_healing:healPlayer', healPercent)
    CloseHealingUI()
    cb({ ok = true })
end)

RegisterNUICallback('close', function(data, cb)
    CloseHealingUI()
    cb({ ok = true })
end)

-- Main loop
CreateThread(function()
    CreateHealingBlip()

    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = #(playerCoords - healingPoint)

        if distance < 10.0 then
            DrawMarker(1, healingPoint.x, healingPoint.y, healingPoint.z - 1.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                1.5, 1.5, 1.0, 0, 255, 0, 100,
                false, true, 2, false, nil, nil, false)

            if distance < 1.5 then
                isAtHealingPoint = true
                DisplayHelpText("Press ~INPUT_CONTEXT~ to open the Healing Station")

                if IsControlJustReleased(0, 38) and not showingUI then
                    OpenHealingUI()
                end
            else
                isAtHealingPoint = false
                if showingUI then CloseHealingUI() end
            end
            Wait(0)
        else
            isAtHealingPoint = false
            if showingUI then CloseHealingUI() end
            Wait(500)
        end
    end
end)

-- Heal event from server (partial or full)
RegisterNetEvent('my_healing:heal')
AddEventHandler('my_healing:heal', function(healPercent)
    local playerPed = PlayerPedId()
    local maxHealth = GetEntityMaxHealth(playerPed)
    local currentHealth = GetEntityHealth(playerPed)
    local adjustedMax = maxHealth - 100
    local healthToAdd = math.floor((healPercent / 100) * adjustedMax)
    local newHealth = math.min(currentHealth + healthToAdd, maxHealth)

    RequestAnimDict('mini@repair')
    while not HasAnimDictLoaded('mini@repair') do
        Wait(0)
    end

    TaskPlayAnim(playerPed, 'mini@repair', 'fixing_a_ped', 8.0, -8.0, -1, 49, 0, false, false, false)
    Wait(4000)

    SetEntityHealth(playerPed, newHealth)
    StopAnimTask(playerPed, 'mini@repair', 'fixing_a_ped', 1.0)

    ShowNotification('~g~Healed ' .. healPercent .. '% health!')

    -- Save health after healing
    TriggerServerEvent('my_healing:saveHealth', GetHealthPercent())
end)

-- Health persistence: load on first spawn
AddEventHandler('playerSpawned', function()
    if hasSpawned then return end
    hasSpawned = true
    TriggerServerEvent('my_healing:requestHealth')
end)

RegisterNetEvent('my_healing:loadHealth')
AddEventHandler('my_healing:loadHealth', function(healthPercent)
    if not healthPercent then return end
    local playerPed = PlayerPedId()
    local maxHealth = GetEntityMaxHealth(playerPed)
    local adjustedMax = maxHealth - 100
    local newHealth = 100 + math.floor((healthPercent / 100) * adjustedMax)
    newHealth = math.max(101, math.min(newHealth, maxHealth))
    SetEntityHealth(playerPed, newHealth)
end)

-- Periodically save health (every 60 seconds)
CreateThread(function()
    while true do
        Wait(60000)
        if hasSpawned then
            TriggerServerEvent('my_healing:saveHealth', GetHealthPercent())
        end
    end
end)

-- Save health on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if healingBlip ~= nil then
            RemoveBlip(healingBlip)
        end
        if hasSpawned then
            TriggerServerEvent('my_healing:saveHealth', GetHealthPercent())
        end
    end
end)
