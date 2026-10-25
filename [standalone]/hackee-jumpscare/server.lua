
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
