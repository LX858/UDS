local propSlots = {}
local animData = {}

propSlots[1] = {
    entity = nil,
    model = nil,
    boneId = nil,
    offset = vector3(0.0, 0.0, 0.0),
    rot = vector3(0.0, 0.0, 0.0),
    rotOrder = 1
}

propSlots[2] = {
    entity = nil,
    model = nil,
    boneId = nil,
    offset = vector3(0.0, 0.0, 0.0),
    rot = vector3(0.0, 0.0, 0.0),
    rotOrder = 1
}

animData = {
    dict = nil,
    anim = nil,
    flags = 0
}

local moveSpeed = 0.01
local rotateSpeed = 0.1
local defaultMoveSpeeds = {0.001, 0.01, 0.1, 0.5, 1.0}
local defaultRotateSpeeds = {0.001, 0.01, 0.1, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0}
local isUIOpen = false
local camera = nil
local cameraFocus = "ped"
local cameraDistance = 2.5
local cameraAngle = 0.0
local cameraHeight = 0.5
RegisterCommand(Config.Command, function()
    TriggerServerEvent("dc_propattach:server:checkAdmin")
end)
RegisterNetEvent("dc_propattach:client:admincheck", function(hasPermission)
    if hasPermission then
        if not isUIOpen then
            isUIOpen = true
            SetNuiFocus(true, true)
            createOrUpdateCamera()
            SendNUIMessage({
                type = "openUI",
                props = Config.Props,
                animations = Config.Animations,
                bones = Config.Bones,
                moveSpeed = moveSpeed,
                rotateSpeed = rotateSpeed,
                defaultMoveSpeeds = defaultMoveSpeeds,
                defaultRotateSpeeds = defaultRotateSpeeds,
                cameraDistance = cameraDistance,
                cameraAngle = cameraAngle,
                cameraHeight = cameraHeight,
                cameraFocus = cameraFocus
            })
        end
    else
        TriggerEvent("chat:addMessage", {
            color = {255, 0, 0},
            multiline = true,
            args = {"[SYSTEM]", "You don't have permission to use this command!"}
        })
    end
end)
RegisterNUICallback("resetAll", function(data, callback)
    DoPropReset()
    SendNUIMessage({
        type = "resetAllUI"
    })
    callback("ok")
end)
RegisterNUICallback("closeUI", function(data, callback)
    DoPropReset()
    isUIOpen = false
    SetNuiFocus(false, false)
    callback("ok")
end)
function DoPropReset()
    for propIndex = 1, 2, 1 do
        if propSlots[propIndex].entity then
            if DoesEntityExist(propSlots[propIndex].entity) then
                DeleteEntity(propSlots[propIndex].entity)
            end
        end
        propSlots[propIndex].entity = nil
        propSlots[propIndex].model = nil
        propSlots[propIndex].boneId = nil
        propSlots[propIndex].offset = vector3(0.0, 0.0, 0.0)
        propSlots[propIndex].rot = vector3(0.0, 0.0, 0.0)
        propSlots[propIndex].rotOrder = 1
    end
    ClearPedTasksImmediately(PlayerPedId())
    animData = {
        dict = nil,
        anim = nil,
        flags = 0
    }
    if camera then
        if DoesCamExist(camera) then
            DestroyCam(camera, false)
            camera = nil
        end
    end
    RenderScriptCams(false, false, 0, true, false)
    cameraFocus = "ped"
    cameraDistance = 2.5
    cameraAngle = 0.0
    cameraHeight = 0.5
end
RegisterNUICallback("spawnProp", function(data, callback)
    local propIndex = data.propIndex
    local modelName = data.modelName
    if not (propIndex and modelName) or modelName == "" then
        callback("invalid args")
        return
    end
    if propSlots[propIndex].entity then
        if DoesEntityExist(propSlots[propIndex].entity) then
            DeleteEntity(propSlots[propIndex].entity)
        end
    end
    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    local startTime = GetGameTimer()
    while not HasModelLoaded(modelHash) do
        Wait(0)
        if GetGameTimer() - startTime > 5000 then
            callback("model load fail")
            return
        end
    end
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local forwardVector = GetEntityForwardVector(playerPed)
    local spawnPos = playerCoords + forwardVector * 2.0
    local propEntity = CreateObject(modelHash, spawnPos.x, spawnPos.y, spawnPos.z, true, true, false)
    if not propEntity or not DoesEntityExist(propEntity) then
        callback("spawn fail")
        return
    end
    SetEntityHeading(propEntity, GetEntityHeading(playerPed))
    PlaceObjectOnGroundProperly(propEntity)
    SetModelAsNoLongerNeeded(modelHash)
    local networkId = NetworkGetNetworkIdFromEntity(propEntity)
    SetNetworkIdExistsOnAllMachines(networkId, true)
    SetNetworkIdCanMigrate(networkId, true)
    propSlots[propIndex].entity = propEntity
    propSlots[propIndex].model = modelName
    if propSlots[propIndex].boneId then
        AttachEntityToPedBone(propIndex)
    end
    callback("ok")
end)
RegisterNUICallback("deleteProp", function(data, callback)
    local propIndex = data.propIndex
    if not propIndex then
        callback("invalid propIndex")
        return
    end
    if propSlots[propIndex].entity then
        if DoesEntityExist(propSlots[propIndex].entity) then
            DeleteEntity(propSlots[propIndex].entity)
        end
    end
    propSlots[propIndex].entity = nil
    callback("ok")
end)
RegisterNUICallback("setBone", function(data, callback)
    local propIndex = data.propIndex
    local boneId = data.boneId
    if not propIndex or not boneId then
        callback("invalid bone")
        return
    end
    propSlots[propIndex].boneId = boneId
    if propSlots[propIndex].entity then
        if DoesEntityExist(propSlots[propIndex].entity) then
            AttachEntityToPedBone(propIndex)
        end
    end
    callback("ok")
end)
RegisterNUICallback("setRotationOrder", function(data, callback)
    local propIndex = data.propIndex
    local order = data.order
    if not propIndex or order == nil then
        callback("invalid rot order")
        return
    end
    propSlots[propIndex].rotOrder = order
    if propSlots[propIndex].entity then
        if DoesEntityExist(propSlots[propIndex].entity) then
            AttachEntityToPedBone(propIndex)
        end
    end
    callback("ok")
end)
RegisterNUICallback("moveProp", function(data, callback)
    local propIndex = data.propIndex
    local direction = data.direction
    if not propIndex or not direction then
        callback("invalid")
        return
    end
    local propData = propSlots[propIndex]
    if not propData.entity or not DoesEntityExist(propData.entity) then
        callback("no entity")
        return
    end
    if direction == "forward" then
        propData.offset = propData.offset + vector3(moveSpeed, 0.0, 0.0)
    elseif direction == "back" then
        propData.offset = propData.offset + vector3(-moveSpeed, 0.0, 0.0)
    elseif direction == "left" then
        propData.offset = propData.offset + vector3(0.0, moveSpeed, 0.0)
    elseif direction == "right" then
        propData.offset = propData.offset + vector3(0.0, -moveSpeed, 0.0)
    elseif direction == "up" then
        propData.offset = propData.offset + vector3(0.0, 0.0, moveSpeed)
    elseif direction == "down" then
        propData.offset = propData.offset + vector3(0.0, 0.0, -moveSpeed)
    elseif direction == "rotLeft" then
        propData.rot = propData.rot + vector3(0.0, 0.0, -rotateSpeed)
    elseif direction == "rotRight" then
        propData.rot = propData.rot + vector3(0.0, 0.0, rotateSpeed)
    elseif direction == "rotUp" then
        propData.rot = propData.rot + vector3(rotateSpeed, 0.0, 0.0)
    elseif direction == "rotDown" then
        propData.rot = propData.rot + vector3(-rotateSpeed, 0.0, 0.0)
    elseif direction == "rotClock" then
        propData.rot = propData.rot + vector3(0.0, rotateSpeed, 0.0)
    elseif direction == "rotCClock" then
        propData.rot = propData.rot + vector3(0.0, -rotateSpeed, 0.0)
    end
    AttachEntityToPedBone(propIndex)
    callback("ok")
end)
RegisterNUICallback("updateMoveSpeed", function(data, callback)
    local value = tonumber(data.value)
    if value then
        moveSpeed = value
    end
    callback("ok")
end)
RegisterNUICallback("updateRotateSpeed", function(data, callback)
    local value = tonumber(data.value)
    if value then
        rotateSpeed = value
    end
    callback("ok")
end)
RegisterNUICallback("setAnimation", function(data, callback)
    animData.dict = data.dict
    animData.anim = data.anim
    animData.flags = data.flags
    callback("ok")
end)
RegisterNUICallback("playAnim", function(data, callback)
    if animData.dict and animData.anim then
        local playerPed = PlayerPedId()
        ClearPedTasks(playerPed)
        RequestAnimDict(animData.dict)
        local startTime = GetGameTimer()
        while not HasAnimDictLoaded(animData.dict) do
            Wait(0)
            if GetGameTimer() - startTime > 5000 then
                callback("failed anim dict")
                return
            end
        end
        TaskPlayAnim(playerPed, animData.dict, animData.anim, 8.0, 8.0, -1, animData.flags, 0, false, false, false)
    end
    callback("ok")
end)
RegisterNUICallback("stopAnim", function(data, callback)
    ClearPedTasks(PlayerPedId())
    callback("ok")
end)
RegisterNUICallback("copyData", function(data, callback)
    local propIndex = data.propIndex
    local format = data.format
    if not format then
        format = "devcore"
    end
    if not propIndex then
        callback("error")
        return
    end
    local propData = propSlots[propIndex]
    if not propData.model or not propData.boneId then
        callback("no data")
        return
    end
    local output = nil
    if format == "ox" then
        output = string.format([[
anim = { dict = '%s', clip = '%s' },
prop = {
    model = '%s',
    bone = %d,
    pos = vec3(%.6f, %.6f, %.6f),
    rot = vec3(%.6f, %.6f, %.6f)
},]], animData.dict or "", animData.anim or "", propData.model, propData.boneId, propData.offset.x, propData.offset.y, propData.offset.z, propData.rot.x, propData.rot.y, propData.rot.z)
    elseif format == "emotes" then
        output = string.format([[
Prop = '%s',
PropBone = %d,
PropPlacement = {
    %.4f,
    %.4f,
    %.4f,
    %.1f,
    %.1f,
    %.1f
},]], propData.model, propData.boneId, propData.offset.x, propData.offset.y, propData.offset.z, propData.rot.x, propData.rot.y, propData.rot.z)
    else
        output = string.format([[
Model = '%s',
BoneID = %d,
Offset = vector3(%.6f, %.6f, %.6f),
Rot = vector3(%.6f, %.6f, %.6f),
AnimDict = '%s',
Anim = '%s']], propData.model, propData.boneId, propData.offset.x, propData.offset.y, propData.offset.z, propData.rot.x, propData.rot.y, propData.rot.z, animData.dict or "", animData.anim or "")
    end
    SendNUIMessage({
        type = "clipboard",
        text = output
    })
    callback("ok")
end)
RegisterNUICallback("resetProp", function(data, callback)
    local propIndex = data.propIndex
    if not propIndex then
        callback("error")
        return
    end
    propSlots[propIndex].offset = vector3(0.0, 0.0, 0.0)
    propSlots[propIndex].rot = vector3(0.0, 0.0, 0.0)
    if propSlots[propIndex].entity then
        if DoesEntityExist(propSlots[propIndex].entity) then
            AttachEntityToPedBone(propIndex)
        end
    end
    callback("ok")
end)
RegisterNUICallback("setOffset", function(data, callback)
    local propIndex = data.propIndex
    if not propIndex then
        callback("error")
        return
    end
    if data.px ~= nil then
        propSlots[propIndex].offset = vector3(
            tonumber(data.px) or 0.0,
            tonumber(data.py) or 0.0,
            tonumber(data.pz) or 0.0
        )
    end
    if data.rx ~= nil then
        propSlots[propIndex].rot = vector3(
            tonumber(data.rx) or 0.0,
            tonumber(data.ry) or 0.0,
            tonumber(data.rz) or 0.0
        )
    end
    if propSlots[propIndex].entity then
        if DoesEntityExist(propSlots[propIndex].entity) then
            AttachEntityToPedBone(propIndex)
        end
    end
    callback("ok")
end)
RegisterNUICallback("updateCameraFocus", function(data, callback)
    cameraFocus = data.focus
    updateCamera()
    callback("ok")
end)
RegisterNUICallback("updateCamera", function(data, callback)
    if data.dist then
        cameraDistance = tonumber(data.dist)
    end
    if data.angle then
        cameraAngle = tonumber(data.angle)
    end
    if data.height then
        cameraHeight = tonumber(data.height)
    end
    updateCamera()
    callback("ok")
end)
RegisterNUICallback("nudgeCamera", function(data, callback)
    local axis = data.axis
    local amount = data.amount
    if axis == "dist" then
        cameraDistance = cameraDistance + amount
        if cameraDistance < 0.1 then
            cameraDistance = 0.1
        end
    elseif axis == "angle" then
        cameraAngle = cameraAngle + amount
        if cameraAngle < 0 then
            cameraAngle = cameraAngle + 360
        end
        if cameraAngle >= 360 then
            cameraAngle = cameraAngle - 360
        end
    elseif axis == "height" then
        cameraHeight = cameraHeight + amount
    end
    updateCamera()
    callback("ok")
end)
function createOrUpdateCamera()
    if not camera or not DoesCamExist(camera) then
        camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    end
    RenderScriptCams(true, false, 0, true, false)
    updateCamera()
end
function updateCamera()
    if not camera or not DoesCamExist(camera) then
        return
    end
    local playerPed = PlayerPedId()
    local focusCoords = GetEntityCoords(playerPed)
    print("Camera focus: " .. cameraFocus)
    if cameraFocus == "prop1" then
        if propSlots[1].entity ~= nil then
            if DoesEntityExist(propSlots[1].entity) then
                focusCoords = GetEntityCoords(propSlots[1].entity)
                print("Focusing on prop1")
            else
                print("Prop1 entity exists in data but not in game")
            end
        end
    elseif cameraFocus == "prop2" then
        if propSlots[2].entity ~= nil then
            if DoesEntityExist(propSlots[2].entity) then
                focusCoords = GetEntityCoords(propSlots[2].entity)
                print("Focusing on prop2")
            else
                print("Prop2 entity exists in data but not in game")
            end
        end
    end
    local angleRadians = math.rad(cameraAngle)
    local offsetX = cameraDistance * math.cos(angleRadians)
    local offsetY = cameraDistance * math.sin(angleRadians)
    local camX = focusCoords.x + offsetX
    local camY = focusCoords.y + offsetY
    local camZ = focusCoords.z + cameraHeight
    SetCamCoord(camera, camX, camY, camZ)
    PointCamAtCoord(camera, focusCoords.x, focusCoords.y, focusCoords.z)
    SetCamActive(camera, true)
end
function destroyCamera()
    if camera then
        if DoesCamExist(camera) then
            DestroyCam(camera, false)
            camera = nil
        end
    end
    RenderScriptCams(false, false, 0, true, false)
end
function AttachEntityToPedBone(propIndex)
    local playerPed = PlayerPedId()
    local propData = propSlots[propIndex]
    if not propData.entity or not DoesEntityExist(propData.entity) then
        return
    end
    if not propData.boneId then
        return
    end
    local boneIndex = GetPedBoneIndex(playerPed, propData.boneId)
    AttachEntityToEntity(propData.entity, playerPed, boneIndex, propData.offset.x, propData.offset.y, propData.offset.z, propData.rot.x, propData.rot.y, propData.rot.z, true, true, false, true, 1, propData.rotOrder)
end
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DoPropReset()
    end
end)
