-- Initialize debug system as GLOBAL variable (like original)
dbg = RDebug()
dbg.setupPrefix(GetCurrentResourceName())

-- Global variables
_activePlayers = {}
_sendedInitData = {}
_waitingForInitData = {}
IsDataFinishedLoading = false

-- Player spawned event handler
RegisterNetEvent(triggerName("playerSpawned"), function()
    local playerId = source
    local playerIdentifier = getPlayerIdentifier(playerId)
    
    -- Add player to active players list
    _activePlayers[playerIdentifier] = playerId
    
    -- Log player join
    dbg.info("Player %s (%s) with ID %s is joining", 
        GetPlayerName(playerId), 
        playerIdentifier, 
        playerId
    )
    
    -- Create thread to handle delayed initialization
    CreateThread(function()
        -- Wait for configured delay or default 10 seconds
        Wait(Config.JoinDelay or 10000)
        
        -- Send initial data to client
        TriggerClientEvent(
            triggerName("receivePoints"), 
            playerId, 
            getPoints(), 
            Ace.Can(playerId, Permissions.OPEN_CONTROL)
        )
    end)
end)

-- Player dropped event handler
AddEventHandler("playerDropped", function(reason)
    local playerId = source
    local playerIdentifier = getPlayerIdentifier(playerId)
    
    -- Remove player from tracking lists
    _activePlayers[playerIdentifier] = nil
    _sendedInitData[playerId] = nil
    
    -- Log player leave
    dbg.info("Player %s (%s) is left server", 
        GetPlayerName(playerId), 
        playerIdentifier
    )
end)

-- Check if player has received initial data
function havePlayerInitData(playerId)
    return _sendedInitData[playerId] ~= nil
end

-- Mark player as having received initial data
function sendedPlayerInitData(playerId)
    _sendedInitData[playerId] = true
end

-- Mark player as waiting for initial data
function playerWaitingForInitData(playerId)
    _waitingForInitData[playerId] = true
end

-- Resource start event handler
AddEventHandler("onResourceStart", function(resourceName)
    local currentResource = GetCurrentResourceName()
    if resourceName ~= currentResource then
        return
    end
    
    Citizen.CreateThread(function()
        -- Load existing players
        for _, playerId in pairs(GetPlayers()) do
            local playerIdentifier = getPlayerIdentifier(playerId)
            _activePlayers[playerIdentifier] = playerId
        end
        
        dbg.debug("Loaded %s players", table.len(_activePlayers))
        
        -- Wait before database operations
        Wait(2000)
        
        -- Initialize database when MySQL is ready
        MySQL.ready(function()
            -- Database initialization
            insertDatabaseSafely()
            updateDatabaseStructure()
            loadCategories()
            loadPageContent()
            loadPointContent()
            
            IsDataFinishedLoading = true
            
            -- Send data to waiting players
            for playerId, _ in pairs(_waitingForInitData) do
                TriggerClientEvent(
                    triggerName("receiveInitDataLazy"), 
                    playerId, 
                    formatFrontendData()
                )
                _waitingForInitData[playerId] = nil
            end
        end)
        
        -- Configure client settings
        TriggerClientEvent(
            triggerName("configure"), 
            -1, 
            {
                imageWebhook = SConfig.ImageWebhook
            }
        )
        
        -- Send points data to all clients
        TriggerClientEvent(
            triggerName("receivePoints"), 
            -1, 
            getPoints()
        )
    end)
end)

-- Get active players list
function getActivePlayers()
    return _activePlayers
end