-- Hàm phân tích stackable item:
-- fishingrod -> {baseName = "fishingrod", level = 1}
-- fishingrod1 -> {baseName = "fishingrod", level = 1}
-- fishingrod2 -> {baseName = "fishingrod", level = 2}
-- Dùng chung cho cả client và server
local function ParseStackableItemConfig(itemName)
    -- Cần duyệt componentMapping sau khi Config được định nghĩa
    if not Config or not Config.componentMapping then return nil end
    for baseName, mapping in pairs(Config.componentMapping) do
        if mapping.isStackable and mapping.type == 'item' then
            -- Kiểm tra xem itemName có khớp chính xác baseName không (fishingrod = level 1)
            if itemName == baseName then
                return {baseName = baseName, level = 1}
            end
            local pattern = "^" .. baseName .. "(%d+)$"
            local levelStr = string.match(itemName, pattern)
            if levelStr then
                return {baseName = baseName, level = tonumber(levelStr)}
            end
        end
    end
    return nil
end

-- Tính phần trăm nâng cấp dựa trên vật liệu đã chọn
-- Sử dụng cấu trúc BaloLevels với clothing rarity (DoHiem)
-- itemsSelected là danh sách {name = string, quantity = number, DoHiem = string}
-- Trả về tỷ lệ HIỂN THỊ (capped by maxtile) - dùng cho UI
function CalcPercent(item, itemsSelected)
    if not item then return 0 end

    -- Ensure metadata and Capdo exist
    if not item.metadata then item.metadata = {} end

    -- Kiểm tra stackable item
    local stackableInfo = ParseStackableItemConfig(item.name)
    local baseName = stackableInfo and stackableInfo.baseName or item.name
    local currentCapdo = stackableInfo and stackableInfo.level or
                             item.metadata.Capdo or 1

    -- Lấy config level từ BaloLevels (dùng baseName)
    local itemConfig = Config.BaloLevels[baseName]
    if not itemConfig then return 0 end

    local levelConfig = itemConfig[currentCapdo]
    if not levelConfig then return 0 end

    local totalPercent = 0

    -- Duyệt qua các vật phẩm đã chọn và tính tổng %
    for k, v in pairs(itemsSelected) do
        -- Lấy rarity (DoHiem) và số lượng
        local materialKey = v.DoHiem or "Common"
        local quantity = v.quantity or 1

        -- Lấy % từ bảng tyle theo rarity và nhân với số lượng
        if levelConfig.tyle and levelConfig.tyle[materialKey] then
            totalPercent = totalPercent +
                               (levelConfig.tyle[materialKey] * quantity)
        end
    end

    -- Giới hạn tối đa theo maxtile (cho hiển thị)
    if totalPercent > levelConfig.maxtile then
        totalPercent = levelConfig.maxtile
    end

    return totalPercent
end

function CalcRealPercent(item, itemsSelected)
    if not item then return 0 end

    -- Ensure metadata and Capdo exist
    if not item.metadata then item.metadata = {} end

    -- Kiểm tra stackable item
    local stackableInfo = ParseStackableItemConfig(item.name)
    local baseName = stackableInfo and stackableInfo.baseName or item.name
    local currentCapdo = stackableInfo and stackableInfo.level or
                             item.metadata.Capdo or 1

    -- Lấy config level từ BaloLevels (dùng baseName)
    local itemConfig = Config.BaloLevels[baseName]
    if not itemConfig then return 0 end

    local levelConfig = itemConfig[currentCapdo]
    if not levelConfig then return 0 end

    local totalPercent = 0

    -- Duyệt qua các vật phẩm đã chọn và tính tổng %
    for k, v in pairs(itemsSelected) do
        -- Lấy rarity (DoHiem) và số lượng
        local materialKey = v.DoHiem or "Common"
        local quantity = v.quantity or 1

        -- Lấy % từ bảng tyle theo rarity và nhân với số lượng
        if levelConfig.tyle and levelConfig.tyle[materialKey] then
            totalPercent = totalPercent +
                               (levelConfig.tyle[materialKey] * quantity)
        end
    end

    -- Giới hạn tối đa theo realtile (nếu có), nếu không có thì dùng maxtile
    -- realtile là tỷ lệ thành công thực sự, ẩn với người chơi
    local maxRate = levelConfig.realtile or levelConfig.maxtile
    if totalPercent > maxRate then totalPercent = maxRate end

    return totalPercent
end

function GetItemImageUrl(itemName, metadata, gender)
    -- Check if it's a clothing item (has component)
    local clothingConfig = Config.componentMapping[itemName]

    if clothingConfig and not clothingConfig.isStackable and metadata then
        -- Try both 'drawable' and 'item' metadata fields (ox_inventory variants)
        local drawableVal = metadata.drawable or metadata.item
        if drawableVal ~= nil then
            local genderPrefix = gender or metadata.sex or metadata.gender or
                                     "male"
            if genderPrefix ~= "male" and genderPrefix ~= "female" then
                genderPrefix = "male"
            end
            local component = clothingConfig.component
            local drawable = tonumber(drawableVal) or 0

            local imageName = string.format("%s_%d_%d", genderPrefix, component,
                                            drawable)
            return
                "https://raw.githubusercontent.com/xuannguyen995/miniclothing/refs/heads/main/" ..
                    imageName .. ".webp"
        end
    end
    -- For non-clothing items or stackable items
    return
        "https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/" ..
            itemName .. ".webp"
end

Config = {
    debug = false,
    Textserial = "MI",
    DiscordWebhook = "https://discord.com/api/webhooks/1485214125012422668/2-TZHI0CQFbP_yDQuMo99k4oFdz1lOs8qT2TrVkqAZdtl3uJUboWyvVpJ94kIykO141Z",
    componentMapping = {
        cloth_bags = {
            component = 5,
            prop = false,
            itemname = 'cloth_bags',
            clothesSlotID = 17,
            camera = 'default',
            label = 'Túi xách'
        },
        cloth_mask = {
            component = 1,
            prop = false,
            itemname = 'cloth_mask',
            clothesSlotID = 1,
            camera = 'default',
            label = 'Mặt nạ'
        },
        cloth_helmet = {
            component = 0,
            prop = true,
            itemname = 'cloth_helmet',
            clothesSlotID = 0,
            camera = 'default',
            label = 'Mũ'
        },
        cloth_ears = {
            component = 2,
            prop = true,
            itemname = 'cloth_ears',
            clothesSlotID = 2,
            camera = 'default',
            label = 'Phụ kiện tai'
        },
        cloth_glasses = {
            component = 1,
            prop = true,
            itemname = 'cloth_glasses',
            clothesSlotID = 1,
            camera = 'default',
            label = 'Kính mắt'
        },
        cloth_tshirt = {
            component = 8,
            prop = false,
            itemname = 'cloth_tshirt',
            clothesSlotID = 8,
            camera = 'default',
            label = 'Áo thun'
        },
        cloth_torso = {
            component = 11,
            prop = false,
            itemname = 'cloth_torso',
            clothesSlotID = 11,
            camera = 'default',
            label = 'Áo khoác'
        },
        cloth_bproof = {
            component = 9,
            prop = false,
            itemname = 'cloth_bproof',
            clothesSlotID = 9,
            camera = 'default',
            label = 'Áo chống đạn'
        },
        cloth_bracelets = {
            component = 7,
            prop = true,
            itemname = 'cloth_bracelets',
            clothesSlotID = 7,
            camera = 'default',
            label = 'Vòng tay'
        },
        cloth_watches = {
            component = 6,
            prop = true,
            itemname = 'cloth_watches',
            clothesSlotID = 6,
            camera = 'default',
            label = 'Đồng hồ'
        },
        cloth_chain = {
            component = 7,
            prop = false,
            itemname = 'cloth_chain',
            clothesSlotID = 7,
            camera = 'default',
            label = 'Dây chuyền'
        },
        cloth_pants = {
            component = 4,
            prop = false,
            itemname = 'cloth_pants',
            clothesSlotID = 4,
            camera = 'default',
            label = 'Quần dài'
        },
        cloth_shoes = {
            component = 6,
            prop = false,
            itemname = 'cloth_shoes',
            clothesSlotID = 6,
            camera = 'default',
            label = 'Giày'
        },
        cloth_arms = {
            component = 3,
            prop = false,
            itemname = 'cloth_arms',
            clothesSlotID = 3,
            camera = 'default',
            label = 'Phụ kiện tay'
        },
        fishingrod = {
            component = nil,
            prop = false,
            itemname = 'fishingrod',
            clothesSlotID = nil,
            camera = 'default',
            label = 'Cần Câu',
            isStackable = true,
            type = 'item', -- item phân theo cấp: fishingrod1, fishingrod2, ...
            maxLevel = 5 -- cấp tối đa
        },
        chaodaivang = {
            component = nil,
            prop = false,
            itemname = 'chaodaivang',
            clothesSlotID = nil,
            camera = 'default',
            label = 'Chảo đãi vàng',
            isStackable = true,
            type = 'item', -- item phân theo cấp: chaodaivang1, chaodaivang2, ...
            maxLevel = 5 -- cấp tối đa
        }
    },
    Locations = {vector4(197.7834, -996.3307, 32.1545, 260.0996)},
    -- Danh sách item có thể nâng cấp
    ItemBalo = {'cloth_bags', 'fishingrod', 'chaodaivang'},

    -- Cấp độ tối đa
    maxLevel = 8,

    -- Clothing items từ componentMapping được dùng làm vật liệu nâng cấp
    -- Trừ các item trong danh sách loại trừ này
    ExcludedUpgradeMaterials = {"cloth_bags"},

    -- Thứ tự rarity để so sánh
    RarityOrder = {
        ["Common"] = 1,
        ["Uncommon"] = 2,
        ["Rare"] = 3,
        ["Epic"] = 4,
        ["Legendary"] = 5
    },

    BaloLevels = {
        -- ==================== TÚI XÁCH (cloth_bags) ====================
        cloth_bags = {
            [1] = {
                male = {1, 2, 3},
                female = {1, 2, 3},
                nextadd = {
                    male = {10, 11, 12, 13, 14, 15, 16, 17, 18},
                    female = {10, 11, 12, 13, 14, 15, 16, 17, 18},
                },
                hesoChia = 1,
                hasrarity = 'Common',
                maxtile = 80,
                returnitem = nil,
                tyle = {
                    ['Common'] = 5,
                    ['Uncommon'] = 10,
                    ['Rare'] = 20,
                    ['Epic'] = 40,
                    ['Legendary'] = 80
                }
            },
            [2] = {
                male = {10, 11, 12, 13, 14, 15, 16, 17, 18,
                    185, 188, 193, 194, 199, 203, 205, 215, 222, 223, 224, 226,
                    232, 233, 234, 235, 236, 242, 244, 245, 246, 247, 248, 249,
                    250, 253, 254, 255, 256, 257, 272, 273, 274, 280, 281, 282,
                    283, 284, 286, 289, 290, 303, 304, 305, 312, 313, 314, 315
                },
                female = {10, 11, 12, 13, 14, 15, 16, 17, 18,
                    141, 142, 143, 144, 145, 147, 148, 149, 150, 151, 153, 155,
                    156, 158, 166, 167, 170, 172, 174, 176, 177, 178, 179, 180,
                    181, 183, 187, 209, 211, 218, 222, 230, 237, 238, 239, 241,
                    247, 248, 249, 250, 251, 257, 259, 260, 261, 262, 263, 264,
                    265, 268, 269, 270, 271, 272, 287, 288, 295, 296, 297, 298,
                    299, 301, 304, 305, 318, 319, 320, 327, 328, 329, 330
                },
                nextadd = {
                    male = {
                        89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99
                    },
                    female = {
                        89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99
                    }
                },
                hesoChia = 2,
                hasrarity = 'Uncommon',
                maxtile = 75,
                pity_rate = {15, 20},
                returnitem = nil,
                realtile = 60,
                failBackTo = 1,
                tyle = {
                    ['Common'] = 2.5,
                    ['Uncommon'] = 5,
                    ['Rare'] = 10,
                    ['Epic'] = 20,
                    ['Legendary'] = 40
                }
            },
            [3] = {
                male = {89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99,
                    122, 128, 130, 131, 132, 134, 139, 140, 141, 142, 147, 148,
                    149, 153, 155, 156, 157, 158, 159, 160, 164, 165, 166, 167,
                    170, 172, 173, 174, 175, 181, 182, 183, 186, 187, 189, 190,
                    191, 195, 200, 201, 202, 216, 218, 219, 221, 225, 229, 230,
                    231, 237, 238, 240, 241, 243, 251, 252, 258, 259, 260, 261,
                    262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 275, 279,
                    285, 293, 294, 295, 299, 300, 301, 302, 306, 307, 308, 309,
                    316, 318
                },
                female = {89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99,
                    129, 131, 132, 133, 134, 136, 161, 184, 185, 186, 188, 189,
                    190, 194, 195, 197, 199, 200, 201, 202, 208, 212, 213, 157,
                    231, 233, 234, 236, 240, 244, 245, 246, 252, 253, 255, 256,
                    258, 266, 267, 273, 274, 275, 276, 277, 278, 279, 280, 281,
                    282, 283, 284, 285, 286, 289, 290, 294, 300, 308, 309, 310,
                    314, 315, 316, 317, 321, 322, 323, 324, 331, 333
                },
                nextadd = {
                    male = {
                            31, 32, 33, 34, 35, 36, 37, 38, 39
                    },
                    female = {31, 32, 33, 34, 35, 36, 37, 38, 39
                    }
                },
                hesoChia = 3.3,
                hasrarity = 'Rare',
                maxtile = 65,
                downlevel = true,
                pity_rate = {40, 60},
                returnitem = nil,
                realtile = 15,
                failBackTo = 2,
                tyle = {
                    ['Common'] = 1.5,
                    ['Uncommon'] = 3,
                    ['Rare'] = 5,
                    ['Epic'] = 10,
                    ['Legendary'] = 20
                }
            },
            [4] = {
                male = {31, 32, 33, 34, 35, 36, 37, 38, 39,
                    117, 118, 119, 120, 121, 124, 125, 126, 127, 133, 135, 136,
                    137, 138, 144, 145, 146, 151, 152, 154, 163, 171, 178, 179,
                    197, 198, 204, 217, 228, 239, 277, 278, 291, 292, 296, 297,
                    298, 310, 311
                },
                female = {31, 32, 33, 34, 35, 36, 37, 38, 39,
                    120, 121, 122, 123, 124, 125, 128, 130, 135, 160, 163, 164,
                    168, 198, 203, 210, 215, 216, 219, 152, 154, 173, 232, 243,
                    254, 292, 293, 306, 307, 311, 312, 313, 325, 326
                },
                nextadd = {
                    male = {100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
                        123, 143, 150, 161, 162, 169, 176, 177, 180, 184, 192,
                        196, 206, 220, 227, 276, 287, 288, 317
                    },
                    female = {100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
                        126, 127, 138, 139, 140, 162, 175, 217, 221, 171, 146,
                        192, 191, 159, 235, 242, 291, 302, 303, 332
                    }
                },
                hesoChia = 5,
                hasrarity = 'Epic',
                maxtile = 60,
                downlevel = true,
                pity_rate = {60, 80},
                returnitem = nil,
                realtile = 10,
                failBackTo = 3,
                tyle = {
                    ['Common'] = 1,
                    ['Uncommon'] = 2,
                    ['Rare'] = 3,
                    ['Epic'] = 5,
                    ['Legendary'] = 10
                }
            },
            [5] = {
                male = {},
                female = {},
                nextadd = {male = {}, female = {}},
                hesoChia = 6,
                hasrarity = 'Legendary',
                maxtile = 55,
                returnitem = nil,
                realtile = 5,
                failBackTo = 4,
                tyle = {
                    ['Common'] = 0.5,
                    ['Uncommon'] = 1,
                    ['Rare'] = 2,
                    ['Epic'] = 3,
                    ['Legendary'] = 5
                }
            },
            [6] = {
                male = {},
                female = {},
                nextadd = {male = {}, female = {}},
                hesoChia = 7,
                hasrarity = 'Legendary',
                maxtile = 50,
                returnitem = nil,
                realtile = 2,
                failBackTo = 5,
                tyle = {
                    ['Common'] = 0.2,
                    ['Uncommon'] = 0.5,
                    ['Rare'] = 1,
                    ['Epic'] = 2,
                    ['Legendary'] = 3
                }
            },
            [7] = {
                male = {},
                female = {},
                hesoChia = 8,
                hasrarity = 'Legendary',
                maxtile = 45,
                returnitem = nil,
                realtile = 1,
                failBackTo = 6,
                tyle = {
                    ['Common'] = 0.1,
                    ['Uncommon'] = 0.2,
                    ['Rare'] = 0.5,
                    ['Epic'] = 1,
                    ['Legendary'] = 2
                }
            },
            [8] = {
                -- Level max - không thể nâng tiếp
                male = {},
                female = {},
                hesoChia = 10,
                maxtile = 0,
                realtile = 0,
                failBackTo = 7,
                tyle = {}
            }
        },

        -- ==================== CẦN CÂU (fishingrod) ====================
        fishingrod = {
            [1] = {
                male = {},
                female = {},
                hesoChia = 1,
                hasrarity = 'Common',
                maxtile = 80,
                returnitem = nil,
                tyle = {
                    ['Common'] = 5,
                    ['Uncommon'] = 10,
                    ['Rare'] = 20,
                    ['Epic'] = 40,
                    ['Legendary'] = 80
                }
            },
            [2] = {
                male = {},
                female = {},
                hesoChia = 2,
                hasrarity = 'Uncommon',
                maxtile = 75,
                returnitem = nil,
                pity_rate = {5, 10},
                realtile = 60,
                failBackTo = 1,
                tyle = {
                    ['Common'] = 2.5,
                    ['Uncommon'] = 5,
                    ['Rare'] = 10,
                    ['Epic'] = 20,
                    ['Legendary'] = 40
                }
            },
            [3] = {
                male = {},
                female = {},
                hesoChia = 3.3,
                hasrarity = 'Rare',
                maxtile = 65,
                returnitem = nil,
                pity_rate = {15, 20},
                realtile = 40,
                failBackTo = 2,
                tyle = {
                    ['Common'] = 1.5,
                    ['Uncommon'] = 3,
                    ['Rare'] = 5,
                    ['Epic'] = 10,
                    ['Legendary'] = 20
                }
            },
            [4] = {
                male = {},
                female = {},
                hesoChia = 5,
                hasrarity = 'Epic',
                maxtile = 60,
                returnitem = nil,
                realtile = 20,
                pity_rate = {20, 30},
                failBackTo = 3,
                tyle = {
                    ['Common'] = 1,
                    ['Uncommon'] = 2,
                    ['Rare'] = 3,
                    ['Epic'] = 5,
                    ['Legendary'] = 10
                }
            },
            [5] = {
                -- Level max cho fishingrod
                male = {},
                female = {},
                hesoChia = 6,
                maxtile = 0,
                realtile = 0,
                failBackTo = 4,
                tyle = {}
            }
        },

        -- ==================== CHẢO ĐÃI VÀNG (chaodaivang) ====================
        chaodaivang = {
            [1] = {
                male = {},
                female = {},
                hesoChia = 1,
                hasrarity = 'Common',
                maxtile = 80,
                returnitem = nil,
                tyle = {
                    ['Common'] = 5,
                    ['Uncommon'] = 10,
                    ['Rare'] = 20,
                    ['Epic'] = 40,
                    ['Legendary'] = 80
                }
            },
            [2] = {
                male = {},
                female = {},
                hesoChia = 2,
                hasrarity = 'Uncommon',
                maxtile = 75,
                returnitem = nil,
                realtile = 60,
                failBackTo = 1,
                tyle = {
                    ['Common'] = 2.5,
                    ['Uncommon'] = 5,
                    ['Rare'] = 10,
                    ['Epic'] = 20,
                    ['Legendary'] = 40
                }
            },
            [3] = {
                male = {},
                female = {},
                hesoChia = 3.3,
                hasrarity = 'Rare',
                maxtile = 65,
                returnitem = nil,
                realtile = 30,
                failBackTo = 2,
                tyle = {
                    ['Common'] = 1.5,
                    ['Uncommon'] = 3,
                    ['Rare'] = 5,
                    ['Epic'] = 10,
                    ['Legendary'] = 20
                }
            },
            [4] = {
                male = {},
                female = {},
                hesoChia = 5,
                hasrarity = 'Epic',
                maxtile = 60,
                returnitem = nil,
                realtile = 15,
                failBackTo = 3,
                tyle = {
                    ['Common'] = 1,
                    ['Uncommon'] = 2,
                    ['Rare'] = 3,
                    ['Epic'] = 5,
                    ['Legendary'] = 10
                }
            },
            [5] = {
                -- Level max cho chaodaivang
                male = {},
                female = {},
                hesoChia = 6,
                maxtile = 0,
                realtile = 0,
                failBackTo = 4,
                tyle = {}
            }
        }
    }
};
