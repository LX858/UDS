if Config.Framework == nil or Config.Framework == 0 then
    if GetResourceState('qb-core') == 'starting' or GetResourceState('qb-core') == 'started' then
        Config.Framework = 2
    end
end

if Config.Framework == 2 then
    if Config.FrameworkTriggers['notify'] == '' or string.strtrim(string.lower(Config.FrameworkTriggers['notify'])) == 'qbcore' then
        Config.FrameworkTriggers['notify'] = 'QBCore:Notify'
    end

    if Config.FrameworkTriggers['load'] == '' or string.strtrim(string.lower(Config.FrameworkTriggers['load'])) == 'qbcore' then
        Config.FrameworkTriggers['load'] = 'QBCore:GetObject'
    end

    if Config.FrameworkTriggers['resourceName'] == '' or string.strtrim(string.lower(Config.FrameworkTriggers['resourceName'])) == 'qbcore' then
        Config.FrameworkTriggers['resourceName'] = 'qb-core'
    end
end


CreateThread(function()
    if Config.Framework == 2 then
        local QBCore = Citizen.Await(GetSharedObjectSafe())

        local jobName, jobIsBoss, jobGrade = nil, nil, nil

        Citizen.CreateThread(function()
            while true do
                local playerData = QBCore.Functions.GetPlayerData()

                if playerData and playerData.job then
                    jobName = playerData.job.name
                    jobIsBoss = playerData.job.isboss
                    jobGrade = playerData.job.grade.level
                else
                    jobName = nil
                    jobIsBoss = nil
                    jobGrade = nil
                end


                Wait(2000)
            end
        end)

        ShowNotification = function(msg, type)
            local notificationType = "success"

            if type == "error" then
                notificationType = "error"
            end

            QBCore.Functions.Notify(msg, notificationType)
        end

        GetPlayersJobName = function()
            return jobName, jobIsBoss
        end

        GetPlayersJobGrade = function()
            return jobGrade
        end
    end
end)
