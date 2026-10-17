local lobbies = {}
local pendingInvites = {}
local serverCallbacks = {}
local maxPartySize = 4
local wallBuildingCooldowns = {}
local customTaskCooldowns = {}
local pipeInstallationCooldowns = {}
local weldingCooldowns = {}
local originalGetPlayerPing = GetPlayerPing

local function NormalizeProgress(progress)
    progress = tonumber(progress) or 0
    return math.floor(progress * 10 + 0.5) / 10
end

local function AddLobbyProgress(lobby, amount)
    lobby.progress = NormalizeProgress(lobby.progress + (tonumber(amount) or 0))
    if lobby.progress > 100 then
        lobby.progress = 100
    end
end

function GetPlayerPing(playerId, ...)
    if playerId ~= nil then
        originalGetPlayerPing(playerId, ...)
    end
end

local originalTriggerClientEvent = TriggerClientEvent
function TriggerClientEvent(eventName, playerId, ...)
    if playerId ~= nil then
        originalTriggerClientEvent(eventName, playerId, ...)
    end
end

local originalGetPlayerIdentifierByType = GetPlayerIdentifierByType
function GetPlayerIdentifierByType(playerId, identifierType)
    if playerId == nil then
        return 0
    end
    if originalGetPlayerIdentifierByType ~= nil then
        return originalGetPlayerIdentifierByType(playerId, identifierType)
    else
        return GetPlayerIdentifier(playerId, 1)
    end
end

if Config.useModernUI then
    function RecalculateRewards(hostId)
        local lobbyIndex = 0
        for index, lobby in pairs(lobbies) do
            if lobby.host == hostId then
                lobbyIndex = index
            end
        end
        
        lobbies[lobbyIndex].rewardsOptions = {}
        local totalMembers = #lobbies[lobbyIndex].clients + 1
        
        for i = 1, totalMembers - 1 do
            local clientId = lobbies[lobbyIndex].clients[i]
            local percentage = math.floor(100 / totalMembers)
            lobbies[lobbyIndex].rewardsOptions[clientId] = percentage
        end
        
        local hostPercentage = math.floor(100 / totalMembers)
        lobbies[lobbyIndex].rewardsOptions[hostId] = hostPercentage
        
        TriggerForAllMembers(hostId, "17mov_construction:SetMyReward", hostPercentage)
        TriggerClientEvent("17mov_construction:UpdateHostPercentages", hostId, hostPercentage)
    end
end

function RegisterServerCallback(callbackName, callbackFunction)
    serverCallbacks[callbackName] = callbackFunction
end

RegisterNetEvent("17mov_Callbacks:GetResponse" .. GetCurrentResourceName())
AddEventHandler("17mov_Callbacks:GetResponse" .. GetCurrentResourceName(), function(callbackName, requestId, ...)
    local callback = serverCallbacks[callbackName]
    if callback == nil then
        return
    end
    
    local playerId = source
    local result1, result2, result3, result4, result5, result6, result7, result8, result9, result10, result11 = callback(playerId, ...)
    
    TriggerClientEvent("17mov_Callbacks:receiveData" .. GetCurrentResourceName(), playerId, callbackName, requestId, 
        result1, result2, result3, result4, result5, result6, result7, result8, result9, result10, result11)
end)

Citizen.CreateThread(function()
    RegisterServerCallback("17mov_construction:CheckThisReward", function(playerId, newReward, targetPlayerId)
        local lobbyIndex = 0
        for index, lobby in pairs(lobbies) do
            if playerId == lobby.host then
                lobbyIndex = index
                break
            end
            for i = 1, #lobby.clients do
                if playerId == lobby.clients[i] then
                    lobbyIndex = index
                    break
                end
            end
        end
        
        local totalOtherRewards = 0
        for memberId, reward in pairs(lobbies[lobbyIndex].rewardsOptions) do
            if memberId ~= targetPlayerId then
                totalOtherRewards = totalOtherRewards + reward
            end
        end
        
        if totalOtherRewards + newReward > 100 then
            return false
        else
            lobbies[lobbyIndex].rewardsOptions[targetPlayerId] = newReward
            TriggerClientEvent("17mov_construction:SetMyReward", targetPlayerId, newReward)
            return true
        end
    end)
    
    RegisterServerCallback("17mov_construction:GetPlayersNames", function(playerId, playerIds)
        local playerList = {}
        for i = 1, #playerIds do
            table.insert(playerList, {
                id = playerIds[i],
                name = GetPlayerIdentity(playerIds[i])
            })
        end
        return playerList
    end)
    
    RegisterServerCallback("17mov_construction:GetLobbyMembers", function(playerId, hostId)
        if hostId == nil then
            return {}
        end
        
        local membersList = {hostId}
        for index, lobby in pairs(lobbies) do
            if lobby.host == hostId then
                for i = 1, #lobby.clients do
                    table.insert(membersList, lobby.clients[i])
                end
            end
        end
        return membersList
    end)
    
    RegisterServerCallback("17mov_construction:IfPlayerOwnsTeam", function(playerId)
        local isHost = false
        for index, lobby in pairs(lobbies) do
            if lobby.host == playerId then
                isHost = true
                break
            end
        end
        return isHost
    end)
    
    RegisterServerCallback("17mov_construction:IfPlayerIsHost", function(playerId)
        local isHost = true
        local lobbyIndex = 0
        
        for index, lobby in pairs(lobbies) do
            for i = 1, #lobby.clients do
                if lobby.clients[i] == playerId then
                    isHost = false
                    lobbyIndex = index
                    break
                end
            end
        end
        
        if not isHost then
            local hostPing = GetPlayerPing(lobbies[lobbyIndex].host)
            if hostPing == 0 then
                isHost = true
                lobbies[lobbyIndex].host = playerId
            end
        end
        
        return isHost
    end)
    
    RegisterServerCallback("17mov_construction:init", function(playerId)
        return {
            name = GetPlayerIdentity(playerId),
            source = playerId
        }
    end)
    
    RegisterServerCallback("17mov_Construction:CheckIfWallIsFree", function(playerId, hostId, wallIndex)
        local isWallFree = true
        for index, lobby in pairs(lobbies) do
            if lobby.host == hostId then
                if lobby.blockedWalls[wallIndex] then
                    isWallFree = false
                end
            end
        end
        return isWallFree
    end)
end)

RegisterNetEvent("17mov_construction:SendRequestToClient_sv")
AddEventHandler("17mov_construction:SendRequestToClient_sv", function(targetPlayerId)
    local senderId = source
    
    for index, lobby in pairs(lobbies) do
        if lobby.host == targetPlayerId then
            Notify(senderId, Config.Lang.isAlreadyHost)
            return
        else
            for i = 1, #lobby.clients do
                if lobby.clients[i] == targetPlayerId then
                    Notify(senderId, Config.Lang.isBusy)
                    return
                end
            end
        end
    end
    
    for index, invite in pairs(pendingInvites) do
        if invite.client == targetPlayerId then
            Notify(senderId, Config.Lang.hasActiveInvite)
            return
        end
        if invite.host == senderId and invite.client ~= nil then
            Notify(senderId, Config.Lang.HaveActiveInvite)
            return
        end
    end
    
    local currentClients = {}
    for index, lobby in pairs(lobbies) do
        if lobby.host == senderId then
            currentClients = lobby.clients
        end
    end
    
    if #currentClients + 1 >= maxPartySize then
        Notify(senderId, Config.Lang.partyIsFull)
        return
    end
    
    table.insert(pendingInvites, {
        host = senderId,
        client = targetPlayerId
    })
    
    Notify(senderId, Config.Lang.inviteSent)
    TriggerClientEvent("17mov_construction:SendRequestToClient_cl", targetPlayerId, GetPlayerIdentity(senderId))
end)

RegisterNetEvent("17mov_construction:ClientReactRequest")
AddEventHandler("17mov_construction:ClientReactRequest", function(accepted)
    local clientId = source
    local hostId = nil
    local lobbyExists = false
    
    for index, invite in pairs(pendingInvites) do
        if invite.client == source then
            hostId = invite.host
            pendingInvites[index] = nil
            break
        end
    end
    
    if accepted then
        if hostId ~= nil and clientId ~= nil then
            for index, lobby in pairs(lobbies) do
                if lobby.host == hostId then
                    if lobby.clients ~= nil then
                        table.insert(lobby.clients, clientId)
                        lobbyExists = true
                    end
                end
            end
            
            if not lobbyExists then
                table.insert(lobbies, {
                    host = hostId,
                    clients = {clientId},
                    progress = 0,
                    blockedWalls = {}
                })
            end
            
            if Config.useModernUI then
                RecalculateRewards(hostId)
            end
            
            Notify(hostId, Config.Lang.InviteAccepted)
            local partyMugs = GetAllPartyMugs(hostId)
            TriggerForAllMembers(hostId, "17mov_construction:RefreshMugs", partyMugs)
        else
            Notify(source, Config.Lang.error)
            Notify(hostId, Config.Lang.error)
        end
    else
        Notify(hostId, Config.Lang.InviteDeclined)
    end
end)

RegisterNetEvent("17mov_construction:KickPlayerFromLobby")
AddEventHandler("17mov_construction:KickPlayerFromLobby", function(targetPlayerId, shouldNotify, kickedPlayerId)
    local kickedId = targetPlayerId
    local hostId = nil
    
    if kickedPlayerId == nil then
        hostId = source
        for index, lobby in pairs(lobbies) do
            for i = 1, #lobby.clients do
                if lobby.host == hostId and lobby.clients[i] == kickedId then
                    lobby.clients[i] = nil
                    break
                end
            end
        end
    else
        for index, lobby in pairs(lobbies) do
            for i = 1, #lobby.clients do
                if lobby.clients[i] == kickedPlayerId then
                    hostId = lobby.host
                    lobby.clients[i] = nil
                    break
                end
            end
        end
    end
    
    if shouldNotify then
        Notify(kickedId, Config.Lang.kickedOut)
    end
    
    if Config.useModernUI then
        local soloMugs = {
            {
                id = kickedId,
                name = GetPlayerIdentity(kickedId),
                isHost = true
            }
        }
        TriggerClientEvent("17mov_construction:RefreshMugs", kickedId, soloMugs, kickedId)
        TriggerClientEvent("17mov_construction:clearMyLobby", kickedId)
        TriggerClientEvent("17mov_construction:SetMyReward", kickedId, 100)
        
        local partyMugs = GetAllPartyMugs(hostId)
        TriggerForAllMembers(hostId, "17mov_construction:RefreshMugs", partyMugs)
        RecalculateRewards(hostId)
        
        for index, lobby in pairs(lobbies) do
            if #lobby.clients == 0 and lobby.host == hostId then
                lobbies[index] = nil
                TriggerClientEvent("17mov_construction:clearMyLobby", hostId)
            end
        end
    else
        local soloMugs = {
            {
                id = kickedId,
                name = GetPlayerIdentity(kickedId),
                isHost = true
            }
        }
        TriggerClientEvent("17mov_construction:RefreshMugs", kickedId, soloMugs, kickedId)
        
        local partyMugs = GetAllPartyMugs(hostId)
        TriggerForAllMembers(hostId, "17mov_construction:RefreshMugs", partyMugs)
        
        for index, lobby in pairs(lobbies) do
            if #lobby.clients == 0 and lobby.host == hostId then
                lobbies[index] = nil
            end
        end
    end
end)

RegisterNetEvent("17movement_builder:disableCustomTask")
AddEventHandler("17movement_builder:disableCustomTask", function(hostId, taskId)
    TriggerForAllMembers(hostId, "17mov_construction:disableThisCustomTask", taskId)
end)

RegisterNetEvent("17mov_builder:CustomTaskDone")
AddEventHandler("17mov_builder:CustomTaskDone", function(hostId, taskData, taskIndex)
    local playerId = source
    local lobbyIndex = nil
    
    for index, lobby in pairs(lobbies) do
        if hostId == lobby.host then
            lobbyIndex = index
        end
    end
    
    if not lobbyIndex then
        return
    end
    
    local locationIndex = lobbies[lobbyIndex].randomLocation
    
    if taskIndex then
        if taskData.progressValue ~= Config.JobLocations[locationIndex].customTasks[taskIndex].progressValue then
            return
        end
    end
    
    local taskCoords = vec3(
        Config.JobLocations[locationIndex].customTasks[taskIndex].pedInteractionCoords.x,
        Config.JobLocations[locationIndex].customTasks[taskIndex].pedInteractionCoords.y,
        Config.JobLocations[locationIndex].customTasks[taskIndex].pedInteractionCoords.z
    )
    
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local distance = #(taskCoords - playerCoords)
    
    if distance > 10.0 then
        return
    end
    
    if not lobbies[lobbyIndex].completedCustomTasks then
        lobbies[lobbyIndex].completedCustomTasks = {}
    end
    
    if lobbies[lobbyIndex].completedCustomTasks[taskIndex] then
        return
    end
    
    local cooldownTime = 5000
    local currentTime = GetGameTimer()
    
    if customTaskCooldowns[playerId] then
        if currentTime - customTaskCooldowns[playerId] < cooldownTime then
            return
        end
    end
    
    customTaskCooldowns[playerId] = currentTime
    lobbies[lobbyIndex].completedCustomTasks[taskIndex] = true
    
    for index, lobby in pairs(lobbies) do
        if hostId == lobby.host then
            AddLobbyProgress(lobby, taskData.progressValue)
            TriggerForAllMembers(hostId, "17mov_constructionJob:refreshProgressValue", lobby.progress)
            break
        end
    end
    
    TriggerForAllMembers(hostId, "17mov_Builder:SpawnCustomProps", taskData, taskIndex)
end)

RegisterNetEvent("17mov_Construction:DisableThisPipe")
AddEventHandler("17mov_Construction:DisableThisPipe", function(hostId, pipeId)
    TriggerForAllMembers(hostId, "17mov_construction:disableThisPipe", pipeId)
end)

RegisterNetEvent("17mov_construction:PourConcrete")
AddEventHandler("17mov_construction:PourConcrete", function(hostId, concreteData, holeData)
    local playerId = source
    local lobbyIndex = nil
    
    for index, lobby in pairs(lobbies) do
        if hostId == lobby.host then
            lobbyIndex = index
        end
    end
    
    if not lobbyIndex then
        return
    end
    
    local locationIndex = lobbies[lobbyIndex].randomLocation
    
    if holeData then
        if concreteData.progressValue ~= Config.JobLocations[locationIndex].mixerTargetLocations[holeData.holeIndex].concreteSettings.progressValue then
            return
        end
    end
    
    local concreteCoords = vec3(Config.JobLocations[locationIndex].mixerTargetLocations[holeData.holeIndex].concreteSettings.startingLoc.xyz)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local distance = #(concreteCoords - playerCoords)
    
    if distance > 10.0 then
        return
    end
    
    TriggerForAllMembers(hostId, "17mov_construction:PourConcrete_cl", concreteData, holeData)
    
    for index, lobby in pairs(lobbies) do
        if hostId == lobby.host then
            AddLobbyProgress(lobby, concreteData.progressValue)
            TriggerForAllMembers(hostId, "17mov_constructionJob:refreshProgressValue", lobby.progress)
            break
        end
    end
end)

RegisterNetEvent("17mov_Construction:SpawnPipe_SV")
AddEventHandler("17mov_Construction:SpawnPipe_SV", function(hostId, pipeData, pipeInfo)
    local playerId = source
    local lobbyIndex = nil
    
    for index, lobby in pairs(lobbies) do
        if hostId == lobby.host then
            lobbyIndex = index
        end
    end
    
    if not lobbyIndex then
        return
    end
    
    if not lobbies[lobbyIndex].builtPipes then
        lobbies[lobbyIndex].builtPipes = {}
    end
    
    local locationIndex = lobbies[lobbyIndex].randomLocation
    local pipeKey = string.format("%d-%d", pipeInfo.holeIndex, pipeInfo.pipeIndex)
    
    if lobbies[lobbyIndex].builtPipes[pipeKey] then
        return
    end
    
    local cooldownTime = Config.PipeInstallingTime * 0.8
    local currentTime = GetGameTimer()
    
    if pipeInstallationCooldowns[playerId] then
        if currentTime - pipeInstallationCooldowns[playerId] < cooldownTime then
            return
        end
    end
    
    pipeInstallationCooldowns[playerId] = currentTime
    
    if pipeInfo then
        if pipeData.progressValue ~= Config.JobLocations[locationIndex].mixerTargetLocations[pipeInfo.holeIndex].pipes[pipeInfo.pipeIndex].progressValue then
            return
        end
    end
    
    local pipeCoords = vec3(Config.JobLocations[locationIndex].mixerTargetLocations[pipeInfo.holeIndex].pipes[pipeInfo.pipeIndex].pedInstallingCoords.xyz)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local distance = #(pipeCoords - playerCoords)
    
    if distance > 10.0 then
        return
    end
    
    TriggerForAllMembers(hostId, "17mov_ConstructionJob:SpawnPipe", pipeData, pipeInfo)
    
    for index, lobby in pairs(lobbies) do
        if hostId == lobby.host then
            AddLobbyProgress(lobby, pipeData.progressValue)
            TriggerForAllMembers(hostId, "17mov_constructionJob:refreshProgressValue", lobby.progress)
            break
        end
    end
    
    lobbies[lobbyIndex].builtPipes[pipeKey] = true
end)

RegisterNetEvent("17mov_constructionJob:RemoveMixerPickupBlip")
AddEventHandler("17mov_constructionJob:RemoveMixerPickupBlip", function(hostId, mixerCoords)
    TriggerForAllMembers(hostId, "17mov_constructionJob:RemoveMixerPickupBlip_cl")
    
    for index, spawn in pairs(Config.MixerSpawns) do
        if spawn.coords == mixerCoords then
            spawn.avalible = true
        end
    end
end)

RegisterNetEvent("17mov_constructionJob:sendMixer")
AddEventHandler("17mov_constructionJob:sendMixer", function(hostId, mixerNetId)
    for index, lobby in pairs(lobbies) do
        if lobby.host == hostId then
            lobby.mixerNetId = mixerNetId
        end
    end
    TriggerForAllMembers(hostId, "17mov_constructionJob:sendMixer_cl", mixerNetId)
end)

RegisterNetEvent("17mov_constructionJob:deleteBlockFromSpawn")
AddEventHandler("17mov_constructionJob:deleteBlockFromSpawn", function(hostId, blockId)
    TriggerForAllMembers(hostId, "17mov_constructionJob:deleteBlockFromSpawn_cl", blockId)
end)

RegisterNetEvent("17mov_constructionJob:installBlockOnWall")
AddEventHandler("17mov_constructionJob:installBlockOnWall", function(hostId, blockData, progressValue)
    local playerId = source
    local cooldownTime = Config.WallBuildingTime * 0.8
    local currentTime = GetGameTimer()
    
    if wallBuildingCooldowns[playerId] then
        if currentTime - wallBuildingCooldowns[playerId] < cooldownTime then
            print("Install block event REJECTED - Player %s installing blocks too fast. Current Time: %s Last value: %s Cooldown time: %s",
                playerId, currentTime, wallBuildingCooldowns[playerId], cooldownTime)
            return
        end
    end
    
    wallBuildingCooldowns[playerId] = currentTime
    
    local lobbyIndex = nil
    for index, lobby in pairs(lobbies) do
        if hostId == lobby.host then
            lobbyIndex = index
        end
    end
    
    if not lobbyIndex then
        return
    end
    
    local locationIndex = lobbies[lobbyIndex].randomLocation
    
    if blockData.wallIndex and blockData.placeIndex then
        if progressValue ~= Config.JobLocations[locationIndex].walls[blockData.wallIndex].blocksInFrameLocations[blockData.placeIndex].progressValue then
            return
        end
    end
    
    local blockCoords = vec3(Config.JobLocations[locationIndex].walls[blockData.wallIndex].blocksInFrameLocations[blockData.placeIndex].coords.xyz)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local distance = #(blockCoords - playerCoords)
    
    if distance > 12.0 then
        return
    end
    
    if not lobbies[lobbyIndex].completedBlockInstallations then
        lobbies[lobbyIndex].completedBlockInstallations = {}
    end
    
    if lobbies[lobbyIndex].completedBlockInstallations[blockData] then
        return
    end
    
    if lobbies[lobbyIndex].blockedWalls[blockData.wallIndex] then
        return
    end
    
    lobbies[lobbyIndex].completedBlockInstallations[blockData] = true
    TriggerForAllMembers(hostId, "17mov_constructionJob:installBlockOnWall_cl", blockData)
    
    local targetLobbyIndex = 0
    for index, lobby in pairs(lobbies) do
        if hostId == lobby.host then
            AddLobbyProgress(lobby, progressValue)
            TriggerForAllMembers(hostId, "17mov_constructionJob:refreshProgressValue", lobby.progress)
            lobby.blockedWalls[blockData.wallIndex] = true
            targetLobbyIndex = index
            break
        end
    end
    
    Citizen.Wait(Config.WallBuildingTime)
    lobbies[targetLobbyIndex].blockedWalls[blockData.wallIndex] = nil
end)

RegisterNetEvent("17mov_constructionJob:weldingReady")
AddEventHandler("17mov_constructionJob:weldingReady", function(hostId, weldingIndex, progressValue)
    local playerId = source
    local lobbyIndex = nil
    
    for index, lobby in pairs(lobbies) do
        if hostId == lobby.host then
            lobbyIndex = index
        end
    end
    
    if not lobbyIndex then
        return
    end
    
    local locationIndex = lobbies[lobbyIndex].randomLocation
    
    if weldingIndex then
        if progressValue ~= Config.JobLocations[locationIndex].welding[weldingIndex].progressValue then
            return
        end
    end
    
    local cooldownTime = Config.WeldingTime * 0.8
    local currentTime = GetGameTimer()
    
    if weldingCooldowns[playerId] then
        if currentTime - weldingCooldowns[playerId] < cooldownTime then
            return
        end
    end
    
    weldingCooldowns[playerId] = currentTime
    
    local weldingCoords = vec3(
        Config.JobLocations[locationIndex].welding[weldingIndex].coords.x,
        Config.JobLocations[locationIndex].welding[weldingIndex].coords.y,
        Config.JobLocations[locationIndex].welding[weldingIndex].coords.z
    )
    
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local distance = #(weldingCoords - playerCoords)
    
    if distance > 10.0 then
        return
    end
    
    if not lobbies[lobbyIndex].completedWeldings then
        lobbies[lobbyIndex].completedWeldings = {}
    end
    
    if lobbies[lobbyIndex].completedWeldings[weldingIndex] then
        return
    end
    
    lobbies[lobbyIndex].completedWeldings[weldingIndex] = true
    TriggerForAllMembers(hostId, "17mov_constructionJob:disableWeldingBlip", weldingIndex)
    
    for index, lobby in pairs(lobbies) do
        if hostId == lobby.host then
            AddLobbyProgress(lobby, progressValue)
            TriggerForAllMembers(hostId, "17mov_constructionJob:refreshProgressValue", lobby.progress)
            break
        end
    end
end)

local playerCooldowns = {}
local CooldownsTime = {}

local function FormatCooldownRemaining(remaining)
    local hours = math.floor(remaining / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    local seconds = remaining % 60

    local timeString = ""
    if hours > 0 then
        timeString = timeString .. hours .. Config.Lang.hours .. " "
    end
    if minutes > 0 then
        timeString = timeString .. minutes .. Config.Lang.minutes .. " "
    end
    return timeString .. seconds .. Config.Lang.seconds
end

local function ClearJobCooldownForLicense(license)
    if not license then
        return
    end

    playerCooldowns[license] = nil
    CooldownsTime[license] = nil
end

local function SetJobCooldownForLicense(license, timestamp)
    if not license then
        return
    end

    playerCooldowns[license] = true
    CooldownsTime[license] = timestamp
end

local function GetJobCooldownRemaining(license, currentTimestamp)
    if Config.JobCooldown <= 0 or not playerCooldowns[license] then
        return 0
    end

    local timeDiff = currentTimestamp - (CooldownsTime[license] or 0)
    if timeDiff >= Config.JobCooldown then
        ClearJobCooldownForLicense(license)
        return 0
    end

    return Config.JobCooldown - timeDiff
end

local function HandleEndJobCooldown(allMembers, finalProgress)
    if Config.JobCooldown <= 0 then
        return
    end

    local minProgress = tonumber(Config.VehicleDepositRefundMinProgress) or 90
    local currentTimestamp = os.time()

    for i = 1, #allMembers do
        local license = GetPlayerIdentifierByType(allMembers[i], "license")
        if finalProgress >= minProgress then
            ClearJobCooldownForLicense(license)
        else
            SetJobCooldownForLicense(license, currentTimestamp)
        end
    end
end

RegisterNetEvent("17mov_construction:endJob_sv")
AddEventHandler("17mov_construction:endJob_sv", function(jobCompleted, vehicleNetId)
    local playerId = source
    TriggerForAllMembers(playerId, "17mov_construction:endJob_cl", 0)
    
    for index, lobby in pairs(lobbies) do
        if lobby.host == source then
            local finalProgress = lobby.progress
            lobby.progress = 0
            
            DeleteEntity(NetworkGetEntityFromNetworkId(lobby.mixerNetId))
            DeleteEntity(NetworkGetEntityFromNetworkId(vehicleNetId))
            
            lobby.working = false
            lobby.builtPipes = {}
            lobby.completedWeldings = {}
            lobby.completedBlockInstallations = {}
            lobby.completedCustomTasks = {}

            if lobby.vehicleDepositPaid then
                local depositAmount = lobby.vehicleDepositAmount or tonumber(Config.VehicleDeposit) or 0
                local minProgress = tonumber(Config.VehicleDepositRefundMinProgress) or 90
                local depositPayers = lobby.vehicleDepositPayers or { lobby.host }
                local accountType = Config.VehicleDepositAccount or "cash"

                if jobCompleted and finalProgress >= minProgress and depositAmount > 0 then
                    for i = 1, #depositPayers do
                        RefundVehicleDeposit(depositPayers[i], depositAmount, accountType)
                        Notify(depositPayers[i], Config.Lang.vehicleDepositRefunded .. depositAmount)
                    end
                elseif jobCompleted and finalProgress < minProgress then
                    for i = 1, #depositPayers do
                        Notify(depositPayers[i], string.format(Config.Lang.vehicleDepositNotRefunded, minProgress))
                    end
                end

                lobby.vehicleDepositPaid = false
                lobby.vehicleDepositAmount = nil
                lobby.vehicleDepositPayers = nil
            end
            
            local allMembers = {}
            for i = 1, #lobby.clients do
                table.insert(allMembers, lobby.clients[i])
            end
            table.insert(allMembers, lobby.host)

            HandleEndJobCooldown(allMembers, finalProgress)
            
            local playerCount = #allMembers
            local baseReward = finalProgress * Config.OnePercentWorth
            if Config.multiplyRewardWhileWorkingInGroup then
                baseReward = math.floor(baseReward * playerCount)
            end
            local rewardPerPlayer = CalcRewardPerPlayer(baseReward, playerCount)
            
            if Config.useModernUI and #lobby.clients == 0 then
                RecalculateRewards(playerId)
            end
            
            local paidPlayers = {}
            for i = 1, #allMembers do
                local memberReward = 0
                
                if Config.useModernUI and Config.letBossSplitReward then
                    memberReward = math.floor((lobby.rewardsOptions[allMembers[i]] / 100) * rewardPerPlayer)
                elseif not Config.useModernUI and Config.splitReward then
                    memberReward = math.floor(baseReward / playerCount)
                else
                    memberReward = rewardPerPlayer
                end
                
                if not jobCompleted then
                    PayPenalty(allMembers[i], Config.PenaltyAmount)
                    Notify(allMembers[i], Config.Lang.penalty .. Config.PenaltyAmount)
                end
                
                if jobCompleted or not Config.DontPayRewardWithoutVehicle then
                    CreateThread(function()
                        if not paidPlayers[allMembers[i]] then
                            paidPlayers[allMembers[i]] = true
                            local multiplier = Config.JobLocations[lobby.randomLocation].paymentMultipler or 1.0
                            Pay(allMembers[i], memberReward * multiplier, #allMembers, finalProgress)
                            Notify(allMembers[i], Config.Lang.reward .. (memberReward * multiplier))
                        end
                    end)
                end
            end
            
            if #lobby.clients == 0 then
                lobbies[index] = nil
                TriggerClientEvent("17mov_construction:clearMyLobby", playerId)
            end
        end
    end
end)

local lastStartTime = 0
local startCooldown = 3000

local function TryChargeVehicleDeposit(hostId, lobbyIndex)
    if not Config.EnableVehicleDeposit then
        return true
    end

    local depositAmount = tonumber(Config.VehicleDeposit) or 0
    if depositAmount <= 0 then
        return true
    end

    local accountType = Config.VehicleDepositAccount or "cash"
    local lobby = lobbies[lobbyIndex]
    local members = { hostId }

    if lobby.clients ~= nil then
        for i = 1, #lobby.clients do
            if lobby.clients[i] ~= nil then
                table.insert(members, lobby.clients[i])
            end
        end
    end

    for i = 1, #members do
        if not HasEnoughMoney(members[i], depositAmount, accountType) then
            if members[i] == hostId then
                Notify(hostId, string.format(Config.Lang.notEnoughForDeposit, depositAmount))
            else
                Notify(hostId, string.format(Config.Lang.notEnoughForDepositTeam, GetPlayerIdentity(members[i]), depositAmount))
            end
            return false
        end
    end

    local chargedMembers = {}
    for i = 1, #members do
        if not ChargeVehicleDeposit(members[i], depositAmount, accountType) then
            for j = 1, #chargedMembers do
                RefundVehicleDeposit(chargedMembers[j], depositAmount, accountType)
            end
            if members[i] == hostId then
                Notify(hostId, string.format(Config.Lang.notEnoughForDeposit, depositAmount))
            else
                Notify(hostId, string.format(Config.Lang.notEnoughForDepositTeam, GetPlayerIdentity(members[i]), depositAmount))
            end
            return false
        end
        table.insert(chargedMembers, members[i])
        Notify(members[i], Config.Lang.vehicleDepositCharged .. depositAmount)
    end

    lobby.vehicleDepositPaid = true
    lobby.vehicleDepositAmount = depositAmount
    lobby.vehicleDepositPayers = chargedMembers
    return true
end

RegisterNetEvent("17mov_construction:StartJob_sv")
AddEventHandler("17mov_construction:StartJob_sv", function()
    local playerId = source
    local currentTime = GetGameTimer()
    
    if currentTime - lastStartTime <= startCooldown then
        Notify(playerId, Config.Lang.wait)
        return
    end
    
    lastStartTime = currentTime
    
    local currentClients = nil
    local lobbyIndex = 0
    
    for index, lobby in pairs(lobbies) do
        if lobby.host == playerId then
            currentClients = lobby.clients
            lobbyIndex = index
            break
        end
    end
    
    if Config.RequireJobAlsoForFriends and Config.RequiredJob ~= "none" and currentClients ~= nil then
        for i = 1, #currentClients do
            if GetPlayerJob(currentClients[i]) ~= Config.RequiredJob then
                Notify(playerId, Config.Lang.notEverybodyHasRequiredJob)
                return
            end
        end
    end
    
    if not IsHaveRequiredItem(playerId) then
        Notify(playerId, Config.Lang.dontHaveReqItem)
        return
    end
    
    if Config.RequireItemFromWholeTeam and currentClients ~= nil then
        for i = 1, #currentClients do
            if not IsHaveRequiredItem(currentClients[i]) then
                Notify(playerId, Config.Lang.dontHaveReqItem)
                return
            end
        end
    end
    
    local currentTimestamp = os.time()
    local playerLicense = GetPlayerIdentifierByType(playerId, "license")

    local hostCooldownRemaining = GetJobCooldownRemaining(playerLicense, currentTimestamp)
    if hostCooldownRemaining > 0 then
        Notify(playerId, string.format(
            Config.Lang.someoneIsOnCooldown,
            GetPlayerIdentity(playerId),
            FormatCooldownRemaining(hostCooldownRemaining)
        ))
        return
    end

    if currentClients ~= nil then
        for i = 1, #currentClients do
            local clientLicense = GetPlayerIdentifierByType(currentClients[i], "license")
            local clientCooldownRemaining = GetJobCooldownRemaining(clientLicense, currentTimestamp)
            if clientCooldownRemaining > 0 then
                Notify(playerId, string.format(
                    Config.Lang.someoneIsOnCooldown,
                    GetPlayerIdentity(currentClients[i]),
                    FormatCooldownRemaining(clientCooldownRemaining)
                ))
                return
            end
        end
    end
    
    math.randomseed(os.time())
    local randomLocation = math.random(1, #Config.JobLocations)
    
    if Config.RequireOneFriendMinimum then
        if currentClients ~= nil and #currentClients > 0 then
            if not TryChargeVehicleDeposit(playerId, lobbyIndex) then
                return
            end

            lobbies[lobbyIndex].working = true
            lobbies[lobbyIndex].randomLocation = randomLocation
            lobbies[lobbyIndex].mixerCoords = mixerCoords
            
            TriggerForAllMembers(playerId, "17mov_construction:StartJob_cl", playerId, lobbies[lobbyIndex].randomLocation, #lobbies[lobbyIndex].clients + 1)
        else
            Notify(playerId, Config.Lang.RequireOneFriend)
        end
    else
        if currentClients == nil then
            table.insert(lobbies, {
                host = playerId,
                clients = {},
                progress = 0,
                blockedWalls = {}
            })
        end
        
        for index, lobby in pairs(lobbies) do
            if lobby.host == playerId then
                lobbyIndex = index
            end
        end

        if not TryChargeVehicleDeposit(playerId, lobbyIndex) then
            return
        end
        
        lobbies[lobbyIndex].randomLocation = randomLocation
        lobbies[lobbyIndex].working = true
        lobbies[lobbyIndex].mixerCoords = mixerCoords
        
        TriggerForAllMembers(playerId, "17mov_construction:StartJob_cl", playerId, lobbies[lobbyIndex].randomLocation, #lobbies[lobbyIndex].clients + 1)
    end
end)

function GetAllPartyMugs(hostId)
    local partyMembers = {}
    local clients = {}
    local lobbyIndex = 0
    
    for index, lobby in pairs(lobbies) do
        if hostId == lobby.host then
            lobbyIndex = index
            clients = lobby.clients
        end
    end
    
    if Config.useModernUI then
        for i = 1, #clients do
            table.insert(partyMembers, {
                id = clients[i],
                name = GetPlayerIdentity(clients[i]),
                isHost = false,
                rewardPercent = lobbies[lobbyIndex].rewardsOptions[clients[i]]
            })
        end
        
        if #clients == 0 then
            table.insert(partyMembers, {
                id = hostId,
                name = GetPlayerIdentity(hostId),
                isHost = true,
                rewardPercent = lobbies[lobbyIndex].rewardsOptions[hostId]
            })
        else
            table.insert(partyMembers, {
                id = hostId,
                name = GetPlayerIdentity(hostId),
                isHost = true,
                rewardPercent = lobbies[lobbyIndex].rewardsOptions[hostId]
            })
        end
    else
        for i = 1, #clients do
            table.insert(partyMembers, {
                id = clients[i],
                name = GetPlayerIdentity(clients[i]),
                isHost = false
            })
        end
        
        if #clients == 0 then
            table.insert(partyMembers, {
                id = hostId,
                name = GetPlayerIdentity(hostId),
                isHost = true
            })
        else
            table.insert(partyMembers, {
                id = hostId,
                name = GetPlayerIdentity(hostId),
                isHost = true
            })
        end
    end
    
    return partyMembers
end

function TriggerForAllMembers(hostId, eventName, arg1, arg2, arg3, arg4, arg5)
    local clients = {}
    for index, lobby in pairs(lobbies) do
        if hostId == lobby.host then
            clients = lobby.clients
        end
    end
    
    for i = 1, #clients + 1 do
        local memberId = clients[i]
        if i > #clients then
            memberId = hostId
        end
        
        if memberId ~= nil and type(memberId) == "number" then
            if eventName == "17mov_construction:RefreshMugs" then
                TriggerClientEvent(eventName, memberId, arg1, memberId, arg2, arg3)
            elseif eventName == "17mov_construction:StartJob_cl" then
                TriggerClientEvent(eventName, memberId, arg1, memberId, arg2, arg3, arg4)
            elseif eventName == "17mov_constructionJob:sendMixer_cl" then
                TriggerClientEvent(eventName, memberId, arg1, memberId, hostId)
            else
                TriggerClientEvent(eventName, memberId, arg1, arg2)
            end
        end
    end
end

RegisterNetEvent("17mov_construction:SendVehicleNetId")
AddEventHandler("17mov_construction:SendVehicleNetId", function(vehicleNetId)
    local playerId = source
    for index, lobby in pairs(lobbies) do
        if lobby.host == playerId then
            lobby.vehNetId = vehicleNetId
            break
        end
    end
end)

AddEventHandler("playerDropped", function()
    local droppedPlayerId = source
    local lobbyIndex = "waiting"
    
    for index, lobby in pairs(lobbies) do
        if lobby.host == droppedPlayerId then
            for i = 1, #lobby.clients do
                if GetPlayerPing(lobby.clients[i]) ~= 0 then
                    lobby.host = lobby.clients[i]
                    Notify(lobby.clients[i], Config.Lang.newBoss)
                    lobby.clients[i] = nil
                    break
                end
            end
            lobbyIndex = index
            break
        end
        
        for i = 1, #lobby.clients do
            if lobby.clients[i] == droppedPlayerId then
                lobby.clients[i] = nil
                lobbyIndex = index
                break
            end
        end
    end
    
    if lobbyIndex == "waiting" then
        return
    end
    
    local hostId = lobbies[lobbyIndex].host
    local isWorking = lobbies[lobbyIndex].working
    
    if isWorking then
        if #lobbies[lobbyIndex].clients == 0 then
            TriggerClientEvent("17mov_construction:clearMyLobby", hostId)
        else
            TriggerForAllMembers(hostId, "17mov_construction:RefreshMugs", GetAllPartyMugs(hostId))
            if Config.useModernUI then
                RecalculateRewards(hostId)
            end
        end
    else
        if #lobbies[lobbyIndex].clients == 0 then
            TriggerClientEvent("17mov_construction:clearMyLobby", hostId)
            lobbies[lobbyIndex] = nil
        end
    end
    
    if wallBuildingCooldowns[droppedPlayerId] ~= nil then
        wallBuildingCooldowns[droppedPlayerId] = nil
    end
    
    if customTaskCooldowns[droppedPlayerId] ~= nil then
        customTaskCooldowns[droppedPlayerId] = nil
    end
    
    if pipeInstallationCooldowns[droppedPlayerId] ~= nil then
        pipeInstallationCooldowns[droppedPlayerId] = nil
    end
    
    if weldingCooldowns[droppedPlayerId] ~= nil then
        weldingCooldowns[droppedPlayerId] = nil
    end
end)