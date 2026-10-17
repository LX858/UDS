
local scriptInitialized = false
local jobVehicle = nil
local mixerVehicle = nil
OnDuty = false
JobVehicleNetId = nil
local tutorialActive = false
local carryingBlock = false
local progressValue = 0
local mixerBlip = nil
local jobData = {}
local spawnedObjects = {}
local currentProgress = 0
local currentCounter = 0
local totalProgress = 0
local wearingUniform = false
local pendingCallbacks = {}
local callbackId = 0
local nearbyPlayers = {}
local myServerId = GetPlayerServerId(PlayerId())
local menuOpen = true
local tutorialName = ""
local driverLoaded = false
local nuiLoaded = false

RegisterNUICallback("driverLoaded", function()
    driverLoaded = true
end)

RegisterNUICallback("nuiLoaded", function()
    nuiLoaded = true
end)

CreateThread(function()
    while true do
        if driverLoaded then
            break
        end
        Citizen.Wait(100)
    end
    
    if Config.useModernUI then
        SendNUIMessage({
            ui = "new"
        })
    else
        SendNUIMessage({
            ui = "old"
        })
        nuiLoaded = true
        Citizen.Wait(500)
    end
    
    while true do
        if nuiLoaded then
            break
        end
        Citizen.Wait(100)
    end
    
    SendNUIMessage({
        action = "setProgressBarAlign",
        align = Config.ProgressBarAlign,
        offset = Config.ProgressBarOffset
    })
    
    if not Config.EnableCloakroom then
        SendNUIMessage({
            action = "hideCloakroom"
        })
    end
end)

if Config.useModernUI then
    RegisterNUICallback("tutorialClosed", function()
        SetNuiFocus(false, false)
        tutorialActive = false
        tutorialName = ""
    end)
    
    RegisterNetEvent("17mov_construction:UpdateHostPercentages")
    AddEventHandler("17mov_construction:UpdateHostPercentages", function(data)
        SendNUIMessage({
            action = "updateHostRewards",
            value = data
        })
    end)
    
    RegisterNUICallback("menuClosed", function()
        menuOpen = false
        SetNuiFocus(false, false)
    end)
    
    RegisterNUICallback("dontShowTutorialAgain", function(data, cb)
        SetResourceKvpInt("17mov_Tutorials:" .. tutorialName, 1)
    end)
    
    RegisterNetEvent("17mov_construction:SetMyReward")
    AddEventHandler("17mov_construction:SetMyReward", function(reward)
        SendNUIMessage({
            action = "updateMyReward",
            reward = reward
        })
    end)
    
    if Config.letBossSplitReward then
        RegisterNUICallback("checkIfThisRewardIsFine", function(data, cb)
            local value = math.floor(data.value)
            local playerId = data.plyId
            
            if value > 100 or value < 0 then
                Notify(Config.Lang.wrongReward1)
                cb(false)
                return
            end
            
            TriggerServerCallback("17mov_construction:CheckThisReward", function(result)
                if result then
                    cb(true)
                else
                    cb(false)
                    Notify(Config.Lang.wrongReward2)
                end
            end, value, playerId)
        end)
    else
        CreateThread(function()
            while true do
                if nuiLoaded then
                    break
                end
                Citizen.Wait(100)
            end
            SendNUIMessage({
                action = "hideManageRewards"
            })
        end)
    end
    
    RegisterNetEvent("17mov_construction:clearMyLobby")
    AddEventHandler("17mov_construction:clearMyLobby", function()
        nearbyPlayers = {}
        TriggerServerCallback("17mov_construction:init", function(data)
            SendNUIMessage({
                action = "Init",
                name = data.name,
                myId = data.source
            })
            scriptInitialized = true
        end)
    end)
    
    RegisterNetEvent("17mov_construction:RefreshMugs")
    AddEventHandler("17mov_construction:RefreshMugs", function(players, hostId)
        while true do
            if scriptInitialized then
                break
            end
            Citizen.Wait(100)
        end
        
        for k, player in pairs(players) do
            SendNUIMessage({
                action = "DeleteNearbyPlayer",
                id = player.id
            })
            
            if nearbyPlayers[player.id] == nil then
                if myServerId == player.id then
                    nearbyPlayers[player.id] = {
                        name = player.name,
                        id = player.id,
                        isHost = player.isHost,
                        rewardPercent = player.rewardPercent,
                        itsMe = true
                    }
                else
                    nearbyPlayers[player.id] = {
                        name = player.name,
                        id = player.id,
                        isHost = player.isHost,
                        rewardPercent = player.rewardPercent,
                        itsMe = false
                    }
                end
                
                SendNUIMessage({
                    action = "addNewMember",
                    name = player.name,
                    id = player.id,
                    isHost = player.isHost,
                    rewardPercent = player.rewardPercent,
                    showQuitBtn = nearbyPlayers[player.id].itsMe
                })
            end
        end
        
        local memberCount = 0
        for playerId, playerData in pairs(nearbyPlayers) do
            local found = false
            for k, player in pairs(players) do
                if player.id == playerId then
                    found = true
                    break
                end
            end
            
            if not found then
                nearbyPlayers[playerId] = nil
                SendNUIMessage({
                    action = "DeletePlayer",
                    id = playerId
                })
            else
                memberCount = memberCount + 1
            end
        end
        
        if memberCount == 1 then
            TriggerServerCallback("17mov_construction:init", function(data)
                SendNUIMessage({
                    action = "Init",
                    name = data.name,
                    myId = data.source
                })
                scriptInitialized = true
            end)
        end
        
        TriggerServerCallback("17mov_construction:IfPlayerOwnsTeam", function(isOwner)
            SendNUIMessage({
                action = "ToggleHostHUD",
                boolean = isOwner
            })
        end)
    end)
else
    RegisterNetEvent("17mov_construction:RefreshMugs")
    AddEventHandler("17mov_construction:RefreshMugs", function(names, myId, hostStatus)
        while true do
            if scriptInitialized then
                break
            end
            Citizen.Wait(100)
        end
        
        Citizen.Wait(100)
        SendNUIMessage({
            action = "refreshMugs",
            names = names,
            myId = myId
        })
        
        TriggerServerCallback("17mov_construction:IfPlayerIsHost", function(isHost)
            SendNUIMessage({
                action = "HostStatusUpdate",
                status = isHost
            })
        end)
    end)
    
    RegisterNUICallback("GetClosestPlayers", function(data, cb)
        local activePlayers = GetActivePlayers()
        local myCoords = GetEntityCoords(PlayerPedId())
        local nearbyPlayerIds = {}
        
        for k, playerId in pairs(activePlayers) do
            if PlayerId() ~= playerId then
                local playerPed = GetPlayerPed(playerId)
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(myCoords - playerCoords)
                
                if distance < 20.0 then
                    table.insert(nearbyPlayerIds, GetPlayerServerId(playerId))
                end
            end
        end
        
        TriggerServerCallback("17mov_construction:IfPlayerIsHost", function(isHost)
            if isHost then
                TriggerServerCallback("17mov_construction:GetPlayersNames", function(playerNames)
                    cb(playerNames)
                    if #playerNames == 0 then
                        Notify(Config.Lang.nobodyNearby)
                    end
                end, nearbyPlayerIds)
            else
                Notify(Config.Lang.no_permission)
            end
        end)
    end)
end

function TriggerServerCallback(name, callback, ...)
    local id = callbackId
    callbackId = callbackId + 1
    pendingCallbacks[name] = {}
    pendingCallbacks[name][id] = callback
    TriggerServerEvent("17mov_Callbacks:GetResponse" .. GetCurrentResourceName(), name, id, ...)
end

RegisterNetEvent("17mov_Callbacks:receiveData" .. GetCurrentResourceName())
AddEventHandler("17mov_Callbacks:receiveData" .. GetCurrentResourceName(), function(name, id, ...)
    if pendingCallbacks[name] == nil then
        return
    end
    
    if pendingCallbacks[name][id] == nil then
        return
    end
    
    pendingCallbacks[name][id](...)
    
    if pendingCallbacks[name] ~= nil then
        if pendingCallbacks[name][id] ~= nil then
            pendingCallbacks[name][id] = nil
        end
    end
    
    if pendingCallbacks[name] ~= nil then
        if #pendingCallbacks[name] == 0 then
            pendingCallbacks[name] = nil
        end
    end
end)

local markersRunning = false

function StartMarkers(playerData)
    if markersRunning then
        return
    end
    
    if Config.RequiredJob ~= "none" then
        if playerData.job.name ~= Config.RequiredJob then
            markersRunning = false
            return
        end
    end
    
    markersRunning = true
    
    if Config.UseTarget then
        SpawnStartingPed()
        Config.Locations2 = {
            FinishJob = Config.Locations.FinishJob
        }
        
        while true do
            if not markersRunning then
                break
            end
            
            Citizen.Wait(0)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local isNearMarker = false
            local hasExited = false
            local shouldSleep = true
            local currentStation = nil
            local currentPart = nil
            local currentPartNum = nil
            
            if Config.RequiredJob ~= "none" then
                if playerData.job.name == Config.RequiredJob then
                end
            end
            
            if Config.RequiredJob == "none" then
                for stationName, stationData in pairs(Config.Locations2) do
                    if stationData.grade then
                        if not (playerData.job.grade >= stationData.grade) then
                            goto continue
                        end
                    end
                    
                    if OnDuty and stationData.type == "duty" then
                        goto continue
                    end
                    
                    for iterator, coords in pairs(stationData.Coords) do
                        local distance = #(playerCoords - coords)
                        
                        if distance < 20 then
                            if distance > stationData.scale.x then
                                DrawMarker(6, coords.x, coords.y, coords.z - 1, 0.0, 0.0, 0.0, -90.0, 0.0, 0.0,
                                    stationData.scale.x, stationData.scale.y, stationData.scale.z,
                                    Config.MarkerSettings.UnActive.r, Config.MarkerSettings.UnActive.g, Config.MarkerSettings.UnActive.b, Config.MarkerSettings.UnActive.a,
                                    false, false, 2, false, false, false, false)
                                shouldSleep = false
                            else
                                DrawMarker(6, coords.x, coords.y, coords.z - 1, 0.0, 0.0, 0.0, -90.0, 0.0, 0.0,
                                    stationData.scale.x, stationData.scale.y, stationData.scale.z,
                                    Config.MarkerSettings.Active.r, Config.MarkerSettings.Active.g, Config.MarkerSettings.Active.b, Config.MarkerSettings.Active.a,
                                    false, false, 2, false, false, false, false)
                                isNearMarker = true
                                currentStation = stationName
                                currentPart = stationName
                                currentPartNum = iterator
                                shouldSleep = false
                            end
                        end
                    end
                    ::continue::
                end
                
                if isNearMarker and not HasAlreadyEnteredMarker then
                elseif isNearMarker and (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum) then
                    if LastStation and LastPart and LastPartNum then
                        if not (LastStation == currentStation and LastPart == currentPart and LastPartNum == currentPartNum) then
                            TriggerEvent("17mov_construction:ExitedMarker", LastStation, LastPart, LastPartNum)
                            hasExited = true
                        end
                    end
                    
                    HasAlreadyEnteredMarker = true
                    LastStation = currentStation
                    LastPart = currentPart
                    LastPartNum = currentPartNum
                    TriggerEvent("17mov_construction:EnteredMarker", currentPart)
                end
                
                if not hasExited and not isNearMarker then
                    if HasAlreadyEnteredMarker then
                        HasAlreadyEnteredMarker = false
                        TriggerEvent("17mov_construction:ExitedMarker", LastStation, LastPart, LastPartNum)
                    end
                end
                
                if shouldSleep then
                    Citizen.Wait(500)
                end
            end
        end
        
        if spawnedPed then
            DeleteEntity(spawnedPed)
        end
        
        if SpawnedPed then
            DeleteEntity(SpawnedPed)
        end
    else
        while true do
            if not markersRunning then
                break
            end
            
            Citizen.Wait(0)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local isNearMarker = false
            local hasExited = false
            local shouldSleep = true
            local currentStation = nil
            local currentPart = nil
            local currentPartNum = nil
            
            if Config.RequiredJob ~= "none" then
                if playerData.job.name == Config.RequiredJob then
                end
            end
            
            if Config.RequiredJob == "none" then
                for stationName, stationData in pairs(Config.Locations) do
                    if stationData.grade then
                        if not (playerData.job.grade >= stationData.grade) then
                            goto continue
                        end
                    end
                    
                    if OnDuty then
                        if stationData.type == "duty" then
                            goto continue
                        end
                    end
                    
                    for iterator, coords in pairs(stationData.Coords) do
                        local distance = #(playerCoords - coords)
                        
                        if distance < 20 then
                            if distance > stationData.scale.x then
                                DrawMarker(6, coords.x, coords.y, coords.z - 1, 0.0, 0.0, 0.0, -90.0, 0.0, 0.0,
                                    stationData.scale.x, stationData.scale.y, stationData.scale.z,
                                    Config.MarkerSettings.UnActive.r, Config.MarkerSettings.UnActive.g, Config.MarkerSettings.UnActive.b, Config.MarkerSettings.UnActive.a,
                                    false, false, 2, false, false, false, false)
                                shouldSleep = false
                            else
                                DrawMarker(6, coords.x, coords.y, coords.z - 1, 0.0, 0.0, 0.0, -90.0, 0.0, 0.0,
                                    stationData.scale.x, stationData.scale.y, stationData.scale.z,
                                    Config.MarkerSettings.Active.r, Config.MarkerSettings.Active.g, Config.MarkerSettings.Active.b, Config.MarkerSettings.Active.a,
                                    false, false, 2, false, false, false, false)
                                isNearMarker = true
                                currentStation = stationName
                                currentPart = stationName
                                currentPartNum = iterator
                                shouldSleep = false
                            end
                        end
                    end
                    ::continue::
                end
                
                if isNearMarker and not HasAlreadyEnteredMarker then
                    HasAlreadyEnteredMarker = true
                    LastStation = currentStation
                    LastPart = currentPart
                    LastPartNum = currentPartNum
                    TriggerEvent("17mov_construction:EnteredMarker", currentPart)
                elseif isNearMarker and (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum) then
                    if LastStation and LastPart and LastPartNum then
                        if not (LastStation == currentStation and LastPart == currentPart and LastPartNum == currentPartNum) then
                            TriggerEvent("17mov_construction:ExitedMarker", LastStation, LastPart, LastPartNum)
                            hasExited = true
                        end
                    end
                    HasAlreadyEnteredMarker = true
                    LastStation = currentStation
                    LastPart = currentPart
                    LastPartNum = currentPartNum
                    TriggerEvent("17mov_construction:EnteredMarker", currentPart)
                end

                
                if not hasExited and not isNearMarker then
                    if HasAlreadyEnteredMarker then
                        HasAlreadyEnteredMarker = false
                        TriggerEvent("17mov_construction:ExitedMarker", LastStation, LastPart, LastPartNum)
                    end
                end
                
                if shouldSleep then
                    Citizen.Wait(500)
                end
            end
        end
    end
end

local playerData = nil

CreateThread(function()
    playerData = GetPlayerData()
    
    while true do
        if playerData ~= nil then
            if playerData.job ~= nil then
                break
            end
        end
        playerData = GetPlayerData()
        Citizen.Wait(1000)
    end
    
    if Config.RestrictBlipToRequiredJob then
        if Config.RequiredJob ~= playerData.job.name then
        else
            MakeBlip()
        end
    else
        MakeBlip()
    end
    
    Citizen.Wait(5000)
    StartMarkers(playerData)
end)

local blipCreated = false

function MakeBlip()
    if blipCreated then
        return
    end
    
    blipCreated = true
    
    for k, blipData in pairs(Config.Blips) do
        blipData.blip = AddBlipForCoord(blipData.Pos.x, blipData.Pos.y, blipData.Pos.z)
        SetBlipSprite(blipData.blip, blipData.Sprite)
        SetBlipDisplay(blipData.blip, 4)
        SetBlipScale(blipData.blip, blipData.Scale)
        SetBlipColour(blipData.blip, blipData.Color)
        SetBlipAsShortRange(blipData.blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(blipData.Label)
        EndTextCommandSetBlipName(blipData.blip)
    end
end

function DeleteBlip()
    blipCreated = false
    
    for k, blipData in pairs(Config.Blips) do
        RemoveBlip(blipData.blip)
        blipData.blip = nil
    end
end

local scriptLoaded = false

function InitalizeScript(fastLoad)
    if scriptLoaded then
        return
    end
    
    if Config.useModernUI then
        while true do
            if nuiLoaded then
                break
            end
            Citizen.Wait(100)
        end
    else
        Citizen.Wait(5500)
    end
    
    playerData = GetPlayerData()
    
    if not fastLoad then
        Citizen.Wait(5500)
    end
    
    scriptLoaded = true
    
    if Config.RequiredJob ~= "none" then
        if Config.RestrictBlipToRequiredJob then
            while true do
                if playerData ~= nil then
                    break
                end
                if playerData.job ~= nil then
                    break
                end
                playerData = GetPlayerData()
                Citizen.Wait(100)
            end
            
            if playerData.job.name ~= Config.RequiredJob then
                Config.RestrictBlipToRequiredJob = Config.RestrictBlipToRequiredJob
            end
            
            if not Config.RestrictBlipToRequiredJob then
                MakeBlip()
            end
        end
    else
        MakeBlip()
    end
    
    TriggerServerCallback("17mov_construction:init", function(data)
        SendNUIMessage({
            action = "Init",
            name = data.name,
            myId = data.source
        })
        scriptInitialized = true
    end)
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    InitalizeScript()
end)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function()
    InitalizeScript()
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate")
AddEventHandler("QBCore:Client:OnJobUpdate", function(job)
    playerData = GetPlayerData()
    
    if Config.RequiredJob ~= "none" then
        if Config.RestrictBlipToRequiredJob then
            if playerData.job.name == Config.RequiredJob then
            else
                Config.RestrictBlipToRequiredJob = Config.RestrictBlipToRequiredJob
            end
        end
    end
    
    if not Config.RestrictBlipToRequiredJob then
        MakeBlip()
    else
        DeleteBlip()
    end
    
    if Config.RequiredJob ~= "none" then
        if playerData.job.name == Config.RequiredJob then
        else
            Config.RequiredJob = Config.RequiredJob
        end
    end
    
    if Config.RequiredJob == "none" then
        StartMarkers(playerData)
    else
        markersRunning = false
    end
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(job)
    while true do
        if playerData ~= nil then
            if playerData.job ~= nil then
                break
            end
        end
        playerData = GetPlayerData()
        Citizen.Wait(1000)
    end
    
    playerData.job = job
    
    if Config.RequiredJob ~= "none" then
        if Config.RestrictBlipToRequiredJob then
            if playerData.job.name == Config.RequiredJob then
            else
                Config.RestrictBlipToRequiredJob = Config.RestrictBlipToRequiredJob
            end
        end
    end
    
    if not Config.RestrictBlipToRequiredJob then
        MakeBlip()
    else
        DeleteBlip()
    end
    
    if Config.RequiredJob ~= "none" then
        if playerData.job.name == Config.RequiredJob then
        else
            Config.RequiredJob = Config.RequiredJob
        end
    end
    
    if Config.RequiredJob == "none" then
        StartMarkers(playerData)
    else
        markersRunning = false
    end
end)

AddEventHandler("17mov_construction:EnteredMarker", function(markerName)
    CurrentAction = Config.Locations[markerName].CurrentAction
    CurrentActionMsg = Config.Locations[markerName].CurrentActionMsg
    CurrentActionStation = markerName
    
    for i = 0, 500 do
        Citizen.Wait(0)
        ShowHelpNotification(CurrentActionMsg)
    end
end)

AddEventHandler("17mov_construction:ExitedMarker", function(station)
    CurrentAction = nil
    CurrentActionMsg = nil
    CurrentActionStation = nil
end)

RegisterCommand("+17MovConstructionJobStartMarkerAction", function()
end, false)

RegisterCommand("-17MovConstructionJobStartMarkerAction", function()
    if CurrentAction ~= nil then
        if CurrentAction == "open_dutyToggle" then
            OpenDutyMenu()
        elseif CurrentAction == "finish_job" then
            TriggerServerCallback("17mov_construction:IfPlayerIsHost", function(isHost)
                if isHost then
                    EndJob()
                else
                    Notify(Config.Lang.no_permission)
                end
            end)
        end
    end
end, false)

TriggerEvent("chat:removeSuggestion", "/+17MovConstructionJobStartMarkerAction")
TriggerEvent("chat:removeSuggestion", "/-17MovConstructionJobStartMarkerAction")

RegisterKeyMapping("+17MovConstructionJobStartMarkerAction", Config.Lang.keybind, "keyboard", "E")

local nearbyPlayersData = {}

if Config.useModernUI then
    function OpenDutyMenu()
        if not scriptLoaded then
            InitalizeScript(true)
            print("SCRIPT NOT READY - WAIT UNTIL SCRIPT PROPERLY LOAD")
            return
        end
        
        if not scriptInitialized then
            TriggerServerCallback("17mov_construction:init", function(data)
                SendNUIMessage({
                    action = "Init",
                    name = data.name,
                    myId = data.source
                })
                scriptInitialized = true
            end)
            print("SCRIPT NOT READY - WAIT UNTIL SCRIPT PROPERLY LOAD")
            return
        end
        
        SendNUIMessage({
            action = "OpenWorkMenu"
        })
        SetNuiFocus(true, true)
        menuOpen = true
        
        local showNearbyTab = false
        local hasDeletedPlayers = false
        local hasAddedPlayers = false
        
        CreateThread(function()
            while true do
                if not menuOpen then
                    break
                end
                
                local activePlayers = GetActivePlayers()
                local myCoords = GetEntityCoords(PlayerPedId())
                local nearbyPlayerIds = {}
                local hasNearbyPlayers = false
                
                for k, playerId in pairs(activePlayers) do
                    if PlayerId() ~= playerId then
                        local playerPed = GetPlayerPed(playerId)
                        local playerCoords = GetEntityCoords(playerPed)
                        local distance = #(myCoords - playerCoords)
                        
                        if distance < 10.0 then
                            table.insert(nearbyPlayerIds, GetPlayerServerId(playerId))
                        end
                    end
                end
                
                if #nearbyPlayerIds > 0 then
                    if not hasDeletedPlayers then
                        TriggerServerCallback("17mov_construction:GetPlayersNames", function(playerNames)
                            for k, player in pairs(playerNames) do
                                if nearbyPlayers[player.id] == nil then
                                    hasNearbyPlayers = true
                                    
                                    if nearbyPlayersData[player.id] == nil then
                                        nearbyPlayersData[player.id] = {
                                            id = player.id,
                                            name = player.name
                                        }
                                        
                                        CreateThread(function()
                                            while true do
                                                if not hasAddedPlayers then
                                                    break
                                                end
                                                Citizen.Wait(10)
                                            end
                                            SendNUIMessage({
                                                action = "addNewNearbyPlayer",
                                                id = player.id,
                                                name = player.name
                                            })
                                        end)
                                    end
                                else
                                    playerNames[k] = nil
                                end
                            end
                            
                            hasDeletedPlayers = false
                            
                            for playerId, playerData in pairs(nearbyPlayersData) do
                                hasDeletedPlayers = true
                                local found = false
                                
                                for k, player in pairs(playerNames) do
                                    if player.id == playerId then
                                        found = true
                                        break
                                    end
                                end
                                
                                if not found then
                                    nearbyPlayersData[playerId] = nil
                                    hasDeletedPlayers = true
                                    SendNUIMessage({
                                        action = "DeleteNearbyPlayer",
                                        id = playerData.id
                                    })
                                    
                                    CreateThread(function()
                                        Citizen.Wait(250)
                                        hasDeletedPlayers = false
                                    end)
                                end
                            end
                            
                            if not hasNearbyPlayers and hasAddedPlayers then
                                CreateThread(function()
                                    while true do
                                        if not hasDeletedPlayers then
                                            break
                                        end
                                        Citizen.Wait(10)
                                    end
                                    SendNUIMessage({
                                        action = "hideNearbyPlayersTab"
                                    })
                                    
                                    CreateThread(function()
                                        Citizen.Wait(250)
                                        hasAddedPlayers = false
                                    end)
                                end)
                            elseif hasNearbyPlayers and not hasAddedPlayers then
                                SendNUIMessage({
                                    action = "showNearbyPlayersTab"
                                })
                                
                                CreateThread(function()
                                    Citizen.Wait(250)
                                    hasAddedPlayers = true
                                end)
                            end
                        end, nearbyPlayerIds)
                    end
                elseif hasAddedPlayers and not hasDeletedPlayers then
                    for playerId, playerData in pairs(nearbyPlayersData) do
                        SendNUIMessage({
                            action = "DeleteNearbyPlayer",
                            id = playerData.id
                        })
                        nearbyPlayersData[playerId] = nil
                    end
                    SendNUIMessage({
                        action = "hideNearbyPlayersTab"
                    })
                    hasAddedPlayers = false
                end
                
                Citizen.Wait(2500)
            end
        end)
    end
else
    function OpenDutyMenu()
        if not scriptLoaded then
            InitalizeScript(true)
            print("SCRIPT NOT READY - WAIT UNTIL SCRIPT PROPERLY LOAD")
            return
        end
        
        if not scriptInitialized then
            TriggerServerCallback("17mov_construction:init", function(data)
                SendNUIMessage({
                    action = "Init",
                    name = data.name,
                    myId = data.source
                })
                scriptInitialized = true
            end)
            print("SCRIPT NOT READY - WAIT UNTIL SCRIPT PROPERLY LOAD")
            return
        end
        
        TriggerServerCallback("17mov_construction:IfPlayerIsHost", function(isHost)
            SendNUIMessage({
                action = "HostStatusUpdate",
                status = isHost
            })
            SendNUIMessage({
                action = "OpenWorkMenu"
            })
            SetNuiFocus(true, true)
        end)
    end
end

RegisterNUICallback("changeClothes", function(data)
    if data.type == "work" then
        wearingUniform = true
        ChangeClothes("work")
    else
        wearingUniform = false
        ChangeClothes("citizen")
    end
end)

RegisterNUICallback("requestReacted", function(data)
    SetNuiFocus(false, false)
    local accepted = data.boolean
    TriggerServerEvent("17mov_construction:ClientReactRequest", accepted)
end)

if Config.useModernUI then
    RegisterNUICallback("sendRequest", function(data)
        if OnDuty then
            Notify(Config.Lang.cantInvite)
            return
        end
        TriggerServerEvent("17mov_construction:SendRequestToClient_sv", tonumber(data.id))
    end)
    
    RegisterNUICallback("kickPlayerFromLobby", function(data)
        local playerId = tonumber(data.id)
        Notify(string.format(Config.Lang.kicked, nearbyPlayers[playerId].name))
        TriggerServerEvent("17mov_construction:KickPlayerFromLobby", playerId, true)
    end)
else
    RegisterNUICallback("sendRequest", function(data)
        if OnDuty then
            Notify(Config.Lang.cantInvite)
            return
        end
        Notify(Config.Lang.inviteSent)
        TriggerServerEvent("17mov_construction:SendRequestToClient_sv", data.id)
    end)
    
    RegisterNUICallback("kickPlayerFromLobby", function(data)
        Notify(string.format(Config.Lang.kicked, data.name))
        TriggerServerEvent("17mov_construction:KickPlayerFromLobby", data.id, true)
    end)
end

RegisterNUICallback("focusOff", function(data)
    SetNuiFocus(false, false)
end)

RegisterNUICallback("notify", function(data)
    Notify(data.msg)
end)

RegisterNetEvent("17mov_construction:SendRequestToClient_cl")
AddEventHandler("17mov_construction:SendRequestToClient_cl", function(name, fromId)
    SendNUIMessage({
        action = "ShowInviteBox",
        name = name
    })
    SetNuiFocus(true, true)
end)

function IsSpawnPointClear()
    local spawnPoint = vec3(Config.SpawnPoint.x, Config.SpawnPoint.y, Config.SpawnPoint.z)
    local mixerSpawnPoint = vec3(Config.MixerSpawnPoint.x, Config.MixerSpawnPoint.y, Config.MixerSpawnPoint.z)
    local vehicles = GetGamePool("CVehicle")
    
    if vehicles == nil or type(vehicles) ~= "table" then
        print("FAILED TO FETCH GAMEPOOL - Returning CLEAR")
        return true
    end
    
    for k, vehicle in pairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        if #(vehicleCoords - spawnPoint) < 6.0 or #(vehicleCoords - mixerSpawnPoint) < 6.0 then
            return false
        end
    end
    
    return true
end

RegisterNUICallback("startJob", function(data)
    if not OnDuty then
        if IsSpawnPointClear() then
            TriggerServerEvent("17mov_construction:StartJob_sv")
        else
            Notify(Config.Lang.spawnpointOccupied)
        end
    else
        Notify(Config.Lang.alreadyWorking)
    end
end)

RegisterNUICallback("leaveLobby", function(data)
    if OnDuty then
        Notify(Config.Lang.cantLeaveLobby)
        return
    end
    
    local playerId = tonumber(data.id)
    TriggerServerEvent("17mov_construction:KickPlayerFromLobby", playerId, false, GetPlayerServerId(PlayerId()))
    Notify(Config.Lang.quit)
end)

function SpawnVehicle(model, spawnLocation, teleportPlayer)
    PrepeareVehicle()
    
    local attempts = 250
    RequestModel(model)
    
    while not HasModelLoaded(model) and attempts > 0 do
        Citizen.Wait(100)
        attempts = attempts - 1
        RequestModel(model)
    end
    
    local vehicle = CreateVehicle(model, spawnLocation.x, spawnLocation.y, spawnLocation.z, spawnLocation.w, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, "OFF")
    SetVehicleFuelLevel(vehicle, 100.0)
    
    if teleportPlayer then
        if Config.EnableVehicleTeleporting then
            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        end
    end
    
    SetVehicle(vehicle)
    
    local vehicleExistAttempts = 50
    while not DoesEntityExist(vehicle) and vehicleExistAttempts > 0 do
        Citizen.Wait(100)
        vehicleExistAttempts = vehicleExistAttempts - 1
    end
    
    if vehicleExistAttempts <= 0 then
        vehicle = SpawnVehicle(model, spawnLocation, teleportPlayer)
    end
    
    return vehicle
end

function AddBlip(name, sprite, coords, color)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    
    if sprite ~= nil then
        SetBlipSprite(blip, sprite)
    end
    
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.6)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    
    return blip
end

local function FormatProgress(value)
    return math.floor((tonumber(value) or 0) * 10 + 0.5) / 10
end

RegisterNetEvent("17mov_constructionJob:refreshProgressValue")
AddEventHandler("17mov_constructionJob:refreshProgressValue", function(value)
    local formattedProgress = FormatProgress(value)
    if formattedProgress > currentProgress then
        currentProgress = formattedProgress
        totalProgress = formattedProgress
        SendNUIMessage({
            action = "updateCounter",
            value = formattedProgress
        })
    end
end)

RegisterNUICallback("tutorialClosed", function()
    tutorialActive = false
    DisableControlAction(0, 30, false)
    DisableControlAction(0, 31, false)
    DisableControlAction(0, 32, false)
    DisableControlAction(0, 33, false)
    DisableControlAction(0, 34, false)
    DisableControlAction(0, 35, false)
end)

RegisterNetEvent("17mov_construction:disableThisCustomTask")
AddEventHandler("17mov_construction:disableThisCustomTask", function(taskIndex)
    jobData.customTasks[taskIndex].ready = true
end)

RegisterNetEvent("17mov_Builder:SpawnCustomProps")
AddEventHandler("17mov_Builder:SpawnCustomProps", function(taskData, taskIndex)
    if taskData.spawnPropAfter then
        while not HasModelLoaded(taskData.propSpawnName) do
            RequestModel(taskData.propSpawnName)
            Citizen.Wait(0)
        end
        
        local prop = CreateObject(taskData.propSpawnName, taskData.propSpawnCoords.x, taskData.propSpawnCoords.y, taskData.propSpawnCoords.z, false, true, true)
        table.insert(spawnedObjects, prop)
        SetEntityRotation(prop, taskData.propSpawnRotation.x, taskData.propSpawnRotation.y, taskData.propSpawnRotation.z, 0, false)
        FreezeEntityPosition(prop, true)
        SetEntityInvincible(prop, true)
    end
    
    RemoveBlip(jobData.customTasks[taskIndex].blip)
end)

RegisterNetEvent("17mov_construction:StartJob_cl")
AddEventHandler("17mov_construction:StartJob_cl", function(myId, hostId, jobIndex, memberCount, vehicleNetId, skipTeleport)
    local hostPlayer = myId
    local spawnPoint = Config.SpawnPoint
    local locationData = Config.JobLocations[jobIndex]
    OnDuty = true
    jobData = locationData
    totalProgress = 0
    
    CreateThread(function()
        if not wearingUniform then
            if Config.RequireWorkClothes then
                wearingUniform = true
                ChangeClothes("work")
            end
        end
    end)
    
    if not skipTeleport then
        local tutorialKvp = GetResourceKvpInt("17mov_Tutorials:" .. Config.Lang.startingTutorial)
        if tutorialKvp == 0 then
            tutorialName = Config.Lang.startingTutorial
            SendNUIMessage({
                action = "showTutorial",
                customText = Config.Lang.startingTutorial
            })
            tutorialActive = true
            
            CreateThread(function()
                while true do
                    if not tutorialActive then
                        break
                    end
                    Citizen.Wait(0)
                    DisableControlAction(0, 30, true)
                    DisableControlAction(0, 31, true)
                    DisableControlAction(0, 32, true)
                    DisableControlAction(0, 33, true)
                    DisableControlAction(0, 34, true)
                    DisableControlAction(0, 35, true)
                end
            end)
            
            SetNuiFocus(true, true)
        end
    end
    
    if hostPlayer == hostId then
        if Config.EnableVehicleTeleporting and not skipTeleport then
            DoScreenFadeOut(300)
            Citizen.Wait(1000)
        end
        
        if not skipTeleport then
            local shouldSpawnVehicle = false
            if not (memberCount > 1) then
                if memberCount == 1 and not jobData.enableConcretePouring then
                    shouldSpawnVehicle = true
                end
            else
                shouldSpawnVehicle = true
            end
            
            if shouldSpawnVehicle then
                jobVehicle = SpawnVehicle(Config.JobVehicleModel, Config.SpawnPoint, true)
                JobVehicleNetId = 0
                
                CreateThread(function()
                    while JobVehicleNetId == 0 or JobVehicleNetId == nil do
                        JobVehicleNetId = VehToNet(jobVehicle)
                        Citizen.Wait(100)
                    end
                    TriggerServerEvent("17mov_construction:SendVehicleNetId", JobVehicleNetId)
                end)
            end
            
            if jobData.enableConcretePouring then
                local mixer = SpawnVehicle(Config.MixerModel, Config.MixerSpawnPoint, memberCount <= 1)
                local mixerNetId = 0
                
                CreateThread(function()
                    while mixerNetId == 0 or mixerNetId == nil do
                        mixerNetId = VehToNet(mixer)
                        Citizen.Wait(100)
                    end
                    TriggerServerEvent("17mov_constructionJob:sendMixer", hostPlayer, mixerNetId)
                    
                    if not shouldSpawnVehicle then
                        TriggerServerEvent("17mov_construction:SendVehicleNetId", mixerNetId)
                    end
                end)
            end
            
            CreateThread(function()
                Citizen.Wait(2000)
                DoScreenFadeIn(300)
            end)
        else
            local vehicleFound = false
            while not vehicleFound do
                Citizen.Wait(500)
                local vehicle = NetToVeh(vehicleNetId)
                if vehicle ~= vehicleNetId and vehicle ~= 0 then
                    if DoesEntityExist(vehicle) then
                        JobVehicleNetId = vehicleNetId
                        jobVehicle = vehicle
                        vehicleFound = true
                    end
                end
            end
        end
        
        CreateThread(function()
            while true do
                if not OnDuty then
                    break
                end
                
                if JobVehicleNetId ~= 0 and JobVehicleNetId ~= nil then
                    local networkVehicle = NetToVeh(JobVehicleNetId)
                    if jobVehicle ~= networkVehicle then
                        if networkVehicle ~= JobVehicleNetId then
                            jobVehicle = NetToVeh(JobVehicleNetId)
                        end
                    end
                end
                
                Citizen.Wait(5000)
            end
        end)
    else
        while true do
            Citizen.Wait(0)
            local vehicles = GetGamePool("CVehicle")
            local closestDistance = 200.0
            local closestVehicle = 0
            
            for k, vehicle in pairs(vehicles) do
                local vehicleCoords = GetEntityCoords(vehicle)
                local spawnCoords = vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z)
                local distance = #(vehicleCoords - spawnCoords)
                
                if distance < closestDistance then
                    closestDistance = distance
                    closestVehicle = vehicle
                end
            end
            
            if closestVehicle ~= nil then
                local distance = #(vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z) - GetEntityCoords(closestVehicle))
                if distance < 2.0 then
                    local vehicleModel = GetEntityModel(closestVehicle)
                    if vehicleModel == GetHashKey(Config.JobVehicleModel) then
                        Citizen.Wait(300)
                        while "JobVehicleNetId" do
                            if DoesEntityExist(closestVehicle) then
                                break
                            end
                            Citizen.Wait(100)
                        end
                        JobVehicleNetId = VehToNet(closestVehicle)
                        jobVehicle = closestVehicle
                        break
                    end
                end
            end
        end
        
        if Config.GiveKeysToAllLobby then
            SetVehicle(jobVehicle)
        end
    end
    
    if Config.EnableWaypoint then
        if jobData.welding[1] ~= nil then
            if jobData.welding[1].coords ~= nil then
                SetNewWaypoint(jobData.welding[1].coords.x, jobData.welding[1].coords.y)
            end
        end
    end
    
    CreateThread(function()
        for taskIndex, taskData in pairs(jobData.customTasks) do
            jobData.customTasks[taskIndex].ready = false
            taskData.blip = AddBlip(taskData.blipName, taskData.blipSprite, taskData.coordsToDrawText, taskData.blipColor)
        end
        
        while true do
            if not OnDuty then
                break
            end
            
            local waitTime = 1000
            
            if not IsPedInAnyVehicle(PlayerPedId(), true) then
                for taskIndex, taskData in pairs(jobData.customTasks) do
                    if not taskData.ready then
                        local playerCoords = GetEntityCoords(PlayerPedId())
                        local distance = #(playerCoords - taskData.coordsToDrawText)
                        
                        if distance < 50.0 then
                            waitTime = 0
                            DrawMarker(20, taskData.coordsToDrawText.x, taskData.coordsToDrawText.y, taskData.coordsToDrawText.z + 2.0, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.45, 0.45, 0.45,
                                Config.ArrowMarkerColor.r, Config.ArrowMarkerColor.g, Config.ArrowMarkerColor.b, Config.ArrowMarkerColor.a,
                                true, true, 2, false, false, false, false)
                        end
                        
                        if distance < 2.0 then
                            if not carryingBlock then
                                waitTime = 0
                                DrawText3Ds(taskData.coordsToDrawText.x, taskData.coordsToDrawText.y, taskData.coordsToDrawText.z, "~o~[E] | ~s~" .. taskData.drawingText)
                                
                                if IsControlJustReleased(0, 38) then
                                    TriggerServerEvent("17movement_builder:disableCustomTask", hostPlayer, taskIndex)
                                    SetEntityCoords(PlayerPedId(), taskData.pedInteractionCoords.x, taskData.pedInteractionCoords.y, taskData.pedInteractionCoords.z, false, false, false, false)
                                    SetEntityHeading(PlayerPedId(), taskData.pedInteractionCoords.w)
                                    
                                    local animDict = taskData.animDict
                                    local animName = taskData.animName
                                    
                                    while not HasAnimDictLoaded(animDict) do
                                        RequestAnimDict(animDict)
                                        Citizen.Wait(10)
                                    end
                                    
                                    local freezePlayer = true
                                    
                                    CreateThread(function()
                                        while true do
                                            if not freezePlayer then
                                                break
                                            end
                                            Citizen.Wait(100)
                                            FreezeEntityPosition(PlayerPedId(), true)
                                        end
                                        FreezeEntityPosition(PlayerPedId(), false)
                                    end)
                                    
                                    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
                                    Citizen.Wait(taskData.TimeToBuild)
                                    ClearPedTasks(PlayerPedId())
                                    FreezeEntityPosition(PlayerPedId(), false)
                                    TriggerServerEvent("17mov_builder:CustomTaskDone", hostPlayer, taskData, taskIndex)
                                    freezePlayer = false
                                end
                            end
                        end
                    end
                end
            end
            
            Citizen.Wait(waitTime)
        end
    end)
    
    CreateThread(function()
        for k, weldingData in pairs(jobData.welding) do
            weldingData.blip = AddBlip(Config.JobBlipsStyle.welding.string, Config.JobBlipsStyle.welding.sprite, weldingData.coords, Config.JobBlipsStyle.welding.color)
        end
        
        for k, wallData in pairs(jobData.walls) do
            wallData.frame.blip = AddBlip(Config.JobBlipsStyle.buildWall.string, Config.JobBlipsStyle.buildWall.sprite, wallData.frame.coords, Config.JobBlipsStyle.buildWall.color)
            wallData.blocksPickupBlip = AddBlip(Config.JobBlipsStyle.blockPickup.string, Config.JobBlipsStyle.blockPickup.sprite, wallData.blocksSpawnLocation, Config.JobBlipsStyle.blockPickup.color)
            
            local modelList = {
                "17mov_wallframe_wall",
                "17mov_brick_001",
                "17mov_brick_002",
                "17mov_brick_003",
                "17mov_brick_004"
            }
            
            for i = 1, #modelList do
                RequestModel(modelList[i])
                while not HasModelLoaded(modelList[i]) do
                    Citizen.Wait(10)
                end
            end
            
            wallData.frame.object = CreateObject("17mov_wallframe_wall", wallData.frame.coords.x, wallData.frame.coords.y, wallData.frame.coords.z, false, true, true)
            table.insert(spawnedObjects, wallData.frame.object)
            SetEntityRotation(wallData.frame.object, wallData.frame.rotation.x, wallData.frame.rotation.y, wallData.frame.rotation.z, 0, false)
            FreezeEntityPosition(wallData.frame.object, true)
            
            local currentZ = wallData.blocksSpawnLocation.z
            for i = 1, #wallData.blocksInFrameLocations do
                wallData.blocksInFrameLocations[i].baseBlock = CreateObject("17mov_brick_00" .. math.random(1, 4), wallData.blocksSpawnLocation.x, wallData.blocksSpawnLocation.y, currentZ, false, true, true)
                table.insert(spawnedObjects, wallData.blocksInFrameLocations[i].baseBlock)
                SetEntityRotation(wallData.blocksInFrameLocations[i].baseBlock, wallData.blocksSpawnRotation.x, wallData.blocksSpawnRotation.y, wallData.blocksSpawnRotation.z, 0, false)
                FreezeEntityPosition(wallData.blocksInFrameLocations[i].baseBlock, true)
                currentZ = currentZ + 0.15
            end
            
            CreateThread(function()
                while true do
                    if not OnDuty then
                        break
                    end
                    
                    local waitTime = 1000
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    local distance = #(playerCoords - wallData.blocksSpawnLocation)
                    
                    if distance < 50.0 then
                        DrawMarker(20, wallData.blocksSpawnLocation.x, wallData.blocksSpawnLocation.y, currentZ + 1.5, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.45, 0.45, 0.45,
                            Config.ArrowMarkerColor.r, Config.ArrowMarkerColor.g, Config.ArrowMarkerColor.b, Config.ArrowMarkerColor.a,
                            true, true, 2, false, false, false, false)
                        waitTime = 0
                    end
                    
                    if wallData.spawnClear then
                        break
                    end
                    
                    Citizen.Wait(waitTime)
                end
            end)
        end
    end)
    
    CreateThread(function()
        while true do
            if not OnDuty then
                break
            end
            
            Citizen.Wait(1000)
            local tutorialShown = false
            
            for k, weldingData in pairs(jobData.welding) do
                local distance = #(vec3(weldingData.coords.x, weldingData.coords.y, weldingData.coords.z) - GetEntityCoords(PlayerPedId()))
                
                if distance < 4.0 then
                    if not carryingBlock then
                        tutorialShown = true
                        local tutorialKvp = GetResourceKvpInt("17mov_Tutorials:" .. Config.Lang.tutorialWelding)
                        if tutorialKvp == 0 then
                            tutorialName = Config.Lang.tutorialWelding
                            SendNUIMessage({
                                action = "showTutorial",
                                customText = Config.Lang.tutorialWelding
                            })
                            tutorialActive = true
                            
                            CreateThread(function()
                                while true do
                                    if not tutorialActive then
                                        break
                                    end
                                    Citizen.Wait(0)
                                    DisableControlAction(0, 30, true)
                                    DisableControlAction(0, 31, true)
                                    DisableControlAction(0, 32, true)
                                    DisableControlAction(0, 33, true)
                                    DisableControlAction(0, 34, true)
                                    DisableControlAction(0, 35, true)
                                end
                            end)
                            
                            SetNuiFocus(true, true)
                            break
                        end
                    end
                end
            end
            
            if tutorialShown then
                break
            end
        end
    end)
    
    CreateThread(function()
        while true do
            if not OnDuty then
                break
            end
            
            local waitTime = 500
            local playerCoords = GetEntityCoords(PlayerPedId())
            
            for k, weldingData in pairs(jobData.welding) do
                if not weldingData.ready then
                    local distance = #(vec3(weldingData.coords.x, weldingData.coords.y, weldingData.coords.z) - playerCoords)
                    
                    if distance < 50.0 then
                        waitTime = 0
                        DrawMarker(20, weldingData.coords.x, weldingData.coords.y, weldingData.coords.z + 2.5, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.45, 0.45, 0.45,
                            Config.ArrowMarkerColor.r, Config.ArrowMarkerColor.g, Config.ArrowMarkerColor.b, Config.ArrowMarkerColor.a,
                            true, true, 2, false, false, false, false)
                    end
                    
                    if distance < 2.0 then
                        if not carryingBlock then
                            waitTime = 0
                            DrawText3Ds(weldingData.coords.x, weldingData.coords.y, weldingData.coords.z + 2.0, "~o~[E] | ~s~" .. Config.Lang.startWelding)
                            
                            if IsControlJustReleased(0, 38) then
                                if WeldingMinigame ~= nil then
                                    SetEntityCoords(PlayerPedId(), weldingData.coords.x, weldingData.coords.y, weldingData.coords.z, false, false, false, false)
                                    SetEntityHeading(PlayerPedId(), weldingData.coords.w)
                                    
                                    local freezePlayer = true
                                    
                                    CreateThread(function()
                                        while true do
                                            if not freezePlayer then
                                                break
                                            end
                                            Citizen.Wait(100)
                                            FreezeEntityPosition(PlayerPedId(), true)
                                        end
                                        FreezeEntityPosition(PlayerPedId(), false)
                                    end)
                                    
                                    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_WELDING", 0, true)
                                    
                                    if WeldingMinigame() then
                                        TriggerServerEvent("17mov_constructionJob:weldingReady", hostPlayer, k, weldingData.progressValue)
                                    end
                                    
                                    freezePlayer = false
                                else
                                    TriggerServerEvent("17mov_constructionJob:weldingReady", hostPlayer, k, weldingData.progressValue)
                                    SetEntityCoords(PlayerPedId(), weldingData.coords.x, weldingData.coords.y, weldingData.coords.z, false, false, false, false)
                                    SetEntityHeading(PlayerPedId(), weldingData.coords.w)
                                    
                                    local freezePlayer = true
                                    
                                    CreateThread(function()
                                        while true do
                                            if not freezePlayer then
                                                break
                                            end
                                            Citizen.Wait(100)
                                            FreezeEntityPosition(PlayerPedId(), true)
                                        end
                                        FreezeEntityPosition(PlayerPedId(), false)
                                    end)
                                    
                                    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_WELDING", 0, true)
                                    Citizen.Wait(Config.WeldingTime)
                                    freezePlayer = false
                                end
                                
                                FreezeEntityPosition(PlayerPedId(), false)
                                ClearPedTasks(PlayerPedId())
                                
                                local gameObjects = GetGamePool("CObject")
                                if gameObjects ~= nil and type(gameObjects) == "table" then
                                    for k, obj in pairs(GetGamePool("CObject")) do
                                        if GetEntityModel(obj) == -1010290664 then
                                            SetEntityAsMissionEntity(obj, true, true)
                                            DeleteObject(obj)
                                            DeleteEntity(obj)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            Citizen.Wait(waitTime)
        end
    end)
    
    local wallInteractionBlocked = false
    
    CreateThread(function()
        while true do
            if not OnDuty then
                break
            end
            
            local waitTime = 500
            local playerCoords = GetEntityCoords(PlayerPedId())
            
            if not carryingBlock and not wallInteractionBlocked then
                for k, wallData in pairs(jobData.walls) do
                    if not wallData.spawnClear then
                        local distance = #(vec3(wallData.blocksSpawnLocation.x, wallData.blocksSpawnLocation.y, wallData.blocksSpawnLocation.z) - playerCoords)
                        
                        if distance < 2.5 then
                            waitTime = 0
                            DrawText3Ds(wallData.blocksSpawnLocation.x, wallData.blocksSpawnLocation.y, wallData.blocksSpawnLocation.z + 2.0, "~o~[E] | ~s~" .. Config.Lang.pickupBlock)
                            
                            if IsControlJustReleased(0, 38) then
                                if not carryingBlock then
                                    TriggerServerEvent("17mov_constructionJob:deleteBlockFromSpawn", hostPlayer, k)
                                    Pick("17mov_brick_00" .. math.random(1, 4), Config.wearingAnimation.dict, Config.wearingAnimation.name)
                                end
                            end
                        end
                    end
                end
            end
            
            Citizen.Wait(waitTime)
        end
    end)
    
    CreateThread(function()
        while true do
            if not OnDuty then
                break
            end
            
            local playerPed = PlayerPedId()
            
            if carryingBlock then
                if IsDead(playerPed) then
                    DeleteEntity(progressValue)
                    FreezeEntityPosition(playerPed, false)
                    ClearPedTasks(playerPed)
                    carryingBlock = false
                    progressValue = 0
                end
            end
            
            Wait(500)
        end
    end)
    
    CreateThread(function()
        while true do
            if not OnDuty then
                break
            end
            
            local waitTime = 500
            
            if carryingBlock and not wallInteractionBlocked then
                local playerCoords = GetEntityCoords(PlayerPedId())
                
                for k, wallData in pairs(jobData.walls) do
                    if IsThereFreeSlotInWall(wallData.blocksInFrameLocations) then
                        local distance = #(vec3(wallData.frame.interactionCoords.x, wallData.frame.interactionCoords.y, wallData.frame.interactionCoords.z) - playerCoords)
                        
                        if distance < 7.0 then
                            waitTime = 0
                            DrawText3Ds(wallData.frame.interactionCoords.x, wallData.frame.interactionCoords.y, wallData.frame.interactionCoords.z, "~o~[E] | ~s~" .. Config.Lang.installBlock)
                            
                            if distance < 2.0 then
                                if IsControlJustReleased(0, 38) then
                                    TriggerServerCallback("17mov_Construction:CheckIfWallIsFree", function(isWallFree)
                                        if isWallFree then
                                            wallInteractionBlocked = true
                                            DeleteEntity(progressValue)
                                            
                                            for i = 1, #spawnedObjects do
                                                if spawnedObjects[i] == progressValue then
                                                    spawnedObjects[i] = nil
                                                end
                                            end
                                            
                                            carryingBlock = false
                                            progressValue = 0
                                            
                                            local freeSlotIndex = 0
                                            for i = 1, #wallData.blocksInFrameLocations do
                                                if not wallData.blocksInFrameLocations[i].ready then
                                                    freeSlotIndex = i
                                                    break
                                                end
                                            end
                                            
                                            if freeSlotIndex ~= 0 then
                                                SetEntityCoords(PlayerPedId(), wallData.frame.interactionCoords.x, wallData.frame.interactionCoords.y, wallData.frame.interactionCoords.z - 2.0, false, false, false, false)
                                                SetEntityHeading(PlayerPedId(), wallData.frame.interactionCoords.w)
                                                
                                                local freezePlayer = true
                                                
                                                CreateThread(function()
                                                    while true do
                                                        if not freezePlayer then
                                                            break
                                                        end
                                                        Citizen.Wait(100)
                                                        FreezeEntityPosition(PlayerPedId(), true)
                                                    end
                                                    FreezeEntityPosition(PlayerPedId(), false)
                                                end)
                                                
                                                TaskStartScenarioInPlace(PlayerPedId(), Config.installingBlockToFrameScenario, 0.0, true)
                                                
                                                if WallMinigame ~= nil then
                                                    if WallMinigame() then
                                                        TriggerServerEvent("17mov_constructionJob:installBlockOnWall", hostPlayer, {wallIndex = k, placeIndex = freeSlotIndex}, wallData.blocksInFrameLocations[freeSlotIndex].progressValue)
                                                    end
                                                else
                                                    TriggerServerEvent("17mov_constructionJob:installBlockOnWall", hostPlayer, {wallIndex = k, placeIndex = freeSlotIndex}, wallData.blocksInFrameLocations[freeSlotIndex].progressValue)
                                                    Citizen.Wait(Config.WallBuildingTime)
                                                end
                                                
                                                ClearPedTasks(PlayerPedId())
                                                FreezeEntityPosition(PlayerPedId(), false)
                                                freezePlayer = false
                                                
                                                local gameObjects = GetGamePool("CObject")
                                                if gameObjects ~= nil and type(gameObjects) == "table" then
                                                    for k, obj in pairs(GetGamePool("CObject")) do
                                                        if GetEntityModel(obj) == -127739306 then
                                                            SetEntityAsMissionEntity(obj, true, true)
                                                            DeleteObject(obj)
                                                            DeleteEntity(obj)
                                                        end
                                                    end
                                                end
                                                
                                                wallInteractionBlocked = false
                                            end
                                        else
                                            Notify(Config.Lang.workstationOccupied)
                                        end
                                    end, hostPlayer, k)
                                end
                            end
                        end
                    end
                end
            end
            
            Citizen.Wait(waitTime)
        end
    end)
    
    CreateThread(function()
        while true do
            if not OnDuty then
                break
            end
            
            Citizen.Wait(1000)
            local tutorialShown = false
            
            for k, targetData in pairs(jobData.mixerTargetLocations) do
                local distance = #(targetData.targetLocation - GetEntityCoords(PlayerPedId()))
                
                if distance < 8.0 then
                    tutorialShown = true
                    local tutorialKvp = GetResourceKvpInt("17mov_Tutorials:" .. Config.Lang.tutorialAboutPipes)
                    if tutorialKvp == 0 then
                        tutorialName = Config.Lang.tutorialAboutPipes
                        SendNUIMessage({
                            action = "showTutorial",
                            customText = Config.Lang.tutorialAboutPipes
                        })
                        tutorialActive = true
                        
                        CreateThread(function()
                            while true do
                                if not tutorialActive then
                                    break
                                end
                                Citizen.Wait(0)
                                DisableControlAction(0, 30, true)
                                DisableControlAction(0, 31, true)
                                DisableControlAction(0, 32, true)
                                DisableControlAction(0, 33, true)
                                DisableControlAction(0, 34, true)
                                DisableControlAction(0, 35, true)
                            end
                        end)
                        
                        SetNuiFocus(true, true)
                        break
                    end
                end
            end
            
            if tutorialShown then
                break
            end
        end
    end)
    
    CreateThread(function()
        while true do
            if not OnDuty then
                break
            end
            
            Citizen.Wait(1000)
            local tutorialShown = false
            
            for k, wallData in pairs(jobData.walls) do
                local distance = #(wallData.frame.coords - GetEntityCoords(PlayerPedId()))
                
                if distance < 8.0 then
                    tutorialShown = true
                    local tutorialKvp = GetResourceKvpInt("17mov_Tutorials:" .. Config.Lang.tutorialWallBuilding)
                    if tutorialKvp == 0 then
                        tutorialName = Config.Lang.tutorialWallBuilding
                        SendNUIMessage({
                            action = "showTutorial",
                            customText = Config.Lang.tutorialWallBuilding
                        })
                        tutorialActive = true
                        
                        CreateThread(function()
                            while true do
                                if not tutorialActive then
                                    break
                                end
                                Citizen.Wait(0)
                                DisableControlAction(0, 30, true)
                                DisableControlAction(0, 31, true)
                                DisableControlAction(0, 32, true)
                                DisableControlAction(0, 33, true)
                                DisableControlAction(0, 34, true)
                                DisableControlAction(0, 35, true)
                            end
                        end)
                        
                        SetNuiFocus(true, true)
                        break
                    end
                end
            end
            
            if tutorialShown then
                break
            end
        end
    end)
    
    CreateThread(function()
        for k, targetData in pairs(jobData.mixerTargetLocations) do
            for i, pipeData in pairs(targetData.pipes) do
                if not pipeData.spawnByDefault then
                    pipeData.blip = AddBlip(Config.JobBlipsStyle.installPipe.string, Config.JobBlipsStyle.installPipe.sprite, pipeData.coords, Config.JobBlipsStyle.installPipe.color)
                else
                    CreateThread(function()
                        RequestModel(Config.PipeModel)
                        while not HasModelLoaded(Config.PipeModel) do
                            RequestModel(Config.PipeModel)
                            Citizen.Wait(10)
                        end
                        
                        local pipe = CreateObject(Config.PipeModel, pipeData.coords.x, pipeData.coords.y, pipeData.coords.z, false, true, true)
                        table.insert(spawnedObjects, pipe)
                        SetEntityRotation(pipe, pipeData.rotation.x, pipeData.rotation.y, pipeData.rotation.z, 0, false)
                        FreezeEntityPosition(pipe, true)
                    end)
                end
            end
        end
    end)
    
    CreateThread(function()
        while true do
            if not OnDuty then
                break
            end
            
            local waitTime = 1000
            local playerCoords = GetEntityCoords(PlayerPedId())
            local closestPipe = {table = {}, distance = 100}
            
            for k, targetData in pairs(jobData.mixerTargetLocations) do
                for i, pipeData in pairs(targetData.pipes) do
                    if not pipeData.ready then
                        local distance = #(pipeData.coords - playerCoords)
                        if distance < closestPipe.distance then
                            closestPipe.distance = distance
                            closestPipe.table = pipeData
                            closestPipe.holeIndex = k
                            closestPipe.pipeIndex = i
                        end
                    end
                end
            end
            
            if closestPipe.distance < 2.0 then
                if not IsPedSittingInAnyVehicle(PlayerPedId()) then
                    if not carryingBlock then
                        waitTime = 0
                        local coords = closestPipe.table.coords
                        DrawText3Ds(coords.x, coords.y, coords.z, "~o~[E] |~s~" .. Config.Lang.installPipe)
                        
                        if IsControlJustReleased(0, 38) then
                            Config.JobLocations[jobIndex].mixerTargetLocations[closestPipe.holeIndex].pipes[closestPipe.pipeIndex].ready = true
                            TriggerServerEvent("17mov_Construction:DisableThisPipe", hostPlayer, {jobIndex = jobIndex, holeIndex = closestPipe.holeIndex, pipeIndex = closestPipe.pipeIndex})
                            
                            local animDict = Config.JobLocations[jobIndex].mixerTargetLocations[closestPipe.holeIndex].pipes[closestPipe.pipeIndex].animDict
                            local animName = Config.JobLocations[jobIndex].mixerTargetLocations[closestPipe.holeIndex].pipes[closestPipe.pipeIndex].animName
                            
                            while not HasAnimDictLoaded(animDict) do
                                RequestAnimDict(animDict)
                                Citizen.Wait(10)
                            end
                            
                            SetEntityCoords(PlayerPedId(), closestPipe.table.pedInstallingCoords.x, closestPipe.table.pedInstallingCoords.y, closestPipe.table.pedInstallingCoords.z, false, false, false, false)
                            SetEntityHeading(PlayerPedId(), closestPipe.table.pedInstallingCoords.w)
                            ClearPedTasks(PlayerPedId())
                            TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
                            
                            local freezePlayer = true
                            
                            CreateThread(function()
                                while true do
                                    if not freezePlayer then
                                        break
                                    end
                                    Citizen.Wait(100)
                                    FreezeEntityPosition(PlayerPedId(), true)
                                end
                                FreezeEntityPosition(PlayerPedId(), false)
                            end)
                            
                            if PipeMinigame ~= nil then
                                if PipeMinigame() then
                                    ClearPedTasks(PlayerPedId())
                                    TriggerServerEvent("17mov_Construction:SpawnPipe_SV", hostPlayer, closestPipe.table, {jobIndex = jobIndex, holeIndex = closestPipe.holeIndex, pipeIndex = closestPipe.pipeIndex})
                                end
                            else
                                Citizen.Wait(Config.PipeInstallingTime)
                                ClearPedTasks(PlayerPedId())
                                TriggerServerEvent("17mov_Construction:SpawnPipe_SV", hostPlayer, closestPipe.table, {jobIndex = jobIndex, holeIndex = closestPipe.holeIndex, pipeIndex = closestPipe.pipeIndex})
                            end
                            
                            FreezeEntityPosition(PlayerPedId(), false)
                            freezePlayer = false
                        end
                    end
                end
            end
            
            Citizen.Wait(waitTime)
        end
    end)
    
    if jobData.enableConcretePouring then
        CreateThread(function()
            while true do
                if not OnDuty then
                    break
                end
                
                local waitTime = 1000
                local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                local vehicleModel = GetEntityModel(vehicle)
                
                if vehicleModel == GetHashKey(Config.MixerModel) then
                    for k, targetData in pairs(jobData.mixerTargetLocations) do
                        if not targetData.concreteReady then
                            local distance = #(targetData.targetLocation - GetEntityCoords(PlayerPedId()))
                            
                            if distance < 20.0 and distance > 4.0 then
                                waitTime = 0
                                DrawMarker(20, targetData.targetLocation.x, targetData.targetLocation.y, targetData.targetLocation.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 2.0, 2.0, 2.0,
                                    Config.MarkerSettings.UnActive.r, Config.MarkerSettings.UnActive.g, Config.MarkerSettings.UnActive.b, Config.MarkerSettings.UnActive.a,
                                    true, false, 2, false, false, false, false)
                            elseif distance < 4.0 then
                                waitTime = 0
                                DrawMarker(20, targetData.targetLocation.x, targetData.targetLocation.y, targetData.targetLocation.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 2.0, 2.0, 2.0,
                                    Config.MarkerSettings.Active.r, Config.MarkerSettings.Active.g, Config.MarkerSettings.Active.b, Config.MarkerSettings.Active.a,
                                    true, false, 2, false, false, false, false)
                                ShowHelpNotification(Config.Lang.clickToPour)
                                
                                if IsControlJustReleased(0, 38) then
                                    if PipesReady(targetData) then
                                        local mixerVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                        TriggerServerEvent("17mov_construction:PourConcrete", hostPlayer, targetData.concreteSettings, {jobIndex = jobIndex, holeIndex = k, netId = VehToNet(mixerVehicle)})
                                        SetEntityHeading(mixerVehicle, targetData.mixerFixedTargetLocation.w)
                                        SetEntityCoords(mixerVehicle, targetData.mixerFixedTargetLocation.x, targetData.mixerFixedTargetLocation.y, targetData.mixerFixedTargetLocation.z, false, false, false, false)
                                        FreezeEntityPosition(mixerVehicle, true)
                                        return
                                    else
                                        Notify(Config.Lang.pipesNotReady)
                                    end
                                end
                            end
                        end
                    end
                end
                
                Citizen.Wait(waitTime)
            end
        end)
    end
    
    SendNUIMessage({
        action = "showCounter"
    })
end)

function IsThereFreeSlotInWall(blocksArray)
    local hasFreeSlot = false
    
    for k, blockData in pairs(blocksArray) do
        if not blockData.ready then
            hasFreeSlot = true
            break
        end
    end
    
    return hasFreeSlot
end

RegisterNetEvent("17mov_constructionJob:sendMixer_cl")
AddEventHandler("17mov_constructionJob:sendMixer_cl", function(netId, myId, hostId)
    Citizen.Wait(1000)
    
    if myId == hostId then
        return
    end
    
    if not jobData.enableConcretePouring then
        return
    end
    
    local mixer = NetToVeh(netId)
    mixerVehicle = mixer
    
    while mixerVehicle == netId do
        Citizen.Wait(1000)
        mixerVehicle = NetToVeh(netId)
    end
    
    while jobData == nil do
        Citizen.Wait(100)
    end
    
    SetVehicle(mixerVehicle)
end)

RegisterNetEvent("17mov_construction:disableThisPipe")
AddEventHandler("17mov_construction:disableThisPipe", function(data)
    Config.JobLocations[data.jobIndex].mixerTargetLocations[data.holeIndex].pipes[data.pipeIndex].ready = true
end)

RegisterNetEvent("17mov_constructionJob:disableWeldingBlip")
AddEventHandler("17mov_constructionJob:disableWeldingBlip", function(index)
    jobData.welding[index].ready = true
    RemoveBlip(jobData.welding[index].blip)
end)

RegisterNetEvent("17mov_constructionJob:installBlockOnWall_cl")
AddEventHandler("17mov_constructionJob:installBlockOnWall_cl", function(data)
    jobData.walls[data.wallIndex].blocksInFrameLocations[data.placeIndex].ready = true
    
    local blockModel = "17mov_brick_00" .. math.random(1, 4)
    
    RequestModel(blockModel)
    while not HasModelLoaded(blockModel) do
        RequestModel(blockModel)
        Citizen.Wait(10)
    end
    
    local blockCoords = jobData.walls[data.wallIndex].blocksInFrameLocations[data.placeIndex].coords
    local frameRotation = jobData.walls[data.wallIndex].frame.rotation
    
    local block = CreateObject(blockModel, blockCoords.x, blockCoords.y, blockCoords.z, false, true, true)
    table.insert(spawnedObjects, block)
    SetEntityRotation(block, frameRotation.x, frameRotation.y, frameRotation.z, 0, false)
    FreezeEntityPosition(block, true)
    
    if data.placeIndex == #jobData.walls[data.wallIndex].blocksInFrameLocations then
        RemoveBlip(jobData.walls[data.wallIndex].frame.blip)
    end
end)

function Pick(model, animDict, animName)
    if not carryingBlock then
        while not HasAnimDictLoaded(animDict) do
            RequestAnimDict(animDict)
            Citizen.Wait(5)
        end
        
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(100)
            RequestModel(model)
        end
        
        local playerPed = PlayerPedId()
        local x, y, z = table.unpack(GetEntityCoords(playerPed))
        
        local object = CreateObject(GetHashKey(model), x, y, z + 0.2, true, true, true)
        table.insert(spawnedObjects, object)
        AttachEntityToEntity(object, playerPed, GetPedBoneIndex(playerPed, 60309), 0.025, 0.08, 0.255, -145.0, 290.0, 180.0, true, true, false, true, 1, true)
        TaskPlayAnim(playerPed, animDict, animName, 3.0, -8, -1, 63, 0, false, false, false)
        carryingBlock = true
        progressValue = object
        
        CreateThread(function()
            while true do
                if not carryingBlock then
                    break
                end
                Citizen.Wait(0)
                DisableControlAction(0, 278, true)
                DisableControlAction(0, 279, true)
                DisableControlAction(0, 280, true)
                DisableControlAction(0, 281, true)
                DisableControlAction(0, 59, true)
                DisableControlAction(0, 60, true)
                DisableControlAction(0, 61, true)
                DisableControlAction(0, 62, true)
                DisableControlAction(0, 63, true)
                DisableControlAction(0, 64, true)
                DisableControlAction(0, 136, true)
                DisableControlAction(0, 137, true)
            end
        end)
        
        Citizen.Wait(1000)
        
        while true do
            if not carryingBlock then
                break
            end
            Citizen.Wait(300)
            if not IsEntityPlayingAnim(playerPed, animDict, animName, 3) then
                if carryingBlock then
                    TaskPlayAnim(playerPed, animDict, animName, 3.0, -8, -1, 63, 0, false, false, false)
                end
            end
        end
    end
end

RegisterNetEvent("17mov_constructionJob:deleteBlockFromSpawn_cl")
AddEventHandler("17mov_constructionJob:deleteBlockFromSpawn_cl", function(wallIndex)
    local highestBlockIndex = 0
    
    for i = 1, #jobData.walls[wallIndex].blocksInFrameLocations do
        if jobData.walls[wallIndex].blocksInFrameLocations[i].baseBlock ~= 0 then
            highestBlockIndex = i
        end
    end
    
    DeleteEntity(jobData.walls[wallIndex].blocksInFrameLocations[highestBlockIndex].baseBlock)
    
    for i = 1, #spawnedObjects do
        if spawnedObjects[i] == jobData.walls[wallIndex].blocksInFrameLocations[highestBlockIndex].baseBlock then
            spawnedObjects[i] = nil
        end
    end
    
    jobData.walls[wallIndex].blocksInFrameLocations[highestBlockIndex].baseBlock = 0
    
    if highestBlockIndex == 1 then
        jobData.walls[wallIndex].spawnClear = true
        RemoveBlip(jobData.walls[wallIndex].blocksPickupBlip)
    end
end)

function PipesReady(targetData)
    for k, pipeData in pairs(targetData.pipes) do
        if not pipeData.ready then
            return false
        end
    end
    return true
end

RegisterNetEvent("17mov_constructionJob:RemoveMixerPickupBlip_cl")
AddEventHandler("17mov_constructionJob:RemoveMixerPickupBlip_cl", function()
    if mixerBlip then
        RemoveBlip(mixerBlip)
    end
end)

RegisterNetEvent("17mov_construction:PourConcrete_cl")
AddEventHandler("17mov_construction:PourConcrete_cl", function(concreteSettings, data)
    Config.JobLocations[data.jobIndex].mixerTargetLocations[data.holeIndex].concreteReady = true
    RemoveBlip(Config.JobLocations[data.jobIndex].mixerTargetLocations[data.holeIndex].blip)
    
    RequestModel(concreteSettings.model)
    while not HasModelLoaded(concreteSettings.model) do
        RequestModel(concreteSettings.model)
        Citizen.Wait(10)
    end
    
    local concrete = CreateObject(concreteSettings.model, concreteSettings.startingLoc.x, concreteSettings.startingLoc.y, concreteSettings.startingLoc.z, false, true, true)
    SetEntityRotation(concrete, concreteSettings.rotation.x, concreteSettings.rotation.y, concreteSettings.rotation.z, 0, false)
    table.insert(spawnedObjects, concrete)
    
    while GetEntityCoords(concrete).z <= concreteSettings.maxZ do
        local currentCoords = GetEntityCoords(concrete)
        SetEntityCoords(concrete, currentCoords.x, currentCoords.y, currentCoords.z + 0.0075, false, false, false, false)
        Citizen.Wait(0)
    end
    
    FreezeEntityPosition(NetToVeh(data.netId), false)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    for i = 1, #spawnedObjects do
        DeleteObject(spawnedObjects[i])
    end
    
    SetModelAsNoLongerNeeded("concrete")
    SetModelAsNoLongerNeeded("17mov_pipe")
    SetModelAsNoLongerNeeded("17mov_brick_001")
    SetModelAsNoLongerNeeded("17mov_brick_002")
    SetModelAsNoLongerNeeded("17mov_brick_003")
    SetModelAsNoLongerNeeded("17mov_brick_004")
    SetModelAsNoLongerNeeded("17mov_construction_objects")
    SetModelAsNoLongerNeeded("17mov_wallframe_wall")
end)

RegisterNetEvent("17mov_ConstructionJob:SpawnPipe")
AddEventHandler("17mov_ConstructionJob:SpawnPipe", function(pipeData, data)
    Config.JobLocations[data.jobIndex].mixerTargetLocations[data.holeIndex].pipes[data.pipeIndex].ready = true
    RemoveBlip(Config.JobLocations[data.jobIndex].mixerTargetLocations[data.holeIndex].pipes[data.pipeIndex].blip)
    
    RequestModel(Config.PipeModel)
    while not HasModelLoaded(Config.PipeModel) do
        RequestModel(Config.PipeModel)
        Citizen.Wait(10)
    end
    
    local pipe = CreateObject(Config.PipeModel, pipeData.coords.x, pipeData.coords.y, pipeData.coords.z, false, true, true)
    SetEntityRotation(pipe, pipeData.rotation.x, pipeData.rotation.y, pipeData.rotation.z, 0, false)
    FreezeEntityPosition(pipe, true)
    table.insert(spawnedObjects, pipe)
end)

local endJobBlocked = true

function EndJob()
    if not endJobBlocked then
        return
    end
    
    endJobBlocked = false
    
    if totalProgress < 100 then
        if Config.RequireFullJob then
            Notify(Config.Lang.notFullJob)
            endJobBlocked = true
            return
        end
    end
    
    local driver = GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1)
    
    if driver ~= PlayerPedId() then
        local vehicleModel = GetEntityModel(vehicle)
        if vehicleModel == GetHashKey(Config.JobVehicleModel) or vehicleModel == GetHashKey(Config.MixerModel) then
            Notify(Config.Lang.notADriver)
            endJobBlocked = true
            return
        end
    end
    
    local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local vehicleModel = GetEntityModel(currentVehicle)
    
    if vehicleModel == GetHashKey(Config.JobVehicleModel) or vehicleModel == GetHashKey(Config.MixerModel) then
        DeleteVehicleByCore(currentVehicle)
        TriggerServerEvent("17mov_construction:endJob_sv", true, JobVehicleNetId)
        endJobBlocked = true
        return
    end
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openWarning"
    })
    endJobBlocked = true
end

RegisterNetEvent("17mov_construction:endJob_cl")
AddEventHandler("17mov_construction:endJob_cl", function()
    if RemoveKeys ~= nil then
        RemoveKeys()
    end
    
    local playerCoords = GetEntityCoords (PlayerPedId())
    local dutyToggleCoords = Config.Locations.DutyToggle.Coords[1]
    local distance = #(playerCoords - dutyToggleCoords)
    
    if distance < 40.0 then
        if Config.EnableVehicleTeleporting then
            DoScreenFadeOut(250)
            Citizen.Wait(1000)
            SetEntityCoords(PlayerPedId(), Config.Locations.DutyToggle.Coords[1].x, Config.Locations.DutyToggle.Coords[1].y, Config.Locations.DutyToggle.Coords[1].z, false, false, false, false)
        end
    end
    
    Citizen.Wait(1000)
    DoScreenFadeIn(300)
    
    OnDuty = false
    currentProgress = 0
    
    if Config.RequireWorkClothes then
        if not Config.EnableCloakroom then
            wearingUniform = false
            ChangeClothes("citizen")
        end
    end
    
    SendNUIMessage({
        action = "updateCounter",
        value = 0
    })
    
    SendNUIMessage({
        action = "hideCounter"
    })
    
    SetModelAsNoLongerNeeded("concrete")
    SetModelAsNoLongerNeeded("17mov_pipe")
    SetModelAsNoLongerNeeded("17mov_brick_001")
    SetModelAsNoLongerNeeded("17mov_brick_002")
    SetModelAsNoLongerNeeded("17mov_brick_003")
    SetModelAsNoLongerNeeded("17mov_brick_004")
    SetModelAsNoLongerNeeded("17mov_construction_objects")
    SetModelAsNoLongerNeeded("17mov_wallframe_wall")
    
    if mixerBlip then
        RemoveBlip(mixerBlip)
    end
    
    for k, targetData in pairs(jobData.mixerTargetLocations) do
        RemoveBlip(targetData.blip)
        targetData.concreteReady = false
        
        for i, pipeData in pairs(targetData.pipes) do
            if pipeData.ready then
                if not pipeData.spawnByDefault then
                    pipeData.ready = false
                end
            end
        end
    end
    
    for k, weldingData in pairs(jobData.welding) do
        RemoveBlip(weldingData.blip)
        weldingData.ready = false
    end
    
    for k, targetData in pairs(jobData.mixerTargetLocations) do
        for i, pipeData in pairs(targetData.pipes) do
            RemoveBlip(pipeData.blip)
        end
    end
    
    for k, wallData in pairs(jobData.walls) do
        RemoveBlip(wallData.frame.blip)
        RemoveBlip(wallData.blocksPickupBlip)
        wallData.spawnClear = false
        
        for i, blockData in pairs(wallData.blocksInFrameLocations) do
            blockData.ready = false
        end
    end
    
    for k, taskData in pairs(jobData.customTasks) do
        RemoveBlip(taskData.blip)
    end
    
    for i = 1, #spawnedObjects do
        while DoesEntityExist(spawnedObjects[i]) do
            DeleteObject(spawnedObjects[i])
            Citizen.Wait(10)
        end
        spawnedObjects[i] = nil
    end
end)

RegisterNUICallback("acceptWarning", function(data)
    TriggerServerEvent("17mov_construction:endJob_sv", false, JobVehicleNetId)
    
    if Config.DeleteVehicleWithPenalty then
        DeleteVehicleByCore(GetVehiclePedIsIn(PlayerPedId(), false))
    end
end)