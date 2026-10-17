-- ============================================
-- DOCTOR TREATMENT SYSTEM
-- Hệ thống bác sĩ điều trị cai nghiện
-- ============================================

if not Config then return end
if not Config.DoctorTreatment then return end
if not Config.DoctorTreatment.enabled then return end
if not Config.Addiction.rehab.open_rehab then return end  -- Tắt bác sĩ khi open_rehab = false

local inTreatment = false
local currentTargetId = nil
local bypassJobCheck = false
local selectedPackage = nil
local isExamining = false
local isCarrying = false
local carriedPlayer = nil
local isTiedToBed = false
local seizureTimer = nil
local isLayingOnBed = false  -- Trạng thái bệnh nhân nằm giường
local distanceMonitorThread = nil  -- Thread theo dõi khoảng cách
local treatmentCancelled = false  -- Cờ để hủy điều trị
local patientConvulsing = false  -- Track co giật bệnh nhân

-- Forward declarations
local StartTreatment
local StartSeizure

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Check if player is doctor (giống qbx_police)
local function IsDoctor()
    -- Debug bypass
    if Config.Debug and bypassJobCheck then return true end
    
    -- Dùng QBX global như qbx_police/qbx_ambulancejob
    if not QBX or not QBX.PlayerData or not QBX.PlayerData.job then
        return false
    end
    
    local jobName = QBX.PlayerData.job.name
    local isOnDuty = QBX.PlayerData.job.onduty
    
    -- Check if job is allowed AND on duty
    for _, allowedJob in ipairs(Config.Job.allowedJobs) do
        if jobName == allowedJob and isOnDuty then
            return true
        end
    end
    
    return false
end

-- Load animation dictionary
local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end
    end
end

-- ============================================
-- CARRY SYSTEM (Vác người)
-- ============================================

-- Start carrying patient (chỉ trigger server event, let server handle)
local function StartCarrying(targetId)
    -- Chỉ verify target tồn tại và trigger server
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if not targetPed or not DoesEntityExist(targetPed) then
        lib.notify({
            description = 'Không tìm thấy bệnh nhân!',
            type = 'error'
        })
        return false
    end
    
    carriedPlayer = targetId
    
    -- Trigger server event - server sẽ handle cả 2 bên
    TriggerServerEvent('mini_hethongnghien:server:setCarried', targetId, true)
    
    return true
end

-- Stop carrying patient
local function StopCarrying()
    if not isCarrying then return end
    
    isCarrying = false
    local targetPed = GetPlayerPed(GetPlayerFromServerId(carriedPlayer))
    
    if DoesEntityExist(targetPed) then
        DetachEntity(targetPed, true, false)
        TriggerServerEvent('mini_hethongnghien:server:setCarried', carriedPlayer, false)
    end
    
    ClearPedTasks(cache.ped)
    carriedPlayer = nil
    
    lib.notify({
        description = 'Đã thả bệnh nhân xuống',
        type = 'info'
    })
end

-- ============================================
-- DOCTOR SIDE: Carrying animation (giống qbx_police)
-- ============================================
RegisterNetEvent('mini_hethongnghien:client:carryingPatient', function(state)
    if state then
        if isCarrying then return end
        
        -- Start carrying animation
        LoadAnimDict('missfinale_c2mcs_1')
        TaskPlayAnim(cache.ped, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8.0, -1, 49, 0, false, false, false)
        isCarrying = true
        
        -- Thread maintain animation + disable controls (giống qbx_police)
        CreateThread(function()
            while isCarrying do
                -- Maintain animation
                if not IsEntityPlayingAnim(cache.ped, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 3) then
                    TaskPlayAnim(cache.ped, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8.0, -1, 49, 0, false, false, false)
                end
                
                -- Disable các phím có thể làm gián đoạn (giống qbx_police)
                DisableControlAction(0, 24, true) -- Attack
                DisableControlAction(0, 25, true) -- Aim
                DisableControlAction(0, 140, true) -- Melee Attack Light
                DisableControlAction(0, 141, true) -- Melee Attack Heavy
                DisableControlAction(0, 142, true) -- Melee Attack Alternate
                DisableControlAction(0, 257, true) -- Attack 2
                DisableControlAction(0, 263, true) -- Melee Attack 1
                DisableControlAction(0, 44, true) -- Cover
                DisableControlAction(0, 37, true) -- Select Weapon
                DisableControlAction(0, 45, true) -- Reload
                DisableControlAction(0, 22, true) -- Jump
                
                Wait(5) -- Tối ưu: giảm tải CPU
            end
        end)
        
        lib.notify({
            description = '🚑 Đang vác bệnh nhân | Vác đến giường và target vào giường',
            type = 'info',
            duration = 5000
        })
    else
        -- Stop carrying
        if not isCarrying then return end
        
        isCarrying = false
        ClearPedTasks(cache.ped)
        
        lib.notify({
            description = 'Đã thả bệnh nhân xuống',
            type = 'info'
        })
    end
end)

-- ============================================
-- PATIENT SIDE: Being carried (giống qbx_police)
-- ============================================
RegisterNetEvent('mini_hethongnghien:client:setCarried', function(state, doctorId)
    if state then
        -- Bắt đầu bị vác (giống qbx_police)
        if not doctorId then return end
        
        local carrierPed = GetPlayerPed(GetPlayerFromServerId(doctorId))
        if not carrierPed or not DoesEntityExist(carrierPed) then return end
        
        -- Đảm bảo entity hiển thị
        SetEntityVisible(cache.ped, true, false)
        SetEntityAlpha(cache.ped, 255, false)
        
        -- Disable targeting và collision
        SetPedCanBeTargetted(cache.ped, false)
        SetPedCanBeTargettedByTeam(cache.ped, 0, false)
        SetPedCanBeTargettedByPlayer(cache.ped, PlayerId(), false)
        
        -- Disable collision hoàn toàn
        SetEntityCollision(cache.ped, false, false)
        SetEntityCompletelyDisableCollision(cache.ped, false, false)
        
        -- Cố định người chơi
        SetBlockingOfNonTemporaryEvents(cache.ped, true)
        SetPedCanRagdoll(cache.ped, false)
        SetPedConfigFlag(cache.ped, 32, false) -- Disable movement
        SetPedConfigFlag(cache.ped, 281, true) -- Disable ragdoll from player
        
        -- Animation người bị vác
        LoadAnimDict('nm')
        TaskPlayAnim(cache.ped, 'nm', 'firemans_carry', 8.0, -8.0, -1, 33, 0, false, false, false)
        
        -- Network sync (giống qbx_police)
        SetEntityAsMissionEntity(cache.ped, true, true)
        SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(cache.ped), true)
        NetworkSetEntityInvisibleToNetwork(cache.ped, false)
        
        -- Disable collision giữa 2 entity
        SetEntityNoCollisionEntity(cache.ped, carrierPed, true)
        SetEntityNoCollisionEntity(carrierPed, cache.ped, true)
        SetEntityCompletelyDisableCollision(cache.ped, false, true)
        
        -- Wait for doctor animation
        Wait(300)
        
        -- Attach vào doctor (giống qbx_police)
        AttachEntityToEntity(cache.ped, carrierPed, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, true, false, 2, true)
        
        -- Thread liên tục maintain attachment + disable controls (giống qbx_police)
        CreateThread(function()
            while true do
                -- Check if still being carried
                if not IsEntityAttached(cache.ped) then
                    break
                end
                
                -- Disable all controls
                DisableAllControlActions(0)
                DisableAllControlActions(1)
                DisableAllControlActions(2)
                
                -- Maintain targeting disabled
                SetPedCanBeTargetted(cache.ped, false)
                SetPedCanBeTargettedByTeam(cache.ped, 0, false)
                SetEntityCollision(cache.ped, false, false)
                
                -- Disable ragdoll
                SetPedCanRagdoll(cache.ped, false)
                SetPedToRagdoll(cache.ped, 0, 0, 0, false, false, false)
                
                -- Check and re-attach if needed (giống qbx_police)
                if DoesEntityExist(carrierPed) then
                    local currentAttached = GetEntityAttachedTo(cache.ped)
                    local isAttached = IsEntityAttached(cache.ped)
                    
                    if not isAttached or not currentAttached or not DoesEntityExist(currentAttached) or currentAttached ~= carrierPed then
                        -- Re-attach
                        DetachEntity(cache.ped, true, false)
                        Wait(10)
                        AttachEntityToEntity(cache.ped, carrierPed, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, true, false, 2, true)
                        SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(cache.ped), true)
                    end
                end
                
                -- Maintain animation
                if not IsEntityPlayingAnim(cache.ped, 'nm', 'firemans_carry', 3) then
                    TaskPlayAnim(cache.ped, 'nm', 'firemans_carry', 8.0, -8.0, -1, 33, 0, false, false, false)
                end
                
                Wait(5) -- Tối ưu: giảm tải CPU
            end
            
            -- Cleanup khi kết thúc vác
            ClearPedTasks(cache.ped)
            SetEntityCollision(cache.ped, true, true)
            SetPedCanBeTargetted(cache.ped, true)
            SetPedCanBeTargettedByTeam(cache.ped, 0, true)
            SetBlockingOfNonTemporaryEvents(cache.ped, false)
            SetPedCanRagdoll(cache.ped, true)
            SetPedConfigFlag(cache.ped, 32, true)
            SetPedConfigFlag(cache.ped, 281, false)
        end)
        
        exports.qbx_core:Notify('Bạn đang được bác sĩ vác!', 'inform')
    else
        -- Kết thúc bị vác
        ClearPedTasks(cache.ped)
        DetachEntity(cache.ped, true, false)
        
        -- Re-enable collision và targeting
        SetEntityCollision(cache.ped, true, true)
        SetPedCanBeTargetted(cache.ped, true)
        SetPedCanBeTargettedByTeam(cache.ped, 0, true)
        SetBlockingOfNonTemporaryEvents(cache.ped, false)
        SetPedCanRagdoll(cache.ped, true)
        SetPedConfigFlag(cache.ped, 32, true)
        SetPedConfigFlag(cache.ped, 281, false)
    end
end)

-- Tie patient to bed
local function TiePatientToBed()
    if not isCarrying or not carriedPlayer then
        lib.notify({
            description = '❌ Bạn phải vác bệnh nhân trước!',
            type = 'error'
        })
        return false
    end
    
    local targetPed = GetPlayerPed(GetPlayerFromServerId(carriedPlayer))
    if not DoesEntityExist(targetPed) then
        lib.notify({
            description = '❌ Không tìm thấy bệnh nhân!',
            type = 'error'
        })
        return false
    end
    
    -- Lấy vị trí giường từ config
    local bedPos = Config.DoctorTreatment.treatmentBed
    
    -- Trigger server to stop carrying (will detach patient)
    TriggerServerEvent('mini_hethongnghien:server:setCarried', carriedPlayer, false)
    
    -- Set coords after detach (thêm +0.02 z-offset giống qbx)
    Wait(100)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(carriedPlayer))
    if DoesEntityExist(targetPed) then
        SetEntityCoords(targetPed, bedPos.x, bedPos.y, bedPos.z + 0.02, false, false, false, false)
        SetEntityHeading(targetPed, bedPos.w)
    end
    
    -- Animation nằm và bị trói
    TriggerServerEvent('mini_hethongnghien:server:layOnBed', carriedPlayer)
    
    isCarrying = false
    isTiedToBed = true
    ClearPedTasks(cache.ped)
    
    lib.notify({
        description = '✅ Đã trói bệnh nhân lên giường',
        type = 'success'
    })
    
    -- Bắt đầu co giựt sau 1 giây
    Wait(1000)
    StartSeizure(carriedPlayer)
    
    carriedPlayer = nil
    return true
end

-- Bệnh nhân co giựt
StartSeizure = function(targetId)
    -- Notify bác sĩ
    lib.notify({
        description = '⚠️ Bệnh nhân bắt đầu co giựt! Bạn có 20 giây để vác và đặt lại lên giường!',
        type = 'warning',
        duration = 7000
    })
    
    -- Notify bệnh nhân
    TriggerServerEvent('mini_hethongnghien:server:startSeizure', targetId)
    
    isTiedToBed = false
    seizureTimer = 20
    
    -- Countdown timer
    CreateThread(function()
        while seizureTimer > 0 and inTreatment do
            Wait(1000)
            seizureTimer = seizureTimer - 1
            
            if seizureTimer == 10 then
                lib.notify({
                    description = '⏰ Còn 10 giây!',
                    type = 'warning'
                })
            elseif seizureTimer == 5 then
                lib.notify({
                    description = '🚨 Còn 5 giây! Nhanh lên!',
                    type = 'error'
                })
            end
        end
        
        -- Timeout - điều trị thất bại
        if seizureTimer <= 0 and inTreatment and not isTiedToBed then
            lib.notify({
                description = '❌ Hết thời gian! Điều trị thất bại vì không đặt bệnh nhân lên giường kịp!',
                type = 'error',
                duration = 7000
            })
            
            -- Stop seizure
            TriggerServerEvent('mini_hethongnghien:server:stopSeizure', targetId)
            
            -- Cancel treatment
            inTreatment = false
            currentTargetId = nil
            selectedPackage = nil
            isTiedToBed = false
            
            TriggerServerEvent('mini_hethongnghien:server:completeTreatment', targetId, false, selectedPackage)
        end
    end)
end

-- Đặt bệnh nhân lại lên giường (sau khi co giựt)
local function PlaceBackOnBed()
    if not isCarrying or not carriedPlayer then
        lib.notify({
            description = '❌ Bạn phải vác bệnh nhân trước!',
            type = 'error'
        })
        return false
    end
    
    local targetPed = GetPlayerPed(GetPlayerFromServerId(carriedPlayer))
    if not DoesEntityExist(targetPed) then
        lib.notify({
            description = '❌ Không tìm thấy bệnh nhân!',
            type = 'error'
        })
        return false
    end
    
    local bedPos = Config.DoctorTreatment.treatmentBed
    
    -- Trigger server to stop carrying (will detach patient)
    TriggerServerEvent('mini_hethongnghien:server:setCarried', carriedPlayer, false)
    
    -- Set coords after detach (thêm +0.02 z-offset giống qbx)
    Wait(100)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(carriedPlayer))
    if DoesEntityExist(targetPed) then
        SetEntityCoords(targetPed, bedPos.x, bedPos.y, bedPos.z + 0.02, false, false, false, false)
        SetEntityHeading(targetPed, bedPos.w)
    end
    
    -- Stop seizure và cho nằm yên
    TriggerServerEvent('mini_hethongnghien:server:layOnBed', carriedPlayer)
    TriggerServerEvent('mini_hethongnghien:server:stopSeizure', carriedPlayer)
    
    isCarrying = false
    isTiedToBed = true
    ClearPedTasks(cache.ped)
    
    lib.notify({
        description = '✅ Đã đặt bệnh nhân lên giường! Bắt đầu điều trị...',
        type = 'success'
    })
    
    -- Stop timer
    seizureTimer = 0
    
    -- Bắt đầu điều trị sau 1 giây
    Wait(1000)
    PerformTreatment(carriedPlayer)
    
    carriedPlayer = nil
    return true
end

RegisterNetEvent('mini_hethongnghien:client:layOnBed', function(bedCoords)
    isLayingOnBed = true
    
    -- Sử dụng bedCoords từ parameter hoặc fallback to config
    local bedPos = bedCoords or Config.DoctorTreatment.treatmentBed
    
    -- Clear animation cũ
    ClearPedTasksImmediately(cache.ped)
    Wait(100)
    
    -- Force coords (giống qbx_ambulancejob)
    SetEntityCoords(cache.ped, bedPos.x, bedPos.y, bedPos.z, true, true, true, false)
    SetEntityHeading(cache.ped, bedPos.w)
    
    -- Không freeze để bệnh nhân có thể co giật tự nhiên
    
    -- Animation quằn quại (giống hệ thống cai nghiện NPC)
    LoadAnimDict('combat@damage@rb_writhe')
    TaskPlayAnim(cache.ped, 'combat@damage@rb_writhe', 'rb_writhe_loop', 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- Thread maintain animation (giống qbx)
    CreateThread(function()
        while isLayingOnBed do
            -- Disable movement controls
            DisableControlAction(0, 73, true) -- X - disable get up
            DisableControlAction(0, 32, true) -- W
            DisableControlAction(0, 33, true) -- S
            DisableControlAction(0, 34, true) -- A
            DisableControlAction(0, 35, true) -- D
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 47, true) -- G
            DisableControlAction(0, 22, true) -- Jump
            
            Wait(5) -- Tối ưu: giảm tải CPU
        end
    end)
    
    -- Thread maintain position + animation (giống qbx_ambulancejob) - kiểm tra mỗi 500ms
    CreateThread(function()
        while isLayingOnBed do
            if not IsEntityPlayingAnim(cache.ped, 'combat@damage@rb_writhe', 'rb_writhe_loop', 3) then
                ClearPedTasksImmediately(cache.ped)
                TaskPlayAnim(cache.ped, 'combat@damage@rb_writhe', 'rb_writhe_loop', 8.0, -8.0, -1, 1, 0, false, false, false)
                -- Không force position để bệnh nhân co giật tự nhiên
            end
            Wait(500)
        end
    end)
end)

-- Patient seizure animation (co giựt)
RegisterNetEvent('mini_hethongnghien:client:seizure', function()
    CreateThread(function()
        local animDict = 'misscarsteal4@actor'
        LoadAnimDict(animDict)
        
        while seizureTimer and seizureTimer > 0 do
            -- Random twitching animation
            TaskPlayAnim(cache.ped, animDict, 'stumble', 8.0, -8.0, -1, 1, 0, false, false, false)
            Wait(math.random(500, 1500))
            
            -- Apply random force
            ApplyForceToEntity(cache.ped, 1, 
                math.random(-1, 1) * 0.5, 
                math.random(-1, 1) * 0.5, 
                0.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
        end
        
        ClearPedTasks(cache.ped)
    end)
end)

-- Stop seizure
RegisterNetEvent('mini_hethongnghien:client:stopSeizure', function()
    seizureTimer = 0
    ClearPedTasks(cache.ped)
end)

-- ============================================
-- TREATMENT PROCESS (Quy trình điều trị)
-- ============================================

-- Examine Patient (Khám bệnh)
local function ExaminePatient(targetId)
    if isExamining or inTreatment then
        lib.notify({
            description = '⚠️ Bạn đang bận!',
            type = 'error'
        })
        return
    end
    
    if not IsDoctor() then
        lib.notify({
            description = Config.DoctorTreatment.notifications.not_doctor,
            type = 'error'
        })
        return
    end

    -- Kiểm tra bác sĩ phải đứng trong bán kính 5m từ giường
    local bedPos = Config.DoctorTreatment.treatmentBed
    local doctorPos = GetEntityCoords(cache.ped)
    local distToBed = #(doctorPos - vector3(bedPos.x, bedPos.y, bedPos.z))
    if distToBed > 3.0 then
        lib.notify({
            description = '❌ Lại gần giường bệnh viện để cai nghiện cho bệnh nhân! (Trong vòng 3m)',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    isExamining = true
    
    -- Animation khám bệnh (đứng cầm clipboard)
    LoadAnimDict('amb@world_human_clipboard@male@idle_a')
    TaskPlayAnim(cache.ped, 'amb@world_human_clipboard@male@idle_a', 'idle_c', 8.0, -8.0, -1, 49, 0, false, false, false)
    
    lib.notify({
        description = Config.DoctorTreatment.notifications.examining,
        type = 'info'
    })
    
    -- Progress bar khám bệnh 10s
    if lib.progressCircle({
        duration = Config.DoctorTreatment.examinationDuration * 1000,
        label = 'Đang khám bệnh nhân...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
    }) then
        ClearPedTasks(cache.ped)
        
        -- Check if target is addicted
        lib.callback('mini_hethongnghien:server:isAddicted', false, function(isAddicted)
            isExamining = false
            
            if not isAddicted then
                lib.notify({
                    description = Config.DoctorTreatment.notifications.patient_not_addicted,
                    type = 'error',
                    duration = 5000
                })
                return
            end
            
            -- Bệnh nhân bị nghiện → Hiện menu chọn gói điều trị
            lib.notify({
                description = Config.DoctorTreatment.notifications.examination_complete,
                type = 'success'
            })
            
            Wait(500)
            
            -- Hiện menu chọn gói bằng ox_lib menu
            local menuOptions = {}
            
            for packageType, packageData in pairs(Config.DoctorTreatment.packages) do
                local packageName = packageType == 'normal' and 'Gói Thường' or 'Gói Nhanh'
                
                -- Lấy thông tin từ Config.Addiction.rehab
                local rehabInfo = Config.Addiction.rehab[packageType]
                local cost = rehabInfo and rehabInfo.cost or 0
                local duration = rehabInfo and rehabInfo.duration or 0
                
                local description = string.format(
                    '💰 Giá: $%s | ⏱️ Thời gian: %ds | 🎯 Tỷ lệ: %d%%',
                    cost,
                    duration,
                    packageData.successRate
                )
                
                table.insert(menuOptions, {
                    title = packageName,
                    description = description,
                    icon = packageType == 'normal' and 'fa-solid fa-heartbeat' or 'fa-solid fa-bolt',
                    onSelect = function()
                        -- Kiểm tra tiền bệnh nhân trước khi làm bất cứ điều gì
                        lib.callback('mini_hethongnghien:server:checkPatientMoney', false, function(hasMoney, cost)
                            if not hasMoney then
                                lib.notify({
                                    description = string.format('❌ Bệnh nhân không đủ tiền! Cần $%s để cai nghiện gói này.', cost),
                                    type = 'error',
                                    duration = 6000
                                })
                                return
                            end
                            StartTreatment(targetId, packageType)
                        end, targetId, packageType)
                    end
                })
            end
            
            -- Thêm nút hủy
            table.insert(menuOptions, {
                title = '❌ Hủy',
                description = 'Không điều trị',
                icon = 'fa-solid fa-times',
            })
            
            lib.registerContext({
                id = 'doctor_treatment_packages',
                title = '💊 Chọn Gói Điều Trị',
                options = menuOptions
            })
            
            lib.showContext('doctor_treatment_packages')
        end, targetId)
    else
        -- Cancelled
        ClearPedTasks(cache.ped)
        isExamining = false
        lib.notify({
            description = '❌ Đã hủy khám bệnh',
            type = 'error'
        })
    end
end

-- Setup ox_target cho giường (khi bác sĩ đang vác)
local function SetupBedTarget()
    local bedPos = Config.DoctorTreatment.treatmentBed
    
    exports.ox_target:addSphereZone({
        name = 'doctor_treatment_bed_first',
        coords = vec3(bedPos.x, bedPos.y, bedPos.z),
        radius = 2.0,
        options = {
            {
                name = 'tie_patient_to_bed',
                icon = 'fa-solid fa-bed',
                label = 'Trói bệnh nhân vào giường',
                canInteract = function()
                    return isCarrying
                end,
                onSelect = function()
                    if TiePatientToBed() then
                        exports.ox_target:removeZone('doctor_treatment_bed_first')
                        Wait(1000)
                        StartSeizure(currentTargetId)
                    end
                end
            }
        }
    })
end

-- Setup ox_target cho giường lần 2 (sau khi vác lại)
local function SetupBedTargetSecondTime()
    local bedPos = Config.DoctorTreatment.treatmentBed
    
    exports.ox_target:addSphereZone({
        name = 'doctor_treatment_bed_second',
        coords = vec3(bedPos.x, bedPos.y, bedPos.z),
        radius = 2.0,
        options = {
            {
                name = 'place_patient_back',
                icon = 'fa-solid fa-bed-pulse',
                label = 'Đặt bệnh nhân lên giường',
                canInteract = function()
                    return isCarrying
                end,
                onSelect = function()
                    PlaceBackOnBed()
                    -- Remove bed target
                    exports.ox_target:removeZone('doctor_treatment_bed_second')
                end
            }
        }
    })
end

-- Start treatment process (sau khi chọn gói)
StartTreatment = function(targetId, packageType)
    if inTreatment then
        lib.notify({
            description = '⚠️ Bạn đang trong quá trình điều trị!',
            type = 'error'
        })
        return
    end
    
    if not IsDoctor() then
        lib.notify({
            description = Config.DoctorTreatment.notifications.not_doctor,
            type = 'error'
        })
        return
    end
    
    -- Kiểm tra khoảng cách ban đầu
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if not targetPed or not DoesEntityExist(targetPed) then
        lib.notify({
            description = '❌ Không tìm thấy bệnh nhân!',
            type = 'error'
        })
        return
    end
    
    local doctorCoords = GetEntityCoords(cache.ped)
    local patientCoords = GetEntityCoords(targetPed)
    local distance = #(doctorCoords - patientCoords)
    
    if distance > (Config.DoctorTreatment.maxDoctorDistance or 5.0) then
        lib.notify({
            description = '❌ Bạn đang đứng quá xa bệnh nhân! Hãy đến gần hơn.',
            type = 'error'
        })
        return
    end
    
    selectedPackage = packageType
    currentTargetId = targetId
    treatmentCancelled = false
    
    lib.notify({
        description = '💰 Đang kiểm tra tiền bệnh nhân...',
        type = 'info'
    })
    
    -- Gọi callback server để trừ tiền bệnh nhân và teleport
    lib.callback('mini_hethongnghien:server:payForPatient', false, function(success, message)
        if not success then
            lib.notify({
                description = message or Config.DoctorTreatment.notifications.patient_not_enough_money,
                type = 'error',
                duration = 7000
            })
            selectedPackage = nil
            currentTargetId = nil
            return
        end
        
        -- Thành công - bệnh nhân đã được teleport lên giường bởi server
        inTreatment = true
        
        lib.notify({
            description = '✅ Đã trừ tiền bệnh nhân thành công! Bắt đầu điều trị...',
            type = 'success',
            duration = 5000
        })
        
        -- Bắt đầu thread kiểm tra khoảng cách
        if distanceMonitorThread then
            distanceMonitorThread = nil
        end
        
        distanceMonitorThread = CreateThread(function()
            local warningTime = 0
            local isWarning = false
            local maxDistance = Config.DoctorTreatment.maxDoctorDistance or 5.0
            local timeout = Config.DoctorTreatment.doctorDistanceTimeout or 10
            
            while inTreatment and not treatmentCancelled do
                Wait(1000) -- Kiểm tra mỗi giây
                
                local targetPedCheck = GetPlayerPed(GetPlayerFromServerId(targetId))
                if not targetPedCheck or not DoesEntityExist(targetPedCheck) then
                    break
                end
                
                local doctorPos = GetEntityCoords(cache.ped)
                local patientPos = GetEntityCoords(targetPedCheck)
                local dist = #(doctorPos - patientPos)
                
                if dist > maxDistance then
                    if not isWarning then
                        -- Bắt đầu cảnh báo
                        isWarning = true
                        warningTime = 0
                        
                        lib.notify({
                            description = string.format(Config.DoctorTreatment.notifications.doctor_too_far, timeout),
                            type = 'error',
                            duration = timeout * 1000
                        })
                    else
                        -- Tăng thời gian cảnh báo
                        warningTime = warningTime + 1
                        
                        if warningTime >= timeout then
                            -- Hết thời gian - hủy điều trị
                            treatmentCancelled = true
                            inTreatment = false
                            
                            lib.notify({
                                description = Config.DoctorTreatment.notifications.treatment_cancelled_distance,
                                type = 'error',
                                duration = 7000
                            })
                            
                            -- Dừng co giật bệnh nhân
                            TriggerServerEvent('mini_hethongnghien:server:stopPatientSeizure', targetId)
                            
                            -- Thông báo cho bệnh nhân
                            TriggerServerEvent('mini_hethongnghien:server:cancelTreatment', targetId)
                            
                            -- Clean up
                            ClearPedTasks(cache.ped)
                            selectedPackage = nil
                            currentTargetId = nil
                            distanceMonitorThread = nil
                            
                            break
                        end
                    end
                else
                    -- Bác sĩ quay lại gần - reset cảnh báo
                    if isWarning then
                        isWarning = false
                        warningTime = 0
                        
                        lib.notify({
                            description = '✅ Bác sĩ đã quay lại gần bệnh nhân',
                            type = 'success'
                        })
                    end
                end
            end
            
            distanceMonitorThread = nil
        end)
        
        -- Chờ 1 giây rồi bắt đầu điều trị
        Wait(1000)
        
        if not treatmentCancelled then
            PerformTreatment(targetId)
        end
    end, targetId, packageType)
end

-- Perform treatment on patient (sử dụng package đã chọn)
function PerformTreatment(targetId)
    if not inTreatment or treatmentCancelled then return end
    if not selectedPackage then
        lib.notify({
            description = '❌ Lỗi: Chưa chọn gói điều trị!',
            type = 'error'
        })
        return
    end
    
    local packageConfig = Config.DoctorTreatment.packages[selectedPackage]
    if not packageConfig then
        lib.notify({
            description = '❌ Lỗi: Gói điều trị không hợp lệ!',
            type = 'error'
        })
        return
    end
    
    -- Lấy duration từ Config.DoctorTreatment.packages (thời gian điều trị của bác sĩ)
    local rehabConfig = Config.DoctorTreatment.packages[selectedPackage]
    if not rehabConfig then
        lib.notify({
            description = '❌ Lỗi: Không tìm thấy cấu hình gói cai nghiện!',
            type = 'error'
        })
        return
    end
    
    lib.notify({
        description = '💉 Đang tiến hành điều trị gói ' .. (selectedPackage == 'normal' and 'Thường' or 'Nhanh') .. '...',
        type = 'info'
    })
    
    -- Đợi bệnh nhân teleport xong trước khi bắt đầu co giật
    Wait(500)
    
    -- Trigger server để bắt đầu co giật cho bệnh nhân
    TriggerServerEvent('mini_hethongnghien:server:startPatientSeizure', targetId, rehabConfig.duration)
    
    -- Đợi thêm chút để bệnh nhân bắt đầu co giật
    Wait(500)
    
    -- Doctor treatment animation (đứng điều trị)
    LoadAnimDict('amb@world_human_clipboard@male@idle_a')
    TaskPlayAnim(cache.ped, 'amb@world_human_clipboard@male@idle_a', 'idle_c', 8.0, -8.0, -1, 49, 0, false, false, false)
    
    -- Treatment progress bar (dùng duration từ Config.Addiction.rehab)
    local duration = rehabConfig.duration * 1000
    
    -- Thread monitor để hủy progressbar khi treatmentCancelled = true
    local progressMonitor = CreateThread(function()
        while not treatmentCancelled do
            Wait(100)
        end
        
        -- Hủy progressbar khi bác sĩ đi xa
        if treatmentCancelled then
            exports['ox_lib']:cancelProgress()
            ClearPedTasks(cache.ped)
        end
    end)
    
    if lib.progressBar({
        duration = duration,
        label = 'Đang điều trị cai nghiện...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = false,
            car = true,
            combat = true,
        },
    }) then
        if treatmentCancelled then
            ClearPedTasks(cache.ped)
            return
        end
        
        ClearPedTasks(cache.ped)
        
        -- Calculate success (dùng successRate từ package)
        local success = math.random(1, 100) <= packageConfig.successRate
        
        -- Complete treatment (gửi cả package để server tính reward)
        TriggerServerEvent('mini_hethongnghien:server:completeTreatment', targetId, success, selectedPackage)
        
        lib.notify({
            description = success and Config.DoctorTreatment.notifications.treatment_success or Config.DoctorTreatment.notifications.treatment_failed,
            type = success and 'success' or 'error',
            duration = 7000
        })
    else
        -- Progressbar bị cancel
        ClearPedTasks(cache.ped)
    end
    
    -- Cleanup
    inTreatment = false
    currentTargetId = nil
    selectedPackage = nil
    isTiedToBed = false
    seizureTimer = nil
    treatmentCancelled = false
    
    -- Stop distance monitor thread
    if distanceMonitorThread then
        distanceMonitorThread = nil
    end
end

-- ============================================
-- OX_TARGET INTEGRATION (theo cách QBX)
-- ============================================

local function setupOxTarget()
    local success, err = pcall(function()
        exports.ox_target:addGlobalPlayer({
            {
                name = 'doctor_examine_patient',
                icon = 'fa-solid fa-syringe',
                label = 'Cai Nghiện cho bệnh nhân',
                distance = Config.DoctorTreatment.targetDistance or 3.0,
                canInteract = function(entity, distance, coords, name, bone)
                    if inTreatment or isExamining then return false end
                    return IsDoctor()
                end,
                onSelect = function(data)
                    local targetPed = data.entity
                    if not targetPed or not DoesEntityExist(targetPed) then
                        lib.notify({
                            description = '❌ Không tìm thấy người chơi!',
                            type = 'error'
                        })
                        return
                    end
                    
                    local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
                    if not targetId or targetId == 0 then
                        lib.notify({
                            description = '❌ Không tìm thấy ID người chơi!',
                            type = 'error'
                        })
                        return
                    end
                    
                    ExaminePatient(targetId)
                end
            },
            {
                name = 'doctor_carry_patient',
                icon = 'fa-solid fa-hand-holding-medical',
                label = 'Vác bệnh nhân cai nghiện',
                distance = Config.DoctorTreatment.targetDistance or 3.0,
                canInteract = function(entity, distance, coords, name, bone)
                    -- Hiện khi: onduty + đã chọn gói + chưa vác + đúng bệnh nhân
                    if not IsDoctor() or not inTreatment or isCarrying or isTiedToBed then return false end
                    
                    local targetPed = entity
                    if not targetPed or not DoesEntityExist(targetPed) then return false end
                    
                    local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
                    return targetId == currentTargetId
                end,
                onSelect = function(data)
                    local targetPed = data.entity
                    if not targetPed or not DoesEntityExist(targetPed) then
                        lib.notify({
                            description = '❌ Không tìm thấy người chơi!',
                            type = 'error'
                        })
                        return
                    end
                    
                    local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
                    if not targetId or targetId == 0 then
                        lib.notify({
                            description = '❌ Không tìm thấy ID người chơi!',
                            type = 'error'
                        })
                        return
                    end
                    
                    if StartCarrying(targetId) then
                        -- Check nếu đang co giựt (lần 2) hoặc lần đầu
                        if seizureTimer and seizureTimer > 0 then
                            SetupBedTargetSecondTime()
                        else
                            SetupBedTarget()
                        end
                    end
                end
            }
        })
    end)
end

-- Setup khi player load (spawn/relog)
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    setupOxTarget()
end)

-- Setup ngay khi resource start (nếu player đã logged in)
CreateThread(function()
    Wait(3000)
    if QBX and QBX.PlayerData and QBX.PlayerData.citizenid then
        setupOxTarget()
    end
end)

-- ============================================
-- TELEPORT EVENT (from server)
-- ============================================

RegisterNetEvent('mini_hethongnghien:client:teleportToBed', function(bedCoords)
    local ped = cache.ped
    if not ped then return end
    
    SetEntityCoords(ped, bedCoords.x, bedCoords.y, bedCoords.z, false, false, false, false)
    SetEntityHeading(ped, bedCoords.w)
    
    lib.notify({
        description = '🏥 Bạn được chuyển đến khu điều trị',
        type = 'info'
    })
end)

-- Stand up from bed after treatment
RegisterNetEvent('mini_hethongnghien:client:standUp', function()
    isLayingOnBed = false
    FreezeEntityPosition(cache.ped, false)
    ClearPedTasks(cache.ped)
    lib.notify({
        description = '✅ Bạn có thể đứng dậy rồi',
        type = 'success'
    })
end)

-- ============================================
-- PATIENT SEIZURE DURING TREATMENT (giống cai nghiện NPC)
-- ============================================

RegisterNetEvent('mini_hethongnghien:client:startTreatmentSeizure', function(duration)
    local ped = cache.ped
    if not ped then return end
    
    -- Thông báo bắt đầu điều trị
    lib.notify({
        description = '🏥 Đang nằm trên giường để cai nghiện an toàn...',
        type = 'inform',
        duration = 5000
    })
    
    -- Clear animation cũ (nếu có)
    ClearPedTasksImmediately(ped)
    Wait(100)
    
    -- Animation co giựt/quằn quại (writhe = quằn quại đau đớn)
    RequestAnimDict('combat@damage@rb_writhe')
    while not HasAnimDictLoaded('combat@damage@rb_writhe') do
        Wait(10)
    end
    TaskPlayAnim(ped, 'combat@damage@rb_writhe', 'rb_writhe_loop', 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- Thread để làm hiệu ứng co giựt thêm
    patientConvulsing = true
    CreateThread(function()
        while patientConvulsing do
            Wait(math.random(4000, 8000)) -- Co giựt mạnh mỗi 4-8 giây
            if patientConvulsing then
                -- Hiệu ứng giống bị taser - co giật mạnh
                ClearPedTasksImmediately(ped)
                SetPedToRagdoll(ped, 2000, 2000, 0, true, true, false)
                
                -- Tạo hiệu ứng rung giật liên tục
                CreateThread(function()
                    for i = 1, 20 do -- Rung 20 lần
                        if not patientConvulsing then break end
                        SetPedToRagdoll(ped, 100, 100, 0, true, true, false)
                        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.15)
                        Wait(100)
                    end
                end)
                
                Wait(2000)
                -- Quay lại quằn quại
                if patientConvulsing then
                    TaskPlayAnim(ped, 'combat@damage@rb_writhe', 'rb_writhe_loop', 8.0, -8.0, -1, 1, 0, false, false, false)
                end
            end
        end
    end)
    
    -- Thông báo thời gian điều trị
    lib.notify({
        description = string.format('Đang điều trị cai nghiện... Thời gian: %d giây', duration),
        type = 'inform',
        duration = 7000
    })
    
    -- Disable controls trong lúc điều trị
    CreateThread(function()
        local endTime = GetGameTimer() + (duration * 1000)
        while GetGameTimer() < endTime and patientConvulsing do
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
            Wait(5)
        end
    end)
    
    -- Thông báo thời gian còn lại mỗi 10 giây
    CreateThread(function()
        local endTime = GetGameTimer() + (duration * 1000)
        while GetGameTimer() < endTime and patientConvulsing do
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
    Wait(duration * 1000)
    
    -- Dừng co giựt
    patientConvulsing = false
    ClearPedTasks(ped)
    
    lib.notify({
        description = '✅ Đã hoàn thành điều trị!',
        type = 'success'
    })
end)

-- Event: Stop patient seizure (khi bác sĩ hủy điều trị)
RegisterNetEvent('mini_hethongnghien:client:stopTreatmentSeizure', function()
    -- Dừng co giật
    patientConvulsing = false
    ClearPedTasks(cache.ped)
    
    lib.notify({
        description = '❌ Điều trị bị hủy!',
        type = 'error',
        duration = 5000
    })
end)

-- ============================================
-- CLEANUP
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isCarrying and carriedPlayer then
        -- Trigger server to stop carrying
        TriggerServerEvent('mini_hethongnghien:server:setCarried', carriedPlayer, false)
    end
    
    if inTreatment then
        inTreatment = false
    end
end)
