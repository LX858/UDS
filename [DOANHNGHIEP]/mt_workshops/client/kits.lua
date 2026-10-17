useRepairKit = function(action)
    local vehicle = getClosestVehicle()
    if not vehicle then notify(locale('notify_error_no_vehicle'), 'error') return end
    if action == 'engine' then
        loadAnimDict("rcmnigel3_trunk")
        TaskPlayAnim(cache.ped, "rcmnigel3_trunk", "out_trunk_trevor", 8.0, 8.0, 2000, 1, 0.0, false, false, false)
        Wait(2000)
        SetVehicleDoorOpen(vehicle, 4, true, true)
        if progressBar(locale('progress_repair_engine'), Config.times.repairEngine, { car = true, walk = true }, { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 6 }, { model = `w_me_wrench`, pos = vec3(0.071, -0.017, 0.036), rot = vec3(-121.24, -10.43, 6.64) }) then
            TriggerServerEvent('mt_workshops:server:fixVehicleEngine', VehToNet(vehicle), cache.serverId)
            lib.callback.await('mt_workshops:server:removeItem', false, 'engine_repair_kit', 1)
        end
        loadAnimDict("rcmepsilonism8")
        TaskPlayAnim(cache.ped, "rcmepsilonism8", "bag_handler_close_trunk_walk_left", 8.0, 8.0, 2500, 1, 0.0, false, false, false)
        Wait(2500)
        SetVehicleDoorShut(vehicle, 4, true)
    elseif action == 'body' then
        SetEntityHeading(cache.ped, GetEntityHeading(cache.ped)+180)
        if progressBar(locale('progress_repair_body'), Config.times.repairBody, { car = true, walk = true }, { dict = 'amb@world_human_vehicle_mechanic@male@base', clip = 'base', flag = 6 }, { model = `w_me_wrench`, pos = vec3(0.071, -0.017, 0.036), rot = vec3(-121.24, -10.43, 6.64) }) then
            TriggerServerEvent('mt_workshops:server:fixVehicleBody', VehToNet(vehicle), cache.serverId)
            lib.callback.await('mt_workshops:server:removeItem', false, 'body_repair_kit', 1)
        end
        local pCoords = GetEntityCoords(cache.ped)
        SetEntityCoords(cache.ped, pCoords.x, pCoords.y, pCoords.z+0.5, true, false, false, false)
        SetEntityHeading(cache.ped, GetEntityHeading(cache.ped)-180)
    end
end
lib.callback.register('mt_workshops:client:useRepairKit', useRepairKit)
exports('useRepairKit', useRepairKit)