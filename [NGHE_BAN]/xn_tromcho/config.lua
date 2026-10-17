Config = {}
Config.Debug = false -- BẬT CÁI NÀY LÊN ĐỂ CHECK XEM CHÓ CÓ SPAWN KHÔNG

Config.Framework = "QBCore" -- Sài QBus thì ghi QBCore, PEPE thì ghi Framework
Config.Pepev6 = false -- Nếu bạn dùng Pepev6 thì điền true


--[[ CHUNG ]]--
Config.ToaDo = vector3(-348.782, 484.7171, 113.34) -- TỌA ĐỘ MÀ CHÓ SẼ XUẤT HIỆN
Config.Peds = {"a_c_husky", "a_c_poodle", "a_c_pug", "a_c_retriever", "a_c_rottweiler", "a_c_shepherd", "a_c_westy"} -- LOẠI CHÓ SẼ XUẤT HIỆN https://docs.fivem.net/docs/game-references/ped-models/#animals
Config.MaxSpawn = 5 -- MỖI NGƯỜI CHƠI SẼ XUẤT HIỆN NHIỀU NHẤT 5 CON
Config.PhamVi = 200.0 -- NHỚ LÀ SỐ THẬP PHÂN
Config.VatPham = "xichcho" -- VẬT PHẨM CẦN ĐỂ BẮT CHÓ
Config.PoliceOnDutyRequired = 3 -- SỐ CẢNH SÁT TRÊN SERVER ĐANG TRỰC (0 = KHÔNG YÊU CẦU)
Config.event = false

-- ĐỘ HIẾM CỦA CHÓ (Spawn rate - càng cao càng dễ xuất hiện)
Config.DogRarity = {
    ["a_c_westy"] = 30,      -- PHỔ BIẾN (30%)
    ["a_c_pug"] = 25,        -- PHỔ BIẾN (25%)
    ["a_c_poodle"] = 20,     -- KHÔNG PHỔ BIẾN (20%)
    ["a_c_retriever"] = 12,  -- HIẾM (12%)
    ["a_c_rottweiler"] = 8,  -- HIẾM (8%)
    ["a_c_shepherd"] = 3,    -- RẤT HIẾM (3%)
    ["a_c_husky"] = 2        -- CỰC KỲ HIẾM (2%)
}
-- TỔNG: 100% (30+25+20+12+8+3+2)

-- ĐỘ KHÓ MINIGAME THEO ĐỘ HIẾM (Difficulty, Keys)
-- easy = dễ (4 phím), normal = trung bình (5-6 phím), hard = khó (7-8 phím), veryhard = rất khó (9-10 phím)
Config.DogMinigameDifficulty = {
    ["a_c_westy"] = {difficulty = "easy", keys = 4},        -- PHỔ BIẾN → DỄ
    ["a_c_pug"] = {difficulty = "easy", keys = 4},          -- PHỔ BIẾN → DỄ
    ["a_c_poodle"] = {difficulty = "normal", keys = 5},     -- KHÔNG PHỔ BIẾN → TRUNG BÌNH
    ["a_c_retriever"] = {difficulty = "normal", keys = 6},  -- HIẾM → TRUNG BÌNH +
    ["a_c_rottweiler"] = {difficulty = "hard", keys = 7},   -- HIẾM → KHÓ
    ["a_c_shepherd"] = {difficulty = "hard", keys = 8},     -- RẤT HIẾM → KHÓ +
    ["a_c_husky"] = {difficulty = "veryhard", keys = 10}    -- CỰC KỲ HIẾM → RẤT KHÓ
}

-- BẢNG CHUYỂN ĐỔI PED → ITEM
Config.PedToItem = {
    ["a_c_husky"] = "cho_husky",
    ["a_c_poodle"] = "cho_poodle",
    ["a_c_pug"] = "cho_pug",
    ["a_c_retriever"] = "cho_retriever",
    ["a_c_rottweiler"] = "cho_rottweiler",
    ["a_c_shepherd"] = "cho_shepherd",
    ["a_c_westy"] = "cho_westy"
}

-- BẢNG CHUYỂN ĐỔI ITEM → PED (ĐỂ SPAWN LẠI KHI USE ITEM)
Config.ItemToPed = {
    ["cho_husky"] = "a_c_husky",
    ["cho_poodle"] = "a_c_poodle",
    ["cho_pug"] = "a_c_pug",
    ["cho_retriever"] = "a_c_retriever",
    ["cho_rottweiler"] = "a_c_rottweiler",
    ["cho_shepherd"] = "a_c_shepherd",
    ["cho_westy"] = "a_c_westy"
}
Config.ChoCan = true -- CÓ CHO CHÓ CẮN HAY KHÔNG
Config.ChanceChoCan = 90 -- TỈ LỆ BỊ CHÓ CẮN (TỪ 1 TỚI 10)
Config.MauBiCan = 10 -- MÁU MẤT KHI BỊ CẮN

--[[ THỜI GIAN XUẤT HIỆN ]] -- 
Config.CopRequired = 3 -- CẢNH SÁT YÊU CẦU
Config.MinTime = 0 -- XUẤT HIỆN TỪ 0H (00:00 - CẢ NGÀY)
Config.MaxTime = 23 -- ĐÉN 23H (23:00 - 23:59 - CẢ NGÀY)
-- VÍ DỤ: MinTime = 18, MaxTime = 6 → Hoạt động từ 18:00 qua 00:00 đến 06:59 (QUA NỬA ĐÊM)
-- VÍ DỤ: MinTime = 18, MaxTime = 23 → Hoạt động từ 18:00 đến 23:59
-- VÍ DỤ: MinTime = 0, MaxTime = 23 → Hoạt động cả ngày (00:00 đến 23:59)


--[[ BIỂU TƯỢNG TRÊN BẢN ĐỒ ]]--
Config.HienBlip = true -- HIỆN ICON TRÊN BẢN ĐỒ
Config.Title = "Khu Vực Chó" -- TÊN ICON 
Config.Icon = 273 -- https://docs.fivem.net/docs/game-references/blips/
Config.Scale = 0.5 -- ĐỘ LỚN (0 < n < 1)
Config.Colour = 7 -- MÀU https://docs.fivem.net/docs/game-references/blips/ (CUỐI TRANG SẼ CÓ BẢNG MÀU)
Config.Alpha = 255 -- ĐỘ MỜ (từ 0 tới 255)
--[[ VÒNG TO ]]--
Config.BigColour = 1 -- MÀU https://docs.fivem.net/docs/game-references/blips/ (CUỐI TRANG SẼ CÓ BẢNG MÀU)
Config.BigAlpha = 50 -- ĐỘ MỜ (từ 0 tới 255)

--[[ PHƯƠNG TIỆN - BẮT CHÓ Ở KHOẢNG CÁCH XA ]]--
Config.PhuongTien = {}
Config.PhuongTien.Allow = true -- CHO PHÉP BẮT CHÓ BẰNG PHƯƠNG TIỆN HAY KHÔNG
Config.PhuongTien.Xe = "exciter" -- PHƯƠNG TIỆN ĐƯỢC SỬ DỤNG (CHỈ MÔ TÔ)
Config.PhuongTien.Distance = 4 -- KHOẢNG CÁCH CÓ THỂ BẮT CHÓ Ở XA
Config.PhuongTien.VatPham = "thonglong" -- VẬT PHẨM CẦN DÙNG KHI BẮT BẰNG PHƯƠNG TIỆN

--[[ XE CHO PHÉP KHI VÁC CHÓ ]]--
Config.AllowedVehicles = {
    "exciter", "z1000", "ponycarv1", "zx10rr", "airblade150", "sh350", "yaz",
    "akuma", "avarus", "bagger", "bati", "bati2", "bf400", "carbonrs", "chimera", 
    "cliffhanger", "daemon", "daemon2", "deathbike", "deathbike2", "deathbike3", 
    "diabolus", "diabolus2", "double", "enduro", "esskey", "faggio", "faggio2", 
    "faggio3", "fcr", "fcr2", "gargoyle", "hakuchou", "hakuchou2", "hexer", 
    "innovation", "lectro", "manchez", "manchez2", "nemesis", "nightblade", 
    "oppressor", "oppressor2", "pcj", "pizzaboy", "policeb", "powersurge", 
    "rampant", "ratbike", "reever", "ruffian", "sanchez", "sanchez2", "sanctus", 
    "shinobi", "shotaro", "sovereign", "stryder", "thrust", "vader", "vindicator", 
    "vortex", "wolfsbane", "zombiea", "zombieb"
}

--[[ BÁO CẢNH SÁT ]] -- 
Config.BCS = {}
Config.BCS.Enable = true -- CÓ BÁO CẢNH SÁT HAY KHÔNG
Config.BCS.Chance = 100 -- TỈ LỆ BÁO CẢNH SÁT (TỪ 1 TỚI 10)
Config.BCS.Event = "" -- LIÊN HỆ ĐỂ ĐƯỢC SETUP

--[[ THANH SKILLBAR ]]--
Config.Skillbar = {}
Config.Skillbar.Type = "qb-skillbar" -- qb-skillbar, pepe-skillbar
Config.Skillbar.Tocdo = math.random(2500, 5000) -- SỐ CÀNG NHỎ TỐC ĐỘ SẼ CÀNG NHANH
Config.Skillbar.Solan = 1 -- SỐ LẦN LẶP LẠI (1 = CHỈ CẦN LÀM MỘT LẦN)
Config.ThoiGianBatCho = 100000 -- THỜI GIAN CHẠY PROGRESS BAR KHI BẮT CHÓ (mili giây) 10000
Config.CooldownToanServer = 3 -- COOLDOWN TOÀN SERVER SAU KHI CÓ NGƯỜI TRỘM THÀNH CÔNG (phút)
Config.CooldownThatBai = 10   -- COOLDOWN TOÀN SERVER SAU KHI TRỘM THẤT BẠI (giây)
Config.TimeoutAuto = 120      -- AUTO RESET NẾU PLAYER BỊ STUCK KHÔNG HOÀN THÀNH (giây)


--[[ BÁN CHÓ ]]--
Config.BanCho = {}
Config.BanCho.NPC = "a_m_m_hillbilly_02"
Config.BanCho.ViTri = vec4(979.54, -2145.13, 29.48, 314.26)
Config.BanCho.TenIcon = "Bán Chó"
Config.BanCho.Icon = 484
Config.BanCho.MauIcon = 1
Config.BanCho.HienBlip = true
Config.BanCho.LoaiTien = "tiensach" -- tiensach, tienban 
Config.BanCho.GiaCho = { -- GIÁ CHÓ (THEO ITEM)
    ["cho_westy"] = 2000,
    ["cho_pug"] = 3000,
    ["cho_poodle"] = 4000, 
    ["cho_retriever"] = 5000, 
    ["cho_rottweiler"] = 6000, 
    ["cho_shepherd"] = 7000, 
    ["cho_husky"] = 8000
}

Config.Event = {
    enabled = true, -- Bật/tắt hệ thống phần thưởng đặc biệt
    chance = 3, -- Tỉ lệ % ra phần thưởng đặc biệt (10 = 10%)
    rewards = {
        {item = "banvevukhi", chance = 70}, -- 25% nhận manhgep1
        {item = "the_sieu_trom", chance = 30}, -- Thẻ Siêu trộm
    }
}

Config.Event2 = {
    enabled = true, -- Bật/tắt hệ thống phần thưởng đặc biệt
    chance = 30, -- Tỉ lệ % ra phần thưởng đặc biệt (10 = 10%)
    rewards = {
        {item = "co_bon_la_9", chance = 100}, -- 25% nhận manhgep1

    }
}

--[[ HUẤN LUYỆN CHÓ ]]--
Config.HuanLuyenCho = {}
Config.HuanLuyenCho.NPC = "s_m_y_ranger_01"
Config.HuanLuyenCho.ViTri = vec4(1125.24, -645.11, 56.73, 276.09)
Config.HuanLuyenCho.TenIcon = "Huấn Luyện Chó"
Config.HuanLuyenCho.Icon = 484
Config.HuanLuyenCho.MauIcon = 2
Config.HuanLuyenCho.HienBlip = true
Config.HuanLuyenCho.SuccessRate = {
    -- ["cho_westy"] = 2,
    ["cho_pug"] = 2,
    ["cho_poodle"] = 2,     
    ["cho_retriever"] = 1,  
    -- ["cho_rottweiler"] = 1, 
    -- ["cho_shepherd"] = 1,   
    -- ["cho_husky"] = 1       
}
Config.HuanLuyenCho.TrainTime = 15000 -- 15 giây
Config.HuanLuyenCho.Items = {
    -- ["cho_westy"] = "pet_a_c_westy_2",
    ["cho_pug"] = "pet_a_c_pug",
    ["cho_poodle"] = "pet_a_c_poodle_2", 
    ["cho_retriever"] = "pet_a_c_retriever_2", 
    -- ["cho_rottweiler"] = "pet_a_c_chop", 
    -- ["cho_shepherd"] = "pet_a_c_shepherd_2", 
    -- ["cho_husky"] = "pet_a_c_husky_2"
}
Config.HuanLuyenCho.FailMessages = {
    "Rất tiếc, chú chó này đã ngỏm trong quá trình huấn luyện.",
    "Chú chó của bạn đã cắn huấn luyện viên và bỏ chạy mất tăm.",
    "Khóa huấn luyện quá khắc nghiệt, chú chó đã kiệt sức và không qua khỏi.",
    "Do không chịu được áp lực, chú chó đã đào tẩu thành công.",
    "Huấn luyện viên lỡ tay làm chú chó bị thương nặng và không thể cứu chữa.",
    "Chú chó đã tìm thấy bầy đàn hoang dã và quyết định trở về với thiên nhiên.",
    "Trong lúc học bắt đĩa, chú chó đã nhảy lố qua bờ rào và biến mất.",
    "Một tai nạn xảy ra khi chú chó tập bơi, xin chia buồn cùng bạn...",
    "Chú chó bị trầm cảm vì phải học quá nhiều nên đã lén bỏ trốn.",
    "Chú chó vì quá tham ăn nên đã ăn nhầm bả, huấn luyện viên phát hiện thì đã quá muộn.",
}
Config.HuanLuyenCho.Webhook = "https://discord.com/api/webhooks/1497405710080933928/j-Z-mOlZMl8APq9Twms3oai4LClTz2mCfA9fGMqF5tCaKJnjyEt8p_OYExDupCPEvaW7"