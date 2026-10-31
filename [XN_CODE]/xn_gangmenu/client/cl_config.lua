-- Zones for Menues
Config = Config or {}

Config.UseTarget = GetConvar('UseTarget', 'false') == 'true' -- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)

Config.Max_Cap_Gang = 5

-- ============================================================
-- CẤU HÌNH THỜI GIAN ĐẾM NGƯỢC (COUNTDOWN) RỜI GANG / KHAI TRỪ
-- ============================================================
Config.GangCooldown = {
    enabled = true, -- Bật (true) hoặc Tắt (false) tính năng cooldown
    days = 3,       -- Số ngày đếm ngược trước khi được phép gia nhập gang mới (Mặc định: 3 ngày)
    hours = 0,      -- Số giờ bổ sung (để 0 nếu chỉ tính theo ngày)
    minutes = 0,    -- Số phút bổ sung (để 0 nếu chỉ tính theo ngày)
}

Config.Cap_Do = {
    [1] = {
        ["exp"] = 1000,
        ["max_member"] = 50,
        ["phi_nangcap"] = 10000000,
        ["require_items"] = {
            { item = 'hoa_mynhan', alt_items = {'the_hoa_mn', 'hoamynhan'}, label = 'Hoa Mỹ Nhân', amount = 400 },
            { item = 'traidudu', alt_items = {'the_du_du', 'dudu', 'ladudu_tuoi'}, label = 'Đu Đủ', amount = 400 },
            { item = 'the_can_thu', label = 'Thẻ Cần Thủ', amount = 1000 },
            { item = 'the_da_quy', label = 'Thẻ Đá Quý', amount = 1000 },
            -- { item = 'tinhthach', alt_items = {'tinh_thach'}, label = 'Tinh Thạch', amount = 700 },
        },
        ["nhiemvu"] = {
            [1] = {
                ['vatpham'] = 'hoa_mynhan',
                ['soluong'] = 3,
                ['sodiem'] = '1',
            },
            [2] = {
                ['vatpham'] = 'traidudu',
                ['soluong'] = 3,
                ['sodiem'] = '1',
            },
            [3] = {
                ['vatpham'] = 'the_sieu_trom',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [4] = {
                ['vatpham'] = 'tinhthach',
                ['soluong'] = 5,
                ['sodiem'] = '1',
            },
            [5] = {
                ['vatpham'] = 'bandage',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [6] = {
                ['vatpham'] = 'la_hoamynhan',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [7] = {
                ['vatpham'] = 'ladudu_tuoi',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
        },
        ["doiqua"] = {
            [1] = {
                ['vatpham'] = 'bandage_lv2',
                ['soluong'] = 3,
                ['grade'] = 0,
                ['require_items'] = {
                    { item = 'bandage', amount = 1, label = 'Băng Gạc' },
                    { item = 'traidudu', amount = 1, alt_items = {'the_du_du', 'dudu', 'ladudu_tuoi'}, label = 'Đu Đủ' },
                    { item = 'hoa_mynhan', amount = 1, alt_items = {'the_hoa_mn', 'hoamynhan'}, label = 'Hoa Mỹ Nhân' },
                },
            },
            [2] = {
                ['vatpham'] = 'ao_giap_gang_lv1',
                ['grade'] = 0,
                ['cash'] = 5000,
                ['require_items'] = {
                    { item = 'tinhthach', amount = 2, alt_items = {'tinh_thach'}, label = 'Tinh Thạch' },
                    { item = 'la_hoamynhan', amount = 2, alt_items = {'hoa_mynhan', 'the_hoa_mn', 'hoamynhan'}, label = 'Lá Hoa Mỹ Nhân' },
                    { item = 'ladudu_tuoi', amount = 2, alt_items = {'traidudu', 'the_du_du', 'dudu'}, label = 'Lá Đu Đủ Tươi' },
                },
            },
            [3] = {
                ['vatpham'] = 'medlangbam',
                ['grade'] = 0,
                ['require_items'] = {
                    { item = 'ladudu_tuoi', amount = 1, alt_items = {'tinh_thach'}, label = 'Tinh Thạch' },
                    { item = 'la_hoamynhan', amount = 1, alt_items = {'hoa_mynhan', 'the_hoa_mn', 'hoamynhan'}, label = 'Lá Hoa Mỹ Nhân' },
                    { item = 'tinhthach', amount = 2, alt_items = {'traidudu', 'the_du_du', 'dudu'}, label = 'Lá Đu Đủ Tươi' },
                },
            },
        },
        ["doiqua_gang"] = {},
        ["doiitemcash"] = {
            [1] = {
                ['vatpham'] = 'WEAPON_CROWBAR',
                ['label'] = 'Xà Beng',
                ['sodiem'] = '30000',
            },
            [2] = {
                ['vatpham'] = 'ao_giap_gang_lv1',
                ['label'] = 'Áo Giáp Xã Đoàn (Cấp 1)',
                ['sodiem'] = '30000',
            },
            [3] = {
                ['vatpham'] = 'bandage_lv2',
                ['label'] = 'Băng gạc LV2',
                ['sodiem'] = '3000',
            },
            [4] = {
                ['vatpham'] = 'carry_item',
                ['label'] = 'Carry',
                ['sodiem'] = '3000',
            },
        },
    },
    [2] = {
        ["exp"] = 10000,
        ["max_member"] = 70,
        ["phi_nangcap"] = 12000000,
        ["require_items"] = {
            { item = 'hoa_mynhan', alt_items = {'the_hoa_mn', 'hoamynhan'}, label = 'Hoa Mỹ Nhân', amount = 800 },
            { item = 'traidudu', alt_items = {'the_du_du', 'dudu', 'ladudu_tuoi'}, label = 'Đu Đủ', amount = 800 },
            { item = 'the_can_thu', label = 'Thẻ Cần Thủ', amount = 3000 },
            { item = 'the_da_quy', label = 'Thẻ Đá Quý', amount = 3000 },
        },
        ["nhiemvu"] = {
            [1] = {
                ['vatpham'] = 'hoa_mynhan',
                ['soluong'] = 3,
                ['sodiem'] = '1',
            },
            [2] = {
                ['vatpham'] = 'traidudu',
                ['soluong'] = 3,
                ['sodiem'] = '1',
            },
            [3] = {
                ['vatpham'] = 'the_sieu_trom',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [4] = {
                ['vatpham'] = 'tinhthach',
                ['soluong'] = 5,
                ['sodiem'] = '1',
            },
            [5] = {
                ['vatpham'] = 'bandage',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [6] = {
                ['vatpham'] = 'la_hoamynhan',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [7] = {
                ['vatpham'] = 'ladudu_tuoi',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
        },
        ["doiqua"] = {
            [1] = {
                ['vatpham'] = 'bandage_lv2',
                ['soluong'] = 3,
                ['grade'] = 0,
                ['require_items'] = {
                    { item = 'bandage', amount = 1, label = 'Băng Gạc' },
                    { item = 'traidudu', amount = 1, alt_items = {'the_du_du', 'dudu', 'ladudu_tuoi'}, label = 'Đu Đủ' },
                    { item = 'hoa_mynhan', amount = 1, alt_items = {'the_hoa_mn', 'hoamynhan'}, label = 'Hoa Mỹ Nhân' },
                },
            },
            [2] = {
                ['vatpham'] = 'ao_giap_gang_lv1',
                ['grade'] = 0,
                ['cash'] = 5000,
                ['require_items'] = {
                    { item = 'tinhthach', amount = 2, alt_items = {'tinh_thach'}, label = 'Tinh Thạch' },
                    { item = 'la_hoamynhan', amount = 2, alt_items = {'hoa_mynhan', 'the_hoa_mn', 'hoamynhan'}, label = 'Lá Hoa Mỹ Nhân' },
                    { item = 'ladudu_tuoi', amount = 2, alt_items = {'traidudu', 'the_du_du', 'dudu'}, label = 'Lá Đu Đủ Tươi' },
                },
            },
            [3] = {
                ['vatpham'] = 'medlangbam',
                ['grade'] = 0,
                ['require_items'] = {
                    { item = 'ladudu_tuoi', amount = 1, alt_items = {'tinh_thach'}, label = 'Tinh Thạch' },
                    { item = 'la_hoamynhan', amount = 1, alt_items = {'hoa_mynhan', 'the_hoa_mn', 'hoamynhan'}, label = 'Lá Hoa Mỹ Nhân' },
                    { item = 'tinhthach', amount = 2, alt_items = {'traidudu', 'the_du_du', 'dudu'}, label = 'Lá Đu Đủ Tươi' },
                },
            },
        },
        ["doiqua_gang"] = {},
        ["doiitemcash"] = {
            [1] = {
                ['vatpham'] = 'WEAPON_CROWBAR',
                ['label'] = 'Xà Beng',
                ['sodiem'] = '30000',
            },
            [2] = {
                ['vatpham'] = 'ao_giap_gang_lv1',
                ['label'] = 'Áo Giáp Xã Đoàn (Cấp 1)',
                ['sodiem'] = '30000',
            },
            [3] = {
                ['vatpham'] = 'bandage_lv2',
                ['label'] = 'Băng gạc LV2',
                ['sodiem'] = '3000',
            },
            [4] = {
                ['vatpham'] = 'carry_item',
                ['label'] = 'Carry',
                ['sodiem'] = '3000',
            },
        },
    },
    [3] = {
        ["exp"] = 20000,
        ["max_member"] = 90,
        ["phi_nangcap"] = 20000000,
        ["require_items"] = {
            { item = 'hoa_mynhan', alt_items = {'the_hoa_mn', 'hoamynhan'}, label = 'Hoa Mỹ Nhân', amount = 1600 },
            { item = 'traidudu', alt_items = {'the_du_du', 'dudu', 'ladudu_tuoi'}, label = 'Đu Đủ', amount = 1600 },
            { item = 'the_sieu_trom', label = 'Thẻ Sêu trộm', amount = 100 },
            { item = 'tinh_thach', label = 'Thẻ Đá Quý', amount = 1000 },
        },
        ["nhiemvu"] = {
            [1] = {
                ['vatpham'] = 'hoa_mynhan',
                ['soluong'] = 3,
                ['sodiem'] = '1',
            },
            [2] = {
                ['vatpham'] = 'traidudu',
                ['soluong'] = 3,
                ['sodiem'] = '1',
            },
            [3] = {
                ['vatpham'] = 'the_sieu_trom',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [4] = {
                ['vatpham'] = 'tinhthach',
                ['soluong'] = 5,
                ['sodiem'] = '1',
            },
            [5] = {
                ['vatpham'] = 'bandage',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [6] = {
                ['vatpham'] = 'la_hoamynhan',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [7] = {
                ['vatpham'] = 'ladudu_tuoi',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
        },
        ["doiqua"] = {
            [1] = {
                ['vatpham'] = 'bandage_lv2',
                ['soluong'] = 3,
                ['grade'] = 0,
                ['require_items'] = {
                    { item = 'bandage', amount = 1, label = 'Băng Gạc' },
                    { item = 'traidudu', amount = 1, alt_items = {'the_du_du', 'dudu', 'ladudu_tuoi'}, label = 'Đu Đủ' },
                    { item = 'hoa_mynhan', amount = 1, alt_items = {'the_hoa_mn', 'hoamynhan'}, label = 'Hoa Mỹ Nhân' },
                },
            },
            [2] = {
                ['vatpham'] = 'ao_giap_gang_lv1',
                ['grade'] = 0,
                ['cash'] = 5000,
                ['require_items'] = {
                    { item = 'tinhthach', amount = 2, alt_items = {'tinh_thach'}, label = 'Tinh Thạch' },
                    { item = 'la_hoamynhan', amount = 2, alt_items = {'hoa_mynhan', 'the_hoa_mn', 'hoamynhan'}, label = 'Lá Hoa Mỹ Nhân' },
                    { item = 'ladudu_tuoi', amount = 2, alt_items = {'traidudu', 'the_du_du', 'dudu'}, label = 'Lá Đu Đủ Tươi' },
                },
            },
            [3] = {
                ['vatpham'] = 'medlangbam',
                ['grade'] = 0,
                ['require_items'] = {
                    { item = 'ladudu_tuoi', amount = 1, alt_items = {'tinh_thach'}, label = 'Tinh Thạch' },
                    { item = 'la_hoamynhan', amount = 1, alt_items = {'hoa_mynhan', 'the_hoa_mn', 'hoamynhan'}, label = 'Lá Hoa Mỹ Nhân' },
                    { item = 'tinhthach', amount = 2, alt_items = {'traidudu', 'the_du_du', 'dudu'}, label = 'Lá Đu Đủ Tươi' },
                },
            },
        },
        ["doiqua_gang"] = {},
        ["doiitemcash"] = {
            [1] = {
                ['vatpham'] = 'WEAPON_CROWBAR',
                ['label'] = 'Xà Beng',
                ['sodiem'] = '30000',
            },
            [2] = {
                ['vatpham'] = 'ao_giap_gang_lv1',
                ['label'] = 'Áo Giáp Xã Đoàn (Cấp 1)',
                ['sodiem'] = '30000',
            },
            [3] = {
                ['vatpham'] = 'bandage_lv2',
                ['label'] = 'Băng gạc LV2',
                ['sodiem'] = '3000',
            },
            [4] = {
                ['vatpham'] = 'carry_item',
                ['label'] = 'Carry',
                ['sodiem'] = '3000',
            },
        },
    },
    [4] = {
        ["exp"] = 40000,
        ["max_member"] = 120,
        ["phi_nangcap"] = 32000000,
        ["require_items"] = {
            { item = 'hoa_mynhan', alt_items = {'the_hoa_mn', 'hoamynhan'}, label = 'Hoa Mỹ Nhân', amount = 3200 },
            { item = 'traidudu', alt_items = {'the_du_du', 'dudu', 'ladudu_tuoi'}, label = 'Đu Đủ', amount = 3200 },
            { item = 'the_sieu_trom', label = 'Thẻ Sêu trộm', amount = 300 },
            { item = 'tinh_thach', label = 'Tinh thạch', amount = 3000 },
        },
        ["nhiemvu"] = {
            [1] = {
                ['vatpham'] = 'hoa_mynhan',
                ['soluong'] = 3,
                ['sodiem'] = '1',
            },
            [2] = {
                ['vatpham'] = 'traidudu',
                ['soluong'] = 3,
                ['sodiem'] = '1',
            },
            [3] = {
                ['vatpham'] = 'the_sieu_trom',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [4] = {
                ['vatpham'] = 'tinhthach',
                ['soluong'] = 5,
                ['sodiem'] = '1',
            },
            [5] = {
                ['vatpham'] = 'bandage',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [6] = {
                ['vatpham'] = 'la_hoamynhan',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [7] = {
                ['vatpham'] = 'ladudu_tuoi',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
        },
        ["doiqua"] = {
            [1] = {
                ['vatpham'] = 'bandage_lv2',
                ['soluong'] = 3,
                ['grade'] = 0,
                ['require_items'] = {
                    { item = 'bandage', amount = 1, label = 'Băng Gạc' },
                    { item = 'traidudu', amount = 1, alt_items = {'the_du_du', 'dudu', 'ladudu_tuoi'}, label = 'Đu Đủ' },
                    { item = 'hoa_mynhan', amount = 1, alt_items = {'the_hoa_mn', 'hoamynhan'}, label = 'Hoa Mỹ Nhân' },
                },
            },
            [2] = {
                ['vatpham'] = 'ao_giap_gang_lv1',
                ['grade'] = 0,
                ['cash'] = 5000,
                ['require_items'] = {
                    { item = 'tinhthach', amount = 2, alt_items = {'tinh_thach'}, label = 'Tinh Thạch' },
                    { item = 'la_hoamynhan', amount = 2, alt_items = {'hoa_mynhan', 'the_hoa_mn', 'hoamynhan'}, label = 'Lá Hoa Mỹ Nhân' },
                    { item = 'ladudu_tuoi', amount = 2, alt_items = {'traidudu', 'the_du_du', 'dudu'}, label = 'Lá Đu Đủ Tươi' },
                },
            },
            [3] = {
                ['vatpham'] = 'medlangbam',
                ['grade'] = 0,
                ['require_items'] = {
                    { item = 'ladudu_tuoi', amount = 1, alt_items = {'tinh_thach'}, label = 'Tinh Thạch' },
                    { item = 'la_hoamynhan', amount = 1, alt_items = {'hoa_mynhan', 'the_hoa_mn', 'hoamynhan'}, label = 'Lá Hoa Mỹ Nhân' },
                    { item = 'tinhthach', amount = 2, alt_items = {'traidudu', 'the_du_du', 'dudu'}, label = 'Lá Đu Đủ Tươi' },
                },
            },
        },
        ["doiqua_gang"] = {},
        ["doiitemcash"] = {
            [1] = {
                ['vatpham'] = 'WEAPON_CROWBAR',
                ['label'] = 'Xà Beng',
                ['sodiem'] = '30000',
            },
            [2] = {
                ['vatpham'] = 'ao_giap_gang_lv1',
                ['label'] = 'Áo Giáp Xã Đoàn (Cấp 1)',
                ['sodiem'] = '30000',
            },
            [3] = {
                ['vatpham'] = 'bandage_lv2',
                ['label'] = 'Băng gạc LV2',
                ['sodiem'] = '3000',
            },
            [4] = {
                ['vatpham'] = 'carry_item',
                ['label'] = 'Carry',
                ['sodiem'] = '3000',
            },
        },
    },
    [5] = {
        ["exp"] = 60000,
        ["max_member"] = 150,
        ["phi_nangcap"] = 50000000,
        ["nhiemvu"] = {
            [1] = {
                ['vatpham'] = 'hoa_mynhan',
                ['soluong'] = 3,
                ['sodiem'] = '1',
            },
            [2] = {
                ['vatpham'] = 'traidudu',
                ['soluong'] = 3,
                ['sodiem'] = '1',
            },
            [3] = {
                ['vatpham'] = 'the_sieu_trom',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [4] = {
                ['vatpham'] = 'tinhthach',
                ['soluong'] = 5,
                ['sodiem'] = '1',
            },
            [5] = {
                ['vatpham'] = 'bandage',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [6] = {
                ['vatpham'] = 'la_hoamynhan',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
            [7] = {
                ['vatpham'] = 'ladudu_tuoi',
                ['soluong'] = 1,
                ['sodiem'] = '1',
            },
        },
        ["doiqua"] = {
            [1] = {
                ['vatpham'] = 'bandage_lv2',
                ['soluong'] = 3,
                ['grade'] = 0,
                ['require_items'] = {
                    { item = 'bandage', amount = 1, label = 'Băng Gạc' },
                    { item = 'traidudu', amount = 1, alt_items = {'the_du_du', 'dudu', 'ladudu_tuoi'}, label = 'Đu Đủ' },
                    { item = 'hoa_mynhan', amount = 1, alt_items = {'the_hoa_mn', 'hoamynhan'}, label = 'Hoa Mỹ Nhân' },
                },
            },
            [2] = {
                ['vatpham'] = 'ao_giap_gang_lv1',
                ['grade'] = 0,
                ['cash'] = 5000,
                ['require_items'] = {
                    { item = 'tinhthach', amount = 2, alt_items = {'tinh_thach'}, label = 'Tinh Thạch' },
                    { item = 'la_hoamynhan', amount = 2, alt_items = {'hoa_mynhan', 'the_hoa_mn', 'hoamynhan'}, label = 'Lá Hoa Mỹ Nhân' },
                    { item = 'ladudu_tuoi', amount = 2, alt_items = {'traidudu', 'the_du_du', 'dudu'}, label = 'Lá Đu Đủ Tươi' },
                },
            },
            [3] = {
                ['vatpham'] = 'medlangbam',
                ['grade'] = 0,
                ['require_items'] = {
                    { item = 'ladudu_tuoi', amount = 1, alt_items = {'tinh_thach'}, label = 'Tinh Thạch' },
                    { item = 'la_hoamynhan', amount = 1, alt_items = {'hoa_mynhan', 'the_hoa_mn', 'hoamynhan'}, label = 'Lá Hoa Mỹ Nhân' },
                    { item = 'tinhthach', amount = 2, alt_items = {'traidudu', 'the_du_du', 'dudu'}, label = 'Lá Đu Đủ Tươi' },
                },
            },
        },
        ["doiqua_gang"] = {},
        ["doiitemcash"] = {
            [1] = {
                ['vatpham'] = 'WEAPON_CROWBAR',
                ['label'] = 'Xà Beng',
                ['sodiem'] = '30000',
            },
            [2] = {
                ['vatpham'] = 'ao_giap_gang_lv1',
                ['label'] = 'Áo Giáp Xã Đoàn (Cấp 1)',
                ['sodiem'] = '30000',
            },
            [3] = {
                ['vatpham'] = 'bandage_lv2',
                ['label'] = 'Băng gạc LV2',
                ['sodiem'] = '3000',
            },
            [4] = {
                ['vatpham'] = 'carry_item',
                ['label'] = 'Carry',
                ['sodiem'] = '3000',
            },
        },
    },
}

Config.Qua_ChiemDong = {
    [0] = {
        sodiem = 10,
        amount = 1,
        type = "item",
        item = "ruongchiemdong",
    },
    [1] = {
        sodiem = 20,
        amount = 1,
        type = "item",
        item = "ruongchiemdong",
    },
    [2] = {
        sodiem = 30,
        amount = 1,
        type = "item",
        item = "ruongchiemdong",
    },
    [3] = {
        sodiem = 40,
        amount = 1,
        type = "item",
        item = "ruongchiemdong",
    },
    [4] = {
        sodiem = 50,
        amount = 1,
        type = "item",
        item = "ruongchiemdong",
    },
    [5] = {
        sodiem = 60,
        amount = 1,
        type = "item",
        item = "ruongchiemdong",
    },
}


Config.GangLabel = {
    [0] = 'Đàn em',
    [1] = 'Đàn anh',
    [2] = 'Lão đại',
    [3] = 'Ông trùm'
}

-- Cấu hình tạo xã đoàn mới & quản lý
Config.CreateGangCost = 1000000 -- Phí tạo xã đoàn (Cash), mặc định: $1.000.000
Config.MaxDescriptionWords = 100 -- Giới hạn số từ cho phần giới thiệu xã đoàn
Config.DiscordWebhook = "https://discord.com/api/webhooks/1547588427195748517/XtHZ-NELWebdcey7WSgVf7qnhtKxhdQpFfgos31nDjAtNlSZy0xl_vbZaN2aQJvkh3ee" -- Điền URL Discord Webhook để nhận thông báo đăng ký xã đoàn (để trống nếu không dùng)
Config.AdminGroups = { -- Nhóm quyền được sử dụng lệnh /quanlygang
    ['god'] = true,
    ['admin'] = true,
    ['mod'] = true,
}

-- Điểm Target mở UI Xã Đoàn
Config.TargetLocations = {
    {
        coords = vec3(165.76403808594, -945.99584960938, 31.842708587646),
        radius = 1.5,
        label = 'Mở Quản Lý Xã Đoàn',
        icon = 'fa-solid fa-users',
    }
}

-- Phúc lợi Gang theo mốc thành viên đủ thời gian chơi
Config.PhucLoiGang = {
    playtimeRequired = 3 * 86400, -- 3 ngày (259200 giây)
    milestones = {
        {
            id = 1,
            membersRequired = 10,
            item = 'qua_gang_1',
            label = 'Gói Quà Xã Đoàn I',
            amount = 1,
            description = 'Đạt 10 thành viên có thời gian chơi từ 3 ngày trở lên',
        },
        {
            id = 2,
            membersRequired = 20,
            item = 'qua_gang_2',
            label = 'Gói Quà Xã Đoàn II',
            amount = 1,
            description = 'Đạt 20 thành viên có thời gian chơi từ 3 ngày trở lên',
        },
        {
            id = 3,
            membersRequired = 30,
            item = 'qua_gang_3',
            label = 'Gói Quà Xã Đoàn III',
            amount = 1,
            description = 'Đạt 30 thành viên có thời gian chơi từ 3 ngày trở lên',
        },
    }
}
