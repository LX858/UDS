local function permissionName(name)
    return string.format('%s_%s', GetCurrentResourceName(), name)
end

local function isAllowedPlayer(source)
    if not AdminPlayers or #AdminPlayers == 0 then return false end
    local playerIds = GetPlayerIdentifiers(source)
    if not playerIds then return false end
    for _, id in ipairs(playerIds) do
        for _, allowedId in ipairs(AdminPlayers) do
            if id == allowedId then
                return true
            end
        end
    end
    return false
end

Ace = {}
Ace.AddPrincipal = function(child, parent)
    dbg.info('add_principal %s %s', child, parent)
    ExecuteCommand(string.format('add_principal %s %s', child, parent))
end
Ace.RemovePrincipal = function(child, parent)
    dbg.info('remove_principal %s %s', child, parent)
    ExecuteCommand(string.format('remove_principal %s %s', child, parent))
end
Ace.Allow = function(identifier, resource)
    dbg.info('add_ace %s %s allow', identifier, resource)
    ExecuteCommand(string.format('add_ace %s %s allow', identifier, permissionName(resource)))
end
Ace.Deny = function(identifier, resource)
    dbg.info('add_ace %s %s deny', identifier, resource)
    ExecuteCommand(string.format('add_ace %s %s deny', identifier, permissionName(resource)))
end
Ace.Can = function(source, rule)
    -- 1. Check standard FiveM ACE Permissions
    if IsPlayerAceAllowed(source, permissionName(rule)) then
        return true
    end

    -- 2. If checking admin/editing rights, check custom players list or job list
    if rule ~= Permissions.OPEN_PAGE and rule ~= Permissions.NAVIGATE then
        -- Check specific players list
        if isAllowedPlayer(source) then
            return true
        end

        -- Check job name and grade level
        if GetPlayersJobName and GetPlayersJobGrade then
            local jobName = GetPlayersJobName(source)
            local jobGrade = GetPlayersJobGrade(source)
            if jobName and jobGrade then
                local minGrade = AdminJobs[jobName]
                if minGrade and tonumber(jobGrade) >= tonumber(minGrade) then
                    return true
                end
            end
        end
    end

    return false
end
Ace.CanGroup = function(group, rule)
    return IsPrincipalAceAllowed(group, permissionName(rule))
end
