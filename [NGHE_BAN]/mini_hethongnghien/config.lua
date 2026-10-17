Config = {}

Config.Debug = false -- Set true để debug

-- Item gây nghiện (phải khớp với ox_inventory)
Config.AddictiveItem = 'dieududu' -- Hoặc 'dieu_ladudu'
Config.RequiredItem = 'goi_dudu_say' -- Gói đu đủ sấy khô yêu cầu khi sử dụng

-- Cài đặt Methadone
Config.MethadoneItem = 'methadone' -- Item Methadone cai nghiện
Config.MethadoneSuccessRate = 50 -- Tỷ lệ cai nghiện thành công (50%)
Config.MethadoneProgressTime = 5000 -- Thời gian uống Methadone (ms)

-- Cài đặt nghiện
Config.Addiction = {
    enabled = false,                     -- Bật/tắt hệ thống nghiện (false: tắt hoàn toàn nghiện/vã thuốc)
    withdrawalTimeSeconds = 5400,          -- 5400 giây - thời gian bắt đầu nghiện
    
    -- Hiệu ứng khi dùng (ảo giác)
    effects = {
        duration = 30,                   -- 30 giây - thời gian hiệu ứng phê
        screenEffect = 'spectator5',     -- drug, spectator5, chop
        cameraShake = true,
        cameraShakeIntensity = 3.5,      -- Độ mạnh camera shake (1.0 = nhẹ, 3.0 = rất mạnh)
        drunk = true,                    -- Bật hiệu ứng say (màn hình mờ ảo)
        armorAmount = 20,                -- Tăng giáp tối đa 20 (không cộng dồn)
    },
    
    -- Triệu chứng cai nghiện
    withdrawal = {
        checkInterval = 60,              -- 30 giây - thời gian lập lại hành động nghiện
        
        -- Ngã lăn (ragdoll)
        ragdollEnabled = false,          -- TẮT ragdoll
        ragdollChance = 30,              -- 30% mỗi lần check
        ragdollDuration = 5,             -- 5 giây - nằm lăn
        
        -- Màn hình
        screenEffects = true,            -- Bật hiệu ứng màn hình khi có triệu chứng
        screenEffect = 'spectator5',     -- Loại hiệu ứng (drug, spectator5, chop)
        
        -- Animation ngứa người
        animations = {
            'WORLD_HUMAN_SMOKING_POT',
            'WORLD_HUMAN_DRUG_DEALER_HARD',
        }
    },
    
    -- Cai nghiện
    rehab = {
        open_rehab = false,               -- Bật/tắt tính năng cai nghiện qua NPC (true: mở, false: đóng)
        -- Gói cai nghiện thường
        normal = {
            cost = 10000,                -- $10,000
            duration = 120,               -- 90 giây
        },
        
        -- Gói cai nghiện cấp tốc
        fast = {
            cost = 20000,                -- $20,000
            duration = 60,              -- 60 giây
        },
        
        useMinigame = true,              -- Dùng skillcheck
        minigameDifficulty = {'easy', 'esaasy', 'medium'}, -- Độ khó
        
        -- NPC và vị trí
        npcModel = 's_m_m_doctor_01',
        npcCoords = vec4(312.8, -590.55, 43.27, 348.57), -- Pillbox Hospital
        
        -- Giường cai nghiện (teleport)
        bedCoords = vec4(320.65, -595.08, 43.27, 162.39),
        
        -- Vị trí sau khi cai nghiện xong
        exitCoords = vec4(318.1095, -591.5289, 43.2654, 331.8001),
        
        -- Blip
        blipEnabled = true,
        blipSprite = 403,                -- Icon bệnh viện
        blipColor = 2,                   -- Màu xanh lá
        blipScale = 0.7,
        blipLabel = 'Cai Nghiện Đu Đủ'
    }
}

-- Thông báo
Config.Notify = {
    addiction_started = 'Bạn cảm thấy phê quá... nhưng có gì đó không ổn',
    withdrawal_active = 'Người bạn ngứa ngáy, cần dùng lại hoặc đi cai nghiện!',
    withdrawal_tick = 'Người bạn ngứa ngáy, cần dùng lại hoặc đi cai nghiện!',
    withdrawal_ragdoll = 'Cơ thể bạn rã rời vì thiếu chất...',
    rehab_success = 'Bạn đã cai nghiện thành công! Hãy giữ gìn sức khỏe.',
    rehab_failed = 'Cai nghiện thất bại! Hãy thử lại.',
    not_addicted = 'Bạn không bị nghiện.',
    not_enough_money = 'Không đủ tiền cai nghiện! (Cần $10,000)',
    already_in_rehab = 'Bạn đang trong quá trình cai nghiện!',
    blacklist_zone = 'Không thể sử dụng tại khu vực này!',
    
    -- Thông báo Methadone
    methadone_success = 'Bạn đã cai nghiện thành công nhờ Methadone!',
    methadone_failed = 'Sử dụng Methadone không mang lại hiệu quả cai nghiện lần này.',
    methadone_not_addicted = 'Bạn không bị nghiện để sử dụng Methadone!'
}

-- Job Settings - Bác Sĩ
Config.Job = {
    jobName = 'ambulance',               -- Job bác sĩ (qbx_ambulancejob)
    allowedJobs = {'ambulance'},         -- Bác sĩ ambulance được điều trị cai nghiện
}

-- Khu vực bác sĩ có thể chữa trị cai nghiện (chỉ bác sĩ mới thực hiện được trong vùng này)
Config.DoctorZone = {
    coords = vec4(318.0876, -595.8604, 43.2654, 159.9755),
    radius = 10.0, -- mét, có thể chỉnh
}

-- ============================================
-- DOCTOR TREATMENT SYSTEM (Bác sĩ điều trị)
-- ============================================
Config.DoctorTreatment = {
    enabled = true,                      -- Bật/tắt tính năng bác sĩ điều trị
    
    -- Khám bệnh
    examinationDuration = 10,            -- 10 giây - thời gian khám bệnh
    
    -- Gói điều trị (2 gói như UI cũ)
    packages = {
        normal = {
            duration = 60,               -- 60 giây điều trị
            successRate = 80,            -- 80% thành công
            commission = 1500,           -- Hoa hồng bác sĩ khi thành công ($3,000)
        },
        fast = {
            duration = 30,               -- 30 giây
            successRate = 90,            -- 90% thành công
            commission = 2000,           -- Hoa hồng bác sĩ khi thành công ($5,000)
        },
    },
    
    -- Vị trí điều trị (Pillbox Hospital)
    treatmentBed = vec4(320.65, -595.08, 44.03, 162.39),     -- Giường bệnh nhân nằm
    doctorPosition = vec4(320.58, -595.69, 43.27, 71.48),    -- Vị trí bác sĩ đứng điều trị
    
    -- Khoảng cách
    targetDistance = 3.0,                -- Khoảng cách target người chơi (mét)
    maxDoctorDistance = 5.0,             -- Khoảng cách tối đa bác sĩ - bệnh nhân (mét)
    doctorDistanceTimeout = 10,          -- Thời gian cảnh báo trước khi hủy (giây)
    
    -- Thông báo
    notifications = {
        examining = 'Đang khám bệnh nhân...',
        examination_complete = 'Hoàn tất khám bệnh',
        select_package = 'Chọn gói điều trị',
        start_treatment = 'Đã bắt đầu quy trình điều trị cai nghiện',
        treatment_success = '✅ Điều trị thành công! Bệnh nhân đã hết nghiện.',
        treatment_failed = '❌ Điều trị thất bại! Hãy thử lại sau.',
        patient_not_addicted = '⚠️ Bệnh nhân này không nghiện lá đu đủ',
        not_doctor = '❌ Bạn không phải bác sĩ!',
        patient_not_enough_money = '❌ Bệnh nhân không đủ tiền!',
        doctor_too_far = '⚠️ Bác sĩ đi quá xa! Quay lại gần bệnh nhân trong %s giây!',
        treatment_cancelled_distance = '❌ Điều trị bị hủy vì bác sĩ đi xa!',
    }
}

-- Blacklist - Khu vực cấm sử dụng
Config.Blacklist = {
    enabled = true,                      -- Bật/tắt blacklist
    zones = {
        -- Ví dụ: { coords = vec4(x, y, z, heading), radius = 50.0, label = "Bệnh viện" },
        { coords = vec4(1437.37, 3144.97, 40.1, 122.97), radius = 130.0, label = "Pillbox Hospital" },
    }
}

-- ============================================
-- ACID & TRIP FX SYSTEM (Converted from mf-drugfx)
-- ============================================
Config.AcidItem = 'acid'
Config.AcidAddictionChance = 90 -- Tỷ lệ gây nghiện khi dùng Acid (90%)

Config.Acid = {
    name    = 'Acid',
    type    = 'trip',         
    quality = 1.0,
    instant = false,
    sober   = false,
    effects = {      
        move_speed    = false, 
        add_armor     = false,
        add_health    = false,
        take_armor    = false,
        take_health   = false, 
        health_regen  = false, 
    },
    animation = {
        type      = "animation",        
        dict      = 'anim@mp_player_intcelebrationmale@face_palm', 
        anim      = 'face_palm',
        blend_in  = 8.0,
        blend_out = -8.0,
        flag      = 48,
        start     = 0.2,
        prop      = 'prop_cs_pills',
        bone      = 18905,
        wait      = true,
        pos       = vector3(0.05, 0.0, 0.05)
    },
}

Config.TripPresets = {
    {
        timecycle               = 'BikerFilter',      -- main timecycle modifier
        timecycle_min_strength  = 0.2,                -- timecycle min strength
        timecycle_max_strength  = 1.5,                -- timecycle max strength

        secondary_timecycle               = false,
        secondary_timecycle_min_strength  = false,
        secondary_timecycle_max_strength  = false,   

        cam_shake               = 'DRUNK_SHAKE',      -- Cam shake
        cam_shake_min_strength  = 1.0,
        cam_shake_max_strength  = 1.5,
        motion_blur             = true,

        effect_timeout = 120 * 1000,                  -- default time for effect (ms)

        spawn_clone   = false,
        draw_toon     = {'mario'},
        toon_count    = 1,
        draw_box      = 20,
        play_song     = 'files/they-exist.mp3',
        get_wave      = true,
        song_start    = 0,
        drunk_drive   = true, 
    },
    {
        timecycle               = 'BikerFilter',     
        timecycle_min_strength  = 0.5,                
        timecycle_max_strength  = 2.0,              

        secondary_timecycle               = false,
        secondary_timecycle_min_strength  = false,   
        secondary_timecycle_max_strength  = false,              

        cam_shake               = 'DRUNK_SHAKE',    
        cam_shake_min_strength  = 1.5,              
        cam_shake_max_strength  = 2.0,            
        motion_blur             = true,            

        effect_timeout = 120 * 1000,             

        spawn_clone   = false,                 
        draw_toon     = {'luigi'},              
        toon_count    = 1,                   
        draw_box      = 20,                       
        play_song     = 'files/altar.mp3',        
        get_wave      = true,                 
        song_start    = 50,                     
        drunk_drive   = true, 
    },
    {
        timecycle               = 'BikerFilter',     
        timecycle_min_strength  = 1.0,                
        timecycle_max_strength  = 2.5,              

        secondary_timecycle               = false,
        secondary_timecycle_min_strength  = false,   
        secondary_timecycle_max_strength  = false,  

        cam_shake               = 'DRUNK_SHAKE',     
        cam_shake_min_strength  = 2.0,              
        cam_shake_max_strength  = 2.5,              
        motion_blur             = true,           

        effect_timeout = 120 * 1000,              

        spawn_clone   = true,                        
        draw_toon     = {'yoshi'},                    
        toon_count    = 1,                          
        draw_box      = 20,                         
        play_song     = 'files/gone.mp3',            
        get_wave      = true,                        
        song_start    = 0,                            
        drunk_drive   = true, 
    }
}

Config.DrivingIncidents = {
    {interaction = 07, time = 800},
    {interaction = 08, time = 800},
    {interaction = 11, time = 800},
    {interaction = 20, time = 2000},
}

