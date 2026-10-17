Config = {}

-- Framework
Config.Framework = 'qbx' -- 'newqb', 'qb', or 'qbx'

-- Command để mở MDT
Config.Command = 'pdtool'

-- Jobs có thể dùng MDT
Config.AllowedJobs = {
    ['police'] = true,
    ['sheriff'] = true
}

-- Cấp bậc tối thiểu để truy cập "Quản Lý Mức Án" (Charges Management)
Config.MinGradeForCharges = 12  -- Chỉ grade >= 12 mới thấy tab Quản Lý Mức Án

-- Cấp bậc tối thiểu để mở MDT (bằng tablet và /pdtool)
Config.MinGradeToOpenMDT = 1 -- Chỉ grade >= 1 mới được mở MDT

-- Avatar mặc định
Config.DefaultAvatar = 'https://i.imgur.com/6VWrF0Y.png'

-- Bảng players
Config.PlayersTable = 'players'

-- Discord Bot
Config.DiscordBotName = 'PD TOOL UNDER STAR'
Config.DiscordBotAvatar = 'https://i.imgur.com/6VWrF0Y.png'

-- Discord Logs
Config.EnableDiscordLogs = true -- Bật/tắt gửi log lên Discord (true = bật, false = tắt)

-- Tags tội phạm
Config.CrimeTags = {
    {id = 1, label = "Không"},
    {id = 2, label = "Nghi phạm"},
    {id = 3, label = "Kẻ giết người"},
    {id = 4, label = "Kẻ buôn lậu"},
    {id = 5, label = "Kẻ cướp"},
    {id = 6, label = "Kẻ trộm"},
    {id = 7, label = "Kẻ bạo lực"},
    {id = 8, label = "Kẻ ma túy"}
}

-- Loại tiền phạt
Config.FineTypes = {
    {id = 1, label = "Tiền mặt"},
    {id = 2, label = "Ngân hàng"}
}

-- Quản lý cư dân
Config.IDCardPrice = 5000 -- Giá cấp CCCD

-- ==================== VEHICLE ACTIONS ====================
-- Chức năng giam xe & xóa xe bằng target khi on duty

Config.VehicleActions = {
    Enabled = true, -- Bật/tắt chức năng
    MinGradeImpound = 1, -- Cấp bậc tối thiểu để giam xe
    MinGradeDelete = 1, -- Cấp bậc tối thiểu để xóa xe (thay đổi từ 10 xuống 1)
    Target = 'ox', -- 'ox' hoặc 'qb'
    
    -- Vi phạm mặc định cho giam xe
    DefaultOffences = {
        {label = "🚫 Đỗ xe sai luật", duration = 30},
        {label = "⚠️ Vi phạm giao thông", duration = 60},
        {label = "🚨 Tấn công cảnh sát", duration = 180},
        {label = "💀 Tội phạm nghiêm trọng", duration = 360},
        {label = "📝 Khác (tự nhập)", duration = 0}
    }
}

-- ==================== PATROL POINTS ====================
-- Cooldown được tính bằng phút (Ví dụ: 30 = 30 phút, nếu không có sẽ mặc định là 15 phút)
Config.PatrolPoints = {
    {
        id = 1,
        name = "Bãi đu đủ",
        coords = vector3(1231.5006, -86.8380, 59.6442),
        radius = 100.0,
        sprite = 140,
        cooldown = 30 -- 30 phút
    },
    {
        id = 2,
        name = "Chợ đen",
        coords = vector3(-1171.2560, -1571.1517, 3.6636),
        radius = 100.0,
        sprite = 59,
        cooldown = 15 -- 15 phút
    },
    {
        id = 3,
        name = "bãi hoa",
        coords = vector3(1481.9066, -2354.6516, 71.9142),
        radius = 100.0,
        sprite = 140,
        cooldown = 30 -- 15 phút
    },
    {
        id = 4,
        name = "bãi dò kim loại",
        coords = vector3(-1171.4543, 33.4847, 51.4955),
        radius = 100.0,
        sprite =  486,
        cooldown = 30 -- 15 phút
    }
}

-- ==================== RED ZONES ====================
-- Các khu vực cấm không nằm trong danh sách tuần tra PatrolPoints của MDT (nhưng vẫn áp dụng cấm và đẩy ra ngoài khi có cooldown)
Config.RedZones = {
    {
        id = 'gang_ballas',
        name = "Trụ Sở Ballas",
        coords = vector3(100.94, -1912.42, 21.41),
        radius = 100.0
    },
    {
        id = 'gang_vagos',
        name = "Trụ Sở Vagos",
        coords = vector3(346.60, -1012.87, 29.20),
        radius = 100.0
    },
    {
        id = 'gang_families',
        name = "Trụ Sở Families",
        coords = vector3(-14.34, -1445.89, 31.10),
        radius = 100.0
    },
    {
        id = 'gang_saigondanang',
        name = "Trụ Sở Sài Gòn Đà Nẵng",
        coords = vector3(-140.23, -1607.34, 35.03),
        radius = 100.0
    },
    {
        id = 'gang_buidoi',
        name = "Trụ Sở Bụi Đời",
        coords = vector3(1392.51, 1154.21, 114.33),
        radius = 100.0
    },
    {
        id = 'dao_dau_lau',
        name = "Đảo đầu lâu",
        coords = vector3(4840.571, -5174.425, 2.0),
        radius = 2000.0
    }
}

-- ==================== PERSONAL COOLDOWN & ZONE PROTECTION ====================
-- Tự động đưa người chơi ra ngoài an toàn (cách zone 10.0m) khi đi vào khu vực zone nếu đang dính cooldown
Config.PersonalCooldown = {
    DefaultDuration = 30,     -- Thời gian cooldown mặc định (phút) nếu không truyền tham số
    BufferDistance = 10.0,    -- Khoảng cách đưa ra ngoài cách mép vòng tròn zone (mét)
    WarningCooldown = 4000,   -- Cooldown giữa các lần gửi thông báo cảnh báo để tránh spam (ms)
    WarningMessage = "Bạn đang trong thời gian bị cấm vào khu vực này! Còn lại: %s",
    WarningType = 'error'     -- Loại thông báo ('error', 'warning', 'info')
}