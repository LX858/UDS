Framework = Framework or {}

if Config.Framework ~= 'qbox' then
    return
end

local QBX = nil

function Framework:getCore()
    if not QBX then
        QBX = exports['qb-core']:GetCoreObject()
    end
    return QBX
end

function Framework:fetchPlayer(source)
    local core = self:getCore()
    return core and core.Functions.GetPlayer(source)
end

function Framework:addMoney(source, amount)
    local core = self:getCore()
    if not core then return end
    local player = core.Functions.GetPlayer(source)
    if not player then return end

    player.Functions.AddMoney('cash', amount)
end

function Framework:getMoney(source, moneyType)
    local player = self:fetchPlayer(source)
    if not player then return 0 end
    moneyType = moneyType or 'cash'
    if player.Functions and player.Functions.GetMoney then
        return player.Functions.GetMoney(moneyType) or 0
    elseif player.PlayerData and player.PlayerData.money then
        return player.PlayerData.money[moneyType] or 0
    end
    return 0
end

function Framework:removeMoney(source, amount, moneyType)
    local player = self:fetchPlayer(source)
    if not player then return false end
    amount = tonumber(amount) or 0
    if amount <= 0 then return true end
    moneyType = moneyType or 'cash'

    if player.Functions and player.Functions.GetMoney and player.Functions.RemoveMoney then
        local currentCash = player.Functions.GetMoney('cash') or 0
        if currentCash >= amount then
            return player.Functions.RemoveMoney('cash', amount, 'chopshop-contract')
        end

        local currentBank = player.Functions.GetMoney('bank') or 0
        if currentBank >= amount then
            return player.Functions.RemoveMoney('bank', amount, 'chopshop-contract')
        end
    end

    return false
end

function Framework:addStress(source, amount)
    local player = self:fetchPlayer(source)
    if not player then return end

    amount = tonumber(amount) or 1.0
    local currentStress = (player.PlayerData and player.PlayerData.metadata and player.PlayerData.metadata['stress']) or 0
    local newStress = math.min(100, currentStress + amount)

    if player.Functions and player.Functions.SetMetaData then
        player.Functions.SetMetaData('stress', newStress)
    end
end

function Framework:getIdentifier(src)
    local player = self:fetchPlayer(src)

    if not player then
        return nil
    end

    return player.PlayerData and player.PlayerData.citizenid
end

function Framework:Notify(source, message)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Notification',
        description = message,
        type = 'inform'
    })
end

function Framework:getTopPlayers()
    local result = MySQL.query.await([[
        SELECT
            u.identifier,
            u.xp,
            u.level,
            u.contracts_completed as finished_contracts,
            u.vehicles_chopped as chopped_vehicles,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) as firstname,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) as lastname
        FROM bablo_chop_shop_users u
        LEFT JOIN players p ON u.identifier = p.citizenid
        ORDER BY u.xp DESC
        LIMIT 10
    ]])

    return result
end

function Framework:getPlayerName(source)
    source = tonumber(source)
    if not source then
        return "Unknown Player"
    end

    local player = self:fetchPlayer(source)
    if not player then
        return "Unknown Player"
    end

    if not player.PlayerData or not player.PlayerData.charinfo then
        return "Unknown Player"
    end

    local firstName = player.PlayerData.charinfo.firstname
    local lastName = player.PlayerData.charinfo.lastname

    if firstName and lastName and firstName ~= '' and lastName ~= '' then
        return firstName .. ' ' .. lastName
    elseif firstName and firstName ~= '' then
        return firstName
    elseif lastName and lastName ~= '' then
        return lastName
    end

    return "Unknown Player"
end

function Framework:getPoliceCount()
    local policeJobs = Config.PoliceJobs or { "police" }
    local policeCount = 0
    local core = self:getCore()

    if core and core.Functions and core.Functions.GetPlayers then
        local players = core.Functions.GetPlayers()
        for _, playerId in pairs(players) do
            local player = core.Functions.GetPlayer(playerId)
            if player and player.PlayerData and player.PlayerData.job then
                for _, policeJob in pairs(policeJobs) do
                    if player.PlayerData.job.name == policeJob and player.PlayerData.job.onduty then
                        policeCount = policeCount + 1
                        break
                    end
                end
            end
        end
    elseif GetPlayers then
        for _, playerId in ipairs(GetPlayers()) do
            local player = self:fetchPlayer(playerId)
            if player and player.PlayerData and player.PlayerData.job then
                for _, policeJob in pairs(policeJobs) do
                    if player.PlayerData.job.name == policeJob and player.PlayerData.job.onduty then
                        policeCount = policeCount + 1
                        break
                    end
                end
            end
        end
    end

    return policeCount
end