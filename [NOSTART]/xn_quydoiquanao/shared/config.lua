Config = {}

-- Mapping giữa UI slot và item name trong inventory
Config.UIToItemMapping = {
    ['shirt'] = 'cloth_tshirt',
    ['torso'] = 'cloth_torso',
    ['pants'] = 'cloth_pants',
    ['shoes'] = 'cloth_shoes',
    ['gloves'] = 'cloth_arms',
    ['mask'] = 'cloth_mask',
    ['vest'] = 'cloth_bproof',
    ['chain'] = 'cloth_chain',
    ['bag'] = 'cloth_bags',
    ['earrings'] = 'cloth_ears',
    ['hat'] = 'cloth_helmet',
    ['glasses'] = 'cloth_glasses',
    ['watch'] = 'cloth_watches',
    ['bracelets'] = 'cloth_bracelets'
}

-- Component mapping cho build URL ảnh (dùng component ID số)
Config.ComponentMapping = {
    ['shirt'] = { id = 8, isProp = false },      -- Component 8: Undershirt
    ['torso'] = { id = 11, isProp = false },     -- Component 11: Torso/Jackets
    ['pants'] = { id = 4, isProp = false },      -- Component 4: Legs
    ['shoes'] = { id = 6, isProp = false },      -- Component 6: Shoes
    ['gloves'] = { id = 3, isProp = false },     -- Component 3: Arms/Gloves
    ['mask'] = { id = 1, isProp = false },       -- Component 1: Mask
    ['vest'] = { id = 9, isProp = false },       -- Component 9: Body Armor
    ['chain'] = { id = 7, isProp = false },      -- Component 7: Accessories/Neck
    ['bag'] = { id = 5, isProp = false },        -- Component 5: Bags
    ['earrings'] = { id = 2, isProp = true },    -- Prop 2: Ears
    ['hat'] = { id = 0, isProp = true },         -- Prop 0: Hats/Helmets
    ['glasses'] = { id = 1, isProp = true },     -- Prop 1: Glasses
    ['watch'] = { id = 6, isProp = true },       -- Prop 6: Watches
    ['bracelets'] = { id = 7, isProp = true }    -- Prop 7: Bracelets
}

-- Label hiển thị cho từng slot
Config.ClothingSlots = {
    ['shirt'] = 'Áo Trong',
    ['torso'] = 'Áo Khoác',
    ['pants'] = 'Quần',
    ['shoes'] = 'Giày',
    ['gloves'] = 'Gang Tay',
    ['mask'] = 'Mặt Nạ',
    ['vest'] = 'Áo Giáp',
    ['chain'] = 'Vòng Cổ',
    ['bag'] = 'Balo',
    ['earrings'] = 'Nhẫn',
    ['hat'] = 'Mũ',
    ['glasses'] = 'Kính',
    ['watch'] = 'Đồng Hồ',
    ['bracelets'] = 'Vòng Tay'
}

-- Màu theo độ hiếm
Config.RarityColors = {
    ['Common'] = '#22c55e',
    ['Uncommon'] = '#3b82f6',
    ['Rare'] = '#a855f7',
    ['Epic'] = '#f59e0b',
    ['Legendary'] = '#ef4444'
}

-- URL và extension cho ảnh quần áo
Config.Url = "https://raw.githubusercontent.com/xuannguyen995/miniclothing/refs/heads/main"
Config.Extension = "webp"

-- Command và key
Config.Command = "doiquanao"
Config.OpenKey = nil -- Set nil nếu không dùng key, hoặc 'F5' chẳng hạn

-- Location để mở shop (set nil nếu không dùng location, chỉ dùng command)
Config.Location = {
    coords = vec4(206.3234, -887.6556, 29.4835, 71.2557),
    pedModel = 's_m_m_strperf_01', -- Model của NPC
    target = {
        label = "Trao Đổi Quần Áo",
        icon = "fas fa-tshirt",
        distance = 2.5
    }
}

-- Debug mode (hiển thị logs)
Config.Debug = false

-- Cooldown (milliseconds)
Config.ExchangeCooldown = 1500

-- Cho phép trao đổi quần áo mới (metadata isnew = 'yes')
Config.AllowNewItems = true

-- Thông báo
Config.Notify = {
    no_item = "Bạn không có item quần áo hợp lệ để trao đổi.",
    invalid_item = "Item quần áo không hợp lệ.",
    invalid_rarity = "Độ hiếm của item không hợp lệ.",
    invalid_drawable = "Trang phục này không nằm trong nhóm có thể trao đổi.",
    invalid_sex = "Nhân vật hiện tại không hợp lệ.",
    invalid_item_sex = "Bạn chỉ có thể trao đổi quần áo khác giới tính với nhân vật hiện tại.",
    invalid_new_item = "Bạn không thể trao đổi quần áo mới.",
    success = "Trao đổi quần áo thành công.",
    failed = "Trao đổi thất bại.",
    cooldown = "Vui lòng chờ trước khi trao đổi tiếp.",
    no_permission = "Bạn không có quyền thực hiện thao tác này."
}

-- Danh sách drawable theo độ hiếm
-- Lưu ý: Bạn cần điền đầy đủ drawable vào các mảng này theo dữ liệu thực tế của server
Config.Dohiem = {
    ['female'] = {
        ['cloth_tshirt'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {295,306,339,346,353,355,359,360,363,370,376,383,386,387,395,414,421,424,429,431,432,436,437,440,442,445,452,456},
            ['Epic'] = {321,322,337,348,362,401,404,407,411,434,435,438,439,441,449,450,458},
            ['Legendary'] = {}
        },
        ['cloth_torso'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {589,674,676,677,687,688,695,705,722,723,725,741,752,761,773,784,785,827,828,830,833,835,838,839,842,844,845,846,847,848,849,850,852,854,855,858,859,860,861,862,865,868,870,872,885,889,896,898,900,902,903,904,908,909,910,913,915,916,917,920,921},
            ['Epic'] = {603,604,605,606,607,617,618,780,786,826,837,841,843,851,856,897,901,907,911,912,914,918,919},
            ['Legendary'] = {588, 590, 591, 609, 613}
        },
        ['cloth_pants'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_shoes'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {174,178,181,182,188,198,199,209,211,215,224,226,228,235,237},
            ['Epic'] = {168,190,212,241},
            ['Legendary'] = {}
        },
        ['cloth_arms'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_helmet'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_glasses'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_mask'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_bproof'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_bags'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_bracelets'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_ears'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_chain'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_watches'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        }
    },

    ['male'] = {
        ['cloth_tshirt'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {252,253,255,256,263,264,271,274,291,297,305,313,322,323,324},
            ['Epic'] = {250,257,287,314,325},
            ['Legendary'] = {}
        },
        ['cloth_torso'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {559,560,561,621,641,645,676,679,680,682,684,686,687,697,700,714,722,727,733,735,746,747,748,751,757,758,759,761,764,791,796,802,804,806,808,809,810,811,812,815,817,820,824,825,829,839,840,844,845,846,847,848,850,853,854,855,857,858,861,862,866,878,885,886,889,891},
            ['Epic'] = {562,563,666,677,685,696,699,723,743,749,750,765,792,798,822,823,837,838,852,863,867,868,869,870,882,887,892,895},
            ['Legendary'] = {544, 546, 547, 565, 569}
        },
        ['cloth_pants'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {226,247},
            ['Epic'] = {},
            ['Legendary'] = {278}
        },
        ['cloth_shoes'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {146,147,153,157,158,160,161,164,166,167,175,176,179,180,183,186,188,190,192,194,198,204,211,213,219,220,225,226,231,232,233,235,241,242,243,244,245,247,250,253,255,266,268,270,272},
            ['Epic'] = {165,181,189,199,210,216,218,236,246,252,271,273,285},
            ['Legendary'] = {}
        },
        ['cloth_arms'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_helmet'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_glasses'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_mask'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_bproof'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_bags'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_bracelets'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_ears'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_chain'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        },
        ['cloth_watches'] = {
            ['Common'] = {},
            ['Uncommon'] = {},
            ['Rare'] = {},
            ['Epic'] = {},
            ['Legendary'] = {}
        }
    }
}
