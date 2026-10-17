Config = {}

-- Debug mode
Config.Debug = false -- Bật/tắt debug logs

-- Cấu hình thời gian ngủ động
Config.SleepTimeCalculation = {
    enabled = true,                    -- Bật tính toán thời gian ngủ động
    timePerPercent = 1.8,             -- Thời gian (giây) cho mỗi 1% sleepiness
    maxSleepTime = 90,               -- Thời gian tối đa để ngủ từ 0% -> 100% (3 phút)
    minSleepTime = 5,                 -- Thời gian tối thiểu để ngủ (5 giây)
}

-- Thời gian ngủ (tính bằng giây) - Chỉ dùng khi SleepTimeCalculation.enabled = false
Config.SleepDuration = 6 -- 1 phút

-- Model khi ngủ
Config.SleepModel = 'xm_prop_body_bag'

-- Lượng sleepiness tăng sau khi ngủ
Config.SleepinessIncrease = 100

-- Animation cho việc ngủ
Config.SleepAnimation = {
    dict = 'timetable@tracy@sleep@',
    anim = 'idle_c'
}

-- Cấu hình progressbar
Config.ProgressBar = {
    duration = 60000, -- 60 giây tính bằng milliseconds (chỉ dùng khi SleepTimeCalculation.enabled = false)
    label = 'Đang ngủ...',
    useWhileDead = false,
    canCancel = true,
    disable = {
        car = true,
        move = true,
        combat = true,
        mouse = false,
    },
    anim = {
        dict = 'timetable@tracy@sleep@',
        clip = 'idle_c',
        flag = 49,
    },
}

-- Vị trí có thể ngủ (có thể mở rộng)
-- Body bag sẽ được tạo tại vị trí coords này, không phải vị trí của player
-- LƯU Ý: Để tránh bị đặt trên mái nhà, hãy đặt UseExactCoords = true
Config.SleepLocations = {
    -- thanh pho
    -- {
    --     coords = vec4(328.43, -601.61, 48.28, 64.24), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Giường bệnh viện 1",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     jobs = {'ambulance'}, -- Chỉ job bác sĩ mới target được (phải là table)
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- {
    --     coords = vec4(317.16, -597.35, 48.28, 71.39), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Giường bệnh viện 2",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     jobs = {'ambulance'}, -- Chỉ job bác sĩ mới target được (phải là table)
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- {
    --     coords = vec4(322.63, -599.42, 48.27, 65.04), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Giường bệnh viện 3",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     jobs = {'ambulance'}, -- Chỉ job bác sĩ mới target được (phải là table)
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- {
    --     coords = vec4(336.52, -575.1, 47.28, 333.97-90), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Giường bệnh viện 4",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     jobs = {'ambulance'}, -- Chỉ job bác sĩ mới target được (phải là table)
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- samac
    -- {
    --     coords = vec4(1775.98, 3649.5, 34.79, 138.81+90), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Giường bệnh viện 1",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     jobs = {'ambulance'}, -- Chỉ job bác sĩ mới target được (phải là table)
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- {
    --     coords = vec4(1773.5, 3653.67, 34.76, 139.37+90), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Giường bệnh viện 2",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     jobs = {'ambulance'}, -- Chỉ job bác sĩ mới target được (phải là table)
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- thanh pho
    -- {
    --     coords = vec4(80.49, -380.96, 41.05, 68.46+90), -- X, Y, Z, Heading CỐ ĐỊNH vec4(459.51, -980.99, 31.14, 4.81)
    --     label = "Ghế cảnh sát 1",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     jobs = {'police'},
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- {
    --     coords = vec4(81.45, -378.52, 41.05, 67.23+90), -- X, Y, Z, Heading CỐ ĐỊNH vec4(459.51, -980.99, 31.14, 4.81)
    --     label = "Ghế cảnh sát 2",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     jobs = {'police'},
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- sa mac
    -- {
    --     coords = vec4(1839.58, 3677.0, 38.36, 297.9+90), -- X, Y, Z, Heading CỐ ĐỊNH vec4(459.51, -980.99, 31.14, 4.81)
    --     label = "Ghế cảnh sát 1",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     jobs = {'police'},
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- {
    --     coords = vec4(1837.24, 3677.43, 38.36, 204.65+90), -- X, Y, Z, Heading CỐ ĐỊNH vec4(459.51, -980.99, 31.14, 4.81)
    --     label = "Ghế cảnh sát 2",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     jobs = {'police'},
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },

    -- {
    --     coords = vec4(371.27, -314.21, 47.71, 159.33), -- X, Y, Z, Heading CỐ ĐỊNH vec4(459.51, -980.99, 31.14, 4.81)
    --     label = "Ghế Cardealer",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     jobs = {'cardealer'},
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },

    -- {
    --     coords = vec4(463.1, -850.37, 26.11, 261.05), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Bên bếp lửa hồng 1",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- {
    --     coords = vec4(466.38, -850.06, 26.18, 80.28), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Bên bếp lửa hồng 2",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- {
    --     coords = vec4(462.95, -847.61, 26.24, 193.02), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Bên bếp lửa hồng 3",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- {
    --     coords = vec4(461.22, -851.25, 27.23, 287.3), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Bên bếp lửa hồng 4",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- {
    --     coords = vec4(454.63, -859.48, 28.1, 76.23), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Bên bếp lửa hồng 4",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },

    -- {
    --     coords = vec4(453.46, -867.34, 27.65, 285.73), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Bên bếp lửa hồng 5",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },

    -- {
    --     coords = vec4(466.61, -864.5, 27.17, 24.23), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Bên bếp lửa hồng 6",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- bat dong san
    -- {
    --     coords = vec4(-125.94, -633.19, 169.32, 87.02), -- X, Y, Z, Heading CỐ ĐỊNH vec4(459.51, -980.99, 31.14, 4.81)
    --     label = "Nghỉ ngơi",
    --     radius = 2.5, -- Bán kính để player có thể tương tác
    --     jobs = {'realestate'},
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    -- taxi
    -- {
    --     coords = vec4(382.75, -1610.82, 28.77, 42.65), -- X, Y, Z, Heading CỐ ĐỊNH
    --     label = "Nghỉ ngơi Taxi",
    --     radius = 2.0, -- Bán kính để player có thể tương tác
    --     jobs = {'taxi'},
    --     maxSleepiness = 50 -- Chỉ ngủ tối đa đến 50%
    -- },
    
    
}

-- Cấu hình vật phẩm chiếu ngủ
Config.SleepItem = {
    enabled = true,                 -- Bật/tắt tính năng sử dụng chiếu ngủ
    itemName = 'chieungu_newbie',          -- Tên item trong inventory
    consumeOnUse = true,           -- true = xóa item sau khi dùng, false = giữ lại
    label = "Chiếu ngủ di động",    -- Tên hiển thị
    zOffset = 0.8,                  -- Độ cao Z khi dùng túi ngủ (xuống thấp hơn)
}

-- Thông báo
Config.Messages = {
    startSleep = "Bạn đang bắt đầu ngủ...",
    wakeUp = "Bạn đã thức dậy và cảm thấy sảng khoái!",
    alreadySleeping = "Bạn đã đang ngủ rồi!",
    cannotSleep = "Bạn không thể ngủ ở đây!",
    usingSleepItem = "Bạn đang trải chiếu để ngủ...",
    noSleepItem = "Bạn không có chiếu ngủ!"
}

-- Cấu hình ox_target
Config.UseTarget = true -- Bật/tắt ox_target
Config.TargetIcon = 'fas fa-bed'
Config.TargetLabel = 'Ngủ'
Config.DebugTarget = false -- Bật để xem zones debug

-- Cấu hình vị trí prop
Config.UseExactCoords = true -- true = sử dụng chính xác coords từ config, false = tìm ground
Config.PedOffset = 0.0 -- Độ cao ped so với prop (để tránh clipping)
Config.UseExactRestore = true -- true = restore về chính xác vị trí gốc (tránh mái nhà), false = tìm ground khi restore

-- Cấu hình bảo vệ khi ngủ
Config.SleepProtection = {
    invincible = false,          -- Làm ped bất tử hoàn toàn
    noTarget = false,            -- Không thể target
    noCollision = false,         -- Tắt collision
    invisible = false,           -- BẬT ẩn ped (tránh hiển thị mờ gây trải nghiệm xấu)
    hideUnderground = false,    -- TẮT: Tránh đặt ped dưới lòng đất (gây góc nhìn lạ)
    
    -- Phương pháp bảo vệ tối ưu
    useEntityProofs = false,    -- Sử dụng entity proofs để bảo vệ (TẮT để có thể bị tấn công)
    freezePlayer = false,       -- TẮT freeze để xe có thể cán qua (dùng ragdoll disable thay thế)
    disableControls = true,     -- Tắt các controls (combat, movement)
    setCameraFocus = false,     -- TẮT camera focus (giữ camera tự do)
    disableRagdoll = true,      -- TẮT ragdoll để player nằm yên (nhưng vẫn bị damage)
    
    -- Cấu hình tự động hủy khi bị tấn công
    cancelOnDamage = true,      -- Tự động hủy ngủ khi bị tấn công
    damageCheckInterval = 100,  -- Kiểm tra damage mỗi 100ms
    
    -- Hiệu ứng visual khi ngủ
    enableBlurEffect = true,    -- 🌙 BẬT hiệu ứng blur khi ngủ
    blurEffectName = 'DeathFailMPIn',  -- Tên hiệu ứng blur
    -- Các hiệu ứng khác có thể sử dụng (theo mức độ rung từ ít -> nhiều):
    -- 'SwitchHudMichaelOut' - Hiệu ứng nhẹ nhàng, ít rung nhất
    -- 'DeathFailMPIn' - Hiệu ứng chết trong MP (mờ và tối) - Khuyến nghị
    -- 'HeistCelebPass' - Hiệu ứng celebrate - Rung trung bình
    -- 'DrugsTrevorClownsFight' - Hiệu ứng ma túy (màu sắc lạ) - Rung nhiều
    -- 'DrugsMichaelAliensFight' - Hiệu ứng alien fight - Rung nhiều nhất
    blurTimecycle = 'sleeping',        -- Timecycle modifier cho hiệu ứng mơ màng
    blurStrength = 0.5,               -- Độ mạnh của timecycle (0.0 - 1.0) - GIẢM để ít rung
    
    -- Cài đặt chống rung màn hình
    reduceScreenShake = true,         -- 🔧 Giảm rung màn hình
    blurUpdateInterval = 500,         -- Thời gian cập nhật hiệu ứng (ms) - Tăng để ít rung
    
    -- Các loại proofs để bảo vệ ped (TẮT HẾT để xe có thể cán qua)
    proofs = {
        bullets = false,        -- TẮT chống đạn (để có thể bị bắn)
        fire = false,           -- TẮT chống lửa (để có thể bị cháy)
        explosion = false,      -- TẮT chống nổ (để có thể bị nổ)
        collision = false,      -- TẮT chống va chạm (để xe có thể cán qua)
        melee = false,          -- TẮT chống đánh đấm (để có thể bị đánh)
        water = false,          -- TẮT chống nước
        steam = false,          -- TẮT chống hơi nước
        smoke = false           -- TẮT chống khói
    }
}
