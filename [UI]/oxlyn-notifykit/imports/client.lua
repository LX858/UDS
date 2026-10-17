

-- ┌─────────────────────────────────────────────────────────────────────┐
-- │  oxlyn-notifykit · imports/client.lua                                 │
-- │  Drop-in import for OTHER resources. Add to their fxmanifest:         │
-- │      client_script '@oxlyn-notifykit/imports/client.lua'              │
-- │  and a global `Notify` (alias `NotifyKit`) appears:                   │
-- │      Notify('Saved')                                   -- info        │
-- │      Notify('Paid $500', 'money', 4000, 'Bank')                       │
-- │      Notify({ type = 'police', title = '10-31', message = '…' })      │
-- │      Notify.success('Done')   Notify.error('No keys', 'Garage')       │
-- │      Notify.police('Backup requested')   -- any type name works       │
-- │      local id = Notify({ message = 'Uploading', progress = 0 })       │
-- │      Notify.progress(id, 60)   Notify.update(id, { … })   Notify.hide(id)│
-- │      if Notify.confirm({ message = 'Accept the job?' }) then … end    │
-- │      Notify.announce('Server restart in 5 minutes')                   │
-- │  Every client export is reachable by its name (camelCase or not).     │
-- │  While NotifyKit is not started, notifications fall back to the GTA   │
-- │  feed instead of throwing "No such export".                           │
-- └─────────────────────────────────────────────────────────────────────┘

local RES = 'oxlyn-notifykit'

local MAP = {
    notify = 'Notify', success = 'Success', error = 'Error', warning = 'Warning', info = 'Info',
    update = 'Update', progress = 'Progress', hide = 'Hide', clear = 'Clear', announce = 'Announce',
    confirm = 'Confirm', confirmAsync = 'ConfirmAsync', test = 'Test',
    setDnd = 'SetDnd', setMute = 'SetMute', getPersonal = 'GetPersonal',
    openHistory = 'OpenHistory', closeHistory = 'CloseHistory', history = 'OpenHistory',
    openEditor = 'OpenEditor', closeEditor = 'CloseEditor', editor = 'OpenEditor',
    getLook = 'GetLook', setStyle = 'SetStyle', setPersonalLook = 'SetPersonalLook',
    getStyles = 'GetStyles', getStyleGroups = 'GetStyleGroups', getTypes = 'GetTypes', getPositions = 'GetPositions',
    getCompat = 'GetCompat',
    -- framework-shaped entries (same signatures as ESX / QBCore / ox_lib)
    oxlib = 'OxLib', esx = 'ESX', esxAdvanced = 'ESXAdvanced', qbcore = 'QBCore',
}

-- built-in type names (and the usual aliases): Notify.<type>(message, title?, duration?)
local TYPES = {
    primary = true, neutral = true, money = true, bank = true, police = true, ems = true, fire = true, mechanic = true,
    phone = true, message = true, mail = true, system = true, admin = true, achievement = true, xp = true,
    item = true, vehicle = true, location = true, weather = true, loading = true,
    inform = true, ambulance = true, cash = true, sms = true, staff = true, warn = true, danger = true,
}

-- the calls that show something: fall back to the GTA feed while the kit is down
local SHOWS = { Notify = true, Success = true, Error = true, Warning = true, Info = true, Announce = true, OxLib = true, ESX = true, QBCore = true }

local function textOf(a, b)
    if type(a) == 'table' then
        local m = a.message or a.description or a.text or a.msg
        local t = a.title or a.caption
        if t and m then return tostring(t) .. ': ' .. tostring(m) end
        return m and tostring(m) or (t and tostring(t) or nil)
    end
    if a == nil then return nil end
    return tostring(a)
end

local function feed(text)
    if type(text) ~= 'string' or text == '' then return end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(text:gsub('%*%*', ''):sub(1, 99))
    EndTextCommandThefeedPostTicker(false, true)
end

local function call(exportName, ...)
    if GetResourceState(RES) ~= 'started' then
        if SHOWS[exportName] then feed(textOf(...)) end
        return nil
    end
    local e = exports[RES]
    return e[exportName](e, ...)
end

local function typed(ntype)
    return function(message, title, duration)
        local d
        if type(message) == 'table' then
            d = {}
            for k, v in pairs(message) do d[k] = v end
        else
            d = { message = message, title = title, duration = duration }
        end
        d.type = ntype
        return call('Notify', d)
    end
end

Notify = setmetatable({}, {
    -- Notify(data | message, type?, duration?, title?)
    __call = function(_, ...) return call('Notify', ...) end,
    __index = function(self, key)
        if type(key) ~= 'string' then return nil end
        local fn
        if MAP[key] then
            local exportName = MAP[key]
            fn = function(...) return call(exportName, ...) end
        elseif TYPES[key] then
            fn = typed(key)
        else
            local exportName = key:sub(1, 1):upper() .. key:sub(2)
            fn = function(...) return call(exportName, ...) end
        end
        rawset(self, key, fn)
        return fn
    end,
})

NotifyKit = Notify

