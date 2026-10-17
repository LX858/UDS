

-- oxlyn-notifykit | client history panel (cleaned from decompiled output)

local historyOpen = false

-- Returns true if any of the given NK fields is `true`,
-- or is a function that returns a truthy value (errors are swallowed).
local function anyTruthy(names)
    for _, name in ipairs(names) do
        local value = NK[name]

        if type(value) == "function" then
            local ok, result = pcall(value)
            if ok and result then
                return true
            end
        elseif value == true then
            return true
        end
    end

    return false
end

local function isEditorOpen()
    return anyTruthy({ "IsEditorOpen", "editorOpen" })
end

---------------------------------------------------------------------
-- Open / close
---------------------------------------------------------------------

function NK.OpenHistory()
    -- History feature disabled in config
    if Config.History and Config.History.enabled == false then
        NK.Feedback(_U("hi_disabled"), "warning")
        return false
    end

    -- Only one panel at a time
    if isEditorOpen() and NK.CloseEditor then
        NK.CloseEditor()
    end

    historyOpen = true
    NK.Focus("history", true, false)

    NK.Send("openHistory", {
        dnd                 = (NK.personal.dnd == true),
        mute                = (NK.personal.mute == true),
        allowDnd            = (Config.History.allowDnd ~= false),
        allowPlayerSettings = (Config.AllowPlayerSettings == true),
        look                = NK.look,
        personalLook        = NK.personalLook,
    })

    return true
end

function NK.CloseHistory()
    if not historyOpen then
        return false
    end

    historyOpen = false
    NK.Blur("history")
    NK.Send("closeHistory", {})

    return true
end

function NK.IsHistoryOpen()
    return historyOpen
end

---------------------------------------------------------------------
-- NUI callbacks
---------------------------------------------------------------------

RegisterNUICallback("historyClose", function(_, cb)
    cb(1)
    historyOpen = false
    NK.Blur("history")
end)

RegisterNUICallback("historyPersonal", function(data, cb)
    cb(1)

    if type(data) ~= "table" then return end

    local settings = {}

    if data.dnd ~= nil then
        settings.dnd = (data.dnd == true)
    end

    if data.mute ~= nil then
        settings.mute = (data.mute == true)
    end

    -- Only save if something actually changed
    if next(settings) then
        NK.SetPersonal(settings)
    end
end)

RegisterNUICallback("historyLook", function(data, cb)
    cb(1)

    if Config.AllowPlayerSettings ~= true then return end

    local look = (type(data) == "table" and data.look) or nil

    -- Empty or invalid look = reset to default
    if type(look) ~= "table" or next(look) == nil then
        look = nil
    end

    NK.SetPersonalLook(look)
end)

---------------------------------------------------------------------
-- Command + key mapping
---------------------------------------------------------------------

local historyConfig = Config.History or {}
local key = (type(historyConfig.key) == "string" and historyConfig.key) or ""

local historyForEveryone = Config.Permissions and Config.Permissions.history == "everyone"

if key ~= "" and historyConfig.enabled ~= false and historyForEveryone then
    RegisterCommand("notifykit_history", function()
        if historyOpen then
            NK.CloseHistory()
        else
            NK.OpenHistory()
        end
    end, false)

    RegisterKeyMapping("notifykit_history", _U("hi_keymap"), "keyboard", key)
end

---------------------------------------------------------------------
-- Exports
---------------------------------------------------------------------

exports("OpenHistory", NK.OpenHistory)
exports("CloseHistory", NK.CloseHistory)
exports("IsHistoryOpen", NK.IsHistoryOpen)

