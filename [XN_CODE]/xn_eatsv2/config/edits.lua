--#Notifications
Config.Notify = function(message, type)
    lib.notify({
        title = 'Eats',
        description = message,
        type = type,
        position = 'top',
        duration = 5000
    })
end



Config.QBUpdateNeeds = 'hud:client:UpdateNeeds' --  'qb-hud:client:UpdateNeeds'  |  'hud:client:UpdateNeeds'