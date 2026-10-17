grapplers = {}

grapplerActions = {
    install = "install",
    deploy = "deploy",
    remove = "remove",
    reset = "reset"
}

grapplerModes = {
    installed = "installed",
    deployed = "deployed",
    used = "used",
    inactive = "inactive"
}

tyreBurstIndex = {
    wheel_lf = 0,
    wheel_rf = 1,
    wheel_lm = 2,
    wheel_rm = 3,
    wheel_lr = 4,
    wheel_rr = 5
}

local evenAtKey = GetConvar("EKey2", "")

if grapplerCommand.enabled then
    local commandPath = "/" .. grapplerCommand.commandName
    local params = {
        {
            name = translations.grapplerCommandParameterOne,
            help = translations.grapplerCommandParameterOneHelp
        }
    }
    TriggerEvent("chat:addSuggestion", commandPath, translations.grapplerCommandHelp, params)
end

Citizen.CreateThread(function()
    Wait(2500)
    TriggerServerEvent("Server:requestGrapplerTable")
    
    while true do
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle ~= nil and vehicle ~= 0 then
            local driver = GetPedInVehicleSeat(vehicle, -1)
            local vehicleNetId = VehToNet(vehicle)
            local grapplerData = grapplers[vehicleNetId]
            
            if grapplerData ~= nil and driver == playerPed then
                if grapplerData.mode == grapplerModes.installed then
                    if IsControlPressed(deployGrapplerKey[1], deployGrapplerKey[2]) then
                        deployGrappler()
                        Wait(3000)
                    end
                end
                
                if grapplerData.mode == grapplerModes.deployed then
                    if grapplerData.props and DoesEntityExist(grapplerData.props[2]) then
                        local frameCoords = GetEntityCoords(grapplerData.props[2])
                        local targetVehicle = raycastDeploy(vehicle, frameCoords)
                        
                        if targetVehicle ~= nil and targetVehicle ~= 0 then
                            for wheelBoneName, wheelData in pairs(wheelBones) do
                                local wheelBoneIndex = GetEntityBoneIndexByName(targetVehicle, wheelBoneName)
                                
                                if wheelBoneIndex ~= -1 then
                                    local wheelCoords = GetWorldPositionOfEntityBone(targetVehicle, wheelBoneIndex)
                                    local distance = #(frameCoords - wheelCoords)
                                    local targetVehicleNetId = VehToNet(targetVehicle)
                                    
                                    if distance < main.radiusToAttachToVehicle then
                                        local vehicleModel = GetEntityModel(vehicle)
                                        local vehicleName = (vehicles[vehicleModel] and vehicles[vehicleModel].name) or tostring(vehicleModel)
                                        
                                        TriggerServerEvent("Server:newGrapplerLog", evenAtKey, translations.usedGrappler, translations.vehicle .. vehicleName)
                                        TriggerServerEvent("Server:deployGrapplerOnVehicle", evenAtKey, vehicleNetId, targetVehicleNetId, wheelBoneName)
                                        Wait(5000)
                                        break
                                    end
                                end
                            end
                            Wait(500)
                        end
                    end
                end
            else
                Wait(2000)
            end
        else
            for netId, grapplerData in pairs(grapplers) do
                if grapplerData and grapplerData.mode ~= grapplerModes.inactive then
                    local veh = NetToVeh(netId)
                    if not DoesEntityExist(veh) then
                        clearGrapplerProps(netId)
                        grapplers[netId] = nil
                    end
                end
            end
            Wait(1000)
        end
        Wait(0)
    end
end)

function isVehicleModelAllowed(vehicleModel)
    if vehicles[vehicleModel] == nil then
        return false
    else
        return true
    end
end

function raycast()
    local playerPed = PlayerPedId()
    local pedCoords = GetEntityCoords(playerPed)
    local forwardCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 10.0, 0.0)
    local shapeTest = StartShapeTestCapsule(pedCoords.x, pedCoords.y, pedCoords.z, forwardCoords.x, forwardCoords.y, forwardCoords.z, 10.0, 2, playerPed, 0)
    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shapeTest)
    return entityHit
end

function raycastDeploy(vehicle, startCoords)
    local forwardCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 10.0, 0.0)
    local shapeTest = StartShapeTestCapsule(startCoords.x, startCoords.y, startCoords.z, forwardCoords.x, forwardCoords.y, forwardCoords.z, main.radiusToAttachToVehicle, 2, vehicle, 0)
    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shapeTest)
    return entityHit
end

RegisterNetEvent("Client:receiveGrapplerTable")
AddEventHandler("Client:receiveGrapplerTable", function(grapplerTable)
    if grapplerTable == nil then
        return nil
    end
    
    grapplers = grapplerTable
    
    for netId, grapplerData in pairs(grapplers) do
        local vehicle = NetToVeh(netId)
        if DoesEntityExist(vehicle) then
            setupNewMode(netId)
        end
    end
end)

RegisterNetEvent("Client:updateGrapplerTable")
AddEventHandler("Client:updateGrapplerTable", function(vehicleNetId, mode, owner, vehicleModel)
    if grapplers[vehicleNetId] == nil then
        grapplers[vehicleNetId] = {}
        grapplers[vehicleNetId].mode = grapplerModes.inactive
        grapplers[vehicleNetId].owner = nil
        grapplers[vehicleNetId].props = {}
        
        if vehicleModel ~= nil then
            grapplers[vehicleNetId].model = vehicleModel
        end
    end
    
    local oldMode = grapplers[vehicleNetId].mode
    removeOldMode(vehicleNetId)
    grapplers[vehicleNetId].mode = mode
    grapplers[vehicleNetId].owner = owner
    setupNewMode(vehicleNetId)
end)

RegisterNetEvent("Client:grapplerCommand")
AddEventHandler("Client:grapplerCommand", function(action)
    if action == grapplerActions.install then
        installGrappler()
    elseif action == grapplerActions.deploy then
        deployGrappler()
    elseif action == grapplerActions.remove then
        removeGrappler()
    elseif action == grapplerActions.reset then
        resetGrappler()
    end
end)

RegisterNetEvent("Client:installGrappler")
AddEventHandler("Client:installGrappler", function()
    installGrappler()
end)

RegisterNetEvent("Client:removeGrappler")
AddEventHandler("Client:removeGrappler", function()
    removeGrappler()
end)

RegisterNetEvent("Client:deployGrapplerOnVehicle")
AddEventHandler("Client:deployGrapplerOnVehicle", function(policeVehicleNetId, targetVehicleNetId, wheelBoneName)
    if grapplers[policeVehicleNetId] ~= nil then
        grapplers[policeVehicleNetId].targetVehicle = targetVehicleNetId
        grapplers[policeVehicleNetId].mode = grapplerModes.used
        
        local policeVehicle = NetToVeh(policeVehicleNetId)
        local targetVehicle = NetToVeh(targetVehicleNetId)
        
        if DoesEntityExist(policeVehicle) and DoesEntityExist(targetVehicle) then
            clearGrapplerProps(policeVehicleNetId)
            if not grapplers[policeVehicleNetId] then return end
            if not grapplers[policeVehicleNetId].props then grapplers[policeVehicleNetId].props = {} end
            
            loadModel(props.bumperDeployed)
            if not grapplers[policeVehicleNetId] or not grapplers[policeVehicleNetId].props then return end
            local vehicleCoords = GetEntityCoords(policeVehicle)
            grapplers[policeVehicleNetId].props[1] = CreateObject(props.bumperDeployed, vehicleCoords, false, false, false)
            
            while not DoesEntityExist(grapplers[policeVehicleNetId].props[1]) do
                Wait(0)
                if not grapplers[policeVehicleNetId] or not grapplers[policeVehicleNetId].props then return end
            end
            
            SetModelAsNoLongerNeeded(props.bumperDeployed)
            
            if not grapplers[policeVehicleNetId] then return end
            local vehicleConfig = vehicles[grapplers[policeVehicleNetId].model]
            if vehicleConfig and grapplers[policeVehicleNetId].props and DoesEntityExist(grapplers[policeVehicleNetId].props[1]) then
                local vehicleOffset = vehicleConfig.offSet
                local vehicleRotation = vehicleConfig.rotation
                local vehicleBoneIndex = GetEntityBoneIndexByName(policeVehicle, vehicleConfig.boneName)
                
                AttachEntityToEntity(grapplers[policeVehicleNetId].props[1], policeVehicle, vehicleBoneIndex, vehicleOffset[1], vehicleOffset[2], vehicleOffset[3], vehicleRotation[1], vehicleRotation[2], vehicleRotation[3], true, false, true, false, 1, true)
            end
            
            loadModel(props.frameDeployed)
            if not grapplers[policeVehicleNetId] or not grapplers[policeVehicleNetId].props then return end
            grapplers[policeVehicleNetId].props[2] = CreateObject(props.frameDeployed, vehicleCoords, false, false, false)
            
            while not DoesEntityExist(grapplers[policeVehicleNetId].props[2]) do
                Wait(0)
                if not grapplers[policeVehicleNetId] or not grapplers[policeVehicleNetId].props then return end
            end
            
            SetModelAsNoLongerNeeded(props.frameDeployed)
            if grapplers[policeVehicleNetId] and grapplers[policeVehicleNetId].props and DoesEntityExist(grapplers[policeVehicleNetId].props[1]) and DoesEntityExist(grapplers[policeVehicleNetId].props[2]) then
                AttachEntityToEntity(grapplers[policeVehicleNetId].props[2], grapplers[policeVehicleNetId].props[1], -1, 0.0, 0.19, -0.13, -main.frameRotation + 0.0, 0.0, 0.0, true, false, true, false, 1, true)
            end
            
            local wheelBoneIndex = GetEntityBoneIndexByName(targetVehicle, wheelBoneName)
            
            if wheelBoneIndex ~= -1 then
                loadModel(props.wheelBlock)
                if not grapplers[policeVehicleNetId] or not grapplers[policeVehicleNetId].props then return end
                local wheelCoords = GetWorldPositionOfEntityBone(targetVehicle, wheelBoneIndex)
                grapplers[policeVehicleNetId].props[3] = CreateObject(props.wheelBlock, wheelCoords, false, false, false)
                
                while not DoesEntityExist(grapplers[policeVehicleNetId].props[3]) do
                    Wait(0)
                    if not grapplers[policeVehicleNetId] or not grapplers[policeVehicleNetId].props then return end
                end
                
                local wheelOffset = wheelBones[wheelBoneName].offSet
                local wheelRotation = wheelBones[wheelBoneName].rotation
                
                if grapplers[policeVehicleNetId] and grapplers[policeVehicleNetId].props and DoesEntityExist(grapplers[policeVehicleNetId].props[3]) then
                    AttachEntityToEntity(grapplers[policeVehicleNetId].props[3], targetVehicle, wheelBoneIndex, wheelOffset[1], wheelOffset[2], wheelOffset[3], wheelRotation[1], wheelRotation[2], wheelRotation[3], true, false, true, false, 1, true)
                end
                SetModelAsNoLongerNeeded(props.wheelBlock)
                
                if main.burstTyre then
                    local tyreIndex = tyreBurstIndex[wheelBoneName]
                    if tyreIndex ~= nil then
                        SetVehicleTyreBurst(targetVehicle, tyreIndex, false, main.burstTyreLevel)
                    end
                end
                
                RopeLoadTextures()
                local ropeLength = main.rope.defaultLength
                local maxRopeLength = main.rope.maxLength
                local ropeType = main.rope.type
                
                if grapplers[policeVehicleNetId] and grapplers[policeVehicleNetId].props and DoesEntityExist(grapplers[policeVehicleNetId].props[1]) then
                    local bumperCoords = GetEntityCoords(grapplers[policeVehicleNetId].props[1])
                    
                    ApplyForceToEntity(targetVehicle, 4, 0.0, 10.0, 0.0, 0.0, 10.0, 0.0, 0, false, true, true, false, true)
                    
                    local rope = AddRope(bumperCoords.x, bumperCoords.y, bumperCoords.z, 0.0, 0.0, 0.0, ropeLength, ropeType, maxRopeLength, 1.0, 0, 0, 0, 1, 0, 0, 0)
                    grapplers[policeVehicleNetId].rope = rope
                    
                    AttachEntitiesToRope(rope, policeVehicle, targetVehicle, bumperCoords.x, bumperCoords.y, bumperCoords.z, wheelCoords.x, wheelCoords.y, wheelCoords.z, ropeLength, false, false, vehicleBoneIndex, wheelBoneIndex)
                    
                    if main.forceHandbrake.enabled then
                        SetVehicleHandbrake(targetVehicle, true)
                        Wait(main.forceHandbrake.timeToForceHandbrake * 1000)
                        SetVehicleHandbrake(targetVehicle, false)
                        SetVehicleMaxSpeed(targetVehicle, main.forceHandbrake.maxSpeedAfterHandbrake / 2.23)
                        TriggerServerEvent("Server:updateHandBrakeTable", policeVehicleNetId, targetVehicleNetId)
                    end
                end
            end
        end
    end
end)

function debug(message)
    if main.debugMode then
        print(message)
    end
end

function clearGrapplerProps(vehicleNetId)
    if grapplers[vehicleNetId] == nil then
        return
    end
    
    if grapplers[vehicleNetId].props ~= nil then
        for propIndex, propEntity in pairs(grapplers[vehicleNetId].props) do
            if DoesEntityExist(propEntity) then
                DetachEntity(propEntity)
                DeleteEntity(propEntity)
            end
        end
    end
    
    if grapplers[vehicleNetId].rope ~= nil then
        if DoesRopeExist(grapplers[vehicleNetId].rope) then
            DeleteRope(grapplers[vehicleNetId].rope)
            RopeUnloadTextures()
        end
    end
    
    grapplers[vehicleNetId].props = {}
end

function removeOldMode(vehicleNetId)
    if grapplers[vehicleNetId] == nil then
        return
    end
    local mode = grapplers[vehicleNetId].mode
    
    if mode == grapplerModes.inactive then
        grapplers[vehicleNetId].props = {}
    elseif mode == grapplerModes.installed then
        clearGrapplerProps(vehicleNetId)
    elseif mode == grapplerModes.deployed then
        clearGrapplerProps(vehicleNetId)
    elseif mode == grapplerModes.used then
        if grapplers[vehicleNetId] and grapplers[vehicleNetId].rope and DoesRopeExist(grapplers[vehicleNetId].rope) then
            DeleteRope(grapplers[vehicleNetId].rope)
            RopeUnloadTextures()
        end
        clearGrapplerProps(vehicleNetId)
    end
    
    if grapplers[vehicleNetId] then
        grapplers[vehicleNetId].props = {}
    end
end

function setupNewMode(vehicleNetId)
    if grapplers[vehicleNetId] == nil then
        return
    end
    local mode = grapplers[vehicleNetId].mode
    local vehicle = NetToVeh(vehicleNetId)
    if not DoesEntityExist(vehicle) then return end
    local vehicleCoords = GetEntityCoords(vehicle)
    if not grapplers[vehicleNetId].props then
        grapplers[vehicleNetId].props = {}
    end
    
    if mode == grapplerModes.installed then
        loadModel(props.bumperClosed)
        if not grapplers[vehicleNetId] or not grapplers[vehicleNetId].props then return end
        grapplers[vehicleNetId].props[1] = CreateObject(props.bumperClosed, vehicleCoords, false, false, false)
        
        while not DoesEntityExist(grapplers[vehicleNetId].props[1]) do
            Wait(0)
            if not grapplers[vehicleNetId] or not grapplers[vehicleNetId].props then return end
        end
        
        SetModelAsNoLongerNeeded(props.bumperClosed)
        
        if not grapplers[vehicleNetId] then return end
        local vehicleConfig = vehicles[grapplers[vehicleNetId].model]
        if vehicleConfig and grapplers[vehicleNetId].props and DoesEntityExist(grapplers[vehicleNetId].props[1]) then
            local boneIndex = GetEntityBoneIndexByName(vehicle, vehicleConfig.boneName)
            local vehicleOffset = vehicleConfig.offSet
            local vehicleRotation = vehicleConfig.rotation
            
            AttachEntityToEntity(grapplers[vehicleNetId].props[1], vehicle, boneIndex, vehicleOffset[1], vehicleOffset[2], vehicleOffset[3], vehicleRotation[1], vehicleRotation[2], vehicleRotation[3], true, false, true, false, 1, true)
        end
    elseif mode == grapplerModes.deployed then
        local policeVehicle = NetToVeh(vehicleNetId)
        local playerPed = PlayerPedId()
        local currentVehicle = GetVehiclePedIsIn(playerPed, false)
        
        if policeVehicle == currentVehicle then
            if grapplerSound.enabled then
                PlaySoundFrontend(-1, grapplerSound.soundName, grapplerSound.soundDict)
                Wait(500)
                PlaySoundFrontend(-1, grapplerSound.soundName, grapplerSound.soundDict)
            end
        end
        
        if not grapplers[vehicleNetId] then return end
        if not grapplers[vehicleNetId].props then
            grapplers[vehicleNetId].props = {}
        end
        
        loadModel(props.bumperReady)
        if not grapplers[vehicleNetId] or not grapplers[vehicleNetId].props then return end
        grapplers[vehicleNetId].props[1] = CreateObject(props.bumperReady, vehicleCoords, false, false, false)
        
        while not DoesEntityExist(grapplers[vehicleNetId].props[1]) do
            Wait(0)
            if not grapplers[vehicleNetId] or not grapplers[vehicleNetId].props then return end
        end
        
        loadModel(props.frameReady)
        if not grapplers[vehicleNetId] or not grapplers[vehicleNetId].props then return end
        grapplers[vehicleNetId].props[2] = CreateObject(props.frameReady, vehicleCoords, false, false, false)
        
        while not DoesEntityExist(grapplers[vehicleNetId].props[2]) do
            Wait(0)
            if not grapplers[vehicleNetId] or not grapplers[vehicleNetId].props then return end
        end
        
        SetModelAsNoLongerNeeded(props.bumperReady)
        SetModelAsNoLongerNeeded(props.frameReady)
        
        if not grapplers[vehicleNetId] then return end
        local vehicleConfig = vehicles[grapplers[vehicleNetId].model]
        if vehicleConfig and grapplers[vehicleNetId].props and DoesEntityExist(grapplers[vehicleNetId].props[1]) then
            local boneIndex = GetEntityBoneIndexByName(policeVehicle, vehicleConfig.boneName)
            local vehicleOffset = vehicleConfig.offSet
            local vehicleRotation = vehicleConfig.rotation
            
            AttachEntityToEntity(grapplers[vehicleNetId].props[1], policeVehicle, boneIndex, vehicleOffset[1], vehicleOffset[2], vehicleOffset[3], vehicleRotation[1], vehicleRotation[2], vehicleRotation[3], true, false, true, false, 1, true)
        end
        
        for rotationStep = 1, main.frameRotation, 1 do
            if not grapplers[vehicleNetId] or not grapplers[vehicleNetId].props or not DoesEntityExist(grapplers[vehicleNetId].props[1]) or not DoesEntityExist(grapplers[vehicleNetId].props[2]) then
                break
            end
            DetachEntity(grapplers[vehicleNetId].props[2])
            AttachEntityToEntity(grapplers[vehicleNetId].props[2], grapplers[vehicleNetId].props[1], -1, 0.0, 0.19, -0.13, -rotationStep + 0.0, 0.0, 0.0, true, false, true, false, 1, true)
            Wait(40)
        end
    end
end

function grapplerAnimation(vehicle)
    if animation.enabled then
        local playerPed = PlayerPedId()
        local targetCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 2.5, 0.0)
        
        TaskGoToCoordAnyMeans(playerPed, targetCoords.x, targetCoords.y, targetCoords.z, 3.0, false, false, 786603, 1.0)
        
        while true do
            local pedCoords = GetEntityCoords(playerPed)
            local distance = #(targetCoords - pedCoords)
            if distance < 1.0 then
                break
            end
            Wait(0)
        end
        
        Wait(1000)
        TaskTurnPedToFaceEntity(playerPed, vehicle, 1.0)
        Wait(1800)
        ClearPedTasksImmediately(playerPed)
        SetVehicleDoorOpen(vehicle, 4, false, false)
        requestAnim(animation.dict)
        TaskPlayAnim(playerPed, animation.dict, animation.name, 8.0, -8.0, -1, 0, 0.0, 0, 0, 0)
        Wait(5000)
        SetVehicleDoorShut(vehicle, 4, false)
        ClearPedTasksImmediately(playerPed)
    end
end

function installGrappler()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        local targetVehicle = raycast()
        
        if targetVehicle ~= nil and targetVehicle ~= 0 then
            local vehicleModel = GetEntityModel(targetVehicle)
            
            if isVehicleModelAllowed(vehicleModel) then
                local vehicleNetId = VehToNet(targetVehicle)
                
                if grapplers[vehicleNetId] ~= nil and grapplers[vehicleNetId].mode ~= grapplerModes.inactive then
                    showNotification(translations.cannotPerformAction)
                else
                    grapplerAnimation(targetVehicle)
                    local vehicleName = (vehicles[vehicleModel] and vehicles[vehicleModel].name) or tostring(vehicleModel)
                    TriggerServerEvent("Server:newGrapplerLog", evenAtKey, translations.installedGrappler, translations.vehicle .. vehicleName)
                    TriggerServerEvent("Server:updateGrapplerTable", evenAtKey, vehicleNetId, grapplerModes.installed, vehicleModel)
                    showNotification(translations.installed)
                end
            else
                showNotification(translations.vehicleNotAllowed)
            end
        else
            showNotification(translations.noVehicleFound)
        end
    else
        showNotification(translations.inVehicle)
    end
end

function deployGrappler()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local driver = GetPedInVehicleSeat(vehicle, -1)
    
    if vehicle ~= 0 and playerPed == driver then
        local vehicleNetId = VehToNet(vehicle)
        local vehicleModel = GetEntityModel(vehicle)
        
        if grapplers[vehicleNetId] ~= nil and grapplers[vehicleNetId].mode == grapplerModes.installed then
            local vehicleName = (vehicles[vehicleModel] and vehicles[vehicleModel].name) or tostring(vehicleModel)
            TriggerServerEvent("Server:newGrapplerLog", evenAtKey, translations.deployedGrappler, translations.vehicle .. vehicleName)
            TriggerServerEvent("Server:updateGrapplerTable", evenAtKey, vehicleNetId, grapplerModes.deployed, vehicleModel)
            showNotification(translations.deployed)
        else
            showNotification(translations.cannotPerformAction)
        end
    else
        showNotification(translations.drivingVehicle)
    end
end

function removeGrappler()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        local targetVehicle = raycast()
        
        if targetVehicle ~= nil and targetVehicle ~= 0 then
            local vehicleModel = GetEntityModel(targetVehicle)
            
            if isVehicleModelAllowed(vehicleModel) then
                local vehicleNetId = VehToNet(targetVehicle)
                
                if grapplers[vehicleNetId] == nil or grapplers[vehicleNetId].mode == grapplerModes.inactive then
                    showNotification(translations.cannotPerformAction)
                else
                    grapplerAnimation(targetVehicle)
                    local vehicleName = (vehicles[vehicleModel] and vehicles[vehicleModel].name) or tostring(vehicleModel)
                    TriggerServerEvent("Server:updateGrapplerTable", evenAtKey, vehicleNetId, grapplerModes.inactive, vehicleModel)
                    TriggerServerEvent("Server:newGrapplerLog", evenAtKey, translations.removedGrappler, translations.vehicle .. vehicleName)
                    TriggerServerEvent("Server:requestHandbrakeTable", vehicleNetId)
                    showNotification(translations.removed)
                end
            else
                showNotification(translations.modelNotAllowed)
            end
        else
            showNotification(translations.noVehicleFound)
        end
    else
        showNotification(translations.inVehicle)
    end
end

function resetGrappler()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        local targetVehicle = raycast()
        
        if targetVehicle ~= nil and targetVehicle ~= 0 then
            local vehicleModel = GetEntityModel(targetVehicle)
            
            if isVehicleModelAllowed(vehicleModel) then
                local vehicleNetId = VehToNet(targetVehicle)
                
                if grapplers[vehicleNetId] == nil or grapplers[vehicleNetId].mode == grapplerModes.inactive then
                    showNotification(translations.cannotPerformAction)
                else
                    grapplerAnimation(targetVehicle)
                    local vehicleName = (vehicles[vehicleModel] and vehicles[vehicleModel].name) or tostring(vehicleModel)
                    TriggerServerEvent("Server:updateGrapplerTable", evenAtKey, vehicleNetId, grapplerModes.inactive, vehicleModel)
                    TriggerServerEvent("Server:newGrapplerLog", evenAtKey, translations.removedGrappler, translations.vehicle .. vehicleName)
                    TriggerServerEvent("Server:requestHandbrakeTable", vehicleNetId)
                    Citizen.Wait(100)
                    TriggerServerEvent("Server:newGrapplerLog", evenAtKey, translations.installedGrappler, translations.vehicle .. vehicleName)
                    TriggerServerEvent("Server:updateGrapplerTable", evenAtKey, vehicleNetId, grapplerModes.installed, vehicleModel)
                    showNotification(translations.reset)
                end
            else
                showNotification(translations.modelNotAllowed)
            end
        else
            showNotification(translations.noVehicleFound)
        end
    else
        showNotification(translations.inVehicle)
    end
end

RegisterNetEvent("Client:updateHandBrakeTable")
AddEventHandler("Client:updateHandBrakeTable", function(handbrakeTable, targetVehicleNetId)
    for netId, handbrakeData in pairs(handbrakeTable) do
        if netId == targetVehicleNetId then
            local vehicle = NetToVeh(handbrakeData.targetNetId)
            local maxSpeed = GetVehicleMaxSpeed(handbrakeData.targetNetId)
            SetVehicleMaxSpeed(vehicle, maxSpeed)
        end
    end
end)

RegisterNetEvent("Client:GrapplerInstallForOutOfScope")
AddEventHandler("Client:GrapplerInstallForOutOfScope", function(grapplerTable, vehicleNetId)
    grapplers = grapplerTable
    Wait(3000)
    if grapplers[vehicleNetId] ~= nil then
        removeOldMode(vehicleNetId)
        
        local vehicle = NetToVeh(vehicleNetId)
        if DoesEntityExist(vehicle) then
            setupNewMode(vehicleNetId)
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    local currentResource = GetCurrentResourceName()
    if currentResource == resourceName then
        for netId, grapplerData in pairs(grapplers) do
            clearGrapplerProps(netId)
        end
        grapplers = {}
    end
end)
