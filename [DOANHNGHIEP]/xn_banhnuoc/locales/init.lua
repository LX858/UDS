-- Locale configuration
Config.Locale = 'vi' -- Ngôn ngữ mặc định

-- Function để lấy text từ locales
function _(key, ...)
    local locale = Locales[Config.Locale]
    if not locale then
        print("Locale not found: " .. Config.Locale)
        return key
    end
    
    local text = locale[key]
    if not text then
        print("Translation not found for key: " .. key)
        return key
    end
    
    -- Xử lý string formatting nếu có arguments
    if ... then
        return string.format(text, ...)
    end
    
    return text
end
