Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'esx' then
        return
    end

    function Framework:getCore()
        return exports['es_extended']:getSharedObject();
    end

    local ESX = Framework:getCore();

    function Framework:isCharacterLoaded()
        return ESX.IsPlayerLoaded()
    end

    function Framework:Notify(message)
        ESX.ShowNotification(message)
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

    function Framework:canChopVehicle(vehicleEntity)
        -- add your own logic here if you want to restrict chopping of vehicles

        return true
    end

    function Framework:onVehicleChopped(vehicleEntity)
        -- add your own logic here if you want to do something when a vehicle has been chopped
    end

    RegisterNetEvent('esx:playerLoaded', function()
        Citizen.Wait(1000)

        TriggerEvent(eventName .. 'client:characterLoaded')
    end)
end)