if Config.Framework == nil or Config.Framework == 0 or Config.SocietySystem == nil then
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

local allServerJobs = nil

CreateThread(function()
    if Config.Framework == 1 then
        local ESX = Citizen.Await(GetSharedObjectSafe())
        ShowNotification = function(src, msg)
            TriggerClientEvent(Config.FrameworkTriggers['notify'], src, msg)
        end

        GetPlayersJobName = function(serverId)
            local xPlayer = ESX.GetPlayerFromId(serverId)
            local jobInfo = xPlayer.getJob()
            if xPlayer and jobInfo.name ~= nil then
                return jobInfo.name
            end

            return nil
        end

        GetPlayersJobGrade = function(serverId)
            local xPlayer = ESX.GetPlayerFromId(serverId)
            local jobInfo = xPlayer.getJob()
            if xPlayer and jobInfo.name ~= nil then
                return jobInfo.grade
            end

            return nil
        end

        GetAllServerJobs = function()
            if allServerJobs then
                return allServerJobs
            end

            local rawJobs = ESX.Jobs

            if table.len(rawJobs) == 0 then
                local ESX = Citizen.Await(GetSharedObjectSafe())

                rawJobs = ESX.Jobs
            end

            for jobKey, jobData in pairs(rawJobs) do
                local grades = jobData.grades

                for gradeKey, gradeData in pairs(grades) do
                    grades[gradeKey] = {
                        name = gradeData.label,
                        key = gradeKey,
                    }
                end

                rawJobs[jobKey] = {
                    name = jobData.label or jobKey,
                    grades = grades,
                }
            end

            allServerJobs = rawJobs

            return rawJobs
        end
    end
end)
