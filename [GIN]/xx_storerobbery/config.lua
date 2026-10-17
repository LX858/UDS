Config = {}

Config.MinimumStoreRobberyPolice = 4
Config.ShowCorrectPass = false -- Bật/tắt hiển thị mật khẩu đúng ở bên dưới UI để test (true: Bật, false: Tắt)

-- Cấu hình Bẻ khóa Két tính tiền (Két ngoài)
Config.LockpickItem = 'advalockpicknced' -- Tên mã vật phẩm (item ID trong ox_inventory) bắt buộc có để cướp két tiền ngoài
Config.LockpickLabel = 'Bộ Bẻ Khóa Cao Cấp' -- Tên hiển thị của vật phẩm bẻ khóa
Config.LockpickBreakChance = 50          -- Tỷ lệ % làm mất/hỏng lockpick khi bẻ khóa (70 = 70% mất, 30% giữ lại)
Config.RemoveLockpickOnFail = true       -- Áp dụng tỷ lệ mất lockpick khi bẻ khóa thất bại (true: Có, false: Không)
Config.RemoveLockpickOnSuccess = true    -- Áp dụng tỷ lệ mất lockpick khi bẻ khóa thành công (true: Có, false: Không)

-- Cấu hình Minigame ox_lib (skillCheck) cho Két tính tiền ngoài
Config.SkillCheckDifficulty = {'easy', 'medium'} -- Độ khó của minigame: 'easy', 'medium', 'hard' hoặc custom table
Config.SkillCheckKeys = {'w', 'a', 's', 'd'}     -- Phím bấm minigame ox_lib (ví dụ: {'w', 'a', 's', 'd'} hoặc nil để dùng mặc định)

-- Vật phẩm Thẻ giải mã két sắt
Config.CardItem = 'blue_card'          -- Tên mã vật phẩm (item ID trong ox_inventory) dùng để quẹt mở két sắt
Config.CardLabel = 'Blue Card' -- Tên hiển thị của thẻ trên thông báo và giao diện

-- Cấu hình thời gian chờ giữa các vụ cướp tạp hóa (tính bằng giây)
Config.GlobalRobberyCooldown = 30 * 60 -- Khi một tạp hóa bị cướp xong, tất cả các tạp hóa khác phải đợi 30 giây mới cho người khác cướp tiếp

-- Cấu hình thời gian sau khi cướp (tính bằng giây)
Config.BasicCooldown = 1 * 60 -- (30 phút) Thời gian hồi két tính tiền của cửa hàng vừa bị cướp
Config.HardCooldown = 2 * 60  -- (30 phút) Thời gian hồi két sắt lớn của cửa hàng vừa bị cướp

-- Cấu hình thời gian thanh progressbar sau khi cướp (tính bằng miligiây)
Config.Progress_BasicCooldown = 90 * 1000 --  Thời gian hồi két tính tiền 
Config.Progress_HardCooldown =  120 * 1000  --  Thời gian hồi két sắt lớn 

-- Cấu hình hệ thống giải mã (Check Pass & Mở Két)
Config.CheckPassLoadTime = 3 * 1000 -- ( giây ) Thời gian load thanh progressbar khi nhấn Check Pass (miligiây). 5000 = 5 giây
Config.MaxPassAttempts = 8      -- Số lần thử (Check Pass) sai tối đa tại Máy tính PC trước khi bị khóa UI
Config.MaxSafePassAttempts = 3  -- Số lần nhập sai mật khẩu tối đa tại Két Sắt trước khi bị khóa hệ thống
Config.LockoutDuration = 60    -- ( giây ) - Thời gian khóa hệ thống khi vượt quá số lần thử sai (giây). 180 = 3 phút

-- Cấu hình danh sách phần thưởng khi cướp (Két tính tiền & Két sắt)
-- Các trường cấu hình cho mỗi item:
--   - item: Tên mã vật phẩm (item ID trong ox_inventory)
--   - label: Tên hiển thị khi thông báo cho người chơi
--   - min: Số lượng tối thiểu nhận được
--   - max: Số lượng tối đa nhận được
--   - chance: Tỷ lệ (%) nhận được item đó (từ 1 đến 100). Ví dụ: 100 là 100% chắc chắn nhận, 20 là 20% tỷ lệ rơi đồ
Config.Rewards = {
    ['basic'] = { -- Phần thưởng khi cướp Két máy tính tiền (Két ngoài)
        { item = 'cash', label = 'Tiền mặt', min = 2500, max = 5000, chance = 100 },
        { item = 'blue_card', label = 'Blue Card', min = 1, max = 1, chance = 20 },
        -- Bạn có thể bổ sung thêm các item khác tại đây:
        -- { item = 'lockpick', label = 'Dụng cụ bẻ khóa', min = 1, max = 1, chance = 30 },
    },
    ['hard'] = { -- Phần thưởng khi mở khóa Két sắt an toàn (Két trong)
        { item = 'cash', label = 'Tiền mặt', min = 5500, max = 9000, chance = 100 }, 
        { item = 'goldchain', label = 'Dây Chuyền Vàng', min = 3, max = 5, chance = 100 }, -- 3830
        { item = 'rolex', label = 'Đồng Hồ Rolex', min = 1, max = 3, chance = 40 }, -- 4220
        { item = 'diamond', label = 'Kim Cương', min = 1, max = 1, chance = 25 }, -- 6430
        { item = 'blue_card', label = 'Thẻ Xanh Dương', min = 1, max = 1, chance = 20 },
        { item = 'the_sieu_trom', label = 'Thẻ Siêu Trộm', min = 1, max = 1, chance = 20 },
        -- { item = 'diamond', label = 'Kim cương', min = 1, max = 1, chance = 10 },
    }
}