Config = {}

Config.debug = false

-- Label mapping: item name -> display name hiển thị trên UI
Config.labels = {
    -- Chibi pets
    ["bupbe10"]          = "Búp Bê 10",
    ["rubygirl"]         = "Ruby Girl",
    ["babepippa"]        = "Babe Pippa",
    ["fox_white"]        = "Cáo Trắng",

    -- D_Dimo series
    ["d_dimo_foxspirit"]      = "Fox Spirit",
    ["d_dimo_ghostcatcher"]   = "Ghost Catcher",
    ["d_dimo_littledevil"]    = "Little Devil",
    ["d_dimo_mummy"]          = "Mummy",
    ["d_dimo_shadowsailor"]   = "Shadow Sailor",
    ["d_dimo_ghost"]          = "Ghost",
    ["d_dimo_scarebox"]       = "Scare Box",
    ["d_dimo_scarecrow"]      = "Scarecrow",
    ["d_dimo_unicorn"]        = "Unicorn",
    ["d_dimo_yeti"]           = "Yeti",

    -- Bear
    ["bear_456"]              = "Bear 456",

    -- Reawx Manager series
    ["reawx_manager_circle_01"] = "Manager Circle",
    ["reawx_manager_quads_01"]  = "Manager Quads",
    ["reawx_manager_tis_01"]    = "Manager Tis",

    -- Reawx Duck series
    ["reawx_duck_artist"]     = "Duck Artist",
    ["reawx_duck_pilot"]      = "Duck Pilot",
    ["reawx_duck_shower"]     = "Duck Shower",
    ["reawx_duck_swim"]       = "Duck Swim",
    ["reawx_head_duck"]       = "Head Duck",

    -- Sharkz series
    ["sharkz_shark_sing_cup"]   = "Shark Sing Cup",
    ["sharkz_shark_bag_glass"]  = "Shark Bag Glass",
    ["sharkz_shark_surf_board"] = "Shark Surf Board",
    ["sharkz_shark_headphone"]  = "Shark Headphone",

    -- Skateboard
    ["skateboard"]       = "Ván Trượt",

    -- Weapons
    ["weapon_machete"]   = "Dao Rừng",
    ["weapon_knife"]     = "Dao",
    ["weapon_bat"]       = "Gậy Bóng Chày",
    ["weapon_crowbar"]   = "Thanh Xà Beng",
    ["weapon_hammer"]    = "Búa",
    ["weapon_hatchet"]   = "Rìu",
    ["weapon_dagger"]    = "Dao Găm",
    ["weapon_golfclub"]  = "Gậy Golf",
    ["weapon_wrench"]    = "Cờ Lê",
    ["weapon_stone_hatchet"] = "Rìu Đá",
}

Config.item_setting = {
    ["bupbe10"] = {{
        ['Model'] = 'VALENTINEMODEL50',
        ['Bone'] = 24818,
        ['Pos'] = vec3(-0.205, 0.085, -0.4),
        ['Rot'] = vec3(174.705, -90.119, 0.000)
    }},
    
    ["rubygirl"] = {{
        ['Model'] = 'notz_chibi_f_anim',
        ['Bone'] = 24818,
        ['Pos'] = vec3(0.25, 0.0, -0.2),
        ['Rot'] = vec3(0.0, 80.00, 180.0)
    }},

    ["babepippa"] = {{
        ['Model'] = 'xa_fashion_babe_pippa',
        ['Bone'] = 24818,
        ['Pos'] = vec3(0.260000, -0.030000, 0.190000),
        ['Rot'] = vec3(7.000000, 89.000000, -174.500000) 
    }},

    ["fox_white"] = {{
        ['Model'] = 'seacity_ahrimoonwhite',
        ['Bone'] = 64729,
        ['Pos'] = vec3(-0.200000, -0.140000, 0.020000),
        ['Rot'] = vec3(-4.334999, -161.120041, -206.465057)
    }},

    ["d_dimo_foxspirit"] = {{
        ['Model'] = 'd_dimo_foxspirit',
        ['Bone'] = 10706,
        ['Pos'] = vec3(0.145, -0.020, 0.150),
        ['Rot'] = vec3(-1.200, 0.000, 192.400)
    }},

    ["d_dimo_ghostcatcher"] = {{
        ['Model'] = 'd_dimo_ghostcatcher',
        ['Bone'] = 1,
        ['Pos'] = vec3(-0.760, 0.000, -0.800),
        ['Rot'] = vec3(0.000, 0.000, 180.000)
    }},

    ["d_dimo_littledevil"] = {{
        ['Model'] = 'd_dimo_littledevil',
        ['Bone'] = 64729,
        ['Pos'] = vec3(0.185, -0.030, -0.145),
        ['Rot'] = vec3(-192.000, 0.200, 26.800)
    }},

    ["d_dimo_shadowsailor"] = {{
        ['Model'] = 'd_dimo_shadowsailor',
        ['Bone'] = 1,
        ['Pos'] = vec3(0.465, 0.000, -0.800),
        ['Rot'] = vec3(0.000, 0.000, 180.000)
    }},

    ["d_dimo_ghost"] = {{
        ['Model'] = 'd_dimo_ghost',
        ['Bone'] = 10706,
        ['Pos'] = vec3(0.140, 0.000, 0.155),
        ['Rot'] = vec3(0.500, 0.900, 189.100)
    }},

    ["d_dimo_scarecrow"] = {{
        ['Model'] = 'd_dimo_scarecrow',
        ['Bone'] = 1,
        ['Pos'] = vec3(-0.475, 0.000, -0.760),
        ['Rot'] = vec3(0.000, 0.000, 180.000)
    }},

    ["d_dimo_unicorn"] = {{
        ['Model'] = 'd_dimo_unicorn',
        ['Bone'] = 1,
        ['Pos'] = vec3(0.465, 0.000, -0.795),
        ['Rot'] = vec3(0.000, 0.000, 180.000)
    }},

    ["d_dimo_yeti"] = {{
        ['Model'] = 'd_dimo_yeti',
        ['Bone'] = 64729,
        ['Pos'] = vec3(0.185, -0.070, -0.070),
        ['Rot'] = vec3(-175.300, 0.800, 18.000)
    }},

    ["bear_456"] = {{
        ['Model'] = 'bear_456',
        ['Bone'] = 10706,
        ['Pos'] = vec3(0.290, 0.05, 0.02),
        ['Rot'] = vec3(0.000, 0.00, -120.000)
    }},



    ["reawx_manager_circle_01"] = {{
        ['Model'] = 'reawx_manager_circle_01',
        ['Bone'] = 36864,
        ['Pos'] = vec3(0.120000, 0.060000, 0.225000),
        ['Rot'] = vec3(-5.000000, -65.000000, 200.000000)
    }},

    ["reawx_manager_quads_01"] = {{
        ['Model'] = 'reawx_manager_quads_01',
        ['Bone'] = 64729,
        ['Pos'] = vec3(0.31, 0.025, -0.00),
        ['Rot'] = vec3(190.000, 0.000, 90.000)
    }},

    ["reawx_manager_tis_01"] = {{
        ['Model'] = 'reawx_manager_tis_01',
        ['Bone'] = 58271,
        ['Pos'] = vec3(0.56, 0.03, -0.185),
        ['Rot'] = vec3(-90.000, 0.000, 90.000)
    }},

    ["reawx_duck_artist"] = {{
        ['Model'] = 'reawx_duck_artist',
        ['Bone'] = 10706,
        ['Pos'] = vec3(0.14, -0.06, 0.11),
        ['Rot'] = vec3(-50, 10, 190)
    }},Model = 'reawx_duck_pilot',


    ["reawx_duck_pilot"] = {{
        ['Model'] = 'reawx_duck_pilot',
        ['Bone'] = 58271,
        ['Pos'] = vec3(0.590000, 0.030000, -0.190000),
        ['Rot'] = vec3(0.000000, -180.000000, -255.000000)
    }},

    ["reawx_duck_shower"] = {{
        ['Model'] = 'reawx_duck_shower',
        ['Bone'] = 64729,
        ['Pos'] = vec3(0.11, 0.10, -0.12),
        ['Rot'] = vec3(0, 180, 190)
    }},


    ["reawx_duck_swim"] = {{
        ['Model'] = 'reawx_duck_swim',
        ['Bone'] = 36864,
        ['Pos'] = vec3(0.060000, -0.040000, 0.170000),
        ['Rot'] = vec3(-205.000000, 105.000000, -10.000000)
    }},

    ["sharkz_shark_sing_cup"] = {{
        ['Model'] = 'sharkz_shark_sing_cup',
        ['Bone'] = 40269,
        ['Pos'] = vec3(-0.190000, -0.030000, 0.060000),
        ['Rot'] = vec3(193.000000, 63.000000, 379.000000)
    }},

    ["sharkz_shark_bag_glass"] = {{
        ['Model'] = 'sharkz_shark_bag_glass',
        ['Bone'] = 45509,
        ['Pos'] = vec3(-0.320000, 0.060000, -0.020000),
        ['Rot'] = vec3(12.000000, -50.000000, -189.600098)
    }},

    ["sharkz_shark_surf_board"] = {{
        ['Model'] = 'sharkz_shark_surf_board',
        ['Bone'] = 34577,
        ['Pos'] = vec3(0.45, -0.1, -0.47),
        ['Rot'] = vec3(0.0, 0.0, 180.0)
    }},

    ["sharkz_shark_headphone"] = {{
        ['Model'] = 'sharkz_shark_headphone',
        ['Bone'] = 63931,
        ['Pos'] = vec3(0.070000, 0.010000, -0.245000),
        ['Rot'] = vec3(-182.000000, 85.000000, 29.000000)
    }}
}

-- Skateboard accessory items
Config.skateboard_setting = {
    ["skateboard"] = {
        ['Model'] = 'p_defilied_ragdoll_01_s',
        ['Bone'] = 24818,
        ['Pos'] = vec3(0.0, -0.27, 0.0),
        ['Rot'] = vec3(-90.0, 150.0, 0.0)
    }
}

-- Weapon skin/component -> alternative prop model
-- Khi vũ khí có component (skin), thay đổi model prop hiển thị trên lưng
-- Key = weapon item name, value = { [component_name] = prop_model_name }
Config.weapon_component_models = {
    ["weapon_bat"] = {
        ["skin_batmot"] = "w_me_skinbatmot",
        ["skin_bathai"] = "w_me_skinbathai",
        ["skin_icbat1"] = "w_me_ic_batmot",
        ["skin_icbat2"] = "w_me_ic_bathai",
        ["skin_cole1"] = "w_me_colemot",
        ["skin_cole2"] = "w_me_colehai",
        ["skin_coleic1"] = "w_me_ic_colemot",
        ["skin_coleic2"] = "w_me_ic_colehai",
    },
    -- Thêm weapon khác có skin tại đây:
    -- Key = tên component lưu trong metadata.components (vd: "skin_batnos")
    -- ["weapon_knife"] = {
    --     ["skin_knifenos"] = "w_me_knife_nos",
    -- },
}

-- Carry weapon items (item name = ox_inventory item name)
-- Tier 2: bone 24817 (SKEL_Spine3), weapons go sideways on player's back
Config.weapon_setting = {
    ["weapon_machete"] = {
        ['Model'] = 'w_me_machette_lr',
        ['Bone'] = 24817,
        ['Pos'] = vec3(-0.13, -0.16, -0.14),
        ['Rot'] = vec3(5.0, 62.0, 0.0)
    },
    ["weapon_knife"] = {
        ['Model'] = 'prop_w_me_knife_01',
        ['Bone'] = 24817,
        ['Pos'] = vec3(-0.13, -0.16, -0.14),
        ['Rot'] = vec3(5.0, 62.0, 0.0)
    },
    ["weapon_bat"] = {
        ['Model'] = 'w_me_bat',
        ['Bone'] = 24817,
        ['Pos'] = vec3(-0.13, -0.16, -0.14),
        ['Rot'] = vec3(5.0, 62.0, 0.0)
    },
    ["weapon_crowbar"] = {
        ['Model'] = 'w_me_crowbar',
        ['Bone'] = 24817,
        ['Pos'] = vec3(-0.13, -0.16, -0.14),
        ['Rot'] = vec3(5.0, 62.0, 0.0)
    },
    ["weapon_hammer"] = {
        ['Model'] = 'w_me_hammer',
        ['Bone'] = 24817,
        ['Pos'] = vec3(-0.13, -0.16, -0.14),
        ['Rot'] = vec3(5.0, 62.0, 0.0)
    },
    ["weapon_hatchet"] = {
        ['Model'] = 'w_me_hatchet',
        ['Bone'] = 24817,
        ['Pos'] = vec3(-0.13, -0.16, -0.14),
        ['Rot'] = vec3(5.0, 62.0, 0.0)
    },
    ["weapon_dagger"] = {
        ['Model'] = 'w_me_dagger',
        ['Bone'] = 24817,
        ['Pos'] = vec3(-0.13, -0.16, -0.14),
        ['Rot'] = vec3(5.0, 62.0, 0.0)
    },
    ["weapon_golfclub"] = {
        ['Model'] = 'w_me_gclub',
        ['Bone'] = 24817,
        ['Pos'] = vec3(-0.13, -0.16, -0.14),
        ['Rot'] = vec3(5.0, 62.0, 0.0)
    },
    ["weapon_wrench"] = {
        ['Model'] = 'w_me_wrench',
        ['Bone'] = 24817,
        ['Pos'] = vec3(-0.13, -0.16, -0.14),
        ['Rot'] = vec3(5.0, 62.0, 0.0)
    },
    ["weapon_stone_hatchet"] = {
        ['Model'] = 'w_me_stonehatchet',
        ['Bone'] = 24817,
        ['Pos'] = vec3(-0.13, -0.16, -0.14),
        ['Rot'] = vec3(5.0, 62.0, 0.0)
    }
}

-- Các prop bổ sung cần whitelist khi lên xe nhưng không thuộc item_setting / skateboard_setting / weapon_setting
Config.extra_prop_whitelist = {
    'prop_money_bag_01',
    'prop_toilet_01',
    'prop_microwave_1',
    'prop_tv_flat_02b',
}
