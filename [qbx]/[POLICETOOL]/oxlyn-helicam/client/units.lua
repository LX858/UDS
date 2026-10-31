Heli = Heli or {}

local KVP_KEY   = "oxlyn_helicam:speedUnit"
local KMH_TO_MPH = 0.6213711922

local function unitsConfig()
    return Config.Units or {}
end

local function toggleAllowed()
    return unitsConfig().allowToggle ~= false
end

local function rememberEnabled()
    return unitsConfig().remember ~= false
end

local function normalizeUnit(value)
    local s = tostring(value or ""):lower():gsub("[^%a]", "")
    if s == "mph" or s == "mih" or s == "imperial" or s == "mi" then
        return "mph"
    end
    return "kmh"
end

local currentUnit = nil

function Heli.SpeedUnit()
    if currentUnit then return currentUnit end

    currentUnit = normalizeUnit(unitsConfig().speed)

    if toggleAllowed() and rememberEnabled() then
        local saved = GetResourceKvpString(KVP_KEY)
        if saved and saved ~= "" then
            currentUnit = normalizeUnit(saved)
        end
    end

    return currentUnit
end

function Heli.SpeedLabel()
    if Heli.SpeedUnit() == "mph" then
        local label = _U("ui_mph")
        if label then return label end
    end
    return _U("ui_kmh")
end

function Heli.ToSpeed(value)
    value = tonumber(value) or 0.0
    if Heli.SpeedUnit() == "mph" then
        return value * KMH_TO_MPH
    end
    return value
end

function Heli.FormatSpeed(value)
    return ("%d %s"):format(math.floor(Heli.ToSpeed(value) + 0.5), Heli.SpeedLabel())
end

function Heli.SetSpeedUnit(unit, notify)
    local newUnit = normalizeUnit(unit)
    local changed = newUnit ~= Heli.SpeedUnit()

    currentUnit = newUnit

    if rememberEnabled() then
        SetResourceKvp(KVP_KEY, newUnit)
    end

    SendNUIMessage({
        action     = "units",
        speedLabel = Heli.SpeedLabel(),
    })

    if Heli.active and Heli.PushTelemetry then
        Heli.PushTelemetry()
    end

    if notify then
        Notify.Send(_U(newUnit == "mph" and "units_mph" or "units_kmh"), "info")
    end

    return changed
end

function Heli.ToggleSpeedUnit()
    if not toggleAllowed() then
        Notify.Send(_U("units_locked"), "warning")
        return false
    end

    local nextUnit = Heli.SpeedUnit() == "mph" and "kmh" or "mph"
    return Heli.SetSpeedUnit(nextUnit, true)
end

-- Key handling -------------------------------------------------------------

local KEYS = {
    BACKSPACE = 8, TAB = 9, ENTER = 13, RETURN = 13, SHIFT = 16,
    CTRL = 17, CONTROL = 17, ALT = 18, CAPS = 20, CAPSLOCK = 20,
    ESC = 27, ESCAPE = 27, SPACE = 32, PAGEUP = 33, PAGEDOWN = 34,
    END = 35, HOME = 36, LEFT = 37, UP = 38, RIGHT = 39, DOWN = 40,
    INSERT = 45, DEL = 46, DELETE = 46,
    NUMPAD0 = 96, NUMPAD1 = 97, NUMPAD2 = 98, NUMPAD3 = 99, NUMPAD4 = 100,
    NUMPAD5 = 101, NUMPAD6 = 102, NUMPAD7 = 103, NUMPAD8 = 104, NUMPAD9 = 105,
    MULTIPLY = 106, ADD = 107, SUBTRACT = 109, DECIMAL = 110, DIVIDE = 111,
    F1 = 112, F2 = 113, F3 = 114, F4 = 115, F5 = 116, F6 = 117,
    F7 = 118, F8 = 119, F9 = 120, F10 = 121, F11 = 122, F12 = 123,
    SEMICOLON = 186, EQUALS = 187, COMMA = 188, MINUS = 189, PERIOD = 190,
    SLASH = 191, GRAVE = 192, TILDE = 192, LBRACKET = 219,
    BACKSLASH = 220, RBRACKET = 221, QUOTE = 222,
}

local function resolveKey(key)
    if type(key) == "number" then
        return math.floor(key)
    end

    local name = tostring(key or ""):upper():gsub("%s", "")
    if name == "" then return nil end

    if KEYS[name] then return KEYS[name] end

    if #name == 1 then
        local byte = name:byte()
        if (byte >= 65 and byte <= 90) or (byte >= 48 and byte <= 57) then
            return byte
        end
    end

    return nil
end

local function isKeyDown(code)
    if IsRawKeyDown then
        return IsRawKeyDown(code) == true
    end
    if IsRawKeyPressed then
        return IsRawKeyPressed(code) == true
    end
    return false
end

local toggleKeyCode = nil
local keyHeld = false

function Heli.UnitsKey()
    if not toggleAllowed() then return end

    if toggleKeyCode == nil then
        toggleKeyCode = resolveKey(unitsConfig().toggleKey) or false

        if not toggleKeyCode and Config.Debug then
            print(('[oxlyn-helicam] Config.Units.toggleKey "%s" is not a key I know — unit switching is command-only.')
                :format(tostring(unitsConfig().toggleKey)))
        end
    end

    if not toggleKeyCode then return end

    if isKeyDown(toggleKeyCode) then
        if not keyHeld then
            keyHeld = true
            Heli.ToggleSpeedUnit()
        end
    else
        keyHeld = false
    end
end

RegisterCommand("helicamunits", function(_, args)
    if not toggleAllowed() then
        Notify.Send(_U("units_locked"), "warning")
        return
    end

    local arg = tostring((args and args[1]) or ""):lower()

    if arg == "" then
        Heli.ToggleSpeedUnit()
    else
        Heli.SetSpeedUnit(arg, true)
    end
end, false)