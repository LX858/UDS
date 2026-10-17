Config = {}

-- ====================================================================
-- CẤU HÌNH VỊ TRÍ (COORDINATES)
-- ====================================================================
-- Danh sách các vị trí quỳ khấn vái lạy, lu hương & hiệu ứng pháo sáng ở tường lu hương
Config.Locations = {
    {
        prayPos = vector4(174.2592, -990.2649, 32.4664, 158.0184),
        burnerPos = vector4(173.7197, -992.1871, 32.4664, 157.6191),
         ptfxPos = vector4(173.2222, -993.4399, 32.6067, 335.3998)
        
    },
    {
        prayPos = vector4(175.8036, -990.1749, 32.4664, 157.6080),
        burnerPos = vector4(174.8324, -992.8548, 32.4664, 161.7784),
       ptfxPos = vector4(174.4960, -994.1761, 32.8322, 354.6909)
    },
    {
        prayPos = vector4(173.1930, -989.2941, 32.4664, 159.1574),
        burnerPos = vector4(172.1977, -991.9748, 32.4664, 159.2811), 
        ptfxPos = vector4(171.8833, -993.0898, 33.0006, 341.1471)
    }
}

-- Khoảng cách cho phép tương tác (mét)
Config.InteractDistance = 1.5

-- Phím bấm tương tác (Mặc định 38 = Phím E)
Config.InteractKey = 38
Config.InteractKeyLabel = '~g~[E]~s~ Thắp hương khấn vái'

-- ====================================================================
-- CẤU HÌNH THỜI GIAN & HÀNH ĐỘNG (ANIMATIONS & TIMINGS)
-- ====================================================================
-- Thời gian quỳ vái lạy (giây) - Đếm ngược 10s trên progress bar
Config.PrayDuration = 5

-- Cấu hình Scenario / Animation quỳ vái lạy (Dùng Yoga Scenario)
Config.YogaScenario = 'WORLD_HUMAN_YOGA'

-- Cấu hình Animation dự phòng (nếu không dùng Scenario)
Config.YogaAnimDict = 'amb@world_human_yoga@female@base'
Config.YogaAnimName = 'yoga_pose1'

-- Cấu hình Animation thắp hương ở lu hương
Config.ThapHuongAnimDict = 'amb@medic@standing@kneel@base'
Config.ThapHuongAnimName = 'base'
Config.ThapHuongDuration = 2 * 1000 -- Miligiây (4 giây thắp hương ở lu)

-- Cấu hình vị trí & góc xoay cầm cây hương trên tay (Hand Bone, Offset & Rotation)
Config.IncenseBone = 57005                              -- 57005 (SKEL_R_Hand - Tay phải)
Config.IncenseOffset = vector3(0.12, 0.02, -0.02)       -- Tọa độ offset (X, Y, Z)
Config.IncenseRotation = vector3(-90.0, 0.0, 0.0)       -- Góc xoay (Pitch, Roll, Yaw) để cây hương hướng đúng

-- ====================================================================
-- CẤU HÌNH HIỆU ỨNG & ÂM THANH (PTFX & AUDIO)
-- ====================================================================
-- Bật/Tắt hiệu ứng khói bay ra ở lu hương khi thắp
Config.EnableSmokeEffect = true
Config.SmokePtfxAsset = 'core'
Config.SmokePtfxName = 'proj_flare_fuse'

-- Âm lượng nhạc chùa (0.0 đến 1.0)
Config.SoundVolume = 0.3

-- ====================================================================
-- CẤU HÌNH VẬT PHẨM YÊU CẦU & LOẠI HƯƠNG (INCENSE TYPES)
-- ====================================================================
Config.RequireItem = true            -- Bật/tắt yêu cầu cần vật phẩm để thắp hương
Config.RemoveItemOnPray = true       -- Trừ nén hương khi thắp hương thành công
Config.DefaultIncenseType = 'cay_huong'

-- Danh sách 2 loại nén hương
Config.IncenseTypes = {
    ['cay_huong'] = {
        label = 'Cây hương',
        propModel = `jr_nhanhuonglv1`,
        reputationGain = 1,
        amount = 1
    },
    ['cay_huong_luxury'] = {
        label = 'Cây hương cao cấp',
        propModel = `jr_nhanhuonglv3`,
        reputationGain = 20,
        amount = 1
    }
}

-- Prop Nén Hương mặc định dự phòng
Config.IncensePropModel = `jr_nhanhuonglv1`

-- ====================================================================
-- CẤU HÌNH ĐIỂM UY TÍN (REPUTATION SYSTEM)
-- ====================================================================
Config.ReputationSystem = {
    defaultReputation = 100,     -- Điểm mặc định khi chưa có dữ liệu trong DB
    maxReputation = 100        -- Điểm uy tín tối đa
}

-- ====================================================================
-- THÔNG BÁO (NOTIFICATIONS)
-- ====================================================================
Config.Notify = function(msg, type)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end
