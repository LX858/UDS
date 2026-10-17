local config = require 'config'

groups = {}

--- Return the named group, creating it if it does not exist.
--- @param  name     string        Group name
--- @param  enabled  boolean|nil   Initial enabled state (defaults to true when creating)
--- @return { enabled: boolean, props: table<integer, table> }
function getOrCreateGroup(name, enabled)
    if not groups[name] then
        groups[name] = { enabled = (enabled ~= false), props = {} }
    end
    return groups[name]
end

--- Return the permission level of a player based on their ACE flags.
--- 3 = admin, 2 = moderator, 1 = basic access, 0 = no access.
--- @param  source  integer  Player server ID
--- @return integer          Permission level (0–3)
function getPlayerLevel(source)
    if IsPlayerAceAllowed(source, config.ace[3]) then return 3 end
    if IsPlayerAceAllowed(source, config.ace[2]) then return 2 end
    if IsPlayerAceAllowed(source, config.ace[1]) then return 1 end
    return 0
end

--- Return the license identifier for a player.
--- @param  source  integer       Player server ID
--- @return string|nil            License string, or nil if not found
function getIdentifier(source)
    return GetPlayerIdentifierByType(source, 'license')
end

--- Test whether a 2-D point lies inside a polygon using ray-casting.
--- @param  px      number                          X coordinate of the test point
--- @param  py      number                          Y coordinate of the test point
--- @param  points  { x: number, y: number }[]      Polygon vertices
--- @return boolean                                 true if the point is inside the polygon
function pointInZone(px, py, points)
    if not points or #points < 3 then return false end
    local inside = false
    local j = #points
    for i = 1, #points do
        local xi, yi = points[i].x, points[i].y
        local xj, yj = points[j].x, points[j].y
        if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

--- Check whether a player is allowed to interact with props in the given group and position.
--- Level 2+ players always have access; level 0 players are checked against DB access records and optional zone restrictions.
--- @param  source    integer                                                    Player server ID
--- @param  group     string                                                     Group name to check against
--- @param  position  { x: number, y: number, z: number }|nil                   World position used for zone-based restriction checks
--- @return boolean                                                               true if the player has access
function hasPlayerAccess(source, group, position)
    if getPlayerLevel(source) >= 2 then return true end

    local identifier = getIdentifier(source)
    if not identifier then return false end

    local isNewGroup = groups[group] == nil
    local rows
    if isNewGroup then
        rows = MySQL.query.await(
            'SELECT * FROM `ar_props_player_access` WHERE identifier = ?',
            { identifier }
        )
    else
        rows = MySQL.query.await(
            'SELECT * FROM `ar_props_player_access` WHERE identifier = ? AND JSON_CONTAINS(`groups`, JSON_QUOTE(?))',
            { identifier, group }
        )
    end
    if not rows or #rows == 0 then return false end

    for _, row in ipairs(rows) do
        if not row.zones then return true end
        if not position then return true end

        local ok, zones = pcall(json.decode, row.zones)
        if not ok or not zones or #zones == 0 then return true end

        for _, zone in ipairs(zones) do
            if pointInZone(position.x, position.y, zone) then return true end
        end
    end
    return false
end

--- Check whether a player is allowed to use a specific group name when placing a prop.
--- Returns false only when the group already exists server-side and the player lacks access to it.
--- New group names are always permitted here; zone checks happen at save time via hasPlayerAccess.
--- @param  source  integer  Player server ID
--- @param  group   string   Group name the player wants to place into
--- @return boolean
lib.callback.register('ar_propmanager:canUseGroup', function(source, group)
    if getPlayerLevel(source) >= 2 then return true end
    if not groups[group] then return true end  -- new group, allow it

    local identifier = getIdentifier(source)
    if not identifier then return false end

    local rows = MySQL.query.await(
        'SELECT id FROM `ar_props_player_access` WHERE identifier = ? AND JSON_CONTAINS(`groups`, JSON_QUOTE(?))',
        { identifier, group }
    )
    return rows ~= nil and #rows > 0
end)

--- Build a flat map of every group name to its current enabled state.
--- @return table<string, boolean>
function buildGroupStates()
    local states = {}
    for name, group in pairs(groups) do
        states[name] = group.enabled
    end
    return states
end

--- Build a flat list of all props across every group, ready for client sync.
--- @return { id: integer, model: string, position: table, quaternion: table, group: string, outlined: boolean, renderDistance: number, expiresAt: integer|nil }[]
function buildPropList()
    local list = {}
    for groupName, group in pairs(groups) do
        for dbId, prop in pairs(group.props) do
            list[#list + 1] = {
                id             = dbId,
                model          = prop.model,
                position       = prop.position,
                quaternion     = prop.quat,
                group          = groupName,
                outlined       = false,
                renderDistance = prop.renderDistance or 200,
                expiresAt      = prop.expiresAt,
            }
        end
    end
    return list
end

--- Build the full sync payload sent to clients on connect.
--- @return { props: table[], groupStates: table<string, boolean> }
function buildSyncPayload()
    return { props = buildPropList(), groupStates = buildGroupStates() }
end

--- Build a single client-ready prop entry from internal server data.
--- @param  id         integer  Prop database ID
--- @param  prop       { model: string, position: table, quat: table, renderDistance: number, expiresAt: integer|nil }  Internal prop data
--- @param  groupName  string   Group the prop belongs to
--- @return { id: integer, model: string, position: table, quaternion: table, group: string, outlined: boolean, renderDistance: number, expiresAt: integer|nil }
function buildPropEntry(id, prop, groupName)
    return {
        id             = id,
        model          = prop.model,
        position       = prop.position,
        quaternion     = prop.quat,
        group          = groupName,
        outlined       = false,
        renderDistance = prop.renderDistance or 200,
        expiresAt      = prop.expiresAt,
    }
end

--- Broadcast a newly-added prop to all connected clients.
--- @param  id         integer  Prop database ID
--- @param  prop       table    Internal prop data
--- @param  groupName  string   Group the prop belongs to
--- @return nil
function broadcastPropAdded(id, prop, groupName)
    TriggerClientEvent('ar_propmanager:propAdded', -1, buildPropEntry(id, prop, groupName))
end

--- Broadcast an updated prop transform/metadata to all connected clients.
--- @param  id         integer  Prop database ID
--- @param  prop       table    Internal prop data
--- @param  groupName  string   Group the prop belongs to
--- @return nil
function broadcastPropUpdated(id, prop, groupName)
    TriggerClientEvent('ar_propmanager:propUpdated', -1, buildPropEntry(id, prop, groupName))
end

--- Broadcast a list of removed prop IDs to all connected clients.
--- @param  ids  integer[]  Database IDs of the props that were removed
--- @return nil
function broadcastPropsRemoved(ids)
    TriggerClientEvent('ar_propmanager:propsRemoved', -1, ids)
end

--- Broadcast the current enabled state of all groups to all connected clients.
--- @return nil
function broadcastGroupStates()
    TriggerClientEvent('ar_propmanager:groupStatesChanged', -1, buildGroupStates())
end

-- ████▄  ▄████▄ ██████ ▄████▄ █████▄ ▄████▄ ▄█████ ██████ 
-- ██  ██ ██▄▄██   ██   ██▄▄██ ██▄▄██ ██▄▄██ ▀▀▀▄▄▄ ██▄▄   
-- ████▀  ██  ██   ██   ██  ██ ██▄▄█▀ ██  ██ █████▀ ██▄▄▄▄ 

local function createTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ar_props` (
            `id`              INT         NOT NULL AUTO_INCREMENT,
            `model`           VARCHAR(64) NOT NULL,
            `pos_x`           FLOAT       NOT NULL,
            `pos_y`           FLOAT       NOT NULL,
            `pos_z`           FLOAT       NOT NULL,
            `quat_x`          FLOAT       NOT NULL DEFAULT 0,
            `quat_y`          FLOAT       NOT NULL DEFAULT 0,
            `quat_z`          FLOAT       NOT NULL DEFAULT 0,
            `quat_w`          FLOAT       NOT NULL DEFAULT 1,
            `group_name`      VARCHAR(64) NOT NULL,
            `render_distance` FLOAT       NOT NULL DEFAULT 200,
            `expires_at`      BIGINT      NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_group` (`group_name`)
        )
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ar_prop_groups` (
            `group_name` VARCHAR(64) NOT NULL,
            `enabled`    TINYINT     NOT NULL DEFAULT 1,
            PRIMARY KEY (`group_name`)
        )
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ar_props_player_access` (
            `id`         INT         NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(64) NOT NULL,
            `name`       VARCHAR(64) NOT NULL,
            `groups`     JSON        NOT NULL,
            `zones`      JSON        NULL,
            `max_expiry` BIGINT      NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_identifier` (`identifier`)
        )
    ]])
end

-- ██  ██ ▄████▄ ███  ██ ████▄  ██     ██████ █████▄  ▄█████ 
-- ██████ ██▄▄██ ██ ▀▄██ ██  ██ ██     ██▄▄   ██▄▄██▄ ▀▀▀▄▄▄ 
-- ██  ██ ██  ██ ██   ██ ████▀  ██████ ██▄▄▄▄ ██   ██ █████▀ 

local function loadData()
    local groupRows = MySQL.query.await('SELECT * FROM `ar_prop_groups`')
    for _, row in ipairs(groupRows or {}) do
        getOrCreateGroup(row.group_name, row.enabled == 1)
    end

    local propRows = MySQL.query.await('SELECT * FROM `ar_props`')
    for _, row in ipairs(propRows or {}) do
        local group = getOrCreateGroup(row.group_name)
        group.props[row.id] = {
            model          = row.model,
            position       = { x = row.pos_x, y = row.pos_y, z = row.pos_z },
            quat           = { x = row.quat_x, y = row.quat_y, z = row.quat_z, w = row.quat_w },
            renderDistance = row.render_distance or 200,
            expiresAt      = row.expires_at,
        }
    end

    print(string.format('^5Loaded %d prop(s)^7', #(propRows or {})))
end

MySQL.ready(function()
    createTables()
    CreateThread(function()
        Wait(200)
        loadData()
        GlobalState:set('arPropManagerReady', true, true)
    end)
end)

if Framework then
    print(string.format('^5Framework detected: %s^7', Framework.Name))
else
    print('^5No framework detected, prop manager functionalities will not work properly.^7')
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    GlobalState:set('arPropManagerReady', false, true)
end)
