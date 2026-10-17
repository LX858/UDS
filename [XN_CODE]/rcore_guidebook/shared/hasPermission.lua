function HasPermission(attributes, playerJob, isAdmin)
    if Config.DisableDataPermissions or (isAdmin and Config.DisableDataPermissionsForAdmin) then
        return true
    end

    if not attributes then
        return true
    end

    if not attributes.permissions or not attributes.permissions.enabled or not attributes.permissions.jobs or not #attributes.permissions.jobs then
        return true
    end

    if not playerJob and not attributes then
        return true
    end

    if not playerJob then
        return false
    end

    -- check if attributes.permissions.jobs contains any job with jobName == playerJob.name
    local job = false

    for _, jobData in pairs(attributes.permissions.jobs) do
        if jobData.jobName == playerJob.name then
            job = jobData
            break
        end
    end

    return job and job.grade <= playerJob.grade
end
