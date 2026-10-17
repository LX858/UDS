local DEBUG = false
local function debugLog() end
if DEBUG then debugLog = function(...)
    print(...)
end end

local PROSPECTING_STATUS = {}
local PROSPECTING_TARGETS = {}
local PLAYER_TARGETS = {} -- Maps player ID to their target index in PROSPECTING_TARGETS

-- Multiplier for distance to check
-- 1.0 is default, allows ~3m around target
-- 2.0 allows ~1.5m around target
-- 10.0 allows ~0.3m around target
-- Alters all distance checks, so higher means you need to be closer to the target to get a signal
-- Each controller resource can define their own difficulty
local PROSPECTING_DIFFICULTIES = {}

--[[ Common ]]
function UpdateProspectingTargets(player)
    if Config.debug then
        print(string.format("^4[SERVER] UpdateProspectingTargets called for player %s - PROSPECTING_TARGETS size: %d", player, #PROSPECTING_TARGETS))
    end
    local targets = {}
    
    -- Only send target that belongs to this specific player
    if PLAYER_TARGETS[player] then
        local targetIndex = PLAYER_TARGETS[player]
        local target = PROSPECTING_TARGETS[targetIndex]
        if target then
            local difficulty = PROSPECTING_DIFFICULTIES[target.resource] or 1.0
            targets[#targets + 1] = {target.x, target.y, target.z, difficulty}
            if Config.debug then
                print(string.format("^4[SERVER] Sending player %s their target at %.2f, %.2f, %.2f", player, target.x, target.y, target.z))
            end
        else
            if Config.debug then
                print(string.format("^1[SERVER] ERROR: Player %s has target index %d but target not found!", player, targetIndex))
            end
        end
    else
        if Config.debug then
            print(string.format("^3[SERVER] Player %s has no assigned target", player))
        end
    end
    
    if Config.debug then
        print(string.format("^4[SERVER] Built targets array for player %s, size: %d", player, #targets))
    end
    debugLog("new targets", json.encode(targets))
    TriggerClientEvent("prospecting:setTargetPool", player, targets)
end

function InsertProspectingTarget(resource, x, y, z, data)
    PROSPECTING_TARGETS[#PROSPECTING_TARGETS + 1] = {resource = resource, data = data, x = x, y = y, z = z}
    if Config.debug then
        print(string.format("^2[SERVER] Inserted target - Total targets now: %d", #PROSPECTING_TARGETS))
    end
end

function InsertProspectingTargets(resource, targets)
    for _, target in next, targets do
        InsertProspectingTarget(resource, target.x, target.y, target.z, target.data)
    end
    UpdateProspectingTargets(-1)
end

function RemoveProspectingTarget(index)
    local new_targets = {}
    for n, target in next, PROSPECTING_TARGETS do
        if n ~= index then
            new_targets[#new_targets + 1] = target
        end
    end
    PROSPECTING_TARGETS = new_targets
    UpdateProspectingTargets(-1)
end

-- Remove target without broadcasting update (for internal use)
function RemoveProspectingTargetSilent(index)
    local new_targets = {}
    for n, target in next, PROSPECTING_TARGETS do
        if n ~= index then
            new_targets[#new_targets + 1] = target
        end
    end
    PROSPECTING_TARGETS = new_targets
end

function ClearProspectingTargets()
    if Config.debug then
        print("^1[SERVER] ClearProspectingTargets called! Stack trace:")
        print(debug.traceback())
    end
    PROSPECTING_TARGETS = {}
    UpdateProspectingTargets(-1)
end

-- Set a single target for a specific player (remove old target for that player first)
function SetPlayerProspectingTarget(player, x, y, z, data)
    local resource = GetInvokingResource()
    if not resource then
        resource = GetCurrentResourceName()
    end
    
    if Config.debug then
        print(string.format("^3[SERVER] SetPlayerProspectingTarget for player %s at %.2f, %.2f, %.2f", player, x, y, z))
    end
    
    -- Remove old target for this player if exists (silently, no broadcast)
    if PLAYER_TARGETS[player] then
        local oldIndex = PLAYER_TARGETS[player]
        if Config.debug then
            print(string.format("^3[SERVER] Removing old target index %d for player %s", oldIndex, player))
        end
        RemoveProspectingTargetSilent(oldIndex)
        -- Update all player target indices after removal
        for pid, idx in pairs(PLAYER_TARGETS) do
            if idx > oldIndex then
                PLAYER_TARGETS[pid] = idx - 1
            end
        end
        PLAYER_TARGETS[player] = nil
    end
    
    -- Add new target
    local newIndex = #PROSPECTING_TARGETS + 1
    PROSPECTING_TARGETS[newIndex] = {resource = resource, data = data, x = x, y = y, z = z}
    PLAYER_TARGETS[player] = newIndex
    
    if Config.debug then
        print(string.format("^3[SERVER] Added target index %d for player %s, total targets: %d", newIndex, player, #PROSPECTING_TARGETS))
    end
end

function FindMatchingPickup(x, y, z)
    for index, target in next, PROSPECTING_TARGETS do
        local dx, dy, dz = target.x, target.y, target.z
        if math.floor(dx) == math.floor(x) and math.floor(dy) == math.floor(y) and math.floor(dz) == math.floor(z) then
            return index
        end
    end
    return nil
end

function HandleProspectingPickup(player, index, x, y, z)
    -- Validate player source
    if not player or player == 0 then
        if Config.debug then
            print("^1[SERVER ERROR] HandleProspectingPickup: Invalid player source")
        end
        return
    end
    
    debugLog("pickup", player, "idx", index, "pos", x, y, z)
    local target = PROSPECTING_TARGETS[index]
    if target then
        local dx, dy, dz = target.x, target.y, target.z
        local resource, data = target.resource, target.data
        if math.floor(dx) == math.floor(x) and math.floor(dy) == math.floor(y) and math.floor(dz) == math.floor(z) then
            debugLog("pickup matches")
            
            -- Clean up player target mapping before removing target
            if PLAYER_TARGETS[player] == index then
                if Config.debug then
                    print(string.format("^3[SERVER] Player %s collected their target, cleaning up", player))
                end
                PLAYER_TARGETS[player] = nil
            end
            
            -- Remove target silently to avoid broadcasting to all players
            RemoveProspectingTargetSilent(index)
            
            -- Update all player target indices after removal
            for pid, idx in pairs(PLAYER_TARGETS) do
                if idx > index then
                    PLAYER_TARGETS[pid] = idx - 1
                    if Config.debug then
                        print(string.format("^3[SERVER] Updated player %s target index from %d to %d", pid, idx, idx - 1))
                    end
                end
            end
            
            TriggerEvent("prospecting:onCollected", player, resource, data, x, y, z)
        else
            debugLog("pickup does not match")
            local newMatch = FindMatchingPickup(x, y, z)
            if newMatch then
                HandleProspectingPickup(player, newMatch, x, y, z)
            end
        end
    else
        debugLog("target does not exist?")
    end
end

--[[ Export handling ]]

function AddProspectingTarget(x, y, z, data)
    local resource = GetInvokingResource()
    if not resource then
        resource = GetCurrentResourceName() -- Internal call
    end
    debugLog("adding prospecting target at", vector3(x, y, z), "with data", data)
    InsertProspectingTarget(resource, x, y, z, data)
end
AddEventHandler("prospecting:AddProspectingTarget", function(x, y, z, data)
    AddProspectingTarget(x, y, z, data)
end)

function AddProspectingTargets(list)
    local resource = GetInvokingResource()
    if not resource then
        resource = GetCurrentResourceName() -- Internal call
    end
    debugLog("adding prospecting targets")
    InsertProspectingTargets(resource, list)
end
AddEventHandler("prospecting:AddProspectingTargets", function(list)
    AddProspectingTargets(list)
end)

function StartProspecting(player)
    if not PROSPECTING_STATUS[player] then
        debugLog("forcing", player, "to start")
        TriggerClientEvent("prospecting:forceStart", player)
    end
end
AddEventHandler("prospecting:StartProspecting", function(player)
    StartProspecting(player)
end)

function StopProspecting(player)
    if PROSPECTING_STATUS[player] then
        debugLog("forcing", player, "to stop")
        TriggerClientEvent("prospecting:forceStop", player)
    end
end
AddEventHandler("prospecting:StopProspecting", function(player)
    StopProspecting(player)
end)

function IsProspecting(player)
    return PROSPECTING_STATUS[player] ~= nil
end

function SetDifficulty(modifier)
    local resource = GetInvokingResource()
    if not resource then
        resource = GetCurrentResourceName() -- Internal call
    end
    PROSPECTING_DIFFICULTIES[resource] = modifier
end

--[[ Client triggered events ]]

-- When the client stops prospecting
RegisterServerEvent("prospecting:userStoppedProspecting")
AddEventHandler("prospecting:userStoppedProspecting", function()
    local player = source
    if not player or player == 0 then
        print("^1[SERVER ERROR] prospecting:userStoppedProspecting: Invalid player source")
        return
    end
    if PROSPECTING_STATUS[player] then
        local time = GetGameTimer() - PROSPECTING_STATUS[player]
        PROSPECTING_STATUS[player] = nil
        TriggerEvent("prospecting:onStop", player, time)
    end
end)

-- When the client starts prospecting
RegisterServerEvent("prospecting:userStartedProspecting")
AddEventHandler("prospecting:userStartedProspecting", function()
    local player = source
    if not player or player == 0 then
        print("^1[SERVER ERROR] prospecting:userStartedProspecting: Invalid player source")
        return
    end
    if not PROSPECTING_STATUS[player] then
        PROSPECTING_STATUS[player] = GetGameTimer()
        TriggerEvent("prospecting:onStart", player)
    end
end)

-- When the client collects a node
RegisterServerEvent("prospecting:userCollectedNode")
AddEventHandler("prospecting:userCollectedNode", function(index, x, y, z)
    local player = source
    if not player or player == 0 then
        print("^1[SERVER ERROR] prospecting:userCollectedNode: Invalid player source")
        return
    end
    if PROSPECTING_STATUS[player] then
        HandleProspectingPickup(player, index, x, y, z)
    end
end)

RegisterServerEvent("prospecting:userRequestsLocations")
AddEventHandler("prospecting:userRequestsLocations", function()
    local player = source
    if not player or player == 0 then
        print("^1[SERVER ERROR] prospecting:userRequestsLocations: Invalid player source")
        return
    end
    UpdateProspectingTargets(player)
end)
