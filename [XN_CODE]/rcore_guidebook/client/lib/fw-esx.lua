if Config.Framework == nil or Config.Framework == 0 then
    if GetResourceState('es_extended') == 'starting' or GetResourceState('es_extended') == 'started' then
        Config.Framework = 1
    end
end

if Config.Framework == 1 then
    if Config.FrameworkTriggers['notify'] == '' or string.strtrim(string.lower(Config.FrameworkTriggers['notify'])) == 'esx' then
        Config.FrameworkTriggers['notify'] = 'esx:showNotification'
    end

    if Config.FrameworkTriggers['load'] == '' or string.strtrim(string.lower(Config.FrameworkTriggers['load'])) == 'esx' then
        Config.FrameworkTriggers['load'] = 'esx:getSharedObject'
    end

    if Config.FrameworkTriggers['resourceName'] == '' or string.strtrim(string.lower(Config.FrameworkTriggers['resourceName'])) == 'esx' then
        Config.FrameworkTriggers['resourceName'] = 'es_extended'
    end
end


CreateThread(function()
    if Config.Framework == 1 then
        local ESX = Citizen.Await(GetSharedObjectSafe())

        local jobName, jobIsBoss, jobGrade = nil, nil, nil

        Citizen.CreateThread(function()
            while true do
                local playerData = ESX.GetPlayerData()

                if playerData and playerData.job then
                    jobName = playerData.job.name
                    jobIsBoss = playerData.job.grade_name:lower() == "boss"
                    jobGrade = playerData.job.grade
                else
                    jobName = nil
                    jobIsBoss = nil
                    jobGrade = nil
                end

                Wait(2000)
            end
        end)

        ShowNotification = function(text, type)
            local notificationType = "info"

            if type == "error" then
                notificationType = "error"
            end

            TriggerEvent(Config.FrameworkTriggers['notify'], text, notificationType)
        end

        GetPlayersJobName = function()
            return jobName, jobIsBoss
        end

        GetPlayersJobGrade = function()
            return jobGrade
        end
    end
end)
