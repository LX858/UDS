local containerConfigs = {}
local states = {}
local busyUntil = {}
local playerCooldowns = {}

local function buildContainerIndex()
    for index = 1, #Config.Containers do
        local container = Config.Containers[index]

        if type(container.id) ~= 'string' or container.id == '' then
            error(('[us_long_container] Container tại vị trí %s thiếu id hợp lệ.'):format(index))
        end

        if containerConfigs[container.id] then
            error(('[us_long_container] ID container bị trùng: %s'):format(container.id))
        end

        containerConfigs[container.id] = container
        states[container.id] = container.initiallyOpen == true
        busyUntil[container.id] = 0
    end
end

local function isPlayerNearContainer(source, container)
    local ped = GetPlayerPed(source)
    if ped == 0 then
        return false
    end

    local playerCoords = GetEntityCoords(ped)
    local heading = math.rad(container.coords.w)
    local localFrontY = -3.55
    local localRearY = 3.55

    local frontX = container.coords.x - (localFrontY * math.sin(heading))
    local frontY = container.coords.y + (localFrontY * math.cos(heading))
    local rearX = container.coords.x - (localRearY * math.sin(heading))
    local rearY = container.coords.y + (localRearY * math.cos(heading))

    local frontDeltaX = playerCoords.x - frontX
    local frontDeltaY = playerCoords.y - frontY
    local rearDeltaX = playerCoords.x - rearX
    local rearDeltaY = playerCoords.y - rearY
    local maxDistance = Config.ServerValidationDistance

    return math.sqrt((frontDeltaX * frontDeltaX) + (frontDeltaY * frontDeltaY)) <= maxDistance
        or math.sqrt((rearDeltaX * rearDeltaX) + (rearDeltaY * rearDeltaY)) <= maxDistance
end

local function deny(source, message, containerId)
    TriggerClientEvent('us_long_container:client:denied', source, message, containerId)
end

local function setContainerState(containerId, desiredState, skipBusyCheck)
    local container = containerConfigs[containerId]
    if not container or type(desiredState) ~= 'boolean' then
        return false, 'invalid_container'
    end

    local now = GetGameTimer()

    if not skipBusyCheck and now < (busyUntil[containerId] or 0) then
        return false, 'busy'
    end

    if states[containerId] == desiredState then
        return true, 'unchanged'
    end

    states[containerId] = desiredState
    busyUntil[containerId] = now + Config.AnimationDuration + 250
    TriggerClientEvent('us_long_container:client:setState', -1, containerId, desiredState)

    return true, 'changed'
end

RegisterNetEvent('us_long_container:server:requestSync', function()
    TriggerClientEvent('us_long_container:client:syncStates', source, states)
end)

RegisterNetEvent('us_long_container:server:requestState', function(containerId, desiredState)
    local source = source

    if type(containerId) ~= 'string' or type(desiredState) ~= 'boolean' then
        return
    end

    local container = containerConfigs[containerId]
    if not container then
        return
    end

    local now = GetGameTimer()
    if now < (playerCooldowns[source] or 0) then
        return
    end

    playerCooldowns[source] = now + Config.InteractionCooldown

    if not isPlayerNearContainer(source, container) then
        deny(source, 'Bạn đang ở quá xa container.', containerId)
        return
    end

    -- Kiểm tra item khi mở container
    local hasRequiredItem = false
    if desiredState == true and Config.RequireItem.enabled then
        local hasItem = exports.ox_inventory:Search(source, 'count', Config.RequireItem.itemName) > 0
        if not hasItem then
            deny(source, 'Bạn thiếu chìa khóa container.', containerId)
            return
        end
        hasRequiredItem = true
    end

    if not CanPlayerUseLongContainer(source, containerId, desiredState) then
        deny(source, 'Bạn không có quyền thao tác container này.', containerId)
        return
    end

    local success, reason = setContainerState(containerId, desiredState, false)

    if not success then
        if reason == 'busy' then
            deny(source, 'Cửa container đang chuyển động.', containerId)
        end
        return
    end

    -- Xóa item nếu cấu hình removeOnUse = true và mở container thành công (trạng thái thực sự thay đổi)
    if success and reason == 'changed' and hasRequiredItem and Config.RequireItem.removeOnUse then
        exports.ox_inventory:RemoveItem(source, Config.RequireItem.itemName, 1)
    end
end)

AddEventHandler('playerDropped', function()
    playerCooldowns[source] = nil
end)

-- Server export để resource khác điều khiển container.
-- exports.us_long_container:SetState('understar_container_01', true)
exports('SetState', function(containerId, desiredState)
    return setContainerState(containerId, desiredState == true, true)
end)

exports('GetState', function(containerId)
    return states[containerId]
end)

buildContainerIndex()
