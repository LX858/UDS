

-- oxlyn-notifykit | client core (cleaned from decompiled output)

NK = {
    ready        = false,
    isAdmin      = false,
    serverLook   = nil,   -- look set by the server (global)
    personalLook = nil,   -- look set by this player
    look         = nil,   -- merged result (default + server + personal)
    types        = nil,
    liveCount    = 0,     -- number of notifications currently on screen
}

local RESOURCE = GetCurrentResourceName()
NK.resource = RESOURCE

local LOOK_KEY     = "oxlyn-notifykit:look"
local PERSONAL_KEY = "oxlyn-notifykit:personal"

---------------------------------------------------------------------
-- NUI message queue
--   * before the NUI is ready, messages wait in `pending`
--   * afterwards they are batched into one SendNUIMessage per tick
---------------------------------------------------------------------

local pending        = {}
local outbox         = {}
local flushScheduled = false

local function flushOutbox()
    flushScheduled = false

    if #outbox == 0 then return end

    local batch = outbox
    outbox = {}

    if #batch == 1 then
        SendNUIMessage({ action = batch[1].a, data = batch[1].d })
    else
        SendNUIMessage({ action = "batch", data = batch })
    end
end

function NK.Send(action, data)
    if not NK.ready then
        pending[#pending + 1] = { a = action, d = data }
        return
    end

    outbox[#outbox + 1] = { a = action, d = data }

    if not flushScheduled then
        flushScheduled = true
        SetTimeout(0, flushOutbox)
    end
end

---------------------------------------------------------------------
-- Utility helpers
---------------------------------------------------------------------

-- Deep-copies a value into something safe to send to the NUI:
-- strips functions/userdata/threads, callable tables, and caps depth at 8.
function NK.Clean(value, depth)
    depth = depth or 0

    local t = type(value)

    if t == "function" or t == "userdata" or t == "thread" then
        return nil
    end

    if t ~= "table" then
        return value
    end

    if depth > 8 then
        return nil
    end

    local mt = getmetatable(value)
    if mt and mt.__call then
        return nil
    end

    local copy = {}
    for k, v in pairs(value) do
        local cleaned = NK.Clean(v, depth + 1)
        if cleaned ~= nil then
            copy[k] = cleaned
        end
    end

    return copy
end

function NK.Callable(value)
    if type(value) == "function" then
        return true
    end

    if type(value) == "table" then
        return getmetatable(value) ~= nil
    end

    return false
end

---------------------------------------------------------------------
-- NUI focus management (multiple panels can hold focus at once)
---------------------------------------------------------------------

local focusOwners = {}

local function updateFocus()
    local any       = false
    local cursor    = false
    local keepInput = true

    for _, owner in pairs(focusOwners) do
        any = true

        if owner.cursor then
            cursor = true
        end

        if not owner.keepInput then
            keepInput = false
        end
    end

    SetNuiFocus(any, any and cursor)
    SetNuiFocusKeepInput(any and keepInput)
end

function NK.Focus(name, cursor, keepInput)
    focusOwners[name] = {
        cursor    = (cursor ~= false),
        keepInput = (keepInput == true),
    }
    updateFocus()
end

function NK.Blur(name)
    if not focusOwners[name] then return end

    focusOwners[name] = nil
    updateFocus()
end

function NK.HasFocus(name)
    if name then
        return focusOwners[name] ~= nil
    end

    return next(focusOwners) ~= nil
end

---------------------------------------------------------------------
-- Look (theme) handling
---------------------------------------------------------------------

-- Loads the player's saved personal look from KVP
local function loadPersonalLook()
    if not Config.AllowPlayerSettings then
        return nil
    end

    local raw = GetResourceKvpString(LOOK_KEY)
    if not raw or raw == "" then
        return nil
    end

    local ok, decoded = pcall(json.decode, raw)

    if ok and type(decoded) == "table" then
        local look = Utils.CleanLook(decoded)
        look.types = nil

        if next(look) then
            return look
        end
    end

    return nil
end

-- Rebuilds NK.look = default + server look + personal look, then pushes it to the NUI
function NK.ApplyLook()
    local look = Utils.DefaultLook()

    if NK.serverLook then
        look = Utils.DeepMerge(look, NK.serverLook)
    end

    if Config.AllowPlayerSettings and NK.personalLook then
        look = Utils.DeepMerge(look, NK.personalLook)
    end

    NK.look = look
    NK.Send("look", look)

    if NK.OnLookChanged then
        NK.OnLookChanged(look)
    end
end

function NK.GetLook()
    return NK.look
end

-- Pass nil to clear the personal look
function NK.SetPersonalLook(look)
    if not Config.AllowPlayerSettings then
        return false
    end

    if look == nil then
        NK.personalLook = nil
        DeleteResourceKvp(LOOK_KEY)
    else
        local cleaned = Utils.CleanLook(look)
        cleaned.types = nil

        NK.personalLook = next(cleaned) and cleaned or nil

        if NK.personalLook then
            SetResourceKvp(LOOK_KEY, json.encode(NK.personalLook))
        else
            DeleteResourceKvp(LOOK_KEY)
        end
    end

    NK.ApplyLook()
    return true
end

-- Sets only the personal style (nil clears it)
function NK.SetStyle(style)
    if style ~= nil and not Utils.IsStyle(style) then
        return false
    end

    if not Config.AllowPlayerSettings then
        return false
    end

    local look = NK.personalLook and Utils.Copy(NK.personalLook) or {}
    look.style = style

    return NK.SetPersonalLook(next(look) and look or nil)
end

NK.personalLook = loadPersonalLook()
NK.types        = Utils.Types()

RegisterNetEvent("oxlyn-notifykit:look", function(look)
    local cleaned = (type(look) == "table" and Utils.CleanLook(look)) or nil

    NK.serverLook = (cleaned and next(cleaned)) and cleaned or nil
    NK.ApplyLook()
end)

RegisterNetEvent("oxlyn-notifykit:admin", function(isAdmin)
    NK.isAdmin = (isAdmin == true)
    NK.Send("admin", { admin = NK.isAdmin })
end)

---------------------------------------------------------------------
-- Personal settings (do-not-disturb / mute)
---------------------------------------------------------------------

NK.personal = { dnd = false, mute = false }

do
    local raw = GetResourceKvpString(PERSONAL_KEY)

    if raw and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)

        if ok and type(decoded) == "table" then
            NK.personal.dnd  = (decoded.dnd == true)
            NK.personal.mute = (decoded.mute == true)
        end
    end
end

function NK.SetPersonal(data)
    if type(data) ~= "table" then return end

    if data.dnd ~= nil then
        NK.personal.dnd = (data.dnd == true)
    end

    if data.mute ~= nil then
        NK.personal.mute = (data.mute == true)
    end

    SetResourceKvp(PERSONAL_KEY, json.encode(NK.personal))
    NK.Send("personal", NK.personal)
end

---------------------------------------------------------------------
-- NUI init payload + ready/log callbacks
---------------------------------------------------------------------

local function buildInitPayload()
    local limits  = Config.Limits
    local confirm = Config.Confirm
    local history = Config.History

    return {
        resource            = RESOURCE,
        lang                = GetCurrentLocale(),
        locale              = GetLocaleTable(),
        styles              = Utils.Styles,
        types               = NK.types,
        typeList            = Utils.TypeList(NK.types),
        look                = NK.look,
        admin               = NK.isAdmin,
        allowPlayerSettings = (Config.AllowPlayerSettings == true),

        limits = {
            allowHTML     = (limits.allowHTML == true),
            titleLength   = limits.titleLength or 120,
            messageLength = limits.messageLength or 600,
        },

        confirm = {
            acceptKey  = Keys.Label(confirm.acceptKey or "Y"),
            declineKey = Keys.Label(confirm.declineKey or "N"),
            type       = confirm.type or "primary",
        },

        history = {
            enabled  = (history.enabled ~= false),
            max      = history.max or 60,
            allowDnd = (history.allowDnd ~= false),
        },

        debug = (Config.Debug == true),
    }
end

RegisterNUICallback("ready", function(_, cb)
    cb(1)

    if not NK.look then
        NK.ApplyLook()
    end

    -- Sent directly (not via NK.Send) because the queue isn't open yet
    SendNUIMessage({ action = "init",     data = buildInitPayload() })
    SendNUIMessage({ action = "personal", data = NK.personal })

    NK.ready = true

    -- Flush everything that was queued before the NUI was ready
    local queued = pending
    pending = {}

    for i = 1, #queued do
        NK.Send(queued[i].a, queued[i].d)
    end

    Utils.Debug("NUI ready")
end)

RegisterNUICallback("log", function(data, cb)
    cb(1)

    if Config.Debug then
        print(("^5[OXLYN-NOTIFYKIT NUI]^7 %s"):format(tostring(data and data.msg)))
    end
end)

-- Initial look + ask the server for the global look
CreateThread(function()
    NK.ApplyLook()
    Wait(500)
    TriggerServerEvent("oxlyn-notifykit:requestLook")
end)

---------------------------------------------------------------------
-- Visibility watcher (hide UI during pause menu / screen fades)
---------------------------------------------------------------------

local watcherRunning = false
local uiVisible      = true

local function setVisible(visible)
    if visible == uiVisible then return end

    uiVisible = visible
    NK.Send("visible", { visible = visible })
end

local function startVisibilityWatcher()
    if watcherRunning then return end
    watcherRunning = true

    CreateThread(function()
        while NK.liveCount > 0 do
            local look   = NK.look or {}
            local hidden = false

            if look.hideInPause ~= false then
                hidden = IsPauseMenuActive() or IsScreenFadedOut() or IsScreenFadingOut()
            end

            setVisible(not hidden)
            Wait(250)
        end

        setVisible(true)
        watcherRunning = false
    end)
end

RegisterNUICallback("count", function(data, cb)
    cb(1)

    NK.liveCount = tonumber(data and data.n) or 0

    if NK.liveCount > 0 then
        startVisibilityWatcher()
    end
end)

---------------------------------------------------------------------
-- Game sounds
---------------------------------------------------------------------

function NK.PlayGameSound(name)
    local sound = Config.GameSounds and Config.GameSounds[name]

    if type(sound) ~= "table" or not sound[1] then
        return
    end

    local soundId = GetSoundId()
    PlaySoundFrontend(soundId, sound[1], sound[2], true)
    ReleaseSoundId(soundId)
end

RegisterNUICallback("gameSound", function(data, cb)
    cb(1)

    if NK.personal.mute then return end

    if type(data) == "table" and type(data.name) == "string" then
        NK.PlayGameSound(data.name)
    end
end)

---------------------------------------------------------------------
-- Feedback messages
---------------------------------------------------------------------

function NK.Feedback(message, kind)
    if NK.Notify then
        NK.Notify({
            message    = message,
            type       = kind or "system",
            duration   = 4500,
            _nohistory = true,
        })
    else
        print(("^5[OXLYN-NOTIFYKIT]^7 %s"):format(tostring(message)))
    end
end

-- Server sends a locale key (+ format args)
RegisterNetEvent("oxlyn-notifykit:feedback", function(key, kind, ...)
    NK.Feedback(_U(key, ...), kind)
end)

-- Server sends already-formatted text
RegisterNetEvent("oxlyn-notifykit:feedbackRaw", function(text, kind)
    NK.Feedback(tostring(text), kind)
end)

---------------------------------------------------------------------
-- Chat command suggestions
---------------------------------------------------------------------

CreateThread(function()
    Wait(1500) -- let the chat resource load first

    local cmds  = Config.Commands
    local perms = Config.Permissions

    local function suggest(name, helpKey, params)
        if not name or name == "" then return end

        pcall(TriggerEvent, "chat:addSuggestion", "/" .. name, _U(helpKey), params)
    end

    if perms.editor ~= "none" then
        suggest(cmds.editor, "cmd_editor")
    end

    if perms.test ~= "none" then
        suggest(cmds.test, "cmd_test", {
            { name = "style", help = "optional style name" },
            { name = "type",  help = "optional type" },
        })
    end

    if perms.style ~= "none" then
        suggest(cmds.style, "cmd_style", {
            { name = "style",  help = "style name (see /" .. (cmds.test or "notifytest") .. ")" },
            { name = "global", help = 'admin: "global" applies to everyone' },
        })
    end

    if perms.announce ~= "none" then
        suggest(cmds.announce, "cmd_announce", {
            { name = "message", help = "text of the announcement" },
        })
    end

    if perms.history ~= "none" and Config.History.enabled ~= false then
        suggest(cmds.history, "cmd_history")
    end

    suggest(cmds.access, "cmd_access", {
        { name = "id", help = "server id of the player" },
    })
end)

---------------------------------------------------------------------
-- Commands forwarded from the server
---------------------------------------------------------------------

RegisterNetEvent("oxlyn-notifykit:command", function(cmd, args)
    args = args or {}

    if cmd == "editor" then
        if NK.OpenEditor then NK.OpenEditor() end

    elseif cmd == "history" then
        if NK.OpenHistory then NK.OpenHistory() end

    elseif cmd == "test" then
        local style = Utils.Norm(args[1] or "")
        local kind  = Utils.Norm(args[2] or "")

        if style ~= "" and not Utils.IsStyle(style) then
            -- Not a style: maybe the player passed a type as the first argument
            if NK.types[style] or Utils.TypeAlias[style] then
                kind  = style
                style = ""
            else
                NK.Feedback(_U("msg_style_unknown", style), "error")
                return
            end
        end

        NK.Send("test", {
            style = (style ~= "") and style or nil,
            type  = (kind ~= "") and kind or nil,
        })

    elseif cmd == "style" then
        local style = Utils.Norm(args[1] or "")

        if style == "" or not Utils.IsStyle(style) then
            NK.Feedback(_U("msg_style_unknown", style), "error")
            return
        end

        -- "/style <name> global" -> server-wide (server validates admin)
        if Utils.Norm(args[2] or "") == "global" then
            TriggerServerEvent("oxlyn-notifykit:saveLook", { style = style })
            return
        end

        if not Config.AllowPlayerSettings then
            NK.Feedback(_U("msg_style_locked"), "warning")
            return
        end

        NK.SetStyle(style)
        NK.Feedback(_U("msg_style_set", style), "success")
    end
end)

---------------------------------------------------------------------
-- Cleanup
---------------------------------------------------------------------

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= RESOURCE then return end

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)

