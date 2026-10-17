

-- Cleaned from decompiled output: registers renamed, goto-ternaries turned into and/or,
-- and the duplicated Notify/Success/Error/Warning/Info and job/gang code folded into helpers.

local resourceName = GetCurrentResourceName()

NKServer = {}

local state = { look = nil }   -- server-wide notification look (persisted to data/settings.json)

local SETTINGS_FILE = 'data/settings.json'
local TAG = '^5[OXLYN-NOTIFYKIT]^7 '

-- ---------------------------------------------------------------------------
-- Persistence
-- ---------------------------------------------------------------------------

local function loadSettings()
    local raw = LoadResourceFile(resourceName, SETTINGS_FILE)
    if not raw or raw == '' then return end

    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' and type(data.look) == 'table' then
        local look = Utils.CleanLook(data.look)
        if next(look) then
            state.look = look
        end
    end
end

local function saveSettings()
    local saved = SaveResourceFile(resourceName, SETTINGS_FILE, json.encode({ look = state.look or {} }), -1)
    if not saved then
        Utils.Warn('could not write data/settings.json (does the data/ folder exist?)')
    end
end

loadSettings()

-- Pushes the current look to one player (or everyone when target is nil / -1)
local function sendLook(target)
    TriggerClientEvent('oxlyn-notifykit:look', target or -1, state.look or {})
end

RegisterNetEvent('oxlyn-notifykit:requestLook', function()
    local src = source
    sendLook(src)
    TriggerClientEvent('oxlyn-notifykit:admin', src, Bridge.IsAdmin(src))
end)

RegisterNetEvent('oxlyn-notifykit:requestAdmin', function()
    local src = source
    TriggerClientEvent('oxlyn-notifykit:admin', src, Bridge.IsAdmin(src))
end)

-- ---------------------------------------------------------------------------
-- Permissions
-- ---------------------------------------------------------------------------

local deniedLogAt = {}   -- per-player timestamp, so denied-access logs aren't spammed

-- Returns true when the player is DENIED (and tells them so)
local function denied(src)
    local isAdmin, reason = Bridge.IsAdmin(src)
    if isAdmin then return false end

    TriggerClientEvent('oxlyn-notifykit:feedback', src, 'msg_no_permission', 'error')

    local now = os.time()
    if now >= (deniedLogAt[src] or 0) + 20 then
        deniedLogAt[src] = now
        Utils.Info('%s (id %s) was denied admin access (%s) — run "%s %s" for the full report',
            Bridge.GetName(src), src, reason, Config.Commands.access or 'notifyaccess', src)
    end

    return true
end

AddEventHandler('playerDropped', function()
    deniedLogAt[source] = nil
end)

NKServer.Denied = denied

-- mode: 'none' | 'everyone' | anything else = admins only
local function allowed(mode, src)
    if mode == 'none' then return false end
    if mode == 'everyone' then return true end
    return Bridge.IsAdmin(src)
end

NKServer.Allowed = allowed

-- Console report explaining why a player does / doesn't count as admin
local function buildAccessReport(src)
    local eval = Bridge.EvaluateAdmin(src)
    local ace = Bridge.AdminConfig().ace
    local lines = {}

    lines[#lines + 1] = ('access report for %s (id %s) — framework %s%s'):format(
        Bridge.GetName(src), src, Bridge.framework,
        eval.group and (', group ' .. eval.group) or '')

    for _, source in ipairs(eval.sources) do
        lines[#lines + 1] = ('  %-11s %s  %s'):format(source.name, source.ok and '^2YES^7' or '^1no ^7', source.why)
    end

    lines[#lines + 1] = ('  RESULT      %s'):format(eval.allowed and ('^2ALLOWED^7 (' .. eval.reason .. ')') or '^1DENIED^7')

    if not eval.allowed then
        local license = eval.license or 'license:YOUR_LICENSE_HERE'
        lines[#lines + 1] = ('  to allow:   add_ace group.admin %s allow'):format(ace)
        lines[#lines + 1] = ('              add_principal identifier.%s group.admin'):format(license)
        lines[#lines + 1] = ("  or add to Config.Admin.identifiers:  '%s'"):format(license)
        lines[#lines + 1] = '  (an add_ace in server.cfg applies on the next full server start — paste both lines in the console to apply now)'
    end

    return lines
end

if Config.Commands.access and Config.Commands.access ~= '' then
    RegisterCommand(Config.Commands.access, function(src, args)
        local target = tonumber(args[1]) or src
        if target == 0 then target = nil end   -- console has no player to report on

        if src ~= 0 and not Bridge.IsAdmin(src) and not IsPlayerAceAllowed(src, 'command') then
            TriggerClientEvent('oxlyn-notifykit:feedback', src, 'msg_no_permission', 'error')
            return
        end

        if not (target and GetPlayerName(target)) then
            local usage = ('usage: %s <player id>'):format(Config.Commands.access)
            if src == 0 then
                print(TAG .. usage)
            else
                TriggerClientEvent('oxlyn-notifykit:feedbackRaw', src, usage, 'info')
            end
            return
        end

        local lines = buildAccessReport(target)
        for _, line in ipairs(lines) do
            print(TAG .. line)
        end

        -- In-game players get a colour-free copy as a notification (header line skipped)
        if src ~= 0 then
            local plain = {}
            for i, line in ipairs(lines) do
                plain[i] = line:gsub('%^%d', ''):gsub('^%s+', '')
            end

            local eval = Bridge.EvaluateAdmin(target)
            TriggerClientEvent('oxlyn-notifykit:notify', src, {
                type = eval.allowed and 'success' or 'warning',
                title = _U(eval.allowed and 'msg_access_allowed' or 'msg_access_denied', GetPlayerName(target) or target),
                message = table.concat(plain, '\n', 2),
                duration = 20000,
                markdown = false,
                _nohistory = true,
            })
        end
    end, false)
end

-- ---------------------------------------------------------------------------
-- Global look (saved by admins, pushed to everyone)
-- ---------------------------------------------------------------------------

RegisterNetEvent('oxlyn-notifykit:saveLook', function(data)
    local src = source
    local mode = Config.Permissions.globalStyle

    if mode == 'none' then return end
    if mode ~= 'everyone' and denied(src) then return end

    local look = Utils.CleanLook(data)
    if not next(look) then return end

    -- Is the payload nothing but a style change?
    local styleOnly = look.style ~= nil
    for key in pairs(look) do
        if key ~= 'style' then
            styleOnly = false
            break
        end
    end

    -- A style-only change layers onto the existing look; anything else replaces it
    if styleOnly and state.look then
        state.look = Utils.DeepMerge(state.look, look)
    else
        state.look = look
    end

    saveSettings()
    sendLook(-1)
    TriggerClientEvent('oxlyn-notifykit:feedback', src, 'msg_saved_all', 'success', #GetPlayers())
    Utils.Info('%s saved the server notification look (style: %s)',
        Bridge.GetName(src), tostring(state.look.style or Config.Look.style))
end)

RegisterNetEvent('oxlyn-notifykit:resetLook', function()
    local src = source
    if denied(src) then return end

    state.look = nil
    saveSettings()
    sendLook(-1)
    TriggerClientEvent('oxlyn-notifykit:feedback', src, 'msg_reset', 'success')
    Utils.Info('%s reset the server notification look', Bridge.GetName(src))
end)

-- ---------------------------------------------------------------------------
-- Payload helpers
-- ---------------------------------------------------------------------------

-- Deep copy that drops functions / callable tables (can't be sent to clients); depth-limited
local function sanitize(value, depth)
    depth = depth or 0
    local kind = type(value)

    if kind == 'function' then return nil end
    if kind ~= 'table' or depth > 8 then return value end

    local meta = getmetatable(value)
    if meta and meta.__call then return nil end

    local copy = {}
    for k, v in pairs(value) do
        local clean = sanitize(v, depth + 1)
        if clean ~= nil then copy[k] = clean end
    end
    return copy
end

-- Accepts either a full payload table or a plain message string
local function toPayload(data, notifyType, duration, title)
    if type(data) == 'table' then return sanitize(data) end
    if data == nil then return nil end

    return { message = tostring(data), type = notifyType, duration = duration, title = title }
end

-- Valid targets: -1 (everyone) or a positive integer player id
local function normalizeTarget(target)
    local id = tonumber(target)
    if id == -1 then return -1 end
    if id and id >= 1 and math.floor(id) == id then return id end
    return nil
end

-- Turns "police" / { 'police', 'ambulance' } / { police = 2 } into { name = minGrade }
local function buildGradeMap(input)
    local map = {}

    if type(input) == 'string' then
        map[input] = 0
    elseif type(input) == 'table' then
        if #input > 0 then
            for _, name in ipairs(input) do map[name] = 0 end
        else
            for name, grade in pairs(input) do map[name] = tonumber(grade) or 0 end
        end
    end

    return map
end

-- ---------------------------------------------------------------------------
-- Server API
-- ---------------------------------------------------------------------------

function NKServer.Notify(target, data, notifyType, duration, title)
    local payload = toPayload(data, notifyType, duration, title)
    local id = normalizeTarget(target)
    if not payload or not id then return false end

    TriggerClientEvent('oxlyn-notifykit:notify', id, payload)
    return true
end

function NKServer.NotifyAll(data, notifyType, duration, title)
    return NKServer.Notify(-1, data, notifyType, duration, title)
end

-- Notifies everyone whose job (and minimum grade) matches. Returns the number of recipients.
function NKServer.NotifyJob(jobs, data, requireDuty)
    local payload = toPayload(data)
    if not payload then return 0 end

    local minGrades = buildGradeMap(jobs)
    local count = 0

    for _, player in ipairs(GetPlayers()) do
        local id = tonumber(player)
        local job, grade, onDuty = Bridge.GetJob(id)

        if job and minGrades[job] then
            if (grade or 0) >= minGrades[job] and (not requireDuty or onDuty ~= false) then
                TriggerClientEvent('oxlyn-notifykit:notify', id, payload)
                count = count + 1
            end
        end
    end

    return count
end

function NKServer.NotifyGang(gangs, data)
    local payload = toPayload(data)
    if not payload then return 0 end

    local minGrades = buildGradeMap(gangs)
    local count = 0

    for _, player in ipairs(GetPlayers()) do
        local id = tonumber(player)
        local gang, grade = Bridge.GetGang(id)

        if gang and minGrades[gang] and (grade or 0) >= minGrades[gang] then
            TriggerClientEvent('oxlyn-notifykit:notify', id, payload)
            count = count + 1
        end
    end

    return count
end

-- Notifies everyone within `radius` of `coords` (vector3, {x,y,z} or {x,y,z} array)
function NKServer.NotifyRadius(coords, radius, data)
    local payload = toPayload(data)
    if not payload or not coords then return 0 end

    radius = tonumber(radius) or 50.0
    local x = coords.x or coords[1]
    local y = coords.y or coords[2]
    local z = coords.z or coords[3]

    local count = 0
    for _, player in ipairs(GetPlayers()) do
        local id = tonumber(player)
        local ped = GetPlayerPed(id)

        if ped and ped ~= 0 then
            local pos = GetEntityCoords(ped)
            local dx, dy = pos.x - x, pos.y - y
            local dz = pos.z - (z or pos.z)   -- no z given: ignore height

            if (dx * dx + dy * dy + dz * dz) <= radius * radius then
                TriggerClientEvent('oxlyn-notifykit:notify', id, payload)
                count = count + 1
            end
        end
    end

    return count
end

-- Notifies everyone who has the given ace permission
function NKServer.NotifyAce(ace, data)
    local payload = toPayload(data)
    if not payload or type(ace) ~= 'string' then return 0 end

    local count = 0
    for _, player in ipairs(GetPlayers()) do
        local id = tonumber(player)
        if IsPlayerAceAllowed(id, ace) then
            TriggerClientEvent('oxlyn-notifykit:notify', id, payload)
            count = count + 1
        end
    end

    return count
end

function NKServer.Announce(data, target)
    local payload = toPayload(data)
    local id = (target == nil) and -1 or normalizeTarget(target)
    if not payload or not id then return false end

    TriggerClientEvent('oxlyn-notifykit:announce', id, payload)
    return true
end

function NKServer.Update(target, notifId, data)
    local id = normalizeTarget(target)
    if not id then return false end

    TriggerClientEvent('oxlyn-notifykit:update', id, notifId, sanitize(data))
    return true
end

function NKServer.Progress(target, a, b, c)
    local id = normalizeTarget(target)
    if not id then return false end

    TriggerClientEvent('oxlyn-notifykit:progress', id, a, b, c)
    return true
end

function NKServer.Hide(target, notifId)
    local id = normalizeTarget(target)
    if not id then return false end

    TriggerClientEvent('oxlyn-notifykit:hide', id, notifId)
    return true
end

function NKServer.Clear(target, notifId)
    local id = normalizeTarget(target)
    if not id then return false end

    TriggerClientEvent('oxlyn-notifykit:clear', id, notifId)
    return true
end

-- ---------------------------------------------------------------------------
-- Confirm dialogs (server asks a player yes/no, answer comes back via callback)
-- ---------------------------------------------------------------------------

local pending = {}        -- [requestId] = { src, duration, expires, cb, check }
local requestCounter = 0

RegisterNetEvent('oxlyn-notifykit:confirmReply', function(requestId, answer)
    local src = source
    local entry = pending[requestId]
    if not (entry and entry.src == src) then return end   -- only the asked player may answer

    pending[requestId] = nil
    if answer ~= true and answer ~= false then answer = nil end
    entry.cb(answer)
end)

-- The client tells us when the dialog actually appeared, so the timeout starts from then
RegisterNetEvent('oxlyn-notifykit:confirmStarted', function(requestId)
    local src = source
    local entry = pending[requestId]
    if not (entry and entry.src == src) then return end

    entry.expires = GetGameTimer() + entry.duration + 5000
    if entry.check then
        SetTimeout(entry.duration + 5000, entry.check)
    end
end)

-- A player leaving counts as "no answer"
AddEventHandler('playerDropped', function()
    local src = source
    for requestId, entry in pairs(pending) do
        if entry.src == src then
            pending[requestId] = nil
            entry.cb(nil)
        end
    end
end)

function NKServer.ConfirmAsync(target, data, callback)
    target = tonumber(target)
    if not (target and GetPlayerName(target)) then
        if callback then callback(nil) end
        return nil
    end

    requestCounter = requestCounter + 1
    local requestId = ('%d:%d'):format(target, requestCounter)

    local payload = toPayload(data) or {}
    local duration = math.floor(Utils.Clamp(payload.duration or Config.Confirm.duration, 2000, 600000, 15000))

    local entry = {
        src = target,
        duration = duration,
        expires = GetGameTimer() + duration + 5000 + 120000,   -- generous until the client confirms it started
        cb = function(result)
            if callback then pcall(callback, result) end
        end,
    }
    pending[requestId] = entry

    TriggerClientEvent('oxlyn-notifykit:confirm', target, requestId, payload)

    -- Expiry watchdog: re-arms itself until the (possibly extended) deadline passes
    local function check()
        if pending[requestId] ~= entry then return end

        local remaining = entry.expires - GetGameTimer()
        if remaining > 0 then
            SetTimeout(remaining, check)
            return
        end

        pending[requestId] = nil
        entry.cb(nil)
    end

    entry.check = check
    SetTimeout(duration + 5000, check)

    return requestId
end

-- Blocking version: returns true / false / nil (nil = timeout, disconnect or invalid player)
function NKServer.Confirm(target, data)
    local p = promise.new()

    NKServer.ConfirmAsync(target, data, function(result)
        p:resolve({ result })   -- wrapped so a nil/false result survives the promise
    end)

    local resolved = Citizen.Await(p)
    return resolved and resolved[1]
end

function NKServer.SetLook(look)
    local clean = Utils.CleanLook(look)
    if not next(clean) then return false end

    state.look = Utils.DeepMerge(state.look or {}, clean)
    saveSettings()
    sendLook(-1)
    return true
end

-- ---------------------------------------------------------------------------
-- Exports
-- ---------------------------------------------------------------------------

exports('Notify', NKServer.Notify)
exports('NotifyAll', NKServer.NotifyAll)
exports('NotifyJob', NKServer.NotifyJob)
exports('NotifyGang', NKServer.NotifyGang)
exports('NotifyRadius', NKServer.NotifyRadius)
exports('NotifyAce', NKServer.NotifyAce)
exports('Announce', NKServer.Announce)
exports('Update', NKServer.Update)
exports('Progress', NKServer.Progress)
exports('Hide', NKServer.Hide)
exports('Clear', NKServer.Clear)
exports('Confirm', NKServer.Confirm)
exports('ConfirmAsync', NKServer.ConfirmAsync)

-- Typed shortcuts: Success / Error / Warning / Info(target, message, title, duration)
for exportName, notifyType in pairs({ Success = 'success', Error = 'error', Warning = 'warning', Info = 'info' }) do
    exports(exportName, function(target, message, title, duration)
        return NKServer.Notify(target, {
            message = message,
            title = title,
            duration = duration,
            type = notifyType,
        })
    end)
end

exports('SetLook', NKServer.SetLook)

exports('GetLook', function()
    return Utils.DeepMerge(Utils.DefaultLook(), state.look or {})
end)

exports('SetStyle', function(style)
    return NKServer.SetLook({ style = style })
end)

exports('IsAdmin', function(src)
    return Bridge.IsAdmin(src)
end)

exports('AccessReport', function(src)
    return Bridge.EvaluateAdmin(src)
end)

exports('GetStyles', function()
    return Utils.Copy(Utils.Styles)
end)

exports('GetTypes', function()
    return Utils.Types()
end)

-- ---------------------------------------------------------------------------
-- Broadcast from the in-game editor
-- ---------------------------------------------------------------------------

local broadcastAt = {}   -- per-player timestamp for the 2s cooldown

RegisterNetEvent('oxlyn-notifykit:broadcast', function(data, asAnnouncement)
    local src = source

    if not allowed(Config.Permissions.announce or 'admin', src) then
        denied(src)
        return
    end

    local now = os.time()
    if now < (broadcastAt[src] or 0) + 2 then return end
    broadcastAt[src] = now

    local payload = type(data) == 'table' and sanitize(data) or nil
    if not payload then return end

    payload.id = nil   -- never let a client pick the notification id

    if asAnnouncement then
        NKServer.Announce(payload)
    else
        NKServer.Notify(-1, payload)
    end

    TriggerClientEvent('oxlyn-notifykit:feedback', src, 'msg_sent_all', 'success', #GetPlayers())
    Utils.Info('%s sent a notification to everyone: %s',
        Bridge.GetName(src), tostring(payload.title or payload.message or ''):sub(1, 80))
end)

-- ---------------------------------------------------------------------------
-- Chat commands that open client-side UI
-- ---------------------------------------------------------------------------

local function registerUiCommand(name, permissionKey, action)
    if not name or name == '' then return end

    local baseMode = Config.Permissions[permissionKey] or 'admin'
    if baseMode == 'none' then return end

    RegisterCommand(name, function(src, args)
        if src == 0 then
            print(('%s/%s: %s'):format(TAG, name, _U('msg_ingame')))
            return
        end

        local mode = baseMode

        -- "/style global" is gated by its own permission
        if permissionKey == 'style' and Utils.Norm(args[2] or '') == 'global' then
            mode = Config.Permissions.globalStyle or 'admin'
        end

        if not allowed(mode, src) then
            denied(src)
            return
        end

        TriggerClientEvent('oxlyn-notifykit:command', src, action, args)
    end, false)
end

registerUiCommand(Config.Commands.editor, 'editor', 'editor')
registerUiCommand(Config.Commands.test, 'test', 'test')
registerUiCommand(Config.Commands.style, 'style', 'style')

if Config.History.enabled ~= false then
    registerUiCommand(Config.Commands.history, 'history', 'history')
end

-- /announce <message>
if Config.Commands.announce and Config.Commands.announce ~= ''
    and Config.Permissions.announce ~= 'none' then

    RegisterCommand(Config.Commands.announce, function(src, args, rawCommand)
        if src ~= 0 and not allowed(Config.Permissions.announce, src) then
            denied(src)
            return
        end

        -- raw command is "announce some text": strip the command word
        local message = (rawCommand or ''):gsub('^%S+%s*', '')

        if message == '' then
            local usage = ('usage: /%s <message>'):format(Config.Commands.announce)
            if src == 0 then
                print(TAG .. usage)
            else
                TriggerClientEvent('oxlyn-notifykit:feedbackRaw', src, usage, 'info')
            end
            return
        end

        NKServer.Announce({ title = _U('announce_title'), message = message })
        Utils.Info('%s announced: %s', src == 0 and 'console' or Bridge.GetName(src), message:sub(1, 120))
    end, false)
end

-- ---------------------------------------------------------------------------
-- Startup banner
-- ---------------------------------------------------------------------------

CreateThread(function()
    Wait(0)

    local version = GetResourceMetadata(resourceName, 'version', 0) or '?'
    local style = (state.look and state.look.style) or Config.Look.style

    print((TAG .. 'v%s  framework=^3%s^7  locale=^3%s^7  style=^3%s^7  styles=^3%d^7'):format(
        version, Bridge.framework, GetCurrentLocale(), style, #Utils.Styles))
end)

