CreateThread(function()
    if Config.Framework ~= nil and Config.Framework ~= 1 and Config.Framework ~= 2 then
        Config.DisableDataPermissions = true
        ShowNotification = function(src, msg)
            return
        end

        GetPlayersJobName = function(serverId)
            return nil
        end

        GetPlayersJobGrade = function(serverId)
            return nil
        end

        GetAllServerJobs = function()
            return {}
        end
    end
end)
