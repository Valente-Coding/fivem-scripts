-- Comprehensive vehicle property getter and setter
-- Captures EVERY mod, color, toggle, extra, neon, etc.

local function GetAllVehicleProperties(veh)
    if not veh or not DoesEntityExist(veh) then return {} end

    SetVehicleModKit(veh, 0)

    local colorPrimary, colorSecondary = GetVehicleColours(veh)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(veh)
    local modColor1Type, modColor1Color, modColor1Pearl = GetVehicleModColor_1(veh)
    local modColor2Type, modColor2Color = GetVehicleModColor_2(veh)

    -- Get all standard mods (0-49)
    local mods = {}
    for i = 0, 49 do
        local modValue = GetVehicleMod(veh, i)
        if modValue >= 0 then
            mods[tostring(i)] = modValue
        end
    end

    -- Get extras (1-20)
    local extras = {}
    for i = 1, 20 do
        if DoesExtraExist(veh, i) then
            extras[tostring(i)] = IsVehicleExtraTurnedOn(veh, i)
        end
    end

    -- Get neon state
    local neonEnabled = {}
    for i = 0, 3 do
        neonEnabled[tostring(i)] = IsVehicleNeonLightEnabled(veh, i)
    end
    local neonR, neonG, neonB = GetVehicleNeonLightsColour(veh)

    -- Get tyre smoke color
    local tyreSmokeR, tyreSmokeG, tyreSmokeB = GetVehicleTyreSmokeColor(veh)

    -- Get xenon color
    local xenonColor = GetVehicleXenonLightsColor(veh)

    return {
        -- Colors
        color1 = colorPrimary,
        color2 = colorSecondary,
        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,
        dashboardColor = GetVehicleDashboardColor(veh),
        interiorColor = GetVehicleInteriorColor(veh),
        modColor1 = { modColor1Type, modColor1Color, modColor1Pearl },
        modColor2 = { modColor2Type, modColor2Color },

        -- Custom RGB colors
        customPrimaryColor = GetIsVehiclePrimaryColourCustom(veh) and {GetVehicleCustomPrimaryColour(veh)} or nil,
        customSecondaryColor = GetIsVehicleSecondaryColourCustom(veh) and {GetVehicleCustomSecondaryColour(veh)} or nil,

        -- Health
        bodyHealth = GetVehicleBodyHealth(veh),
        engineHealth = GetVehicleEngineHealth(veh),
        fuelLevel = GetVehicleFuelLevel(veh),
        dirtLevel = GetVehicleDirtLevel(veh),

        -- All mods
        mods = mods,

        -- Wheels
        wheelType = GetVehicleWheelType(veh),

        -- Toggle mods
        turbo = IsToggleModOn(veh, 18),
        tyreSmokeEnabled = IsToggleModOn(veh, 20),
        xenonEnabled = IsToggleModOn(veh, 22),

        -- Tyre smoke color
        tyreSmokeR = tyreSmokeR,
        tyreSmokeG = tyreSmokeG,
        tyreSmokeB = tyreSmokeB,

        -- Xenon color
        xenonColor = xenonColor,

        -- Neon
        neonEnabled = neonEnabled,
        neonR = neonR,
        neonG = neonG,
        neonB = neonB,

        -- Window tint
        windowTint = GetVehicleWindowTint(veh),

        -- Plate
        plateIndex = GetVehicleNumberPlateTextIndex(veh),

        -- Livery
        livery = GetVehicleLivery(veh),
        liveryMod = GetVehicleMod(veh, 48),
        roofLivery = GetVehicleRoofLivery(veh),

        -- Extras
        extras = extras,
    }
end

local function ApplyAllVehicleProperties(veh, props)
    if not veh or not DoesEntityExist(veh) or not props then return end

    SetVehicleModKit(veh, 0)

    -- Colors
    if props.color1 and props.color2 then
        SetVehicleColours(veh, props.color1, props.color2)
    end

    if props.pearlescentColor and props.wheelColor then
        SetVehicleExtraColours(veh, props.pearlescentColor, props.wheelColor)
    end

    if props.dashboardColor then
        SetVehicleDashboardColor(veh, props.dashboardColor)
    end

    if props.interiorColor then
        SetVehicleInteriorColor(veh, props.interiorColor)
    end

    if props.modColor1 and type(props.modColor1) == "table" then
        if #props.modColor1 >= 3 and props.modColor1[2] >= 0 then
            SetVehicleModColor_1(veh, props.modColor1[1], props.modColor1[2], props.modColor1[3])
        elseif #props.modColor1 >= 2 and props.modColor1[2] >= 0 then
            SetVehicleModColor_1(veh, props.modColor1[1], props.modColor1[2], 0)
        end
    end

    if props.modColor2 and type(props.modColor2) == "table" then
        if #props.modColor2 >= 2 and props.modColor2[2] >= 0 then
            SetVehicleModColor_2(veh, props.modColor2[1], props.modColor2[2])
        end
    end

    -- Custom RGB colors (override palette colors if set)
    if props.customPrimaryColor and type(props.customPrimaryColor) == "table" and #props.customPrimaryColor >= 3 then
        SetVehicleCustomPrimaryColour(veh, props.customPrimaryColor[1], props.customPrimaryColor[2], props.customPrimaryColor[3])
    end
    if props.customSecondaryColor and type(props.customSecondaryColor) == "table" and #props.customSecondaryColor >= 3 then
        SetVehicleCustomSecondaryColour(veh, props.customSecondaryColor[1], props.customSecondaryColor[2], props.customSecondaryColor[3])
    end

    -- Wheel type MUST be set before wheel mods
    if props.wheelType then
        SetVehicleWheelType(veh, props.wheelType)
    end

    -- All standard mods
    if props.mods then
        for modIndex, modValue in pairs(props.mods) do
            local idx = tonumber(modIndex)
            if idx then
                SetVehicleMod(veh, idx, modValue, false)
            end
        end
    end

    -- Toggle mods
    if props.turbo ~= nil then
        ToggleVehicleMod(veh, 18, props.turbo)
    end

    if props.tyreSmokeEnabled ~= nil then
        ToggleVehicleMod(veh, 20, props.tyreSmokeEnabled)
    end

    if props.tyreSmokeR and props.tyreSmokeG and props.tyreSmokeB then
        SetVehicleTyreSmokeColor(veh, props.tyreSmokeR, props.tyreSmokeG, props.tyreSmokeB)
    end

    if props.xenonEnabled ~= nil then
        ToggleVehicleMod(veh, 22, props.xenonEnabled)
    end

    if props.xenonColor then
        SetVehicleXenonLightsColor(veh, props.xenonColor)
    end

    -- Neon
    if props.neonEnabled then
        for i = 0, 3 do
            local key = tostring(i)
            if props.neonEnabled[key] ~= nil then
                SetVehicleNeonLightEnabled(veh, i, props.neonEnabled[key])
            end
        end
    end

    if props.neonR and props.neonG and props.neonB then
        SetVehicleNeonLightsColour(veh, props.neonR, props.neonG, props.neonB)
    end

    -- Window tint
    if props.windowTint then
        SetVehicleWindowTint(veh, props.windowTint)
    end

    -- Plate index
    if props.plateIndex then
        SetVehicleNumberPlateTextIndex(veh, props.plateIndex)
    end

    -- Livery
    if props.livery and props.livery >= 0 then
        SetVehicleLivery(veh, props.livery)
    end
    if props.liveryMod and props.liveryMod >= 0 then
        SetVehicleMod(veh, 48, props.liveryMod, false)
    end
    if props.roofLivery and props.roofLivery >= 0 then
        SetVehicleRoofLivery(veh, props.roofLivery)
    end

    -- Extras (SetVehicleExtra uses inverted logic: 0 = on, 1 = off)
    if props.extras then
        for extraId, enabled in pairs(props.extras) do
            local id = tonumber(extraId)
            if id and DoesExtraExist(veh, id) then
                SetVehicleExtra(veh, id, not enabled)
            end
        end
    end

    -- Health
    if props.bodyHealth then
        SetVehicleBodyHealth(veh, props.bodyHealth)
    end

    if props.engineHealth then
        SetVehicleEngineHealth(veh, props.engineHealth)
    end

    if props.fuelLevel then
        SetVehicleFuelLevel(veh, props.fuelLevel)
    end

    if props.dirtLevel then
        SetVehicleDirtLevel(veh, props.dirtLevel)
    end
end

return {
    GetAllVehicleProperties = GetAllVehicleProperties,
    ApplyAllVehicleProperties = ApplyAllVehicleProperties,
}
