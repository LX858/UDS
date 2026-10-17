function getSupportedLink(redirectType, url, volume, time, identifier)
    if identifier == nil then identifier = 0 end

    for pattern, handler in pairs(Config.CompletRedirect) do
        if string.match(url, pattern) then
            return handler(url, time, volume)
        end
    end

    redirectType = GetRedirectFromURL(url)

    if redirectType ~= RedirectType.MENU and redirectType ~= RedirectType.OTHER then
        local template = "nui://rcore_television/html/support/" .. redirectType .. "/index.html?url=%s&volume=%i&time=%i&identifier=%i"
        return string.format(template, url, volume, time, identifier)
    end

    return url
end
