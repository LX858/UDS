Framework = Framework or {};

CreateThread(function()
    local charLoaded = false

    if Config.Framework ~= 'qbcore' then
        return
    end

    function Framework:getCore()
        return exports['qb-core']:GetCoreObject();
    end

    local QBCore = Framework:getCore();

    function Framework:isCharacterLoaded()
        return charLoaded
    end

    function Framework:Notify(message)
        QBCore.Functions.Notify(message)
    end

    function Framework:doProgress(progress, cb)
        if lib.progressBar({
                duration = progress.time,
                label = progress.text,
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

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Citizen.Wait(1000)

        charLoaded = true
        TriggerEvent(eventName .. 'client:characterLoaded')
    end)

    local playerData = QBCore.Functions.GetPlayerData()
    if playerData and playerData.citizenid then
        charLoaded = true
        TriggerEvent(eventName .. 'client:characterLoaded')
    end
end)