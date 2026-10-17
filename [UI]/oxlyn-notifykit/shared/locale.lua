

--------------------------------------------------------------------------------
-- Locale module (cleaned from decompiled output)
--------------------------------------------------------------------------------

local currentLocale = (Config and Config.Locale) or "en"

-- Merged strings table: English is the base, the selected locale overrides it
local strings = {}

for key, value in pairs((Locales and Locales.en) or {}) do
    strings[key] = value
end

if currentLocale ~= "en" then
    for key, value in pairs((Locales and Locales[currentLocale]) or {}) do
        strings[key] = value
    end
end

--- Translate a key. Falls back to the key itself if no string exists.
--- Extra arguments are passed to string.format; if formatting fails,
--- the unformatted string is returned.
function _U(key, ...)
    local str = strings[key]
    if str == nil then
        return key
    end

    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, str, ...)
        if ok then
            return formatted
        end
    end

    return str
end

--- Like _U, but returns nil when key is nil.
function Lang(key, ...)
    if key == nil then
        return nil
    end
    return _U(key, ...)
end

function GetLocaleTable()
    return strings
end

function GetCurrentLocale()
    return currentLocale
end

