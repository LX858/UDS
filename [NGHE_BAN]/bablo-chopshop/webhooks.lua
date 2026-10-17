eventName = eventName or "bablo-chopshop:"

Webhooks = {
    ['RECEIVED_CONTRACT'] = {
        title = 'Received Contract',
        template = '%s received a contract with contract type %s',
        webhook = ''
    },
    ['CHOPPED_A_VEHICLE'] = {
        title = 'Vehicle Chopped',
        template = '%s chopped a vehicle model: %s',
        webhook = ''
    },
    ['COMPLETED_CONTRACT'] = {
        title = 'Completed Contract',
        template = '%s completed a contract and got %s',
        webhook = ''
    },
}

function sendWebhook(source, name, messageData)
    if not Config.Logs then return end

    if not Webhooks[name] or not Webhooks[name].webhook or Webhooks[name].webhook == '' then
        Trace('Webhook error: Webhook URL not set for', name)
        return
    end

    local playerName
    if Config.Framework == 'standalone' then
        playerName = GetPlayerName(source)
    else
        playerName = GetPlayerName(source) .. ' (' .. source .. ') ' .. Framework:getPlayerName(source)
    end

    local message = Webhooks[name].template and string.format(Webhooks[name].template, playerName, tostring(messageData)) or
        "ERROR: No template found"

    local payload = {
        embeds = {
            {
                title = Webhooks[name].title or "Webhook",
                description = message,
                color = 8039935,
                footer = {
                    text = 'Bablo ChopShop | ' .. os.date("%Y-%m-%d %H:%M:%S")
                }
            }
        }
    }

    PerformHttpRequest(Webhooks[name].webhook, function(err, text, headers)
        if err == 401 then
            Trace("ERROR: Unauthorized - The webhook URL might be invalid or expired.")
        elseif err == 429 then
            Trace("ERROR: Rate limited - Too many requests. Wait and try again later.")
        elseif err ~= 200 and err ~= 204 then
            Trace("Webhook failed! HTTP Error:", err, "Response:", text)
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent(eventName .. 'server:sendWebhook')
AddEventHandler(eventName .. 'server:sendWebhook', function(name, data)
    Trace('Sending webhook', name, json.encode(data))

    sendWebhook(source, name, data)
end)