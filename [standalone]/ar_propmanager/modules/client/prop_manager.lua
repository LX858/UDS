
local outlinedProps = {}
local playerZones   = {}

--- Open the prop manager NUI window with the given data payload.
--- @param  payload { level: integer, props: table[], groupStates: table<string, boolean>, playerAccess: table[]|nil, groups: string[]|nil }
--- @return nil
function OpenPropManager(payload)
    payload.locales = BuildUILocales()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openPropManager', data = payload })
end

--- Close the prop manager NUI window and release NUI focus.
--- @return nil
local function ClosePropManager()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closePropManager', data = {} })
end

--- Build a NUI-ready prop entry from a client-side propCache entry.
--- @param  id    integer  Prop database ID
--- @param  prop  { model: string, position: { x: number, y: number, z: number }, quaternion: { x: number, y: number, z: number, w: number }|nil, group: string, renderDistance: number, expiresAt: integer|nil }
--- @return { id: integer, model: string, position: table, quaternion: table|nil, group: string, outlined: boolean, renderDistance: number, expiresAt: integer|nil }
local function buildPropEntryFromCache(id, prop)
    return {
        id             = id,
        model          = prop.model,
        position       = prop.position,
        quaternion     = prop.quaternion,
        group          = prop.group,
        outlined       = outlinedProps[id] == true,
        renderDistance = prop.renderDistance or 200,
        expiresAt      = prop.expiresAt,
    }
end

-- ███  ██ ██  ██ ██ 
-- ██ ▀▄██ ██  ██ ██ 
-- ██   ██ ▀████▀ ██ 

RegisterNUICallback('ClosePropManager', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('PlaceProp', function(data, cb)
    local model = data.model
    if not model or model == '' then cb('error') return end

    lib.callback('ar_propmanager:canUseGroup', false, function(canUse)
        if not canUse then
            cb({ error = 'group_exists_no_access' })
            return
        end

        local modelHash = GetHashKey(model)
        local success = pcall(function()
            lib.requestModel(model)
        end)
        if not success then
            cb({ error = 'invalid_model' })
            return
        end

        local ped     = PlayerPedId()
        local pos     = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        local prop = CreateObjectNoOffset(
            modelHash,
            pos.x + math.sin(math.rad(-heading)) * 3.0,
            pos.y + math.cos(math.rad(-heading)) * 3.0,
            pos.z,
            false, false, false
        )

        SetModelAsNoLongerNeeded(modelHash)
        FreezeEntityPosition(prop, true)
        SetEntityCollision(prop, false, false)

        local propMeta = {
            model          = model,
            group          = data.group or 'default',
            renderDistance = data.renderDistance or 200,
            expiresAt      = data.expiresAt,
        }

        ClosePropManager()
        OpenGizmo(prop, { zones = playerZones }, function(position, quaternion)
            TriggerServerEvent('ar_propmanager:saveProp', {
                model          = propMeta.model,
                position       = position,
                quaternion     = quaternion,
                group          = propMeta.group,
                renderDistance = propMeta.renderDistance,
                expiresAt      = propMeta.expiresAt,
            })
            if DoesEntityExist(prop) then DeleteEntity(prop) end
        end, function(e)
            if DoesEntityExist(e) then DeleteEntity(e) end
        end)

        cb('ok')
    end, data.group)
end)

RegisterNUICallback('EditProp', function(data, cb)
    lib.callback('ar_propmanager:canInteractWithProp', false, function(allowed)
        if not allowed then cb('denied') return end
        local id   = data.id
        local prop = propCache[id]
        if not prop then cb('error') return end

        local pos = prop.position
        if #(vector3(pos.x, pos.y, pos.z) - GetEntityCoords(PlayerPedId())) > 50.0 then
            cb('too_far')
            return
        end


        local editingProp = spawnedProps[id]
        if not editingProp or not DoesEntityExist(editingProp) then cb('error') return end

        local propMeta = {
            dbId           = id,
            model          = prop.model,
            group          = prop.group,
            renderDistance = prop.renderDistance or 200,
            expiresAt      = prop.expiresAt,
        }

        local origPos            = GetEntityCoords(editingProp)
        local oqx, oqy, oqz, oqw = GetEntityQuaternion(editingProp)

        SetEntityCollision(editingProp, false, false)

        ClosePropManager()
        OpenGizmo(editingProp, {}, function(position, quaternion)
            TriggerServerEvent('ar_propmanager:saveProp', {
                id             = propMeta.dbId,
                model          = propMeta.model,
                position       = position,
                quaternion     = quaternion,
                group          = propMeta.group,
                renderDistance = propMeta.renderDistance,
                expiresAt      = propMeta.expiresAt,
            })
        end, function(e)
            if DoesEntityExist(e) then
                SetEntityCoords(e, origPos.x, origPos.y, origPos.z, false, false, false, false)
                SetEntityQuaternion(e, oqx, oqy, oqz, oqw)
                FreezeEntityPosition(e, true)
                SetEntityCollision(e, true, true)
            end
        end)

        cb('ok')
    end, data.id)
end)

RegisterNUICallback('TeleportToProp', function(data, cb)
    lib.callback('ar_propmanager:canInteractWithProp', false, function(allowed)
        if not allowed then cb('denied') return end
        local prop = propCache[data.id]
        if not prop then cb('error') return end
        local pos = prop.position
        SetEntityCoords(PlayerPedId(), pos.x, pos.y, pos.z + 1.0, false, false, false, false)
        cb('ok')
    end, data.id)
end)

RegisterNUICallback('OutlineProp', function(data, cb)
    local id     = data.id
    local handle = spawnedProps[id]
    if not handle or not DoesEntityExist(handle) then cb('error') return end

    local enabled = not outlinedProps[id]
    SetEntityDrawOutline(handle, enabled)
    if enabled then SetEntityDrawOutlineColor(48, 111, 178, 255) end
    outlinedProps[id] = enabled or nil

    cb('ok')
end)

RegisterNUICallback('OutlineAllProps', function(data, cb)
    local enabled = data.outlined
    for id, handle in pairs(spawnedProps) do
        if DoesEntityExist(handle) then
            SetEntityDrawOutline(handle, enabled)
            if enabled then SetEntityDrawOutlineColor(48, 111, 178, 255) end
            outlinedProps[id] = enabled or nil
        end
    end
    cb('ok')
end)

RegisterNUICallback('DeleteProp', function(data, cb)
    TriggerServerEvent('ar_propmanager:deleteProp', { id = data.id })
    cb('ok')
end)

RegisterNUICallback('ToggleGroup', function(data, cb)
    TriggerServerEvent('ar_propmanager:toggleGroup', { group = data.group, enabled = data.enabled })
    cb('ok')
end)

RegisterNUICallback('GetPlayerPosition', function(_, cb)
    local pos = GetEntityCoords(PlayerPedId())
    cb({ x = pos.x, y = pos.y, z = pos.z })
end)

RegisterNUICallback('GetOnlinePlayers', function(_, cb)
    lib.callback('ar_propmanager:getOnlinePlayers', false, function(players)
        cb(players or {})
    end)
end)

RegisterNUICallback('AddPlayerAccess', function(data, cb)
    TriggerServerEvent('ar_propmanager:addPlayerAccess', data)
    cb('ok')
end)

RegisterNUICallback('UpdatePlayerAccess', function(data, cb)
    TriggerServerEvent('ar_propmanager:updatePlayerAccess', data)
    cb('ok')
end)

RegisterNUICallback('DeletePlayerAccess', function(data, cb)
    TriggerServerEvent('ar_propmanager:deletePlayerAccess', data.id)
    cb('ok')
end)

RegisterNUICallback('GetPropList', function(_, cb)
    cb(require 'config_prop')
end)

-- ██████ ██  ██ ██████ ███  ██ ██████ ▄█████ 
-- ██▄▄   ██▄▄██ ██▄▄   ██ ▀▄██   ██   ▀▀▀▄▄▄ 
-- ██▄▄▄▄  ▀██▀  ██▄▄▄▄ ██   ██   ██   █████▀ 

RegisterNetEvent('ar_propmanager:propAdded', function(prop)
    if groupEnabled[prop.group] == nil then groupEnabled[prop.group] = true end
    propCache[prop.id] = {
        model          = prop.model,
        position       = prop.position,
        quaternion     = prop.quaternion,
        renderDistance = prop.renderDistance or 200,
        group          = prop.group,
        expiresAt      = prop.expiresAt,
    }
    SendNUIMessage({ action = 'addProp', data = prop })
end)

RegisterNetEvent('ar_propmanager:propUpdated', function(prop)
    local cached = propCache[prop.id]
    propCache[prop.id] = {
        model          = prop.model,
        position       = prop.position,
        quaternion     = prop.quaternion,
        renderDistance = prop.renderDistance or 200,
        group          = prop.group,
        expiresAt      = prop.expiresAt,
    }
    if cached and spawnedProps[prop.id] and DoesEntityExist(spawnedProps[prop.id]) then
        local e = spawnedProps[prop.id]
        local q = prop.quaternion or { x = 0, y = 0, z = 0, w = 1 }
        SetEntityCoords(e, prop.position.x, prop.position.y, prop.position.z, false, false, false, false)
        SetEntityQuaternion(e, q.x, q.y, q.z, q.w)
    end
    SendNUIMessage({ action = 'updateProp', data = prop })
end)

RegisterNetEvent('ar_propmanager:propsRemoved', function(ids)
    for _, id in ipairs(ids) do
        despawnProp(id)
        propCache[id]    = nil
        outlinedProps[id] = nil
    end
    SendNUIMessage({ action = 'removeProps', data = { ids = ids } })
end)

RegisterNetEvent('ar_propmanager:groupStatesChanged', function(groupStates)
    for name, enabled in pairs(groupStates) do
        groupEnabled[name] = enabled
    end
    SendNUIMessage({ action = 'updateGroupStates', data = groupStates })
end)

RegisterNetEvent('ar_propmanager:openPropManager', function(openData)
    if not openData then return end

    local props       = {}
    local groupStates = {}

    if openData.level == 0 then
        local allowed = {}
        for _, entry in ipairs(openData.playerAccess or {}) do
            for _, g in ipairs(entry.groups or {}) do allowed[g] = true end
        end
        for id, prop in pairs(propCache) do
            if allowed[prop.group] then
                props[#props + 1]       = buildPropEntryFromCache(id, prop)
                groupStates[prop.group] = groupEnabled[prop.group]
            end
        end
    else
        for id, prop in pairs(propCache) do
            props[#props + 1] = buildPropEntryFromCache(id, prop)
        end
        for name, enabled in pairs(groupEnabled) do
            groupStates[name] = enabled
        end
    end

    if openData.level == 0 and openData.playerAccess and openData.playerAccess[1] then
        playerZones = openData.playerAccess[1].zones or {}
    else
        playerZones = {}
    end

    local payload = {
        level       = openData.level,
        props       = props,
        groupStates = groupStates,
    }
    if openData.playerAccess then payload.playerAccess = openData.playerAccess end
    if openData.groups       then payload.groups       = openData.groups end

    OpenPropManager(payload)
end)

RegisterNetEvent('ar_propmanager:playerAccessSaved', function(entry)
    SendNUIMessage({ action = 'playerAccessSaved', data = entry })
end)
