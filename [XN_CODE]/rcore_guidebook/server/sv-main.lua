-- Initialize debug system
local dbg = RDebug()
dbg.setupPrefix(GetCurrentResourceName())

-- Initialize ACE permissions for all permission groups
Citizen.CreateThread(function()
    for groupName, permissions in pairs(PermissionMap) do
        for _, permission in pairs(permissions) do
            Ace.Allow(groupName, permission)
        end
    end
end)

-- Open help menu with initialization data
function openWithInitData(playerId, eventName, serverData)
    if havePlayerInitData(playerId) then
        dbg.debug("%s %s", triggerName(eventName), playerId)
        TriggerClientEvent(triggerName(eventName), playerId, false, serverData)
    else
        dbg.debug("%s %s init data", triggerName(eventName), playerId)
        local initData = formatFrontendData()
        TriggerClientEvent(triggerName(eventName), playerId, initData, serverData)
        
        if initData and table.len(initData.categories) ~= 0 then
            sendedPlayerInitData(playerId)
        else
            playerWaitingForInitData(playerId)
        end
    end
end

-- Open root help menu for player
function openRootHelp(playerId)
    local playerJob = GetPlayersJobName(playerId)
    local playerGrade = GetPlayersJobGrade(playerId)
    
    openWithInitData(playerId, "openRootHelp", {
        isAdmin = Ace.Can(playerId, Permissions.OPEN_CONTROL),
        jobsData = {
            serverJobs = GetAllServerJobs(),
            playerJob = playerJob,
            playerGrade = playerGrade
        },
        isDataFinishedLoading = IsDataFinishedLoading
    })
end

-- Open admin menu for player
function openAdminMenu(playerId)
    local playerJob = GetPlayersJobName(playerId)
    local playerGrade = GetPlayersJobGrade(playerId)
    
    openWithInitData(playerId, "openHelpAdmin", {
        isAdmin = Ace.Can(playerId, Permissions.OPEN_CONTROL),
        jobsData = {
            serverJobs = GetAllServerJobs(),
            playerJob = playerJob,
            playerGrade = playerGrade
        },
        isDataFinishedLoading = IsDataFinishedLoading
    })
end

-- Open specific help page or custom content
function openSpecificHelp(playerId, pageData, customContent)
    local playerJob = GetPlayersJobName(playerId)
    local playerGrade = GetPlayersJobGrade(playerId)
    
    if pageData == false then
        -- Open with custom content
        openWithInitData(playerId, "openSpecificHelp", {
            customContent = customContent,
            isAdmin = Ace.Can(playerId, Permissions.OPEN_CONTROL),
            jobsData = {
                serverJobs = GetAllServerJobs(),
                playerJob = playerJob,
                playerGrade = playerGrade
            },
            isDataFinishedLoading = IsDataFinishedLoading
        })
    else
        -- Open with specific page
        openWithInitData(playerId, "openSpecificHelp", {
            key = pageData.key,
            isAdmin = Ace.Can(playerId, Permissions.OPEN_CONTROL),
            jobsData = {
                serverJobs = GetAllServerJobs(),
                playerJob = playerJob,
                playerGrade = playerGrade
            },
            isDataFinishedLoading = IsDataFinishedLoading
        })
    end
end

-- Event handler for opening specific page
AddEventHandler(triggerName("openSpecificPage"), function(playerId, pageKey)
    local page = getPage(pageKey)
    if not page then
        dbg.critical("Cannot find page %s", pageKey)
        return
    end
    
    openSpecificHelp(playerId, page)
end)

-- Open help menu with permission check
function openHelp(playerId)
    if not Ace.Can(playerId, Permissions.OPEN_PAGE) then
        log(string.format("Player %s dont have permission to open cmd %s", 
            getNiceName(playerId), Config.Commands.Help), LogLevel.PERMISSION)
        return
    end
    
    openRootHelp(playerId)
end

-- Network event handler for opening help
RegisterNetEvent(triggerName("open"), function(targetPlayerId)
    local playerId = source
    
    -- Use target player ID if provided, otherwise use source
    if tonumber(targetPlayerId) ~= nil then
        playerId = tonumber(targetPlayerId)
    end
    
    openHelp(playerId)
end)

-- Register help command
dbg.info("Register help command %s", Config.Commands.Help)
RegisterCommand(Config.Commands.Help, openHelp)

-- Register admin control command
dbg.info("Register control help command %s", Config.Commands.Admin)
RegisterCommand(Config.Commands.Admin, function(playerId, args)
    if not Ace.Can(playerId, Permissions.OPEN_CONTROL) then
        log(string.format("Player %s dont have permission to open cmd %s", 
            getNiceName(playerId), Config.Commands.Admin), LogLevel.PERMISSION)
        return
    end
    
    dbg.debug("Opening help control for %s", playerId)
    openAdminMenu(playerId)
end)

-- Register send help command
dbg.debug("Register send help command %s", Config.Commands.SendHelp)
RegisterCommand(Config.Commands.SendHelp, function(playerId, args)
    if not Ace.Can(playerId, Permissions.SEND_HELP) then
        log(string.format("Player %s dont have permission to send help cmd %s", 
            getNiceName(playerId), Config.Commands.Admin), LogLevel.PERMISSION)
        return
    end
    
    local targetPlayerId = args[1]
    if targetPlayerId == nil then
        basicNotification(playerId, _U("send_usage", Config.Commands.SendHelp))
        return
    end
    
    local targetPlayerName = GetPlayerName(targetPlayerId)
    if targetPlayerName == nil then
        basicNotification(playerId, _U("player_cannot_be_found_usage", targetPlayerId))
        return
    end
    
    local pageKey = args[2]
    if pageKey ~= nil then
        local page = getPage(pageKey)
        if page == nil then
            basicNotification(playerId, _U("page_not_found", pageKey))
            return
        end
        openSpecificHelp(targetPlayerId, page)
    else
        openRootHelp(targetPlayerId)
    end
end)

-- Register navigate command
RegisterCommand(Config.Commands.Navigate, function(playerId, args)
    if not Ace.Can(playerId, Permissions.NAVIGATE) then
        log(string.format("Player %s dont have permission to navigate command", 
            getNiceName(playerId)), LogLevel.PERMISSION)
        return
    end
    
    local pointKey = args[1]
    if pointKey == nil then
        basicNotification(playerId, _U("send_usage_navigate", Config.Commands.Navigate))
        return
    end
    
    local point = getPoint(pointKey)
    if not point then
        basicNotification(playerId, _U("point_not_found", pointKey))
        dbg.critical("Cannot found point %s - player %s navigate cmd", pointKey, playerId)
        return
    end
    
    if point.can_navigate then
        TriggerClientEvent(triggerName("navigate"), playerId, point.position)
    else
        basicNotification(playerId, _U("point_not_allowed", pointKey))
    end
end)

-- Network event handler for teleport
RegisterNetEvent(triggerName("teleport"), function(pointKey)
    local playerId = source
    
    if not Ace.Can(playerId, Permissions.TELEPORT) then
        log(string.format("Player %s dont have permission to teleport", 
            getNiceName(source)), LogLevel.PERMISSION)
        TriggerClientEvent(triggerName("teleportCb"), playerId, false)
        return
    end
    
    local point = getPoint(pointKey)
    if not point then
        dbg.critical("Cannot found this point by key %s!", pointKey)
        TriggerClientEvent(triggerName("teleportCb"), playerId, false)
        return
    end
    
    local playerPed = GetPlayerPed(playerId)
    
    dbg.debug("Teleporting player %s to %s %s %s", 
        playerId, point.position.x, point.position.y, point.position.z)
    
    SetEntityCoords(playerPed, 
        point.position.x, 
        point.position.y, 
        point.position.z, 
        false, false, false, false)
    
    TriggerClientEvent(triggerName("teleportCb"), playerId, true)
end)

-- Network event handler for opening point help
RegisterNetEvent(triggerName("openPointHelp"), function(pointKey)
    local playerId = source
    local point = getPoint(pointKey)
    
    if not point then
        dbg.critical("Player %s is trying open point that does not exist %s!", playerId, pointKey)
        return
    end
    
    if point.help_key then
        if point.help_key ~= "custom_content" then
            local page = getPage(point.help_key)
            if not page then
                dbg.critical("Page %s does not exist!", point.help_key)
                return
            end
            openSpecificHelp(playerId, page)
        end
    else
        openSpecificHelp(playerId, false, point.content)
    end
end)

-- Debug commands registration
CreateThread(function()
    if Config.Debug then
        -- Test ACE permissions command
        RegisterCommand("guidebook_testace", function(playerId)
            for _, permission in pairs(Permissions) do
                dbg.debug("%s %s", permission, Ace.Can(playerId, permission))
            end
        end)
        
        -- Test API open command
        RegisterCommand("guidebook_testapi_open", function(playerId)
            TriggerEvent(triggerName("open"), playerId)
        end)
        
        -- Test API open specific page command
        RegisterCommand("guidebook_testapi_openspecific", function(playerId)
            TriggerEvent(triggerName("openSpecificPage"), playerId, "vip")
        end)
    end
end)