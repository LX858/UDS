local config = require 'config'
lib.locale()

-- ▄█████ █████▄ ▄████▄ ██     ██ ███  ██ ██ ███  ██  ▄████  
-- ▀▀▀▄▄▄ ██▄▄█▀ ██▄▄██ ██ ▄█▄ ██ ██ ▀▄██ ██ ██ ▀▄██ ██  ▄▄▄ 
-- █████▀ ██     ██  ██  ▀██▀██▀  ██   ██ ██ ██   ██  ▀███▀                                                     

propCache    = {}
groupEnabled = {}
spawnedProps = {}
pendingSpawn = {}

--- Remove a spawned prop entity and clear it from all tracking tables.
--- @param  id  integer  Prop database ID
--- @return nil
function despawnProp(id)
    pendingSpawn[id] = nil
    local entity = spawnedProps[id]
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
    spawnedProps[id] = nil
end

--- Apply a full prop + group-state payload received from the server.
--- Updates propCache and groupEnabled, spawns/despawns entities as needed.
--- @param  payload { props: { id: integer, model: string, position: { x: number, y: number, z: number }, quaternion: { x: number, y: number, z: number, w: number }|nil, renderDistance: number|nil, group: string, expiresAt: integer|nil }[], groupStates: table<string, boolean>|nil }
--- @return nil
local function applySpawnPayload(payload)
    if payload.groupStates then
        for name, enabled in pairs(payload.groupStates) do
            groupEnabled[name] = enabled
        end
    end

    local newIds = {}
    for _, prop in ipairs(payload.props or {}) do
        newIds[prop.id] = true
        local existing = propCache[prop.id]
        propCache[prop.id] = {
            model          = prop.model,
            position       = prop.position,
            quaternion     = prop.quaternion,
            renderDistance = prop.renderDistance or 200,
            group          = prop.group,
            expiresAt      = prop.expiresAt,
        }
        -- Update coords of already-spawned entities in-place
        if existing and spawnedProps[prop.id] and DoesEntityExist(spawnedProps[prop.id]) then
            local e = spawnedProps[prop.id]
            local q = prop.quaternion or { x = 0, y = 0, z = 0, w = 1 }
            SetEntityCoords(e, prop.position.x, prop.position.y, prop.position.z, false, false, false, false)
            SetEntityQuaternion(e, q.x, q.y, q.z, q.w)
        end
    end

    for id in pairs(propCache) do
        if not newIds[id] then
            despawnProp(id)
            propCache[id] = nil
        end
    end

    print('Props loaded:', #payload.props)
end

-- ██████ ██  ██ █████▄  ██████ ▄████▄ ████▄  ▄█████ 
--   ██   ██████ ██▄▄██▄ ██▄▄   ██▄▄██ ██  ██ ▀▀▀▄▄▄ 
--   ██   ██  ██ ██   ██ ██▄▄▄▄ ██  ██ ████▀  █████▀ 

CreateThread(function()
    while true do
        Wait(1000)
        local playerPos = GetEntityCoords(PlayerPedId())

        for id, prop in pairs(propCache) do
            local dist        = #(vector3(prop.position.x, prop.position.y, prop.position.z) - playerPos)
            local shouldSpawn = dist <= (prop.renderDistance or 200) and (groupEnabled[prop.group] ~= false)

            if shouldSpawn and not spawnedProps[id] and not pendingSpawn[id] then
                pendingSpawn[id] = true
                local capturedId   = id
                local capturedProp = prop
                CreateThread(function()
                    local hash = GetHashKey(capturedProp.model)
                    RequestModel(hash)
                    local t = 0
                    while not HasModelLoaded(hash) and t < 100 do Wait(10); t = t + 1 end
                    if HasModelLoaded(hash) and propCache[capturedId] and pendingSpawn[capturedId] then
                        local q      = capturedProp.quaternion or { x = 0, y = 0, z = 0, w = 1 }
                        local entity = CreateObjectNoOffset(
                            hash,
                            capturedProp.position.x, capturedProp.position.y, capturedProp.position.z,
                            false, false, false
                        )
                        SetEntityQuaternion(entity, q.x, q.y, q.z, q.w)
                        FreezeEntityPosition(entity, true)
                        SetModelAsNoLongerNeeded(hash)
                        spawnedProps[capturedId] = entity
                    end
                    pendingSpawn[capturedId] = nil
                end)
            elseif not shouldSpawn and spawnedProps[id] then
                despawnProp(id)
            end
        end
    end
end)

-- ██  ██ ▄████▄ ███  ██ ████▄  ██     ██████ █████▄  ▄█████ 
-- ██████ ██▄▄██ ██ ▀▄██ ██  ██ ██     ██▄▄   ██▄▄██▄ ▀▀▀▄▄▄ 
-- ██  ██ ██  ██ ██   ██ ████▀  ██████ ██▄▄▄▄ ██   ██ █████▀ 

--- Wait for the server to be ready then fetch and apply the initial spawn payload.
--- @return nil
function RequestData()
    lib.print.info('Waiting for server...')
    while not GlobalState.arPropManagerReady do
        Wait(100)
    end
    lib.print.info('Server ready, requesting prop data...')
    lib.callback('ar_propmanager:getSpawnData', false, function(payload)
        if payload then applySpawnPayload(payload) end
    end)
end

if Framework then
    lib.print.info((string.format('Framework detected: %s', Framework.Name)))
    --- Called by the framework bridge when the local player logs in.
    --- @return nil
    function Framework.OnLoaded()
        RequestData()
    end
    --- Called by the framework bridge when the local player logs out.
    --- @return nil
    function Framework.OnUnloaded()
        for id, entity in pairs(spawnedProps) do
            if entity and DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
        end
    end
else
    lib.print.error('No framework detected, prop manager functionalities will not work properly.')
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if not Framework?.IsLoaded() then return end
    RequestData()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for id, entity in pairs(spawnedProps) do
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
end)



