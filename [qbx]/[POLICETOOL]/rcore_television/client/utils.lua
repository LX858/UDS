local duiUrlMap = {}

function GetLoadingDUILink(identifier, link)
    return string.format("nui://rcore_television/html/loaded.html?identifier=%s&link=%s", identifier, link)
end

function SetDUILink(duiObj, url)
    duiUrlMap[duiObj] = url
    SetDuiUrl(duiObj, url)
end

function GetDuiUrl(duiObj)
    return duiUrlMap[duiObj] or "nil dui url"
end

function GetTelevisionCameraData(modelHash, entity)
    local modelData = Config.resolution[modelHash]
    local offset = modelData.CameraOffSet or { x = 0, y = 0, z = 0 }

    local camPos = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
    local camRot = GetEntityRotation(entity)

    if offset.rotation ~= nil then
        camRot = GetEntityRotation(entity) - offset.rotation
    end

    return camPos, camRot
end

function IsAnyDuiActiveOnCoords(coords)
    local _, tvEntry = GetTelevisionAtCoords(coords)
    local menuEntry = TelevisionCache.menu

    if menuEntry then
        Debug("IsDuiAvailable, 21")
        if not menuEntry.duiObj then
            Debug("Dui isnt avaiable line 48")
            return false
        end
        return IsDuiAvailable(menuEntry.duiObj)
    end

    if not tvEntry then return false end

    Debug("IsDuiAvailable, 29")
    return IsDuiAvailable(tvEntry.duiObj)
end

function GetCustomTelevision(coords)
    for index, entry in pairs(Config.PlayingTelevisionOnLocation) do
        local dist = #(entry.Position - coords)
        if dist < 1.0 then
            return index, entry
        end
    end
    return nil, nil
end

function GetModelDataByHash(modelHash)
    if Config.resolution[modelHash] then
        return modelHash, Config.resolution[modelHash]
    end
    return nil, nil
end

function GetTelevisionAtCoords(coords)
    for index, entry in pairs(TelevisionCache) do
        local dist = #(entry.tvPos - coords)
        if dist < 1.0 and index ~= "menu" then
            return index, entry
        end
    end
    return nil, nil
end

function DestroyDuiAndScaleform()
    for _, entry in pairs(TelevisionCache) do
        if entry.scaleformLoaded and entry.duiLoaded then
            Debug("DestroyDui | utils.lua | 75")
            DestroyDui(entry.duiObj)
            SetScaleformMovieAsNoLongerNeeded(entry.scaleformId)
            UnreleaseOccupiedScaleform(entry.scaleformName)
            entry.scaleformLoaded = nil
            entry.duiLoaded = nil
        end
    end
end

function CreateLocalObject(modelInput, position)
    local modelHash = tonumber(modelInput) and modelInput or GetHashKey(modelInput)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(16) end
    local obj = CreateObject(modelHash, position.x, position.y, position.z, false, false, false)
    SetEntityCoordsNoOffset(obj, position.x, position.y, position.z)
    return obj
end

function CreateNetworkObject(modelInput, position)
    local modelHash = tonumber(modelInput) and modelInput or GetHashKey(modelInput)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(16) end
    local obj = CreateObject(modelHash, position.x, position.y, position.z, true, false, false)
    SetEntityCoordsNoOffset(obj, position.x, position.y, position.z)
    return obj
end

function DuiMessage(duiObj, payload)
    SendDuiMessage(duiObj, json.encode(payload))
end

function GetTelevisionMetaData(modelHash, entity)
    local modelData = Config.resolution[modelHash]
    local screenOffset = modelData.ScreenOffSet or vector3(0, 0, 0)

    if Config.Editor then
        screenOffset = vector3(0, 0, 0)
    end

    local screenPos = GetOffsetFromEntityInWorldCoords(entity, screenOffset.x, screenOffset.y, screenOffset.z)
    local entityRot = GetEntityRotation(entity)
    local viewDistance = modelData.distance or 10.0

    if modelData.rotationOffset then
        entityRot = vector3(entityRot.x, entityRot.y, entityRot.z) - modelData.rotationOffset
    end

    local modelDiameter = #GetModelDimensions(modelHash)
    local screenSize = modelData.ScreenSize

    if Config.Editor then
        screenSize = vector3(0, 0, 0)
    end

    local sizeX = (modelDiameter / 1.204) * 100 * 5.75e-4
    local sizeY = (modelDiameter / 1.204) * 100 * 3.25e-4
    local sizeZ = (modelDiameter / 1.204) * 100 * 0.001085
    local tvSize = vector3(sizeX, sizeY, sizeZ) - screenSize

    local customSizes = Config.CustomScreenSizes[modelHash]
    if customSizes then
        for _, customEntry in pairs(customSizes) do
            local dist = #(GetEntityCoords(entity) - customEntry.pos)
            if dist < 7.5 then
                local cx = (modelDiameter / 1.204) * 100 * 5.75e-4
                local cy = (modelDiameter / 1.204) * 100 * 3.25e-4
                local cz = (modelDiameter / 1.204) * 100 * 0.001085
                tvSize = vector3(cx, cy, cz) - customEntry.ScreenSize
                viewDistance = customEntry.distanceToOpen
                break
            end
        end
    end

    return screenPos, tvSize, entityRot, viewDistance, modelData
end

function CastRayCast(fromEntity, flags, maxDistance, filterType, drawDebug)
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local camPos = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot()
    local direction = RotationToDirection(camRot)
    local distance = maxDistance or 15.0

    local endPos = {
        x = camPos.x + direction.x * distance,
        y = camPos.y + direction.y * distance,
        z = camPos.z + direction.z * distance,
    }

    local rayHandle = StartShapeTestRay(
        playerPos.x, playerPos.y, playerPos.z,
        endPos.x, endPos.y, endPos.z,
        filterType or 17,
        fromEntity or PlayerPedId(),
        1
    )

    local hit, _, hitPos, hitNormal, hitEntity = GetShapeTestResult(rayHandle)

    if drawDebug then
        DrawLine(playerPos.x, playerPos.y, playerPos.z, endPos.x, endPos.y, endPos.z, 255, 255, 255, 255)
    end

    return hit, hitPos, hitNormal, hitEntity
end

function RotationToDirection(rotation)
    local radians = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z,
    }
    local cosX = math.abs(math.cos(radians.x))
    return {
        x = -math.sin(radians.z) * cosX,
        y =  math.cos(radians.z) * cosX,
        z =  math.sin(radians.x),
    }
end

function draw3DText(coords, text, options)
    if not options then options = {} end
    local color = options.color or { r = 255, g = 255, b = 255, a = 255 }
    local size = options.size or 0.6

    local camPos = GetGameplayCamCoords()
    local dist = #(camPos - coords)
    local scale = (size / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scaledSize = scale * fov

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextProportional(0)
    SetTextScale(0.0 * scaledSize, 0.55 * scaledSize)
    SetTextColour(color.r, color.g, color.b, color.a)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

function CreateTargetModel(modelInput, options)
    local modelHash = tonumber(modelInput) and modelInput or GetHashKey(modelInput)
    local resourceName = TargetTypeResourceName[Config.TargetZoneType]

    local supportedTargets = {
        [TargetType.Q_TARGET]  = true,
        [TargetType.BT_TARGET] = true,
        [TargetType.QB_TARGET] = true,
    }

    if Config.TargetZoneType == TargetType.OX_TARGET then
        exports.ox_target:addModel(modelHash, options)
    elseif supportedTargets[Config.TargetZoneType] then
        local distance = (options[1] and options[1].distance) or options.distance or Config.DefaultOpenDistance
        exports[resourceName]:AddTargetModel(modelHash, { options = options, distance = distance })
    end
end
