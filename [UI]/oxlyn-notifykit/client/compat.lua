

-- Notification compatibility layer
-- Cleaned from decompiled output. Maps the exports/events of many third-party
-- notify resources (and ESX / QBCore / ox_lib) onto NK.Notify.

local SELF_RESOURCE = NK.resource or GetCurrentResourceName()
local CompatConfig = Config.Compat or {}

NK.Compat = {}

local order = {}     -- registration order (names)
local registry = {}  -- name -> entry

----------------------------------------------------------------------
-- Value helpers
----------------------------------------------------------------------

local function toStr(v)
    if type(v) == "number" then return tostring(v) end
    if type(v) == "string" then return v end
    return nil
end

local function toNum(v)
    local n = tonumber(v)
    if n == nil or n ~= n then return nil end -- nil or NaN
    return n
end

-- "br" -> "[bB][rR]" (case-insensitive Lua pattern)
local function caseInsensitive(s)
    return (s:gsub("%a", function(c)
        return "[" .. c:lower() .. c:upper() .. "]"
    end))
end

-- Matches <tag ...> and </tag ...>
local function tagPattern(name)
    return "<%s*/?%s*" .. caseInsensitive(name) .. "%f[^%w][^>]*>"
end

local PAT_BR       = "<%s*" .. caseInsensitive("br") .. "%s*/?%s*>"
local PAT_B        = tagPattern("b")
local PAT_STRONG   = tagPattern("strong")
local PAT_I        = tagPattern("i")
local PAT_EM       = tagPattern("em")
local PAT_CLOSE_P  = "<%s*/%s*" .. caseInsensitive("p") .. "%s*>"
local PAT_CLOSE_DIV = "<%s*/%s*" .. caseInsensitive("div") .. "%s*>"

local ENTITIES = {
    lt = "<", gt = ">", quot = "\"", apos = "'", nbsp = " ", amp = "&",
}

local function codepointToChar(n)
    n = tonumber(n)
    if not n or n < 1 or n > 1114111 then return nil end
    if utf8 and utf8.char then return utf8.char(n) end
    if n < 128 then return string.char(n) end
    return nil
end

--- Converts a small subset of HTML into plain text / light markdown.
local function fromHtml(value)
    local s = toStr(value)
    if not s then return nil end
    if not s:find("[<&]") then return s end

    s = s:gsub(PAT_BR, "\n")
    s = s:gsub(PAT_STRONG, "**"):gsub(PAT_B, "**")
    s = s:gsub(PAT_EM, "*"):gsub(PAT_I, "*")
    s = s:gsub(PAT_CLOSE_P, "\n"):gsub(PAT_CLOSE_DIV, "\n")
    s = s:gsub("<[^>]*>", "")
    s = s:gsub("&#[xX](%x+);", function(h) return codepointToChar(tonumber(h, 16)) end)
    s = s:gsub("&#(%d+);", function(d) return codepointToChar(d) end)
    s = s:gsub("&(%a+);", function(name) return ENTITIES[name:lower()] end)
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

NK.FromHtml = fromHtml

local function normalizeSound(sound)
    if sound == false then return false end

    if type(sound) == "table" and type(sound.name) == "string" then
        return {
            name = sound.name,
            set  = sound.set or sound.reference or sound.soundset or sound.soundSet,
            bank = sound.bank,
        }
    end

    if type(sound) == "string" and Utils.Contains(Utils.Sounds, sound) then
        return sound
    end

    return nil
end

local function asTable(v)
    if type(v) == "table" then return v end
    return {}
end

----------------------------------------------------------------------
-- Registration machinery
----------------------------------------------------------------------

--- Wraps fn so errors are logged instead of thrown.
local function safeWrap(label, fn)
    return function(...)
        local ok, result = pcall(fn, ...)
        if not ok then
            Utils.Warn("%s", _U("cp_error", label, tostring(result)))
            return nil
        end
        return result
    end
end

local function isResourceStarted(name)
    local ok, result = pcall(function()
        for i = 0, GetNumResources() - 1 do
            local res = GetResourceByFindIndex(i)
            if res == name and res ~= SELF_RESOURCE then
                return GetResourceState(res) == "started"
            end
        end
        return false
    end)
    return ok and result == true
end

local function log(key, ...)
    Utils.Info("%s", _U(key, ...))
end

local function activate(entry, resumed)
    if not entry.registered then
        entry.registered = true

        local function registerExport(exportName, fn)
            local wrapped = safeWrap(entry.name .. ":" .. exportName, fn)
            AddEventHandler(("__cfx_export_%s_%s"):format(entry.name, exportName), function(setCB)
                if NK.Compat[entry.name] == "active" then
                    setCB(wrapped)
                end
            end)
        end

        local function registerEvent(eventName, fn)
            local wrapped = safeWrap(eventName, fn)
            RegisterNetEvent(eventName, function(...)
                if NK.Compat[entry.name] == "active" then
                    wrapped(...)
                end
            end)
        end

        local ok, err = pcall(entry.register, registerExport, registerEvent)
        if not ok then
            NK.Compat[entry.name] = "off"
            Utils.Warn("%s", _U("cp_error", entry.name, tostring(err)))
            return
        end
    end

    NK.Compat[entry.name] = "active"
    log(resumed and "cp_resumed" or "cp_active", entry.name)
end

--- Registers a resource-based shim (provides exports + events when the
--- original resource is NOT running).
local function registerResource(name, configKey, registerFn)
    order[#order + 1] = name

    local entry = {
        name = name,
        kind = "resource",
        key = configKey,
        register = registerFn,
        registered = false,
    }
    registry[name] = entry

    if CompatConfig[configKey] == false then
        NK.Compat[name] = "off"
        return
    end

    if isResourceStarted(name) then
        NK.Compat[name] = "standby"
        log("cp_standby", name)
        return
    end

    activate(entry)
end

local function anyStarted(resources)
    for _, res in ipairs(resources) do
        if GetResourceState(res) == "started" then return true end
    end
    return false
end

local function refreshEventStatus(entry)
    if NK.Compat[entry.name] == "off" then return end
    NK.Compat[entry.name] = anyStarted(entry.owners) and "standby" or "active"
end

--- Registers an event-based shim (framework events; standby while the
--- owning framework resource is running).
local function registerEventCompat(name, configKey, owners, handlers)
    order[#order + 1] = name

    local entry = {
        name = name,
        kind = "event",
        key = configKey,
        owners = owners,
    }
    registry[name] = entry

    if CompatConfig[configKey] == false then
        NK.Compat[name] = "off"
        return
    end

    for _, handler in ipairs(handlers) do
        local wrapped = safeWrap(handler[1], handler[2])
        RegisterNetEvent(handler[1], function(...)
            if anyStarted(owners) then return end
            wrapped(...)
        end)
    end

    refreshEventStatus(entry)
end

----------------------------------------------------------------------
-- esx_notify
----------------------------------------------------------------------
registerResource("esx_notify", "esx_notify", function(export, event)
    local function notify(type_, duration, message, title, position)
        return NK.Notify({
            type     = toStr(type_),
            duration = toNum(duration),
            message  = fromHtml(message),
            title    = fromHtml(title),
            position = position,
        })
    end
    export("Notify", notify)
    event("ESX:Notify", notify)
end)

----------------------------------------------------------------------
-- okokNotify
----------------------------------------------------------------------
registerResource("okokNotify", "okokNotify", function(export, event)
    local function alert(title, message, duration, type_, sound)
        local payload = {
            title    = fromHtml(title),
            message  = fromHtml(message),
            duration = toNum(duration),
            type     = toStr(type_),
        }
        if sound == false then payload.sound = false end
        return NK.Notify(payload)
    end
    export("Alert", alert)
    event("okokNotify:Alert", alert)
end)

----------------------------------------------------------------------
-- mythic_notify
----------------------------------------------------------------------
registerResource("mythic_notify", "mythic_notify", function(export, event)
    local function styleColor(style)
        if type(style) ~= "table" then return nil end
        return toStr(style["background-color"] or style.background or style.backgroundColor)
    end

    local function send(type_, text, length, style, id)
        local payload = {
            type     = toStr(type_),
            message  = fromHtml(text),
            duration = toNum(length),
            color    = styleColor(style),
        }
        if id ~= nil then payload.id = "mythic:" .. tostring(id) end
        return NK.Notify(payload)
    end

    local function persistent(action, id, type_, text, style)
        if id == nil then return nil end
        local fullId = "mythic:" .. tostring(id)
        local act = type(action) == "string" and action:upper() or ""

        if act == "START" then
            return NK.Notify({
                id         = fullId,
                type       = toStr(type_),
                message    = fromHtml(text),
                color      = styleColor(style),
                persistent = true,
            })
        elseif act == "END" or act == "STOP" then
            return NK.Hide(fullId)
        end
        return nil
    end

    -- Exports
    export("SendAlert", function(type_, text, length, style)
        return send(type_, text, length, style)
    end)
    export("SendUniqueAlert", function(id, type_, text, length, style)
        return send(type_, text, length, style, id)
    end)
    export("PersistentAlert", persistent)
    export("DoShortHudText", function(type_, text, style) return send(type_, text, 1000, style) end)
    export("DoHudText",      function(type_, text, style) return send(type_, text, 2500, style) end)
    export("DoLongHudText",  function(type_, text, style) return send(type_, text, 5000, style) end)
    export("DoCustomHudText", function(type_, text, length, style) return send(type_, text, length, style) end)
    export("PersistentHudText", persistent)

    -- Events (table payloads)
    event("mythic_notify:client:SendAlert", function(d)
        d = asTable(d)
        send(d.type, d.text, d.length, d.style)
    end)
    event("mythic_notify:client:SendUniqueAlert", function(d)
        d = asTable(d)
        send(d.type, d.text, d.length, d.style, d.id)
    end)
    event("mythic_notify:client:PersistentAlert", function(d)
        d = asTable(d)
        persistent(d.action, d.id, d.type, d.text, d.style)
    end)
    event("mythic_notify:client:PersistentHudText", function(d)
        d = asTable(d)
        persistent(d.action, d.id, d.type, d.text, d.style)
    end)

    -- Events (HUD text, positional or table payload)
    local function hudHandler(defaultLength)
        return function(a, b, c, d)
            if type(a) == "table" then
                return send(a.type, a.text, a.length or defaultLength, a.style)
            end
            if defaultLength then
                return send(a, b, defaultLength, c)
            end
            return send(a, b, c, d)
        end
    end

    event("mythic_notify:client:DoShortHudText",  hudHandler(1000))
    event("mythic_notify:client:DoHudText",       hudHandler(2500))
    event("mythic_notify:client:DoLongHudText",   hudHandler(5000))
    event("mythic_notify:client:DoCustomHudText", hudHandler(nil))
end)

----------------------------------------------------------------------
-- pNotify
----------------------------------------------------------------------
registerResource("pNotify", "pNotify", function(export, event)
    local typeMap = { alert = "info", notification = "info" }

    local function send(data)
        if type(data) ~= "table" then data = { text = data } end

        local t = toStr(data.type)
        if t then t = typeMap[t:lower()] or t end

        local payload = {
            type     = t,
            message  = fromHtml(data.text),
            title    = fromHtml(data.title),
            position = data.layout,
        }

        if data.timeout == false then
            payload.persistent = true
        else
            payload.duration = toNum(data.timeout)
        end

        if data.progressBar ~= nil then
            payload.showProgress = data.progressBar ~= false
        end

        if data.killer == true then NK.Clear() end

        return NK.Notify(payload)
    end

    local function noop() end

    export("SendNotification", send)
    export("SetQueueMax", noop)
    event("pNotify:SendNotification", send)
    event("pNotify:SetQueueMax", noop)
end)

----------------------------------------------------------------------
-- t-notify
----------------------------------------------------------------------
registerResource("t-notify", "t_notify", function(export, event)
    local active = {}

    local function parse(data)
        if type(data) ~= "table" then
            if data == nil then return nil end
            data = { message = data }
        end
        return {
            type     = toStr(data.style or data.type),
            title    = fromHtml(data.title),
            message  = fromHtml(data.message),
            duration = toNum(data.duration),
            icon     = toStr(data.icon),
            image    = toStr(data.image),
            position = data.position,
            sound    = normalizeSound(data.sound),
        }
    end

    local function alert(data)
        local p = parse(data)
        if not p then return nil end
        p.title = nil
        return NK.Notify(p)
    end

    local function custom(data)
        local p = parse(data)
        if not p then return nil end
        return NK.Notify(p)
    end

    local function image(data)
        local p = parse(data)
        if not p then return nil end
        if not p.title and not p.message then p.message = " " end
        return NK.Notify(p)
    end

    local function persist(data)
        if type(data) ~= "table" or data.id == nil then return nil end

        local id = tostring(data.id)
        local fullId = "tnotify:" .. id
        local step = type(data.step) == "string" and data.step:lower() or "start"

        if step == "end" or step == "stop" then
            active[id] = nil
            return NK.Hide(fullId)
        end

        local opts = parse(data.options or {}) or {}
        opts.duration = nil

        if step == "update" and active[id] then
            local patch = {}
            for k, v in pairs(opts) do
                if k ~= "position" and k ~= "sound" then patch[k] = v end
            end
            return NK.Update(fullId, patch)
        end

        opts.id = fullId
        opts.persistent = true
        active[id] = true
        return NK.Notify(opts)
    end

    export("Alert", alert)
    export("Custom", custom)
    export("Image", image)
    export("Icon", custom)
    export("Persist", persist)
    export("IsPersistentShowing", function(id) return id ~= nil end)

    event("t-notify:client:Alert", alert)
    event("t-notify:client:Custom", custom)
    event("t-notify:client:Image", image)
    event("t-notify:client:Icon", custom)
    event("t-notify:client:Persist", persist)
end)

----------------------------------------------------------------------
-- brutal_notify
----------------------------------------------------------------------
registerResource("brutal_notify", "brutal_notify", function(export, event)
    local function send(title, message, duration, type_, sound)
        local payload = {
            title    = fromHtml(title),
            message  = fromHtml(message),
            duration = toNum(duration),
            type     = toStr(type_),
        }
        if sound == false then
            payload.sound = false
        elseif type(sound) == "string" or type(sound) == "table" then
            payload.sound = normalizeSound(sound)
        end
        return NK.Notify(payload)
    end
    export("SendAlert", send)
    event("brutal_notify:SendAlert", send)
end)

----------------------------------------------------------------------
-- wasabi_notify
----------------------------------------------------------------------
registerResource("wasabi_notify", "wasabi_notify", function(export, event)
    local function notify(title, message, duration, type_, sound, icon, extra)
        local payload = {
            title    = fromHtml(title),
            message  = fromHtml(message),
            duration = toNum(duration),
            type     = toStr(type_),
            icon     = toStr(icon),
        }
        if sound == false then payload.sound = false end

        if type(extra) == "string" then
            payload.color = extra
        elseif type(extra) == "number" then
            payload.id = "wasabi:" .. tostring(extra)
        end

        return NK.Notify(payload)
    end

    local function advancedNotify(data)
        if type(data) ~= "table" then return nil end
        local customType = type(data.customType) == "table" and data.customType or {}

        local payload = {
            title         = fromHtml(data.title or data.heading),
            message       = fromHtml(data.message or data.content or data.description),
            duration      = toNum(data.time or data.duration),
            type          = toStr(data.type),
            position      = data.position,
            icon          = toStr(data.icon),
            iconAnimation = data.iconEffect or data.iconAnimation,
            color         = toStr(data.color or customType.color),
        }
        if data.sound == false then payload.sound = false end
        if data.id ~= nil then payload.id = "wasabi:" .. tostring(data.id) end

        return NK.Notify(payload)
    end

    export("notify", notify)
    export("advancedNotify", advancedNotify)
    event("wasabi_notify:notify", notify)
    event("wasabi_notify:advancedNotify", advancedNotify)
end)

----------------------------------------------------------------------
-- oxlyn-notify
----------------------------------------------------------------------
registerResource("oxlyn-notify", "oxlyn_notify", function(export, event)
    local function show(type_, title, message, duration, opts)
        local payload = (type(opts) == "table" and NK.Clean(opts)) or {}
        payload.duration = toNum(duration)
        payload.message  = fromHtml(message)
        payload.title    = fromHtml(title)
        payload.type     = toStr(type_)
        NK.Notify(payload)
        return true
    end

    local function clear()
        NK.Clear()
        return true
    end

    local function ready() return true end

    export("ShowNotification", show)
    export("ClearNotifications", clear)
    export("IsOxlynCoreReady", ready)
    export("IsOxlynNotifyReady", ready)
    event("Oxlyn-Notify:showNotification", show)
    event("Oxlyn-Notify:clearNotifications", clear)
end)

----------------------------------------------------------------------
-- vms_notify
----------------------------------------------------------------------
registerResource("vms_notify", "vms_notify", function(export, event)
    local function notify(title, message, duration, color, icon)
        return NK.Notify({
            title    = fromHtml(title),
            message  = fromHtml(message),
            duration = toNum(duration),
            color    = toStr(color),
            icon     = toStr(icon),
        })
    end
    export("Notification", notify)
    event("vms_notify:Notification", notify)
end)

----------------------------------------------------------------------
-- vms_notifyv2
----------------------------------------------------------------------
registerResource("vms_notifyv2", "vms_notifyv2", function(export, event)
    local function notify(data, top)
        if type(data) ~= "table" then
            if data == nil then return nil end
            data = { description = data }
        end

        local payload = {
            title    = fromHtml(data.title),
            message  = fromHtml(data.description or data.message),
            duration = toNum(data.time),
            color    = toStr(data.color),
            icon     = toStr(data.icon),
            image    = toStr(data.image),
            type     = toStr(data.preset or data.type),
        }

        if data.progressBar ~= nil then
            payload.showProgress = type(data.progressBar) == "string"
        end

        local native = data.soundNative
        if type(native) == "table" and type(native[2]) == "string" then
            payload.sound = {
                name = native[2],
                set  = type(native[3]) == "string" and native[3] or nil,
            }
        end

        if top then payload.position = "top-center" end

        return NK.Notify(payload)
    end

    local function normal(d) return notify(d, false) end
    local function top(d)    return notify(d, true) end

    export("Notification", normal)
    export("TopNotification", top)
    event("vms_notifyv2:Notification", normal)
    event("vms_notifyv2:TopNotification", top)
end)

----------------------------------------------------------------------
-- k5_notify
----------------------------------------------------------------------
registerResource("k5_notify", "k5_notify", function(export, event)
    local function notify(title, message, type_, duration)
        return NK.Notify({
            title    = fromHtml(title),
            message  = fromHtml(message),
            type     = toStr(type_),
            duration = toNum(duration),
        })
    end
    export("notify", notify)
    event("k5_notify:notify", notify)
end)

----------------------------------------------------------------------
-- codem-notification
----------------------------------------------------------------------
registerResource("codem-notification", "codem_notification", function(export, event)
    local typeMap = {
        twitter = "message", saved = "success",
        lscustom = "mechanic", bennys = "mechanic",
        lsfd = "fire", ranger = "police", statepolice = "police",
        status = "info", taxi = "vehicle",
        ballas = "primary", families = "primary", vagos = "primary", lostmc = "primary",
    }

    local function mapType(v)
        local s = toStr(v)
        if s then s = typeMap[s:lower()] or s end
        return s
    end

    event("codem-notification:Create", function(message, type_, title, duration)
        return NK.Notify({
            message  = fromHtml(message),
            type     = mapType(type_),
            title    = fromHtml(title),
            duration = toNum(duration),
        })
    end)

    event("codem-notification", function(message, duration, type_)
        return NK.Notify({
            message  = fromHtml(message),
            type     = mapType(type_),
            duration = toNum(duration),
        })
    end)
end)

----------------------------------------------------------------------
-- FL-Notify
----------------------------------------------------------------------
registerResource("FL-Notify", "fl_notify", function(export, event)
    local types = { "error", "success", "primary", "info", "admin", "money", "system" }
    local positions = {
        [0] = "top-center",
        [1] = "bottom-center",
        [2] = "center-left",
        [3] = "center-right",
    }

    local function notify(title, subtitle, message, duration, typeArg, positionArg)
        local typeIndex = toNum(typeArg)
        local posIndex  = toNum(positionArg)

        return NK.Notify({
            title    = fromHtml(title),
            subtitle = fromHtml(subtitle),
            message  = fromHtml(message),
            duration = toNum(duration),
            type     = (typeIndex and types[typeIndex]) or toStr(typeArg),
            position = (posIndex and positions[posIndex]) or positionArg,
        })
    end

    export("Notify", notify)
    event("fl:notify", notify)
end)

----------------------------------------------------------------------
-- bulletin
----------------------------------------------------------------------
registerResource("bulletin", "bulletin", function(export, event)
    local pins = {}
    local pinCounter = 0

    local function avatar(icon)
        if type(icon) == "string" and icon:upper():sub(1, 5) == "CHAR_" then
            return ("https://nui-img/%s/%s"):format(icon, icon)
        end
        return nil
    end

    local function build(data, advanced)
        local payload = {
            message  = fromHtml(data.message),
            duration = toNum(data.timeout),
            position = data.position,
            type     = toStr(data.theme),
        }
        if data.progress ~= nil then
            payload.showProgress = data.progress == true
        end
        if advanced then
            payload.title    = fromHtml(data.title)
            payload.subtitle = fromHtml(data.subject)
            payload.avatar   = avatar(data.icon)
        end
        return payload
    end

    local function send(a, timeout, position, progress, theme)
        if type(a) == "table" then
            return NK.Notify(build(a, a.type == "advanced"))
        end
        return NK.Notify(build({
            message = a, timeout = timeout, position = position,
            progress = progress, theme = theme,
        }, false))
    end

    local function sendAdvanced(a, title, subject, icon, timeout, position, progress, theme)
        if type(a) == "table" then
            return NK.Notify(build(a, true))
        end
        return NK.Notify(build({
            message = a, title = title, subject = subject, icon = icon,
            timeout = timeout, position = position, progress = progress, theme = theme,
        }, true))
    end

    local function themed(theme)
        return function(a, b, c, d)
            if type(a) == "table" then
                local copy = Utils.Copy(a)
                copy.theme = theme
                return NK.Notify(build(copy, copy.type == "advanced"))
            end
            return send(a, b, c, d, theme)
        end
    end

    local function sendPinned(data)
        if type(data) ~= "table" then return nil end
        pinCounter = pinCounter + 1

        local payload = build(data, data.type == "advanced")
        payload.duration = nil
        payload.persistent = true
        payload.id = "bulletin:pin" .. pinCounter

        local id = NK.Notify(payload)
        if id then pins[id] = true end
        return id
    end

    local function unpin(id)
        if id == nil then
            for pinId in pairs(pins) do NK.Hide(pinId) end
            pins = {}
            return
        end
        if type(id) == "table" then
            for _, v in ipairs(id) do unpin(v) end
            return
        end
        id = tostring(id)
        pins[id] = nil
        NK.Hide(id)
    end

    local function updatePinned(id, data)
        if id == nil or type(data) ~= "table" then return nil end

        local patch = { keepTimer = true }
        if data.message ~= nil then patch.message  = fromHtml(data.message) end
        if data.title   ~= nil then patch.title    = fromHtml(data.title) end
        if data.subject ~= nil then patch.subtitle = fromHtml(data.subject) end
        if data.icon    ~= nil then patch.avatar   = avatar(data.icon) end
        if data.theme   ~= nil then patch.type     = toStr(data.theme) end

        return NK.Update(tostring(id), patch)
    end

    -- Exports
    export("Send", send)
    export("SendAdvanced", sendAdvanced)
    export("SendSuccess", themed("success"))
    export("SendInfo", themed("info"))
    export("SendWarning", themed("warning"))
    export("SendError", themed("error"))
    export("SendPinned", sendPinned)
    export("Unpin", unpin)
    export("UpdatePinned", updatePinned)

    -- Events
    event("bulletin:send", send)
    event("bulletin:sendAdvanced", sendAdvanced)
    event("bulletin:sendSuccess", themed("success"))
    event("bulletin:sendInfo", themed("info"))
    event("bulletin:sendWarning", themed("warning"))
    event("bulletin:sendError", themed("error"))
    event("bulletin:sendPinned", sendPinned)
    event("bulletin:unpin", unpin)
end)

----------------------------------------------------------------------
-- origen_notify
----------------------------------------------------------------------
registerResource("origen_notify", "origen_notify", function(export, event)
    export("ShowNotification", function(data)
        if type(data) == "table" then
            return NK.Notify(data)
        end
        return NK.Notify({ message = fromHtml(data) })
    end)
end)

----------------------------------------------------------------------
-- renzu_notify
----------------------------------------------------------------------
registerResource("renzu_notify", "renzu_notify", function(export, event)
    event("renzu_notify:Notify", function(type_, title, message, opts)
        opts = asTable(opts)

        local payload = {
            type    = toStr(type_),
            title   = fromHtml(title),
            message = fromHtml(message),
        }

        if opts.sticky == true then
            payload.persistent = true
        else
            payload.duration = toNum(opts.life)
        end

        if opts.progressbar ~= nil then
            payload.showProgress = opts.progressbar ~= false
        end

        return NK.Notify(payload)
    end)
end)

----------------------------------------------------------------------
-- Framework event compat (ox_lib / QBCore / ESX)
----------------------------------------------------------------------
registerEventCompat("ox_lib:notify", "oxlibEvents", { "ox_lib" }, {
    { "ox_lib:notify", function(data)
        return NK.OxLib(data)
    end },
    { "ox_lib:defaultNotify", function(data)
        if type(data) == "table" then
            data = Utils.Copy(data)
            data.type = data.status or data.type
        end
        return NK.OxLib(data)
    end },
})

registerEventCompat("QBCore:Notify", "qbcoreEvent", { "qb-core", "qbx_core" }, {
    { "QBCore:Notify", function(text, type_, length, icon)
        if type(text) == "string" then text = fromHtml(text) end
        return NK.QBCore(text, type_, length, icon)
    end },
})

registerEventCompat("esx:showNotification", "esxEvent", { "es_extended" }, {
    { "esx:showNotification", function(message, type_, length, title, position)
        if type(message) == "string" then message = fromHtml(message) end
        return NK.ESX(
            message,
            toStr(type_),
            toNum(length),
            type(title) == "string" and fromHtml(title) or nil,
            position
        )
    end },
    { "esx:showAdvancedNotification", function(sender, subject, message, textureDict)
        return NK.ESXAdvanced(fromHtml(sender), fromHtml(subject), fromHtml(message), textureDict)
    end },
})

----------------------------------------------------------------------
-- Lifecycle
----------------------------------------------------------------------
local function refreshForOwner(resourceName)
    for _, name in ipairs(order) do
        local entry = registry[name]
        if entry.kind == "event" and Utils.Contains(entry.owners, resourceName) then
            refreshEventStatus(entry)
        end
    end
end

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName == SELF_RESOURCE then return end

    local entry = registry[resourceName]
    if entry and entry.kind == "resource"
        and NK.Compat[resourceName] == "active"
        and isResourceStarted(resourceName) then
        NK.Compat[resourceName] = "standby"
        log("cp_standby", resourceName)
    end

    refreshForOwner(resourceName)
end)

AddEventHandler("onClientResourceStop", function(resourceName)
    if resourceName == SELF_RESOURCE then return end

    local entry = registry[resourceName]
    if entry and entry.kind == "resource" and NK.Compat[resourceName] == "standby" then
        activate(entry, true)
    end

    if resourceName == "ox_lib" or resourceName == "qb-core"
        or resourceName == "qbx_core" or resourceName == "es_extended" then
        SetTimeout(500, function() refreshForOwner(resourceName) end)
    end
end)

function NK.CompatList()
    local list = {}
    for _, name in ipairs(order) do
        local entry = registry[name]
        if entry.kind == "event" then refreshEventStatus(entry) end

        list[#list + 1] = {
            name   = name,
            status = NK.Compat[name],
            kind   = entry.kind,
            key    = entry.key,
            owner  = entry.owners and entry.owners[1] or nil,
        }
    end
    return list
end

exports("GetCompat", function()
    return NK.CompatList()
end)

CreateThread(function()
    Wait(5000)
    for _, name in ipairs(order) do
        local entry = registry[name]
        if entry.kind == "event" then
            refreshEventStatus(entry)
            if NK.Compat[name] == "active" then
                log("cp_event_active", name, entry.owners[1])
            end
        end
    end
end)

