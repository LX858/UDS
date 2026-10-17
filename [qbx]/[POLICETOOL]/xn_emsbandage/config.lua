Config = {}

-- ============================================================
-- CẤU HÌNH CHUNG
-- ============================================================

Config.Debug = false -- Bật/tắt debug log

-- Job yêu cầu để sử dụng tính năng này
Config.EmsJob = 'ambulance'

-- Tên item trong ox_inventory
Config.BandageItem = 'bandage'   -- Băng gạc
Config.BonggonItem = 'bonggon'   -- Bông gòn

-- ============================================================
-- CẤU HÌNH CHẾ TẠO BĂNG GẠC
-- ============================================================

-- Cấp bậc tối thiểu để được phép chế tạo (Bác sĩ cấp 6 trở lên)
Config.MinCraftGrade = 6

-- Vị trí bàn chế tạo
Config.CraftLocation = vec3(342.8427734375, -1423.3229980469, 32.752216339111)
Config.CraftSize = vec3(1.0, 1.0, 1.0)
Config.CraftDistance = 2.5

-- Tỷ lệ: 5 Bông gòn = 1 Băng gạc
Config.BonggonPerBandage = 5

-- Thời gian chế tạo: 1 Băng gạc = 2 giây (2000 ms)
Config.CraftTimePerItem = 2000

-- ============================================================
-- CẤU HÌNH BÁN BĂNG GẠC
-- ============================================================

-- Giá bán mỗi băng gạc (đô la)
Config.BandagePrice = 1000 -- 1000$ / 1 cái

-- Giới hạn số lượng bán mỗi lần giao dịch
Config.MinQuantity = 1
Config.MaxQuantity = 99

-- ID kho y tế bệnh viện (boss stash của EMS)
Config.BossStashId = 'boss_ems'

-- Phân chia doanh thu khi bán băng gạc
-- 80% đưa lại kho EMS (dưới dạng tiền mặt addItem 'money')
-- 20% vào túi bác sĩ (cash)
Config.StashRevenuePct = 0.80   -- 80% vào kho boss_ems
Config.DoctorRevenuePct = 0.20  -- 20% vào túi bác sĩ

-- Item tiền mặt trong kho (ox_inventory item name)
Config.MoneyItem = 'money'

-- Webhook Discord để gửi log bán / chế băng gạc
Config.DiscordWebhook = 'https://discord.com/api/webhooks/1520018576323383308/dPqwLiV85MHVIPUE_oB_2gLuM5qK4OfyWdbolPRuTKwZ1aXhSfOiucngf3aXp3s9c7XZ'

-- ============================================================
-- HELPER
-- ============================================================
function Config.DebugPrint(...)
    if Config.Debug then
        print('[XN_EMSBANDAGE]', ...)
    end
end

