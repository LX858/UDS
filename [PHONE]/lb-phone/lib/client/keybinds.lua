

function AddKeyBind(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.name) == "string", "options.name must be a string")
    assert(type(options.description) == "string", "options.description must be a string")

    options.defaultMapper = options.defaultMapper or "keyboard"

    local name = options.name:lower()
    name = string.format("phone_%s", name)

    local instructionalHash = joaat("+" .. name)
    options.hash = joaat("+" .. name) | 0x80000000
    options.hex = string.upper(string.format("%x", instructionalHash))

    if instructionalHash < 0 then
        options.hex = string.gsub(options.hex, string.rep("F", 8), "")
    end

    options.instructional = "~INPUT_" .. options.hex .. "~"

    RegisterCommand("+" .. name, function()
        if options.disabled or IsPauseMenuActive() then
            return
        end

        options.pressed = true
        options.startedPressing = GetGameTimer()

        if options.onPress then
            options.onPress()
        end
    end, false)

    RegisterCommand("-" .. name, function()
        if options.disabled or IsPauseMenuActive() then
            return
        end

        local timePressed = GetGameTimer() - (options.startedPressing or 0)

        options.pressed = false
        options.startedPressing = nil

        if options.onRelease then
            options.onRelease(timePressed)
        end
    end, false)

    RegisterKeyMapping("+" .. name, "<FONT FACE='arial font'>"..options.description.."</FONT>", options.defaultMapper, options.defaultKey)

    if options.secondaryKey then
        RegisterKeyMapping("~!+" .. name, "<FONT FACE='arial font'>"..options.description.."</FONT>", options.secondaryMapper or options.defaultMapper, options.secondaryKey)
    end

    SetTimeout(500, function()
        TriggerEvent("chat:removeSuggestion", ("/+%s"):format(name))
        TriggerEvent("chat:removeSuggestion", ("/-%s"):format(name))
    end)

    return options
end

exports("AddKeyBind", AddKeyBind)
