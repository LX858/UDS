-- dưa hấu

-- Hệ thống debug - bật/tắt tất cả print statements
Config = {}
Config.Debug = false -- Đặt true để bật debug prints

Config.Event = {
    enabled = true, -- Bật/tắt hệ thống phần thưởng đặc biệt
    chance = 30, -- Tỉ lệ % ra phần thưởng đặc biệt (10 = 10%)
    rewards = {
        {item = "co_bon_la_3", chance = 100}, -- 25% nhận manhgep1
    }
}

Melons = {
    name = "Lúa nước",
    GrowthObjects = {
        {hash = `bzzz_plant_rice_a`, zOffset = 0.05},
        {hash = `bzzz_plant_rice_a`, zOffset = 0.05},
        {hash = `bzzz_plant_rice_b`, zOffset = 0.05},
        {hash = `bzzz_plant_rice_b`, zOffset = 0.05},
        {hash = `bzzz_plant_rice_c`, zOffset = 0.05},
        {hash = `bzzz_plant_rice_c`, zOffset = 0.05},
    },
    -- Thời gian trồng cây trong bao lâu --DEFAULT 15
    GrowthTime = 15,
    -- Số lượng cây có thể trồng được/người chơi
    planamount = 60,
    -- thời gian check sức khỏe cây
    decreaseRate = 0, -- Tốc độ giảm % mỗi chu kỳ (Không sửa đổi chỗ này)
    -- Thời gian giữa mỗi lần giảm (ms) - khuyến cáo 2 phút khuyễn cáo để số phút chẵn
    decreaseInterval = 180000,
    -- How much longer should a male plant take to grow less is faster
    MaleFactor = 0.9,
    -- How many seeds should come from a male plant (range)
    SeedsFromMale = {2, 5},
    -- How many dopes should come from a female plant (range)
    DopeFromFemale = 1,
    DopeFromFemale2 = 2,
    DopeFromFemale4 = 5,
    DopeFromFemale6 = 7,
    DopeFromFemale7 = 9,
    -- Percent at which the plant becomes harvestable
    HarvestPercent = 99,
    -- Time between plant harvests (minutes)
    TimeBetweenHarvest = 400,
    -- How much should 1 water bottle add, if you want to give 20, set {20, 20}
    WaterAdd = {20, 20},
    FertilizerItem = 'fertilizer',
    bugs = 'saubenh',
    thuoctrusau = 'fertilizer',
    WaterItem = 'xo_co_nuoc',
    MaleSeedItem = 'hatgionglua',
    FemaleSeedItem = 'hatgionglua',
    GiveDopeItem = {
        'luanuoc',
    },
    DoubleYieldChance = 30, -- Tỷ lệ % cơ hội x2 sản lượng khi thu hoạch (ví dụ: 30%)
    DoubleYieldMultiplier = 2, -- Hệ số nhân sản lượng (mặc định x2)
    -- less is faster growth but less quality
    FertilizerFactor = 0.9,
    -- Affects how much each nutrient contributes to the final quality
    NWeight = math.random(20, 20),
    PWeight = -10,
    KWeight = math.random(20, 20),
    -- Hệ thống sâu bệnh
    bugSensitivity = 0.3,  -- Xác suất cơ bản bị sâu bệnh mỗi chu kỳ khi điều kiện xấu (0.0 - 1.0)
    bugDecreaseRate = 12,  -- Lượng sức khỏe giảm mỗi chu kỳ khi đã bị nhiễm bệnh
}

-- Hệ thống đa loại cây trồng
-- Thêm loại cây mới vào đây để mở rộng hệ thống
-- Mỗi zone trong FarmRental.FarmZones có thể có cropTypes = {'rice', 'pumpkin', ...}
-- Mặc định (không khai báo cropTypes) = chỉ trồng lúa
CropTypes = {
    rice = Melons, -- Lúa nước (tham chiếu đến bảng Melons bên trên)
    pumpkin = {
        name = "Bí Ngô",
        GrowthObjects = {
            {hash = joaat('SM_Pumpkin_01'), zOffset = -0.2},
            {hash = joaat('SM_Pumpkin_01'), zOffset = -0.2},
            {hash = joaat('SM_Pumpkin_02'), zOffset = -0.2},
            {hash = joaat('SM_Pumpkin_02'), zOffset = -0.2},
            {hash = joaat('SM_Pumpkin_02'), zOffset = -0.2},
            {hash = joaat('SM_Pumpkin_03'), zOffset = -0.2},
            {hash = joaat('SM_Pumpkin_03'), zOffset = -0.2},
        },
        GrowthTime = 15, -- Thời gian lớn (phút)
        planamount = 60,
        decreaseRate = 0,
        decreaseInterval = 120000, -- 3 phút
        MaleFactor = 0.9,
        SeedsFromMale = {2, 4},
        DopeFromFemale = 1,
        DopeFromFemale2 = 1,
        DopeFromFemale4 = 3,
        DopeFromFemale6 = 5,
        DopeFromFemale7 = 7,
        HarvestPercent = 99,
        TimeBetweenHarvest = 400,
        WaterAdd = {20, 20},
        FertilizerItem = 'fertilizer',
        bugs = 'saubenh',
        thuoctrusau = 'fertilizer',
        WaterItem = 'xo_co_nuoc',
        MaleSeedItem = 'hatgiongbingo',
        FemaleSeedItem = 'hatgiongbingo',
        GiveDopeItem = {'bingo'},
        DoubleYieldChance = 30, -- Tỷ lệ % cơ hội x2 sản lượng khi thu hoạch (ví dụ: 50%)
        DoubleYieldMultiplier = 2, -- Hệ số nhân sản lượng (mặc định x2)
        FertilizerFactor = 0.9,
        NWeight = 20,
        PWeight = -10,
        KWeight = 20,
        -- Hệ thống sâu bệnh
        bugSensitivity = 0.5,  -- Bí ngô nhạy cảm hơn lúa
        bugDecreaseRate = 18,
    },
    wheat = {
        name = "Lúa Mì",
        GrowthObjects = {
            {hash = joaat('bzzz_plants_wheat_a'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_wheat_a'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_wheat_b'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_wheat_b'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_wheat_c'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_wheat_c2'), zOffset = 0.05},
        },
        GrowthTime = 15, -- Thời gian lớn (phút)
        planamount = 60,
        decreaseRate = 0,
        decreaseInterval = 180000, -- 3 phút
        MaleFactor = 0.9,
        SeedsFromMale = {2, 5},
        DopeFromFemale = 1,
        DopeFromFemale2 = 2,
        DopeFromFemale4 = 4,
        DopeFromFemale6 = 6,
        DopeFromFemale7 = 8,
        HarvestPercent = 99,
        TimeBetweenHarvest = 400,
        WaterAdd = {20, 20},
        FertilizerItem = 'fertilizer',
        bugs = 'saubenh',
        thuoctrusau = 'fertilizer',
        WaterItem = 'xo_co_nuoc',
        MaleSeedItem = 'hatgiongluami',
        FemaleSeedItem = 'hatgiongluami',
        GiveDopeItem = {'luami'},
        DoubleYieldChance = 30, -- Tỷ lệ % cơ hội x2 sản lượng khi thu hoạch (ví dụ: 100% để luôn nhân đôi khi test/demo)
        DoubleYieldMultiplier = 2, -- Hệ số nhân sản lượng (mặc định x2)
        FertilizerFactor = 0.9,
        NWeight = 20,
        PWeight = -10,
        KWeight = 20,
        bugSensitivity = 0.35,
        bugDecreaseRate = 14,
    },
    dudu = {
        name = "Đu đủ",
        GrowthObjects = {
            {hash = joaat('bzzz_plants_papaya_a'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_papaya_a'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_papaya_b'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_papaya_b'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_papaya_c'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_papaya_d'), zOffset = 0.05},
        },
        GrowthTime = 25, -- Thời gian lớn (phút)
        planamount = 50,
        decreaseRate = 0,
        decreaseInterval = 120000, -- 3 phút
        MaleFactor = 0.9,
        SeedsFromMale = {2, 4},
        DopeFromFemale = 1,
        DopeFromFemale2 = 1,
        DopeFromFemale4 = 3,
        DopeFromFemale6 = 5,
        DopeFromFemale7 = 7,
        HarvestPercent = 99,
        TimeBetweenHarvest = 400,
        WaterAdd = {20, 20},
        FertilizerItem = 'fertilizer',
        bugs = 'saubenh',
        thuoctrusau = 'fertilizer',
        WaterItem = 'xo_co_nuoc',
        MaleSeedItem = 'hatgiongdudu',
        FemaleSeedItem = 'hatgiongdudu',
        GiveDopeItem = {
            {item = 'ladudu_tuoi', ratio = 0.4},  -- Lá đu đủ: nhận ít hơn
            {item = 'traidudu',    ratio = 1.0},  -- Trái đu đủ: nhận nhiều hơn
        },
        PerfectHarvestTotal = 6, -- Nếu nước/phân/health đạt chuẩn hoàn hảo, tổng sản lượng cố định là 6
        FertilizerFactor = 1.0, -- 1.0: phân bón không rút ngắn thời gian lớn (đúng 25 phút)
        NWeight = 20,
        PWeight = -10,
        KWeight = 20,
        -- Hệ thống sâu bệnh
        bugSensitivity = 0.5,  -- Bí ngô nhạy cảm hơn lúa
        bugDecreaseRate = 18,
    },
    poppy = {
        name = "Hoa Mỹ Nhân",
        GrowthObjects = {
            {hash = joaat('bzzz_plants_poppy_2a'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_poppy_2a'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_poppy_2b'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_poppy_2b'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_poppy_2c'),  zOffset = 0.05},
            {hash = joaat('bzzz_plants_poppy_2c'),  zOffset = 0.05},
        },
        GrowthTime = 25, -- Thời gian lớn (phút)
        planamount = 50,
        decreaseRate = 0,
        decreaseInterval = 120000, -- 3 phút
        MaleFactor = 0.9,
        SeedsFromMale = {2, 4},
        DopeFromFemale = 1,
        DopeFromFemale2 = 1,
        DopeFromFemale4 = 3,
        DopeFromFemale6 = 5,
        DopeFromFemale7 = 7,
        HarvestPercent = 99,
        TimeBetweenHarvest = 400,
        WaterAdd = {20, 20},
        FertilizerItem = 'fertilizer',
        bugs = 'saubenh',
        thuoctrusau = 'fertilizer',
        WaterItem = 'xo_co_nuoc',
        MaleSeedItem = 'hatgiong_hoamynhan',
        FemaleSeedItem = 'hatgiong_hoamynhan',
        GiveDopeItem = {
            {item = 'la_hoamynhan',  ratio = 0.4},  -- Lá poppy: nhận ít hơn
            {item = 'hoa_mynhan',    ratio = 1.0},  -- Hoa / quả poppy: nhận nhiều hơn
        },
        PerfectHarvestTotal = 6, -- Nếu nước/phân/health đạt chuẩn hoàn hảo, tổng sản lượng cố định là 6
        FertilizerFactor = 1.0, -- 1.0: phân bón không rút ngắn thời gian lớn (đúng 25 phút)
        NWeight = 20,
        PWeight = -10,
        KWeight = 20,
        -- Hệ thống sâu bệnh
        bugSensitivity = 0.5,
        bugDecreaseRate = 18,
    },
}

-- Cấu hình thuốc trừ sâu
-- healAmount: lượng sức khỏe hồi phục tối thiểu
-- cureChance: xác suất chữa khỏi hoàn toàn (reset về 100)
BugTreatment = {
    pesticide_basic = {
        label = 'Thuốc trừ sâu thường',
        healAmount = 25,
        cureChance = 0.45,
    },
    pesticide_advanced = {
        label = 'Thuốc trừ sâu cao cấp',
        healAmount = 55,
        cureChance = 0.85,
    },
}

-- Hệ thống chó bảo vệ và trộm cây
DogProtection = {
    -- Giá thuê chó bảo vệ ($/giờ)
    RentalPricePerHour = 3000,
    
    -- Tỷ lệ phát hiện kẻ trộm (%) - Sử dụng cho việc spawn chó
    DogBiteChance = 50,
    
    -- Damage khi bị chó cắn
    DogBiteDamage = 20,
    
    -- Thời gian stun khi bị chó cắn (ms)
    StunDuration = 3000,
    
    -- Tỷ lệ thành công khi trộm không có chó (%)
    TheftSuccessRate = 80,
    
    -- Tỷ lệ thành công khi trộm có chó nhưng không bị phát hiện (%)
    TheftSuccessRateWithDog = 60,
    
    -- Cấu hình spawn chó NPC
    GuardDog = {
        Model = `a_c_rottweiler`, -- Model chó bảo vệ
        Health = 200, -- Máu chó
        SpawnDistance = 10, -- Khoảng cách spawn từ kẻ trộm (m)
        AttackDuration = 30000, -- Thời gian tấn công (ms)
        MaxLifetime = 60000, -- Thời gian tối đa tồn tại (ms)
    },
}

-- Cấu hình hệ thống thuê ruộng
FarmRental = {
    -- Vị trí ped cho thuê ruộng
    PedLocation = vector4(2570.48, 4667.58, 34.08, 134.03),
    PedModel = 'a_m_m_farmer_01',
    
    -- Thông tin các ruộng - khớp với tọa độ blip và polyzone trong melons.lua
    FarmZones = {
        [1] = {
            id = 1,
            name = "Ruộng 1 (Bí ngô, Lúa mì)",
            center = vector3(2537.0, 4814.0, 34.0),
            radius = 50.0,
            no_rent = true,            
            blip = true,
            cameraPos = vector3(2537.0, 4814.0, 54.0),
            cameraRot = vector3(-45.0, 0.0, 0.0),
            rentalPrice = 5000, -- Giá thuê $800/giờ
            cropTypes = {'pumpkin', 'wheat'}, -- Ruộng bí ngô
        },
        [2] = {
            id = 2,
            name = "Ruộng 2 (Bí ngô, Lúa mì)", 
            center = vector3(2485.0, 4841.0, 36.0),
            radius = 50.0,
            no_rent = true,
            blip = true,
            cameraPos = vector3(2485.0, 4841.0, 56.0),
            cameraRot = vector3(-45.0, 0.0, 0.0),
            rentalPrice = 5000, -- Giá thuê $1000/giờ
            cropTypes = {'pumpkin', 'wheat'}, -- Ruộng bí ngô
        },
        [3] = {
            id = 3,
            name = "Ruộng 3 (Bí ngô, Lúa mì)",
            center = vector3(1914.0, 4763.0, 42.0),
            radius = 50.0,
            no_rent = true,
            blip = true,
            cameraPos = vector3(1914.0, 4763.0, 62.0),
            cameraRot = vector3(-45.0, 0.0, 0.0),
            rentalPrice = 4000, -- Giá thuê $1200/giờ
            cropTypes = {'pumpkin', 'wheat'}, -- Ruộng bí ngô
        },
        [4] = {
            id = 4,
            name = "Ruộng 4 (Bí ngô, Lúa mì)",
            center = vector3(1886.0, 4794.0, 43.0),
            radius = 50.0,
            no_rent = true,
            blip = true,
            cameraPos = vector3(1886.0, 4794.0, 63.0),
            cameraRot = vector3(-45.0, 0.0, 0.0),
            rentalPrice = 4000, -- Giá thuê $900/giờ
            cropTypes = {'pumpkin', 'wheat'}, -- Ruộng bí ngô
        },
        [5] = {
            id = 5,
            name = "Ruộng 5 (Bí ngô, Lúa mì)",
            center = vector3(1861.0, 4817.0, 44.0),
            radius = 50.0,
            no_rent = true,
            blip = true,
            cameraPos = vector3(1861.0, 4817.0, 64.0),
            cameraRot = vector3(-45.0, 0.0, 0.0),
            rentalPrice = 4000, -- Giá thuê $1100/giờ
            cropTypes = {'pumpkin', 'wheat'}, -- Ruộng bí ngô
        },
        [6] = {
            id = 6,
            name = "Ruộng 6 (Bí ngô, Lúa mì)",
            center = vector3(1956.0, 4795.0, 43.0),
            radius = 50.0,
            no_rent = true,
            blip = true,
            cameraPos = vector3(1956.0, 4795.0, 63.0),
            cameraRot = vector3(-45.0, 0.0, 0.0),
            rentalPrice = 4000, -- Giá thuê $1300/giờ  
            cropTypes = {'pumpkin', 'wheat'}, -- Ruộng bí ngô

        },
        [7] = {
            id = 7,
            name = "Ruộng 7 (Lúa nước)",
            center = vector3(2033.0, 4877.0, 43.0),
            radius = 50.0,
            no_rent = true,
            blip = true, 
            cameraPos = vector3(2033.0, 4877.0, 63.0),
            cameraRot = vector3(-45.0, 0.0, 0.0),
            rentalPrice = 4000, -- Giá thuê $1000/giờ
            cropTypes = {'rice'}, -- Ruộng lúa nước
        },
        [8] = {
            id = 8,
            name = "Ruộng 8 (Lúa nước)",
            center = vector3(2005.0, 4904.0, 44.0),
            radius = 50.0,
            no_rent = true,
            blip = true,
            cameraPos = vector3(2005.0, 4904.0, 64.0),
            cameraRot = vector3(-45.0, 0.0, 0.0),
            rentalPrice = 4000, -- Giá thuê $1400/giờ
            cropTypes = {'rice'}, -- Ruộng lúa nước
        },
        [9] = {
            id = 9,
            name = "Ruộng 9 (Lúa nước)",
            center = vector3(2043.0, 4941.0, 42.0),
            radius = 50.0,
            no_rent = true,
            blip = true,
            cameraPos = vector3(2043.0, 4941.0, 62.0),
            cameraRot = vector3(-45.0, 0.0, 0.0),
            rentalPrice = 4000, -- Giá thuê $1500/giờ
            cropTypes = {'rice'}, -- Ruộng lúa nước
        },
        [10] = {
            id = 10,
            name = "Ruộng 10 (Lúa nước)",
            center = vector3(2070.0, 4915.0, 41.0),
            radius = 50.0,
            no_rent = true,
            blip = true,
            cameraPos = vector3(2070.0, 4915.0, 61.0),
            cameraRot = vector3(-45.0, 0.0, 0.0),
            rentalPrice = 4000, -- Giá thuê $1100/giờ
            cropTypes = {'rice'}, -- Ruộng lúa nước
        },
        [11] = {
            id = 11,
            name = "Ruộng 11",
            center = vector3(1231.5006, -86.8380, 59.6442),
            radius = 100.0,
            blip = false,
            cameraPos = vector3(1232.3610, -85.5546, 59.7014),
            cameraRot = vector3(-45.0, 0.0, 0.0),
            rentalPrice = 6000, -- Giá thuê $1600/giờ
            cropTypes = {'dudu', 'poppy'}, -- Ruộng bí ngô
            growthTimeReduction = 10, -- Cây trong khu này lớn nhanh hơn khu khác 10 phút (tối thiểu còn 1 phút)
            capture = {
                markerRadius = 1.0,   -- bán kính marker đỏ + khoảng cách bấm E
                minMembers = 5,       -- tối thiểu thành viên xã đoàn (còn sống) trong zone để bắt đầu chiếm
                keepMembers = 1,      -- trong lúc chiếm, nếu số thành viên còn sống trong zone < giá trị này thì hủy
                captureTime = 300,    -- 5 phút đếm ngược
                holdTime = 1800,      -- 30 phút xã đoàn khác không thể trồng/khai thác/chiếm
                requireOwner = true,  -- true: khu chưa ai chiếm thì không ai được trồng/khai thác
                cooldown = 1800,      -- 30 phút khóa chiếm khi bị hủy
                winnerCooldown = 0,   -- (giây) xã đoàn thắng không được chiếm lại ngay sau khi hết hạn; 0 = tắt
                tickMs = 1000,
                blip = false,          -- hiện vùng trên bản đồ khi đang chiếm / bị chiếm
            },
        },

        [12] = {
            id = 12,
            name = "Ruộng 12",
            center = vector3(1350.3269, -1022.3098, 40.0573),
            radius = 70.0,
            no_rent = true,
            blip = false,
            cameraPos = vector3(1350.3269, -1022.3098, 60.0573),
            cameraRot = vector3(-45.0, 0.0, 0.0),
            rentalPrice = 6000,
            cropTypes = {'dudu', 'poppy'},
        },
        -- [13] = {
        --     id = 13,
        --     name = "Ruộng 13 (Đu đủ, Hoa Mỹ Nhân)",
        --     center = vector3(4843.6895, -4594.4800, 17.4002),
        --     radius = 70.0,
        --     no_rent = true,
        --     blip = true,
        --     blipRadius = 70.0,
        --     marker = {
        --         enabled = true,
        --         type = 1,
        --         scale = { z = 50.0 }, -- Chiều cao cột marker (50m vút lên trời)
        --         zOffset = 20.0, -- Hạ đáy marker xuống 5m dưới mặt đất để ôm sát địa hình dốc
        --         color = { r = 255, g = 0, b = 0, a = 100 },
        --     },
        --     cameraPos = vector3(4859.8813, -4582.9717, 38.0563),
        --     cameraRot = vector3(-45.0, 0.0, 0.0),
        --     rentalPrice = 6000,
        --     cropTypes = {'dudu', 'poppy'},
        --     harvestMultiplier = 1.5, -- Hệ số x1.5 tài nguyên khi thu hoạch
        --     plantLimitMultiplier = 3, -- Hệ số x3 giới hạn số lượng cây có thể trồng
        -- },
    }
}

-- Hệ thống lấy nước
WaterSystem = {
    -- Vị trí lấy nước (tương thích ngược)
    Location = vector3(2416.64, 4602.5, 29.52),
    -- Các vị trí lấy nước
    Locations = {
        vector3(2416.64, 4602.5, 29.52),
        vector3(1143.6038, -144.5072, 52.6938)
    },
    -- Khoảng cách tương tác
    InteractionDistance = 10.0,
    -- Thời gian lấy nước (ms)
    WaterTime = {min = 3000, max = 5000}, -- 3-5 giây
    -- Vật phẩm cần thiết
    RequiredItem = 'xo_rong', -- Xô rỗng
    -- Vật phẩm nhận được
    RewardItem = 'xo_co_nuoc', -- Xô có nước
}

-- Hệ thống cửa hàng nông nghiệp
FarmShop = {
    -- Sử dụng cùng NPC với hệ thống thuê ruộng
    NPCLocation = vector4(2570.48, 4667.58, 34.08, 134.03), -- Cùng với FarmRental.PedLocation
    NPCModel = 'a_m_m_farmer_01',
    
    -- Sản phẩm bán
    Items = {
        {
            item = 'xo_rong',
            label = 'Xô Rỗng',
            price = 50,
            description = 'Xô để lấy nước tưới cây'
        },
        {
            item = 'melon_seed',
            label = 'Hạt Giống Dưa Hấu',
            price = 50,
            description = 'Hạt giống để trồng dưa hấu'
        },
        {
            item = 'fertilizer',
            label = 'Phân Bón',
            price = 50,
            description = 'Phân bón giúp cây phát triển tốt hơn'
        }
    }
}

-- Cấu hình NPC mua hạt giống hoa mỹ nhân
PoppyShop = {
    Enabled = false, -- Bật/Tắt NPC (true: bật, false: tắt)
    PedLocation = vector4(1430.0602, -2316.8923, 66.8418, 322.8018),
    PedModel = 'a_m_m_farmer_01',
    Blip = {
        enabled = false,
        sprite = 285,
        color = 2,
        scale = 0.7,
        label = "Cửa Hàng Hoa Mỹ Nhân"
    },
    Items = {
        {
            item = 'hatgiong_hoamynhan',
            label = 'Hạt Giống Hoa Mỹ Nhân',
            price = 100,
            description = 'Hạt giống trồng hoa mỹ nhân'
        }
    }
}

Carrot = {}
Carrot.LayNuoc = {
    --Public Garage:
	['LayNuoc'] = {
		zones = {
            vector2(2414.4094238281, 4607.0883789063),
            vector2(2418.193359375, 4609.0551757813),
            vector2(2423.9619140625, 4603.4990234375),
            vector2(2421.6369628906, 4599.744140625),
            vector2(2406.8601074219, 4583.984375),
            vector2(2397.146484375, 4595.5395507813)
        },
        minZ = 29.525592803955,
        maxZ = 30.477895736694
    },

    ['LayNuoc2'] = {
		zones = {
            vector2(1161.6202392578, -160.08274841309),
            vector2(1186.5955810547, -189.9640045166),
            vector2(1190.1866455078, -216.42021179199),
            vector2(1160.5145263672, -214.18339538574),
            vector2(1148.359375, -210.31011962891),
            vector2(1117.6888427734, -215.03941345215),
            vector2(1086.4525146484, -187.96670532227),
            vector2(1090.6271972656, -164.84530639648),
            vector2(1119.3985595703, -144.92828369141),
            vector2(1129.4849853516, -135.5068359375)
        },
        minZ = 50.772033691406,
        maxZ = 55.678325653076
    },
}

