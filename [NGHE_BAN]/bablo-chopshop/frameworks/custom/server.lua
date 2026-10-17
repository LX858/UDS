Framework = Framework or {};

if Config.Framework ~= 'standalone' then
    return
end

function Framework:fetchPlayer(source)
    return source
end

function Framework:getMoney(source, moneyType)
    return 999999
end

function Framework:removeMoney(source, amount, moneyType)
    return true
end

function Framework:getIdentifier(source)
    return source and GetPlayerIdentifiers(source)[1]
end

function Framework:getPlayerName(source)
    return source and GetPlayerName(source) or "Unknown Player"
end

function Framework:getPoliceCount()
    return 0
end

RegisterServerCallback({
    eventName = eventName .. 'server:getIdentifier',
    eventCallback = function(source)
        if not source then
            return { status = false, message = "NO_SOURCE" }
        end

        return { status = true, identifier = Framework:getIdentifier(source) }
    end
})