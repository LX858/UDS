local QBCore = nil

if GetResourceState('qb-core') == 'started' then
    pcall(function()
        QBCore = exports['qb-core']:GetCoreObject()
    end)
end

-- Check if player is Admin
local function IsPlayerAdmin(source)
    if not source or source == 0 then return true end
    
    -- Check via qbx_core exports
    if GetResourceState('qbx_core') == 'started' and exports.qbx_core and exports.qbx_core.HasGroup then
        for group, _ in pairs(Config.AdminGroups) do
            if exports.qbx_core:HasGroup(source, group) then
                return true
            end
        end
    end

    -- Check via QBCore Player permission
    if QBCore and QBCore.Functions and QBCore.Functions.GetPlayer then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local permission = QBCore.Functions.GetPermission(source)
            if type(permission) == 'table' then
                for group, _ in pairs(Config.AdminGroups) do
                    if permission[group] then return true end
                end
            elseif type(permission) == 'string' and Config.AdminGroups[permission] then
                return true
            end
        end
    end

    -- ACE Permission Fallback
    if IsPlayerAceAllowed(source, 'command') or IsPlayerAceAllowed(source, 'admin') then
        return true
    end

    return false
end

-- Helper to Load Updates from MySQL or JSON
local function GetUpdatesFromStorage(cb)
    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:execute('SELECT * FROM xn_updates ORDER BY id DESC', {}, function(results)
            if results and #results > 0 then
                cb(results)
            else
                -- Fallback to default json if table is empty
                local fileData = LoadResourceFile(GetCurrentResourceName(), 'updates.json')
                if fileData then
                    cb(json.decode(fileData) or Config.DefaultUpdates)
                else
                    cb(Config.DefaultUpdates)
                end
            end
        end)
    else
        local fileData = LoadResourceFile(GetCurrentResourceName(), 'updates.json')
        if fileData then
            cb(json.decode(fileData) or Config.DefaultUpdates)
        else
            cb(Config.DefaultUpdates)
        end
    end
end

-- Helper to Save Updates to MySQL or JSON
local function SaveNewUpdate(updateData, cb)
    local currentDate = os.date("%d/%m/%Y")
    
    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:insert('INSERT INTO xn_updates (title, category, version, author, date, content) VALUES (?, ?, ?, ?, ?, ?)', {
            updateData.title,
            updateData.category,
            updateData.version,
            updateData.author,
            currentDate,
            updateData.content
        }, function(insertId)
            GetUpdatesFromStorage(cb)
        end)
    else
        local fileData = LoadResourceFile(GetCurrentResourceName(), 'updates.json')
        local list = fileData and json.decode(fileData) or {}
        local newId = #list + 1
        local newRecord = {
            id = newId,
            title = updateData.title,
            category = updateData.category,
            version = updateData.version,
            author = updateData.author,
            date = currentDate,
            content = updateData.content
        }
        table.insert(list, 1, newRecord)
        SaveResourceFile(GetCurrentResourceName(), 'updates.json', json.encode(list, { indent = true }), -1)
        cb(list)
    end
end

-- Helper to Delete Update
local function DeleteUpdateById(id, cb)
    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:execute('DELETE FROM xn_updates WHERE id = ?', { id }, function()
            GetUpdatesFromStorage(cb)
        end)
    else
        local fileData = LoadResourceFile(GetCurrentResourceName(), 'updates.json')
        local list = fileData and json.decode(fileData) or {}
        local newList = {}
        for _, item in ipairs(list) do
            if item.id ~= id then
                table.insert(newList, item)
            end
        end
        SaveResourceFile(GetCurrentResourceName(), 'updates.json', json.encode(newList, { indent = true }), -1)
        cb(newList)
    end
end

-- Register QBCore callback if QBCore exists
if QBCore and QBCore.Functions and QBCore.Functions.CreateCallback then
    QBCore.Functions.CreateCallback('xn_update:server:getUpdatesData', function(source, cb)
        local isAdmin = IsPlayerAdmin(source)
        GetUpdatesFromStorage(function(updates)
            cb(updates, isAdmin)
        end)
    end)
end

-- Net Event Callback Fallback
RegisterNetEvent('xn_update:server:getUpdatesData', function()
    local src = source
    local isAdmin = IsPlayerAdmin(src)
    GetUpdatesFromStorage(function(updates)
        TriggerClientEvent('xn_update:client:receiveUpdatesData', src, updates, isAdmin)
    end)
end)

-- Helper to Edit Existing Update
local function EditUpdateById(updateData, cb)
    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:execute('UPDATE xn_updates SET title = ?, category = ?, version = ?, content = ? WHERE id = ?', {
            updateData.title,
            updateData.category,
            updateData.version,
            updateData.content,
            updateData.id
        }, function()
            GetUpdatesFromStorage(cb)
        end)
    else
        local fileData = LoadResourceFile(GetCurrentResourceName(), 'updates.json')
        local list = fileData and json.decode(fileData) or {}
        for i, item in ipairs(list) do
            if item.id == updateData.id then
                list[i].title = updateData.title
                list[i].category = updateData.category
                list[i].version = updateData.version
                list[i].content = updateData.content
                break
            end
        end
        SaveResourceFile(GetCurrentResourceName(), 'updates.json', json.encode(list, { indent = true }), -1)
        cb(list)
    end
end

-- Server Event: Post Update (Admin Only)
RegisterNetEvent('xn_update:server:postUpdate', function(data)
    local src = source
    if not IsPlayerAdmin(src) then
        print(('[SECURITY] Player %s attempted to post update without admin permissions!'):format(src))
        return
    end

    local authorName = GetPlayerName(src) or "Admin"
    data.author = authorName

    SaveNewUpdate(data, function(updatedList)
        TriggerClientEvent('xn_update:client:refreshUpdates', -1, updatedList)
    end)
end)

-- Server Event: Edit Update (Admin Only)
RegisterNetEvent('xn_update:server:editUpdate', function(data)
    local src = source
    if not IsPlayerAdmin(src) then
        print(('[SECURITY] Player %s attempted to edit update without admin permissions!'):format(src))
        return
    end

    EditUpdateById(data, function(updatedList)
        TriggerClientEvent('xn_update:client:refreshUpdates', -1, updatedList)
    end)
end)

-- Server Event: Delete Update (Admin Only)
RegisterNetEvent('xn_update:server:deleteUpdate', function(id)
    local src = source
    if not IsPlayerAdmin(src) then
        print(('[SECURITY] Player %s attempted to delete update without admin permissions!'):format(src))
        return
    end

    DeleteUpdateById(id, function(updatedList)
        TriggerClientEvent('xn_update:client:refreshUpdates', -1, updatedList)
    end)
end)
