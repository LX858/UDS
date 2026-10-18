Config = {}

-- ═══════════════════════════════════════════════════════════════════
-- ║                       GENERAL SETTINGS                          ║
-- ═══════════════════════════════════════════════════════════════════

-- Serial text prefix cho vũ khí
Config.Textserial = "ST"

-- Discord Webhook Logs
Config.DiscordLogs = {
    link = "https://discord.com/api/webhooks/1512791703160098836/PilpisREIwhz9FiGbwzcMCLG0HE2tTMl6HMgQPJjJCzVXcQw8s1NevMo0Z4e44zvaRvf",
    communityName = "UNDER STAR CRAFTING",
    username = "Under-star",
    avatar = nil,
    color = 15631086
}

-- ═══════════════════════════════════════════════════════════════════
-- ║                       LUCKY CHARMS                              ║
-- ═══════════════════════════════════════════════════════════════════

Config.Lucky = {
    -- [10] = {
    --     item = 'buamaymancapmot',
    -- },
    -- [20] = {
    --     item = 'buamaymancaphai',
    -- },
    -- [30] = {
    --     item = 'buamaymancapba',
    -- },
}

-- ═══════════════════════════════════════════════════════════════════
-- ║                       WEAPON SYSTEM                             ║
-- ═══════════════════════════════════════════════════════════════════

-- Weapon Level to Rarity Mapping (giống XNClothes DoHiem system)
-- ox_inventory sẽ đọc metadata.DoHiem để hiển thị màu
Config.WeaponRarity = {
    [1] = 'Common',      -- Level 1: Xanh lá (Common)
    [2] = 'Uncommon',    -- Level 2: Xanh dương (Uncommon)
    [3] = 'Rare',        -- Level 3: Tím (Rare)
    [4] = 'Epic',        -- Level 4: Vàng (Epic)
    [5] = 'Legendary',   -- Level 5: Đỏ (Legendary)
}

-- Weapon Repair Config - Danh sách vũ khí có thể sửa + nguyên liệu
-- Key format: 'WEAPON_NAME_LVX' hoặc 'WEAPON_NAME' (cho level 1)
Config.WeaponRepair = {
    -- Cờ lê Level 2: CHO sửa
    ['WEAPON_WRENCH_LV2'] = {
        WeaponName = 'WEAPON_WRENCH',
        Level = 2,
        Label = 'Cờ lê LV2',
        RepairMaterials = {
            manhkimloai = {'Mảnh kim loại', 3},
            -- banvevukhi1 = {'Bản vẽ vũ khí 1', 1},
            -- banvevukhi2 = {'Bản vẽ vũ khí 2', 1},
            -- banvevukhi3 = {'Bản vẽ vũ khí 3', 1},
            -- banvevukhi4 = {'Bản vẽ vũ khí 4', 1},
        },
        RepairAmount = 100,  -- Sửa set về 100% độ bền (không dùng giá trị này nữa)
        Cash = 10000,
        Length = 4000,      -- Thời gian sửa (ms)
    },
    
    -- Gậy bóng chày Level 2: CHO sửa
    ['WEAPON_BAT_LV2'] = {
        WeaponName = 'WEAPON_BAT',
        Level = 2,
        Label = 'Gậy bóng chày LV2',
        RepairMaterials = {
            manhkimloai = {'Mảnh kim loại', 3},
            -- banvevukhi1 = {'Bản vẽ vũ khí 1', 1},
            -- banvevukhi2 = {'Bản vẽ vũ khí 2', 1},
            -- banvevukhi3 = {'Bản vẽ vũ khí 3', 1},
            -- banvevukhi4 = {'Bản vẽ vũ khí 4', 1},
        },
        RepairAmount = 100,  -- Sửa set về 100% độ bền (không dùng giá trị này nữa)
        Cash = 10000,
        Length = 3000,
    },
}

-- ═══════════════════════════════════════════════════════════════════
-- ║                    CRAFTING STATIONS                            ║
-- ═══════════════════════════════════════════════════════════════════

Config[1] = {
    Hash = 'mrm_craft_table_eletrica',
    Position = vector4(159.9892, -937.6042, 30.4963, 250.1977),
    Heading =  255.1977, 
    Blip = {
        Enable = true,
        Scale = 0.8,
        Sprite = 566,
        Color = 5,
        Label = 'Bàn chế tạo'
    },
    Categories = {
        {
            Name = 'Chế tạo vũ khí',
            Items = {
                {
                    Type = 'weapon',
                    Item = 'WEAPON_WRENCH',
                    Label = 'Cờ lê',
                    Tag = 'LV1',
                    Max = 1,
                    WeaponLevel = 1,
                    CraftItems = {
                        congcuren = {'Công cụ rèn', 1},
                        manhkimloai = {'Mảnh kim loại', 5},
                        banvevukhi = {'Bản vẽ vũ khí', 10},
                    },
                    PermItems = {},
                    Cash = 10000,
                    Length = 1000,
                    Chance = 100,
                    Failed = {}
                },
                {
                    Type = 'weapon',
                    Item = 'WEAPON_MACHETE',
                    Label = 'Dao Machete',
                    Tag = 'LV1',
                    Max = 1,
                    WeaponLevel = 1,
                    CraftItems = {
                        congcuren = {'Công cụ rèn', 5},
                        cong_thuc_machete = {'Bản vẽ machete', 50},
                    },
                    PermItems = {
                        WEAPON_WRENCH = {'Cờ lê', 1},
                    },
                    Cash = 500000,
                    Length = 1000,
                    Chance = 100,
                    Failed = {}
                },
            }
        },
        {
            Name = 'Chế tạo công cụ',
            Items = {
                {
                    Type = 'item',
                    Item = 'cong_thuc_machete',
                    Label = 'Công thức Machete',
                    Tag = 'LV1',
                    Max = 10,
                    CraftItems = {
                        hoa_mynhan = {'Hoa Mỹ nhân', 10},
                        traidudu = {'Trái đu đủ', 10},
                        tinhthach =  {'tinh thạch', 10},
                        the_sieu_trom = {'Thẻ Siêu Trộm', 1},
                        
                    },
                    PermItems = {},
                    Cash = 0,
                    Length = 10000,
                    Chance = 100,
                    Failed = {}
                },
                {
                    Type = 'item',
                    Item = 'kimloaitinhche',
                    Label = 'Kim loại tinh chế',
                    Tag = 'LV1',
                    Max = 10,
                    CraftItems = {
                        volon = {'Vỏ lon', 25},
                    },
                    PermItems = {},
                    Cash = 0,
                    Length = 5000,
                    Chance = 100,
                    Failed = {}
                },
                {
                    Type = 'item',
                    Item = 'lockpick',
                    Label = 'Phá khóa',
                    Tag = 'LV1',
                    Max = 10,
                    CraftItems = {
                        ls_iron_ingot = {'Thỏi sắt', 1},
                        kimloaitinhche = {'Kim loại tinh chế', 1},
                    },
                    PermItems = {},
                    Cash = 500,
                    Length = 5000,
                    Chance = 100,
                    Failed = {}
                },
                
                -- {
                --     Type = 'item',
                --     Item = 'may_cau',
                --     Label = 'Máy Câu',
                --     Tag = 'LV1',
                --     Max = 10,
                --     CraftItems = {
                --         kimloaitinhche = {'Kim loại tinh chế', 1},
                --         carbon = {'carbon', 1},
                --     },
                --     PermItems = {},
                --     Cash = 0,
                --     Length = 5000,
                --     Chance = 100,
                --     Failed = {}
                -- },

                {
                    Type = 'item',
                    Item = 'congcuren',
                    Label = 'Công Cụ Rèn',
                    Tag = 'LV1',
                    Max = 10,
                    CraftItems = {
                        manh_boom_vo = {'Mảnh Bom Vỡ', 10},
                    },
                    PermItems = {},
                    Cash = 0,
                    Length = 5000,
                    Chance = 100,
                    Failed = {}
                },

                {
                    Type = 'item',
                    Item = 'bua_may_man',
                    Label = 'Xu May Mắn',
                    Tag = 'LV1',
                    Max = 1,
                    CraftItems = {
                        co_bon_la_1 = {'Cỏ bốn lá số 1', 30},
                        co_bon_la_2 = {'Cỏ bốn lá số 2', 30},
                        co_bon_la_3 = {'Cỏ bốn lá số 3', 30},
                        co_bon_la_4 = {'Cỏ bốn lá số 4', 30},
                        co_bon_la_5 = {'Cỏ bốn lá số 5', 30},
                        co_bon_la_6 = {'Cỏ bốn lá số 6', 30},
                        co_bon_la_7 = {'Cỏ bốn lá số 7', 30},
                        co_bon_la_8 = {'Cỏ bốn lá số 8', 30},
                        co_bon_la_9 = {'Cỏ bốn lá số 9', 10},
                        co_bon_la_10 = {'Cỏ bốn lá số 10', 10},
                    },
                    PermItems = {},
                    Cash = 50000,
                    Length = 5000,
                    Chance = 100,
                    Failed = {}
                },

                {
                    Type = 'item',
                    Item = 'advalockpicknced',
                    Label = 'Phá khóa nâng cao',
                    Tag = 'LV2',
                    Max = 5,
                    CraftItems = {
                        lockpick = {'Lockpick', 5},
                    },
                    PermItems = {},
                    Cash = 5000,
                    Length = 5000,
                    Chance = 100,
                    Failed = {}
                },
            }
        },
    }
}