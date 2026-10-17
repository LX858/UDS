function ShowNotify(message, type)
    if Config.OxLib then
        exports['ox_lib']:notify({
            description = message,
            type = type
        })
    elseif Config.Framework == 'ESX' then
        ESX.ShowNotification(message, type, 5000)
    elseif Config.Framework == 'QBcore' then
        QBCore.Functions.Notify(message, type, 5000)
    end
end