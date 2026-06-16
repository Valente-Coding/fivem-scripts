-- License Center Client
local isMenuOpen = false
local licenseBlip = nil

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

-- Export the license center location for other resources
exports('GetLicenseCenterLocation', function()
    return Config.LicenseCenterLocation
end)

-- Create blip
CreateThread(function()
    licenseBlip = AddBlipForCoord(Config.LicenseCenterLocation)
    SetBlipSprite(licenseBlip, Config.Blip.sprite)
    SetBlipDisplay(licenseBlip, 4)
    SetBlipScale(licenseBlip, Config.Blip.scale)
    SetBlipColour(licenseBlip, Config.Blip.color)
    SetBlipAsShortRange(licenseBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.label)
    EndTextCommandSetBlipName(licenseBlip)
end)

-- Open license center UI
local function OpenLicenseCenter()
    TriggerServerEvent('my_licenses:requestLicenses')
end

-- Receive licenses from server and show UI
RegisterNetEvent('my_licenses:showCenter')
AddEventHandler('my_licenses:showCenter', function(currentLicenses)
    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openLicenseCenter',
        licenses = Config.Licenses,
        currentLicenses = currentLicenses or {}
    })
end)

-- Close UI
local function CloseLicenseCenter()
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeLicenseCenter' })
end

-- Main loop
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - Config.LicenseCenterLocation)

        if distance < 10.0 then
            sleep = 0
            DrawMarker(1,
                Config.LicenseCenterLocation.x,
                Config.LicenseCenterLocation.y,
                Config.LicenseCenterLocation.z - 1.0,
                0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0,
                65, 105, 225, 100,
                false, false, 2, false, nil, nil, false)

            if distance < 2.0 and not isMenuOpen then
                DisplayHelpText("Press ~INPUT_CONTEXT~ to access the License Center")

                if IsControlJustReleased(0, 38) then
                    OpenLicenseCenter()
                end
            end
        end

        -- ESC close
        if isMenuOpen and (IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177)) then
            CloseLicenseCenter()
        end

        Wait(sleep)
    end
end)

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    CloseLicenseCenter()
    cb('ok')
end)

RegisterNUICallback('purchaseLicense', function(data, cb)
    local licenseType = data.license
    TriggerServerEvent('my_licenses:purchase', licenseType)
    cb('ok')
end)

-- Server response for purchase
RegisterNetEvent('my_licenses:purchaseResult')
AddEventHandler('my_licenses:purchaseResult', function(success, message, licenseType)
    if success then
        PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        ShowNotification("~g~" .. message)
        -- Refresh UI
        TriggerServerEvent('my_licenses:requestLicenses')
    else
        ShowNotification("~r~" .. message)
    end
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isMenuOpen then CloseLicenseCenter() end
        if licenseBlip then RemoveBlip(licenseBlip) end
    end
end)
