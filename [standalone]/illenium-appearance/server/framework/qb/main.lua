if not Framework.QBCore() then return end

local QBCore = exports["qb-core"]:GetCoreObject()

function Framework.GetPlayerID(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        return Player.PlayerData.citizenid
    end
end

function Framework.HasMoney(src, type, money)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player.PlayerData.money[type] >= money
end

function Framework.RemoveMoney(src, type, money)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player.Functions.RemoveMoney(type, money)
end

function Framework.GetJob(src)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player.PlayerData.job
end

function Framework.GetGang(src)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player.PlayerData.gang
end

local appearanceWrites = {}
function Framework.SaveAppearance(appearance, citizenID)
    if not citizenID or type(appearance) ~= 'table' or not appearance.model then return false end
    local previous, pending = appearanceWrites[citizenID], promise.new()
    appearanceWrites[citizenID] = pending
    if previous then Citizen.Await(previous) end
    local ok, result = pcall(function()
        return MySQL.transaction.await({
            { query = 'UPDATE playerskins SET active = ? WHERE citizenid = ?', values = { 0, citizenID } },
            { query = 'DELETE FROM playerskins WHERE citizenid = ? AND model = ?', values = { citizenID, appearance.model } },
            { query = 'INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, ?)',
                values = { citizenID, appearance.model, json.encode(appearance), 1 } }
        })
    end)
    if appearanceWrites[citizenID] == pending then appearanceWrites[citizenID] = nil end
    pending:resolve(true)
    if not ok or result ~= true then error(('Appearance save failed: %s'):format(tostring(result)), 0) end
    return true
end

function Framework.GetAppearance(citizenID, model)
    local result = Database.PlayerSkins.GetByCitizenID(citizenID, model)
    if result then
        return json.decode(result)
    end
end
