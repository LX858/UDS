

Oxlyn = Oxlyn or {}

-- KVP storage keys
local KEY_SETTINGS = "oxlyn_fps:settings"
local KEY_PRESET   = "oxlyn_fps:preset"
local KEY_CUSTOM   = "oxlyn_fps:custom"    -- legacy single custom profile
local KEY_CUSTOMS  = "oxlyn_fps:customs"
local KEY_SESSIONS = "oxlyn_fps:sessions"

local DEFAULT_MAX_CUSTOMS = 6
local DEFAULT_MAX_SESSIONS = 20
local MAX_PRESET_MARKS = 200

Oxlyn.State = {
    ready = false,
    open = false,
    activePreset = Config.DefaultPreset,
    values = {},        -- final resolved values
    overrides = {},     -- user changes on top of the active preset
    overlay = nil,      -- temporary values applied over everything
    baseValues = {},    -- resolved values before overlay/locks
    customs = {},       -- saved custom profiles
    locked = {},        -- settings locked by the server
    lockedPresets = {}, -- presets locked by the server
    maxPreset = nil,    -- highest preset a non-admin may use
    isAdmin = false,
    sessionStart = GetGameTimer(),
    presetMarks = {},
}

local State = Oxlyn.State

---------------------------------------------------------------------
-- Indexes built from config
---------------------------------------------------------------------

Oxlyn.SettingIndex = {}
for _, setting in ipairs(Config.Settings) do
    -- The language setting must follow Config.Locale until the player picks
    -- one themselves. Its schema default used to be hardcoded to 'pt', which
    -- silently overrode Config.Locale = 'en'.
    if setting.id == 'uiLocale' then
        local wanted = Config.Locale or 'en'
        setting.default = (Locales and Locales[wanted]) and wanted or 'en'
    end
    Oxlyn.SettingIndex[setting.id] = setting
end

Oxlyn.PresetIndex = {}
for _, preset in ipairs(Config.Presets) do
    Oxlyn.PresetIndex[preset.id] = preset
end

Oxlyn.PresetOrder = {}
for index, preset in ipairs(Config.Presets) do
    Oxlyn.PresetOrder[preset.id] = index
end

---------------------------------------------------------------------
-- Value coercion / validation
---------------------------------------------------------------------

function Oxlyn.Coerce(setting, value)
    if not setting then
        return value
    end

    if setting.type == "toggle" then
        if type(value) == "boolean" then return value end
        if value == "true" or value == 1 then return true end
        if value == "false" or value == 0 then return false end
        return setting.default

    elseif setting.type == "range" then
        local number = tonumber(value)
        if not number then
            return setting.default
        end

        if setting.min and number < setting.min then number = setting.min end
        if setting.max and number > setting.max then number = setting.max end

        -- Whole-number steps round to integers
        if setting.step and setting.step >= 1 and math.floor(setting.step) == setting.step then
            number = math.floor(number + 0.5)
        end

        return number

    elseif setting.type == "select" then
        for _, option in ipairs(setting.options or {}) do
            if option.value == value then
                return value
            end
        end
        return setting.default

    elseif setting.type == "color" then
        if type(value) == "string" and value:match("^#%x%x%x%x%x%x$") then
            return value
        end
        return setting.default
    end

    return value
end

---------------------------------------------------------------------
-- KVP helpers
---------------------------------------------------------------------

local function readKvp(key, fallback)
    local raw = GetResourceKvpString(key)
    if not raw or raw == "" then
        return fallback
    end

    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == "table" then
        return decoded
    end

    return fallback
end

local function writeKvp(key, value)
    local ok, encoded = pcall(json.encode, value)
    if ok then
        SetResourceKvp(key, encoded)
    end
end

---------------------------------------------------------------------
-- Local save / load
---------------------------------------------------------------------

function Oxlyn.SaveLocal()
    writeKvp(KEY_SETTINGS, State.overrides)
    writeKvp(KEY_CUSTOMS, State.customs)
    SetResourceKvp(KEY_PRESET, State.activePreset or Config.DefaultPreset)
end

function Oxlyn.LoadLocal()
    State.overrides = readKvp(KEY_SETTINGS, {})
    State.customs = readKvp(KEY_CUSTOMS, nil)

    -- Migrate the old single custom profile into the customs list
    if not State.customs then
        State.customs = {}

        local legacy = readKvp(KEY_CUSTOM, {})
        if next(legacy) ~= nil then
            local name = (Oxlyn.L and Oxlyn.L("preset_custom")) or ""
            if name == "" then
                name = "Custom"
            end

            State.customs[1] = {
                id = "legacy",
                name = name,
                values = legacy,
                created = "",
            }
        end
    end

    local storedPreset = GetResourceKvpString(KEY_PRESET)
    if storedPreset then
        local valid = Oxlyn.PresetIndex[storedPreset]
            or (Config.AllowCustomPreset and Oxlyn.FindCustom(storedPreset))

        if valid then
            State.activePreset = storedPreset
        end
    else
        State.activePreset = Config.DefaultPreset
    end
end

---------------------------------------------------------------------
-- Custom profiles
---------------------------------------------------------------------

-- Returns the custom profile and its index for an id like "custom:abc"
function Oxlyn.FindCustom(presetId)
    if type(presetId) ~= "string" then
        return nil
    end

    local customId = presetId:match("^custom:(.+)$")
    if not customId or customId == "draft" then
        return nil
    end

    for index, custom in ipairs(State.customs) do
        if custom.id == customId then
            return custom, index
        end
    end

    return nil
end

-- Number of settings the user has changed (the "draft")
function Oxlyn.DraftCount()
    local count = 0
    for key in pairs(State.overrides) do
        if Oxlyn.SettingIndex[key] ~= nil then
            count = count + 1
        end
    end
    return count
end

-- Note: the decompiler's filter here (`setting ~= nil`) is always true for
-- entries of Config.Settings, so this returns the resolved value of every setting.
function Oxlyn.DraftValues()
    local values = {}
    for _, setting in ipairs(Config.Settings) do
        values[setting.id] = State.values[setting.id]
    end
    return values
end

local function generateCustomId()
    local id
    repeat
        id = ("p%x%x"):format(GetGameTimer() % 16777215, math.random(0, 65535))
    until not Oxlyn.FindCustom("custom:" .. id)
    return id
end

-- Returns true, profile  or  false, reason
function Oxlyn.SaveCustomProfile(name)
    if not Config.AllowCustomPreset then
        return false, "disabled"
    end

    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if name == "" or #name > 120 then
        return false, "noname"
    end

    if #State.customs >= (Config.MaxCustomPresets or DEFAULT_MAX_CUSTOMS) then
        return false, "full"
    end

    local year, month, day, hour, minute = GetLocalTime()

    local profile = {
        id = generateCustomId(),
        name = name,
        values = Oxlyn.DraftValues(),
        created = ("%04d-%02d-%02d %02d:%02d"):format(year, month, day, hour, minute),
    }
    State.customs[#State.customs + 1] = profile

    -- The draft becomes the profile, so clear the known overrides
    local remaining = {}
    for key, value in pairs(State.overrides) do
        if Oxlyn.SettingIndex[key] == nil then
            remaining[key] = value
        end
    end
    State.overrides = remaining

    State.activePreset = "custom:" .. profile.id
    Oxlyn.Resolve()
    Oxlyn.SaveLocal()

    return true, profile
end

function Oxlyn.DeleteCustom(presetId)
    local custom, index = Oxlyn.FindCustom(presetId)
    if not custom then
        return false
    end

    table.remove(State.customs, index)

    if State.activePreset == presetId then
        State.activePreset = Config.DefaultPreset
        Oxlyn.Resolve()
        Oxlyn.OnPresetChanged(State.activePreset)
    end

    Oxlyn.SaveLocal()
    return true
end

---------------------------------------------------------------------
-- Saved sessions
---------------------------------------------------------------------

function Oxlyn.GetSessions()
    return readKvp(KEY_SESSIONS, {})
end

function Oxlyn.PushSession(session)
    if not Config.Monitor.saveSessions then
        return
    end

    local sessions = Oxlyn.GetSessions()
    table.insert(sessions, 1, session)

    local maxSessions = Config.Monitor.maxSavedSessions or DEFAULT_MAX_SESSIONS
    while #sessions > maxSessions do
        table.remove(sessions)
    end

    writeKvp(KEY_SESSIONS, sessions)
end

---------------------------------------------------------------------
-- Resolving values
-- Order: defaults -> preset -> user overrides -> overlay -> locked
---------------------------------------------------------------------

function Oxlyn.Resolve()
    local values = {}

    -- 1. Defaults
    for _, setting in ipairs(Config.Settings) do
        values[setting.id] = setting.default
    end

    -- 2. Active preset (custom profile or built-in)
    local presetValues
    local custom = Oxlyn.FindCustom(State.activePreset)
    if custom then
        presetValues = custom.values
    else
        local preset = Oxlyn.PresetIndex[State.activePreset]
        presetValues = preset and preset.values or nil
    end

    if presetValues then
        for key, value in pairs(presetValues) do
            local setting = Oxlyn.SettingIndex[key]
            if setting then
                values[key] = Oxlyn.Coerce(setting, value)
            end
        end
    end

    -- 3. User overrides
    for key, value in pairs(State.overrides) do
        local setting = Oxlyn.SettingIndex[key]
        if setting then
            values[key] = Oxlyn.Coerce(setting, value)
        end
    end

    -- Remember the result before overlay/locks are applied
    local base = {}
    for key, value in pairs(values) do
        base[key] = value
    end
    State.baseValues = base

    -- 4. Temporary overlay
    if State.overlay then
        for key, value in pairs(State.overlay) do
            local setting = Oxlyn.SettingIndex[key]
            if setting then
                values[key] = Oxlyn.Coerce(setting, value)
            end
        end
    end

    -- 5. Locked settings are forced back to their default
    for key in pairs(State.locked) do
        local setting = Oxlyn.SettingIndex[key]
        if setting then
            values[key] = setting.default
        end
    end

    State.values = values
    return values
end

function Oxlyn.Get(id)
    local value = State.values[id]
    if value ~= nil then
        return value
    end

    local setting = Oxlyn.SettingIndex[id]
    return setting and setting.default or nil
end

-- A setting is active unless the setting it requires is off
function Oxlyn.Active(id)
    local setting = Oxlyn.SettingIndex[id]
    if not setting then
        return false
    end

    if setting.requires and not Oxlyn.Get(setting.requires) then
        return false
    end

    return true
end

---------------------------------------------------------------------
-- Changing settings / presets
---------------------------------------------------------------------

-- Returns true  or  false, reason
function Oxlyn.Set(id, value, silent)
    local setting = Oxlyn.SettingIndex[id]
    if not setting then
        return false, "unknown"
    end

    if State.locked[id] and not State.isAdmin then
        return false, "locked"
    end

    if setting.adminOnly and not State.isAdmin then
        return false, "no_perm"
    end

    State.overrides[id] = Oxlyn.Coerce(setting, value)
    Oxlyn.Resolve()
    Oxlyn.SaveLocal()

    if not silent then
        Oxlyn.OnSettingsChanged(id)
    end

    return true
end

-- opts: force, keepOverrides, skipApply
function Oxlyn.ApplyPreset(presetId, opts)
    opts = opts or {}

    local isCustom = Oxlyn.FindCustom(presetId) ~= nil

    if not isCustom and not Oxlyn.PresetIndex[presetId] then
        return false, "unknown"
    end

    if isCustom and not Config.AllowCustomPreset then
        return false, "unknown"
    end

    if not State.isAdmin and not opts.force then
        if State.lockedPresets[presetId] then
            return false, "preset_locked"
        end

        -- Non-admins can't go above the server's max preset
        if State.maxPreset then
            local order = Oxlyn.PresetOrder[presetId]
            local maxOrder = Oxlyn.PresetOrder[State.maxPreset]
            if order and maxOrder and order > maxOrder then
                return false, "preset_locked"
            end
        end
    end

    State.activePreset = presetId

    -- Switching preset clears overrides, except interface/HUD settings
    if not opts.keepOverrides then
        local keepGroups = { interface = true, hud = true }
        local kept = {}

        for key, value in pairs(State.overrides) do
            local setting = Oxlyn.SettingIndex[key]
            if setting and keepGroups[setting.group] then
                kept[key] = value
            end
        end

        State.overrides = kept
    end

    Oxlyn.Resolve()
    Oxlyn.SaveLocal()

    -- Record when presets were switched (for the session timeline)
    State.presetMarks[#State.presetMarks + 1] = {
        t = GetGameTimer() - State.sessionStart,
        preset = presetId,
    }
    if #State.presetMarks > MAX_PRESET_MARKS then
        table.remove(State.presetMarks, 1)
    end

    if not opts.skipApply then
        Oxlyn.OnPresetChanged(presetId)
    end

    return true
end

function Oxlyn.SetOverlay(overlay)
    State.overlay = overlay
    Oxlyn.Resolve()
end

function Oxlyn.ResetAll()
    State.overrides = {}
    State.activePreset = Config.DefaultPreset
    Oxlyn.Resolve()
    Oxlyn.SaveLocal()
    Oxlyn.OnPresetChanged(State.activePreset)
end

-- Hooks, meant to be overridden elsewhere
function Oxlyn.OnSettingsChanged(id) end
function Oxlyn.OnPresetChanged(presetId) end

---------------------------------------------------------------------
-- Preset impact bars
---------------------------------------------------------------------

-- How far a value is from the setting's default (0 to 1)
local function deviation(setting, value)
    if setting.type == "range" then
        local span = (setting.max or 1) - (setting.min or 0)
        if span <= 0 then
            return 0
        end
        return math.min(math.abs((setting.default or 0) - value) / span, 1)
    end

    return value ~= setting.default and 1 or 0
end

-- Weighted score of a preset for a field ("impact" or "visual")
local function scorePreset(preset, field)
    local total = 0

    for key, value in pairs(preset.values or {}) do
        local setting = Oxlyn.SettingIndex[key]
        local weight = setting and setting[field]

        if weight and weight > 0 then
            total = total + weight * deviation(setting, value)
        end
    end

    return total
end

-- Returns { [presetId] = { gain = 0..1, visual = 0..1 } } normalised to the highest preset
function Oxlyn.PresetBars()
    local raw = {}
    local maxGain, maxVisual = 0, 0

    for _, preset in ipairs(Config.Presets) do
        local gain = scorePreset(preset, "impact")
        local visual = scorePreset(preset, "visual")

        raw[preset.id] = { gain = gain, visual = visual }

        if gain > maxGain then maxGain = gain end
        if visual > maxVisual then maxVisual = visual end
    end

    local bars = {}
    for id, entry in pairs(raw) do
        bars[id] = {
            gain = maxGain > 0 and entry.gain / maxGain or 0,
            visual = maxVisual > 0 and entry.visual / maxVisual or 0,
        }
    end

    return bars
end

---------------------------------------------------------------------
-- NUI payloads
---------------------------------------------------------------------

function Oxlyn.BuildSchemaPayload()
    local lang = Oxlyn.ActiveLocale or Config.Locale

    -- Groups
    local groups = {}
    for _, group in ipairs(Config.SettingGroups) do
        groups[#groups + 1] = {
            id = group.id,
            icon = group.icon,
            section = group.section or "performance",
            label = Oxlyn.SchemaText("grp", group.id, nil, group.label),
        }
    end

    -- Settings (admin-only ones are hidden from non-admins)
    local settings = {}
    for _, setting in ipairs(Config.Settings) do
        if not setting.adminOnly or State.isAdmin then
            local options
            if setting.options then
                options = {}
                for _, option in ipairs(setting.options) do
                    options[#options + 1] = {
                        value = option.value,
                        label = Oxlyn.SchemaText("opt", setting.id .. "_" .. tostring(option.value), nil, option.label),
                    }
                end
            end

            local requiresLabel
            if setting.requires and Oxlyn.SettingIndex[setting.requires] then
                requiresLabel = Oxlyn.SchemaText("set", setting.requires, "label", Oxlyn.SettingIndex[setting.requires].label)
            end

            settings[#settings + 1] = {
                id = setting.id,
                group = setting.group,
                type = setting.type,
                label = Oxlyn.SchemaText("set", setting.id, "label", setting.label),
                desc = setting.desc and Oxlyn.SchemaText("set", setting.id, "desc", setting.desc) or nil,
                min = setting.min,
                max = setting.max,
                step = setting.step,
                unit = setting.unit,
                scale = setting.scale,
                options = options,
                swatches = setting.swatches,
                impact = setting.impact,
                visual = setting.visual,
                requires = setting.requires,
                requiresLabel = requiresLabel,
                adminOnly = setting.adminOnly,
                locked = State.locked[setting.id] and true or false,
                default = setting.default,
            }
        end
    end

    -- Presets
    local bars = Oxlyn.PresetBars()
    local presets = {}

    for _, preset in ipairs(Config.Presets) do
        local bar = bars[preset.id] or { gain = 0, visual = 0 }

        presets[#presets + 1] = {
            id = preset.id,
            label = Oxlyn.SchemaText("pre", preset.id, "label", preset.label),
            desc = Oxlyn.SchemaText("pre", preset.id, "desc", preset.desc),
            icon = preset.icon,
            confirm = preset.confirm and true or false,
            locked = (State.lockedPresets[preset.id] and not State.isAdmin) and true or false,
            impact = bar.gain,
            visual = bar.visual,
        }
    end

    -- Saved custom profiles + the "draft" entry
    if Config.AllowCustomPreset then
        for _, custom in ipairs(State.customs) do
            local valueCount = 0
            for _ in pairs(custom.values or {}) do
                valueCount = valueCount + 1
            end

            presets[#presets + 1] = {
                id = "custom:" .. custom.id,
                label = custom.name,
                desc = Oxlyn.L("pf_profile_d", valueCount, custom.created or "\226\128\148"), -- em dash
                icon = "sliders",
                kind = "saved",
                locked = false,
            }
        end

        local draftCount = Oxlyn.DraftCount()

        presets[#presets + 1] = {
            id = "custom:draft",
            label = Oxlyn.L("preset_custom"),
            desc = (draftCount > 0 and Oxlyn.L("pf_draft_d", draftCount)) or Oxlyn.L("pf_draft_empty"),
            icon = "sliders",
            kind = "draft",
            locked = false,
            count = draftCount,
            full = #State.customs >= (Config.MaxCustomPresets or DEFAULT_MAX_CUSTOMS),
        }
    end

    return {
        groups = groups,
        settings = settings,
        presets = presets,
        locale = Locales[lang] or Locales.en,
        lang = lang,
    }
end

function Oxlyn.BuildValuesPayload()
    local values = {}
    for key, value in pairs(State.baseValues) do
        values[key] = value
    end

    return {
        values = values,
        overrides = State.overrides,
        preset = State.activePreset,
        isAdmin = State.isAdmin,
    }
end

