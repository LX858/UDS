Config = {}
Config.EnableTruckerjob = true -- Chỉ điều khiển tích hợp với lr_trucker_job

-- SỐ CẢNH SÁT ONLINE YÊU CẦU ĐỂ BÁN HÀNG TẠI CHỢ ĐEN (choden)
Config.ChodenRequiredCops = 0

-- Lịch đổi giá chỉ dành cho choden; các nhóm khác đổi giá theo tồn kho.
Config.TuDong_ThayDoiGia = true -- Bật = true, Tắt = false
Config.ThoiGian_CapNhat = 30 -- Tính theo phút

Config.TruckerIntegration = {
    AllowedResource = 'lr_trucker_job',
    CleanCategories = {
        fish = true,
        phelieu = true,
        mining = true,
        nuoithu = true,
        traicay = true,
    }
}

-- MINIGAME ROULETTE X2 KHI BÁN HẢI SẢN
Config.RouletteSell = {
    Enable = true,
    Category = 'fish',
    Multiplier = 2,
    WinChance = 35, -- phần trăm thắng khi chọn đỏ/đen
    ZeroChanceOnLose = 10, -- phần trăm lượt thua sẽ ra 0 hoặc 00
    Timeout = 30, -- giây để người chơi chọn đỏ/đen
    PayoutDelay = 16, -- giây sau khi bắt đầu quay mới trả tiền
    ForcePayoutAfter = 30, -- fallback trả tiền nếu client không báo quay xong
    TableCoords = vec4(226.0498, -937.6304, 30.4963, -109.1851),
    RedNumbers = { 1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36 }
}

-- TÊN HIỂN THỊ CHO CÁC DANH MỤC TRONG PHONE APP (dễ thay đổi sau này)
Config.CategoryNames = {
    ['vuanghe'] = '👑 Vua Nghề',
    ['fish'] = '🐟 Hải Sản',
    ['phelieu'] = '🔩 Phế Liệu',
    ['mining'] = '⛏️ Khoáng Sản',
    ['nuoithu'] = '🐄 Nuôi Thú',
    ['traicay'] = '🍊 Nông Nghiệp',
    ['choden'] = '💀 Chợ Đen'
}

    -- ['fish'] = {
    --     Label = 'Cá Nhỏ', --- Tên hiển thị trong menu
    --     Min = 70, -- Giá min bán (bước 1)
    --     Max = 90, -- Giá max bán (bước 6)
    --     RandomWhenStart = true, -- Khi server khởi động, giá sẽ được random ngẫu nhiên trong 6 bước giá (Min, +20%, +40%, +60%, +80%, Max)
    -- },

Config.Items = {
    ['fish'] = {
        ['tramco'] = {
            Label = 'Trắm cỏ',
            Min = 100,
            Max = 120,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 500
        },
        ['rophi'] = {
            Label = 'Cá rô',
            Min = 150,
            Max = 250,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 200
        },
        ['cachep'] = {
            Label = 'Cá Chép hồ',
            Min = 200,
            Max = 350,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 150
        },
        ['ca_chim'] = {
            Label = 'Cá chim',
            Min = 550,
            Max = 600,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 50
        },
        ['ca_hoi'] = {
            Label = 'Cá Hồi',
            Min = 600,
            Max = 750,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 50
        },
        ['ca_thu'] = {
            Label = 'Cá thu',
            Min = 550,
            Max = 750,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 200
        },
        ['tom_hum'] = {
            Label = 'Tôm hùm',
            Min = 800,
            Max = 1000,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 30
        },
        ['ca_ngu'] = {
            Label = 'Cá ngừ',
            Min = 1500,
            Max = 2000,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 50
        },
        ['shark'] = {
            Label = 'Cá Mập',
            Min = 2000,
            Max = 3000,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 50
        },
    },
    ['phelieu'] = {
        ['racthaidaphanloai'] = {
            Label = 'Rác thải phân loại',
            Min = 100,
            Max = 200,
            RandomWhenStart = true
        },

        ['khuyentaicu'] = {
            Label = 'Khuyên tai cũ',
            Min = 150,
            Max = 200,
            RandomWhenStart = true
        },

        ['machdienchay'] = {
            Label = 'Mạch điện cháy',
            Min = 100,
            Max = 200,
            RandomWhenStart = true
        },
    },
    ['mining'] = {
        ['dau_tho'] = {
            Label = 'Dầu thô',
            ReferencePrice = 300,
            Min = 240,
            Max = 360,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 50
        },

        -- ['than'] = {
        --     Label = 'Than',
        --     Min = 300,
        --     Max = 500,
        --     RandomWhenStart = true
        -- },
        -- ['sat'] = {
        --     Label = 'Sắt',
        --     Min = 500,
        --     Max = 600,
        --     RandomWhenStart = true
        -- },
        -- ['carbon'] = {
        --     Label = 'Kim Cương',
        --     Min = 700,
        --     Max = 800,
        --     RandomWhenStart = true
        -- },
    },
    ['choden'] = {
        ['traidudu'] = {
            Label = 'Trái đu đủ',
            Min = 200,
            Max = 400,
            RandomWhenStart = true,
            Cooldown = {
                MaxAmount = 100,
                Duration = 15 -- minutes
            }
        },
        -- ['sat'] = {
        --     Label = 'Sắt',
        --     Min = 500,
        --     Max = 600,
        --     RandomWhenStart = true
        -- },
        -- ['carbon'] = {
        --     Label = 'Kim Cương',
        --     Min = 700,
        --     Max = 800,
        --     RandomWhenStart = true
        -- },
    },
    ['nuoithu'] = {
        ['conheo'] = {
            Label = 'Heo',
            ReferencePrice = 600,
            Min = 480,
            Max = 720,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 50
        },

        ['conbo'] = {
            Label = 'Bò',
            ReferencePrice = 800,
            Min = 640,
            Max = 960,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 50
        },

        -- ['conbo'] = {
        --     Label = 'Con Bò',
        --     Min = 700,
        --     Max = 1000,
        --     RandomWhenStart = true
        -- },
        -- ['conheo'] = {
        --     Label = 'Con Heo',
        --     Min = 250,
        --     Max = 300,
        --     RandomWhenStart = true
        -- },
        -- ['aplaca'] = {
        --     Label = 'Lạc đà Alpaca',
        --     Min = 10000,
        --     Max = 15000,
        --     RandomWhenStart = true
        -- },
    },
     ['traicay'] = {
        ['luanuoc'] = {
            Label = 'Lúa nước',
            ReferencePrice = 300,
            Min = 240,
            Max = 360,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 300
        },

        ['la_che'] = {
            Label = 'Lá chè',
            ReferencePrice = 250,
            Min = 200,
            Max = 300,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 250
        },

        ['luami'] = {
            Label = 'Lúa mì',
            Min = 60,
            Max = 100,
            RandomWhenStart = true,
            RangeChange = {1, 4},
            AmountToChange = 300
        },

        ['coconut'] = {
            Label = 'Quả dừa',
            Min = 50,
            Max = 100,
            RandomWhenStart = true
        },
        ['orange'] = {
            Label = 'Quả Cam',
            Min = 50,
            Max = 100,
            RandomWhenStart = true
        },
        ['afk_item'] = {
            Label = 'Dâu tây',
            Min = 50,
            Max = 60,
            RandomWhenStart = true
        },
    },
}

-- Một điểm thu mua có thể phục vụ thêm danh mục mà vẫn giữ bảng item gốc
-- làm reference để đồng bộ item quản trị tạo sau khi resource đã chạy.
function Config.GetLocationItems(location)
    local items = location and location.Items or {}
    local extraItems = location and location.ExtraItems
    if not extraItems then return items end

    local combined = {}
    for itemName, itemData in pairs(items) do combined[itemName] = itemData end
    for itemName, itemData in pairs(extraItems) do
        if combined[itemName] == nil then combined[itemName] = itemData end
    end
    return combined
end

Config.Locations = {
    {
        Blip = {
            Enable = true,
            Sprite = 356,
            Color = 11,
            Scale = 0.7,
            Label = 'NGƯỜI THU MUA HẢI SẢN'
        },
        Coords = vec4(221.2021, -948.1803, 31.8274, 334.0873),
        NPCText = 'NGƯỜI THU MUA HẢI SẢN',
        Items = Config.Items['fish'],
        TargetName = "fish_dolly"
    },
    {
        Blip = {
            Enable = true,
            Sprite = 356,
            Color = 11,
            Scale = 0.7,
            Label = 'THƯƠNG LÁI MUA PHẾ LIỆU',
            ShortRange = false,
        },
        Coords = vec4(217.1170, -946.8849, 31.5246, 336.6717),
        NPCText = 'THƯƠNG LÁI MUA PHẾ LIỆU',
        Items = Config.Items['phelieu'],
        TargetName = "phelieu_dolly"
    },
    {
        Blip = {
            Enable = true,
            Sprite = 356,
            Color = 11,
            Scale = 0.7,
            Label = 'THƯƠNG LÁI MUA KHOÁNG SẢN',
            ShortRange = false,
        },
        Coords = vec4(219.9575, -936.0698, 31.4963, 155.8201),
        NPCText = 'THƯƠNG LÁI MUA KHOÁNG SẢN',
        Items = Config.Items['mining'],
        TargetName = "mining_dolly"
    },
    {
        Blip = {
            Enable = true,
            Sprite = 356,
            Color = 11,
            Scale = 0.7,
            Label = 'THƯƠNG LÁI MUA NÔNG SẢN & NUÔI THÚ',
            ShortRange = false,
        },
        Coords = vec4(213.4228, -945.4520, 31.8079, 335.0612),
        NPCText = 'THƯƠNG LÁI MUA NÔNG SẢN & NUÔI THÚ',
        Items = Config.Items['traicay'],
        ExtraItems = Config.Items['nuoithu'],
        TargetName = "fram_dolly"
    },
    {
        Blip = {
            Enable = false,
            Sprite = 356,
            Color = 11,
            Scale = 0.7,
            Label = 'Thương lái chợ đen',
            ShortRange = false,
        },
        Coords = vec4(-1171.2560, -1571.1517, 3.6636, 124.8036),
        NPCText = 'THƯƠNG LÁI CHỢ ĐEN',
        Items = Config.Items['choden'],
        TargetName = "choden_dolly"
    },
}

