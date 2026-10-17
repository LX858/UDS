RegisterServerEvent('3dme:sendMe')
AddEventHandler('3dme:sendMe', function(text)
    local source = source
    text = string.sub(text, 1, Config.MaxLength)
    TriggerClientEvent('3dme:me', -1, text, source)
end)