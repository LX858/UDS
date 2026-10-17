openPerformanceMenu = function()
    if not insideZone[getPlayerJob()] then notify(locale('notify_error_inside_zone'), 'error') return end
    local vehicle = getClosestVehicle()
    if not vehicle then notify(locale('notify_error_no_vehicle'), 'error') return end
    local installedParts = {}
    for km, vm in pairs(Config.performance) do
        if (Config.useClasses and (getVehicleClass(vehicle) == vm.class)) or (not Config.useClasses) then
            SetVehicleModKit(vehicle, 0)
            if (GetNumVehicleMods(vehicle, vm.modType) > 0) or vm.modType == 18 then
                local modLevel = (vm.level == 'max') and (GetNumVehicleMods(vehicle, vm.modType) - 1) or vm.level
                if GetVehicleMod(vehicle, vm.modType) == modLevel or (vm.modType == 18 and IsToggleModOn(vehicle, 18)) then
                    local itemData = getItemData(vm.item)
                    installedParts[#installedParts + 1] = { item = vm.item, label = itemData and itemData.label or vm.item, mod = vm.modType }
                end
            end
        end
    end
    SendNUI('performanceMenu', { installedParts = installedParts, inventoryDirectory = Config.inventoryDirectory })
    ShowNUI('setVisiblePerformanceMenu', true)
end

lib.callback.register('mt_workshops:client:usePerformanceItem',  function(modType, item, level, class)
    if not insideZone[getPlayerJob()] then notify(locale('notify_error_inside_zone'), 'error') return end
    local vehicle = getClosestVehicle()
    if not vehicle then notify(locale('notify_error_no_vehicle'), 'error') return end
    SetVehicleModKit(vehicle, 0)
    if not ((Config.useClasses and (getVehicleClass(vehicle) == class)) or (not Config.useClasses)) then notify(locale('notify_error_wrong_class'), 'error') return end
    local modLevel = (level == 'max') and (GetNumVehicleMods(vehicle, modType) - 1) or level
    if not (modType == 18 or (modLevel <= (GetNumVehicleMods(vehicle, modType) - 1))) then notify(locale('notify_error_wrong_class'), 'error') return end
    loadAnimDict("rcmnigel3_trunk")
    TaskPlayAnim(cache.ped, "rcmnigel3_trunk", "out_trunk_trevor", 8.0, 8.0, 2000, 1, 0.0, 0, 0, 0)
    Wait(2000)
    SetVehicleDoorOpen(vehicle, 4, true, true)
    if progressBar(locale('progress_mod'), Config.times.installingMod, { car = true, walk = true }, { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 6 }, { model = `w_me_wrench`, pos = vec3(0.071, -0.017, 0.036), rot = vec3(-121.24, -10.43, 6.64) }) then
        TriggerServerEvent('mt_workshops:server:setVehicleMod', VehToNet(vehicle), modType, modLevel, cache.serverId, item)
        lib.callback.await('mt_workshops:server:removeItem', false, item, 1)
        notify(locale('notify_installed_mod'), 'success')
    end
    loadAnimDict("rcmepsilonism8")
    TaskPlayAnim(cache.ped, "rcmepsilonism8", "bag_handler_close_trunk_walk_left", 8.0, 8.0, 2500, 1, 0.0, 0, 0, 0)
    Wait(2500)
    SetVehicleDoorShut(vehicle, 4, true)
end)

RegisterNuiCallback('removePerformance', function(data, cb)
    ShowNUI('setVisiblePerformanceMenu', false)
    local vehicle = getClosestVehicle()
    if not vehicle then notify(locale('notify_error_no_vehicle'), 'error') cb(true) return end
    loadAnimDict("rcmnigel3_trunk")
    TaskPlayAnim(cache.ped, "rcmnigel3_trunk", "out_trunk_trevor", 8.0, 8.0, 2000, 1, 0.0, 0, 0, 0)
    Wait(2000)
    SetVehicleDoorOpen(vehicle, 4, true, true)
    if progressBar(locale('progress_remove_mod'), Config.times.removingMod, { car = true, walk = true }, { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 6 }, { model = `w_me_wrench`, pos = vec3(0.071, -0.017, 0.036), rot = vec3(-121.24, -10.43, 6.64) }) then
        TriggerServerEvent('mt_workshops:server:setVehicleMod', VehToNet(vehicle), data.mod, -1, cache.serverId)
        if Config.givePerformanceItems then
            Player(cache.serverId).state:set('workshopCurrentVehicle', VehToNet(vehicle), true)
            lib.callback.await('mt_workshops:server:addItem', false, data.item, 1)
            Player(cache.serverId).state:set('workshopCurrentVehicle', nil, true)
        end
    end
    loadAnimDict("rcmepsilonism8")
    TaskPlayAnim(cache.ped, "rcmepsilonism8", "bag_handler_close_trunk_walk_left", 8.0, 8.0, 2500, 1, 0.0, 0, 0, 0)
    Wait(2500)
    SetVehicleDoorShut(vehicle, 4, true)
    openPerformanceMenu()
    cb(true)
end)

RegisterNuiCallback('openCheckMaxPerformanceMenu', function(data, cb)
    local vehicle = getClosestVehicle()
    if not vehicle then notify(locale('notify_error_no_vehicle'), 'error') cb(true) return end
    loadAnimDict("rcmnigel3_trunk")
    TaskPlayAnim(cache.ped, "rcmnigel3_trunk", "out_trunk_trevor", 8.0, 8.0, 2000, 1, 0.0, 0, 0, 0)
    Wait(2000)
    SetVehicleDoorOpen(vehicle, 4, true, true)
    SetVehicleModKit(vehicle, 0)
    local dialog = lib.alertDialog({
        header = locale('alert_max_performance_header'),
        content = '**' .. locale('alert_engine') .. '**: ' .. GetNumVehicleMods(vehicle, 11) .. '     \n**' .. locale('alert_transmission') .. '**: ' .. GetNumVehicleMods(vehicle, 13) .. '     \n**' .. locale('alert_brake') .. '**: ' .. GetNumVehicleMods(vehicle, 12) .. '     \n**' .. locale('alert_suspension') .. '**: ' .. GetNumVehicleMods(vehicle, 15) .. '     \n**' .. locale('alert_armour') .. '**: ' .. GetNumVehicleMods(vehicle, 16),
        centered = true,
        cancel = false
    })
    if dialog then
        loadAnimDict("rcmepsilonism8")
        TaskPlayAnim(cache.ped, "rcmepsilonism8", "bag_handler_close_trunk_walk_left", 8.0, 8.0, 2500, 1, 0.0, 0, 0, 0)
        Wait(2500)
        SetVehicleDoorShut(vehicle, 4, true)
        cb(true)
    end
end)

RegisterNetEvent('mt_workshops:client:setVehicleMod', function(vehicle, modType, modLevel, player, itemUsed)
    if not NetworkDoesEntityExistWithNetworkId(vehicle) then return end
    local veh = NetToVeh(vehicle)
    if not DoesEntityExist(veh) then return end
    
    SetVehicleModKit(veh, 0)
    if modType == 18 then
        ToggleVehicleMod(veh, modType, (modLevel ~= -1) and true or false)
    else
        local numMods = GetNumVehicleMods(veh, modType)
        if modLevel == -1 or (numMods > 0 and modLevel < numMods) then
            SetVehicleMod(veh, modType, modLevel, false)
        end
    end
    if cache.serverId == player then
        local coords = GetEntityCoords(cache.ped)
        local heading = GetEntityHeading(cache.ped)
        -- Only log tuning (not removal when modLevel == -1)
        local isTuning = modLevel ~= -1
        if isTuning then
            lib.callback.await('mt_workshops:server:saveVehicleMods', false, veh, getVehicleMods(veh), true, { x = coords.x, y = coords.y, z = coords.z, w = heading }, 'Performance', itemUsed)
        else
            lib.callback.await('mt_workshops:server:saveVehicleMods', false, veh, getVehicleMods(veh), false, nil, nil, nil)
        end
    end
end)