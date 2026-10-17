-- =============================================
--  xn_quandudu | CONFIG
--  Chỉnh sửa tại đây, không cần đụng vào client/server
-- =============================================

Config = {}
Config.Debug = false               -- Bật/tắt chế độ debug hiển thị log F8/console


-- ============================================================
-- VỊ TRÍ TARGET ĐỂ MẶC ĐỊNH
-- ============================================================
Config.TargetRadius = 1.0          -- bán kính vùng tương tác mặc định (mét)
Config.TargetLabel  = '🌿 Chế biến lá đu đủ'
Config.TargetIcon   = 'fas fa-leaf'

-- ============================================================
-- DANH SÁCH CÁC VỊ TRÍ XƯỞNG LÁ ĐU ĐỦ
-- ============================================================
Config.Locations = {
    -- Diem 1
    {
        TargetCoords = vector3(147.2963, 2299.3872, 93.8529),
        TargetLabel  = '🌿 Chế biến lá đu đủ',
        Say = {
            PropCoords  = vector4(147.2963, 2299.3872, 93.8529, 335.1255),
            PropCoords2 = vector4(147.2963, 2299.3872, 93.9529, 335.1255),
        },
        DongGoi = {
            PropCoords  = vector4(147.2963, 2299.3872, 93.8529, 335.1255),
        }
    },
    {
        TargetCoords = vector3(-1323.1277, -613.6653, 29.2532),
        TargetLabel  = '🌿 Chế biến lá đu đủ',
        Say = {
            PropCoords  = vector4(-1323.2037, -613.6958, 29.2532, 317.9550),
            PropCoords2 = vector4(-1323.2037, -613.6958, 29.2832, 317.9550),
        },
        DongGoi = {
            PropCoords  = vector4(-1323.2037, -613.6958, 29.2532, 317.9550),
        }
    },
    --- Diểm 2
    {
        TargetCoords = vector3(-3176.2568, 1251.5056, 6.6871),
        TargetLabel  = '🌿 Chế biến lá đu đủ',
        Say = {
            PropCoords  = vector4(-3176.2568, 1251.5056, 6.6871, 184.8607),
            PropCoords2 = vector4(-3176.2568, 1251.5056, 6.6871, 184.8607),
        },
        DongGoi = {
            PropCoords  = vector4(-3176.2568, 1251.5056, 6.6871, 184.8607),
        }
    }

    -- {
    --     TargetCoords = vector3(122.6749, 182.1189, 112.3069),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(122.6749, 182.1189, 112.3069, 160.7597),
    --         PropCoords2 = vector4(122.6749, 182.1189, 112.3569, 160.7597),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(122.6749, 182.1189, 112.3069, 72.4828),
    --     }
    -- },
    -- -- Điểm 3
    -- {
    --     TargetCoords = vector3(885.2896, -1148.7593, 25.9153),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(885.2896, -1148.7593, 25.9153, 105.3462),
    --         PropCoords2 = vector4(885.2896, -1148.7593, 25.9353, 105.3462),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(885.2896, -1148.7593, 25.9153, 186.1085),
    --     }
    -- }

    -- {
    --     TargetCoords = vector3(880.1560, -1150.2698, 26.915),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(880.1560, -1150.2698, 25.9153, 9.8666),
    --         PropCoords2 = vector4(880.1560, -1150.2698, 25.9353, 9.8666),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(880.1560, -1150.2698, 26.9153, 272.6174),
    --     }
    -- },
    -- -- Điểm 4
    -- {
    --     TargetCoords = vector3(108.0192, -2684.9072, 5.9932),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(108.0192, -2684.9072, 5.9932, 193.1077),
    --         PropCoords2 = vector4(108.0192, -2684.9072, 6.0132, 193.1077),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(108.0192, -2684.9072, 5.9932, 94.8445),
    --     }
    -- },

    -- {
    --     TargetCoords = vector3(102.8464, -2686.2317, 5.9932),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(102.8464, -2686.2317, 5.9932, 269.8020),
    --         PropCoords2 = vector4(102.8464, -2686.2317, 6.0132, 269.8020),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(102.8464, -2686.2317, 5.9932, 179.5266),
    --     }
    -- },
    -- --điểm 5
    -- {
    --     TargetCoords = vector3(-1027.8567, -418.3700, 33.2458),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(-1027.8567, -418.3700, 34.2458, 309.5423),
    --         PropCoords2 = vector4(-1027.8567, -418.3700, 34.2458, 309.5423),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(-1027.8567, -418.3700, 34.2458, 202.1806),
    --     }
    -- },

    -- {
    --     TargetCoords = vector3(-1024.3202, -422.3966, 33.2457),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(-1024.3202, -422.3966, 33.2457, 34.8639),
    --         PropCoords2 = vector4(-1024.3202, -422.3966, 33.3457, 34.8639),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(-1024.3927, -422.3531, 34.2457, 298.6460),
    --     }
    -- },
    -- --Điểm 6
    -- {
    --     TargetCoords = vector3(-53.3500, -1285.9147, 29.3482),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(-53.3500, -1285.9147, 29.3482, 180.7931),
    --         PropCoords2 = vector4(-53.3500, -1285.9147, 29.4482, 180.7931),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(-53.3500, -1285.9147, 30.3482, 91.4183),
    --     }
    -- },
    -- {
    --     TargetCoords = vector3(-58.4792, -1287.3733, 30.3482),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(-58.4792, -1287.3733, 30.3482, 267.1502),
    --         PropCoords2 = vector4(-58.4792, -1287.3733, 30.3482, 267.1502),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(-53.3500, -1285.9147, 30.3482, 178.8440),
    --     }
    -- },
    -- --Điểm 7
    -- {
    --     TargetCoords = vector3(507.8575, -804.7990, 15.4159),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(507.8575, -804.7990, 15.4159, 181.3976),
    --         PropCoords2 = vector4(507.8575, -804.7990, 15.5159, 181.3976),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(507.8575, -804.7990, 15.4159, 181.3976),
    --     }
    -- },
    -- {
    --     TargetCoords = vector3(502.6121, -805.8465, 15.4159),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(502.6121, -805.8465, 15.4159, 266.6710),
    --         PropCoords2 = vector4(502.6121, -805.8465, 15.5159, 266.6710),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(502.6121, -805.8465, 16.4159, 178.1628),
    --     }
    -- },
    -- --Điểm 8
    -- {
    --     TargetCoords = vector3(-2971.4424, 44.6314, 11.4471),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(-2971.4424, 44.6314, 11.4471, 79.2507),
    --         PropCoords2 = vector4(-2971.4424, 44.6314, 11.4471, 79.2507),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(-2971.5178, 44.5757, 11.4471, 349.7810),
    --     }
    -- },
    -- {
    --     TargetCoords = vector3(-2970.2295, 49.6811, 11.4471),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(-2970.2295, 49.6811, 11.4471, 153.0697),
    --         PropCoords2 = vector4(-2970.2295, 49.6811, 11.4471, 153.0697),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(-2970.2134, 49.5867, 11.4471, 63.5581),
    --     }
    -- },

    -- --Điểm 9
    -- {
    --     TargetCoords = vector3(2716.9524, 3460.8647, 56.161),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(2716.9524, 3460.8647, 56.1613, 71.0480),
    --         PropCoords2 = vector4(2716.9524, 3460.8647, 56.1613, 71.0480),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(2716.8760, 3460.8486, 57.1616, 341.4097),
    --     }
    -- },
    -- {
    --     TargetCoords = vector3(2717.6101, 3466.1440, 56.1615),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(2717.6101, 3466.1440, 56.1615, 156.8371),
    --         PropCoords2 = vector4(2717.6101, 3466.1440, 56.1615, 156.8371),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(2717.6353, 3466.0647, 56.1615, 67.6515),
    --     }
    -- },

    -- --Điểm 10
    -- {
    --     TargetCoords = vector3(-1362.5824, 4852.6768, 138.0854),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(-1362.5824, 4852.6768, 138.0854, 176.1715),
    --         PropCoords2 = vector4(-1362.5824, 4852.6768, 138.0854, 176.1715),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(-1362.5504, 4852.6040, 138.0858, 87.5256),
    --     }
    -- },
    -- {
    --     TargetCoords = vector3(-1367.9050, 4851.4990, 138.0853),
    --     TargetLabel  = '🌿 Chế biến lá đu đủ',
    --     Say = {
    --         PropCoords  = vector4(-1367.9050, 4851.4990, 138.0853, 267.9858),
    --         PropCoords2 = vector4(-1367.9050, 4851.4990, 138.0853, 267.9858),
    --     },
    --     DongGoi = {
    --         PropCoords  = vector4(-1367.8398, 4851.5303, 138.0854, 178.7536),
    --     }
    -- }

}

-- ============================================================
-- SẤY LÁ ĐU ĐỦ
-- ============================================================
Config.Say = {
    -- Prop xuất hiện khi sấy
    PropModel  = 'bzzz_free_hookah_g',
    PropModel2  = 'bkr_prop_weed_bud_01a',

    -- Progressbar
    Duration   = 6000,            -- thời gian sấy (ms)
    Label      = 'Đang sấy lá đu đủ...',
    CanCancel  = true,

    -- Animation khi sấy
    AnimDict   = 'amb@world_human_security_shine_torch@male@idle_b',
    AnimClip   = 'idle_e',

    -- Prop cầm tay khi sấy
    AnimProp = {
        model = 'prop_bzzz_drugs_light001',
        bone  = 18905,
        pos = vec3(0.126000, 0.031000, 0.000000),
        rot = vec3(52.000000, 43.000000, 45.000000)
    },
    
    -- Items
    InputItem  = 'ladudu_tuoi',    -- item cần có
    OutputItem = 'ladudu_kho',     -- item nhận được

    -- Tỷ lệ quy đổi: 1 ladudu_tuoi = 1 ladudu_kho
    InputAmount  = 1,              -- cứ mỗi X cái tươi
    OutputAmount = 1,              -- nhận được Y cái khô
    -- (server sẽ sấy toàn bộ số lượng hiện có theo tỷ lệ này)
}

-- ============================================================
-- ĐÓNG GÓI LÁ ĐU ĐỦ
-- ============================================================
Config.DongGoi = {
    -- Prop xuất hiện khi đóng gói
    PropModel  = 'bkr_prop_weed_scales_01a',

    -- Progressbar
    Duration   = 10000,            -- thời gian đóng gói (ms)
    Label      = 'Đang đóng gói lá đu đủ...',
    CanCancel  = true,

    -- Animation khi đóng gói
    AnimDict   = 'mini@repair',
    AnimClip   = 'fixing_a_ped',

    -- Items
    InputItem  = 'ladudu_kho',     -- item cần có
    OutputItem = 'goi_dudu_say',       -- item nhận được

    -- Tỷ lệ quy đổi: 3 ladudu_kho = 1 dieududu
    InputAmount  = 2,             -- cứ mỗi X cái khô
    OutputAmount = 1,              -- nhận được Y cái dié
}

