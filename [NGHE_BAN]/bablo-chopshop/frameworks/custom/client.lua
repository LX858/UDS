Framework = Framework or {};

CreateThread(function()
    local identifier

    if Config.Framework ~= 'standalone' then
        return
    end

    function Framework:Notify(message)
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, true)
    end

    function Framework:doProgress(progess, cb)
        if lib.progressBar({
                duration = progess.time,
                label = progess.text,
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true,
                },
            }) then
            cb(true)
        else
            cb(false)
        end
    end

    -- Event when the player ped is loaded
    RegisterNetEvent('playerSpawned', function()
        Citizen.Wait(1000)

        local animationData, isNew = Main:getCache()

        if not isNew then
            Main:playAnimation(cache.ped, animationData.walkingstyle or nil, false, true)
            Main:playAnimation(cache.ped, animationData.expression or nil, false, true)
            Main:playAnimation(cache.ped, animationData.weaponstyle or nil, false, true)
        end
    end)
end)