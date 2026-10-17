BS_L = {}
BS_L.Locales = {}

BS_Locale = function(key)
    local lang = BS_C and BS_C.Lang or 'en'
    if BS_L.Locales[lang] and BS_L.Locales[lang][key] ~= nil then
        return BS_L.Locales[lang][key]
    end
    -- Fallback to en if not found
    if BS_L.Locales['en'] and BS_L.Locales['en'][key] ~= nil then
        return BS_L.Locales['en'][key]
    end
    return key or "Translation not found"
end
