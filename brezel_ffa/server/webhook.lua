local function GetTopPlayersFields()
    local topPlayers = MySQL.query.await("SELECT * FROM `brezel_ffa` ORDER BY `kills` DESC LIMIT 10") or {}
    local fields = {}
    for rank, player in ipairs(topPlayers) do
        local kills = tonumber(player.kills) or 0
        local deaths = tonumber(player.deaths) or 0
        local kd = deaths > 0 and (kills / deaths) or kills
        table.insert(fields, {
            name = string.format("#%d %s", rank, player.name or "Unknown"),
            value = string.format("Kills: %d\nDeaths: %d\nK/D: %.2f", kills, deaths, kd),
            inline = false
        })
    end
    return fields
end

local function SendDiscordWebhook()
    if not BS_S.Webhook or not BS_S.Webhook.use or not BS_S.Webhook.url or BS_S.Webhook.url == "" then
        return
    end

    local fields = GetTopPlayersFields()
    local payload = {
        username = BS_S.Webhook.name or "Brezel FFA",
        avatar_url = BS_S.Webhook.avatar or "",
        embeds = {
            {
                title = BS_Locale("webhook_title"),
                color = BS_S.Webhook.color or 16711680,
                fields = fields
            }
        }
    }

    PerformHttpRequest(BS_S.Webhook.url, function(err, text, headers)
    end, "POST", json.encode(payload), {
        ["Content-Type"] = "application/json"
    })
end

-- Webhook scheduler loop
CreateThread(function()
    if not BS_S.Webhook or not BS_S.Webhook.use or not BS_S.Webhook.url or BS_S.Webhook.url == "" then
        return
    end

    while true do
        local currentTime = os.date("*t")
        for _, timeConfig in ipairs(BS_S.Webhook.times or {}) do
            if currentTime.hour == timeConfig.hour and currentTime.min == timeConfig.minute then
                SendDiscordWebhook()
                Wait(60000) -- Wait 1 minute to prevent duplicate trigger in the same minute
            end
        end
        Wait(30000)
    end
end)
