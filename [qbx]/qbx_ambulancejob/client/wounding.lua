local config = require 'config.client'
local sharedConfig = require 'config.shared'
local painkillerAmount = 0

lib.callback.register('hospital:client:UseIfaks', function()
    if lib.progressCircle({
        duration = 3000,
        position = 'bottom',
        label = locale('progress.ifaks'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = 'mp_suicide',
            clip = 'pill',
        },
    })
    then
        TriggerServerEvent('hud:server:RelieveStress', math.random(12, 24))
        SetEntityHealth(cache.ped, GetEntityHealth(cache.ped) + 10)
        OnPainKillers = true
        exports.qbx_medical:DisableDamageEffects()
        if painkillerAmount < 3 then
            painkillerAmount += 1
        end
        if math.random(1, 100) < 50 then
            exports.qbx_medical:RemoveBleed(1)
        end
        return true
    else
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
        return false
    end
end)

lib.callback.register('hospital:client:UseBandage', function()
    if lib.progressCircle({
        duration = 15000,
        position = 'bottom',
        label = locale('progress.bandage'),
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = false,
            car = true,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = "missheistdockssetup1clipboard@idle_a",
            clip = "idle_a",
            flag = 49,
            duration = 6000,
        },
        prop = {
            model = 'prop_stat_pack_01',
            bone = 28422,
            pos = vec3(0.0, 0.0, 0.0),
            rot = vec3(0.0, 0.0, 0.0)
        }
    })
    then
        SetEntityHealth(cache.ped, GetEntityHealth(cache.ped) + 15)
        -- if math.random(1, 100) < 50 then
        --     exports.qbx_medical:RemoveBleed(1)
        -- end
        -- if math.random(1, 100) < 7 then
        --     exports.qbx_medical:ResetMinorInjuries()
        -- end
        return true
    else
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
        return false
    end
end)

lib.callback.register('hospital:client:UseBandageLv2', function()
    if lib.progressCircle({
        duration = 7000,
        position = 'bottom',
        label = locale('progress.bandage_lv2'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = true,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = 'anim@heists@narcotics@funding@gang_idle',
            clip = 'gang_chatting_idle01',
            flag = 0,
            blendIn = 8.0,
            blendOut = -8.0,
            duration = 5000,
        },
    })
    then
        SetEntityHealth(cache.ped, GetEntityHealth(cache.ped) + 25)
        return true
    else
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
        return false
    end
end)

lib.callback.register('hospital:client:UseAoGiapGang', function()
    local currentArmor = GetPedArmour(cache.ped)
    if currentArmor >= 50 then
        exports.qbx_core:Notify(locale('error.max_armor_50') or 'Bạn đã có tối đa 50% giáp từ áo này!', 'error')
        return false
    end

    if lib.progressCircle({
        duration = 5000,
        position = 'bottom',
        label = locale('progress.ao_giap_gang'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = true,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = 'clothingshirt',
            clip = 'try_shirt_positive_d',
            flag = 49,
            blendIn = 8.0,
            blendOut = -8.0,
            duration = 5000,
        },
    })
    then
        SetPlayerMaxArmour(cache.playerId, 100)
        SetPedArmour(cache.ped, 50)
        return true
    else
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
        return false
    end
end)

local function isPlayerInRedZone()
    local plyCoords = GetEntityCoords(cache.ped)
    local redZones = (sharedConfig.medLangBam and sharedConfig.medLangBam.redZones) or {}
    for _, zone in ipairs(redZones) do
        local center = zone.center or zone.coords or (type(zone) == 'vector3' and zone)
        local radius = zone.radius or 100.0
        if center then
            local dist = #(plyCoords - center)
            if dist <= radius then
                return true, zone
            end
        end
    end
    return false
end

lib.callback.register('hospital:client:UseMedLangBam', function()
    if exports.qbx_medical:IsDead() or exports.qbx_medical:IsLaststand() then
        return false
    end

    if IsPedInAnyVehicle(cache.ped, false) then
        exports.qbx_core:Notify('Bạn đang ngồi trên xe không thể cứu người!', 'error')
        return false
    end

    if not isPlayerInRedZone() then
        exports.qbx_core:Notify('Med lang băm chỉ có thể sử dụng trong vùng đỏ!', 'error')
        return false
    end

    local player = GetClosestPlayer()
    if not player then
        exports.qbx_core:Notify(locale('error.no_player'), 'error')
        return false
    end

    local targetId = GetPlayerServerId(player)
    if not targetId or targetId <= 0 then
        exports.qbx_core:Notify(locale('error.no_player'), 'error')
        return false
    end

    local targetState = Player(targetId).state
    local targetDeathState = targetState and targetState['qbx_medical:deathState']

    if targetDeathState == 3 then
        exports.qbx_core:Notify('Người này đã chết hẳn, Med lang băm chỉ cứu được người bị ngất!', 'error')
        return false
    end

    if targetDeathState ~= 2 then
        exports.qbx_core:Notify('Chỉ có thể dùng Med lang băm cho người đang bị ngất (hấp hối)!', 'error')
        return false
    end

    -- Đóng băng người chơi & Chạy animation hô hấp nhân tạo (CPR)
    FreezeEntityPosition(cache.ped, true)
    local animDict = HealAnimDict or 'mini@cpr@char_a@cpr_str'
    local animName = HealAnim or 'cpr_pumpchest'
    lib.requestAnimDict(animDict)
    TaskPlayAnim(cache.ped, animDict, animName, 8.0, 8.0, -1, 1, 0, false, false, false)

    local isPlayingMinigame = true
    CreateThread(function()
        while isPlayingMinigame do
            DisableControlAction(0, 30, true) -- Move left/right
            DisableControlAction(0, 31, true) -- Move forward/back
            DisableControlAction(0, 32, true) -- Move forward
            DisableControlAction(0, 33, true) -- Move back
            DisableControlAction(0, 34, true) -- Move left
            DisableControlAction(0, 35, true) -- Move right
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Jump
            DisableControlAction(0, 23, true) -- Enter vehicle
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 44, true) -- Cover
            DisableControlAction(0, 75, true) -- Exit vehicle
            DisableControlAction(0, 140, true) -- Melee Attack
            DisableControlAction(0, 141, true) -- Melee Attack Heavy
            DisableControlAction(0, 142, true) -- Melee Attack Alt
            Wait(0)
        end
    end)

    -- Khởi chạy Minigame
    local p = promise.new()
    local difficulty = (sharedConfig.medLangBam and sharedConfig.medLangBam.difficulty) or 3

    local success, err = pcall(function()
        exports.mgc:start_game({
            game = 'button_mash',
            data = {
                difficulty = difficulty
            }
        }, function(result)
            p:resolve(result)
        end)
    end)

    local result
    if success then
        result = Citizen.Await(p)
    else
        print('^1[qbx_ambulancejob] Error starting mgc minigame:^7', err)
        result = { success = false }
    end

    -- Dừng minigame, mở đóng băng và dừng animation CPR
    isPlayingMinigame = false
    FreezeEntityPosition(cache.ped, false)
    ClearPedTasks(cache.ped)

    if not isPlayerInRedZone() then
        exports.qbx_core:Notify('Bạn đã ra khỏi vùng đỏ, không thể cứu!', 'error')
        return false
    end

    if result and result.success then
        exports.qbx_core:Notify('Cứu người thành công!', 'success')
        TriggerServerEvent('hospital:server:ReviveMedLangBam', targetId)
        return true -- Mất 01 medlangbam
    else
        exports.qbx_core:Notify('Cứu người thất bại! Med lang băm đã bị hỏng.', 'error')
        return true -- Minigame thất bại VẪN MẤT item medlangbam như bình thường
    end
end)

lib.callback.register('hospital:client:UsePainkillers', function()
    if lib.progressCircle({
        duration = 3000,
        position = 'bottom',
        label = locale('progress.painkillers'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = 'mp_suicide',
            clip = 'pill',
        },
    })
    then
        OnPainKillers = true
        --exports.qbx_medical:DisableDamageEffects()
        TriggerEvent('qbx_medical:client:painkillers')
        if painkillerAmount < 3 then
            painkillerAmount += 1
        end
        return true
    else
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
        return false
    end
end)

local function consumePainKiller()
    painkillerAmount -= 1
    Wait(config.painkillerInterval * 1000)
    if painkillerAmount > 0 then return end
    painkillerAmount = 0
    OnPainKillers = false
    exports.qbx_medical:EnableDamageEffects()
end

CreateThread(function()
    while true do
        Wait(1)
        if OnPainKillers then
            consumePainKiller()
        else
            Wait(3000)
        end
    end
end)