function IsPlayerInGroup(jobName, grade)
    local p = promise.new()
    callCallback(TriggerName("hasPermission"), function(result)
        p:resolve(result)
    end, jobName, grade)
    return Citizen.Await(p)
end
