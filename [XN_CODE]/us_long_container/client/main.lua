local containers = {}
local syncedStates = {}
local spawned = false
local ensureLock
local removeLock
local isNearFront
local isNearLock
local playCutLockAnimation

local points = {}
local spawning = {}
local cancelSpawn = {}

local function getOpenTargetName(runtime)
    return ('us_long_container_open_%s'):format(runtime.id)
end

local function getCloseTargetName(runtime)
    return ('us_long_container_close_%s'):format(runtime.id)
end

local function notify(description, notifyType)
    lib.notify({
        title = 'Container',
        description = description,
        type = notifyType or 'inform'
    })
end

local function loadModel(modelName)
    local model = joaat(modelName)

    if not IsModelInCdimage(model) or not IsModelValid(model) then
        print(('[us_long_container] Model không hợp lệ: %s'):format(modelName))
        return nil
    end

    RequestModel(model)
    local timeout = GetGameTimer() + 10000

    while not HasModelLoaded(model) do
        if GetGameTimer() >= timeout then
            print(('[us_long_container] Hết thời gian tải model: %s'):format(modelName))
            return nil
        end

        Wait(0)
    end

    return model
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 10000

    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() >= timeout then
            print(('[us_long_container] Hết thời gian tải anim dict: %s'):format(dict))
            return false
        end

        Wait(0)
    end

    return true
end

local function loadPtfxAsset(asset)
    RequestNamedPtfxAsset(asset)
    local timeout = GetGameTimer() + 10000

    while not HasNamedPtfxAssetLoaded(asset) do
        if GetGameTimer() >= timeout then
            print(('[us_long_container] Hết thời gian tải ptfx asset: %s'):format(asset))
            return false
        end

        Wait(0)
    end

    return true
end

local function smoothStep(value)
    return value * value * (3.0 - (2.0 * value))
end

local function lerp(a, b, progress)
    return a + ((b - a) * progress)
end

local function lerpVector3(from, to, progress)
    return vec3(
        lerp(from.x, to.x, progress),
        lerp(from.y, to.y, progress),
        lerp(from.z, to.z, progress)
    )
end

local function attachDoor(doorEntity, bodyEntity, position, rotation)
    if not DoesEntityExist(doorEntity) or not DoesEntityExist(bodyEntity) then
        return
    end

    AttachEntityToEntity(
        doorEntity,
        bodyEntity,
        0,
        position.x,
        position.y,
        position.z,
        rotation.x,
        rotation.y,
        rotation.z,
        false,
        false,
        Config.Door.collision,
        false,
        2,
        true
    )
end

local function applyDoorPose(runtime, leftRotation, rightRotation)
    attachDoor(runtime.leftDoor, runtime.body, Config.Door.left.position, leftRotation)
    attachDoor(runtime.rightDoor, runtime.body, Config.Door.right.position, rightRotation)
end

local function removeOpenTarget(runtime)
    if runtime.lockZoneId then
        exports.ox_target:removeZone(runtime.lockZoneId)
        runtime.lockZoneId = nil
    end
end

local function removeCloseTarget(runtime)
    if DoesEntityExist(runtime.body) then
        exports.ox_target:removeLocalEntity(runtime.body, {
            getCloseTargetName(runtime)
        })
    end
end

local function addCloseTarget(runtime)
    exports.ox_target:addLocalEntity(runtime.body, {
        {
            name = getCloseTargetName(runtime),
            icon = Config.Target.closeIcon,
            label = Config.Target.closeLabel,
            distance = Config.TargetDistance,
            canInteract = function()
                return isNearFront(runtime)
                    and not runtime.busy
                    and runtime.isOpen
                    and CanUseLongContainer(runtime.id, false)
            end,
            onSelect = function()
                if runtime.busy or not runtime.isOpen then
                    return
                end

                TriggerServerEvent('us_long_container:server:requestState', runtime.id, false)
            end
        }
    })
end

local function addOpenTarget(runtime)
    if not runtime.lock or not DoesEntityExist(runtime.lock) then
        return
    end

    removeOpenTarget(runtime)

    local lockCoords = GetEntityCoords(runtime.lock)
    runtime.lockZoneId = exports.ox_target:addSphereZone({
        coords = lockCoords,
        radius = 0.45,
        drawSprite = false,
        options = {
            {
                name = getOpenTargetName(runtime),
                icon = Config.Target.openIcon,
                label = Config.Target.openLabel,
                distance = Config.TargetDistance,
                canInteract = function()
                    return isNearLock(runtime)
                        and not runtime.busy
                        and not runtime.isOpen
                        and CanUseLongContainer(runtime.id, true)
                end,
                onSelect = function()
                    if runtime.busy or runtime.isOpen then
                        return
                    end

                    -- Kiểm tra item nếu bật
                    if Config.RequireItem.enabled then
                        local hasItem = exports.ox_inventory:Search('count', Config.RequireItem.itemName) > 0
                        if not hasItem then
                            notify('Bạn thiếu chìa khóa container.', 'error')
                            return
                        end
                    end

                    runtime.busy = true
                    CreateThread(function()
                        local ok, result = pcall(playCutLockAnimation, runtime)

                        if not ok then
                            runtime.busy = false
                            notify('Loi khi chay animation cua khoa. Kiem tra F8.', 'error')
                            print(('[us_long_container] playCutLockAnimation error: %s'):format(tostring(result)))
                            return
                        end

                        if not result then
                            runtime.busy = false
                            return
                        end

                        removeLock(runtime)
                        TriggerServerEvent('us_long_container:server:requestState', runtime.id, true)
                    end)
                end
            }
        }
    })
end

local function setImmediateState(runtime, isOpen)
    local leftRotation = isOpen and Config.Door.left.openRotation or Config.Door.left.closedRotation
    local rightRotation = isOpen and Config.Door.right.openRotation or Config.Door.right.closedRotation

    runtime.animationToken = runtime.animationToken + 1
    runtime.busy = false
    runtime.isOpen = isOpen
    runtime.leftRotation = leftRotation
    runtime.rightRotation = rightRotation

    if isOpen then
        removeLock(runtime)
    else
        ensureLock(runtime)
    end

    applyDoorPose(runtime, leftRotation, rightRotation)
end

local function animateState(runtime, isOpen)
    if not runtime or not DoesEntityExist(runtime.body) then
        return
    end

    runtime.animationToken = runtime.animationToken + 1
    local token = runtime.animationToken
    runtime.busy = true

    local leftFrom = runtime.leftRotation or Config.Door.left.closedRotation
    local rightFrom = runtime.rightRotation or Config.Door.right.closedRotation
    local leftTo = isOpen and Config.Door.left.openRotation or Config.Door.left.closedRotation
    local rightTo = isOpen and Config.Door.right.openRotation or Config.Door.right.closedRotation
    local startedAt = GetGameTimer()
    local duration = math.max(Config.AnimationDuration, 1)

    CreateThread(function()
        while runtime.animationToken == token do
            local elapsed = GetGameTimer() - startedAt
            local progress = math.min(elapsed / duration, 1.0)
            local eased = smoothStep(progress)

            runtime.leftRotation = lerpVector3(leftFrom, leftTo, eased)
            runtime.rightRotation = lerpVector3(rightFrom, rightTo, eased)
            applyDoorPose(runtime, runtime.leftRotation, runtime.rightRotation)

            if progress >= 1.0 then
                break
            end

            Wait(0)
        end

        if runtime.animationToken ~= token then
            return
        end

        runtime.leftRotation = leftTo
        runtime.rightRotation = rightTo
        runtime.isOpen = isOpen
        runtime.busy = false
        applyDoorPose(runtime, leftTo, rightTo)
    end)
end

local function applyTextureVariation(entity, variation)
    if variation == nil or not DoesEntityExist(entity) then
        return
    end

    SetObjectTextureVariation(entity, variation)
end

local function createDoor(model, bodyCoords)
    local entity = CreateObjectNoOffset(model, bodyCoords.x, bodyCoords.y, bodyCoords.z, false, false, false)

    if entity == 0 then
        return nil
    end

    SetEntityAsMissionEntity(entity, true, true)
    SetEntityCollision(entity, Config.Door.collision, true)
    SetEntityInvincible(entity, Config.Door.invincible)
    SetEntityCanBeDamaged(entity, not Config.Door.invincible)
    SetEntityLodDist(entity, Config.Door.lodDistance)

    return entity
end

local function createLock(model, bodyCoords)
    local entity = CreateObjectNoOffset(model, bodyCoords.x, bodyCoords.y, bodyCoords.z, false, false, false)

    if entity == 0 then
        return nil
    end

    SetEntityAsMissionEntity(entity, true, true)
    SetEntityCollision(entity, Config.Lock.collision, true)
    SetEntityInvincible(entity, Config.Lock.invincible)
    SetEntityCanBeDamaged(entity, not Config.Lock.invincible)
    SetEntityLodDist(entity, Config.Door.lodDistance)

    return entity
end

local function attachLock(runtime)
    if not runtime.lock or not DoesEntityExist(runtime.lock) or not DoesEntityExist(runtime.body) then
        return
    end

    AttachEntityToEntity(
        runtime.lock,
        runtime.body,
        0,
        Config.Lock.position.x,
        Config.Lock.position.y,
        Config.Lock.position.z,
        Config.Lock.rotation.x,
        Config.Lock.rotation.y,
        Config.Lock.rotation.z,
        false,
        false,
        Config.Lock.collision,
        false,
        2,
        true
    )
end

ensureLock = function(runtime)
    if runtime.lock and DoesEntityExist(runtime.lock) then
        addOpenTarget(runtime)
        return true
    end

    if not runtime.lockModel or not DoesEntityExist(runtime.body) then
        return false
    end

    local bodyCoords = GetEntityCoords(runtime.body)
    runtime.lock = createLock(runtime.lockModel, bodyCoords)
    if not runtime.lock then
        return false
    end

    applyTextureVariation(runtime.lock, runtime.config.textureVariation)
    SetEntityNoCollisionEntity(runtime.lock, runtime.body, false)
    attachLock(runtime)
    addOpenTarget(runtime)

    return true
end

removeLock = function(runtime)
    removeOpenTarget(runtime)

    if runtime.lock and DoesEntityExist(runtime.lock) then
        DeleteEntity(runtime.lock)
    end

    runtime.lock = nil
end

playCutLockAnimation = function(runtime)
    if not Config.OpenAnimation.enabled then
        return true
    end

    local animation = Config.OpenAnimation.animation
    local animDict = animation.dict

    if not loadAnimDict(animDict) then
        notify('Không thể tải animation mở cửa.', 'error')
        return false
    end

    runtime.animationToken = runtime.animationToken + 1
    local token = runtime.animationToken
    runtime.busy = true

    local leftFrom = runtime.leftRotation or Config.Door.left.closedRotation
    local rightFrom = runtime.rightRotation or Config.Door.right.closedRotation
    local leftTo = Config.Door.left.openRotation
    local rightTo = Config.Door.right.openRotation

    -- Thread để mở cửa: delay 3s rồi mới mở
    CreateThread(function()
        Wait(Config.OpenAnimation.doorDelay)

        if runtime.animationToken ~= token then
            return
        end

        local doorStartedAt = GetGameTimer()
        local doorDuration = Config.OpenAnimation.doorAnimDuration

        while runtime.animationToken == token do
            local elapsed = GetGameTimer() - doorStartedAt
            local progress = math.min(elapsed / doorDuration, 1.0)
            local eased = smoothStep(progress)

            runtime.leftRotation = lerpVector3(leftFrom, leftTo, eased)
            runtime.rightRotation = lerpVector3(rightFrom, rightTo, eased)
            applyDoorPose(runtime, runtime.leftRotation, runtime.rightRotation)

            if progress >= 1.0 then
                break
            end

            Wait(0)
        end

        if runtime.animationToken ~= token then
            return
        end

        runtime.leftRotation = leftTo
        runtime.rightRotation = rightTo
        runtime.isOpen = true
        runtime.busy = false
        applyDoorPose(runtime, leftTo, rightTo)
    end)

    -- Chạy progressbar với animation (3.15s)
    local completed = lib.progressBar({
        duration = Config.OpenAnimation.duration,
        label = 'Đang mở container...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        },
        anim = {
            dict = animDict,
            clip = animation.pedClip,
            flag = 49
        }
    })

    local ped = PlayerPedId()
    ClearPedTasks(ped)

    return completed == true
end

isNearFront = function(runtime)
    if not DoesEntityExist(runtime.body) then
        return false
    end

    local pedCoords = GetEntityCoords(PlayerPedId())
    local frontCoords = GetOffsetFromEntityInWorldCoords(runtime.body, 0.0, -3.55, 0.8)
    local rearCoords = GetOffsetFromEntityInWorldCoords(runtime.body, 0.0, 3.55, 0.8)
    local maxDistance = Config.FrontInteractionDistance

    return #(pedCoords - frontCoords) <= maxDistance
        or #(pedCoords - rearCoords) <= maxDistance
end

isNearLock = function(runtime)
    if not runtime.lock or not DoesEntityExist(runtime.lock) then
        return false
    end

    local pedCoords = GetEntityCoords(PlayerPedId())
    local lockCoords = GetEntityCoords(runtime.lock)

    return #(pedCoords - lockCoords) <= Config.FrontInteractionDistance
end

local function spawnContainer(containerConfig, bodyModel, leftDoorModel, rightDoorModel, lockModel)
    if containers[containerConfig.id] then
        print(('[us_long_container] ID bị trùng: %s'):format(containerConfig.id))
        return
    end

    local coords = containerConfig.coords
    local body = CreateObjectNoOffset(bodyModel, coords.x, coords.y, coords.z, false, false, false)

    if body == 0 then
        print(('[us_long_container] Không thể tạo thân container: %s'):format(containerConfig.id))
        return
    end

    SetEntityAsMissionEntity(body, true, true)
    SetEntityHeading(body, coords.w)
    SetEntityInvincible(body, true)
    SetEntityCanBeDamaged(body, false)
    SetEntityCollision(body, true, true)
    SetEntityLodDist(body, Config.Door.lodDistance)

    if containerConfig.placeOnGround then
        Wait(0)
        PlaceObjectOnGroundProperly(body)
        Wait(0)
    end

    FreezeEntityPosition(body, true)

    local bodyCoords = GetEntityCoords(body)
    local leftDoor = createDoor(leftDoorModel, bodyCoords)
    local rightDoor = createDoor(rightDoorModel, bodyCoords)
    local lock = createLock(lockModel, bodyCoords)
    local rearLeftDoor
    local rearRightDoor

    if Config.Door.rear.enabled then
        rearLeftDoor = createDoor(leftDoorModel, bodyCoords)
        rearRightDoor = createDoor(rightDoorModel, bodyCoords)
    end

    if not leftDoor or not rightDoor or not lock or (Config.Door.rear.enabled and (not rearLeftDoor or not rearRightDoor)) then
        if leftDoor and DoesEntityExist(leftDoor) then DeleteEntity(leftDoor) end
        if rightDoor and DoesEntityExist(rightDoor) then DeleteEntity(rightDoor) end
        if lock and DoesEntityExist(lock) then DeleteEntity(lock) end
        if rearLeftDoor and DoesEntityExist(rearLeftDoor) then DeleteEntity(rearLeftDoor) end
        if rearRightDoor and DoesEntityExist(rearRightDoor) then DeleteEntity(rearRightDoor) end
        DeleteEntity(body)
        print(('[us_long_container] Không thể tạo đủ bộ cửa: %s'):format(containerConfig.id))
        return
    end

    SetEntityNoCollisionEntity(leftDoor, body, false)
    SetEntityNoCollisionEntity(rightDoor, body, false)
    SetEntityNoCollisionEntity(leftDoor, rightDoor, false)
    SetEntityNoCollisionEntity(lock, body, false)

    if Config.Door.rear.enabled then
        SetEntityNoCollisionEntity(rearLeftDoor, body, false)
        SetEntityNoCollisionEntity(rearRightDoor, body, false)
        SetEntityNoCollisionEntity(rearLeftDoor, rearRightDoor, false)

        attachDoor(
            rearLeftDoor,
            body,
            Config.Door.rear.left.position,
            Config.Door.rear.left.rotation
        )
        attachDoor(
            rearRightDoor,
            body,
            Config.Door.rear.right.position,
            Config.Door.rear.right.rotation
        )
    end

    applyTextureVariation(body, containerConfig.textureVariation)
    applyTextureVariation(leftDoor, containerConfig.textureVariation)
    applyTextureVariation(rightDoor, containerConfig.textureVariation)
    applyTextureVariation(lock, containerConfig.textureVariation)
    applyTextureVariation(rearLeftDoor, containerConfig.textureVariation)
    applyTextureVariation(rearRightDoor, containerConfig.textureVariation)

    local initialState = syncedStates[containerConfig.id]
    if initialState == nil then
        initialState = containerConfig.initiallyOpen == true
    end

    local runtime = {
        id = containerConfig.id,
        config = containerConfig,
        body = body,
        leftDoor = leftDoor,
        rightDoor = rightDoor,
        lock = lock,
        lockModel = lockModel,
        rearLeftDoor = rearLeftDoor,
        rearRightDoor = rearRightDoor,
        isOpen = initialState,
        busy = false,
        animationToken = 0,
        leftRotation = Config.Door.left.closedRotation,
        rightRotation = Config.Door.right.closedRotation
    }

    containers[containerConfig.id] = runtime
    attachLock(runtime)
    setImmediateState(runtime, initialState)
    addCloseTarget(runtime)
    if not initialState then
        addOpenTarget(runtime)
    end

    if Config.Debug then
        print(('[us_long_container] Đã tạo %s tại %.3f %.3f %.3f heading %.2f')
            :format(runtime.id, bodyCoords.x, bodyCoords.y, bodyCoords.z, coords.w))
    end
end

local function setupContainerPoints()
    if spawned then
        return
    end

    if Config.InvalidBodyModels and Config.InvalidBodyModels[Config.Models.body] then
        local message = ('Model %s có cửa liền khối; hãy dùng prop_container_03mb.'):format(Config.Models.body)
        print(('[us_long_container] %s'):format(message))
        notify(message, 'error')
        return
    end

    for index = 1, #Config.Containers do
        local containerConfig = Config.Containers[index]
        local coords = vec3(containerConfig.coords.x, containerConfig.coords.y, containerConfig.coords.z)

        points[containerConfig.id] = lib.points.new({
            coords = coords,
            distance = 150.0,
            onEnter = function(self)
                local id = containerConfig.id
                spawning[id] = true
                cancelSpawn[id] = nil

                CreateThread(function()
                    local bodyModel = loadModel(Config.Models.body)
                    if cancelSpawn[id] then spawning[id] = nil return end
                    local leftDoorModel = loadModel(Config.Models.leftDoor)
                    if cancelSpawn[id] then spawning[id] = nil return end
                    local rightDoorModel = loadModel(Config.Models.rightDoor)
                    if cancelSpawn[id] then spawning[id] = nil return end
                    local lockModel = loadModel(Config.Lock.model)
                    if cancelSpawn[id] then spawning[id] = nil return end

                    if not bodyModel or not leftDoorModel or not rightDoorModel or not lockModel then
                        notify('Không thể tải model container. Kiểm tra F8.', 'error')
                        spawning[id] = nil
                        return
                    end

                    if containerConfig.placeOnGround then
                        RequestCollisionAtCoord(containerConfig.coords.x, containerConfig.coords.y, containerConfig.coords.z)
                        local started = GetGameTimer()
                        while GetGameTimer() - started < 1000 do
                            if cancelSpawn[id] then
                                spawning[id] = nil
                                SetModelAsNoLongerNeeded(bodyModel)
                                SetModelAsNoLongerNeeded(leftDoorModel)
                                SetModelAsNoLongerNeeded(rightDoorModel)
                                SetModelAsNoLongerNeeded(lockModel)
                                return
                            end
                            if GetGroundZFor_3dCoord(containerConfig.coords.x, containerConfig.coords.y, containerConfig.coords.z, false) then
                                break
                            end
                            Wait(0)
                        end
                    end

                    if cancelSpawn[id] then
                        spawning[id] = nil
                        SetModelAsNoLongerNeeded(bodyModel)
                        SetModelAsNoLongerNeeded(leftDoorModel)
                        SetModelAsNoLongerNeeded(rightDoorModel)
                        SetModelAsNoLongerNeeded(lockModel)
                        return
                    end

                    spawnContainer(containerConfig, bodyModel, leftDoorModel, rightDoorModel, lockModel)
                    spawning[id] = nil

                    SetModelAsNoLongerNeeded(bodyModel)
                    SetModelAsNoLongerNeeded(leftDoorModel)
                    SetModelAsNoLongerNeeded(rightDoorModel)
                    SetModelAsNoLongerNeeded(lockModel)
                end)
            end,
            onExit = function(self)
                local id = containerConfig.id
                if spawning[id] then
                    cancelSpawn[id] = true
                end

                local runtime = containers[id]
                if runtime then
                    removeCloseTarget(runtime)
                    removeOpenTarget(runtime)

                    if DoesEntityExist(runtime.leftDoor) then
                        DeleteEntity(runtime.leftDoor)
                    end

                    if DoesEntityExist(runtime.rightDoor) then
                        DeleteEntity(runtime.rightDoor)
                    end

                    if runtime.lock and DoesEntityExist(runtime.lock) then
                        DeleteEntity(runtime.lock)
                    end

                    if runtime.rearLeftDoor and DoesEntityExist(runtime.rearLeftDoor) then
                        DeleteEntity(runtime.rearLeftDoor)
                    end

                    if runtime.rearRightDoor and DoesEntityExist(runtime.rearRightDoor) then
                        DeleteEntity(runtime.rearRightDoor)
                    end

                    if DoesEntityExist(runtime.body) then
                        DeleteEntity(runtime.body)
                    end

                    containers[id] = nil
                end
            end
        })
    end

    spawned = true
end

local function deleteAllContainers()
    for _, runtime in pairs(containers) do
        runtime.animationToken = runtime.animationToken + 1

        if DoesEntityExist(runtime.body) then
            removeCloseTarget(runtime)
        end

        removeOpenTarget(runtime)

        if DoesEntityExist(runtime.leftDoor) then
            DeleteEntity(runtime.leftDoor)
        end

        if DoesEntityExist(runtime.rightDoor) then
            DeleteEntity(runtime.rightDoor)
        end

        if runtime.lock and DoesEntityExist(runtime.lock) then
            DeleteEntity(runtime.lock)
        end

        if runtime.rearLeftDoor and DoesEntityExist(runtime.rearLeftDoor) then
            DeleteEntity(runtime.rearLeftDoor)
        end

        if runtime.rearRightDoor and DoesEntityExist(runtime.rearRightDoor) then
            DeleteEntity(runtime.rearRightDoor)
        end

        if DoesEntityExist(runtime.body) then
            DeleteEntity(runtime.body)
        end
    end

    for _, point in pairs(points) do
        point:remove()
    end

    containers = {}
    points = {}
    spawned = false
end

RegisterNetEvent('us_long_container:client:syncStates', function(states)
    syncedStates = states or {}

    if not spawned then
        setupContainerPoints()
        return
    end

    for id, isOpen in pairs(syncedStates) do
        local runtime = containers[id]
        if runtime then
            setImmediateState(runtime, isOpen == true)
        end
    end
end)

RegisterNetEvent('us_long_container:client:setState', function(containerId, isOpen)
    syncedStates[containerId] = isOpen == true

    local runtime = containers[containerId]
    if not runtime then
        return
    end

    if isOpen == true then
        removeLock(runtime)
    else
        ensureLock(runtime)
    end

    -- Nếu đang busy và trạng thái đã đúng, bỏ qua animation (tránh lặp lại)
    if runtime.busy then
        runtime.isOpen = isOpen == true
        return
    end

    animateState(runtime, isOpen == true)
end)

RegisterNetEvent('us_long_container:client:denied', function(message, containerId)
    if type(containerId) == 'string' then
        local runtime = containers[containerId]
        if runtime then
            runtime.busy = false
            if not runtime.isOpen then
                ensureLock(runtime)
            end
        end
    end

    notify(message or 'Không thể thao tác container.', 'error')
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent('us_long_container:server:requestSync')
end)

if Config.Debug then
    RegisterCommand('uscontainerpos', function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        print(('coords = vec4(%.4f, %.4f, %.4f, %.4f),')
            :format(coords.x, coords.y, coords.z, heading))
        notify('Đã in tọa độ container ra F8.', 'success')
    end, false)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    deleteAllContainers()
end)
