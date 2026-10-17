-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Check if wasabi_bridge resource is started
local bridgeState = GetResourceState("wasabi_bridge")

if not bridgeState:find("start") then
    print("^1wasabi_bridge should be started before this resource: " .. GetCurrentResourceName() .. "^0")
    return
end

-- Import the bridge object
wsb = exports.wasabi_bridge:GetBridgeObject()

-- Get the core framework object (ESX/QBCore)
local FrameworkCore = wsb.getCore()

-- Client-side only functionality
if not IsDuplicityVersion() then
    
    -- Register cache change listener
    -- @param cacheKey string - Cache key to listen for (e.g., "vehicle", "weapon")
    -- @param callback function - Function to call when cache changes
    function wsb.onCache(cacheKey, callback)
        AddEventHandler("wasabi_bridge:cache:" .. cacheKey, callback)
    end
    
    -- Handle player initialization
    AddEventHandler("wasabi_bridge:initialize", function()
        -- Security check: only allow wasabi_bridge to trigger this
        if GetInvokingResource() ~= "wasabi_bridge" then
            return
        end
        
        -- Initialize player data based on framework
        if FrameworkCore.Functions then
            -- QBCore
            wsb.playerData = FrameworkCore.Functions.GetPlayerData()
            wsb.playerLoaded = true
        else
            -- ESX
            wsb.playerData = FrameworkCore.GetPlayerData()
            wsb.playerLoaded = true
        end
    end)
    
    -- Handle player data updates
    AddEventHandler("wasabi_bridge:setPlayerData", function(data)
        -- Security check: only allow wasabi_bridge to trigger this
        if GetInvokingResource() ~= "wasabi_bridge" then
            return
        end
        
        if wsb.framework == "qb" then
            -- QBCore: Replace entire player data
            wsb.playerData = data
            return
        end
        
        if wsb.framework == "esx" then
            -- ESX: Update specific key/value pair
            wsb.playerData[data.key] = data.value
        end
    end)
    
    -- Handle cache updates
    AddEventHandler("wasabi_bridge:updateCache", function(cacheKey, value)
        -- Security check: only allow wasabi_bridge to trigger this
        if GetInvokingResource() ~= "wasabi_bridge" then
            return
        end
        
        wsb.cache[cacheKey] = value
    end)
    
    -- Handle player loaded event
    RegisterNetEvent("wasabi_bridge:playerLoaded", function(playerData)
        wsb.playerData = playerData
        wsb.playerLoaded = true
        
        -- For QBCore, refresh player data
        if wsb.framework == "qb" then
            wsb.playerData = FrameworkCore.Functions.GetPlayerData()
        end
    end)
    
    -- Handle player logout event
    RegisterNetEvent("wasabi_bridge:onPlayerLogout", function()
        table.wipe(wsb.playerData)
        wsb.playerLoaded = false
    end)
    
    -- Handle job change event
    RegisterNetEvent("wasabi_bridge:setJob", function(newJob)
        wsb.playerData.job = newJob
        
        -- For QBCore, refresh entire player data
        if wsb.framework == "qb" then
            wsb.playerData = FrameworkCore.Functions.GetPlayerData()
        end
    end)
end