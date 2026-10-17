

-- Keys module (cleaned from decompiled output)

Keys = Keys or {}

---------------------------------------------------------------------
-- Key name -> Windows virtual-key code (used by the NUI / JS side)
---------------------------------------------------------------------
Keys.VK = {
    -- Letters
    A = 65, B = 66, C = 67, D = 68, E = 69, F = 70, G = 71, H = 72, I = 73,
    J = 74, K = 75, L = 76, M = 77, N = 78, O = 79, P = 80, Q = 81, R = 82,
    S = 83, T = 84, U = 85, V = 86, W = 87, X = 88, Y = 89, Z = 90,

    -- Number row
    ["0"] = 48, ["1"] = 49, ["2"] = 50, ["3"] = 51, ["4"] = 52,
    ["5"] = 53, ["6"] = 54, ["7"] = 55, ["8"] = 56, ["9"] = 57,

    -- Function keys
    F1 = 112, F2 = 113, F3 = 114, F4 = 115, F5 = 116, F6 = 117,
    F7 = 118, F8 = 119, F9 = 120, F10 = 121, F11 = 122, F12 = 123,

    -- Arrows
    UP = 38, DOWN = 40, LEFT = 37, RIGHT = 39,

    -- Editing / navigation
    SPACE = 32, ENTER = 13, RETURN = 13, TAB = 9,
    ESC = 27, ESCAPE = 27, BACKSPACE = 8, DELETE = 46, INSERT = 45,
    HOME = 36, END = 35, PAGEUP = 33, PAGEDOWN = 34,

    -- Modifiers
    SHIFT = 16, LSHIFT = 160, RSHIFT = 161,
    CTRL = 17,  LCTRL = 162,  RCTRL = 163,
    ALT = 18,   LALT = 164,   RALT = 165,
    CAPSLOCK = 20,

    -- Numpad
    NUM0 = 96, NUM1 = 97, NUM2 = 98, NUM3 = 99, NUM4 = 100,
    NUM5 = 101, NUM6 = 102, NUM7 = 103, NUM8 = 104, NUM9 = 105,
    NUMPLUS = 107, NUMMINUS = 109, NUMMUL = 106, NUMDIV = 111, NUMDOT = 110,

    -- Punctuation
    MINUS = 189, PLUS = 187, EQUALS = 187,
    COMMA = 188, PERIOD = 190, SLASH = 191, SEMICOLON = 186,
    QUOTE = 222, LBRACKET = 219, RBRACKET = 221, BACKSLASH = 220,
    GRAVE = 192, TILDE = 192,

    -- Mouse
    MOUSE1 = 1, LMB = 1,
    MOUSE2 = 2, RMB = 2,
    MOUSE3 = 4, MMB = 4,
    MOUSE4 = 5, MOUSE5 = 6,
}

---------------------------------------------------------------------
-- Key name -> list of GTA control IDs (for IsControlPressed etc.)
---------------------------------------------------------------------
Keys.Controls = {
    E = { 38, 46, 51, 86 },
    F = { 23, 75 },
    G = { 47, 58, 103 },
    H = { 74, 172 },
    Q = { 44, 55 },
    R = { 45, 199 },
    X = { 73, 105 },
    Z = { 20, 48 },
    C = { 26, 79 },
    B = { 29 },
    V = { 0 },
    T = { 245 },
    Y = { 246 },
    L = { 182 },
    M = { 244 },
    N = { 249 },

    SPACE     = { 22, 76 },
    TAB       = { 37 },
    ENTER     = { 18, 191, 201 },
    BACKSPACE = { 177, 194, 202 },

    LSHIFT = { 21 }, SHIFT = { 21 },
    LCTRL  = { 36 }, CTRL  = { 36 },
    LALT   = { 19 }, ALT   = { 19 },

    UP    = { 27, 172, 188 },
    DOWN  = { 173, 187 },
    LEFT  = { 174, 189 },
    RIGHT = { 175, 190 },

    MOUSE1 = { 24, 69, 257 }, LMB = { 24, 69, 257 },
    MOUSE2 = { 25, 70 },      RMB = { 25, 70 },

    -- Number row (weapon-select controls)
    ["1"] = { 157 },
    ["2"] = { 158 },
    ["3"] = { 160 },
    ["4"] = { 164 },
    ["5"] = { 165 },
    ["6"] = { 159 },
    ["7"] = { 161 },
    ["8"] = { 162 },
    ["9"] = { 163 },
}

---------------------------------------------------------------------
-- Display labels (symbols / short names shown in the UI)
---------------------------------------------------------------------
Keys.Labels = {
    SPACE = "SPACE",
    ENTER = "↵", RETURN = "↵",
    TAB = "TAB",
    ESC = "ESC", ESCAPE = "ESC",
    BACKSPACE = "⌫",
    DELETE = "DEL",

    UP = "↑", DOWN = "↓", LEFT = "←", RIGHT = "→",

    SHIFT = "SHIFT", LSHIFT = "SHIFT", RSHIFT = "SHIFT",
    CTRL = "CTRL",   LCTRL = "CTRL",   RCTRL = "CTRL",
    ALT = "ALT",     LALT = "ALT",     RALT = "ALT",
    CAPSLOCK = "CAPS",

    MOUSE1 = "LMB", LMB = "LMB",
    MOUSE2 = "RMB", RMB = "RMB",
    MOUSE3 = "MMB", MMB = "MMB",

    NUMPLUS = "NUM +", NUMMINUS = "NUM −", NUMMUL = "NUM *",
    NUMDIV = "NUM /",  NUMDOT = "NUM .",

    MINUS = "-", PLUS = "+", EQUALS = "=",
    COMMA = ",", PERIOD = ".", SLASH = "/", SEMICOLON = ";",
    QUOTE = "'", LBRACKET = "[", RBRACKET = "]", BACKSLASH = "\\",
    GRAVE = "`", TILDE = "~",
}

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

-- Normalizes a key name: trims, uppercases, maps "NUMPAD0" -> "NUM0".
-- Returns nil for non-strings or empty input.
function Keys.Name(name)
    if type(name) ~= "string" then
        return nil
    end

    name = name:gsub("^%s+", ""):gsub("%s+$", ""):upper()

    if name == "" then
        return nil
    end

    -- (original had a "NUMx" passthrough branch that returned the name unchanged)
    if name == "NUMPAD0" then
        return "NUM0"
    end

    return name
end

-- Key name -> virtual-key code (or nil)
function Keys.VKOf(name)
    local normalized = Keys.Name(name)
    return normalized and Keys.VK[normalized] or nil
end

-- Key name -> human-readable label ("?" if invalid)
function Keys.Label(name)
    local normalized = Keys.Name(name)
    if not normalized then
        return "?"
    end

    -- NUM0..NUM9 -> "NUM 0".."NUM 9"
    if normalized:sub(1, 3) == "NUM" and #normalized == 4 then
        return "NUM " .. normalized:sub(4)
    end

    return Keys.Labels[normalized] or normalized
end

local EMPTY = {}

-- Key name -> list of GTA control IDs (empty table if unknown)
function Keys.ControlsOf(name)
    local normalized = Keys.Name(name)
    return (normalized and Keys.Controls[normalized]) or EMPTY
end

