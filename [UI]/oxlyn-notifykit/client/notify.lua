

-- oxlyn-notifykit | client notify / confirm (cleaned from decompiled output)

local limits = Config.Limits or {}

---------------------------------------------------------------------
-- Sanitizing helpers
---------------------------------------------------------------------

-- Accepts a string or number, returns a string truncated to maxLen (nil for anything else)
local function clampString(value, maxLen)
    if type(value) == "number" then
        value = tostring(value)
    end

    if type(value) ~= "string" then
        return nil
    end

    if maxLen and #value > maxLen then
        value = value:sub(1, maxLen)
    end

    return value
end

-- Icon may be: false (no icon), a string, or a FontAwesome-style table
--   { "fas", "heart" } / { prefix = "fas", name = "heart" } / { prefix = "fas", iconName = "heart" }
local function normalizeIcon(icon)
    if icon == false then
        return false
    end

    if type(icon) == "string" then
        return clampString(icon, 300)
    end

    if type(icon) == "table" then
        local prefix = icon.prefix or icon[1]
        local name   = icon.name or icon.iconName or icon[2]

        if type(prefix) == "string" and type(name) == "string" then
            return prefix .. " " .. name
        end

        if type(prefix) == "string" then
            return prefix
        end
    end

    return nil
end

---------------------------------------------------------------------
-- NK.Normalize
--   Turns any accepted input (string or loosely-named table) into a
--   clean payload for the NUI. Returns nil if there is nothing to show
--   (unless allowEmpty is true).
---------------------------------------------------------------------

function NK.Normalize(input, kind, duration, title, allowEmpty)
    if type(input) ~= "table" then
        if input == nil then
            return nil
        end

        input = {
            message  = tostring(input),
            type     = kind,
            duration = duration,
            title    = title,
        }
    else
        input = NK.Clean(input) or {}
    end

    local out = {}

    out.id = (type(input.id) == "string" or type(input.id) == "number") and tostring(input.id) or nil

    out.type     = Utils.TypeName(input.type or input.status or input.notifyType, NK.types)
    out.title    = clampString(input.title or input.header or input.caption, limits.titleLength or 120)
    out.message  = clampString(
        input.message or input.description or input.text or input.msg or input.content,
        limits.messageLength or 600
    )
    out.subtitle = clampString(input.subtitle or input.subject, 160)
    out.label    = clampString(input.label or input.kicker, 60)
    out.value    = clampString(input.value or input.amount, 24)
    out.app      = clampString(input.app, 40)
    out.time     = clampString(input.time, 24)
    out.image    = clampString(input.image, 600)
    out.avatar   = clampString(input.avatar, 600)

    out.icon      = normalizeIcon(input.icon)
    out.iconColor = clampString(input.iconColor, 40)
    out.iconAnimation = (Utils.Contains(Utils.IconAnimations, input.iconAnimation) and input.iconAnimation) or nil
    out.color     = clampString(input.color, 40)

    if input.style ~= nil and Utils.IsStyle(input.style) then
        out.style = input.style
    end

    out.position = Utils.Position(input.position)

    -- Duration: <= 0 means persistent, otherwise clamp to 0.8s .. 1h
    local d = tonumber(input.duration or input.length or input.time_ms or input.timeout)
    if d then
        if d <= 0 then
            out.persistent = true
        else
            out.duration = math.floor(Utils.Clamp(d, 800, 3600000, 5000))
        end
    end

    if input.persistent == true or input.sticky == true then
        out.persistent = true
    end

    if input.showProgress ~= nil then
        out.showProgress = (input.showProgress ~= false)
    end

    if input.showDuration ~= nil then
        out.showProgress = (input.showDuration ~= false)
    end

    if input.progress ~= nil then
        out.progress = Utils.Clamp(input.progress, 0, 100, 0)
    end

    if input.dedupe == false then
        out.dedupe = false
    end

    if input.markdown == false then
        out.markdown = false
    end

    if input.html == true and Config.Limits.allowHTML then
        out.html = true
    end

    if input.force == true or input.priority == "high" then
        out.force = true
    end

    -- Sound: false = silent, string = NUI sound file, table = GTA game sound
    if input.sound ~= nil then
        if input.sound == false then
            out.sound = "none"
        elseif type(input.sound) == "string" then
            out.sound = clampString(input.sound, 300)
        elseif type(input.sound) == "table" then
            out.gameSound = input.sound
        end
    end

    -- Internal flags
    if input._announce then out._announce = true end
    if input._nohistory then out._nohistory = true end

    if not allowEmpty and not (out.title or out.message or out.progress ~= nil) then
        return nil
    end

    return out
end

---------------------------------------------------------------------
-- Rate limiting + queue
---------------------------------------------------------------------

local sentAt        = {}     -- timestamps of notifications sent in the last second
local queue         = {}     -- pending notifications (payloads) and ops ({ _op, payload })
local workerRunning = false

-- True if we're under the per-second limit (also prunes old timestamps)
local function canSendNow()
    local now   = GetGameTimer()
    local count = 0

    for i = #sentAt, 1, -1 do
        if now - sentAt[i] < 1000 then
            count = count + 1
        else
            table.remove(sentAt, i)
        end
    end

    return count < (limits.perSecond or 8)
end

-- Sends one notification to the NUI (and plays its game sound, if any)
local function dispatch(payload)
    sentAt[#sentAt + 1] = GetGameTimer()

    local gameSound = payload.gameSound
    if gameSound then
        payload.gameSound = nil
        payload.sound = "none" -- NUI must not play its own sound

        local soundsEnabled = (NK.look or {}).sounds ~= false

        if not NK.personal.mute and soundsEnabled and type(gameSound.name) == "string" then
            CreateThread(function()
                if gameSound.bank then
                    RequestScriptAudioBank(gameSound.bank, false)
                end

                local soundId = GetSoundId()
                PlaySoundFrontend(soundId, gameSound.name, gameSound.set, true)
                ReleaseSoundId(soundId)

                if gameSound.bank then
                    ReleaseNamedScriptAudioBank(gameSound.bank)
                end
            end)
        end
    end

    NK.Send("notify", payload)
end

local function startQueueWorker()
    if workerRunning then return end
    workerRunning = true

    CreateThread(function()
        while #queue > 0 do
            -- Ops (update/hide/etc.) at the front go out immediately
            while queue[1] and queue[1]._op do
                local item = table.remove(queue, 1)
                NK.Send(item._op, item.payload)
            end

            if queue[1] and canSendNow() then
                dispatch(table.remove(queue, 1))
            end

            if #queue > 0 then
                Wait(1000 / math.max(1, limits.perSecond or 8))
            end
        end

        workerRunning = false
    end)
end

-- Sends an op (update/progress/hide/clear) directly, or behind queued
-- notifications so ordering is preserved.
local function sendOrQueueOp(op, payload)
    if #queue == 0 then
        NK.Send(op, payload)
        return
    end

    queue[#queue + 1] = { _op = op, payload = payload }
    startQueueWorker()
end

---------------------------------------------------------------------
-- NK.Notify and shortcuts
---------------------------------------------------------------------

-- Returns the notification id, or nil if nothing was shown
function NK.Notify(input, kind, duration, title)
    local payload = NK.Normalize(input, kind, duration, title)
    if not payload then
        return nil
    end

    -- NOTE: the decompiled "if canSend then (if queue empty then dispatch) else queue"
    -- is read here as "send now only if under the limit AND nothing is waiting".
    if canSendNow() and #queue == 0 then
        dispatch(payload)
    else
        queue[#queue + 1] = payload

        -- Drop the oldest queued notifications if the queue is too long
        local maxQueued = limits.queueMax or 30
        local waiting = 0

        for i = 1, #queue do
            if not queue[i]._op then
                waiting = waiting + 1
            end
        end

        local i = 1
        while waiting > maxQueued and i <= #queue do
            if not queue[i]._op then
                table.remove(queue, i)
                waiting = waiting - 1
            else
                i = i + 1
            end
        end

        startQueueWorker()
    end

    return payload.id
end

local function makeTypeNotifier(kind)
    return function(a, b, c)
        if type(a) == "table" then
            local copy = Utils.Copy(a)
            copy.type = kind
            return NK.Notify(copy)
        end

        return NK.Notify({ message = a, title = b, duration = c, type = kind })
    end
end

NK.Success = makeTypeNotifier("success")
NK.Error   = makeTypeNotifier("error")
NK.Warning = makeTypeNotifier("warning")
NK.Info    = makeTypeNotifier("info")

---------------------------------------------------------------------
-- Update / Progress / Hide / Clear
---------------------------------------------------------------------

-- Input key (any accepted alias) -> normalized payload key
local UPDATE_FIELDS = {
    title = "title", header = "title", caption = "title",
    message = "message", description = "message", text = "message", msg = "message", content = "message",
    subtitle = "subtitle", subject = "subtitle",
    label = "label", kicker = "label",
    value = "value", amount = "value",
    icon = "icon", iconColor = "iconColor", iconAnimation = "iconAnimation",
    color = "color", type = "type",
    image = "image", avatar = "avatar",
    progress = "progress", duration = "duration",
    app = "app", time = "time", style = "style",
    showProgress = "showProgress",
}

function NK.Update(id, data)
    if id == nil then
        return false
    end

    if type(data) == "string" then
        data = { message = data }
    end

    if type(data) ~= "table" then
        return false
    end

    local normalized = NK.Normalize(data, nil, nil, nil, true) or {}
    local patch = {}

    for inputKey, outKey in pairs(UPDATE_FIELDS) do
        if data[inputKey] ~= nil then
            patch[outKey] = normalized[outKey]
        end
    end

    if data.duration ~= nil and normalized.persistent then
        patch.persistent = true
    end

    if data.persistent ~= nil then
        patch.persistent = (data.persistent == true)
    end

    if data.keepTimer then
        patch.keepTimer = true
    end

    if data.autoClose == false then
        patch.autoClose = false
    end

    sendOrQueueOp("update", { id = tostring(id), patch = patch })
    return true
end

function NK.Progress(id, value, text)
    if id == nil then
        return false
    end

    sendOrQueueOp("progress", {
        id    = tostring(id),
        value = Utils.Clamp(value, 0, 100, 0),
        text  = clampString(text, limits.messageLength or 600),
    })

    return true
end

function NK.Hide(id)
    if id == nil then
        return false
    end

    sendOrQueueOp("hide", { id = tostring(id) })
    return true
end

function NK.Clear(position)
    sendOrQueueOp("clear", { position = Utils.Position(position) })
end

---------------------------------------------------------------------
-- Announce, DND, mute, test
---------------------------------------------------------------------

function NK.Announce(data, title, duration)
    local cfg = Config.Announce or {}

    if type(data) ~= "table" then
        data = { message = data, title = title, duration = duration }
    end

    local copy = Utils.Copy(data)

    copy.style    = copy.style or cfg.style
    copy.position = copy.position or cfg.position
    copy.duration = copy.duration or cfg.duration
    copy.type     = copy.type or cfg.type or "announce"

    if copy.sound == nil then
        copy.sound = cfg.sound
    end

    copy._announce = true

    return NK.Notify(copy)
end

function NK.SetDnd(enabled)
    NK.SetPersonal({ dnd = (enabled == true) })
end

function NK.SetMute(enabled)
    NK.SetPersonal({ mute = (enabled == true) })
end

function NK.Test(style, kind)
    NK.Send("test", {
        style = (style and Utils.IsStyle(style)) and style or nil,
        type  = kind,
    })
end

---------------------------------------------------------------------
-- Compatibility adapters (ox_lib / ESX / QBCore)
---------------------------------------------------------------------

function NK.OxLib(data)
    if type(data) ~= "table" then
        return NK.Notify(data)
    end

    local copy = Utils.Copy(data)
    copy.type = copy.type or copy.status

    -- ox_lib style is a CSS table; ours is a style name
    if type(copy.style) == "table" then
        copy.style = nil
    end

    return NK.Notify(copy)
end

function NK.ESX(message, kind, duration, title, position)
    if type(message) == "table" then
        return NK.Notify(message)
    end

    return NK.Notify({
        message  = message,
        type     = kind,
        duration = duration,
        title    = title,
        position = position,
    })
end

function NK.ESXAdvanced(title, subtitle, message, icon)
    local data = {
        title    = title,
        subtitle = subtitle,
        message  = message,
        type     = "message",
    }

    if type(icon) == "string" and icon ~= "" then
        data.avatar = ("https://nui-img/%s/%s"):format(icon, icon)
    end

    return NK.Notify(data)
end

function NK.QBCore(text, kind, length, icon)
    local data = { type = kind, duration = length }

    if type(text) == "table" then
        data.message = text.text or text.message
        data.title   = text.caption or text.title
    else
        data.message = text
    end

    if type(icon) == "string" and icon ~= "" then
        data.icon = icon
    end

    return NK.Notify(data)
end

---------------------------------------------------------------------
-- Confirm dialogs (accept / decline with a key press)
---------------------------------------------------------------------

local confirmQueue         = {}
local confirmCounter       = 0
local confirmWorkerRunning = false
local currentConfirm       = nil

local function isKeyDown(vk)
    return (vk and IsRawKeyDown(vk)) or false
end

local function startConfirmWorker()
    if confirmWorkerRunning then return end
    confirmWorkerRunning = true

    CreateThread(function()
        while #confirmQueue > 0 do
            local req = table.remove(confirmQueue, 1)
            local cfg = Config.Confirm or {}

            local acceptKey  = req.data.acceptKey or cfg.acceptKey or "Y"
            local declineKey = req.data.declineKey or cfg.declineKey or "N"

            local acceptVK     = Keys.VKOf(acceptKey)
            local declineVK    = Keys.VKOf(declineKey)
            local acceptCtrls  = Keys.ControlsOf(acceptKey)
            local declineCtrls = Keys.ControlsOf(declineKey)

            local duration = math.floor(Utils.Clamp(req.data.duration or cfg.duration, 2000, 600000, 15000))

            local payload = NK.Normalize(Utils.Merge({ type = cfg.type or "primary" }, req.data))
                or { message = " " }

            payload.id          = req.id
            payload.duration    = duration
            payload.acceptKey   = Keys.Label(acceptKey)
            payload.declineKey  = Keys.Label(declineKey)
            payload.acceptText  = clampString(req.data.acceptText or req.data.accept, 40)
            payload.declineText = clampString(req.data.declineText or req.data.decline, 40)
            payload.force       = true

            NK.Send("confirm", payload)

            currentConfirm = req

            if req.onStart then
                pcall(req.onStart)
            end

            local endTime         = GetGameTimer() + duration
            local acceptWasDown   = isKeyDown(acceptVK)
            local declineWasDown  = isKeyDown(declineVK)
            local answer          = nil -- true = accepted, false = declined, nil = timeout/cancelled

            while endTime > GetGameTimer() do
                -- Stop the game from reacting to the accept/decline keys
                if cfg.disableGameControls ~= false then
                    for _, control in ipairs(acceptCtrls) do
                        DisableControlAction(0, control, true)
                    end

                    for _, control in ipairs(declineCtrls) do
                        DisableControlAction(0, control, true)
                    end
                end

                local blocked = IsNuiFocused() or IsPauseMenuActive()

                local acceptDown  = isKeyDown(acceptVK)
                local declineDown = isKeyDown(declineVK)

                if not blocked then
                    -- Only react to a fresh key press (rising edge)
                    if acceptDown and not acceptWasDown then
                        answer = true
                        break
                    end

                    if declineDown and not declineWasDown then
                        answer = false
                        break
                    end
                end

                acceptWasDown  = acceptDown
                declineWasDown = declineDown

                if req.cancelled then
                    break
                end

                Wait(0)
            end

            currentConfirm = nil

            NK.Send("confirmAnswer", { id = req.id, answer = answer })

            if not NK.personal.mute and (NK.look or {}).sounds ~= false and answer ~= nil then
                NK.Send("sound", { name = answer and "success" or "soft" })
            end

            req.resolve(answer)
            Wait(250)
        end

        confirmWorkerRunning = false
    end)
end

-- Non-blocking. `callback(answer)` receives true / false / nil (timeout).
-- Also supports data.onAccept / onDecline / onTimeout. Returns the request id.
function NK.ConfirmAsync(data, callback)
    if type(data) ~= "table" then
        data = { message = tostring(data or "") }
    end

    confirmCounter = confirmCounter + 1

    local req = {
        id      = "confirm:" .. confirmCounter,
        data    = NK.Clean(data) or {},
        onStart = (NK.Callable(data._onStart) and data._onStart) or nil,
    }

    req.resolve = function(answer)
        if NK.Callable(data.onAccept) and answer == true then
            pcall(data.onAccept)
        end

        if NK.Callable(data.onDecline) and answer == false then
            pcall(data.onDecline)
        end

        if NK.Callable(data.onTimeout) and answer == nil then
            pcall(data.onTimeout)
        end

        if NK.Callable(callback) then
            pcall(callback, answer)
        end
    end

    confirmQueue[#confirmQueue + 1] = req
    startConfirmWorker()

    return req.id
end

-- NUI says the dialog disappeared (e.g. closed by the UI) -> stop waiting
RegisterNUICallback("confirmGone", function(data, cb)
    cb(1)

    local id = (type(data) == "table" and data.id) or nil

    if currentConfirm and currentConfirm.id == id then
        currentConfirm.cancelled = true
    end
end)

-- Blocking version: waits for the answer (true / false / nil)
function NK.Confirm(data)
    local p = promise.new()

    NK.ConfirmAsync(data, function(answer)
        -- wrapped in a table so a nil answer still resolves the promise
        p:resolve({ answer })
    end)

    local result = Citizen.Await(p)
    return result and result[1]
end

-- Server-triggered confirm: reports start + answer back to the server
RegisterNetEvent("oxlyn-notifykit:confirm", function(requestId, data)
    if type(data) ~= "table" then
        data = { message = tostring(data or "") }
    end

    data._onStart = function()
        TriggerServerEvent("oxlyn-notifykit:confirmStarted", requestId)
    end

    NK.ConfirmAsync(data, function(answer)
        TriggerServerEvent("oxlyn-notifykit:confirmReply", requestId, answer)
    end)
end)

---------------------------------------------------------------------
-- Net events
---------------------------------------------------------------------

RegisterNetEvent("oxlyn-notifykit:notify", function(input, kind, duration, title)
    NK.Notify(input, kind, duration, title)
end)

RegisterNetEvent("oxlyn-notifykit:update", function(id, data)
    NK.Update(id, data)
end)

RegisterNetEvent("oxlyn-notifykit:progress", function(id, value, text)
    NK.Progress(id, value, text)
end)

RegisterNetEvent("oxlyn-notifykit:hide", function(id)
    NK.Hide(id)
end)

RegisterNetEvent("oxlyn-notifykit:clear", function(position)
    NK.Clear(position)
end)

RegisterNetEvent("oxlyn-notifykit:announce", function(data)
    NK.Announce(data)
end)

---------------------------------------------------------------------
-- Exports
---------------------------------------------------------------------

exports("Notify", NK.Notify)
exports("Success", NK.Success)
exports("Error", NK.Error)
exports("Warning", NK.Warning)
exports("Info", NK.Info)
exports("Update", NK.Update)
exports("Progress", NK.Progress)
exports("Hide", NK.Hide)
exports("Clear", NK.Clear)
exports("Announce", NK.Announce)
exports("Confirm", NK.Confirm)
exports("ConfirmAsync", NK.ConfirmAsync)
exports("Test", NK.Test)
exports("SetDnd", NK.SetDnd)
exports("SetMute", NK.SetMute)

exports("GetPersonal", function()
    return Utils.Copy(NK.personal)
end)

-- Framework / library compatibility
exports("OxLib", NK.OxLib)
exports("ESX", NK.ESX)
exports("ESXAdvanced", NK.ESXAdvanced)
exports("QBCore", NK.QBCore)

-- Read-only data getters
exports("GetStyles", function()
    return Utils.Copy(Utils.Styles)
end)

exports("GetStyleGroups", function()
    return Utils.Copy(Utils.StyleGroups)
end)

exports("GetTypes", function()
    return Utils.Copy(NK.types)
end)

exports("GetPositions", function()
    return Utils.Copy(Utils.Positions)
end)

exports("GetLook", function()
    return Utils.Copy(NK.look)
end)

exports("SetStyle", NK.SetStyle)
exports("SetPersonalLook", NK.SetPersonalLook)

