Framework = Framework or {};

if Config.Framework ~= 'esx' then
    return
end

local ESX = nil

function Framework:getCore()
    if not ESX then
        ESX = exports['es_extended']:getSharedObject()
    end
    return ESX
end

function Framework:fetchPlayer(source)
    local core = self:getCore()
    return core and core.GetPlayerFromId(source)
end

function Framework:addMoney(source, amount)
    local player = self:fetchPlayer(source)
    if not player then return end

    player.addMoney(amount)
end

function Framework:getMoney(source, moneyType)
    local player = self:fetchPlayer(source)
    if not player then return 0 end
    moneyType = moneyType or 'cash'
    if moneyType == 'bank' then
        local account = player.getAccount and player.getAccount('bank')
        return account and account.money or 0
    else
        if player.getMoney then
            return player.getMoney() or 0
        else
            local account = player.getAccount and player.getAccount('money')
            return account and account.money or 0
        end
    end
end

function Framework:removeMoney(source, amount, moneyType)
    local player = self:fetchPlayer(source)
    if not player then return false end
    amount = tonumber(amount) or 0
    if amount <= 0 then return true end
    moneyType = moneyType or 'cash'

    local cash = self:getMoney(source, 'cash')
    if cash >= amount then
        if player.removeMoney then
            player.removeMoney(amount)
            return true
        elseif player.removeAccountMoney then
            player.removeAccountMoney('money', amount)
            return true
        end
    end

    local bank = self:getMoney(source, 'bank')
    if bank >= amount then
        if player.removeAccountMoney then
            player.removeAccountMoney('bank', amount)
            return true
        end
    end

    return false
end

function Framework:getIdentifier(src)
    local player = self:fetchPlayer(src)

    if not player then
        return nil
    end

    return player.identifier
end

function Framework:Notify(source, message)
    TriggerClientEvent('esx:showNotification', source, message)
end

function Framework:getTopPlayers()
    local result = MySQL.query.await([[
        SELECT
            u.identifier,
            u.xp,
            u.level,
            u.contracts_completed as finished_contracts,
            u.vehicles_chopped as chopped_vehicles,
            us.firstname,
            us.lastname
        FROM bablo_chop_shop_users u
        LEFT JOIN users us ON u.identifier = us.identifier
        ORDER BY u.xp DESC
        LIMIT 10
    ]])

    return result
end

function Framework:getPlayerName(source)
    source = tonumber(source)
    if not source then return "Unknown Player" end

    local player = self:fetchPlayer(source)
    if not player then return "Unknown Player" end

    if player.getName then
        return player.getName()
    end

    return "Unknown Player"
end

function Framework:getPoliceCount()
    local policeJobs = Config.PoliceJobs or { "police" }
    local policeCount = 0
    local core = self:getCore()

    if core and core.GetExtendedPlayers then
        for _, policeJob in pairs(policeJobs) do
            local xPlayers = core.GetExtendedPlayers('job', policeJob)
            policeCount = policeCount + (xPlayers and #xPlayers or 0)
        end
    elseif core and core.GetPlayers then
        local xPlayers = core.GetPlayers()
        for _, playerId in pairs(xPlayers) do
            local xPlayer = core.GetPlayerFromId(playerId)
            if xPlayer and xPlayer.job then
                for _, policeJob in pairs(policeJobs) do
                    if xPlayer.job.name == policeJob then
                        policeCount = policeCount + 1
                        break
                    end
                end
            end
        end
    end

    return policeCount
end