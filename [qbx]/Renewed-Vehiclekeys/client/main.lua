local GetEntityCoords = GetEntityCoords
local GetEntityPlayerIsFreeAimingAt = GetEntityPlayerIsFreeAimingAt
local GetEntitySpeed = GetEntitySpeed
local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetVehiclePedIsTryingToEnter = GetVehiclePedIsTryingToEnter
local GetSeatPedIsTryingToEnter = GetSeatPedIsTryingToEnter
local GetVehicleDoorsLockedForPlayer = GetVehicleDoorsLockedForPlayer
local GetPedInVehicleSeat = GetPedInVehicleSeat
local SetVehicleDoorsLockedForPlayer = SetVehicleDoorsLockedForPlayer
local IsEntityDead = IsEntityDead
local IsPedAPlayer = IsPedAPlayer
local GetVehicleDoorLockStatus = GetVehicleDoorLockStatus
local IsControlJustPressed = IsControlJustPressed
local GetVehicleNumberPlateText = GetVehicleNumberPlateText
local GetEntityModel = GetEntityModel
local GetIsVehicleEngineRunning = GetIsVehicleEngineRunning
local SetTimeout = SetTimeout
local GetVehicleClass = GetVehicleClass
local Wait = Wait
-- Natives Dump --

lib.locale()


local utils = require 'utils.client'
local data = require 'data'
local doorsBlocked = data.doorsBlocked
local progressBar = data.circleProgress and lib.progressCircle or lib.progressBar

local animDict, anim = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer'
local huDict, huAnim = 'missminuteman_1ig_2', 'handsup_base'
local lockpickDic, lockpickAnim = 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds'

local hasCurrentKey = false
local foundCar = 0
local playerId = cache.playerId

-- Bug Fix: dùng version counter để kill duplicate idle/veh loops khi đổi bucket
local idleLoopVersion = 0
local vehLoopVersion = 0

local function getClosestVehicle(coords, maxDist)
    local vehicles = GetGamePool('CVehicle')
    local closestVehicle = nil
    local closestDist = maxDist or 15.0
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if DoesEntityExist(vehicle) then
            local dist = #(coords - GetEntityCoords(vehicle))
            if dist < closestDist then
                closestVehicle = vehicle
                closestDist = dist
            end
        end
    end
    return closestVehicle
end


local function getText(vehicle)
    local class = GetVehicleClass(vehicle)
    local searchTime = data.vehicles[class].search
    local search = searchTime and searchTime > 0 and not Entity(vehicle)?.state?.searched
    local hotwire = data.useHotwireSystem and data.vehicles[class].hotwire
    local text = {}

    if search then
        text[#text + 1] = ('%s  \n'):format(locale('search'))
    end

    if hotwire then
        text[#text + 1] = ('%s  \n'):format(locale('hotwire'))
    end

    return text, hotwire, search, searchTime
end

local function carAnim()
    lib.requestAnimDict(animDict, 1000)
    while lib.progressActive() or lib.skillCheckActive() do
        if cache.vehicle and not IsEntityPlayingAnim(cache.ped, animDict, anim, 3) then
            TaskPlayAnim(cache.ped, animDict, anim, 3.0, 3.0, -1, 49, 0, false, false, false)
        end

        Wait(100)
    end

    StopAnimTask(cache.ped, animDict, anim, 3.0)
    RemoveAnimDict(animDict)
end

local function searchVehicle(searchTime)
    SetTimeout(100, carAnim)
    return progressBar({
        duration = searchTime,
        label = locale('search_vehicle'),
        useWhileDead = false,
        canCancel = true,
        position = 'bottom',
        disable = {
            car = true,
            move = true,
            combat = true
        },
    })
end

local function toggleEngine()
    if cache.seat == -1 then
        local hasKey = utils.hasKey(GetVehicleNumberPlateText(cache.vehicle))
        local isHotwired = Entity(cache.vehicle).state?.isHotwired
        local isImmune = data.immune[GetEntityModel(cache.vehicle)]
        
        -- Chỉ cho phép toggle engine khi có chìa khóa hoặc xe miễn dịch
        if not (isImmune or hasKey) then
            return utils.notify('Bạn cần chìa khóa để điều khiển động cơ!', 'error')
        end
        
        -- Nếu xe đã bị hotwire và đang nổ máy, chỉ cho phép tắt khi có chìa khóa
        if isHotwired and GetIsVehicleEngineRunning(cache.vehicle) and not hasKey then
            return utils.notify('Xe đã bị hotwire! Cần chìa khóa để tắt máy.', 'error')
        end
        
        if GetResourceState('Renewed-Fuel') ~= 'missing' then
            local fuel = GetVehicleFuelLevel(cache.vehicle)

            if fuel <= 0 then
                return utils.notify(locale('no_fuel'), 'error')
            end
        end

        local engineHealth, bodyHealth = GetVehicleEngineHealth(cache.vehicle), GetVehicleBodyHealth(cache.vehicle)

        if engineHealth <= 100 or bodyHealth <= 100 then
            return utils.notify(locale('engine_damaged'), 'error')
        end

        local engine = GetIsVehicleEngineRunning(cache.vehicle)

        SetVehicleEngineOn(cache.vehicle, not engine, false, true)

        if not engine then
            local class = GetVehicleClass(cache.vehicle)
            local isBike = class == 8 or class == 9
            local startDict = isBike and 'veh@bike@quad@front@base' or 'oddjobs@towing'

            lib.requestAnimDict(startDict, 1000)
            TaskPlayAnim(cache.ped, startDict, 'start_engine', 8.0, 8.0, isBike and 2250 or 1750, 48, 0, false, false, false)

            Wait(800)

            RemoveAnimDict(startDict)
        else
            -- Khi tắt máy bằng chìa khóa, reset state hotwire
            if hasKey and Entity(cache.vehicle).state?.isHotwired then
                Entity(cache.vehicle).state:set('isHotwired', false, true)
            end
        end


        utils.notify(locale('engine'):format(engine and locale('stopped') or locale('started')), engine and 'error' or 'success')
    end
end exports('toggleEngine', toggleEngine)

local DisableControlAction = DisableControlAction
local function vehLoop()
    -- Bug Fix: capture version hiện tại, thoát nếu bị thay thế bởi loop mới
    local myVersion = vehLoopVersion

    hasCurrentKey = utils.hasKey(GetVehicleNumberPlateText(cache.vehicle))
    local isHotwired = Entity(cache.vehicle).state?.isHotwired

    -- Tắt động cơ nếu xe đang chạy nhưng player không có chìa khóa VÀ xe KHÔNG bị hotwire (nếu config bật)
    if data.autoTurnOffEngine and not data.immune[GetEntityModel(cache.vehicle)] and not hasCurrentKey and not isHotwired then
        if GetIsVehicleEngineRunning(cache.vehicle) then
            SetVehicleEngineOn(cache.vehicle, false, true, true)
            utils.notify('Engine turned off - No keys!', 'error')
        end
    end
    
    -- Xe bị hotwire luôn giữ máy nổ
    if isHotwired and not hasCurrentKey then
        if not GetIsVehicleEngineRunning(cache.vehicle) then
            SetVehicleEngineOn(cache.vehicle, true, true, true)
        end
    end

    if data.vehicleAutoStart and hasCurrentKey then
        if not GetIsVehicleEngineRunning(cache.vehicle) then
            toggleEngine()
        end
    end


    if not data.immune[GetEntityModel(cache.vehicle)] and not utils.setEngineStatus(cache.vehicle) and not hasCurrentKey then
        local text, canHotwire, canSearch, searchTime = getText(cache.vehicle)

        -- if #text > 0 then
        --     utils.textUi(table.concat(text))
        -- end

        while cache.vehicle do
            -- Bug Fix: thoát loop nếu đã bị thay thế bởi version mới (đổi bucket)
            if myVersion ~= vehLoopVersion then break end

            DisableControlAction(0, 71, true) -- disable vehicle acceleration
            DisableControlAction(0, 72, true) -- disable vehicle braking
            DisableControlAction(0, 32, true) -- disable moving forward
            DisableControlAction(0, 33, true) -- disable moving backwards
            DisableControlAction(0, 34, true) -- disable left strafe
            DisableControlAction(0, 35, true) -- disable right strafe


            if hasCurrentKey or cache.seat ~= -1 or GetIsVehicleEngineRunning(cache.vehicle) then
                break
            end

            -- Tắt tính năng search vehicle (tìm chìa khóa)
            -- if canSearch and IsControlJustPressed(0, 47) then
            --     SetTimeout(100, carAnim)

            --     local success = searchVehicle(searchTime)

            --     if cache.seat == -1 and success then
            --         TriggerServerEvent('Renewed-Vehiclekeys:server:searchVehicle')

            --         canSearch = false

            --         table.remove(text, 1)

            --         if #text > 0 then
            --             utils.textUi(table.concat(text))
            --         else
            --             utils.hideTextUi()
            --         end
            --     end
            -- end

            Wait(0)
        end

        --utils.hideTextUi()
    end
end

local touchlessKey = GetConvarInt('vehiclekeys_usetouchlesskey', 0) == 1

local lastTouched = GetGameTimer()
local lastNoKeyNotification = 0 -- Thời gian thông báo cuối cùng

-- Hàm hiển thị thông báo không có chìa khóa (chỉ 1 lần trong 3 giây)
local function notifyNoKeys()
    local currentTime = GetGameTimer()
    if currentTime - lastNoKeyNotification > 3000 then
        utils.notify(locale('no_keys_locked'), 'error')
        lastNoKeyNotification = currentTime
    end
end

local isDragging = false
local dragDict, dragAnim = 'missfinale_c2ig_11', 'pushcar_offcliff_t'
local DRAG_DOOR_DIST = 2.0

local function doDrag(targetVehicle, targetDriver)
    isDragging = true
    ClearPedTasksImmediately(cache.ped)
    CreateThread(function()
        SetVehicleDoorOpen(targetVehicle, 0, false, false)
        RequestAnimDict(dragDict)
        while not HasAnimDictLoaded(dragDict) do Wait(0) end
        TaskPlayAnim(cache.ped, dragDict, dragAnim, 8.0, -8.0, 500, 48, 0, false, false, false)
        Wait(500)
        if IsPedAPlayer(targetDriver) then
            TriggerServerEvent('Renewed-Vehiclekeys:server:dragOutDriver', NetworkGetNetworkIdFromEntity(targetDriver), VehToNet(targetVehicle))
        else
            TaskLeaveVehicle(targetDriver, targetVehicle, 4160)
            Wait(1200)
            SetPedToRagdoll(targetDriver, 3000, 3000, 0, false, false, false)
            Wait(1000)
            TaskSmartFleePed(targetDriver, cache.ped, 100.0, 30000, false, true)
        end
        Wait(500)
        RemoveAnimDict(dragDict)
        isDragging = false
    end)
end

local function idleVehicle()
    -- Bug Fix: capture version hiện tại, thoát nếu bị thay thế bởi loop mới (đổi bucket)
    local myVersion = idleLoopVersion

    local hasChecked = {}
    while not cache.vehicle do
        -- Bug Fix: thoát loop cũ nếu version đã thay đổi
        if myVersion ~= idleLoopVersion then break end

        local vehicle = GetVehiclePedIsTryingToEnter(cache.ped)
        if vehicle > 0 then
            -- Kéo người ra nếu Shift đang giữ + có driver + có chìa khóa + đủ gần cửa
            if not isDragging and IsControlPressed(0, 21) then
                local driver = GetPedInVehicleSeat(vehicle, -1)
                if driver ~= 0 then
                    local plate = GetVehicleNumberPlateText(vehicle)
                    local model = GetEntityModel(vehicle)
                    if data.immune[model] or utils.hasKey(plate) then
                        local doorBone = GetEntityBoneIndexByName(vehicle, 'door_dside_f')
                        local doorPos = doorBone ~= -1
                            and GetWorldPositionOfEntityBone(vehicle, doorBone)
                            or GetEntityCoords(vehicle)
                        if #(GetEntityCoords(cache.ped) - doorPos) <= DRAG_DOOR_DIST then
                            doDrag(vehicle, driver)
                            Wait(100)
                            goto continueIdle
                        end
                    end
                end
            end

            local model = GetEntityModel(vehicle)
            local seat = GetSeatPedIsTryingToEnter(cache.ped)
            local pedLocked = GetVehicleDoorsLockedForPlayer(vehicle, playerId)
            local ped = GetPedInVehicleSeat(vehicle, seat)
            local class = GetVehicleClass(vehicle)
            local lockStatus = GetVehicleDoorLockStatus(vehicle)

            -- Sync lock status with statebag to prevent desync on bucket change/recreation
            local vehState = Entity(vehicle).state
            local vehicleLock = vehState and vehState.vehicleLock
            if vehicleLock and type(vehicleLock) == 'table' then
                local expectedLock = vehicleLock.lock
                if vehState.isLockpicked then
                    expectedLock = 1
                end
                if lockStatus ~= expectedLock then
                    SetVehicleDoorsLocked(vehicle, expectedLock)
                    lockStatus = expectedLock
                end
            end

            if data.immune[model] or data.vehicles[class].noLocks then SetVehicleDoorsLocked(vehicle, 0) goto skip end

            if doorsBlocked[model] and doorsBlocked[model][seat] and not pedLocked then
                SetVehicleDoorsLockedForPlayer(vehicle, playerId, true)
                goto skip
            elseif pedLocked and doorsBlocked[model] and not doorsBlocked[model][seat] then
                SetVehicleDoorsLockedForPlayer(vehicle, playerId, false)
                pedLocked = false
            end

            if lockStatus ~= 2 then
                lockStatus = 0
                SetVehicleDoorsLocked(vehicle, 0)
            end

            if touchlessKey and lockStatus == 2 and not hasChecked[vehicle] and utils.hasKey(GetVehicleNumberPlateText(vehicle)) and (GetGameTimer() - lastTouched > 5000) then
                lastTouched = GetGameTimer()
                TriggerServerEvent('Renewed-Vehiclekeys:server:setVehicleUnlocked', VehToNet(vehicle))

                goto skip
            elseif lockStatus == 2 and not hasChecked[vehicle] and not utils.hasKey(GetVehicleNumberPlateText(vehicle)) then
                -- Thông báo khi người chơi cố mở cửa xe bị khóa mà không có chìa khóa
                notifyNoKeys()
                hasChecked[vehicle] = true
            elseif not hasChecked[vehicle] then
                hasChecked[vehicle] = true
            end

            if ped > 0 and IsEntityDead(ped) and not IsPedAPlayer(ped) and not lib.progressActive() and foundCar ~= vehicle then
                TriggerServerEvent('Renewed-Vehiclekeys:server:StealCandyFromKid', PedToNet(ped), VehToNet(vehicle))
            elseif Entity(vehicle)?.state?.vehicleLock == nil and foundCar ~= vehicle then
                -- Chỉ gọi updateLocal nếu xe CHƯA bị lockpick hoặc hotwire
                local currentVehState = Entity(vehicle).state
                if not currentVehState.isLockpicked and not currentVehState.isHotwired then
                    TriggerServerEvent('Renewed-Vehiclekeys:server:updateLocal', VehToNet(vehicle), GetIsVehicleEngineRunning(vehicle))
                end
            end

            ::skip::

            if foundCar ~= vehicle then
                foundCar = vehicle
                SetEntityAsMissionEntity(vehicle, true, true)
                SetVehicleEngineOn(vehicle, GetIsVehicleEngineRunning(vehicle), true, true)
            end

        end
        ::continueIdle::
        Wait(100)
    end
end

if data.useKeybindKey then
    lib.addKeybind({
        name = 'engine',
        description = locale('engine_descrip'),
        defaultKey = data.engineKey,
        onPressed = toggleEngine
    })
end


local keyDict, keyAnim = 'anim@mp_player_intmenu@key_fob@', 'fob_kick'
local locking = false
local lockingResetTimer = nil -- Bug Fix: timer để tự động reset locking nếu bị kẹt

local function toggleLights(netId)
    local vehicle = NetToVeh(netId)

    local engineState = GetIsVehicleEngineRunning(vehicle)
    local _, light, highBeam = GetVehicleLightsState(vehicle)

    SetVehicleLights(vehicle, 1)

    local state = Entity(vehicle).state
    local lock = state?.vehicleLock?.lock or 1

    if lock == 1 then
        Wait(100)
        SetVehicleLights(vehicle, 2)
        Wait(100)

        SetVehicleLights(vehicle, 1)
        Wait(150)

    elseif lock == 2 then
        Wait(100)
        SetVehicleLights(vehicle, 2)

        Wait(50)

        SetVehicleLights(vehicle, 1)
        Wait(100)

        SetVehicleLights(vehicle, 2)

        Wait(150)

        SetVehicleLights(vehicle, 1)
    end

    local lightState = (light or highBeam) and 3 or 0

    SetVehicleLights(vehicle, lightState)

    if engineState ~= GetVehicleLightsState(vehicle) then
        SetVehicleEngineOn(vehicle, engineState, true, true)
    end
end

RegisterNetEvent('Renewed-Vehiclekeys:client:toggleLights', toggleLights)

local function toggleLocks(vehicle)
    if locking then return end
    locking = true

    -- Bug Fix: Đặt safety timer để tự reset locking sau 2 giây phòng trường hợp bị kẹt do đổi bucket
    if lockingResetTimer then
        lockingResetTimer = nil
    end
    lockingResetTimer = SetTimeout(2000, function()
        if locking then
            locking = false
        end
        lockingResetTimer = nil
    end)

    local vehicleLock = Entity(vehicle).state?.vehicleLock
    local isUnlocking = type(vehicleLock) == 'table' and vehicleLock.lock == 2

    if not cache.vehicle then
        lib.requestAnimDict(keyDict, 1000)

        TaskPlayAnim(cache.ped, keyDict, keyAnim, 3.0, 3.0, -1, 49, 0, false, false, false)
    end

    TriggerServerEvent('Renewed-Vehiclekeys:server:toggleLights', VehToNet(vehicle))

    Wait(150)

    TriggerServerEvent('Renewed-Vehiclekeys:server:toggleLock', VehToNet(vehicle))

    Wait(150)

    if not cache.vehicle then
        if IsEntityPlayingAnim(cache.ped, keyDict, keyAnim, 3) then
            StopAnimTask(cache.ped, keyDict, keyAnim, 3.0)
        end

        RemoveAnimDict(keyDict)
    end


    utils.notify(locale('vehicle'):format(isUnlocking and locale('unlocked') or locale('locked')), isUnlocking and 'success' or 'error')

    locking = false
end

lib.addKeybind({
    name = 'lock',
    description = locale('lock_descrip'),
    defaultKey = data.lockKey,
    onPressed = function()
        if locking then return end

        if cache.vehicle then
            local plate = GetVehicleNumberPlateText(cache.vehicle)
            local class = GetVehicleClass(cache.vehicle)
            local isLockpicked = Entity(cache.vehicle).state?.isLockpicked
            
            -- Xe bị lockpick không thể khóa lại trừ khi có chìa khóa
            if isLockpicked and not utils.hasKey(plate) then
                return utils.notify('Xe đã bị phá khóa! Cần chìa khóa để khóa lại.', 'error')
            end

            if not data.vehicles[class].noLocks and utils.hasKey(plate) then
                -- Nếu có chìa khóa, reset state lockpicked
                if isLockpicked then
                    Entity(cache.vehicle).state:set('isLockpicked', false, true)
                end
                toggleLocks(cache.vehicle)
            elseif not data.vehicles[class].noLocks then
                -- Không có chìa khóa để khóa/mở xe
                notifyNoKeys()
            end

            return
        end

        local closestKeyCar = utils.getClosestKeyCar()

        if closestKeyCar then
            local isLockpicked = Entity(closestKeyCar).state?.isLockpicked
            local plate = GetVehicleNumberPlateText(closestKeyCar)
            
            -- Xe bị lockpick không thể khóa lại trừ khi có chìa khóa
            if isLockpicked and not utils.hasKey(plate) then
                return utils.notify('Xe đã bị phá khóa! Cần chìa khóa để khóa lại.', 'error')
            end
            
            -- Nếu có chìa khóa, reset state lockpicked
            if isLockpicked then
                Entity(closestKeyCar).state:set('isLockpicked', false, true)
            end
            toggleLocks(closestKeyCar)
        else
            -- Kiểm tra xem có xe gần đó không (dù không có chìa khóa)
            local vehicle = getClosestVehicle(GetEntityCoords(cache.ped), 15.0)
            if vehicle then
                local class = GetVehicleClass(vehicle)
                -- Chỉ thông báo nếu xe không miễn dịch khóa
                if not data.vehicles[class].noLocks and not data.immune[GetEntityModel(vehicle)] then
                    notifyNoKeys()
                end
            end
        end
    end,
})

lib.onCache('ped', function(value)
    if value then
        SetPedConfigFlag(value, 170, false)
        SetPedConfigFlag(value, 241, true) -- Player will leave the engine on when exiting a vehicle normally
        SetPedConfigFlag(value, 426, false) -- Use Franklin's alternate lockpicking animations for forced entry
        SetPedConfigFlag(value, 429, true)
        SetPedConfigFlag(value, 448, true) -- Will prevent ped from forcing entry into cars that are open from TryLockedDoor state
    end
end)

lib.onCache('seat', function(value)
    -- Bug Fix: Increment version counters để kill tất cả loop cũ đang chạy
    -- và reset foundCar để buộc re-sync vehicleLock state sau khi đổi bucket
    idleLoopVersion = idleLoopVersion + 1
    vehLoopVersion = vehLoopVersion + 1
    foundCar = 0

    -- Bug Fix: Reset locking flag phòng trường hợp bị kẹt khi đổi bucket giữa chừng
    locking = false

    if value == -1 then
        return SetTimeout(0, vehLoop)
    end

    hasCurrentKey = false

    SetTimeout(0, idleVehicle)
end)


if data.useWeaponRobbery then
    lib.onCache('weapon', function(value)
        if value and not data.blockedWeapons[value] then
            SetTimeout(0, function()
                while cache.weapon do
                    if not cache.vehicle and not lib.progressActive() then
                        local _, target = GetEntityPlayerIsFreeAimingAt(playerId)
                        local pedveh = target and GetVehiclePedIsIn(target, false) or 0

                        if pedveh > 0 then
                            local peds = utils.getPedsInCar(pedveh)
                            local pedAmount = peds and #peds or 0

                            if pedAmount == 0 or GetEntitySpeed(pedveh) > 3 or #(GetEntityCoords(cache.ped) - GetEntityCoords(target)) > 10 then goto skip end

                            if foundCar ~= pedveh and not data.immune[GetEntityModel(pedveh)] and not IsEntityDead(target) and not IsPedAPlayer(target) then
                                foundCar = pedveh

                                TriggerServerEvent('Renewed-Vehiclekeys:server:robPedKeys', PedToNet(target), VehToNet(pedveh))

                                lib.requestAnimDict(huDict, 1000)

                                for i = 1, pedAmount do
                                    TaskPlayAnim(peds[i], huDict, huAnim, 8.0, 8.0, -1, 50, 0, false, false, false)
                                end

                                RemoveAnimDict(huDict)
                            end
                        end
                    end

                    :: skip ::
                    Wait(150)
                end
            end)
        end
    end)
end

local function canLockPick(vehicle, item)
    local class = vehicle and GetVehicleClass(vehicle)

    if class then
        local itemNames = data.vehicles[class] and data.vehicles[class].pickItem

        if itemNames and next(itemNames) then
            return itemNames?[item]
        end
    end

    return false
end

AddEventHandler('lockpick:use', function(payload)
    local vehicle = cache.vehicle or getClosestVehicle(GetEntityCoords(cache.ped), 3.0)
    if vehicle and DoesEntityExist(vehicle) then
        local plate = utils.formatPlate(GetVehicleNumberPlateText(vehicle))
        if plate == 'XEBAN999' then
            return utils.notify('bạn không thể lockpick xe này', 'error')
        end
    end

    local canPick = vehicle and DoesEntityExist(vehicle) and canLockPick(vehicle, payload?.name)

    if cache.vehicle and cache.seat ~= -1 then return end

    if not canPick then 
        if vehicle then
            local class = GetVehicleClass(vehicle)
            -- Kiểm tra nếu dùng lockpick thường với máy bay/thuyền/trực thăng
            if payload?.name == 'lockpick' and (class == 14 or class == 15 or class == 16) then
                return utils.notify(locale('need_advanced_lockpick'), 'error')
            else
                return utils.notify(locale('not_strong_enough'), 'error')
            end
        end
        return
    end

    if not utils.canLockpick(vehicle) then return end

    local state = Entity(vehicle).state

    if not state.vehicleLock then
        TriggerServerEvent('Renewed-Vehiclekeys:server:updateLocal', VehToNet(vehicle))
        while not state.vehicleLock do
            Wait(100)
        end
    end

    local itemConfig = data?.vehicles?[GetVehicleClass(vehicle)]?.pickItem?[payload?.name]
    local difficulty = itemConfig and itemConfig.difficulty or 0.6
    local pins = itemConfig and itemConfig.pins or 3

    -- Nếu đang ngồi trong xe và engine chưa nổ -> HOTWIRE
    if cache.seat == -1 and not GetIsVehicleEngineRunning(vehicle) then
        -- Kích hoạt báo động xe khi bắt đầu hotwire
        SetVehicleAlarm(vehicle, true)
        SetVehicleAlarmTimeLeft(vehicle, 60000)

        -- Gửi thông báo cho chủ xe NGAY KHI BẮT ĐẦU
        TriggerServerEvent('Renewed-Vehiclekeys:server:hotwireVehicle', VehToNet(vehicle))

        TriggerEvent('Renewed-Vehiclekeys:pickVehicle', vehicle, payload?.slot, payload?.name)
        utils.alertHotwire(vehicle, payload?.name)

        -- Progress bar trước khi minigame
        SetTimeout(100, carAnim)
        local progressSuccess = progressBar({
            duration = 5000,
            label = 'Đang đấu động cơ...',
            useWhileDead = false,
            canCancel = true,
            position = 'bottom',
            disable = {
                car = true,
                move = true,
                combat = true
            },
        })

        StopAnimTask(cache.ped, animDict, anim, 3.0)
        RemoveAnimDict(animDict)

        if not progressSuccess then
            utils.notify('Đã hủy đấu động cơ!', 'error')
            return
        end

        -- Sử dụng hotwire minigame thay vì lockpick game
        local success = utils.hotwireMinigame()

        if success == true then
            if cache.seat == -1 then
                if GetVehicleAlarmTimeLeft(vehicle) > 0 then
                    SetVehicleAlarm(vehicle, false)
                    SetVehicleAlarmTimeLeft(vehicle, 0)
                end
                
                -- Đánh dấu xe đã bị hotwire
                Entity(vehicle).state:set('isHotwired', true, true)
                
                -- Nổ máy xe
                SetVehicleEngineOn(vehicle, true, true, true)
                Wait(100)
                
                utils.notify('Hotwire thành công! Động cơ đã khởi động.', 'success')
            end
        elseif success == false then
            -- Thất bại có tỉ lệ mất lockpick
            local tyle = math.random(1, 100)
            if tyle > 1 and tyle < 30 then
                utils.notify('Hotwire thất bại! Lockpick bị gãy.', 'error')
                TriggerServerEvent('Renewed-Vehiclekeys:server:breakLockpick', payload?.slot, payload?.name)
            else
                utils.notify('Hotwire thất bại!', 'error')
            end
        end

        return
    
    -- Nếu đang ở ngoài xe và cửa bị khóa -> LOCKPICK DOOR
    elseif GetVehicleDoorLockStatus(vehicle) == 2 or state?.vehicleLock?.lock == 2 then
        -- Kích hoạt báo động xe khi bắt đầu lockpick door
        SetVehicleAlarm(vehicle, true)
        SetVehicleAlarmTimeLeft(vehicle, 60000)
        
        TriggerEvent('Renewed-Vehiclekeys:pickVehicle', vehicle, payload?.slot, payload?.name)

        -- Nếu dùng advanced lockpick, chạy progressbar 30s trước khi minigame
        if payload?.name == 'advalockpicknced' then
            -- Báo cảnh sát ngay khi bắt đầu phá khóa
            utils.alertLockpick(vehicle, payload?.name)
            
            SetTimeout(100, carAnim)
            local progressSuccess = progressBar({
                duration = 30000,
                label = 'Đang phá khóa nâng cao...',
                useWhileDead = false,
                canCancel = true,
                position = 'bottom',
                disable = {
                    car = true,
                    move = true,
                    combat = true
                },
            })

            StopAnimTask(cache.ped, animDict, anim, 3.0)
            RemoveAnimDict(animDict)

            if not progressSuccess then
                utils.notify('Đã hủy phá khóa!', 'error')
                return
            end
        end

        TriggerServerEvent('Renewed-Vehiclekeys:server:lockpickDoor', VehToNet(vehicle), payload?.slot, payload?.name, itemConfig and itemConfig.degrade)
    end

end)


-- Statebags --
utils.stateBagWrapper('vehicleLock', function(entity, value)
    if type(value) == 'table' then
        local isLockpicked = Entity(entity).state?.isLockpicked
        
        -- Xe bị lockpick luôn mở cửa, không thể khóa lại
        if isLockpicked then
            SetVehicleDoorsLocked(entity, 1) -- Luôn unlocked
        else
            SetVehicleDoorsLocked(entity, value.lock)
        end

        if value.sound and #(GetEntityCoords(entity) - GetEntityCoords(cache.ped)) < 20 then

            while not RequestScriptAudioBank('dlc_vehiclekeys/vehiclekeys', false) do
                Wait(0)
            end

            local soundId = GetSoundId()

            PlaySoundFromEntity(soundId, value.lock == 2 and 'lock' or 'unlock', entity, 'DLC_VEHICLEKEYS_SET', 0, 0)

            ReleaseSoundId(soundId)

            ReleaseNamedScriptAudioBank('dlc_vehiclekeys/vehiclekeys')
        end
    end
end)

-- Callbacks --
local cancelPedSteal = false
lib.callback.register('Renewed-Vehiclekeys:client:stealFromPed', function(netId)
    local ped = NetToPed(netId)
    if not IsEntityDead(ped) then return false end

    cancelPedSteal = false
    SetTimeout(100, function()
        while lib.progressActive() do
            local vehicle = GetVehiclePedIsTryingToEnter(cache.ped)
            if GetVehiclePedIsIn(cache.ped, false) > 0 then return end

            if vehicle == 0 then
                cancelPedSteal = true
                lib.cancelProgress()

                break
            end
            Wait(100)
        end

        if cancelPedSteal then return end
        utils.pedFlee(vehicle)
    end)

    local success = lib.progressCircle({
        duration = 3000,
        label = locale('taking_keys'),
        position = 'bottom',
    })

    return success and cancelPedSteal == false
end)

lib.callback.register('Renewed-Vehiclekeys:client:robPedKeys', function(netId, vehicleNetId)
    local ped, vehicle = NetToPed(netId), NetToVeh(vehicleNetId)

    if not DoesEntityExist(ped) then return false end

    local haveAlerted = false
    cancelPedSteal = false

    SetTimeout(100, function()
        while lib.progressActive() do
            local distance = #(GetEntityCoords(cache.ped) - GetEntityCoords(ped))

            if not haveAlerted then
                utils.alertVehicleTheft(vehicle, ped)
                haveAlerted = true
            end

            if IsPedDeadOrDying(ped) or distance > 10.0 or not cache.weapon or not IsPlayerFreeAiming(playerId) then
                cancelPedSteal = true
                lib.cancelProgress()

                Wait(100)

                foundCar = 0

                break
            end

            Wait(100)
        end

        if not cancelPedSteal then
            utils.pedFlee(vehicle)
        end
    end)

    local success = progressBar({
        duration = 3000,
        label = locale('stealing_keys'),
        position = 'bottom',
    })

    return success and not cancelPedSteal
end)

lib.callback.register('Renewed-Vehiclekeys:client:lockPickCar', function(netId, item)
    local vehicle = NetToVeh(netId)

    if not DoesEntityExist(vehicle) then return false end

    local plate = utils.formatPlate(GetVehicleNumberPlateText(vehicle))
    if plate == 'XEBAN999' then
        utils.notify('bạn không thể lockpick xe này', 'error')
        return false
    end

    lib.requestAnimDict(lockpickDic, 1000)

    TaskTurnPedToFaceEntity(cache.ped, vehicle, 200)

    -- Kích hoạt báo động xe khi bắt đầu lockpick door
    SetVehicleAlarm(vehicle, true)
    SetVehicleAlarmTimeLeft(vehicle, 60000)

    SetTimeout(0, function()
        while lib.skillCheckActive() do
            TaskPlayAnim(cache.ped, lockpickDic, lockpickAnim, 3.0, 3.0, -1, 16, 0, 0, 0, 0)
            Wait(1000)
        end
    end)

    local class = GetVehicleClass(vehicle)

    local itemConfig = data?.vehicles?[class]?.pickItem?[item]
    local difficulty = itemConfig and itemConfig.difficulty or 0.6
    local pins = itemConfig and itemConfig.pins or 3

    local success = utils.lockpickGame(item, difficulty, pins)

    StopAnimTask(cache.ped, lockpickDic, lockpickAnim, 3.0)
    RemoveAnimDict(lockpickDic)

    return success
end)


if data.useKeyItem then
    AddEventHandler('ox_inventory:updateInventory', function(changes)
        if hasCurrentKey or cache.seat ~= -1 or GetIsVehicleEngineRunning(cache.vehicle) then return end

        local tempKeys = {}

        for k, v in pairs(changes) do
            if tempKeys[k] and v?.name ~= 'vehiclekey' then
                tempKeys[k] = nil
            elseif v?.name == 'vehiclekey' then
                tempKeys[k] = v?.metadata?.plate
            end
        end


        if next(tempKeys) then
            local plate = GetVehicleNumberPlateText(cache.vehicle)

            for _, v in pairs(tempKeys) do
                if v and v == plate then
                    hasCurrentKey = true
                    return
                end
            end

            hasCurrentKey = false
            SetTimeout(0, vehLoop)
        end
    end)
else
    local function loadKeys(Keys)
        Keys = Keys or lib.callback.await('Renewed-Vehiclekeys:server:getKeys', false)

        utils.setKeys(Keys)

        if cache.seat == -1 then
            hasCurrentKey = utils.hasKey(GetVehicleNumberPlateText(cache.vehicle))
        end
    end


    RegisterNetEvent('Renewed-Vehiclekeys:client:syncKeys', loadKeys)

    AddEventHandler('Renewed-Lib:client:PlayerLoaded', function()
        loadKeys()
    end)
end

AddEventHandler('onResourceStart', function(resource)
   if resource == GetCurrentResourceName() then
        if cache.vehicle then
            SetTimeout(0, vehLoop)
        else
            SetTimeout(0, idleVehicle)
        end

        SetPedConfigFlag(cache.ped, 170, false)
        SetPedConfigFlag(cache.ped, 241, true) -- Player will leave the engine on when exiting a vehicle normally
        SetPedConfigFlag(cache.ped, 426, false) -- Use Franklin's alternate lockpicking animations for forced entry
        SetPedConfigFlag(cache.ped, 429, true)
        SetPedConfigFlag(cache.ped, 448, true) -- Will prevent ped from forcing entry into cars that are open from TryLockedDoor state
   end
end)


CreateThread(function()
    while not GetResourceState('ox_inventory') == 'started' do
        Wait(100)
    end

    exports.ox_inventory:displayMetadata('plate', locale('plate'))
end)


-- Nhận lệnh từ server để thoát khỏi ghế lái + ragdoll
RegisterNetEvent('Renewed-Vehiclekeys:client:forceExitVehicle', function(vehicleNetId)
    local vehicle = NetToVeh(vehicleNetId)
    if cache.vehicle == vehicle and cache.seat == -1 then
        TaskLeaveVehicle(cache.ped, vehicle, 0)
        Wait(1200)
        -- Ngã ra đất 3 giây
        SetPedToRagdoll(cache.ped, 3000, 3000, 0, false, false, false)
    end
end)