-- client/compat.lua
-- Drop-in replacement for ox_lib functions used by my_bennys
-- Provides: require override, cache, lib.onCache, lib.showTextUI, lib.hideTextUI,
--           lib.notify, lib.callback.await, lib.registerMenu,
--           lib.showMenu, lib.hideMenu, lib.setMenuOptions

-- =============================================
-- REQUIRE OVERRIDE (load modules from resource files)
-- =============================================

local _loadedModules = {}
local _nativeRequire = require

require = function(modName)
    -- Return cached module
    if _loadedModules[modName] ~= nil then
        return _loadedModules[modName]
    end

    -- Try native require first
    local ok, result = pcall(_nativeRequire, modName)
    if ok then
        _loadedModules[modName] = result
        return result
    end

    -- Convert dot notation to path: client.menus.main -> client/menus/main.lua
    local path = modName:gsub('%.', '/') .. '.lua'
    local content = LoadResourceFile(GetCurrentResourceName(), path)

    if not content then
        error(("module '%s' not found (tried native require and LoadResourceFile('%s'))"):format(modName, path), 2)
    end

    local fn, err = load(content, '@' .. path)
    if not fn then
        error(("error loading module '%s': %s"):format(modName, err), 2)
    end

    local moduleResult = fn()
    _loadedModules[modName] = moduleResult
    return moduleResult
end

-- =============================================
-- POLYFILLS
-- =============================================

if not math.clamp then
    math.clamp = function(val, lower, upper)
        if val < lower then return lower end
        if val > upper then return upper end
        return val
    end
end

-- =============================================
-- CACHE SYSTEM
-- =============================================

cache = {}
cache.vehicle = nil

local _cacheCallbacks = {}

lib = {}

lib.onCache = function(key, cb)
    _cacheCallbacks[key] = cb
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local newVeh = (veh ~= 0) and veh or nil
        if newVeh ~= cache.vehicle then
            cache.vehicle = newVeh
            if _cacheCallbacks.vehicle then
                _cacheCallbacks.vehicle(newVeh)
            end
        end
        Wait(200)
    end
end)

-- =============================================
-- TEXT UI (native help text)
-- =============================================

local _showTextUI = false
local _textUIContent = ''

lib.showTextUI = function(text, options)
    _showTextUI = true
    _textUIContent = text or ''
end

lib.hideTextUI = function()
    _showTextUI = false
end

CreateThread(function()
    while true do
        if _showTextUI then
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName(_textUIContent)
            EndTextCommandDisplayHelp(0, false, true, -1)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- =============================================
-- NOTIFICATIONS (native GTA)
-- =============================================

lib.notify = function(data)
    if not data then return end
    local text = ''
    if data.title and data.description then
        text = '~b~' .. data.title .. '~s~: ' .. data.description
    elseif data.description then
        text = data.description
    elseif data.title then
        text = data.title
    end

    -- Color based on type
    if data.type == 'error' then
        text = '~r~' .. text
    elseif data.type == 'success' then
        text = '~g~' .. text
    elseif data.type == 'info' then
        text = '~b~' .. text
    end

    SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    DrawNotification(false, false)
end

-- =============================================
-- SERVER CALLBACKS (event-based)
-- =============================================

lib.callback = {}

local _callbackId = 0
local _callbackResults = {}

RegisterNetEvent('my_bennys:callbackResult')
AddEventHandler('my_bennys:callbackResult', function(id, result)
    if _callbackResults[id] then
        _callbackResults[id].done = true
        _callbackResults[id].result = result
    end
end)

--- Await a server callback (replaces lib.callback.await)
--- @param name string callback name
--- @param _ any unused (ox_lib compat - usually `false`)
--- @return any result from server
lib.callback.await = function(name, _, ...)
    _callbackId = _callbackId + 1
    local id = _callbackId
    _callbackResults[id] = { done = false, result = nil }
    TriggerServerEvent('my_bennys:callback', name, id, ...)

    local timeout = 0
    while not _callbackResults[id].done do
        Wait(10)
        timeout = timeout + 10
        if timeout > 10000 then
            _callbackResults[id] = nil
            return false
        end
    end

    local result = _callbackResults[id].result
    _callbackResults[id] = nil
    return result
end

--- Client-side callback registration (stub - not used in my_bennys)
lib.callback.register = function(name, cb) end

-- =============================================
-- MENU SYSTEM (NUI-driven)
-- =============================================

local _registeredMenus = {}
local _activeMenuId = nil
local _selectedIndex = 1
local _scrollIndexes = {}
local _isMenuOpen = false
local _menuInputActive = false

local function GetCurrentMenuData()
    if not _activeMenuId then return nil end
    return _registeredMenus[_activeMenuId]
end

local function SendMenuToNUI()
    local data = GetCurrentMenuData()
    if not data then return end

    local nuiOptions = {}
    for i, opt in ipairs(data.menu.options) do
        local currentValue = nil
        local hasValues = opt.values ~= nil and #(opt.values or {}) > 0
        if hasValues then
            local scrollIdx = _scrollIndexes[i] or 1
            currentValue = opt.values[scrollIdx]
        end
        nuiOptions[i] = {
            label = opt.label,
            description = opt.description,
            hasValues = hasValues,
            currentValue = currentValue,
            totalValues = opt.values and #opt.values or 0,
            scrollIndex = _scrollIndexes[i] or 1,
        }
    end

    SendNUIMessage({
        action = 'showMenu',
        title = data.menu.title or "Benny's",
        options = nuiOptions,
        selectedIndex = _selectedIndex,
    })
end

local function StartMenuInputThread()
    if _menuInputActive then return end
    _menuInputActive = true

    CreateThread(function()
        while _menuInputActive do
            if not _isMenuOpen then
                Wait(100)
                goto continue
            end

            local menuData = GetCurrentMenuData()
            if not menuData then
                Wait(100)
                goto continue
            end

            local opts = menuData.menu.options
            local numOpts = #opts

            -- Disable frontend controls so they don't trigger game actions
            DisableControlAction(0, 172, true) -- CELLPHONE_UP
            DisableControlAction(0, 173, true) -- CELLPHONE_DOWN
            DisableControlAction(0, 174, true) -- CELLPHONE_LEFT
            DisableControlAction(0, 175, true) -- CELLPHONE_RIGHT
            DisableControlAction(0, 176, true) -- CELLPHONE_SELECT
            DisableControlAction(0, 177, true) -- CELLPHONE_CANCEL
            DisableControlAction(0, 191, true) -- INPUT_FRONTEND_ACCEPT (Enter)
            DisableControlAction(0, 194, true) -- INPUT_FRONTEND_CANCEL (Backspace)
            DisableControlAction(0, 199, true) -- FRONTEND_PAUSE (ESC)
            DisableControlAction(0, 200, true) -- FRONTEND_PAUSE_ALT (P)

            -- Ensure mouse clicks do NOT interact with menu (mouse is for camera only)
            DisableControlAction(0, 18, true)  -- INPUT_ENTER (also mapped to Enter sometimes)

            -- UP
            if IsDisabledControlJustPressed(0, 172) then
                _selectedIndex = _selectedIndex - 1
                if _selectedIndex < 1 then _selectedIndex = numOpts end
                if menuData.menu.onSelected then
                    menuData.menu.onSelected(_selectedIndex)
                end
                SendNUIMessage({ action = 'updateSelected', selectedIndex = _selectedIndex })
            end

            -- DOWN
            if IsDisabledControlJustPressed(0, 173) then
                _selectedIndex = _selectedIndex + 1
                if _selectedIndex > numOpts then _selectedIndex = 1 end
                if menuData.menu.onSelected then
                    menuData.menu.onSelected(_selectedIndex)
                end
                SendNUIMessage({ action = 'updateSelected', selectedIndex = _selectedIndex })
            end

            -- LEFT
            if IsDisabledControlJustPressed(0, 174) then
                local opt = opts[_selectedIndex]
                if opt and opt.values and #opt.values > 0 then
                    local idx = _scrollIndexes[_selectedIndex] or 1
                    idx = idx - 1
                    if idx < 1 then idx = #opt.values end
                    _scrollIndexes[_selectedIndex] = idx
                    if menuData.menu.onSideScroll then
                        menuData.menu.onSideScroll(_selectedIndex, idx)
                    end
                    SendNUIMessage({ action = 'updateScroll', optionIndex = _selectedIndex, scrollIndex = idx, value = opt.values[idx] })
                end
            end

            -- RIGHT
            if IsDisabledControlJustPressed(0, 175) then
                local opt = opts[_selectedIndex]
                if opt and opt.values and #opt.values > 0 then
                    local idx = _scrollIndexes[_selectedIndex] or 1
                    idx = idx + 1
                    if idx > #opt.values then idx = 1 end
                    _scrollIndexes[_selectedIndex] = idx
                    if menuData.menu.onSideScroll then
                        menuData.menu.onSideScroll(_selectedIndex, idx)
                    end
                    SendNUIMessage({ action = 'updateScroll', optionIndex = _selectedIndex, scrollIndex = idx, value = opt.values[idx] })
                end
            end

            -- SELECT (Enter key only - NOT mouse click)
            if IsDisabledControlJustPressed(0, 191) then
                local opt = opts[_selectedIndex]
                if opt then
                    local scrollIdx = _scrollIndexes[_selectedIndex] or 1
                    local args = opt.args
                    local shouldClose = opt.close == true

                    if shouldClose then
                        _isMenuOpen = false
                        SendNUIMessage({ action = 'hideMenu' })
                    end

                    if menuData.onSubmit then
                        menuData.onSubmit(_selectedIndex, scrollIdx, args)
                    end
                end
            end

            -- CANCEL (Backspace or ESC - keyboard only)
            if IsDisabledControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 199) then
                if menuData.menu.canClose ~= false then
                    local menuId = _activeMenuId
                    _isMenuOpen = false
                    _activeMenuId = nil
                    SendNUIMessage({ action = 'hideMenu' })
                    if _registeredMenus[menuId] and _registeredMenus[menuId].menu.onClose then
                        _registeredMenus[menuId].menu.onClose()
                    end
                end
            end

            Wait(0)
            ::continue::
        end
    end)
end

lib.registerMenu = function(menu, onSubmit)
    _registeredMenus[menu.id] = {
        menu = menu,
        onSubmit = onSubmit,
    }
end

lib.showMenu = function(id, index)
    local data = _registeredMenus[id]
    if not data then return end

    _activeMenuId = id
    _selectedIndex = index or 1
    _isMenuOpen = true

    -- Initialize scroll indexes from defaultIndex
    _scrollIndexes = {}
    for i, opt in ipairs(data.menu.options) do
        _scrollIndexes[i] = opt.defaultIndex or 1
    end

    SendMenuToNUI()
    StartMenuInputThread()
end

--- Hide the menu
--- @param callOnClose boolean|nil if truthy, the onClose callback fires
lib.hideMenu = function(callOnClose)
    if not _isMenuOpen then return end
    local menuId = _activeMenuId
    _isMenuOpen = false
    SendNUIMessage({ action = 'hideMenu' })

    if callOnClose and menuId and _registeredMenus[menuId] and _registeredMenus[menuId].menu.onClose then
        _registeredMenus[menuId].menu.onClose()
    end
end

lib.setMenuOptions = function(id, options)
    if _registeredMenus[id] then
        _registeredMenus[id].menu.options = options
    end
end
