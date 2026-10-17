if Config.Framework ~= "ESX" then return end
    ESX = exports['es_extended']:getSharedObject()


    function OpenMenuAlcomat(elements)
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_select_menu',
        {
            title    = 'Gracze w pobliżu',
            align    = 'right',
            elements = elements
        }, function(data, menu)
            local selectedId = data.current.value
            TriggerServerEvent('NRG_AlcoEffect:AskForAlcoCheck', selectedId)
            
            menu.close()  
        end, function(data, menu)
            menu.close()  
        end)
    end