local originalPaint = {}
local lastIndex
local primaryPaint

-- Map paint category names to GTA V paint types for SetVehicleModColor_1/2
local categoryPaintType = {
    Classic = 0,      -- Normal
    Matte = 3,        -- Matte
    Metal = 4,        -- Metal
    Worn = 0,         -- Normal (worn colors use specific indices)
    Chameleon = 0,    -- Normal (chameleon colors use specific indices)
}

local function paintMods()
    local options = {}

    local primary, secondary = GetVehicleColours(vehicle)
    originalPaint.primary = primary
    originalPaint.secondary = secondary

    -- Store original modColor values for proper revert
    local mc1Type, mc1Color, mc1Pearl = GetVehicleModColor_1(vehicle)
    local mc2Type, mc2Color = GetVehicleModColor_2(vehicle)
    originalPaint.modColor1 = {mc1Type, mc1Color, mc1Pearl}
    originalPaint.modColor2 = {mc2Type, mc2Color}

    for category, values in pairs(Config.Paints) do
        local labels = {}
        local ids = {}
        local selectedIndex = 1

        for i, paint in ipairs(values) do
            labels[i] = paint.label
            ids[i] = paint.id
            if paint.id == primary then
                selectedIndex = i
            end
        end

        options[#options + 1] = {
            ids = ids,
            paintType = categoryPaintType[category] or 0,
            description = ('%s%s'):format(Config.Currency, Config.Prices['colors']),
            label = category,
            values = labels,
            close = true,
            defaultIndex = selectedIndex,
        }
    end

    table.sort(options, function(a, b)
        return a.label < b.label
    end)

    return options
end

local menu = {
    id = 'bennys-paint',
    canClose = true,
    disableInput = false,
    position = 'top-left',
    options = {},
}

local function onSubmit(selected, scrollIndex, args)
    local option = menu.options[selected]
    local duplicate = option.ids[scrollIndex] == originalPaint[primaryPaint and 'primary' or 'secondary']

    local success = require('client.utils.installMod')(duplicate, 'colors', {
        description = ('%s applied'):format(option.values[scrollIndex]),
        icon = 'fas fa-paint-brush',
    })

    if not success then
        SetVehicleColours(vehicle, originalPaint.primary, originalPaint.secondary)
        if originalPaint.modColor1 then
            SetVehicleModColor_1(vehicle, originalPaint.modColor1[1], originalPaint.modColor1[2], originalPaint.modColor1[3])
        end
        if originalPaint.modColor2 then
            SetVehicleModColor_2(vehicle, originalPaint.modColor2[1], originalPaint.modColor2[2])
        end
    end

    lib.setMenuOptions('bennys-paint', paintMods())
    lib.showMenu('bennys-paint', lastIndex)
end

menu.onClose = function(keyPressed)
    SetVehicleColours(vehicle, originalPaint.primary, originalPaint.secondary)
    if originalPaint.modColor1 then
        SetVehicleModColor_1(vehicle, originalPaint.modColor1[1], originalPaint.modColor1[2], originalPaint.modColor1[3])
    end
    if originalPaint.modColor2 then
        SetVehicleModColor_2(vehicle, originalPaint.modColor2[1], originalPaint.modColor2[2])
    end
    lib.showMenu('bennys-colors', colorsLastIndex)
end

menu.onSelected = function(selected, secondary, args)
    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    lastIndex = selected
end

menu.onSideScroll = function(selected, scrollIndex)
    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    local option = menu.options[selected]
    local colorId = option.ids[scrollIndex]
    local paintType = option.paintType
    if primaryPaint then
        SetVehicleColours(vehicle, colorId, originalPaint.secondary)
        SetVehicleModColor_1(vehicle, paintType, colorId, originalPaint.modColor1 and originalPaint.modColor1[3] or 0)
    else
        SetVehicleColours(vehicle, originalPaint.primary, colorId)
        SetVehicleModColor_2(vehicle, paintType, colorId)
    end
end

---@param primary boolean
return function(primary)
    primaryPaint = primary
    menu.options = paintMods()
    menu.title = primaryPaint and 'Primary paint' or 'Secondary paint'
    lib.registerMenu(menu, onSubmit)
    return menu.id
end
