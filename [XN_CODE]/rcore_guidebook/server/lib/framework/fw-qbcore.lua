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

local allServerJobs = nil

CreateThread(function()
    if Config.Framework == 2 then
        local QBCore = Citizen.Await(GetSharedObjectSafe())

        ShowNotification = function(src, msg)
            TriggerClientEvent('QBCore:Notify', src, msg, "error")
        end

        GetPlayersJobName = function(serverId)
            local player = QBCore.Functions.GetPlayer(serverId)

            if player and player.PlayerData and player.PlayerData.job then
                return player.PlayerData.job.name
            end

            return nil
        end

        GetPlayersJobGrade = function(serverId)
            local player = QBCore.Functions.GetPlayer(serverId)

            if player and player.PlayerData and player.PlayerData.job then
                return player.PlayerData.job.grade.level
            end

            return nil
        end

        GetAllServerJobs = function()
            if allServerJobs then
                return allServerJobs
            end

            local rawJobs = QBCore.Shared.Jobs

            for jobKey, jobData in pairs(rawJobs) do
                local grades = jobData.grades

                for gradeKey, gradeData in pairs(grades) do
                    grades[gradeKey] = {
                        name = gradeData.name,
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
