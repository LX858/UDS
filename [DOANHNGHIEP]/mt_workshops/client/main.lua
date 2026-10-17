lib.locale()
zone = {}
insideZone = {}
local zonesInitialized = false

RegisterNetEvent('mt_workshops:client:notify', notify)

-- Hàm check và cập nhật zone status cho player
local function checkAndUpdateZoneStatus()
    -- Đợi PlayerData sẵn sàng
    local maxWait = 50 -- 5 giây
    local waited = 0
    while waited < maxWait do
        if Config.framework == 'qbx' then
            if QBX and QBX.PlayerData and QBX.PlayerData.job then
                break
            end
        elseif Config.framework == 'qb' then
            local PlayerData = Config.core.Functions.GetPlayerData()
            if PlayerData and PlayerData.job then
                break
            end
        else
            break
        end
        Wait(100)
        waited = waited + 1
    end
    
    local playerJob = getPlayerJob()
    if not playerJob then 
        if Config.debug then
            print('[MT_WORKSHOPS] checkAndUpdateZoneStatus: playerJob is nil, skipping')
        end
        return 
    end
    
    local playerCoords = GetEntityCoords(cache.ped)
    if Config.debug then
        print('[MT_WORKSHOPS] Checking zone status for job: ' .. playerJob .. ' at coords: ' .. tostring(playerCoords))
    end
    
    for k, v in pairs(Config.workshops) do
        if v.enabled and v.job == playerJob then
            if zone[k] then
                local isInside = zone[k]:contains(playerCoords)
                if Config.debug then
                    print('[MT_WORKSHOPS] Zone ' .. k .. ' exists, contains check: ' .. tostring(isInside))
                end
                if isInside then
                    insideZone[playerJob] = true
                    if Config.debug then
                        print('[MT_WORKSHOPS] Player spawned inside zone: ' .. k .. ', setting insideZone[' .. playerJob .. '] = true')
                    end
                    return -- Đã tìm thấy zone, không cần check thêm
                end
            else
                if Config.debug then
                    print('[MT_WORKSHOPS] Zone ' .. k .. ' does not exist yet!')
                end
            end
        end
    end
end

-- Check zone status sau khi player loaded VÀ zones đã được khởi tạo
CreateThread(function()
    -- Đợi player load xong
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end
    -- Đợi ped tồn tại
    while not cache.ped or not DoesEntityExist(cache.ped) do
        Wait(100)
    end
    -- Đợi zones được khởi tạo (quan trọng!)
    while not zonesInitialized do
        Wait(100)
    end
    Wait(1500) -- Đợi thêm 1.5 giây để đảm bảo hoàn toàn
    checkAndUpdateZoneStatus()
end)

-- Cũng check khi resource restart
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Đợi ped tồn tại
        while not cache.ped or not DoesEntityExist(cache.ped) do
            Wait(100)
        end
        -- Đợi zones được khởi tạo
        while not zonesInitialized do
            Wait(100)
        end
        Wait(1500)
        checkAndUpdateZoneStatus()
    end
end)

-- QBX: Check zone khi player data loaded
if Config.framework == 'qbx' then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        CreateThread(function()
            while not zonesInitialized do
                Wait(100)
            end
            Wait(1000)
            checkAndUpdateZoneStatus()
        end)
    end)
end

startScript = function()
    if Config.inventory == 'ox_inventory' then exports.ox_inventory:displayMetadata({ plate = locale('metadata_plate') }) end

    for k, v in pairs(Config.labelEntry) do
        AddTextEntry(v.hash, v.label)
    end

    for k, v in pairs(Config.stations) do
        if v.blip and v.blip.enabled then
            local blipCoords = (v.type == 'zone' and v.zone) and v.zone and v.zone.points[1] or (v.zone == 'prop' and v.prop) and vec3(v.prop.coords.x, v.prop.coords.y, v.prop.coords.z)
            createBlip(blipCoords, v.blip.sprite, v.blip.display, v.blip.scale, v.blip.color, v.label)
        end

        if v.type == 'zone' and v.zone then
            lib.zones.poly({
                points = v.zone.points,
                thickness = v.zone.thickness,
                debug = Config.debug,
                onEnter = function()
                    showTextUI(locale('textui_inside_station', v.label), "tools")
                end,
                onExit = function()
                    hideTextUI()
                end
            })
        elseif v.type == 'prop' and v.prop then
            createProp(v.prop.model, v.prop.coords, v.prop.coords.w)
            lib.zones.sphere({
                coords = vec3(v.prop.coords.x, v.prop.coords.y, v.prop.coords.z),
                radius = v.prop.radius,
                debug = Config.debug,
                onEnter = function()
                    showTextUI(locale('textui_inside_station', v.label), "tools")
                end,
                onExit = function()
                    hideTextUI()
                end
            })
        else
            --print(string.format("~r~The station (%s) %s is with the wrong type or mission prop or zone field!!", k, v.label))
        end
    end

    for k, v in pairs(Config.workshops) do
        if v.enabled then
            if v.blip and v.blip.enabled then
                createBlip(v.blip.coords, v.blip.sprite, v.blip.display, v.blip.scale, v.blip.color, v.label)
            end

            zone[k] = lib.zones.poly({
                points = v.zone.points,
                thickness = v.zone.thickness,
                debug = Config.debug,
                onEnter = function()
                    onZoneEnter(v.job)
                end,
                onExit = function()
                    onZoneExit(v.job) 
                end,
            })
            
            -- Check ngay sau khi tạo zone xem player có đang ở trong không
            if cache.ped and DoesEntityExist(cache.ped) then
                local playerCoords = GetEntityCoords(cache.ped)
                if zone[k]:contains(playerCoords) then
                    local playerJob = getPlayerJob()
                    if playerJob then
                        insideZone[playerJob] = true
                    end
                    insideZone[v.job] = true
                    if Config.debug then
                        print('[MT_WORKSHOPS] Player already inside zone ' .. k .. ' on creation, setting insideZone[' .. v.job .. '] = true')
                    end
                end
            end

            if v.managements then
                for mk, mv in pairs(v.managements) do
                    createSphereZoneTarget(mv.coords, mv.radius, {
                        {
                            debug = Config.debug,
                            label = locale("target_management"),
                            icon = "fas fa-user-tie",
                            onSelect = managementMenu,
                            action = managementMenu,
                            canInteract = function()
                                return (getPlayerJob() == v.job and isPlayerJobBoss())
                            end
                        }
                    }, 2.5, string.format("management_%s_%s", k, mk))
                end
            end

            if v.duty then
                for dk, dv in pairs(v.duty) do
                    local jobName = v.job
                    createSphereZoneTarget(dv.coords, dv.radius, {
                        {
                            debug = Config.debug,
                            label = locale("target_duty_on"),
                            icon = "fas fa-clock",
                            onSelect = function()
                                TriggerServerEvent("QBCore:ToggleDuty")
                                notify(locale('notify_duty_on'), 'success')
                            end,
                            action = function()
                                TriggerServerEvent("QBCore:ToggleDuty")
                                notify(locale('notify_duty_on'), 'success')
                            end,
                            canInteract = function()
                                return (getPlayerJob() == jobName and not isPlayerOnDuty())
                            end
                        },
                        {
                            debug = Config.debug,
                            label = locale("target_duty_off"),
                            icon = "fas fa-clock",
                            onSelect = function()
                                TriggerServerEvent("QBCore:ToggleDuty")
                                notify(locale('notify_duty_off'), 'success')
                            end,
                            action = function()
                                TriggerServerEvent("QBCore:ToggleDuty")
                                notify(locale('notify_duty_off'), 'success')
                            end,
                            canInteract = function()
                                return (getPlayerJob() == jobName and isPlayerOnDuty())
                            end
                        }
                    }, 2.5, string.format("duty_%s_%s", k, dk))
                end
            end

            if v.stashes then
                for sk, sv in pairs(v.stashes) do
                    createSphereZoneTarget(sv.coords, sv.radius, {
                        {
                            debug = Config.debug,
                            label = locale("target_stash"),
                            icon = "fas fa-cube",
                            onSelect = function()
                                openStash(("stash_%s_%s"):format(k, sk), locale("stash_label"), sv.slots, sv.weight)
                            end,
                            action = function()
                                openStash(("stash_%s_%s"):format(k, sk), locale("stash_label"), sv.slots, sv.weight)
                            end,
                            canInteract = function()
                                return true
                            end
                        }
                    }, 2.5, string.format("stash_%s_%s", k, sk))
                end
            end

            if v.shops then
                for sk, sv in pairs(v.shops) do
                    local options = {}
                    for ck, cv in pairs(sv.categories) do
                        options[#options + 1] = {
                            debug = Config.debug,
                            label = locale("target_shop", Config.shops[cv].categoryLabel),
                            icon = "fas fa-shopping-cart",
                            onSelect = function()
                                openShop(("shop_%s_%s_%s"):format(k, sk, cv), locale("shop_label", Config.shops[cv].categoryLabel), Config.shops[cv].items)
                            end,
                            action = function()
                                openShop(("shop_%s_%s_%s"):format(k, sk, cv), locale("shop_label", Config.shops[cv].categoryLabel), Config.shops[cv].items)
                            end,
                            canInteract = function()
                                return true
                            end
                        }
                    end
                    createSphereZoneTarget(sv.coords, sv.radius, options, 2.5, string.format("shop_%s_%s", k, sk))
                end
            end

            if v.crafts then
                for ck, cv in pairs(v.crafts) do
                    local options = {}
                    for cck, ccv in pairs(cv.categories) do
                        options[#options + 1] = {
                            debug = Config.debug,
                            label = locale("target_craft", Config.crafts[ccv].categoryLabel),
                            icon = "fas fa-tools",
                            onSelect = function()
                                openCraft(("craft_%s_%s"):format(k, ck), locale("craft_label", Config.crafts[ccv].categoryLabel), Config.crafts[ccv].items)
                            end,
                            action = function()
                                openCraft(("craft_%s_%s"):format(k, ck), locale("craft_label", Config.crafts[ccv].categoryLabel), Config.crafts[ccv].items)
                            end,
                            canInteract = function()
                                return true
                            end
                        }
                    end
                    createSphereZoneTarget(cv.coords, cv.radius, options, 2.5, string.format("craft_%s_%s", k, ck))
                end
            end

            if v.garage then
                for a, b in pairs(v.garage) do
                    local jobName = v.job
                    local garageIndex = a
                    local options = {
                        {
                            distance = 3.5,
                            label = locale('target_garage'),
                            icon = 'fas fa-car',
                            onSelect = function() openGarage(jobName, garageIndex) end,
                            action = function() openGarage(jobName, garageIndex) end,
                            canInteract = function()
                                local hasJob = getPlayerJob() == jobName
                                local onDuty = isPlayerOnDuty()
                                if Config.debug then
                                    print(('[MT_WORKSHOPS] Garage canInteract - Job: %s, HasJob: %s, OnDuty: %s'):format(jobName, tostring(hasJob), tostring(onDuty)))
                                end
                                return hasJob and onDuty
                            end,
                        }
                    }
                    -- Tạo prop garage
                    local modelHash = GetHashKey('prop_park_ticket_01')
                    if loadModel(modelHash) then
                        local garageProp = CreateObject(modelHash, b.coords.x, b.coords.y, b.coords.z, false, false, false)
                        if DoesEntityExist(garageProp) then
                            SetEntityHeading(garageProp, b.coords.w)
                            FreezeEntityPosition(garageProp, true)
                            SetEntityCollision(garageProp, true, true)
                            SetModelAsNoLongerNeeded(modelHash)
                            spawnedWorkshopProps[#spawnedWorkshopProps + 1] = garageProp
                            -- Sử dụng sphere zone target thay vì entity target để ổn định hơn
                            createSphereZoneTarget(vec3(b.coords.x, b.coords.y, b.coords.z), 1.0, options, 2.5, 'garage_shop_'..jobName..'_'..garageIndex)
                            if Config.debug then
                                print(('[MT_WORKSHOPS] Created garage prop and target at: %s for job: %s'):format(tostring(b.coords), jobName))
                            end
                        else
                            print(('[MT_WORKSHOPS] ERROR: Failed to create garage prop at: %s'):format(tostring(b.coords)))
                        end
                    end
                end
            end

            if v.registers then
                for a, b in pairs(v.registers) do
                    local options = {
                        {
                            distance = 2.5,
                            label = locale('target_register'),
                            icon = 'fas fa-cash-register',
                            onSelect = function() openRegister(v.job, a) end,
                            action = function() openRegister(v.job, a) end,
                            canInteract = function()
                                return (getPlayerJob() == v.job)
                            end,
                        }
                    }
                    createSphereZoneTarget(b.coords, b.radius, options, 2.5, 'register_target_'..k..'_'..a)

                    if b.prop then
                        createProp(b.prop, b.coords, b.propHeading or 0.0)
                    end
                end
            end

            if v.mission then
                for a, b in pairs(v.mission) do
                    local options = {
                        {
                            distance = 2.5,
                            label = locale('target_ask_mission'),
                            icon = 'fas fa-phone',
                            onSelect = function() askMission(v.job, a) end,
                            action = function() askMission(v.job, a) end,
                            canInteract = function()
                                return (getPlayerJob() == v.job)
                            end,
                        }
                    }
                    createSphereZoneTarget(b.coords, b.radius, options, 2.5, 'mission_target_'..k..'_'..a)

                    if b.prop then
                        createProp(b.prop, b.coords, b.propHeading or 0.0)
                    end
                end
            end
        end
    end
    
    -- Đánh dấu zones đã được khởi tạo hoàn tất
    zonesInitialized = true
    if Config.debug then
        print('[MT_WORKSHOPS] All zones initialized')
    end
end

RegisterNuiCallback('hideFrame', function(data, cb)
    ShowNUI(data.name, false)
    
    if data.name == 'setVisiblePreviewMenu' then
        if exports['mt_workshops']:isInPreview() then
            exports['mt_workshops']:cleanupPreview()
        end
    end
    
    -- Xóa toolbox prop khi đóng repair menu
    if data.name == 'setVisibleRepairMenu' then
        if toolboxProp and DoesEntityExist(toolboxProp) then
            DeleteEntity(toolboxProp)
            toolboxProp = nil
        end
        exports['mt_workshops']:closeToolboxMenu()
    end
    
    cb(true)
end)

ShowNUI = function(action, shouldShow)
    SetNuiFocus(shouldShow, shouldShow)
    SendNUIMessage({ action = action, data = shouldShow })
end
  
SendNUI = function(action, data)
    data.locale = json.decode(LoadResourceFile(cache.resource, ('locales/%s.json'):format(Config.locale or 'en')))
    SendNUIMessage({ action = action, data = data })
end

RegisterNuiCallback('craftItem', function(data, cb)
    local canCraft = lib.callback.await('mt_workshops:server:canCraftItem', false, data.ingredients)
    if not canCraft then notify(locale('notify_error_missing_items'), 'error') return end
    ShowNUI('setVisibleCraftingMenu', false)
    if progressBar(locale('progress_craft'), data.duration, { car = true, walk = true }, { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 6 }, {}) then
        lib.callback.await('mt_workshops:server:craftItem', false, data.name, data.count, data.ingredients)
    end
    openCraft(data.id, data.craftLabel, data.oldItems)
    cb(true)
end)

RegisterNetEvent('mt_workshops:client:checkVehicleClass', function()
    if not IsPedInAnyVehicle(cache.ped, false) then notify(locale('notify_error_no_vehicle_in'), 'error') return end
    notify(locale('notify_check_class', getVehicleClass(GetVehiclePedIsIn(cache.ped, false))))
end)

-- Update zone status when job changes
if Config.framework == 'qbx' then
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
        local newJob = JobInfo.name
        -- Check if player is currently inside any workshop zone
        for k, v in pairs(Config.workshops) do
            if v.enabled and zone[k] then
                if zone[k]:contains(GetEntityCoords(cache.ped)) then
                    if newJob == v.job then
                        insideZone[newJob] = true
                    end
                end
            end
        end
    end)
elseif Config.framework == 'qb' then
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
        local newJob = JobInfo.name
        for k, v in pairs(Config.workshops) do
            if v.enabled and zone[k] then
                if zone[k]:contains(GetEntityCoords(cache.ped)) then
                    if newJob == v.job then
                        insideZone[newJob] = true
                    end
                end
            end
        end
    end)
end

CreateThread(startScript)