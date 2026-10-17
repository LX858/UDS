openStation = function(id)
    local station = Config.stations[id]
    if not IsPedInAnyVehicle(cache.ped, false) then notify(locale('notify_error_no_vehicle_in'), 'error') return end
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    local mecsOn = lib.callback.await('mt_workshops:server:checkMecs', false)
    if (not station.checkMecs) or (station.checkMecs and mecsOn) then
        local averageHealth = math.ceil(((GetVehicleEngineHealth(vehicle) + GetVehicleBodyHealth(vehicle)) / 2) / 10)
        local price = math.ceil(station.price * (1 - (averageHealth / 100)))
        local alert = lib.alertDialog({ header = locale('alert_station_header'), content = locale('alert_station_text', price), centered = true, cancel = true })
        if alert == 'confirm' then
            local canRepair = lib.callback.await('mt_workshops:server:checkCanRepair', false, price)
            if canRepair then
                if progressBar(locale('progress_repair_station'), station.progress, { car = true, walk = true }, {}, {}) then
                    local petrolHealth = GetVehiclePetrolTankHealth(vehicle)
                    local currentFuel = GetVehicleFuelLevel(vehicle)
                    SetVehicleFixed(vehicle)
                    SetVehicleBodyHealth(vehicle, 1000.0)
                    SetVehicleEngineHealth(vehicle, 1000.0)
                    SetVehiclePetrolTankHealth(vehicle, petrolHealth)
                    --exports['cdn-fuel']:SetFuel(vehicle, currentFuel)
                    SetVehicleFuelLevel(vehicle, currentFuel)
                    lib.callback.await('mt_workshops:server:saveVehicleMods', false, vehicle, getVehicleMods(vehicle))
                    TriggerServerEvent('mt_workshops:server:payRepair', price, id)
                end
            else
                notify(locale('notify_no_money'), 'error')
            end
        end
    else
        notify(locale('notify_mecs_on'), 'error')
    end
end