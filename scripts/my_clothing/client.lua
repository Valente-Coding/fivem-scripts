-- ═══════════════════════════════════════════════════════════════════════════════
-- my_clothing - Client
-- Full per-piece clothing customization using NativeUI
-- Uses SliderItems for reliable 1-step scrolling (same pattern as lbg-char)
-- ═══════════════════════════════════════════════════════════════════════════════

local shopPool = nil
local shopMenu = nil
local isShopOpen = false
local savedClothing = nil
local hasPurchased = false
local nearShop = false

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

local function ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

local function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Build a numbered string table {"0", "1", "2", ...} for slider display
local function BuildNumberList(count)
    local t = {}
    for i = 0, math.max(0, count - 1) do
        t[#t + 1] = tostring(i)
    end
    if #t == 0 then t = {"0"} end
    return t
end

-- Capture all current clothing from the ped as a flat array
local function GetCurrentClothing(ped)
    local clothing = {}
    for _, cat in ipairs(Config.Components) do
        clothing[#clothing + 1] = {
            kind = "component",
            id = cat.id,
            drawable = GetPedDrawableVariation(ped, cat.id),
            texture = GetPedTextureVariation(ped, cat.id)
        }
    end
    for _, cat in ipairs(Config.Props) do
        clothing[#clothing + 1] = {
            kind = "prop",
            id = cat.id,
            drawable = GetPedPropIndex(ped, cat.id),
            texture = GetPedPropTextureIndex(ped, cat.id)
        }
    end
    return clothing
end

-- Apply saved clothing data to a ped
local function ApplyClothing(ped, clothing)
    if not clothing or type(clothing) ~= "table" then return end
    for _, entry in pairs(clothing) do
        if type(entry) == "table" and entry.id then
            if entry.kind == "component" then
                SetPedComponentVariation(ped, entry.id, entry.drawable or 0, entry.texture or 0, 2)
            elseif entry.kind == "prop" then
                if entry.drawable == -1 then
                    ClearPedProp(ped, entry.id)
                else
                    SetPedPropIndex(ped, entry.id, entry.drawable or 0, entry.texture or 0, true)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BLIPS
-- ═══════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    for _, coords in ipairs(Config.Shops) do
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blip.name)
        EndTextCommandSetBlipName(blip)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROXIMITY DETECTION & INTERACTION
-- ═══════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        nearShop = false

        for _, shopCoords in ipairs(Config.Shops) do
            local dist = #(pos - shopCoords)
            if dist < Config.DrawDistance then
                sleep = 0
                DrawMarker(Config.MarkerType, shopCoords.x, shopCoords.y, shopCoords.z,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z,
                    Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b,
                    100, false, true, 2, false, nil, nil, false)

                if dist < Config.InteractDistance and not nearShop then
                    nearShop = true
                    if not isShopOpen then
                        Draw3DText(shopCoords.x, shopCoords.y, shopCoords.z + 1.0,
                            "Press ~b~E ~w~to browse clothing")
                    end
                end
            end
        end

        if nearShop and not isShopOpen and IsControlJustReleased(0, 38) then
            OpenClothingShop()
        end

        Wait(sleep)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- MENU PROCESSING (NativeUI tick)
-- ═══════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(0)
        if shopPool then
            shopPool:ProcessMenus()
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- COMPONENT SUBMENU (shirts, pants, shoes, etc.)
-- Uses SliderItems - same input pattern as lbg-char-master (proven to work)
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateComponentSubmenu(pool, parentMenu, category, ped)
    local submenu = pool:AddSubMenu(parentMenu, category.name, "Browse " .. category.name, true)

    local maxDrawable = GetNumberOfPedDrawableVariations(ped, category.id)
    local currentDrawable = GetPedDrawableVariation(ped, category.id)
    local currentTexture = GetPedTextureVariation(ped, category.id)

    -- Build item lists for sliders
    local drawableItems = BuildNumberList(maxDrawable)
    local maxTexture = GetNumberOfPedTextureVariations(ped, category.id, currentDrawable)
    local textureItems = BuildNumberList(maxTexture)

    local drawSlider = NativeUI.CreateSliderItem("Style", drawableItems,
        math.max(1, math.min(currentDrawable + 1, #drawableItems)),
        "Use LEFT/RIGHT to browse styles", true)
    submenu:AddItem(drawSlider)

    local texSlider = NativeUI.CreateSliderItem("Texture", textureItems,
        math.max(1, math.min(currentTexture + 1, #textureItems)),
        "Use LEFT/RIGHT to change texture/color", true)
    submenu:AddItem(texSlider)

    -- Per-item slider callbacks (same pattern as lbg-char-master face features)
    drawSlider.OnSliderChanged = function(sender, item, index)
        local myPed = PlayerPedId()
        local newDrawable = index - 1
        SetPedComponentVariation(myPed, category.id, newDrawable, 0, 2)

        -- Rebuild texture slider for the new drawable
        local newMaxTex = GetNumberOfPedTextureVariations(myPed, category.id, newDrawable)
        local newTexItems = BuildNumberList(newMaxTex)
        texSlider.Items = newTexItems
        texSlider:Index(1)
    end

    texSlider.OnSliderChanged = function(sender, item, index)
        local myPed = PlayerPedId()
        local curDraw = GetPedDrawableVariation(myPed, category.id)
        SetPedComponentVariation(myPed, category.id, curDraw, index - 1, 2)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROP SUBMENU (hats, glasses, watches, etc.)
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreatePropSubmenu(pool, parentMenu, category, ped)
    local submenu = pool:AddSubMenu(parentMenu, category.name, "Browse " .. category.name, true)

    local maxDrawable = GetNumberOfPedPropDrawableVariations(ped, category.id)
    local currentDrawable = GetPedPropIndex(ped, category.id)
    local currentTexture = GetPedPropTextureIndex(ped, category.id)

    -- Build items with "None" (-1) as first entry
    local drawableItems = {"None"}
    for i = 0, math.max(0, maxDrawable - 1) do
        drawableItems[#drawableItems + 1] = tostring(i)
    end

    local drawIndex = 1
    if currentDrawable >= 0 then
        drawIndex = math.min(currentDrawable + 2, #drawableItems)
    end

    local maxTexture = 0
    if currentDrawable >= 0 then
        maxTexture = GetNumberOfPedPropTextureVariations(ped, category.id, currentDrawable)
    end
    local textureItems = BuildNumberList(maxTexture)

    local texIndex = 1
    if currentTexture >= 0 then
        texIndex = math.max(1, math.min(currentTexture + 1, #textureItems))
    end

    local drawSlider = NativeUI.CreateSliderItem("Style", drawableItems, drawIndex,
        "Use LEFT/RIGHT to browse (first = remove)", true)
    submenu:AddItem(drawSlider)

    local texSlider = NativeUI.CreateSliderItem("Texture", textureItems, texIndex,
        "Use LEFT/RIGHT to change texture/color", true)
    submenu:AddItem(texSlider)

    drawSlider.OnSliderChanged = function(sender, item, index)
        local myPed = PlayerPedId()
        if index == 1 then
            ClearPedProp(myPed, category.id)
            texSlider.Items = {"0"}
            texSlider:Index(1)
        else
            local newDrawable = index - 2
            SetPedPropIndex(myPed, category.id, newDrawable, 0, true)

            local newMaxTex = GetNumberOfPedPropTextureVariations(myPed, category.id, newDrawable)
            local newTexItems = BuildNumberList(newMaxTex)
            texSlider.Items = newTexItems
            texSlider:Index(1)
        end
    end

    texSlider.OnSliderChanged = function(sender, item, index)
        local myPed = PlayerPedId()
        local curDraw = GetPedPropIndex(myPed, category.id)
        if curDraw >= 0 then
            SetPedPropIndex(myPed, category.id, curDraw, index - 1, true)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- OPEN / CLOSE SHOP
-- ═══════════════════════════════════════════════════════════════════════════════

function OpenClothingShop()
    if isShopOpen then return end
    isShopOpen = true
    hasPurchased = false

    local ped = PlayerPedId()
    savedClothing = GetCurrentClothing(ped)

    shopPool = NativeUI.CreatePool()
    shopMenu = NativeUI.CreateMenu("Clothing Store",
        "~b~Browse clothes ~w~| Price: ~y~$" .. Config.Price, 47.5, 47.5)
    shopPool:Add(shopMenu)

    -- Add clothing component categories
    for _, cat in ipairs(Config.Components) do
        CreateComponentSubmenu(shopPool, shopMenu, cat, ped)
    end

    -- Add prop categories
    for _, cat in ipairs(Config.Props) do
        CreatePropSubmenu(shopPool, shopMenu, cat, ped)
    end

    -- Purchase button
    local purchaseItem = NativeUI.CreateItem("~g~Purchase Outfit ($" .. Config.Price .. ")",
        "Pay ~y~$" .. Config.Price .. " ~w~to save your current look permanently")
    shopMenu:AddItem(purchaseItem)
    purchaseItem.Activated = function(sender, item)
        local newClothing = GetCurrentClothing(PlayerPedId())
        TriggerServerEvent('my_clothing:purchase', newClothing)
    end

    -- Cancel button
    local cancelItem = NativeUI.CreateItem("~r~Cancel",
        "Revert all changes and leave the store")
    shopMenu:AddItem(cancelItem)
    cancelItem.Activated = function(sender, item)
        CloseShop(false)
    end

    shopPool:RefreshIndex()
    shopMenu:Visible(true)

    shopMenu.OnMenuClosed = function()
        if not hasPurchased then
            ApplyClothing(PlayerPedId(), savedClothing)
        end
        isShopOpen = false
    end
end

function CloseShop(purchased)
    if shopMenu then
        shopMenu:Visible(false)
    end
    if not purchased and savedClothing then
        ApplyClothing(PlayerPedId(), savedClothing)
    end
    isShopOpen = false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SERVER RESPONSES
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('my_clothing:purchaseResult')
AddEventHandler('my_clothing:purchaseResult', function(success, message)
    if success then
        hasPurchased = true
        ShowNotification("~g~" .. message)
        if shopMenu then
            shopMenu:Visible(false)
        end
        isShopOpen = false
    else
        ShowNotification("~r~" .. message)
    end
end)

RegisterNetEvent('my_clothing:loadClothing')
AddEventHandler('my_clothing:loadClothing', function(clothing)
    if clothing then
        Wait(500)
        ApplyClothing(PlayerPedId(), clothing)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- CLOTHING PERSISTENCE - Load saved clothes on spawn
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('lbgchar:loadCharacter')
AddEventHandler('lbgchar:loadCharacter', function(data)
    Wait(1500)
    TriggerServerEvent('my_clothing:requestClothing')
end)

AddEventHandler('playerSpawned', function()
    Wait(3000)
    TriggerServerEvent('my_clothing:requestClothing')
end)
