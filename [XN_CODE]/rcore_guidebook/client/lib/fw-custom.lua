CreateThread(function()
    if Config.Framework ~= nil and Config.Framework ~= 1 and Config.Framework ~= 2 then
        Config.DisableDataPermissions = true
        ShowNotification = function(text)
            print(text)
        end

        GetPlayersJobName = function(serverId)
            return nil
        end

        GetPlayersJobGrade = function(serverId)
            return nil
        end
    end
end)
