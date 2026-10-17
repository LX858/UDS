local config = require 'config'
lib.locale()

--- Enable or disable a prop group, persisting the change to the database and broadcasting to all clients.
--- No-ops if the group does not exist or the state is already set.
--- @param  groupName  string   Group name
--- @param  enabled    boolean  Desired enabled state
--- @return nil
function setGroupEnabled(groupName, enabled)
    local group = groups[groupName]
    if not group or group.enabled == enabled then return end

    group.enabled = enabled

    MySQL.query(
        'INSERT INTO `ar_prop_groups` (group_name, enabled) VALUES (?, ?) ON DUPLICATE KEY UPDATE enabled = ?',
        { groupName, enabled and 1 or 0, enabled and 1 or 0 }
    )

    broadcastGroupStates()
end

--- Remove a group from memory and the database if it has no remaining props.
--- @param  groupName  string  Group name to check and potentially remove
--- @return nil
local function pruneGroupIfEmpty(groupName)
    local group = groups[groupName]
    if not group then return end
    if next(group.props) ~= nil then return end
    groups[groupName] = nil
    MySQL.query('DELETE FROM `ar_prop_groups` WHERE group_name = ?', { groupName })
end

-- ██████ ██  ██ ██████ ███  ██ ██████ ▄█████ 
-- ██▄▄   ██▄▄██ ██▄▄   ██ ▀▄██   ██   ▀▀▀▄▄▄ 
-- ██▄▄▄▄  ▀██▀  ██▄▄▄▄ ██   ██   ██   █████▀ 

RegisterNetEvent('ar_propmanager:toggleGroup', function(data)
    local src = source
    if getPlayerLevel(src) < 1 then return end
    setGroupEnabled(data.group, data.enabled)
    CreateLog(src, locale('logs_toggle_group_title'), locale('logs_toggle_group_description'), {
        group   = data.group,
        enabled = data.enabled,
    })
end)

RegisterNetEvent('ar_propmanager:saveProp', function(data)

    local src  = source
    local pos  = data.position
    local quat = data.quaternion or { x = 0, y = 0, z = 0, w = 1 }

    if not hasPlayerAccess(src, data.group, pos) then
        return
    end

    if data.id then
        -- Update existing prop transform
        local group = groups[data.group]
        if not group then return end
        local propData = group.props[data.id]
        if not propData then return end

        propData.position       = pos
        propData.quat           = quat
        propData.renderDistance = data.renderDistance or propData.renderDistance or 200
        propData.expiresAt      = data.expiresAt

        MySQL.query(
            'UPDATE `ar_props` SET pos_x=?,pos_y=?,pos_z=?,quat_x=?,quat_y=?,quat_z=?,quat_w=?,render_distance=?,expires_at=? WHERE id=?',
            { pos.x, pos.y, pos.z, quat.x, quat.y, quat.z, quat.w, propData.renderDistance, propData.expiresAt, data.id }
        )
        broadcastPropUpdated(data.id, propData, data.group)
        CreateLog(src, locale('logs_update_prop_title'), locale('logs_update_prop_description'), {
            id     = data.id,
            model  = propData.model,
            coords = {
                x = tonumber(string.format('%.2f', pos.x)),
                y = tonumber(string.format('%.2f', pos.y)),
                z = tonumber(string.format('%.2f', pos.z)),
            },
            group      = data.group,
            expires_at = propData.expiresAt,
        })
    else
        -- New prop
        local group = getOrCreateGroup(data.group)

        local propData = {
            model          = data.model,
            position       = pos,
            quat           = quat,
            renderDistance = data.renderDistance or 200,
            expiresAt      = data.expiresAt,
        }

        MySQL.query(
            'INSERT IGNORE INTO `ar_prop_groups` (group_name, enabled) VALUES (?, 1)',
            { data.group }
        )
        local id = MySQL.insert.await(
            'INSERT INTO `ar_props` (model,pos_x,pos_y,pos_z,quat_x,quat_y,quat_z,quat_w,group_name,render_distance,expires_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)',
            { data.model, pos.x, pos.y, pos.z, quat.x, quat.y, quat.z, quat.w, data.group, propData.renderDistance, propData.expiresAt }
        )
        group.props[id] = propData
        broadcastPropAdded(id, propData, data.group)

        if getPlayerLevel(src) < 2 then
            local identifier = getIdentifier(src)
            if identifier then
                MySQL.query(
                    [[UPDATE `ar_props_player_access`
                      SET `groups` = JSON_ARRAY_APPEND(`groups`, '$', ?)
                      WHERE `identifier` = ? AND NOT JSON_CONTAINS(`groups`, JSON_QUOTE(?))
                    ]],
                    { data.group, identifier, data.group }
                )
            end
        end

        CreateLog(src, locale('logs_new_prop_title'), locale('logs_new_prop_description'), {
            id = id,
            model = data.model,
            coords = {
                x = tonumber(string.format("%.2f", pos.x)),
                y = tonumber(string.format("%.2f", pos.y)),
                z = tonumber(string.format("%.2f", pos.z))
            },
            group = data.group,
            render_distance = propData.renderDistance,
            expires_at = propData.expiresAt,
        })

    end
end)

RegisterNetEvent('ar_propmanager:deleteProp', function(data)
    local src = source

    local targetGroupName, propData
    for gName, group in pairs(groups) do
        if group.props[data.id] then
            targetGroupName = gName
            propData        = group.props[data.id]
            break
        end
    end
    if not propData then return end

    if not hasPlayerAccess(src, targetGroupName, propData.position) then
        return
    end

    groups[targetGroupName].props[data.id] = nil
    pruneGroupIfEmpty(targetGroupName)

    MySQL.query('DELETE FROM `ar_props` WHERE id = ?', { data.id })
    broadcastPropsRemoved({ data.id })

    CreateLog(src, locale('logs_delete_prop_title'), locale('logs_delete_prop_description'), {
        id    = data.id,
        model = propData.model,
        group = targetGroupName,
    })
end)

-- ▄█████ █████▄  ▄████▄ ███  ██ 
-- ██     ██▄▄██▄ ██  ██ ██ ▀▄██ 
-- ▀█████ ██   ██ ▀████▀ ██   ██ 

--- Delete any props whose expiresAt timestamp is in the past, broadcasting removals to all clients.
--- @return nil
local function checkExpiredProps()
    local now     = os.time()
    local expired = {}

    for groupName, group in pairs(groups) do
        for dbId, prop in pairs(group.props) do
            if prop.expiresAt and now >= prop.expiresAt then
                expired[#expired + 1] = { groupName = groupName, dbId = dbId, prop = prop }
            end
        end
    end

    if #expired == 0 then return end

    for _, entry in ipairs(expired) do
        groups[entry.groupName].props[entry.dbId] = nil
        pruneGroupIfEmpty(entry.groupName)
        CreateLog(0, locale('logs_expire_prop_title'), locale('logs_expire_prop_description'), {
            id    = entry.dbId,
            model = entry.prop.model,
            group = entry.groupName,
        })
    end

    local ids = {}
    for _, entry in ipairs(expired) do ids[#ids + 1] = entry.dbId end
    local placeholders = string.rep('?,', #ids):sub(1, -2)
    MySQL.query('DELETE FROM `ar_props` WHERE id IN (' .. placeholders .. ')', ids)

    broadcastPropsRemoved(ids)
end

lib.cron.new(config.expiryCron, checkExpiredProps)