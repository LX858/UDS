Config = {}

-- Item bình xăng rỗng yêu cầu phải có/cầm trên tay
Config.EmptyItem = 'canxangrong'

-- Item bình xăng có xăng nhận được sau khi rút (mặc định là 'jerrycan' hoặc 'can_xang')
Config.FilledItem = 'can_xang' 

-- Thời gian rút tối đa (khi bình xăng xe 100%) tính bằng milliseconds (30 giây)
Config.MaxDuration = 30000 

-- Thời gian rút tối thiểu (ms) để đảm bảo tiến trình mượt mà ngay cả khi xăng rất ít
Config.MinDuration = 3000

-- Khoảng cách tối đa để tương tác với xe (meters)
Config.TargetDistance = 2.5

-- Tên animation quỳ/ngồi xuống rút xăng
Config.Anim = {
    dict = 'amb@medic@standing@kneel@base',
    clip = 'base',
    flag = 1
}

-- Cấu hình Kho lưu trữ cây xăng (Đổi vỏ chai lấy bình xăng rỗng)
Config.BottleItem = 'vochai' -- Tên item vỏ chai
Config.ExchangeRatio = 10   -- 10 vỏ chai = 1 bình xăng rỗng
Config.ExchangeLocation = vec3(289.3078, -1264.7252, 29.5075) -- Tọa độ kho lưu trữ
Config.ExchangeDuration = 10000 -- Thời gian đổi (10 giây)
Config.RequiredJob = 'cayxang'  -- Chỉ job 'cayxang' mới được phép đổi bình xăng rỗng
Config.ExchangeAnim = {
    dict = 'mini@repair',
    clip = 'fixing_a_ped',
    flag = 49
}
