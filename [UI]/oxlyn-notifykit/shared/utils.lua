

--------------------------------------------------------------------------------
-- Utils module (cleaned from decompiled output)
--------------------------------------------------------------------------------

Utils = Utils or {}

local PREFIX = "^5[OXLYN-NOTIFYKIT]"

--------------------------------------------------------------------------------
-- Table helpers
--------------------------------------------------------------------------------

--- Deep copy (non-tables are returned as-is).
function Utils.Copy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = Utils.Copy(v)
    end
    return copy
end

--- Shallow merge: keys in `b` override keys in `a`. Returns a new table.
function Utils.Merge(a, b)
    local out = {}
    if type(a) == "table" then
        for k, v in pairs(a) do out[k] = v end
    end
    if type(b) == "table" then
        for k, v in pairs(b) do out[k] = v end
    end
    return out
end

--- Recursive merge of `b` into a copy of `a`.
function Utils.DeepMerge(a, b)
    local out = Utils.Copy(a)
    if type(out) ~= "table" then
        out = {}
    end
    if type(b) ~= "table" then
        return out
    end

    for k, v in pairs(b) do
        if type(v) == "table" then
            -- NOTE: a table value is only merged when the target is also a
            -- table; otherwise it is skipped. This mirrors the decompiled
            -- control flow exactly (it may be an upstream quirk).
            if type(out[k]) == "table" then
                out[k] = Utils.DeepMerge(out[k], v)
            end
        else
            out[k] = Utils.Copy(v)
        end
    end

    return out
end

--- True if array `list` contains `value`.
function Utils.Contains(list, value)
    if type(list) ~= "table" then
        return false
    end
    for i = 1, #list do
        if list[i] == value then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- String helpers
--------------------------------------------------------------------------------

--- Trim + lowercase. Non-strings become "".
function Utils.Norm(s)
    if type(s) ~= "string" then
        return ""
    end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""):lower())
end

--- Join array items with tostring(), default separator ", ".
function Utils.Join(list, separator)
    local parts = {}
    for i = 1, #list do
        parts[i] = tostring(list[i])
    end
    return table.concat(parts, separator or ", ")
end

--- Number -> string; non-string -> nil; optionally truncate to maxLen.
function Utils.Str(value, maxLen)
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

--- Normalise a hex colour to "#rrggbb" (lowercase), or nil if invalid.
--- Accepts "#rgb", "rgb", "#rrggbb", "rrggbb".
function Utils.Hex(value)
    if type(value) ~= "string" then
        return nil
    end

    value = value:gsub("^%s+", ""):gsub("%s+$", "")

    if value:sub(1, 1) ~= "#" then
        value = "#" .. value
    end

    if #value == 4 then
        value = "#"
            .. value:sub(2, 2):rep(2)
            .. value:sub(3, 3):rep(2)
            .. value:sub(4, 4):rep(2)
    end

    if value:match("^#%x%x%x%x%x%x$") then
        return value:lower()
    end
    return nil
end

--------------------------------------------------------------------------------
-- Numbers
--------------------------------------------------------------------------------

--- Clamp to [min, max]; returns `default` if value isn't a valid number.
function Utils.Clamp(value, min, max, default)
    value = tonumber(value)
    if value == nil or value ~= value then -- nil or NaN
        return default
    end
    if value < min then return min end
    if value > max then return max end
    return value
end

--------------------------------------------------------------------------------
-- Logging
--------------------------------------------------------------------------------

--- Print all arguments (tables as JSON) when Config.Debug is on.
function Utils.Debug(...)
    if not (Config and Config.Debug) then
        return
    end

    local parts = {}
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        parts[#parts + 1] = (type(v) == "table" and json.encode(v)) or tostring(v)
    end

    print(("%s^7 %s"):format(PREFIX, table.concat(parts, " ")))
end

function Utils.Info(fmt, ...)
    print((PREFIX .. "^7 " .. fmt):format(...))
end

function Utils.Warn(fmt, ...)
    print((PREFIX .. "^3 " .. fmt .. "^7"):format(...))
end

--------------------------------------------------------------------------------
-- Styles
--------------------------------------------------------------------------------

Utils.Categories = {
    "essentials", "devices", "roleplay", "gaming", "cyber",
    "bold", "elegant", "compact", "playful",
}

Utils.StyleCategory = {} -- style -> category
Utils.Styles = {}        -- flat ordered list of every style

local styleGroups = {
    essentials = { "classic", "glass", "soft", "outline", "line", "split", "pill", "minimal" },
    devices    = { "mobile", "material", "desktop", "aqua", "island", "snackbar", "watch", "lock" },
    roleplay   = { "feed", "nopixel", "phone", "dispatch", "radio", "sms", "breaking", "receipt" },
    gaming     = { "achievement", "trophy", "levelup", "quest", "loot", "arcade", "killfeed", "mission" },
    cyber      = { "neon", "cyber", "hologram", "terminal", "glitch", "synthwave", "circuit", "hud" },
    bold       = { "solid", "gradient", "brutal", "banner", "ribbon", "tile", "stamp", "duo" },
    elegant    = { "luxe", "paper", "frost", "mono", "elegant", "velvet", "aurora", "editorial" },
    compact    = { "toast", "chip", "dot", "ticker", "sidebar", "ring", "bubble", "underline" },
    playful    = { "comic", "kawaii", "sketch", "retro", "western", "score", "sticker", "candy" },
}

Utils.StyleGroups = styleGroups

for _, category in ipairs(Utils.Categories) do
    for _, style in ipairs(styleGroups[category]) do
        Utils.Styles[#Utils.Styles + 1] = style
        Utils.StyleCategory[style] = category
    end
end

function Utils.IsStyle(value)
    return type(value) == "string"
end

--------------------------------------------------------------------------------
-- Positions
--------------------------------------------------------------------------------

Utils.Positions = {
    "top-left",    "top-center",    "top-right",
    "center-left", "center",        "center-right",
    "bottom-left", "bottom-center", "bottom-right",
}

local positionAliases = {
    top = "top-center",
    bottom = "bottom-center",
    left = "center-left",
    right = "center-right",
    middle = "center",
    centre = "center",
    ["middle-center"] = "center",
    ["center-center"] = "center",

    topleft = "top-left",
    topright = "top-right",
    topcenter = "top-center",
    ["top-middle"] = "top-center",

    bottomleft = "bottom-left",
    bottomright = "bottom-right",
    bottomcenter = "bottom-center",
    ["bottom-middle"] = "bottom-center",

    ["left-center"] = "center-left",
    ["right-center"] = "center-right",
    centerleft = "center-left",
    centerright = "center-right",
    ["middle-left"] = "center-left",
    ["middle-right"] = "center-right",
}

--- Normalise user input ("TopLeft", "top_left", "top left"...) to a canonical
--- position, or nil if unrecognised.
function Utils.Position(value)
    if type(value) ~= "string" then
        return nil
    end

    local s = value:gsub("(%l)(%u)", "%1-%2")
    s = s:lower():gsub("_", "-"):gsub("%s+", "")

    if Utils.Contains(Utils.Positions, s) then
        return s
    end

    local compact = s:gsub("%-", "")
    return positionAliases[s] or positionAliases[compact]
end

--------------------------------------------------------------------------------
-- Notification types
--------------------------------------------------------------------------------

Utils.DefaultTypes = {
    success     = { label = "Success",      color = "#34d399", icon = "fa-solid fa-circle-check",        sound = "success" },
    error       = { label = "Error",        color = "#f43f5e", icon = "fa-solid fa-circle-xmark",        sound = "error" },
    warning     = { label = "Warning",      color = "#f59e0b", icon = "fa-solid fa-triangle-exclamation", sound = "warning" },
    info        = { label = "Info",         color = "#3b82f6", icon = "fa-solid fa-circle-info",         sound = "info" },
    primary     = { label = "Notice",       color = "#8b5cf6", icon = "fa-solid fa-bell",                sound = "info" },
    neutral     = { label = "Update",       color = "#9ca3af", icon = "fa-solid fa-circle-dot",          sound = "soft" },
    money       = { label = "Money",        color = "#22c55e", icon = "fa-solid fa-sack-dollar",         sound = "money" },
    bank        = { label = "Bank",         color = "#10b981", icon = "fa-solid fa-building-columns",    sound = "money" },
    police      = { label = "Police",       color = "#3b82f6", icon = "fa-solid fa-shield-halved",       sound = "alert" },
    ems         = { label = "EMS",          color = "#ef4444", icon = "fa-solid fa-truck-medical",       sound = "alert" },
    fire        = { label = "Fire Dept.",   color = "#f97316", icon = "fa-solid fa-fire",                sound = "alert" },
    mechanic    = { label = "Mechanic",     color = "#eab308", icon = "fa-solid fa-wrench",              sound = "info" },
    phone       = { label = "Phone",        color = "#22c55e", icon = "fa-solid fa-phone",               sound = "message" },
    message     = { label = "Message",      color = "#06b6d4", icon = "fa-solid fa-comment-dots",        sound = "message" },
    mail        = { label = "Mail",         color = "#6366f1", icon = "fa-solid fa-envelope",            sound = "message" },
    system      = { label = "System",       color = "#94a3b8", icon = "fa-solid fa-gear",                sound = "soft" },
    admin       = { label = "Staff",        color = "#e11d48", icon = "fa-solid fa-user-shield",         sound = "alert" },
    announce    = { label = "Announcement", color = "#ec4899", icon = "fa-solid fa-bullhorn",            sound = "announce" },
    achievement = { label = "Achievement",  color = "#eab308", icon = "fa-solid fa-trophy",              sound = "achievement" },
    xp          = { label = "Experience",   color = "#a855f7", icon = "fa-solid fa-star",                sound = "achievement" },
    item        = { label = "Item",         color = "#14b8a6", icon = "fa-solid fa-box-open",            sound = "soft" },
    vehicle     = { label = "Vehicle",      color = "#0ea5e9", icon = "fa-solid fa-car",                 sound = "info" },
    location    = { label = "Location",     color = "#84cc16", icon = "fa-solid fa-location-dot",        sound = "info" },
    weather     = { label = "Weather",      color = "#38bdf8", icon = "fa-solid fa-cloud-sun",           sound = "soft" },
    loading     = { label = "Working",      color = "#a3a3a3", icon = "fa-solid fa-spinner",             sound = "none", iconAnimation = "spin" },
}

-- Display order for the built-in types
Utils.TypeOrder = {
    "success", "error", "warning", "info", "primary", "neutral",
    "money", "bank", "police", "ems", "fire", "mechanic",
    "phone", "message", "mail", "system", "admin", "announce",
    "achievement", "xp", "item", "vehicle", "location", "weather", "loading",
}

-- Alternative names -> canonical type
Utils.TypeAlias = {
    inform = "info", information = "info", default = "info",
    normal = "info", generic = "info",
    notice = "primary",

    ok = "success", done = "success", check = "success",
    successful = "success", good = "success",

    err = "error", danger = "error", fail = "error",
    failed = "error", failure = "error", bad = "error", negative = "error",

    warn = "warning", alert = "warning", caution = "warning",

    ambulance = "ems", medic = "ems", medical = "ems",
    doctor = "ems", hospital = "ems",

    cop = "police", lspd = "police", sheriff = "police", dispatch = "police",

    cash = "money", dollar = "money",
    banking = "bank",

    phonemessage = "phone",
    sms = "message", chat = "message",
    email = "mail",

    staff = "admin",
    server = "system",
    broadcast = "announce", announcement = "announce",
    trophy = "achievement",
    level = "xp", exp = "xp",
    inventory = "item",
    car = "vehicle",
    gps = "location", waypoint = "location",
    loader = "loading", progress = "loading", working = "loading",
}

--- Resolve any input to a known type name (falls back to "info").
function Utils.TypeName(value, types)
    types = types or (Config and Config.Types) or Utils.DefaultTypes

    if type(value) ~= "string" or value == "" then
        return "info"
    end

    local name = value:lower()
    if types[name] then
        return name
    end

    local alias = Utils.TypeAlias[name]
    if alias and types[alias] then
        return alias
    end

    return "info"
end

--- Default types merged with Config.Types overrides / additions.
function Utils.Types()
    local result = Utils.Copy(Utils.DefaultTypes)

    if Config and type(Config.Types) == "table" then
        for name, def in pairs(Config.Types) do
            if type(name) == "string" and type(def) == "table" then
                result[name] = Utils.Merge(result[name] or {}, def)
            end
        end
    end

    return result
end

--- Ordered list of type names: built-ins in TypeOrder, then custom ones A-Z.
function Utils.TypeList(types)
    types = types or Utils.Types()

    local list, seen = {}, {}

    for _, name in ipairs(Utils.TypeOrder) do
        if types[name] then
            list[#list + 1] = name
            seen[name] = true
        end
    end

    local extras = {}
    for name in pairs(types) do
        if not seen[name] then
            extras[#extras + 1] = name
        end
    end
    table.sort(extras)

    for _, name in ipairs(extras) do
        list[#list + 1] = name
    end

    return list
end

--------------------------------------------------------------------------------
-- Option lists
--------------------------------------------------------------------------------

Utils.Animations = { "slide", "glide", "swoop", "fade", "drop", "curtain", "reveal", "bounce", "none" }
Utils.StackModes = { "list", "deck" }
Utils.SoundPacks = { "soft", "crisp", "retro", "bubble", "game", "none" }

Utils.IconAnimations = {
    "spin", "spinPulse", "spinReverse", "pulse", "beat", "fade",
    "beatFade", "bounce", "shake", "wiggle", "ring", "flip",
}

Utils.Sounds = {
    "success", "error", "warning", "info", "message", "money",
    "alert", "announce", "achievement", "soft", "none",
}

--------------------------------------------------------------------------------
-- Look sanitising
--------------------------------------------------------------------------------

--- Validate custom type definitions coming from a "look" table.
--- Returns a cleaned table, or nil if nothing valid remains.
local function sanitizeTypes(input)
    if type(input) ~= "table" then
        return nil
    end

    local out = {}

    for name, def in pairs(input) do
        if type(name) == "string"
            and #name <= 32
            and name:match("^[%w_%-]+$")
            and type(def) == "table"
        then
            local entry = {}

            local color = Utils.Hex(def.color)
            if color then entry.color = color end

            local icon = Utils.Str(def.icon, 120)
            if icon then entry.icon = icon end

            local label = Utils.Str(def.label, 40)
            if label then entry.label = label end

            if Utils.Contains(Utils.Sounds, def.sound) then
                entry.sound = def.sound
            end

            if next(entry) then
                out[name] = entry
            end
        end
    end

    -- NOTE: the decompiled output for this return was garbled; returning nil
    -- for an empty result is the evident intent.
    if next(out) then
        return out
    end
    return nil
end

-- { key, min, max, default, floor }
local NUMERIC_FIELDS = {
    { "offsetX",    -600, 600,   0,    true  },
    { "offsetY",    -400, 400,   0,    true  },
    { "width",       240, 640,   360,  true  },
    { "scale",       0.6, 1.6,   1.0,  false },
    { "radius",        0, 32,    14,   true  },
    { "gap",           0, 32,    10,   true  },
    { "maxVisible",    1, 10,    5,    true  },
    { "duration",   1000, 60000, 5000, true  },
    { "volume",      0.0, 1.0,   0.5,  false },
}

local BOOLEAN_FIELDS = {
    "newestFirst", "showProgress", "showIcon", "showTitle", "iconMotion",
    "dedupe", "markdown", "sounds", "hideInPause", "history",
}

local COLOR_FIELDS = { "surface", "text", "accent" }

--- Validate and clamp a user-supplied look/theme table.
--- Only valid fields are copied into the returned table.
function Utils.CleanLook(look)
    if type(look) ~= "table" then
        return {}
    end

    local out = {}

    if Utils.IsStyle(look.style) then
        out.style = look.style
    end

    local position = Utils.Position(look.position)
    if position then
        out.position = position
    end

    for _, f in ipairs(NUMERIC_FIELDS) do
        local key, min, max, default, floor = f[1], f[2], f[3], f[4], f[5]
        if look[key] ~= nil then
            local n = Utils.Clamp(look[key], min, max, default)
            out[key] = floor and math.floor(n) or n
        end
    end

    if Utils.Contains(Utils.StackModes, look.stack) then
        out.stack = look.stack
    end

    if Utils.Contains(Utils.Animations, look.animation) then
        out.animation = look.animation
    end

    if Utils.Contains(Utils.SoundPacks, look.soundPack) then
        out.soundPack = look.soundPack
    end

    for _, key in ipairs(BOOLEAN_FIELDS) do
        if type(look[key]) == "boolean" then
            out[key] = look[key]
        end
    end

    if type(look.colors) == "table" then
        local colors = {}
        for _, key in ipairs(COLOR_FIELDS) do
            local hex = Utils.Hex(look.colors[key])
            if hex then colors[key] = hex end
        end
        if next(colors) then
            out.colors = colors
        end
    end

    local types = sanitizeTypes(look.types)
    if types then
        out.types = types
    end

    return out
end

--- The look defined in Config.Look, sanitised.
function Utils.DefaultLook()
    return Utils.CleanLook(Config.Look or {})
end

