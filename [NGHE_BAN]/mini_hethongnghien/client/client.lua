local isAddicted = false
local lastUseTime = 0
local withdrawalActive = false
local withdrawalThread = nil
local inRehab = false
local rehabNPC = nil
local rehabBlip = nil

-- Animation helper
local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

-- Spawn NPC cai nghiện
local function SpawnRehabNPC()
    -- Xóa NPC cũ nếu tồn tại
    if rehabNPC and DoesEntityExist(rehabNPC) then
        DeleteEntity(rehabNPC)
        rehabNPC = nil
    end
    
    local model = GetHashKey(Config.Addiction.rehab.npcModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    
    local npc = CreatePed(4, model, Config.Addiction.rehab.npcCoords.x, 
                          Config.Addiction.rehab.npcCoords.y, 
                          Config.Addiction.rehab.npcCoords.z - 1.0, 
                          Config.Addiction.rehab.npcCoords.w, false, true)
    
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetModelAsNoLongerNeeded(model)
    
    rehabNPC = npc
    
    -- Target zone
    exports.ox_target:addLocalEntity(npc, {
        {
            name = 'ladudu_rehab_info',
            icon = 'fa-solid fa-info-circle',
            label = 'Hỏi về cai nghiện',
            onSelect = function()
                -- Kiểm tra có bác sĩ online không trước khi mở menu
                local isDoctorOnline = lib.callback.await('F7_ladudu_addiction:server:isDoctorOnline', false)
                if isDoctorOnline then
                    lib.notify({
                        description = 'Hiện đang có Bác Sĩ trực. Vui lòng liên hệ bác sĩ để được hỗ trợ cai nghiện!',
                        type = 'error',
                        duration = 7000
                    })
                    return
                end

                -- Mở NUI menu
                Wait(100)

                SendNUIMessage({
                    action = 'openRehabMenu',
                    prices = {
                        normal = Config.Addiction.rehab.normal.cost,
                        fast = Config.Addiction.rehab.fast.cost
                    }
                })

                Wait(50)

                SetNuiFocus(true, true)
            end
        },
        -- {
        --     name = 'ladudu_heal_treatment',
        --     icon = 'fa-solid fa-heart-pulse',
        --     label = 'Chữa trị ($2,000)',
        --     onSelect = function()
        --         TriggerServerEvent('mini_hethongnghien:server:healPlayer')
        --     end
        -- },

    })
    
    return npc
end

-- Tạo blip
local function CreateRehabBlip()
    if not Config.Addiction.rehab.blipEnabled then return end
    
    -- Xóa blip cũ nếu tồn tại
    if rehabBlip and DoesBlipExist(rehabBlip) then
        RemoveBlip(rehabBlip)
        rehabBlip = nil
    end
    
    local blip = AddBlipForCoord(Config.Addiction.rehab.npcCoords.x, 
                                 Config.Addiction.rehab.npcCoords.y, 
                                 Config.Addiction.rehab.npcCoords.z)
    
    SetBlipSprite(blip, Config.Addiction.rehab.blipSprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Addiction.rehab.blipScale)
    SetBlipColour(blip, Config.Addiction.rehab.blipColor)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Addiction.rehab.blipLabel)
    EndTextCommandSetBlipName(blip)
    
    rehabBlip = blip
end

-- Spawn NPC onduty riêng

-- Hiệu ứng ảo giác khi dùng
RegisterNetEvent('F7_ladudu_addiction:client:useEffect', function()
    local ped = PlayerPedId()
    local config = Config.Addiction.effects
    
    -- Load animation dict
    RequestAnimDict('anim@safehouse@bong')
    while not HasAnimDictLoaded('anim@safehouse@bong') do
        Wait(10)
    end
    
    -- Load prop model
    RequestModel('w_me_dieucay')
    while not HasModelLoaded('w_me_dieucay') do
        Wait(10)
    end
    
    -- Play animation
    TaskPlayAnim(ped, 'anim@safehouse@bong', 'bong_stage3', 8.0, 8.0, 7000, 0, 0.0, false, false, false)
    
    -- Create prop
    Wait(500)
    local coords = GetEntityCoords(ped)
    local prop = CreateObject(GetHashKey('w_me_dieucay'), coords.x, coords.y, coords.z, true, true, true)
    
    -- Network sync để mọi người thấy prop
    local netId = ObjToNet(prop)
    SetNetworkIdCanMigrate(netId, false)
    SetNetworkIdExistsOnAllMachines(netId, true)
    NetworkSetEntityInvisibleToNetwork(prop, false)
    
    -- Attach prop to hand
    local boneIndex = GetPedBoneIndex(ped, 18905)  -- Right hand
    AttachEntityToEntity(prop, ped, boneIndex, 0.126, 0.063, 0.026, -271.5, -4.0, 8.5, true, true, false, true, 1, true)
    
    -- Đợi 3 giây rồi phát âm thanh hút
    Wait(2500) -- 500 + 2500 = 3000ms = 3 giây
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 8.5, "thuoclao", 0.125)
    
    -- Đợi thêm 6.5 giây rồi xóa prop
    Wait(6500) -- 3000 + 6500 = 9500ms
    
    -- Delete prop
    if DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
    
    -- Clear animation
    ClearPedTasks(ped)
    
    -- === ANIMATION HO SAU KHI HÚT XONG ===
    
    -- Load animation ho
    RequestAnimDict("timetable@gardener@smoking_joint")
    while not HasAnimDictLoaded("timetable@gardener@smoking_joint") do
        Wait(10)
    end
    
    -- Phát âm thanh ho sặc sụa
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 6.5, "hosacsua", 0.18)
    
    -- Play animation ho lặp lại 6 giây
    TaskPlayAnim(ped, "timetable@gardener@smoking_joint", "idle_cough", 8.0, 8.0, -1, 49, 0, false, false, false)
    Wait(6000)
    
    -- Clear animation ho
    ClearPedTasks(ped)
    
    -- === TÉ XUỐNG ===
    
    -- Té xuống (ragdoll) 4 giây
    SetPedToRagdoll(ped, 4000, 4000, 0, true, true, false)
    Wait(4500)
    
    -- === BẮT ĐẦU HIỆU ỨNG PHÊ SAU KHI DÙNG XONG ===
    
    -- Screen effect (màn hình quay cuồng)
    SetTimecycleModifier(config.screenEffect)
    
    -- Camera shake
    if config.cameraShake then
        ShakeGameplayCam('DRUNK_SHAKE', config.cameraShakeIntensity or 2.5)
    end
    
    -- Drunk effect
    if config.drunk then
        SetPedIsDrunk(ped, true)
    end
    
    -- Đi lảo đảo như say rượu
    RequestAnimSet("move_m@drunk@verydrunk")
    while not HasAnimSetLoaded("move_m@drunk@verydrunk") do
        Wait(10)
    end
    SetPedMovementClipset(ped, "move_m@drunk@verydrunk", 1.0)
    
    -- Tăng giáp tối đa 20 (không cộng dồn)
    local currentArmor = GetPedArmour(ped)
    if currentArmor < config.armorAmount then
        SetPedArmour(ped, config.armorAmount)
    end
    
    lib.notify({
        description = Config.Notify.addiction_started,
        type = 'success',
        duration = 5000
    })
    
    -- Wait for effects duration
    Wait(config.duration * 1000)
    
    -- Clear scenario
    ClearPedTasks(ped)
    
    -- Clear effects
    ClearTimecycleModifier()
    StopGameplayCamShaking(true)
    SetPedIsDrunk(ped, false)
    
    -- Reset walk style về bình thường
    ResetPedMovementClipset(ped, 0.0)
    RemoveAnimSet("move_m@drunk@verydrunk")
end)

-- Export cho ox_inventory (client-side)
exports('UseItemClient', function(data, slot)
    -- Kiểm tra blacklist zone
    if Config.Blacklist and Config.Blacklist.enabled then
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        
        for _, zone in ipairs(Config.Blacklist.zones) do
            local distance = GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, zone.coords.x, zone.coords.y, zone.coords.z, true)
            if distance <= zone.radius then
                lib.notify({
                    description = Config.Notify.blacklist_zone,
                    type = 'error',
                    duration = 5000
                })
                return -- Không cho dùng, không trừ item
            end
        end
    end
    
    -- Gọi server để kiểm tra, trừ item sấy khô và giảm độ bền điếu đu đủ
    TriggerServerEvent('F7_ladudu_addiction:server:useItem', slot)
end)

-- Bắt đầu kiểm tra cai nghiện
RegisterNetEvent('F7_ladudu_addiction:client:startAddictionMonitor', function()
    if not Config.Addiction or not Config.Addiction.enabled then
        isAddicted = false
        withdrawalActive = false
        SendNUIMessage({ action = 'hideAddictionIndicator' })
        SendNUIMessage({ action = 'setWithdrawalState', isWithdrawal = false })
        return
    end

    isAddicted = true
    
    -- Luôn hiển thị icon UI nghiện khi dính nghiện
    SendNUIMessage({ action = 'showAddictionIndicator' })
    SendNUIMessage({ action = 'setWithdrawalState', isWithdrawal = false })
    
    if Config.Debug then
        print('[DEBUG] 🟢 Bắt đầu theo dõi nghiện - withdrawalTimeSeconds: ' .. Config.Addiction.withdrawalTimeSeconds .. ' giây (' .. math.floor(Config.Addiction.withdrawalTimeSeconds/60) .. ' phút)')
    end
    
    -- Reset withdrawal state khi dùng thuốc lại
    if withdrawalActive then
        withdrawalActive = false
        SendNUIMessage({ action = 'setWithdrawalState', isWithdrawal = false })
        ClearTimecycleModifier()
        if Config.Debug then
            print('[DEBUG] ✅ Reset trạng thái withdrawal vì dùng lại')
        end
    end
    
    if withdrawalThread then return end
    
    withdrawalThread = CreateThread(function()
        while isAddicted do
            Wait(Config.Addiction.withdrawal.checkInterval * 1000)
            
            -- Lấy thời gian từ server
            local timeSince = lib.callback.await('F7_ladudu_addiction:server:getTimeSinceLast', false)
            
            if Config.Debug then
                local timeRemaining = Config.Addiction.withdrawalTimeSeconds - timeSince
                local percentProgress = (timeSince / Config.Addiction.withdrawalTimeSeconds) * 100
                print(string.format('[DEBUG] ⏱️ Kiểm tra withdrawal: %d/%d giây (%.1f%%) | Còn lại: %d giây (%d phút)', 
                    timeSince, 
                    Config.Addiction.withdrawalTimeSeconds, 
                    percentProgress,
                    math.max(0, timeRemaining),
                    math.max(0, math.floor(timeRemaining/60))
                ))
            end
            
            if timeSince >= Config.Addiction.withdrawalTimeSeconds then
                
                if not withdrawalActive then
                    withdrawalActive = true
                    SendNUIMessage({ action = 'setWithdrawalState', isWithdrawal = true })
                    if Config.Debug then
                        print('[DEBUG] 🔴 WITHDRAWAL BẮT ĐẦU! Người chơi đã vượt quá thời gian: ' .. timeSince .. ' giây')
                    end
                    lib.notify({
                        description = Config.Notify.withdrawal_active,
                        type = 'error',
                        duration = 7000
                    })
                end
                
                -- Trigger triệu chứng
                TriggerEvent('F7_ladudu_addiction:client:withdrawalTick')
            else
                if withdrawalActive then
                    withdrawalActive = false
                    SendNUIMessage({ action = 'setWithdrawalState', isWithdrawal = false })
                    ClearTimecycleModifier()
                    if Config.Debug then
                        print('[DEBUG] 🟡 Withdrawal TẮT (đã dùng lại hoặc chưa đủ thời gian)')
                    end
                end
            end
        end
        
        withdrawalThread = nil
    end)
end)

-- Triệu chứng cai nghiện (mỗi tick)
RegisterNetEvent('F7_ladudu_addiction:client:withdrawalTick', function()
    local ped = PlayerPedId()
    local config = Config.Addiction.withdrawal
    
    -- Thông báo trước
    lib.notify({
        description = Config.Notify.withdrawal_tick,
        type = 'error',
        duration = 5000
    })
    
    -- Phát âm thanh ngáp nghiện
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 6.5, "ngapnghien", 0.18)
    
    -- BẬT hiệu ứng màn hình khi có triệu chứng
    if config.screenEffects then
        SetTimecycleModifier(config.screenEffect)
    end
    
    -- Load và chờ animation
    local animDict = 'mp_safehouseshower@male@'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end
    
    -- Play animation 2 lần
    for i = 1, 2 do
        TaskPlayAnim(ped, animDict, 'male_shower_idle_a', 8.0, 8.0, -1, 1, 0, false, false, false)
        Wait(4000) -- Giữ 4 giây mỗi lần
        ClearPedTasks(ped)
        if i < 2 then
            Wait(500) -- Nghỉ 0.5 giây giữa 2 lần
        end
    end
    
    -- Clear
    ClearTimecycleModifier()
    
    -- Ragdoll (nếu bật)
    if config.ragdollEnabled and math.random(100) <= config.ragdollChance then
        SetPedToRagdoll(ped, config.ragdollDuration * 1000, config.ragdollDuration * 1000, 0, 0, 0, 0)
        lib.notify({
            description = Config.Notify.withdrawal_ragdoll,
            type = 'error'
        })
    end
end)

-- Bắt đầu cai nghiện
RegisterNetEvent('F7_ladudu_addiction:client:startRehab', function(rehabType)
    rehabType = rehabType or 'normal' -- Mặc định là cai thường
    
    if not Config.Addiction.rehab.open_rehab then
        lib.notify({
            description = 'Tính năng cai nghiện qua NPC hiện đang đóng!',
            type = 'error'
        })
        return
    end
    
    if inRehab then
        lib.notify({
            description = Config.Notify.already_in_rehab,
            type = 'error'
        })
        return
    end
    
    -- Check xem có bị nghiện không
    if not isAddicted then
        lib.notify({
            description = Config.Notify.not_addicted,
            type = 'error'
        })
        return
    end
    
    inRehab = true
    local ped = PlayerPedId()
    
    -- Teleport đến giường cai nghiện
    local bedCoords = Config.Addiction.rehab.bedCoords
    SetEntityCoords(ped, bedCoords.x, bedCoords.y, bedCoords.z, false, false, false, true)
    SetEntityHeading(ped, bedCoords.w)
    Wait(1000)
    
    -- Thông báo trói tay chân
    lib.notify({
        description = 'Đang nằm trên giường để cai nghiện an toàn...',
        type = 'inform',
        duration = 5000
    })
    
    -- Animation co giựt/quằn quại (writhe = quằn quại đau đớn)
    LoadAnimDict('combat@damage@rb_writhe')
    TaskPlayAnim(ped, 'combat@damage@rb_writhe', 'rb_writhe_loop', 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- Thread để làm hiệu ứng co giựt thêm
    local convulsing = true
    CreateThread(function()
        while convulsing do
            Wait(math.random(4000, 8000)) -- Co giựt mạnh mỗi 4-8 giây
            if convulsing then
                -- Hiệu ứng giống bị taser - co giật mạnh
                ClearPedTasksImmediately(ped)
                SetPedToRagdoll(ped, 2000, 2000, 0, true, true, false)
                
                -- Tạo hiệu ứng rung giật liên tục
                CreateThread(function()
                    for i = 1, 20 do -- Rung 20 lần
                        SetPedToRagdoll(ped, 100, 100, 0, true, true, false)
                        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.15)
                        Wait(100)
                    end
                end)
                
                Wait(2000)
                -- Quay lại quằn quại
                if convulsing then
                    TaskPlayAnim(ped, 'combat@damage@rb_writhe', 'rb_writhe_loop', 8.0, -8.0, -1, 1, 0, false, false, false)
                end
            end
        end
    end)
    
    -- Lấy config theo loại gói
    local rehabConfig = Config.Addiction.rehab[rehabType] or Config.Addiction.rehab.normal
    local duration = rehabConfig.duration * 1000
    local cost = rehabConfig.cost
    
    -- Thông báo thời gian điều trị
    lib.notify({
        description = string.format('Đang điều trị cai nghiện... Thời gian: %d giây', math.floor(duration / 1000)),
        type = 'inform',
        duration = 7000
    })
    
    -- Disable controls trong lúc cai
    CreateThread(function()
        local endTime = GetGameTimer() + duration
        while GetGameTimer() < endTime do
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 47, true) -- Detonate
            DisableControlAction(0, 140, true) -- MeleeAttackLight
            DisableControlAction(0, 141, true) -- MeleeAttackHeavy
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 257, true) -- Attack2
            DisableControlAction(0, 263, true) -- MeleeAttack1
            DisableControlAction(0, 32, true) -- W
            DisableControlAction(0, 33, true) -- S
            DisableControlAction(0, 34, true) -- A
            DisableControlAction(0, 35, true) -- D
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Jump
            Wait(5) -- Tối ưu: giảm tải CPU
        end
    end)
    
    -- Thông báo thời gian còn lại mỗi 10 giây
    CreateThread(function()
        local endTime = GetGameTimer() + duration
        while GetGameTimer() < endTime do
            local remaining = math.ceil((endTime - GetGameTimer()) / 1000)
            if remaining > 0 then
                lib.notify({
                    description = string.format('Thời gian cai nghiện còn lại: %d giây', remaining),
                    type = 'inform',
                    duration = 5000
                })
            end
            Wait(10000) -- Mỗi 10 giây
        end
    end)
    
    -- Chờ hoàn thành
    Wait(duration)
    
    -- Dừng co giựt
    convulsing = false
    ClearPedTasks(ped)
    
    -- Hoàn thành (không cần gửi cost vì đã trừ tiền rồi)
    TriggerServerEvent('F7_ladudu_addiction:server:completeRehab')
    
    inRehab = false
end)

-- Cai nghiện thành công
RegisterNetEvent('F7_ladudu_addiction:client:rehabSuccess', function()
    isAddicted = false
    SendNUIMessage({ action = 'hideAddictionIndicator' })
    lastUseTime = 0
    withdrawalActive = false
    SendNUIMessage({ action = 'setWithdrawalState', isWithdrawal = false })
    
    -- Clear effects
    ClearTimecycleModifier()
    local ped = PlayerPedId()
    SetPedIsDrunk(ped, false)
    
    -- Teleport ra ngoài
    local exitCoords = Config.Addiction.rehab.exitCoords
    SetEntityCoords(ped, exitCoords.x, exitCoords.y, exitCoords.z, false, false, false, true)
    SetEntityHeading(ped, exitCoords.w)
    
    lib.notify({
        description = Config.Notify.rehab_success,
        type = 'success',
        duration = 7000
    })
end)

-- Stop withdrawal (bác sĩ điều trị hoặc reset)
RegisterNetEvent('F7_ladudu_addiction:client:stopWithdrawal', function()
    isAddicted = false
    withdrawalActive = false
    SendNUIMessage({ action = 'hideAddictionIndicator' })
    SendNUIMessage({ action = 'setWithdrawalState', isWithdrawal = false })
    ClearTimecycleModifier()
    local ped = PlayerPedId()
    SetPedIsDrunk(ped, false)
end)

-- Hồi đầy máu (Chữa trị - $2,000)
RegisterNetEvent('mini_hethongnghien:client:fullHeal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200) -- 200 = máu đầy trong GTA V
end)

-- Sync state từ server (khi login)
RegisterNetEvent('F7_ladudu_addiction:client:syncState', function(data)
    if not Config.Addiction or not Config.Addiction.enabled then
        isAddicted = false
        withdrawalActive = false
        SendNUIMessage({ action = 'hideAddictionIndicator' })
        SendNUIMessage({ action = 'setWithdrawalState', isWithdrawal = false })
        return
    end

    isAddicted = data.isAddicted
    lastUseTime = data.lastUseTime
    withdrawalActive = data.withdrawalActive
    
    if isAddicted then
        SendNUIMessage({ action = 'showAddictionIndicator' })
        SendNUIMessage({ action = 'setWithdrawalState', isWithdrawal = (withdrawalActive or false) })
        TriggerEvent('F7_ladudu_addiction:client:startAddictionMonitor')
    else
        SendNUIMessage({ action = 'hideAddictionIndicator' })
        SendNUIMessage({ action = 'setWithdrawalState', isWithdrawal = false })
    end
end)

-- Init khi player spawn
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    TriggerServerEvent('F7_ladudu_addiction:server:requestSync')
end)

RegisterNetEvent('qbx_core:client:playerLoaded', function()
    Wait(2000)
    TriggerServerEvent('F7_ladudu_addiction:server:requestSync')
end)

-- Spawn NPC ngay khi resource start (không phụ thuộc login)
CreateThread(function()
    Wait(1000)  -- Đợi 1 giây để game load
    if Config.Addiction.rehab.open_rehab then
        SpawnRehabNPC()
        CreateRehabBlip()
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Request sync nếu đã login
    if LocalPlayer.state.isLoggedIn then
        TriggerServerEvent('F7_ladudu_addiction:server:requestSync')
    end
end)

-- Cleanup khi resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Xóa NPC
    if rehabNPC and DoesEntityExist(rehabNPC) then
        DeleteEntity(rehabNPC)
    end
    

    
    -- Xóa blip
    if rehabBlip and DoesBlipExist(rehabBlip) then
        RemoveBlip(rehabBlip)
    end
    
    ClearTimecycleModifier()
    local ped = PlayerPedId()
    SetPedIsDrunk(ped, false)
    StopGameplayCamShaking(true)
end)

-- NUI Callbacks
RegisterNUICallback('selectPackage', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
    
    local rehabType = data.type or 'normal'
    
    -- Gọi server để trừ tiền trước
    lib.callback('F7_ladudu_addiction:server:payForRehab', false, function(success, message)
        if success then
            -- Thanh toán thành công → bắt đầu cai nghiện
            lib.notify({
                description = message,
                type = 'success'
            })
            
            Wait(500)
            TriggerEvent('F7_ladudu_addiction:client:startRehab', rehabType)
        else
            -- Không đủ tiền
            lib.notify({
                description = message,
                type = 'error',
                duration = 5000
            })
        end
    end, rehabType)
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Export function cho ox_inventory khi sử dụng item dieududu
function UseItemClient(total)
    -- Item được sử dụng - trigger event để xử lý
    TriggerEvent('mini_hethongnghien:useItem', total)
    
    return true
end

-- ============================================
-- METHADONE SYSTEM (Client)
-- ============================================

local function StartMethadoneUse(slot)
    -- 1. Kiểm tra xem có bị nghiện không
    if not isAddicted then
        lib.notify({
            description = Config.Notify.methadone_not_addicted or 'Bạn không bị nghiện để sử dụng Methadone!',
            type = 'error',
            duration = 5000
        })
        return
    end

    -- 2. Chạy progress bar và animation uống nước + prop hộp thuốc
    local progressTime = Config.MethadoneProgressTime or 5000
    local success = lib.progressCircle({
        duration = progressTime,
        label = 'Đang uống Methadone...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'mp_player_intdrink',
            clip = 'loop_bottle'
        },
        prop = {
            model = `prop_ld_prescription_bottle`,
            pos = vec3(0.09, -0.02, -0.05),
            rot = vec3(-90.0, 0.0, 0.0),
            bone = 18905 -- Bàn tay phải
        }
    })

    if success then
        -- Gọi Server để trừ vật phẩm và tính tỷ lệ cai nghiện
        TriggerServerEvent('mini_hethongnghien:server:useMethadone', slot)
    else
        lib.notify({
            description = 'Đã hủy uống Methadone',
            type = 'inform'
        })
    end
end

-- Export cho ox_inventory khi sử dụng Methadone
exports('UseMethadoneClient', function(data, slot)
    StartMethadoneUse(slot)
end)

-- Event kích hoạt dùng Methadone từ Server (Qbox usable item)
RegisterNetEvent('mini_hethongnghien:client:useMethadone', function(slot)
    StartMethadoneUse(slot)
end)

-- Test commands cho UI Indicator (F8 / Chat)
RegisterCommand('testindicator', function()
    SendNUIMessage({ action = 'showAddictionIndicator' })
    SendNUIMessage({ action = 'setWithdrawalState', isWithdrawal = false })
    lib.notify({ description = '🟢 Đang test hiện UI Nghiện (Bình thường)', type = 'success' })
end, false)

RegisterCommand('testindicator_red', function()
    SendNUIMessage({ action = 'showAddictionIndicator' })
    SendNUIMessage({ action = 'setWithdrawalState', isWithdrawal = true })
    lib.notify({ description = '🔴 Đang test hiện UI Nghiện (Đỏ / Vã thuốc)', type = 'error' })
end, false)

RegisterCommand('testindicator_off', function()
    SendNUIMessage({ action = 'hideAddictionIndicator' })
    SendNUIMessage({ action = 'setWithdrawalState', isWithdrawal = false })
    lib.notify({ description = '⚪ Đã ẩn UI Nghiện', type = 'inform' })
end, false)
