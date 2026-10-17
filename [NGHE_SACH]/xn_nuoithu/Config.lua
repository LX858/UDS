Config = {}

Config._ResetTime = 120 -- Tính theo phút
Config.ThucAn = "thucanthu"
Config.PhanThuong = "money"
Config.SoLuong = math.random(200, 250)
Config.SoLuong_ChamSoc_ToiDa = 5
Config.Pet_Shop = vector4(-3031.29, 92.34, 12.35, 317.89)
Config.Pet_Shop_2 = vector4(-1886.64, -876.9, 7.86, 76.72)

-- Cấu hình các loại động vật với tỷ lệ spawn và thời gian phát triển
Config.AnimalTypes = {
	{ped = "pigagle", chance = 85, growTime = 5 * 60 * 1000}, -- 5 phút
	{ped = "cowbig", chance = 14, growTime = 10 * 60 * 1000}, -- 10 phút
	{ped = "zebra", chance = 1, growTime = 15 * 60 * 1000}, -- 15 phút (50% trong 1%)
	-- {ped = "Capibara_Cute", chance = 0.5, growTime = 15 * 60 * 1000}, -- 15 phút (25% trong 1%)
	-- {ped = "Littleram_ped", chance = 0.5, growTime = 15 * 60 * 1000}, -- 15 phút (25% trong 1%)
}

-- Phần thưởng cho từng loại động vật
Config.AnimalRewards = {
	["pigagle"] = {
		item = "conheo",
		amount = 1
	},
	["cowbig"] = {
		item = "conbo",
		amount = 1
	},
	["zebra"] = {
		item = "aplaca",
		amount = 1
	}
	-- ["Capibara_Cute"] = {
	-- 	item = "capibara",
	-- 	amount = 1
	-- },
	-- ["Littleram_ped"] = {
	-- 	item = "littleram",
	-- 	amount = 1
	-- }
}

Config.Feed = {
	{
		ped = "pigagle", -- Sẽ được override bởi random animal
		coords = vec3(1487.12, 1067.48, 114.33),
		coords_2 = vec3(1487.12, 1067.48, 114.33),
		range = 50,
		text = "<FONT FACE='Oswald'>~r~KHU VỰC CHĂM SÓC THÚ CƯNG",
		percent_feed = {math.random(10, 20), math.random(30, 40) , math.random(50, 60) , math.random(70, 90)},
		need = 2, -- THỜI GIAN ĐÓI
		time_need = 10 * 1000, -- THỜI GIAN TĂNG PHÁT TRIỂN
		blips = {
			enabled = true,
			sprite = 463,
			scale = 1.0,
			color = 3,
			text = "<FONT FACE='Oswald'>~o~[CÔNG VIỆC]~w~ CHĂM SÓC THÚ CƯNG",
		},
		item = {
			use = "trung_thu",
		},
	},
}

Config.Setting = {
	marker = {
		intensive = 70,
		normal = {r = 0, g = 255, b = 85},
		feed = {r = 255, g = 247, b = 0},
		kill = {r = 255, g = 0, b = 0},
	},
	animal = {
		distance = {
			text = 5,
			press = 1.2,
		},
	},
}

Config.Shop_ChamSocThuCung = {
	[1] = {
		name = "trung_thu",
		price = 200,
		amount = 5000,
		type = "item",
		slot = 1,
	},
	[2] = {
		name = "thucan",
		price = 20,
		amount = 5000,
		type = "item",
		slot = 2,
	},

}

Config.Locations_s = {
    ["ViTri"] = vec3(1487.12, 1067.48, 114.33) -- VÙNG CÔNG VIỆC
}

Config.Price = {
    ["corgi"] = {
        price = 925,
        min_price = 900,
        max_price = 950,
    }, 
}

-- Hệ thống nâng cấp
Config.Upgrade = {
    -- Điểm kỹ năng nhận được khi thu hoạch
    SkillPoints = {
        ["pigagle"] = 5,        -- Heo
        ["cowbig"] = 10,       -- Bò
        ["zebra"] = 15,        -- Alpaca
        -- ["Capibara_Cute"] = 15, -- Capibara
        -- ["Littleram_ped"] = 15, -- Littleram
    },

    -- Mapping DoHiem rarity theo tier
    RarityMapping = {
        [1] = "Common",
        [2] = "Uncommon",
        [3] = "Rare",
        [4] = "Epic",
        [5] = "Legendary",
    },

    -- Danh sách item quần áo hợp lệ dùng để nâng cấp
    ClothingItems = {
        "cloth_mask", "cloth_helmet", "cloth_ears", "cloth_glasses",
        "cloth_tshirt", "cloth_torso", "cloth_bproof", "cloth_bracelets",
        "cloth_watches", "cloth_chain", "cloth_pants", "cloth_shoes", "cloth_arms",
    },
    
    -- Cấu hình các mốc nâng cấp (dùng quần áo có metadata DoHiem tương ứng)
    Tiers = {
        [1] = { -- Mốc 0 -> 1
            rarity = "Common",
            itemCount = 2,
            skillPoints = 10,
            successRate = 80,
        },
        [2] = { -- Mốc 1 -> 2
            rarity = "Uncommon",
            itemCount = 2,
            skillPoints = 15,
            successRate = 30,
        },
        [3] = { -- Mốc 2 -> 3
            rarity = "Rare",
            itemCount = 2,
            skillPoints = 20,
            successRate = 20,
        },
        [4] = { -- Mốc 3 -> 4
            rarity = "Epic",
            itemCount = 2,
            skillPoints = 25,
            successRate = 7,
        },
        [5] = { -- Mốc 4 -> 5
            rarity = "Legendary",
            itemCount = 2,
            skillPoints = 30,
            successRate = 5,
        },
    },
    
    -- Buff của từng chỉ số
    Stats = {
        luck = {
            name = "May mắn",
            description = "Tăng 1% tỷ lệ ra bò và lạc đà",
            maxLevel = 5,
            successRates = {80, 30, 20, 7, 5}, -- Tỷ lệ thành công cho mỗi level
        },
        time = {
            name = "Thời gian",
            description = "Giảm 1 phút thời gian trưởng thành",
            maxLevel = 5,
            successRates = {50, 25, 15, 5, 1}, -- Tỷ lệ thành công cho mỗi level
        },
        capacity = {
            name = "Sức chứa",
            description = "Tăng 1 slot chăm sóc",
            maxLevel = 5,
            baseCapacity = 5,
            maxCapacity = 10,
            successRates = {30, 20, 15, 5, 1}, -- Tỷ lệ thành công cho mỗi level
        },
    },
    
    -- Icon theo level tổng
    LevelIcons = {
        [0] = "pigagle",  -- Level 0-1
        [1] = "pigagle",
        [2] = "cowbig",   -- Level 2-3
        [3] = "cowbig",
        [4] = "zebra",    -- Level 4-5
        [5] = "zebra",
    },
}

Config.Main = {
    [1] = {
        name = "CỬA HÀNG THÚ CƯNG",
        description = "Bạn muốn giao lại cho tôi Corgi đã trưởng thành không?",
        coords =  vector4(-3031.29, 92.34, 12.35, 317.89),
        model = "u_m_m_streetart_01",
        market = {
            [1] = {
                name = "🐕‍🦺 Đồng ý", 
                description = "Giao lại Corgi cho cửa hàng",
                item = {
                    "corgi",
                }
            }
        }
    }
}