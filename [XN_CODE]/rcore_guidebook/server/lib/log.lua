function log(msg, level, image)
    if level == LogLevel.CRITICAL then
        sendCustomDiscordMessage(SConfig.LogWebhook, _U('critical_title'), msg, SConfig.DiscordColors.Red, 'rcore_guidebook', image)
    elseif level == LogLevel.PERMISSION then
        sendCustomDiscordMessage(SConfig.LogWebhook, _U('permission_title'), msg, SConfig.DiscordColors.Purple, 'rcore_guidebook', image)
    elseif level == LogLevel.INFO then
        sendCustomDiscordMessage(SConfig.LogWebhook, _U('info_title'), msg, SConfig.DiscordColors.Blue, 'rcore_guidebook', image)
    else
        sendCustomDiscordMessage(SConfig.LogWebhook, _U('other_title'), msg, SConfig.DiscordColors.Grey, 'rcore_guidebook', image)
    end
end

function getDiscord(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.match(id, "discord:") then
            return string.gsub(id, "discord:", "")
        end
    end
    return nil
end

function getNiceName(source)
    local xPlayerDiscord = getDiscord(source)

    local xPlayerName = GetPlayerName(source)
    if xPlayerDiscord then
        xPlayerName = string.format('<@%s> [%s]',xPlayerDiscord, GetPlayerName(source))
    end

    return xPlayerName
end
