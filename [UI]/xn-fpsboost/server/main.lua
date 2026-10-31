---------------------------------------------------------------------
-- Client init
---------------------------------------------------------------------

RegisterNetEvent("oxlyn_fps:clientReady", function()
    local src = source

    Oxlyn.WaitForBridge(10000)

    TriggerClientEvent("oxlyn_fps:init", src, {
        isAdmin = Oxlyn.IsAdmin(src),
        lockedSettings = Config.Restrictions.lockedSettings or {},
        lockedPresets = Config.Restrictions.lockedPresets or {},
        maxPreset = Config.Restrictions.maxPreset,
        forceDefaultOnJoin = Config.Restrictions.forceDefaultOnJoin,
        defaultPreset = Config.DefaultPreset,
    })
end)

---------------------------------------------------------------------
-- Forcing presets (console / ACE-admin command and export)
-- src: player id of the caller, 0 = server console
-- target: player id, or "all" / -1
-- Returns true, message  or  false, error
---------------------------------------------------------------------

local function forcePreset(src, target, presetId)
    if src ~= 0 and not Oxlyn.IsAdmin(src) then
        return false, "sem permissao"
    end

    presetId = tostring(presetId or ""):lower()

    local exists = false
    for _, preset in ipairs(Config.Presets) do
        if preset.id == presetId then
            exists = true
            break
        end
    end

    if not exists then
        return false, ('preset "%s" nao existe'):format(presetId)
    end

    if target == "all" or target == -1 or target == "-1" then
        TriggerClientEvent("oxlyn_fps:forcePreset", -1, presetId, true)
        return true, ('preset "%s" aplicado a todos'):format(presetId)
    end

    local targetId = tonumber(target)
    if not (targetId and GetPlayerName(targetId)) then
        return false, ('jogador "%s" nao encontrado'):format(tostring(target))
    end

    TriggerClientEvent("oxlyn_fps:forcePreset", targetId, presetId, true)
    return true, ('preset "%s" aplicado a %s'):format(presetId, GetPlayerName(targetId))
end

RegisterCommand("fpsforce", function(src, args)
    if src > 0 and not Oxlyn.IsAdmin(src) then
        Oxlyn.NotifyServer(src, Oxlyn.L("notify_no_perm"))
        return
    end

    if not args[1] or not args[2] then
        local usage = "Uso: fpsforce <id | all> <preset>"
        if src == 0 then print(usage) else Oxlyn.NotifyServer(src, usage) end
        return
    end

    local ok, message = forcePreset(src, args[1], args[2])

    if src == 0 then
        print(("[oxlyn-fpsboost] %s%s"):format(ok and "" or "erro: ", message))
    else
        Oxlyn.NotifyServer(src, message)
    end
end, false)

exports("ForcePreset", function(target, presetId)
    return forcePreset(0, target, presetId)
end)
