local currentLocale = (Config and Config.Locale) or "en"

local strings = {}

local function merge(source)
    for key, value in pairs(source or {}) do
        strings[key] = value
    end
end

-- English is the base, selected locale overrides it
merge(Locales and Locales.en)
if currentLocale ~= "en" then
    merge(Locales and Locales[currentLocale])
end

function _U(key, ...)
    local str = strings[key]
    if str == nil then return key end

    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, str, ...)
        if ok then return formatted end
    end

    return str
end

-- Accepts plain keys or "locale:key" prefixed strings; nil passes through
function Lang(key, ...)
    if key == nil then return nil end

    if type(key) == "string" then
        local stripped = key:match("^locale:(.+)$")
        if stripped then
            return _U(stripped, ...)
        end
    end

    return _U(key, ...)
end

function GetLocaleTable()
    return strings
end

function GetCurrentLocale()
    return currentLocale
end