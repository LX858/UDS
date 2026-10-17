

-- ┌─────────────────────────────────────────────────────────────────────┐
-- │  oxlyn-notifykit · imports/server.lua                                 │
-- │  Drop-in import for OTHER resources (server side):                    │
-- │      server_script '@oxlyn-notifykit/imports/server.lua'              │
-- │  and a global `Notify` (alias `NotifyKit`) appears:                   │
-- │      Notify(src, 'Paid $500', 'money')          -- src -1 = everyone  │
-- │      Notify(src, { type = 'police', title = '10-31', message = '…' }) │
-- │      Notify.success(src, 'Saved')   Notify.error(src, 'No money')     │
-- │      Notify.police(src, 'Backup requested')  -- any type name works   │
-- │      Notify.all({ message = 'Storm incoming', type = 'weather' })     │
-- │      Notify.job('police', { title = 'Dispatch', message = '…' }, true)│
-- │      Notify.gang('ballas', '…') · Notify.radius(coords, 30.0, '…')    │
-- │      Notify.ace('my.ace', '…') · Notify.announce('Restart in 5 min')  │
-- │      if Notify.confirm(src, { message = 'Accept?' }) then … end       │
-- │      Notify.update(src, id, { … }) · Notify.progress(src, id, 60)     │
-- │      Notify.hide(src, id) · Notify.clear(src) · Notify.setStyle('glass')│
-- │      Notify.isAdmin(src)                                              │
-- │  Every server export is reachable by its name (camelCase or not).     │
-- └─────────────────────────────────────────────────────────────────────┘

local RES = 'oxlyn-notifykit'

local MAP = {
    notify = 'Notify', all = 'NotifyAll', notifyAll = 'NotifyAll', job = 'NotifyJob', notifyJob = 'NotifyJob',
    gang = 'NotifyGang', notifyGang = 'NotifyGang', radius = 'NotifyRadius', notifyRadius = 'NotifyRadius',
    ace = 'NotifyAce', notifyAce = 'NotifyAce',
    success = 'Success', error = 'Error', warning = 'Warning', info = 'Info',
    announce = 'Announce', confirm = 'Confirm', confirmAsync = 'ConfirmAsync',
    update = 'Update', progress = 'Progress', hide = 'Hide', clear = 'Clear',
    setStyle = 'SetStyle', setLook = 'SetLook', getLook = 'GetLook',
    isAdmin = 'IsAdmin', accessReport = 'AccessReport', getStyles = 'GetStyles', getTypes = 'GetTypes',
}

-- built-in type names (and the usual aliases): Notify.<type>(src, message, title?, duration?)
local TYPES = {
    primary = true, neutral = true, money = true, bank = true, police = true, ems = true, fire = true, mechanic = true,
    phone = true, message = true, mail = true, system = true, admin = true, achievement = true, xp = true,
    item = true, vehicle = true, location = true, weather = true, loading = true,
    inform = true, ambulance = true, cash = true, sms = true, staff = true, warn = true, danger = true,
}

local warned = false
local function call(exportName, ...)
    if GetResourceState(RES) ~= 'started' then
        if not warned then
            warned = true
            print(('^3[%s] %s is not started: notifications are skipped^7'):format(GetCurrentResourceName(), RES))
        end
        return nil
    end
    local e = exports[RES]
    return e[exportName](e, ...)
end

local function typed(ntype)
    return function(src, message, title, duration)
        local d
        if type(message) == 'table' then
            d = {}
            for k, v in pairs(message) do d[k] = v end
        else
            d = { message = message, title = title, duration = duration }
        end
        d.type = ntype
        return call('Notify', src, d)
    end
end

Notify = setmetatable({}, {
    -- Notify(src, data | message, type?, duration?, title?)   src -1 = everyone
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

