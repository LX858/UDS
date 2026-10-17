local mission = nil
local inMission = false
local blip = nil
local ped = nil
local vehicle = nil
local currentJob = nil
local currentId = nil
local pedModel = nil

askMission = function(job, id)
    if lib.callback.await('mt_workshops:server:canStartMission', false, job) then notify(locale('notify_cooldown_error'), 'error') return end
    if progressBar(locale('progress_asking_mission'), Config.times.askMission, { car = true, move = true }, { dict = 'cellphone@', clip = 'cellphone_call_listen_base' }, { model = 'vw_prop_casino_phone_01b_handle', pos = vec3(-0.007, -0.01, -0.03), rot = vec3(-92.7, 28.22, -49.0), bone = 28422 }) then
        notify(locale('notify_started_mission'), 'success')
        lib.callback.await('mt_workshops:server:setCooldownState', false, job, id)
        inMission = true
        currentJob = job
        currentId = id
        mission = Config.missions[math.random(1, #Config.missions)]
        
        blip = createBlip(vec3(mission.ped.x, mission.ped.y, mission.ped.z), 409, 4, 0.6, 5, locale('blip_mission_customer'))
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, 5)

        pedModel = Config.missionsPeds[math.random(1, #Config.missionsPeds)]

        ped = createPed(mission.ped, pedModel, { dict = 'random@shop_tattoo', clip = '_idle_a' })
        local options = {
            {
                label = locale('target_take_order'),
                icon = 'fas fa-key',
                onSelect = function() takeOrder() end,
                action = function() takeOrder() end,
                canInteract = function()
                    return (getPlayerJob() == job and inMission and (not vehicle))
                end,
            }
        }
        createEntityTarget(ped, options, 2.5, 'mission_ped_'..job) 
    end
end

takeOrder = function()
    ClearPedTasks(ped)
    loadAnimDict('mp_common')
    TaskPlayAnim(ped, 'mp_common', 'givetake1_a', 8.0, 8.0, -1, 1, 0.0, false, false, false)
    TaskPlayAnim(cache.ped, 'mp_common', 'givetake1_b', 8.0, 8.0, -1, 1, 0.0, false, false, false)
    Wait(2500)
    ClearPedTasks(cache.ped)
    ClearPedTasks(ped)
    StopAnimTask(ped, 'mp_common', 'givetake1_a', 0.0)
    StopAnimTask(cache.ped, 'mp_common', 'givetake1_b', 0.0)
    RemoveAnimDict('mp_common')

    local model = Config.missionsVehicles[math.random(1, #Config.missionsVehicles)]
    vehicle = spawnVehicle(model, mission.car)

    local mods = {}
    SetVehicleModKit(vehicle, 0)
    for k, v in pairs(Config.cosmetics) do
        if not (v.value == 23 or v.value == 24 or v.value == 'windowTint' or v.value == 'plates' or v.value == 14) then
            if v.value == 'paints' then
                local categories = { "metalic", "matte", "metals", "chameleon" }
                local randomCategory = categories[math.random(#categories)]
                local randomList = Config.paints[randomCategory]
                local paint = randomList[math.random(#randomList)]         
                mods[#mods + 1] = {
                    isPaint = true,
                    id = Config.paintsCategory[1].value,
                    value = paint.value,
                    idLabel = Config.paintsCategory[1].label,
                    valueLabel = paint.label
                }
                mods[#mods + 1] = {
                    isPaint = true,
                    id = Config.paintsCategory[2].value,
                    value = paint.value,
                    idLabel = Config.paintsCategory[2].label,
                    valueLabel = paint.label
                }
                mods[#mods + 1] = {
                    isPaint = true,
                    id = Config.paintsCategory[3].value,
                    value = paint.value,
                    idLabel = Config.paintsCategory[3].label,
                    valueLabel = paint.label
                }
            else
                local numMods = GetNumVehicleMods(vehicle, v.value)
                if numMods > 0 then
                    local cMod = math.random(0, numMods - 1)
                    local modLabelText = GetModTextLabel(vehicle, v.value, cMod)
                    local modLabel = modLabelText and GetLabelText(modLabelText)
                    local label = (modLabel == "NULL" or modLabel == nil) and (locale('ui_custom') .. ' ' .. (cMod + 1)) or string.format("%s - %s", (cMod + 1), modLabel)
                    mods[#mods + 1] = {
                        id = v.value,
                        value = cMod,
                        idLabel = v.label,
                        valueLabel = label
                    }
                end
            end
        end
    end


    Player(cache.serverId).state:set('workshopCurrentVehicle', VehToNet(vehicle), true)
    lib.callback.await('mt_workshops:server:addItem', false, 'mods_list', 1, { plate = GetVehicleNumberPlateText(vehicle), isMission = true, modsList = mods })
    Player(cache.serverId).state:set('workshopCurrentVehicle', nil, true)

    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    TaskWanderStandard(ped, 10.0, 10)
    CreateThread(function()
        Wait(10000)
        DeletePed(ped)
        DeleteEntity(ped)
        ped = nil
    end)

    RemoveBlip(blip)
    local coords = Config.workshops[currentJob].mission[currentId].coords
    blip = createBlip(coords, 825, 4, 0.6, 5, locale('blip_mission_modify'))
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 5)
    notify(locale('notify_started_mission2'), 'success')
end

checkMissionModsFinished = function()
    local isAllDone = lib.callback.await('mt_workshops:server:checkAllMetadataItemIsDone', false, GetVehicleNumberPlateText(vehicle))

    if isAllDone then
        RemoveBlip(blip)
        blip = createBlip(vec3(mission.ped.x, mission.ped.y, mission.ped.z), 825, 4, 0.6, 5, locale('blip_mission_finish'))
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, 5)

        notify(locale('notify_started_mission3'), 'success')

        ped = createPed(mission.ped, pedModel, { dict = 'random@shop_tattoo', clip = '_idle_a' })
        local options = {
            {
                label = locale('target_finish_order'),
                icon = 'fas fa-dollar-sign',
                onSelect = function() finishOrder() end,
                action = function() finishOrder() end,
                canInteract = function()
                    return (getPlayerJob() == currentJob and inMission and vehicle)
                end,
            }
        }
        createEntityTarget(ped, options, 2.5, 'mission_ped_finish_'..currentJob) 
    end
end

finishOrder = function()
    removeVehicleKey(GetVehicleNumberPlateText(vehicle))
    DeleteVehicle(vehicle)
    DeleteEntity(vehicle)
    RemoveBlip(blip)
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    TaskWanderStandard(ped, 10.0, 10)
    CreateThread(function()
        Wait(10000)
        DeletePed(ped)
        DeleteEntity(ped)
        ped = nil
    end)
    lib.callback.await('mt_workshops:server:giveMissionPayment', false, Config.workshops[currentJob].mission[currentId])
    notify(locale('notify_finished_mission'), 'success')
    mission = nil
    inMission = false
    blip = nil
    vehicle = nil
    currentJob = nil
    currentId = nil
    pedModel = nil
end