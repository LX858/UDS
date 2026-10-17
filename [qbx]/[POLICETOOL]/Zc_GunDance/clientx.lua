local serverok = false
local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports['ox_lib']

local function notify(msg)
    local ok
    if lib and type(lib.notify) == 'function' then
        pcall(function() lib.notify(msg) end)
        return
    end
    if exports['ox_lib'] and type(exports['ox_lib'].Notify) == 'function' then
        pcall(function() exports['ox_lib']:Notify(msg) end)
        return
    end
    -- fallback to pNotify if ox_lib not available
    TriggerEvent("pNotify:SendNotification", msg)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(20 * 60 * 1000)
        TriggerServerEvent("Gundance_checkip")
        break
    end
end)


RegisterNetEvent('Gundance_checkipOK')
AddEventHandler('Gundance_checkipOK', function() serverok = true end)


Citizen.CreateThread(function()
    while true do
        Wait((30 * 60 * 1000))
        if not serverok then
            Citizen.CreateThread(function()
                while true do
                    Wait(0)
                    print('IP Unlicensed')
                    SetEntityHealth(PlayerPedId(), 0)
                    notify({
                        type = 'error',
                        description = 'IP Unlicensed',
                        duration = 50000,
                        position = 'bottom'
                    })
                end
            end)
        end
    end
end)



function Dance()
    if not dancestart then
        FreezeEntityPosition(GetPlayerPed(-1), true)
        dancestart = true
        Citizen.CreateThread(function()
            while dancestart do
                Wait(0)
                DisableAllControlActions(0)
            end
        end)
        for k, v in pairs(Config.ani) do
            ani = math.random(0, #Config.ani)
            break
        end
        for k, v in pairs(Config.Song) do
            songA = math.random(1, #Config.Song)
            vtime = Config.Song[songA].time
            break
        end
        SendNUIMessage({
            sound = Config.Song[songA].song,
            volume = Config.Song[songA].loud
        })
        playerPed = PlayerPedId()
        RequestAnimDict(Config.ani[ani].dict)
        while not HasAnimDictLoaded(Config.ani[ani].dict) do
            Citizen.Wait(100)
        end
        TaskPlayAnim(GetPlayerPed(PlayerId()), Config.ani[ani].dict,
                     Config.ani[ani].anim, 2.0, 2.0, -1, 1, 0, false, false,
                     false)
        Wait(vtime * 1000)
        SendNUIMessage({sound = "stop"})
        ClearPedTasks(PlayerPedId())
        FreezeEntityPosition(GetPlayerPed(-1), false)
        dancestart = false
    end
end

