--- Player-facing UI settings (marker style, accent colour, toggles).
--- Opened with a command, stored per player in the resource KVP.
--- Only depends on client.utils so it can be required from anywhere.

local utils = require 'client.utils'

local settings = {}

local KVP_KEY = 'ox_target:settings'
-- The HUD that can drive the accent colour (bp_hud by default; blank disables).
local hudResource = GetConvar('ox_target:hudResource', 'bp_hud')
local settingsCommand = GetConvar('ox_target:settingsCommand', 'target')

---@param hex string
---@return number[]?
local function hexToRgb(hex)
    if type(hex) ~= 'string' then return nil end

    hex = hex:gsub('#', '')

    if #hex ~= 6 then return nil end

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)

    if not (r and g and b) then return nil end

    return { r, g, b }
end

local defaults = {
    marker = 'eye', -- 'eye' | 'crosshair'
    accentMode = 'auto', -- 'auto' follows the HUD/convar, 'custom' uses accentColor
    accentColor = '#00FFFF',
    vignette = GetConvarInt('ox_target:vignette', 1) == 1,
    handCursor = GetConvarInt('ox_target:handCursor', 0) == 1,
    hotkeys = GetConvarInt('ox_target:hotkeys', 1) == 1,
}

local current = {}

for key, value in pairs(defaults) do current[key] = value end

local accentRgb = { 0, 255, 255 }
local hudAccent
local isOpen = false

local function load()
    local raw = GetResourceKvpString(KVP_KEY)
    if not raw then return end

    local ok, saved = pcall(json.decode, raw)
    if not ok or type(saved) ~= 'table' then return end

    for key in pairs(defaults) do
        if saved[key] ~= nil then current[key] = saved[key] end
    end
end

local function resolveAccent()
    if current.accentMode == 'custom' then
        return hexToRgb(current.accentColor) or { 0, 255, 255 }
    end

    if hudAccent then
        local rgb = hexToRgb(hudAccent)
        if rgb then return rgb end
    end

    local convar = GetConvar('ox_target:accentColor', '')

    if convar ~= '' then
        local rgb = hexToRgb(convar)
        if rgb then return rgb end
    end

    return { 0, 255, 255 }
end

local function pushAccent()
    accentRgb = resolveAccent()
    utils.setAccentColor(accentRgb[1], accentRgb[2], accentRgb[3])

    SendNuiMessage(json.encode({
        event = 'updateAccentColor',
        r = accentRgb[1],
        g = accentRgb[2],
        b = accentRgb[3],
    }))
end

local function pushSettings()
    SendNuiMessage(json.encode({
        event = 'updateSettings',
        settings = current,
    }))
end

---@return table
function settings.get()
    return current
end

---@return number[]
function settings.getAccentRgb()
    return accentRgb
end

---@return boolean
function settings.isOpen()
    return isOpen
end

---@return boolean
function settings.isTiltEnabled()
    if hudResource == '' then return false end

    local ok, result = pcall(function() return exports[hudResource]:isTiltEnabled() end)

    return (ok and result) and true or false
end

function settings.open()
    if isOpen then return end

    isOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNuiMessage(json.encode({
        event = 'openSettings',
        settings = current,
        hud = hudResource ~= '' and hudResource or nil,
    }))
end

function settings.close()
    if not isOpen then return end

    isOpen = false
    SetNuiFocus(false, false)
    SendNuiMessage('{"event":"closeSettings"}')
end

local validMarkers = { eye = true, crosshair = true }
local validModes = { auto = true, custom = true }

---@param data table
local function apply(data)
    if type(data) ~= 'table' then return end

    if validMarkers[data.marker] then current.marker = data.marker end
    if validModes[data.accentMode] then current.accentMode = data.accentMode end

    if type(data.accentColor) == 'string' then
        local hex = data.accentColor:gsub('#', '')

        if #hex == 6 and hexToRgb(hex) then
            current.accentColor = '#' .. hex:lower()
        end
    end

    for _, key in ipairs({ 'vignette', 'handCursor', 'hotkeys' }) do
        if type(data[key]) == 'boolean' then current[key] = data[key] end
    end

    SetResourceKvp(KVP_KEY, json.encode(current))
    pushSettings()
    pushAccent()
end

RegisterNUICallback('settings:update', function(data, cb)
    cb(1)
    apply(data)
end)

RegisterNUICallback('settings:reset', function(_, cb)
    cb(1)

    for key, value in pairs(defaults) do current[key] = value end

    DeleteResourceKvp(KVP_KEY)
    SendNuiMessage(json.encode({ event = 'openSettings', settings = current }))
    pushSettings()
    pushAccent()
end)

RegisterNUICallback('settings:close', function(_, cb)
    cb(1)
    isOpen = false
    SetNuiFocus(false, false)
end)

-- The page announces itself so it can never miss the startup push.
RegisterNUICallback('uiReady', function(_, cb)
    cb(1)
    pushSettings()
    pushAccent()
end)

if settingsCommand ~= '' then
    RegisterCommand(settingsCommand, function()
        settings.open()
    end, false)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource and isOpen then settings.close() end
end)

if hudResource ~= '' then
    AddEventHandler(hudResource .. ':accentChanged', function(hex)
        hudAccent = hex
        if current.accentMode == 'auto' then pushAccent() end
    end)
end

CreateThread(function()
    load()

    -- Give the HUD a moment to start before asking it for a colour.
    Wait(500)

    if hudResource ~= '' then
        local ok, color = pcall(function() return exports[hudResource]:GetAccentColor() end)
        if ok and type(color) == 'string' then hudAccent = color end
    end

    pushSettings()
    pushAccent()

    if settingsCommand ~= '' then
        TriggerEvent('chat:addSuggestion', '/' .. settingsCommand, 'Targeting UI settings (marker, colour)')
    end
end)

return settings
