-- Initialize debug system
local dbg = RDebug()
dbg.setupPrefix(GetCurrentResourceName())

-- Get configured keys
local keys = getKeys()

-- Global variables
local serverConfig = {}
local initData = {}
local waitingCallbacks = {}
IsDataFinishedLoading = false

-- Set waiting callback for async operations
function setWaitingCallback(callbackId, callback)
    waitingCallbacks[callbackId] = callback
end

-- Call and remove waiting callback
function callWaitingCallback(callbackId, ...)
    local callback = waitingCallbacks[callbackId]
    if callback ~= nil then
        pcall(callback, ...)
    end
    waitingCallbacks[callbackId] = nil
end

-- Get initialization data
function getInitData()
    return initData
end

-- Set initialization data and send to UI
function setInitData(data, hasPermission)
    initData = data
    sendInitData(data, hasPermission)
    sendUITranslation()
end

-- Get server configuration
function getServerConfig(key)
    if key then
        return serverConfig[key]
    end
    return serverConfig
end

-- Create variable string for RDR2
function CreateVarString(p0, p1, p2)
    return Citizen.InvokeNative(-391150436700639047, p0, p1, p2, Citizen.ResultAsLong())
end

-- Server configuration event handler
RegisterNetEvent(triggerName("configure"), function(config)
    serverConfig = config
    dbg.info("Obtains new server configuration")
end)

-- Main initialization thread
CreateThread(function()
    -- Wait for player to be active
    while true do
        Wait(0)
        if NetworkIsPlayerActive(PlayerId()) then
            TriggerServerEvent(triggerName("playerSpawned"))
            break
        end
    end
    
    -- Send initial configuration to NUI
    Wait(500)
    SendNuiMessage(json.encode({
        type = "CONFIGURATION",
        game = GetGameName()
    }))
end)

-- Key registration thread
CreateThread(function()
    local openKey = Config.Keys.OpenGuidebook
    if openKey then
        Key.Register(
            "openGuidebook",
            _U("registered_key_label"),
            openKey,
            function()
                TriggerServerEvent(triggerName("open"))
            end
        )
    end
end)