Config = {}

-- Debug mode
Config.Debug = false

-- Debug function
function DebugPrint(...)
    if Config.Debug then
        print(...)
    end
end

-- Item cấu hình cho balo
Config.BagItem = 'cloth_bags'

-- Mapping component cho cloth_bags
Config.componentMapping = {
    cloth_bags = {
        component = 5,
        prop = false,
        itemname = 'cloth_bags',
        clothesSlotID = 17,
        camera = 'default',
        label = 'Túi xách'
    },
}

-- Cấu hình cấp độ và drawable theo gender
Config.UpgradeLevels = {
    ['male'] = {
        [2] = { -- Cấp độ 3
            upgradeable_drawables = {
                10, 11, 12, 13, 14, 15, 16, 17, 18, 122, 128, 130, 131, 132, 134, 139, 140, 141,
                142, 147, 148, 149, 153, 155, 156, 157, 158, 159, 160, 164, 165, 166, 167, 170,
                172, 173, 174, 175, 181, 182, 183, 186, 187, 189, 190, 191, 195, 200, 201, 202,
                216, 218, 219, 221, 225, 226, 229, 230, 231, 237, 238, 240, 241, 243, 251, 252, 258,
                259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 275, 279, 285,
                293, 294, 295, 299, 300, 301, 302, 306, 307, 308, 309, 313, 316, 318, 393 
            }, -- Có thể trao đổi (xóa 100 vì thuộc cấp 5)
            downgrade_chance = 0, -- 5% tụt cấp
            downgrade_drawables = {},
            upgrade_normal_chance = 100, -- 5% trao đổi thường
            upgrade_normal_drawables = {
                185, 188, 193, 194, 199, 203, 205, 215, 222, 223, 224, 226,
                232, 233, 234, 235, 236, 242, 244, 245, 246, 247, 248, 249,
                250, 253, 254, 255, 256, 257, 272, 273, 274, 280, 281, 282,
                283, 284, 286, 289, 290, 303, 304, 305, 312, 313, 314, 315
            },
            upgrade_rare_chance = 0, -- 1% trao đổi hiếm   
            upgrade_rare_drawables = {}
        },
        [3] = { -- Cấp độ 3
            upgradeable_drawables = {
                89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 122, 128, 130,
                131, 132, 134, 139, 140, 141, 142, 147, 148, 149, 153, 155, 156, 157, 158, 159, 160,
                164, 165, 166, 167, 170, 172, 173, 174, 175, 181, 182, 183, 186, 187, 189, 190, 191,
                195, 200, 201, 202, 216, 218, 219, 221, 225, 229, 230, 231, 237, 238, 240, 241, 243,
                251, 252, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 275,
                279, 285, 293, 294, 295, 299, 300, 301, 302, 306, 307, 308, 309, 316, 318, 393
            }, -- Có thể trao đổi (xóa 100 vì thuộc cấp 5)
            downgrade_chance = 0, -- 5% tụt cấp
            downgrade_drawables = {},
            upgrade_normal_chance = 100, -- 5% trao đổi thường
            upgrade_normal_drawables = {
                122, 128, 130, 131, 132, 134, 139, 140, 141, 142, 147,
                148, 149, 153, 155, 156, 157, 158, 159, 160, 164, 165, 166, 167, 170,
                172, 173, 174, 175, 181, 182, 183, 186, 187, 189, 190, 191, 195, 200,
                201, 202, 216, 218, 219, 221, 225, 229, 230, 231, 237, 238, 240, 241,
                243, 251, 252, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268,
                269, 270, 271, 275, 279, 285, 293, 294, 295, 299, 300, 301, 302, 306,
                307, 308, 309, 316, 318, 393
            },
            upgrade_rare_chance = 0, -- 1% trao đổi hiếm   
            upgrade_rare_drawables = {}
        },
        [4] = { -- Cấp độ 3
            upgradeable_drawables = {
                31, 32, 33, 34, 35, 36, 37, 38, 39,
                117, 118, 119, 120, 121, 124, 125, 126, 127, 133, 135, 136, 137, 138,
                144, 145, 146, 151, 152, 154, 163, 171, 178, 179, 197, 198, 204, 217, 228,
                239, 277, 278, 291, 292, 296, 297, 298, 310, 311, 325, 326, 327, 328, 331,
                332, 333, 353, 354, 355, 357, 359, 366, 370, 371, 388, 392
            }, -- Có thể trao đổi (xóa 100 vì thuộc cấp 5)
            downgrade_chance = 0, -- 5% tụt cấp
            downgrade_drawables = {},
            upgrade_normal_chance = 100, -- 5% trao đổi thường
            upgrade_normal_drawables = {
                117, 118, 119, 120, 121, 124, 125, 126, 127, 133, 135, 136, 137,
                138, 144, 145, 146, 151, 152, 154, 163, 171, 178, 179, 197, 198,
                204, 217, 228, 239, 277, 278, 291, 292, 296, 297, 298, 310, 311,
                325, 326, 327, 328, 331, 332, 333, 353, 354, 355, 357, 359, 366,
                370, 371, 388, 392,
            },
            upgrade_rare_chance = 0, -- 1% trao đổi hiếm   
            upgrade_rare_drawables = {}
        },
        [5] = { -- Cấp độ 3
            upgradeable_drawables = {
                100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
                123, 143, 150, 161, 162, 169, 176, 177, 180, 184, 192, 196, 206,
                220, 227, 276, 287, 288, 317,  319, 320, 321, 322, 323, 324, 329,
                330, 334, 335, 336, 337, 338, 339, 340, 341, 342, 343, 344, 345,
                346, 347, 348, 349, 350, 351, 352, 356, 358, 360, 361, 362, 363,
                364, 365, 367, 368, 369, 372, 373, 374, 375, 376, 377, 378, 379,
                380, 381, 382, 383, 384, 385, 386, 387, 389, 390, 391, 394
            }, -- Có thể trao đổi (xóa 100 vì thuộc cấp 5)
            downgrade_chance = 0, -- 5% tụt cấp
            downgrade_drawables = {},
            upgrade_normal_chance = 100, -- 5% trao đổi thường
            upgrade_normal_drawables = {
                123, 143, 150, 161, 162, 169, 176, 177, 180, 184, 192, 196, 206,
                220, 227, 276, 287, 288, 317, 319, 320, 321, 322, 323, 324, 329, 330,
                334, 335, 336, 337, 338, 339, 340, 341, 342, 343, 344, 345, 346, 347,
                348, 349, 350, 351, 352, 356, 358, 360, 361, 362, 363, 364, 365, 367,
                368, 369, 372, 373, 374, 375, 376, 377, 378, 379, 380, 381, 382, 383,
                384, 385, 386, 387, 389, 390, 391, 394
            },
            upgrade_rare_chance = 0, -- 1% trao đổi hiếm   
            upgrade_rare_drawables = {}
        }
    },
    ['female'] = {
        [2] = { -- Cấp độ 3
            upgradeable_drawables = {
                    10, 11, 12, 13, 14, 15, 16, 17, 18,
                    141, 142, 143, 144, 145, 147, 148, 149, 150, 151, 153, 155,
                    156, 158, 166, 167, 170, 172, 174, 176, 177, 178, 179, 180,
                    181, 183, 187, 209, 211, 218, 222, 230, 237, 238, 239, 241,
                    247, 248, 249, 250, 251, 257, 259, 260, 261, 262, 263, 264,
                    265, 268, 269, 270, 271, 272, 287, 288, 295, 296, 297, 298,
                    299, 301, 304, 305, 318, 319, 320, 327, 328, 329, 330
            }, -- Có thể trao đổi (xóa 100 vì thuộc cấp 5)
            downgrade_chance = 0, -- 5% tụt cấp
            downgrade_drawables = {},
            upgrade_normal_chance = 100, -- 5% trao đổi thường
            upgrade_normal_drawables = {
                    141, 142, 143, 144, 145, 147, 148, 149, 150, 151, 153, 155,
                    156, 158, 166, 167, 170, 172, 174, 176, 177, 178, 179, 180,
                    181, 183, 187, 209, 211, 218, 222, 230, 237, 238, 239, 241,
                    247, 248, 249, 250, 251, 257, 259, 260, 261, 262, 263, 264,
                    265, 268, 269, 270, 271, 272, 287, 288, 295, 296, 297, 298,
                    299, 301, 304, 305, 318, 319, 320, 327, 328, 329, 330
            },
            upgrade_rare_chance = 0, -- 1% trao đổi hiếm   
            upgrade_rare_drawables = {}
        },
        [3] = { -- Cấp độ 3
            upgradeable_drawables = {
                89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99,
                129, 131, 132, 133, 134, 136, 161, 184, 185, 186, 188, 189, 190, 194,
                195, 197, 199, 200, 201, 202, 208, 212, 213, 157, 231, 233, 234, 236,
                240, 244, 245, 246, 252, 253, 255, 256, 258, 266, 267, 273, 274, 275,
                276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 289, 290, 294,
                300, 308, 309, 310, 314, 315, 316, 317, 321, 322, 323, 324, 331, 333, 334
            }, -- Có thể trao đổi (xóa 100 vì thuộc cấp 5)
            downgrade_chance = 0, -- 5% tụt cấp
            downgrade_drawables = {},
            upgrade_normal_chance = 100, -- 5% trao đổi thường
            upgrade_normal_drawables = {
                129, 131, 132, 133, 134, 136, 161, 184, 185, 186, 188, 189, 190, 194,
                195, 197, 199, 200, 201, 202, 208, 212, 213, 157, 231, 233, 234, 236,
                240, 244, 245, 246, 252, 253, 255, 256, 258, 266, 267, 273, 274, 275,
                276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 289, 290, 294,
                300, 308, 309, 310, 314, 315, 316, 317, 321, 322, 323, 324, 331, 333, 334
            },
            upgrade_rare_chance = 0, -- 1% trao đổi hiếm   
            upgrade_rare_drawables = {}
        },
        [4] = { -- Cấp độ 3
            upgradeable_drawables = {
                31, 32, 33, 34, 35, 36, 37, 38, 39,
                120, 121, 122, 123, 124, 125, 128, 130, 135, 160, 163, 164,
                168, 198, 203, 210, 215, 216, 219, 152, 154, 173, 232, 243,
                254, 292, 293, 306, 307, 311, 312, 313, 325, 326, 335, 336,
                337, 338, 339, 340, 341, 342, 343, 353, 354, 355, 356, 357,
                358, 363, 368, 369, 384, 387, 389, 391, 394, 395, 409
            }, -- Có thể trao đổi (xóa 100 vì thuộc cấp 5)
            downgrade_chance = 0, -- 5% tụt cấp
            downgrade_drawables = {},
            upgrade_normal_chance = 100, -- 5% trao đổi thường
            upgrade_normal_drawables = {
                120, 121, 122, 123, 124, 125, 128, 130, 135, 160, 163, 164,
                168, 198, 203, 210, 215, 216, 219, 152, 154, 173, 232, 243,
                254, 292, 293, 306, 307, 311, 312, 313, 325, 326, 335, 336,
                337, 338, 339, 340, 341, 342, 343, 353, 354, 355, 356, 357,
                358, 363, 368, 369, 384, 387, 389, 391, 394, 395, 409
            },
            upgrade_rare_chance = 0, -- 1% trao đổi hiếm   
            upgrade_rare_drawables = {}
        },
        [5] = { -- Cấp độ 3
            upgradeable_drawables = {
                100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
                126, 127, 138, 139, 140, 162, 175, 217, 221, 171, 146, 192, 191, 159,
                235, 242, 291, 302, 303, 332, 344, 345, 346, 347, 348, 349, 350, 351,
                352, 359, 360, 361, 362, 364, 365, 366, 367, 370, 371, 372, 373, 374,
                375, 376, 377, 378, 379, 380, 381, 382, 383, 385, 386, 388, 390, 392,
                393, 396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 406, 407, 408,
                410, 411, 412
            }, -- Có thể trao đổi (xóa 100 vì thuộc cấp 5)
            downgrade_chance = 0, -- 5% tụt cấp
            downgrade_drawables = {},
            upgrade_normal_chance = 100, -- 5% trao đổi thường
            upgrade_normal_drawables = {
                126, 127, 138, 139, 140, 162, 175, 217, 221, 171, 146, 192, 191, 159,
                235, 242, 291, 302, 303, 332, 344, 345, 346, 347, 348, 349, 350, 351,
                352, 359, 360, 361, 362, 364, 365, 366, 367, 370, 371, 372, 373, 374,
                375, 376, 377, 378, 379, 380, 381, 382, 383, 385, 386, 388, 390, 392,
                393, 396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 406, 407, 408, 410, 411, 412
            },
            upgrade_rare_chance = 0, -- 1% trao đổi hiếm   
            upgrade_rare_drawables = {}
        }
    }
}

-- Vật phẩm cần có để trao đổi theo Level
Config.UpgradeRequirementsByLevel = {
    [2] = { -- Cấp độ 3 -> 4
        {item = 'money', amount = 100000}
    },
    [3] = { -- Cấp độ 3 -> 4
        {item = 'vdm_ngaunhien', amount = 1}
    },
    [4] = { -- Cấp độ 4 -> 5
        {item = 'vdm_ngaunhien', amount = 2}
    },
    [5] = { -- Cấp độ 5 -> 6 (cao nhất)
        {item = 'vdm_ngaunhien', amount = 3},
    }
}

-- Vật phẩm cần có để trao đổi theo DoHiem (legacy, sẽ được thay thế)
Config.UpgradeRequirements = {
    ['Uncommon'] = {
        {item = 'money', amount = 100000}
    },
    ['Rare'] = {
        {item = 'vdm_ngaunhien', amount = 1}
    },
    ['Epic'] = { -- Có thể mở rộng
        {item = 'vdm_ngaunhien', amount = 2}
    },
    ['Legendary'] = { -- Có thể mở rộng
        {item = 'vdm_ngaunhien', amount = 3},
    }
}

-- Vật phẩm cần có để đổi mẫu theo yêu cầu (theo Level)
Config.CustomUpgradeRequirementsByLevel = {
    [2] = {
        {item = 'money', amount = 200000}
    },
    [3] = {
        {item = 'vdm_tuychon', amount = 1}
    },
    [4] = {
        {item = 'vdm_tuychon', amount = 2}
    },
    [5] = {
        {item = 'vdm_tuychon', amount = 3}
    }
}

-- Vật phẩm cần có để đổi mẫu theo yêu cầu (theo DoHiem - legacy)
Config.CustomUpgradeRequirements = {
    ['Uncommon'] = {
        {item = 'money', amount = 200000}
    },
    ['Rare'] = {
        {item = 'vdm_tuychon', amount = 1}
    },
    ['Epic'] = {
        {item = 'vdm_tuychon', amount = 2}
    },
    ['Legendary'] = {
        {item = 'vdm_tuychon', amount = 3}
    }
}


-- Cấu hình trao đổi bằng coin (100% thành công)
Config.CoinUpgrade = {
    enabled = false,
    cost_per_level = {
        [2] = 100,  -- Từ cấp 2 lên cấp 3 cần 100 coin
        [3] = 200,  -- Từ cấp 3 lên cấp 4 cần 200 coin
        [4] = 500,  -- Từ cấp 4 lên cấp 5 cần 500 coin
        [5] = 800,  -- Từ cấp 5 lên cấp 6 cần 800 coin
    },
    success_rate = 100, -- 100% thành công
    countdown_time = 3, -- 3 giây đếm ngược
    -- Tỷ lệ nhận được rare vs normal khi coin upgrade
    rare_chance = 0, -- 20% nhận rare drawables
    normal_chance = 100 -- 80% nhận normal drawables
}

-- Hierarchy DoHiem (độ hiếm)
Config.RarityHierarchy = {
    'Common',
    'Uncommon',
    'Rare',
    'Epic',
    'Legendary'
}

-- Function để lấy index của rarity
function GetRarityIndex(rarity)
    for i, r in ipairs(Config.RarityHierarchy) do
        if r == rarity then
            return i
        end
    end
    return 3 -- Default to Rare if not found
end

-- Function để upgrade/downgrade rarity
function UpgradeRarity(currentRarity)
    local index = GetRarityIndex(currentRarity)
    if index < #Config.RarityHierarchy then
        return Config.RarityHierarchy[index + 1]
    end
    return currentRarity -- Đã max level
end

function DowngradeRarity(currentRarity)
    local index = GetRarityIndex(currentRarity)
    if index > 1 then
        return Config.RarityHierarchy[index - 1]
    end
    return currentRarity -- Đã min level
end

-- Cấu hình ảnh
Config.ImageSettings = {
    Url = "https://raw.githubusercontent.com/xuannguyen995/miniclothing/refs/heads/main",
    Extension = "webp",
    component_id = 5 -- component cho cloth_bagsconfig.lua
}

-- Cấu hình giá cho appraisal theo cấp độ
Config.AppraisalCost = {
    [2] = 0,  -- Cấp độ 2 = 1000$
    [3] = 0,  -- Cấp độ 3 = 3000$
    [4] = 0,  -- Cấp độ 4 = 10000$
    [5] = 0,  -- Cấp độ 5 = 20000$
}

-- Command để mở UI (TẮT - dùng ox_target)
Config.OpenCommand = "thamdinhtui" -- Chỉ dùng cho debug, không còn active

-- ox_target Configuration
Config.Target = {
    enabled = true,
    model = 'prop_tablesaw_01',
    icon = 'fa-solid fa-suitcase', -- Font Awesome 6 format
    label = 'Đổi mẫu Balo',
    distance = 3.0
}

-- Thời gian đếm ngược (giây)
Config.CountdownTime = 5
