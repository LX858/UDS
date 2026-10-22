Config = {}

-- Cấu hình các kho đồ cho từng công việc
Config.Stashes = {
    -- mechanic = {
    --     coords = vec3(-316.91, -129.96, 39.02),
    --     label = "Kho Đồ Thợ Máy",
    --     job = "mechanic",
    --     stashId = "mechanic_stash",
    --     slots = 50,
    --     weight = 400000, -- 400kg
    --     icon = "fas fa-toolbox",
    --     groups = {
    --         mechanic = 2 -- Minimum grade required
    --     }
    -- },

    -- mechanicboss = {
    --     coords = vec3(-342.87, -157.74, 44.59),
    --     label = "Kho Đồ Boss MCN",
    --     job = "mechanic",
    --     stashId = "mechanicboss_stash",
    --     slots = 25,
    --     weight = 100000, -- 100kg
    --     icon = "fas fa-toolbox",
    --     groups = {
    --         mechanic = 4 -- Minimum grade required
    --     }
    -- },
    -- Thêm các công việc khác ở đây
    cardealer = {
        coords = vec3(-809.9256, -204.4826, 44.1658),
        label = "Kho Cardealer",
        job = "cardealer",
        stashId = "cardealer_stash",
        slots = 30,
        weight = 200000,
        icon = "fas fa-shield-alt",
        groups = {
            cardealer = 2
        }
    },

    boss_ambulance = {
        coords = vec3(337.23519897461,-1416.5096435547,32.305950164795),
        label = "Kho Đồ Giám đốc",
        job = "ambulance",
        stashId = "boss_ems",
        slots = 100,
        weight = 2000000,
        icon = "fas fa-shield-alt",
        groups = {
            ambulance = 7
        },
        whitelist = {
            'money',
            'cloth_bags',
            'bandage',
            'binhlannghanh',
            'bonggon',
            'phieu_luong_y'
        }
    },

    balo_police = {
        coords = vec3(93.164794921875,-394.51010131836,47.30782699585),
        label = "Kho Trang Bi",
        job = "police",
        stashId = "balo_police",
        slots = 50,
        weight = 50000,
        icon = "fas fa-shield-alt",
        groups = {
            police = 10
        },
        whitelist = {
            'cloth_bags',
            'cloth_helmet',
            'cloth_bproof',
            'WEAPON_PUMPSHOTGUN',
            'ammo-shotgun',
        }
    },

    balo_policehocvien = {
        coords = vec3(2543.2028808594,-287.18615722656,93.260955810547), --
        label = "Kho Trang Bị Học Viện",
        job = "police",
        stashId = "balo_policehociven",
        slots = 100,
        weight = 50000,
        icon = "fas fa-shield-alt",
        groups = {
            police = 11
        },
        whitelist = {
            'cloth_bags',
            'cloth_helmet',
            'cloth_bproof',
            'stevo_policebadge',
            'handcuffs',
            'weapon_stungun',
            'weapon_nightstick',
            'nuocdua_utso',
            'com_suon_tam_9h',
            'ciga_hp',
            'trada_utso',
            'radio',
        }
    },

    kho_mechanic = {
        coords = vec3(-322.32666015625,-146.61672973633,39.015670776367),
        label = "Kho Mechanic",
        job = "menchanic",
        stashId = "khochua_mechanic",
        slots = 50,
        weight = 1000000,
        icon = "fas fa-shield-alt",
        groups = {
            mechanic = 4
        },
        whitelist = {
            'mechanic_toolbox',
            'phutung',
            'thanvo',
            'bolauxe',
            'bandage',
            'phieu_giam_gia_50',
            'lockpick',
            'manhkimloai',
            'banvevukhi',
            'manh_boom_vo',
            'WEAPON_WRENCH',
            'ciga_hp',
            'banhrandua_ht',
            'banhmochi_ht',
            'trada_utso',
            'nuocdua_utso',
        }
    },

    cayxang = {
        coords = vec3(289.30783081055,-1264.7252197266,29.507553100586),
        label = "Kho lưu trữ cây xăng",
        job = "cayxang",
        stashId = "cayxang_stash",
        slots = 50,
        weight = 1000000,
        icon = "fas fa-shield-alt",
        groups = {
            cayxang = 0
        },
        whitelist = {
            'dau_tho',
            'jerrycan',
        }
    },

    -- realestate = {
    --     coords = vec3(-816.17, -698.28, 27.95),
    --     label = "Kho lưu trữ TL",
    --     job = "realestate",
    --     stashId = "thienlong_stash",
    --     slots = 50,
    --     weight = 400000,
    --     icon = "fas fa-shield-alt",
    --     groups = nil, -- Ai cũng có thể mở nếu có chìa
    --     requiredItem = "lenhbai_tlvip" -- Phải có item này
    -- },


    -- bosstunner_stash = {
    --     coords = vec3(177.35, -1110.22, 34.37),
    --     label = "Kho Cấp cao Độ xe",
    --     job = "doxe",
    --     stashId = "bosstunner_stash",
    --     slots = 30,
    --     weight = 300000,
    --     icon = "fas fa-shield-alt",
    --     groups = {
    --         doxe = 3
    --     }
    -- }
}

-- Cấu hình kho đồ cá nhân
Config.PersonalStashes = {
    -- -- Kho đồ cá nhân tại nhà
    -- personal_home = {
    --     coords = vec3(447.02, -996.93, 30.69), -- Ví dụ: Grove Street vec3(447.02, -996.93, 30.69)
    --     label = "Kho Đồ PD cá nhân",
    --     stashType = "personal", -- personal = citizenid_stashId
    --     stashId = "personal_home",
    --     slots = 20,
    --     weight = 50000, -- 50kg
    --     icon = "fas fa-home",
    --     groups = {
    --         police = 1
    --     }
    -- },
    
    -- Kho đồ cá nhân tại garage
    personal_garage = {
        coords = vec3(172.8997, -926.7631, 31.4501), --218.1889, -894.3079, 31.2592, 122.6105
        label = "Kho Đồ Cá Nhân", 
        stashType = "personal",
        stashId = "personal_garage",
        slots = 50,
        weight = 100000, -- 200kg
        icon = "fas fa-warehouse",
        groups = nil,
        takeOnly = false -- Chỉ có thể lấy đồ ra, không thể cất vào
    }
}

-- Cấu hình target
Config.Target = {
    distance = 2.0,
    debug = false
}

-- Cấu hình thông báo
Config.Notifications = {
    noPermission = "Bạn không có quyền truy cập kho đồ này!",
    notWhitelisted = "Vật phẩm này không được phép cất vào kho này!",
    cannotDeposit = "Kho đồ này chỉ cho phép lấy ra, không thể cất vào!"
}
