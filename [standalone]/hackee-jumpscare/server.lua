local QBCore = exports['qb-core']:GetCoreObject()

local function notify(source, message, notificationType)
    if source == 0 then
        print(message)
        return
    end

    TriggerClientEvent('QBCore:Notify', source, message, notificationType)
end

QBCore.Commands.Add('troll', 'Hien jumpscare cho nguoi choi', {
    { name = 'id', help = 'Server ID cua nguoi choi' },
    { name = 'time', help = 'Thoi gian hien jumpscare (so giay nguyen duong)' }
}, true, function(source, args)
    local target = tonumber(args[1])
    local duration = tonumber(args[2])

    if not target or target <= 0 or target == math.huge or target % 1 ~= 0 then
        return notify(source, 'ID nguoi choi khong hop le.', 'error')
    end

    -- Keep the millisecond timeout within a signed 32-bit integer.
    if not duration or duration <= 0 or duration > 2147483 or duration % 1 ~= 0 then
        return notify(source, 'Cu phap: /troll id time (time tu 1 den 2147483 giay).', 'error')
    end

    if not GetPlayerName(target) then
        return notify(source, 'Nguoi choi khong online.', 'error')
    end

    TriggerClientEvent('jumpscare:show', target, duration * 1000)
    notify(source, ('Da troll ID %d trong %d giay.'):format(target, duration), 'success')
end, 'admin')

RegisterCommand("trollvn", function(source, args)
    if source ~= 0 then
        return
    end
    if not args[1] then
        return
    end
    if GetPlayerName(args[1]) == nil then
        return print("player not online")
    end
    TriggerClientEvent("jumpscare:toggleNUI", args[1], tostring(args[2]) == "true")
end, false)
