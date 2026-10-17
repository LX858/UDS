_T = Locales[Config.Language]

local drunkLevel = 0
local drunkStage = 0
local isDrunk = false
local drunkThreadStarted = false
local bwRollCache = nil
local lostControlRollCache = nil
local lostControlCoords = nil
local isLostControlActive = false
local isStuckCheck = false
local isMovingToRandomCoords = false
local isAnimationInProgress = false
local isVomiting = false
local isRagdolling = false
InProgressLostAction = false
local testingMode = true
local menuResponseReceived = true
local callbackQueue = {}
local callbackId = 0

RegisterNetEvent("NRG_AlcoEffect:onDrink")
AddEventHandler("NRG_AlcoEffect:onDrink", function(drinkAmount, objectModel, objectOffset, notifyMessage)
    local playerPed = PlayerPedId()
    ShowNotify(notifyMessage, "success")
    AnimatePlayerGo(objectModel, objectOffset)
    drunkLevel = math.min(100, math.max(0, drunkLevel + drinkAmount))
    TriggerServerEvent("NRG_AlcoEffect:SavePlayerDrunkLevel", drunkLevel)
    isDrunk = true
    Wait(5000)
    Drunk()
end)

RegisterNetEvent("NRG_AlcoEffect:PlayerLoader")
AddEventHandler("NRG_AlcoEffect:PlayerLoader", function(savedDrunkLevel)
    drunkLevel = math.min(100, math.max(0, tonumber(savedDrunkLevel) or 0))
    TriggerServerEvent("NRG_AlcoEffect:SavePlayerDrunkLevel", drunkLevel)
    isDrunk = true
    Drunk(true)
end)

function AnimatePlayerGo(objectModel, objectOffset)
    if not isAnimationInProgress then
        local playerPed = PlayerPedId()
        local pedCoords = GetEntityCoords(playerPed)
        local boneIndex = GetPedBoneIndex(playerPed, 18905)
        isAnimationInProgress = true
        
        SpawnObject(objectModel, {
            x = pedCoords.x,
            y = pedCoords.y,
            z = pedCoords.z - 1
        }, function(spawnedObject)
            RequestAnimDict("mp_player_intdrink")
            while not HasAnimDictLoaded("mp_player_intdrink") do
                Citizen.Wait(5)
            end
            
            AttachEntityToEntity(spawnedObject, playerPed, boneIndex, 
                objectOffset.x, objectOffset.y, objectOffset.z, 
                -100.0, 0.0, -25.0, 1, 1, 0, 1, 1, 1)
            
            TaskPlayAnim(playerPed, "mp_player_intdrink", "loop_bottle", 
                1.0, -1.0, -1, 48, 0.0, false, false, false)
            
            Wait(5000)
            isAnimationInProgress = false
            ClearPedSecondaryTask(playerPed)
            DeleteObject(spawnedObject)
        end)
    end
end

function SpawnObject(model, coords, callback)
    local modelHash = type(model) == "number" and model or GetHashKey(model)
    
    Citizen.CreateThread(function()
        RequestModel2(modelHash)
        local obj = CreateObject(modelHash, coords.x, coords.y, coords.z, true, false, true)
        if callback ~= nil then
            callback(obj)
        end
    end)
end

function RequestModel2(model, callback)
    local modelHash = type(model) == "number" and model or GetHashKey(model)
    
    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Citizen.Wait(1)
        end
    end
    
    if nil ~= callback then
        callback()
    end
end

function Drunk(forceRefresh)
    local playerPed = PlayerPedId()
    
    if drunkLevel >= Config.DrunkStageOneFrom and drunkLevel < Config.DrunkStageTwoFrom then
        if drunkStage ~= 1 or forceRefresh then
            ClearPedTasks(playerPed)
            ShakeGameplayCam("DRUNK_SHAKE", 0.4)
            drunkStage = 1
        end
    end
    
    if drunkLevel >= Config.DrunkStageTwoFrom and drunkLevel < Config.DrunkStageThreeFrom then
        if drunkStage ~= 2 or forceRefresh then
            RequestAnimSet("move_m@drunk@slightlydrunk")
            drunkStage = 2
            while not HasAnimSetLoaded("move_m@drunk@slightlydrunk") do
                Citizen.Wait(0)
            end
            ShakeGameplayCam("DRUNK_SHAKE", 2.0)
            SetPedMovementClipset(playerPed, "move_m@drunk@slightlydrunk", true)
            SetTimecycleModifier("spectator5")
            SetPedIsDrunk(playerPed, true)
        end
    elseif drunkLevel >= Config.DrunkStageThreeFrom and drunkLevel < Config.DrunkStageFourFrom then
        if drunkStage ~= 3 or forceRefresh then
            drunkStage = 3
            ShakeGameplayCam("DRUNK_SHAKE", 3.0)
            SetTimecycleModifier("spectator5")
            SetPedMotionBlur(playerPed, true)
            RequestAnimSet("move_m@drunk@moderatedrunk")
            while not HasAnimSetLoaded("move_m@drunk@moderatedrunk") do
                Citizen.Wait(0)
            end
            SetPedMovementClipset(playerPed, "move_m@drunk@moderatedrunk", true)
        end
    elseif drunkLevel >= Config.DrunkStageFourFrom then
        if drunkStage ~= 4 or forceRefresh then
            drunkStage = 4
            ShakeGameplayCam("DRUNK_SHAKE", 10.0)
            SetTimecycleModifier("spectator5")
            RequestAnimSet("move_m@drunk@verydrunk")
            while not HasAnimSetLoaded("move_m@drunk@verydrunk") do
                Citizen.Wait(0)
            end
            SetPedMovementClipset(playerPed, "move_m@drunk@verydrunk", true)
        end
    end
    
    if Config.LostControlFromOverDrink then
        if drunkLevel >= Config.LostControlCount and not isLostControlActive then
            local rollResult = 0
            if not lostControlRollCache then
                rollResult = math.random(1, 100)
            else
                if lostControlRollCache.promil < drunkLevel then
                    rollResult = math.random(1, 100)
                    lostControlRollCache = {los = rollResult, promil = drunkLevel}
                else
                    rollResult = lostControlRollCache.los
                end
            end
            
            if rollResult <= Config.ProcentForLostControl then
                LostControlAction(6)
                isMovingToRandomCoords = true
                isRagdolling = true
            else
                lostControlRollCache = {los = rollResult, promil = drunkLevel}
            end
        end
    end
    
    if drunkLevel >= Config.BwOverDrinkCount and Config.BwFromOverDrink then
        local rollResult = 0
        if not bwRollCache then
            rollResult = math.random(1, 100)
        else
            if bwRollCache.promil < drunkLevel then
                rollResult = math.random(1, 100)
                bwRollCache = {los = rollResult, promil = drunkLevel}
            else
                rollResult = bwRollCache.los
            end
        end
        
        if rollResult <= Config.ProcentForBw then
            local player = GetPlayerPed(-1)
            SetEntityHealth(player, 0)
        elseif Config.BwOverDrinkPassProcent <= drunkLevel then
            local player = GetPlayerPed(-1)
            SetEntityHealth(player, 0)
        else
            bwRollCache = {los = rollResult, promil = drunkLevel}
        end
    end
    
    if drunkLevel >= Config.DrunkStageOneFrom then
        StartCheckerOfDrunkStage()
    end
end

function LostControlAction(duration)
    if InProgressLostAction then
        return
    end
    
    local endTime = GetGameTimer() + (duration * 1000)
    InProgressLostAction = true
    
    Citizen.CreateThread(function()
        while InProgressLostAction do
            if GetGameTimer() >= endTime then
                InProgressLostAction = false
                return
            end
            
            Wait(1)
            DisableAllControlActions(0)
            EnableControlAction(0, 245, true)
        end
    end)
end

function Reality(shouldRefreshDrunk)
    CreateThread(function()
        local playerPed = PlayerPedId()
        SetCamEffect(0)
        StopGameplayCamShaking(false)
        ClearTimecycleModifier()
        ResetScenarioTypesEnabled()
        ResetPedMovementClipset(playerPed, 0)
        SetPedIsDrunk(playerPed, false)
        SetPedMotionBlur(playerPed, false)
        
        if shouldRefreshDrunk then
            Wait(100)
            Drunk()
        end
    end)
end

function StartCheckerOfDrunkStage()
    if not drunkThreadStarted then
        drunkThreadStarted = true
        
        CreateThread(function()
            while isDrunk do
                Wait(Config.DropDrunkLevelTime * 1000)
                
                if drunkLevel > 0 then
                    drunkLevel = drunkLevel - Config.DropDrunkLevelCount
                    TriggerServerEvent("NRG_AlcoEffect:SavePlayerDrunkLevel", drunkLevel)
                    
                    local shouldResetEffects = false
                    if drunkStage == 4 and drunkLevel < Config.DrunkStageFourFrom then
                        shouldResetEffects = true
                    elseif drunkStage == 3 and drunkLevel < Config.DrunkStageThreeFrom then
                        shouldResetEffects = true
                    elseif drunkStage == 2 and drunkLevel < Config.DrunkStageTwoFrom then
                        shouldResetEffects = true
                    end
                    
                    if shouldResetEffects then
                        if drunkStage == 4 and Config.Vomit then
                            local vomitRoll = math.random(1, 100)
                            if vomitRoll <= Config.VomitLos then
                                Vomit()
                                Wait(5000)
                            end
                        end
                        Reality(true)
                    end
                    
                    if drunkLevel <= 0 then
                        drunkLevel = 0
                        drunkStage = 0
                        ClearAllAlcoEffect()
                        drunkThreadStarted = false
                        isDrunk = false
                        bwRollCache = nil
                    end
                elseif isDrunk then
                    ClearAllAlcoEffect()
                    drunkThreadStarted = false
                    isDrunk = false
                    bwRollCache = nil
                end
            end
        end)
        
        if Config.RagdollWhenDrunk then
            CreateThread(function()
                local minNextRagdoll = Config.NextRagdollRandomTimer.min * 1000
                local maxNextRagdoll = Config.NextRagdollRandomTimer.max * 1000
                local minRagdollTime = Config.RagdollRandomTimer.min * 1000
                local maxRagdollTime = Config.RagdollRandomTimer.max * 1000
                
                while isDrunk do
                    local nextRagdollWait = math.random(minNextRagdoll, maxNextRagdoll)
                    local ragdollDuration = math.random(minRagdollTime, maxRagdollTime)
                    
                    Wait(nextRagdollWait)
                    
                    if drunkLevel >= Config.RagdollOverDrunk and not isVomiting then
                        SetPedToRagdoll(GetPlayerPed(-1), ragdollDuration, ragdollDuration, 0, 0, 0, 0)
                    end
                end
            end)
        end
        
        if Config.CarDriveDifficultWhenDrunk then
            CreateThread(function()
                local isInVehicleAndDriving = false
                local vehicleActions = {{name = "A"}, {name = "D"}}
                local playerPed = PlayerPedId()
                
                while isDrunk do
                    Wait(500)
                    
                    if IsPedInAnyVehicle(playerPed, false) then
                        local currentVehicle = GetVehiclePedIsIn(playerPed, false)
                        if GetPedInVehicleSeat(currentVehicle, -1) == playerPed then
                            if drunkLevel >= Config.CarDriveDefficultOver and not isLostControlActive then
                                if not isInVehicleAndDriving then
                                    Wait(5000)
                                end
                                
                                local vehicle = GetVehiclePedIsIn(playerPed, false)
                                isInVehicleAndDriving = true
                                
                                local randomAction = vehicleActions[math.random(#vehicleActions)]
                                local holdDuration = math.random(Config.CarDriveDefficultHold.min, Config.CarDriveDefficultHold.max)
                                
                                if randomAction.name == "A" then
                                    TaskVehicleTempAction(playerPed, vehicle, 7, holdDuration)
                                elseif randomAction.name == "D" then
                                    TaskVehicleTempAction(playerPed, vehicle, 8, holdDuration)
                                end
                                
                                Wait(math.random(3000, 6000))
                            end
                        end
                    else
                        isInVehicleAndDriving = false
                        Wait(1000)
                    end
                end
            end)
        end
        
        if Config.LostControlFromOverDrink then
            CreateThread(function()
                while isDrunk do
                    Wait(2000)
                    
                    if Config.LostControlCount <= drunkLevel then
                        if isMovingToRandomCoords and not isLostControlActive then
                            isMovingToRandomCoords = false
                            lostControlRollCache = nil
                            MoveToRandomCoordsNearPlayer(Config.LostControlRadialToMove)
                        end
                    elseif Config.LostControlCount >= drunkLevel then
                        if isLostControlActive then
                            local playerPed = PlayerPedId()
                            isLostControlActive = false
                            lostControlCoords = nil
                            ClearPedTasks(playerPed)
                            Reality(true)
                        end
                    elseif Config.LostControlCount <= drunkLevel then
                        if isRagdolling and not isMovingToRandomCoords and not isLostControlActive then
                            if Config.LostControlAction then
                                Wait(math.random(4000, 12000))
                                local actionDuration = math.random(10, 35)
                                LostControlAction(actionDuration / 10)
                            end
                        end
                    end
                end
            end)
        end
    end
end

function getRandomCoordsNearPlayer(radius)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    local offsetX = math.random(-radius, radius)
    local offsetY = math.random(-radius, radius)
    local targetCoords = vector3(playerCoords.x + offsetX, playerCoords.y + offsetY, playerCoords.z)
    
    local foundGround, groundZ = GetGroundZFor_3dCoord(targetCoords.x, targetCoords.y, targetCoords.z + 1000.0, 0)
    
    if foundGround then
        return vector3(targetCoords.x, targetCoords.y, groundZ)
    else
        return getRandomCoordsNearPlayer(radius)
    end
end

function MoveToRandomCoordsNearPlayer(radius)
    if isLostControlActive then
        return
    end
    
    isLostControlActive = true
    Wait(2000)
    
    local targetCoords = getRandomCoordsNearPlayer(radius)
    local playerPed = PlayerPedId()
    
    TaskGoToCoordAnyMeans(playerPed, targetCoords.x, targetCoords.y, targetCoords.z, 3.0, 0, 0, 786468, 3212836864)
    
    Citizen.CreateThread(function()
        local ped = PlayerPedId()
        local destination = vector3(targetCoords.x, targetCoords.y, targetCoords.z)
        local startCoords = GetEntityCoords(ped)
        local timeElapsed = 0
        local timeout = Config.LostControlTimeOut * 1000
        
        while true do
            Citizen.Wait(5000)
            timeElapsed = timeElapsed + 5000
            
            if timeout <= timeElapsed then
                isLostControlActive = false
                lostControlCoords = nil
                TaskGoToCoordAnyMeans(ped, startCoords.x, startCoords.y, startCoords.z, 3.0, 0, 0, 786469, 3212836864)
                break
            end
            
            if not isLostControlActive then
                break
            end
            
            local currentCoords = GetEntityCoords(ped)
            local distance = Vdist(currentCoords.x, currentCoords.y, currentCoords.z, destination.x, destination.y, destination.z)
            
            if distance < 8.0 then
                isLostControlActive = false
                lostControlCoords = nil
                TaskGoToCoordAnyMeans(ped, currentCoords.x, currentCoords.y, currentCoords.z, 3.0, 0, 0, 786469, 3212836864)
                break
            else
                if lostControlCoords then
                    local distanceDiff = lostControlCoords - distance
                    if distanceDiff < 2 and distanceDiff > -2 then
                        if isStuckCheck then
                            isLostControlActive = false
                            lostControlCoords = nil
                            TaskGoToCoordAnyMeans(ped, currentCoords.x, currentCoords.y, currentCoords.z, 3.0, 0, 0, 786469, 3212836864)
                            break
                        else
                            isStuckCheck = true
                        end
                    else
                        lostControlCoords = distance
                        isStuckCheck = false
                    end
                else
                    lostControlCoords = distance
                end
            end
        end
    end)
end

function GetNearbyPlayers(radius, includeSelf)
    local nearbyPlayers = {}
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if radius >= distance then
                local serverId = GetPlayerServerId(playerId)
                table.insert(nearbyPlayers, {id = serverId})
            end
        elseif includeSelf then
            local serverId = GetPlayerServerId(playerId)
            table.insert(nearbyPlayers, {id = serverId, name = _T.You .. " "})
        end
    end
    
    return nearbyPlayers
end

RegisterNetEvent("NRG_AlcoEffect:UseAlcomat")
AddEventHandler("NRG_AlcoEffect:UseAlcomat", function()
    UseAlcomat()
end)

function UseAlcomat()
    local nearbyPlayers = GetNearbyPlayers(3.0, true)
    local menuOptions = {}
    
    if Config.OxLib then
        for _, playerData in ipairs(nearbyPlayers) do
            if playerData.name then
                table.insert(menuOptions, {
                    title = playerData.name .. " " .. playerData.id,
                    value = playerData.id,
                    onSelect = function()
                        TriggerServerEvent("NRG_AlcoEffect:AskForAlcoCheck", playerData.id)
                    end
                })
            else
                table.insert(menuOptions, {
                    title = tostring(playerData.id),
                    value = playerData.id,
                    onSelect = function()
                        TriggerServerEvent("NRG_AlcoEffect:AskForAlcoCheck", playerData.id)
                    end
                })
            end
        end
        
        exports.ox_lib:registerContext({
            id = "player_select_menu",
            title = _T.ClosePlayers,
            options = menuOptions
        })
        exports.ox_lib:showContext("player_select_menu")
    else
        for _, playerData in ipairs(nearbyPlayers) do
            if playerData.name then
                table.insert(menuOptions, {
                    label = playerData.name .. playerData.id,
                    value = playerData.id
                })
            else
                table.insert(menuOptions, {
                    label = tostring(playerData.id),
                    value = playerData.id
                })
            end
        end
        
        OpenMenuAlcomat(menuOptions)
    end
end

RegisterNetEvent("NRG_AlcoEffect:AskClientForAlcomat")
AddEventHandler("NRG_AlcoEffect:AskClientForAlcomat", function(targetId)
    SendReactMessage("OpenMenuAsk", {t = _T, tid = targetId})
    SetDisplay(true)
    menuResponseReceived = false
    
    Citizen.CreateThread(function()
        local timeoutTime = GetGameTimer() + 10000
        
        while not menuResponseReceived do
            Wait(500)
            
            if timeoutTime < GetGameTimer() then
                SetDisplay(false)
                SendReactMessage("setUI", {status = false})
                SendJustOneTime(targetId, false)
                break
            end
        end
    end)
end)

function SetDisplay(state)
    Wait(100)
    SetNuiFocus(state, state)
end

RegisterNUICallback("doAction", function(data, cb)
    if data.action == "AskClient" then
        SetDisplay(false)
        SendJustOneTime(data.tid, data.ask)
    end
    
    if data.action == "offFocus" then
        SetDisplay(false)
    end
    
    cb(true)
end)

function SendJustOneTime(targetId, response)
    if not menuResponseReceived then
        menuResponseReceived = true
        TriggerServerEvent("NRG_AlcoEffect:AnswerForAlcoCheck", targetId, response)
    end
end

RegisterNetEvent("NRG_AlcoEffect:AnswerClientForAlcomat")
AddEventHandler("NRG_AlcoEffect:AnswerClientForAlcomat", function(accepted, targetId, isSelfTest)
    if accepted and not isSelfTest then
        local nearbyPlayers = GetNearbyPlayers(3.0, true)
        local isPlayerNearby = false
        
        for _, playerData in ipairs(nearbyPlayers) do
            if playerData.id == targetId then
                isPlayerNearby = true
            end
        end
        
        if isPlayerNearby then
            PlayAlcoTestAnime(targetId)
            Wait(2000)
            SetNuiFocus(true, false)
            local drunkLevelResult = ReturnDrunkLevel(targetId)
            SendReactMessage("setVisible", {
                duration = Config.BreathalyzerCheckTimer * 1000,
                result = drunkLevelResult
            })
        else
            ShowNotify(_T.PlayerIsTooFar, "error")
        end
    elseif isSelfTest then
        PlayAlcoTestAnimeMe()
        Wait(1200)
        SetNuiFocus(true, false)
        local drunkLevelResult = ReturnDrunkLevel(targetId)
        SendReactMessage("setVisible", {
            duration = Config.BreathalyzerCheckTimer * 1000,
            result = drunkLevelResult
        })
    else
        ShowNotify(_T.NotAcceptFromPlayer, "error")
    end
end)

RegisterNetEvent("nrg_alcoeffect:client:SendAlcoCheck")
AddEventHandler("nrg_alcoeffect:client:SendAlcoCheck", function(data)
    TriggerServerEvent("NRG_AlcoEffect:AskForAlcoCheck", data.id)
end)

function ReturnDrunkLevel(playerId)
    local result = nil
    
    NRGCallback("NRG_AlcoEffect:PlayerDrunkLevel", function(level)
        result = level
    end, playerId)
    
    local timeoutTime = GetGameTimer() + 3000
    while not result do
        Wait(1)
        if timeoutTime < GetGameTimer() then
            if not result then
                result = "0.00"
            end
            break
        end
    end
    
    return result
end

local alcomatAnimDict = "missfam4"
local alcomatAnimName = "base"
local alcomatInUse = false

function PlayAlcoTestAnime(targetPlayerId)
    CreateThread(function()
        local playerPed = PlayerPedId()
        
        RequestAnimDict(alcomatAnimDict)
        while not HasAnimDictLoaded(alcomatAnimDict) do
            Wait(0)
        end
        
        local offsetDistance = 0.8
        local frontCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, offsetDistance, 0.0)
        local foundGround, groundZ = GetGroundZFor_3dCoord(frontCoords.x, frontCoords.y, frontCoords.z + 2.0, 0)
        local heading = (GetEntityHeading(playerPed) + 180.0) % 360
        
        local syncData = {
            x = frontCoords.x,
            y = frontCoords.y,
            z = groundZ,
            h = heading
        }
        
        TriggerServerEvent("NRG_AlcoEffect:synchAnime", targetPlayerId, syncData, true)
        
        local pedCoords = GetEntityCoords(playerPed)
        local alcomatObject = CreateObject(GetHashKey("alcomat"), pedCoords.x, pedCoords.y, pedCoords.z, true, true, true)
        
        AttachEntityToEntity(alcomatObject, playerPed, GetPedBoneIndex(playerPed, 18905), 
            0.09, 0.01, 0.02, -79.0, 34.0, -36.0, 1, 1, 0, 1, 1, 1)
        
        Wait(1000)
        OpenWatch()
        Wait((Config.BreathalyzerCheckTimer * 1000) + 2000)
        CloseWatch()
        DeleteEntity(alcomatObject)
        
        TriggerServerEvent("NRG_AlcoEffect:synchAnime", targetPlayerId, syncData, false)
    end)
end

function PlayAlcoTestAnimeMe()
    CreateThread(function()
        local playerPed = PlayerPedId()
        
        RequestAnimDict("amb@world_human_drinking@coffee@male@base")
        while not HasAnimDictLoaded("amb@world_human_drinking@coffee@male@base") do
            Wait(0)
        end
        
        local pedCoords = GetEntityCoords(playerPed)
        local alcomatObject = CreateObject(GetHashKey("alcomat"), pedCoords.x, pedCoords.y, pedCoords.z, true, true, true)
        
        TaskPlayAnim(playerPed, "amb@world_human_drinking@coffee@male@base", "base", 
            1.0, -1.0, -1, 1, 0.0, false, false, false)
        
        AttachEntityToEntity(alcomatObject, playerPed, GetPedBoneIndex(playerPed, 57005), 
            0.1, 0.0, -0.02, -104.0, -51.0, -6.0, 1, 1, 0, 1, 1, 1)
        
        Wait((Config.BreathalyzerCheckTimer * 1000) + 2000)
        CloseWatch()
        Wait(1000)
        DeleteEntity(alcomatObject)
    end)
end

RegisterNetEvent("NRG_AlcoEffect:synchAnimeC")
AddEventHandler("NRG_AlcoEffect:synchAnimeC", function(coords, shouldPosition)
    local playerPed = PlayerPedId()
    
    if shouldPosition then
        SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
        Wait(200)
        SetEntityHeading(playerPed, coords.h)
        Wait(200)
        FreezeEntityPosition(playerPed, true)
    else
        FreezeEntityPosition(playerPed, false)
    end
end)

function OpenWatch()
    TaskPlayAnim(PlayerPedId(), alcomatAnimDict, alcomatAnimName, 8.0, -8.0, -1, 1, 0.0, false, false, false)
end

function CloseWatch()
    ClearPedTasks(PlayerPedId())
end

function ToDoStomachLavage(targetPlayerId)
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then
        TriggerServerEvent("NRG_AlcoEffect:ToDoStomachLavage", targetPlayerId)
        TaskStartScenarioInPlace(playerPed, "CODE_HUMAN_MEDIC_TEND_TO_DEAD", 0, 1)
        Citizen.Wait(7000)
        ClearPedTasks(playerPed)
    end
end

RegisterNetEvent("NRG_AlcoEffect:ClientStomachLavage")
AddEventHandler("NRG_AlcoEffect:ClientStomachLavage", function(targetId)
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, true)
    Citizen.Wait(7000)
    FreezeEntityPosition(playerPed, false)
    ClearAllAlcoEffect()
end)

function ClearAllAlcoEffect()
    local playerPed = PlayerPedId()
    Reality()
    drunkLevel = 0
    drunkStage = 0
    isDrunk = false
    drunkThreadStarted = false
    bwRollCache = nil
    lostControlRollCache = nil
    lostControlCoords = nil
    isLostControlActive = false
    isStuckCheck = false
    isMovingToRandomCoords = false
    isRagdolling = false
    InProgressLostAction = false
    ClearPedTasks(playerPed)
    TriggerServerEvent("NRG_AlcoEffect:SavePlayerDrunkLevel", drunkLevel)
end

AddEventHandler("playerSpawned", function(spawn)
    if Config.ClearAllEffectAfterDead then
        ClearAllAlcoEffect()
    else
        Wait(3000)
        Drunk(true)
    end
end)

function NRGscriptsGetDrunkLevel()
    return drunkLevel
end

function NRGscriptsSetDrunkLevel(level)
    drunkLevel = math.min(100, math.max(0, tonumber(level) or 0))
    TriggerServerEvent("NRG_AlcoEffect:SavePlayerDrunkLevel", drunkLevel)
    if drunkLevel > 0 then
        isDrunk = true
    end
    Wait(1000)
    Drunk()
end

RegisterNetEvent("NRG_AlcoEffect:NRGscriptsAddDrunkLevel")
AddEventHandler("NRG_AlcoEffect:NRGscriptsAddDrunkLevel", function(amount)
    NRGscriptsAddDrunkLevel(amount)
end)

function NRGscriptsAddDrunkLevel(amount)
    local level = math.min(100, math.max(0, (tonumber(drunkLevel) or 0) + (tonumber(amount) or 0)))
    drunkLevel = level
    if level > 0 then
        isDrunk = true
    end
    TriggerServerEvent("NRG_AlcoEffect:SavePlayerDrunkLevel", drunkLevel)
    Drunk()
end

function RefreshAlcoEffect()
    Drunk(true)
end

function NRGCallback(eventName, callback, ...)
    callbackId = callbackId + 1
    local currentId = callbackId
    callbackQueue[currentId] = callback
    TriggerServerEvent("NRGalcoeffect:triggerCallback", eventName, currentId, ...)
end

RegisterNetEvent("NRGalcoeffect:callbackResponse")
AddEventHandler("NRGalcoeffect:callbackResponse", function(requestId, ...)
    if callbackQueue[requestId] then
        callbackQueue[requestId](...)
        callbackQueue[requestId] = nil
    end
end)

function SendReactMessage(action, data)
    SendNUIMessage({action = action, data = data})
end

function Vomit()
    CreateThread(function()
        local playerPed = PlayerPedId()
        isVomiting = true
        
        if IsPedInAnyVehicle(playerPed, false) then
            return
        end
        
        local animDict = "missheistpaletoscore1leadinout"
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(100)
        end
        
        TaskPlayAnim(playerPed, animDict, "trv_puking_leadout", 8.0, -8.0, 10500, 49, 0, false, false, false)
        Wait(10500)
        isVomiting = false
    end)
end

exports("UseAlcomat", UseAlcomat)
exports("GetDrunkLevel", NRGscriptsGetDrunkLevel)
exports("SetDrunkLevel", NRGscriptsSetDrunkLevel)
exports("AddDrunkLevel", NRGscriptsAddDrunkLevel)
exports("ClearAllAlcoEffect", ClearAllAlcoEffect)
exports("ClearClientStomachById", ToDoStomachLavage)
exports("RefreshAlcoEffect", RefreshAlcoEffect)
exports("ToggleUI", function(status)
    SendReactMessage("toggleUI", {status = status})
end)

ClearAllAlcoEffect()

if testingMode then
    RegisterCommand("testA", function()
        ClearAllAlcoEffect()
    end, false)
    
    RegisterCommand("testF", function(source, args)
        exports.nrg_alcoeffect:ToggleUI(false)
    end, false)
    
    RegisterCommand("testB", function(source, args)
        local id = tonumber(args[1])
        if id then
            ToDoStomachLavage(id)
        end
    end, false)
    
    RegisterCommand("testC", function()
        UseAlcomat()
    end, false)
    
    RegisterCommand("testD", function()
        SendReactMessage("setUI", {status = false})
    end, false)
    
    RegisterCommand("testE", function(source, args)
        local level = tonumber(args[1])
        if level then
            NRGscriptsSetDrunkLevel(level)
        end
    end, false)
end
