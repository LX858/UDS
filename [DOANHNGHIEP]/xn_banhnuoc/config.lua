custom = 'custom' -- Keyword cho item có giá tùy chỉnh
Config = {}

-- Debug configuration
Config.debug = false

-- Locale configuration
Config.Locale = 'vi' -- Ngôn ngữ mặc định

-- Global settings
Config.GlobalSettings = {
    -- Cấp bậc tối thiểu (job grade) mặc định để chỉnh giá custom
    defaultCustomPriceMinGrade = 4,

    -- URL mặc định cho hình ảnh item (có thể override trong từng shop)
    itemImageUrl = 'https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/',
    
    -- Icon mặc định cho shop (emoji hoặc URL hình ảnh, có thể override trong từng shop)
    shopIcon = '🍽️',
    
    -- Khoảng cách mặc định cho target zones
    defaultTargetRadius = 1.5,
    
    -- Thời gian tự động xóa đơn hàng đã hoàn thành (phút), 0 = không xóa
    orderCleanupTime = 30,
    
    -- Số đơn hàng tối đa mỗi shop, 0 = không giới hạn
    maxOrdersPerShop = 50,

    -- Phần trăm hoa hồng mặc định trích cho nhân viên khi bán thành công (%)
    defaultCommissionPercent = 10,
}

-- Function để lấy text từ locales
function _(key, ...)
    local locale = Locales[Config.Locale]
    if not locale then
        if Config.debug then
            print("Locale not found: " .. Config.Locale)
        end
        return key
    end
    
    local text = locale[key]
    if not text then
        if Config.debug then
            print("Translation not found for key: " .. key)
        end
        return key
    end
    
    -- Xử lý string formatting nếu có arguments
    if ... then
        return string.format(text, ...)
    end
    
    return text
end

Config.Shops = {

    ['quanbar'] = {
        label = 'bar_shop',
        shopIcon = '🥤',
        job = 'bar',
        -- coords: có thể là 1 tọa độ vec3(...) hoặc danh sách nhiều tọa độ { vec3(...), vec3(...) }
        coords = vec3(389.75927734375,-309.7021484375,49.430976867676),
        -- Ví dụ nhiều quầy bán/đặt hàng:
        -- coords = {
        --     vec3(389.75927734375,-309.7021484375,49.430976867676),
        --     vec3(392.1234,-310.5678,49.43),
        -- },
        stash = vec3(389.66571044922,-322.62042236328,49.397903442383),
        stash_sell =  vec3(391.76705932617,-317.18392944336,49.397903442383),
        discordWebhook = 'https://discord.com/api/webhooks/1539330278944940193/uiWnzvxle6y0j-26Jpb-4pv34lYkqw2uD2p8xyrf2zEKvh4i6UMn8xhRmJWpzbSyPfaY', -- Webhook log cho quán nước
        customPriceMinGrade = 4, -- Cấp bậc tối thiểu (job grade) để được chỉnh giá các item custom
        commission = {
            enabled = true,   -- Bật trích phần trăm cho nhân viên khi bán thành công
            percent = 10,     -- 10% hoa hồng cho nhân viên
        },
        stash_config = {
            slots = 25,
            weight = 500000,
            minGrade = 1,      -- Cấp bậc tối thiểu để mở kho (cất đồ vào)
            minGradeTake = 4,  -- Cấp bậc tối thiểu (job grade >= 3) mới lấy được đồ ra (cấp < 3 chỉ đưa đồ vào được)
        },
        stash_sell_config = {
            slots = 5,
            weight = 500000,  -- 100kg
            minGrade = 3,
        },
        target_config = {
            order_radius = 1.5,
            stash_radius = 1.5,
        },
        order_config = {
            requireEmployee = true,
            allowSelfService = false,
        },
        -- Vật phẩm BÁN ĐƯỢC và GIÁ:
        -- Đặt giá là số (vd: 800) -> Giá cố định
        -- Đặt là 'custom' hoặc custom -> Cho phép cấp bậc (grade >= customPriceMinGrade) tùy chỉnh giá trong game
        items = {
            ['ciga_hp'] = 800,
            ['red_wine_glass'] = 'custom',   -- Ly rượu vang đỏ (custom giá theo job grade 4)
            ['white_wine_glass'] = 'custom', -- Ly rượu vang trắng (custom giá theo job grade 4)
            ['rose_wine_glass'] = 'custom',  -- Ly rượu vang hồng (custom giá theo job grade 4)
            ['acid'] = 'custom', -- Acid (custom giá theo job grade 4)
        },
        -- Vật phẩm ĐƯỢC PHÉP BỎ VÀO STASH (nguyên liệu, bao bì, thành phẩm, ...)
        stash_items = {
            'lathuocla',
            'ciga_hp',
            'ladudu_tuoi',
            'red_wine_glass',
            'white_wine_glass',
            'rose_wine_glass',
            'red_wine_bottle',
            'white_wine_bottle',
            'rose_wine_bottle',
            'red_wine_glass',
            'white_wine_glass',
            'rose_wine_glass',
            'hoa_mynhan',
            'la_hoamynhan',
            'acid',
        },
        -- Vật phẩm ĐƯỢC PHÉP BỎ VÀO KHO BÁN (chỉ thành phẩm bán được)
        stash_sell_items = {
            'acid',
            'ciga_hp',
            'red_wine_glass',
            'white_wine_glass',
            'rose_wine_glass',
        },
    },

    ['bar'] = {
        label = 'quannuoc',
        shopIcon = '🥤',
        job = 'quannuoc',
        coords = vec3(214.6596, -961.8030, 32.9034), --vector3(214.6596, -961.8030, 32.9034)
        stash = vec3(216.0342, -962.4194, 32.1632),
        stash_sell =  vec3(215.6340, -964.7753, 32.1636),
        discordWebhook = '', -- Webhook log cho quán nước
        commission = {
            enabled = false,  -- Tắt trích hoa hồng cho nhân viên
            percent = 10,
        },
        stash_config = {
            slots = 25,
            weight = 500000,
            minGrade = 1,  -- Cấp bậc tối thiểu để mở kho
        },
        stash_sell_config = {
            slots = 5,
            weight = 500000,  -- 100kg
            minGrade = 3,
        },
        target_config = {
            order_radius = 1.5,
            stash_radius = 1.5,
        },
        order_config = {
            requireEmployee = true,
            allowSelfService = false,
        },
        -- Vật phẩm BÁN ĐƯỢC và GIÁ (chỉ những item này khách mới đặt mua được)
        items = {
            ['trada_utso'] = 500,
            ['nuocdua_utso'] = 800,
        },
        -- Vật phẩm ĐƯỢC PHÉP BỎ VÀO STASH (nguyên liệu, bao bì, thành phẩm, ...)
        stash_items = {
            'nuocdua_utso',
            'trada_utso',
            'nuocloc',
            'la_che',
            'coconut',
        },
        -- Vật phẩm ĐƯỢC PHÉP BỎ VÀO KHO BÁN (chỉ thành phẩm bán được)
        stash_sell_items = {
            'nuocdua_utso',
            'trada_utso',
        },
    },

    ['restaurant_shop'] = {
        label = 'restaurant_shop',
        shopIcon = '🍽️',
        job = 'quanan',
        coords = vec3(321.52587890625,-1645.8511962891,32.583156585693),
        stash = vec3(321.78677368164,-1650.6796875,32.708847045898),
        stash_sell = vec3(320.55575561523,-1649.3017578125,32.945339202881),
        discordWebhook = 'https://discord.com/api/webhooks/1547619813835407523/7uy9lTLgl-8bPHaHWp9tBWz2oumQoM_DctNk4ZB5mEt2rahc_0HpvgkfcQVDmWMTIwjl', -- Webhook log cho quán ăn
        commission = {
            enabled = false,  -- Tắt trích hoa hồng cho nhân viên
            percent = 10,
        },
        stash_config = {
            slots = 25,
            weight = 500000,
            minGrade = 1,  -- Cấp bậc tối thiểu để mở kho
        },
        stash_sell_config = {
            slots = 5,
            weight = 500000,  -- 100kg
            minGrade = 3,
        },
        target_config = {
            order_radius = 1.5,
            stash_radius = 1.5,
        },
        order_config = {
            requireEmployee = true,
            allowSelfService = false,
        },
        -- Vật phẩm BÁN ĐƯỢC và GIÁ
        items = {
            ['com_suon_tam_9h'] = 800,
        },
        -- Vật phẩm ĐƯỢC PHÉP BỎ VÀO STASH
        stash_items = {  
            'com_suon_tam_9h',
            'luanuoc',
            'conheo',
            'conbo',
        },
        -- Vật phẩm ĐƯỢC PHÉP BỎ VÀO KHO BÁN (chỉ thành phẩm bán được)
        stash_sell_items = {   
            'com_suon_tam_9h',
        },
    },

    ['vukhi_shop'] = {
        label = 'vukhi_shop',
        shopIcon = '⚔️',
        job = 'vukhi',
        coords = {
            vec3(252.64735412598,-51.451732635498,70.175994873047),
            vec3(4630.2266, -4464.4565, 4.2828),
        },
        stash = vec3(253.4341, -52.9350, 69.9411),
        stash_sell = vec3(253.4341, -52.9350, 69.9411),
        discordWebhook = 'https://discord.com/api/webhooks/1547619813835407523/7uy9lTLgl-8bPHaHWp9tBWz2oumQoM_DctNk4ZB5mEt2rahc_0HpvgkfcQVDmWMTIwjl', -- Webhook log cho quán ăn
        commission = {
            enabled = false,  -- Tắt trích hoa hồng cho nhân viên
            percent = 10,
        },
        stash_config = {
            slots = 25,
            weight = 50000000,
            minGrade = 3,  -- Cấp bậc tối thiểu để mở kho
        },
        stash_sell_config = {
            slots = 5,
            weight = 50000000,  -- 100kg
            minGrade = 3,
        },
        target_config = {
            order_radius = 1.5,
            stash_radius = 1.5,
        },
        order_config = {
            requireEmployee = true,
            allowSelfService = false,
        },
        -- Vật phẩm BÁN ĐƯỢC và GIÁ
        items = {
            ['bosuavukhi_cole'] = 50000,
            ['bosuavukhi_machete'] = 100000,
        },
        -- Vật phẩm ĐƯỢC PHÉP BỎ VÀO STASH
        stash_items = {
            'bosuavukhi_machete',   
            'bosuavukhi_cole',
        },
        -- Vật phẩm ĐƯỢC PHÉP BỎ VÀO KHO BÁN (chỉ thành phẩm bán được)
        stash_sell_items = {
            'bosuavukhi_machete',   
            'bosuavukhi_cole',
        },
    },
    
    -- Ví dụ thêm shop mới:
    -- ['restaurant'] = {
    --     label = 'restaurant_shop',
    --     job = 'restaurant',
    --     coords = vec3(0, 0, 0),
    --     stash = vec3(0, 0, 0),
    --     stash_config = {
    --         slots = 30,
    --         weight = 150000
    --     },
    --     blip = {
    --         sprite = 106,
    --         color = 1,
    --         scale = 0.8,
    --         display = 4,
    --     },
    --     items = {
    --         ['burger'] = 50,
    --         ['water'] = 20,
    --     }
    -- },
}

-- Cấu hình chung cho crafting
Config.CraftingSettings = {
    maxQuantityPerCraft = 10,  -- Số lượng tối đa mỗi lần chế biến
}

-- Cấu hình NPC bán hàng offline
Config.NpcSettings = {
    pricePerHour = 5000,   -- 5.000$ / 1 giờ
    maxHours    = 24,      -- Số giờ tối đa có thể thuê 1 lần
}

-- Cấu hình animations mặc định cho từng loại công việc
Config.CraftingAnimations = {
    -- Pha chế bartender
    bartender = {
        dict = 'amb@prop_human_bbq@male@base',
        anim = 'base',
        flag = 49,
        prop = nil  -- Không dùng prop để tránh lỗi
    },
    
    -- Nấu ăn
    cooking = {
        dict = 'amb@prop_human_bbq@male@base',
        anim = 'base',
        flag = 49,
        prop = nil  -- Không dùng prop để tránh lỗi
    },
    
    -- Pha cà phê
    coffee = {
        dict = 'mini@sprunk',
        anim = 'plyr_buy_drink_pt1',
        flag = 49,
        prop = nil
    },
}

Config.Crafting = {
    -- Bàn pha chế cho quán nước (bar)
    ['bar_crafting'] = {
        label = 'Pha chế đồ uống',
        job = 'quannuoc',
        minGrade = 0,  -- Cấp bậc tối thiểu để chế biến
        coords = vec3(214.5941, -965.9333, 32.1635),
        target_radius = 1.5,
        
        -- Sử dụng animation bartender
        animation = Config.CraftingAnimations.bartender,
        
        recipes = {
            {
                name = 'nuocdua_utso',
                label = 'Nước dừa',
                count = 1,
                duration = 2000,
                ingredients = {
                    { name = 'coconut', count = 1 },
                }
            },
            {
                name = 'trada_utso',
                label = 'Trà đá Út sổ',
                count = 1,
                duration = 2000,
                ingredients = {
                    { name = 'la_che', count = 1 },
                    -- { name = 'nuocloc', count = 1 },
                }
            },
        },
    },

    -- Bàn nấu ăn cho nhà hàng
    ['restaurant_crafting'] = {
        label = 'Nấu ăn',
        job = 'quanan',
        minGrade = 0,  -- Cấp bậc tối thiểu để chế biến
        coords = vec3(317.85821533203,-1647.2297363281,32.705383300781),
        target_radius = 1.5,
        
        -- Sử dụng animation cooking
        animation = Config.CraftingAnimations.cooking,
        
        recipes = {
            {
                name = 'com_suon_tam_9h',
                label = 'x8 Cơm sườn tấm',
                count = 8,
                duration = 2000,
                ingredients = {
                    { name = 'luanuoc', count = 5 },
                    { name = 'conheo', count = 4 },
                }
            },
      
            -- Thêm công thức khác ở đây
        }
    },

    ['bar_chetao'] = {
        label = 'Chế biến quán bar',
        job = 'bar',
        minGrade = 0,  -- Cấp bậc tối thiểu để chế biến
        coords = vec3(390.85632324219,-320.26473999023,49.400409698486),
        target_radius = 1.5,
        
        -- Sử dụng animation bartender
        animation = Config.CraftingAnimations.bartender,
        
        recipes = {
            {
                name = 'ciga_hp',
                label = 'Điếu thuốc',
                count = 1,
                duration = 2000,
                ingredients = {
                    { name = 'lathuocla', count = 1 },
                }
            },
            {
                name = 'red_wine_glass',
                label = 'Ly Rượu Vang Đỏ',
                count = 3,
                duration = 2000,
                ingredients = {
                    { name = 'red_wine_bottle', count = 1 },
                }
            },
            {
                name = 'white_wine_glass',
                label = 'Ly Rượu Vang Trắng',
                count = 3,
                duration = 2000,
                ingredients = {
                    { name = 'white_wine_bottle', count = 1 },
                }
            },
            {
                name = 'rose_wine_glass',
                label = 'Ly Rượu Vang Hồng',
                count = 3,
                duration = 2000,
                ingredients = {
                    { name = 'rose_wine_bottle', count = 1 },
                }
            },
            {
                name = 'acid',
                label = 'TEM TIÊN CẢNH',
                count = 1,
                duration = 2000,
                ingredients = {
                    { name = 'hoa_mynhan', count = 1 },
                }
            },
        },
    },

    ['vukhi_shop'] = {
        label = 'Bán công cụ',
        job = "vukhi",                        -- nil = tất cả có thể dùng
        coords = vec3(252.15475463867,-53.563961029053,70.180671691895),
        target_radius = 1.5,
        animation = Config.CraftingAnimations.cooking,
        recipes = {
            {
                name = 'bosuavukhi_cole',
                label = 'Bộ sửa vũ khí',
                count = 1,
                duration = 3000,
                ingredients = {
                    { name = 'bread', count = 2 },
                    { name = 'ham', count = 1 },
                }
            },
        }
    },

    -- Ví dụ bàn chế tạo công cộng
    -- ['public_cooking'] = {
    --     label = 'Bếp công cộng',
    --     job = nil,                        -- nil = tất cả có thể dùng
    --     coords = vec3(0, 0, 0),
    --     target_radius = 1.5,
    --     animation = Config.CraftingAnimations.cooking,
    --     recipes = {
    --         {
    --             name = 'sandwich',
    --             label = 'Sandwich',
    --             count = 1,
    --             duration = 3000,
    --             ingredients = {
    --                 { name = 'bread', count = 2 },
    --                 { name = 'ham', count = 1 },
    --             }
    --         },
    --     }
    -- },
}