Config = {}

-- Helper function to convert any truthy prop representation (true, 1, "1", "true") to boolean
function isPropToBool(val)
    if val == true or val == 1 or val == "1" or val == "true" then
        return true
    end
    return false
end


Config.ServerName =
"ServerName"                                                                                -- CHANGE THIS FOR SCREENSHOT OF YOUR OUTFIT !!!!!
Config.ServerLogo = "https://projetcartylion.fr/wp-content/uploads/2020/08/Placeholder.png" -- The url to the server logo

Config.Url =
"https://raw.githubusercontent.com/xuannguyen995/miniclothing/refs/heads/main" -- The url to the image exemple (https://localhost:3000/images) or if in the folder images put (/web/build/images)
Config.Extension = "webp"                                                   -- The extension of the image (png, webp, jpg, etc.)
Config.UrlInventory = true                                                  -- use only if you use a cloud for images (if disabled disable NoImage)
Config.NoImage = false                                                      --if true, the image will be the same on all categories (if enabled disable UrlInventory)

Config.EnableSound = true                                                   -- if true, the sound will be played when you click on an item

Config.StaffGroup = {
    "license:4718a60e-86b0-44c6-b6e3-4e4e279a978d", --XN
    "license:a17d2435-8433-4c2c-8650-1fe1509e2cab", --Kon
    "license:e413f60d-1dec-42df-998f-50945a6f080b", --Soi
    "license:294c5a5e-c194-4889-896a-0c332fcbc02f", --Kon2
    "license:2382446a-779c-4adc-b601-ed2c82d5c40d", --SonHoang
    "license:dec537b0-c953-4eb3-a3db-a876a4e7cb58", --Toibikho
    -- "license:e6104924-2135-4de0-a446-51d929799ad3", --Black
    "license:d54e8b57-b352-465e-b99b-64b0ce69ff41" --Anh Chon (thanh phan nguy hiem)
}

Config.Animation = false -- If you want to play an animation when you open the menu
Config.AnimationName = "anim@heists@heist_corona@single_team"
Config.AnimationName2 = "single_team_loop_boss"

Config.SaveOutfit = false     -- if true in the menu you can save your outfit (if active our player can duplicate the clothes !!)
Config.SaveOutfitPrice = 1000 -- The price to save an outfit
Config.CopyOutfitPrice = 1000 -- The price to copy an outfit
Config.TakeOutfitPrice = 1000 -- The price to take an outfit

Config.UseIllenium = true     -- true = Use Illenium-Appearance, false = Use SKINCHANGER

Config.InventorySlot = 33     -- Please set the same value in ox_inventory/init.lua (playerslots = 60,)


-- Cấu hình hệ thống Durability (DISABLED - Đã tắt hoàn toàn)
Config.Durability = {
    MonitoringEnabled = false,       -- DISABLED - Tắt hệ thống kiểm tra durability
    MonitoringInterval = 999999,     -- Không sử dụng
    AutoRemoveBroken = false,        -- DISABLED - Không tự động tháo
    LowDurabilityWarning = false,    -- DISABLED - Không cảnh báo
    LowDurabilityThreshold = 0,      -- Không sử dụng
    WarningCooldown = 999999,        -- Không sử dụng
    ExcludeItems = {},               -- Không sử dụng
    UsePersonalStorage = true,      -- Không sử dụng
}


-- Warning: Our server could shut down at any time, and you would lose all your saved images.
-- We highly recommend using your own server or disabling screenshots to avoid losing your data.

-- If you want to use your own server for the screenshot, get the backend here: https://github.com/MaskeZenY/MClothes-StockImages
-- HTTPS is required
Config.UseScreenshot = false                                  -- true = Use Screenshot, false = Disable Screenshot
Config.ScreenshotUrl = "https://api2.discordtools.lol/upload" -- The URL to upload the screenshot
Config.ScreenshotGetUrl =
"https://api2.discordtools.lol/getimage"                      -- The URL to retrieve the screenshot (if you change, update in CSS .outfit-image[src^="https://api2.discordtools.lol/getimage/"])

Config.PedDepth = 1.5                                         -- The depth of the ped in the inventory

Config.UseCustomOXInventory = true                            -- if true, you will use the custom ox_inventory in keymaster

Config.Decription = "Thời trang của "

-- Default outfit (male)
Config.DefaultOutfit = {
    components = {
        { component_id = 1,  drawable = 0,  texture = 0, name = "mask_1" },
        { component_id = 3,  drawable = 15, texture = 0, name = "arms" },
        { component_id = 4,  drawable = 61, texture = 0, name = "pants_1" },
        { component_id = 5,  drawable = 0,  texture = 0, name = "bags_1" },
        { component_id = 6,  drawable = 34, texture = 0, name = "shoes_1" },
        { component_id = 7,  drawable = 1,  texture = 0, name = "chain_1" },
        { component_id = 8,  drawable = 15, texture = 0, name = "tshirt_1" },
        { component_id = 9,  drawable = 0,  texture = 0, name = "bproof_1" },
        { component_id = 10, drawable = 0,  texture = 0, name = "decals" },
        { component_id = 11, drawable = 15, texture = 0, name = "torso_1" },

    },
    props = {
        { prop_id = 0, drawable = -1, texture = 0, name = "helmet_1" },
        { prop_id = 1, drawable = 0,  texture = 0, name = "glasses_1" },
        { prop_id = 6, drawable = -1, texture = 0, name = "watches_1" },
        { prop_id = 7, drawable = -1, texture = 0, name = "bracelets_1" },
        { prop_id = 2, drawable = -1, texture = 0, name = "ears_1" },
    }
}

-- Default outfit (female)
Config.DefaultOutfitWoman = {
    components = {
        { component_id = 1,  drawable = 0,  texture = 0, name = "mask_1" },
        { component_id = 3,  drawable = 15, texture = 0, name = "arms" },
        { component_id = 4,  drawable = 15, texture = 0, name = "pants_1" },
        { component_id = 5,  drawable = 0,  texture = 0, name = "bags_1" },
        { component_id = 6,  drawable = 35, texture = 0, name = "shoes_1" },
        { component_id = 7,  drawable = 0,  texture = 0, name = "chain_1" },
        { component_id = 8,  drawable = 15, texture = 0, name = "tshirt_1" },
        { component_id = 9,  drawable = 0,  texture = 0, name = "bproof_1" },
        { component_id = 10, drawable = 0,  texture = 0, name = "decals" },
        { component_id = 11, drawable = 15, texture = 0, name = "torso_1" },

    },
    props = {
        { prop_id = 0, drawable = -1, texture = 0, name = "helmet_1" },
        { prop_id = 1, drawable = 0,  texture = 0, name = "glasses_1" },
        { prop_id = 6, drawable = -1, texture = 0, name = "watches_1" },
        { prop_id = 7, drawable = -1, texture = 0, name = "bracelets_1" },
        { prop_id = 2, drawable = -1, texture = 0, name = "ears_1" },
    }
}


Config.Coords = { 
    -- { x = 219.8566, y = -944.4186, z = 28.6353, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat"} },
    { x = 72.3, y = -1399.1, z = 28.4, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat", "hat"} },
    { x = -703.8, y = -152.3, z = 36.4, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat", "hat"} },
    { x = -167.9, y = -299.0, z = 38.7, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat", "hat"} },
    { x = 428.7, y = -800.1, z = 28.5, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat"} },
    { x = -829.4, y = -1073.7, z = 10.3, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat"} },
    { x = -1447.8, y = -242.5, z = 48.8, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat"} },
    { x = 11.6, y = 6514.2, z = 30.9, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "shoes"} },
    { x = 123.6, y = -219.4, z = 53.6, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat"} },
    { x = 1696.3, y = 4829.3, z = 41.1, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat"} },
    { x = 618.1, y = 2759.6, z = 41.1, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat"} },
    { x = 1190.6, y = 2713.4, z = 37.2, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat"} },
    { x = -1193.4, y = -772.3, z = 16.3, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat"} },
    { x = -3172.5, y = 1048.1, z = 19.9, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat"} },
    { x = -1108.4, y = 2708.9, z = 18.1, blips = true, BlipsName = "Cửa hàng quần áo", blipsid = 73, blipcolor = 47, category = { "shirt", "torso", "gloves", "earrings", "bag", "vest", "pants", "shoes", "hat"} },
    { x = -1337.459351, y = -1277.657104, z = 4.064502, blips = true, BlipsName = "Cửa hàng mặt nạ", blipsid = 362, blipcolor = 0, category = { "mask" } }

}

Config.ShowNotificationHelpMessage = "Nhấn ~INPUT_CONTEXT~ để thay đổi trang phục"

Config.DrawMarker = {
    draw = true,
    scale = 1.1,
    color = { r = 255, g = 0, b = 0, a = 100 },
    type = 27,
    bobUpAndDown = false,
    faceCamera = false,
    rotate = false,
}

Config.Blips = {
    scale = 0.7,
    shortRange = true,
}

Config.WeightBag = 0
Config.WeightBagIndex = { 40, 41, 44, 45 }

Config.Notification = {
    ['notenoughtmoney'] = "Bạn không có đủ 💵",
    ['cannotechange'] = "Bạn không thể trao đổi quần áo từ hoặc đến các vị trí này",
    ['cannotcarry'] = "Bạn không thể mang vật phẩm này",
    ['othersex'] = "Bạn không thể sao chép trang phục của giới tính khác",
    ['reservedto'] = "Vị trí này được dành riêng cho ",
    ['outfitnamelength'] = "Tên trang phục phải có ít nhất 3 ký tự",
    ['outfitnameexists'] = "Tên này đã tồn tại",
    ['outfitsaved'] = "Trang phục đã được lưu thành công",
    ['outfitdeleted'] = "Trang phục đã được xóa thành công",
    ['outfitnotfound'] = "Không tìm thấy trang phục",
    ['outfitexported'] = "Trang phục đã được xuất thành công",
    ['outfitexporterror'] = "Lỗi khi xuất trang phục",
    ['outfitequipped'] = "Bạn đã trang bị trang phục thành công",
    ['priceupdated'] = "Giá đã được cập nhật thành công"
}

-- LISTE DES COMPOSANTS DE VÊTEMENTS
-- ================================

-- PROPS (Accessoires)
-- 0 = Chapeau / Hat
-- 1 = Masque / Mask
-- 2 = Boucles d'oreilles / Earrings
-- 6 = Montre / Watch
-- 7 = Bracelets / Vòng tay

-- NON-PROPS (Vêtements)
-- 1 = Masque / Mask
-- 3 = Gants / Gloves
-- 4 = Pantalon / Pants
-- 5 = Sac à dos / Backpack
-- 6 = Chaussures / Shoes
-- 7 = Chaîne / Chain
-- 8 = T-shirt / T-shirt
-- 9 = Gilet pare-balles / Bulletproof Vest
-- 11 = Torso (Haut du corps) / Torso (Upper body)


Config.PriceClothes = {
    ['male'] = {
        { index = { 3 }, componentNumber = 5, prop = false, price = 3000 }, -- Giá áo khoác cho nam
        --{index = {8,9,2,3,6}, componentNumber = 11, prop = false, price = 50},  -- Giá áo khoác khác cho nam
        --{index = {1,2,3}, componentNumber = 4, prop = false, price = 200},      -- Giá quần cho nam
        --{index = {10,11}, componentNumber = 6, prop = false, price = 150},      -- Giá giày cho nam
    },
    ['female'] = {
        { index = { 4 }, componentNumber = 5, prop = false, price = 3500 }, -- Giá áo khoác cho nữ
        --{index = {12,13,14}, componentNumber = 4, prop = false, price = 250},   -- Giá quần cho nữ
        --{index = {8,9}, componentNumber = 6, prop = false, price = 180},        -- Giá giày cho nữ
        --{index = {1,2}, componentNumber = 1, prop = true, price = 100},         -- Giá mũ cho nữ
    }
}

-- Mapping UI names to item names for unified config access
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

Config.DefaultPrice = {
    shirt = 1000,
    torso = 1000,
    pants = 1000,
    shoes = 1000,
    gloves = 1000,
    hat = 1000,
    glasses = 1000,
    mask = 1000,
    vest = 1000,
    bracelets = 1000,
    earrings = 1000,
    chain = 1000,
    watch = 1000,
    bag = 1000,
}

-- Giá đổi màu (texture) dựa trên độ hiếm
Config.TextureChangePrice = {
    default = 500,      -- Không có độ hiếm
    common = 1000,       -- Common (xanh lá)
    uncommon = 2000,     -- Uncommon (xanh dương)
    rare = 3000,        -- Rare (tím)
    epic = 4000,        -- Epic (vàng)
    legendary = 5000    -- Legendary (đỏ)
}

local function calculateSlot(baseSlot)
    return baseSlot
end

local minSlot = 999
local maxSlot = 0
componentMapping = {
    hat = { component = 0, prop = true, itemname = 'cloth_helmet', clothesSlotID = calculateSlot(6), camera = 'head', label = 'Mũ' },
    mask = { component = 1, prop = false, itemname = 'cloth_mask', clothesSlotID = calculateSlot(7), camera = 'head', label = 'Mặt nạ' },
    glasses = { component = 1, prop = true, itemname = 'cloth_glasses', clothesSlotID = calculateSlot(8), camera = 'head', label = 'Kính' },
    chain = { component = 7, prop = false, itemname = 'cloth_chain', clothesSlotID = calculateSlot(9), camera = 'default', label = 'Dây chuyền' },
    gloves = { component = 3, prop = false, itemname = 'cloth_arms', clothesSlotID = calculateSlot(10), camera = 'default', label = 'Găng tay' },
    torso = { component = 11, prop = false, itemname = 'cloth_torso', clothesSlotID = calculateSlot(11), camera = 'body', label = 'Áo khoác' },
    watch = { component = 6, prop = true, itemname = 'cloth_watches', clothesSlotID = calculateSlot(12), camera = 'head', label = 'Đồng hồ' },
    pants = { component = 4, prop = false, itemname = 'cloth_pants', clothesSlotID = calculateSlot(13), camera = 'pants', label = 'Quần' },
    clothes = { itemname = 'clothes', clothesSlotID = calculateSlot(14), label = "Trang phục" },
    earrings = { component = 2, prop = true, itemname = 'cloth_ears', clothesSlotID = calculateSlot(16), camera = 'head', label = 'Khuyên tai' },
    bag = { component = 5, prop = false, itemname = 'cloth_bags', clothesSlotID = calculateSlot(17), camera = 'default', label = 'Túi xách' },
    shirt = { component = 8, prop = false, itemname = 'cloth_tshirt', clothesSlotID = calculateSlot(18), camera = 'body', label = 'Áo thun' },
    vest = { component = 9, prop = false, itemname = 'cloth_bproof', clothesSlotID = calculateSlot(19), camera = 'default', label = 'Áo chống đạn' },
    bracelets = { component = 7, prop = true, itemname = 'cloth_bracelets', clothesSlotID = calculateSlot(20), camera = 'default', label = 'Vòng tay' },
    shoes = { component = 6, prop = false, itemname = 'cloth_shoes', clothesSlotID = calculateSlot(21), camera = 'bottom', label = 'Giày' },
    current_outfit = { component = -1, prop = false, itemname = 'current_outfit', clothesSlotID = nil, camera = 'default', label = 'Trang phục hiện tại', isSpecial = true }
}

for _, item in pairs(componentMapping) do
    if item.clothesSlotID then
        if item.clothesSlotID < minSlot then
            minSlot = item.clothesSlotID
        end
        if item.clothesSlotID > maxSlot then
            maxSlot = item.clothesSlotID
        end
    end
end

Config.MinClothesSlot = minSlot
Config.MaxClothesSlot = maxSlot

Config.Camera = {
    default = {
        vec3(0, 2.2, 0.2),
        vec3(0, 0, -0.05),
    },
    head = {
        vec3(0, 0.9, 0.65),
        vec3(0, 0, 0.6),
    },
    body = {
        vec3(0, 1.2, 0.2),
        vec3(0, 0, 0.2),
    },
    pants = {
        vec3(0, 1.0, 0.2),
        vec3(0, 0, -0.3),
    },
    bottom = {
        vec3(0, 0.98, -0.7),
        vec3(0, 0, -0.9),
    },
}


Config.Clothes = {
    ["shirt"] = {
        male = 15,
        female = 14,
        dict = "clothingshirt",
        anim = "try_shirt_positive_d"
    },
    ["torso"] = {
        male = 1,
        female = 2,
        dict = "clothingshirt",
        anim = "try_shirt_positive_d"
    },
    ["pants"] = {
        male = 14,
        female = 14,
        dict = "re@construction",
        anim = "out_of_breath"
    },
    ["shoes"] = {
        male = 34,
        female = 0,
        dict = "random@domestic",
        anim = "pickup_low"
    },
    ["mask"] = {
        male = 0,
        female = 0,
        dict = "misscommon@van_put_on_masks",
        anim = "put_on_mask_ps"
    },
    ["gloves"] = {
        male = 0,
        female = 0,
        dict = "nmt_3_rcm-10",
        anim = "cs_nigel_dual-10"
    },
    ["vest"] = {
        male = 0,
        female = 0,
        dict = "anim@heists@ornate_bank@grab_cash",
        anim = "intro"
    },
    ["bag"] = {
        male = 0,
        female = 0,
        dict = "anim@heists@ornate_bank@grab_cash",
        anim = "intro"
    },
    ["hat"] = {
        dict = "misscommon@van_put_on_masks",
        anim = "put_on_mask_ps"
    },
    ["glasses"] = {
        dict = "clothingspecs",
        anim = "take_off"
    },
    ["earrings"] = {
        dict = "mp_cp_stolen_tut",
        anim = "b_think"
    },
    ["watch"] = {
        dict = "nmt_3_rcm-10",
        anim = "cs_nigel_dual-10"
    },
    ["chain"] = {
        dict = "nmt_3_rcm-10",
        anim = "cs_nigel_dual-10"
    },
    ["bracelets"] = {
        dict = "nmt_3_rcm-10",
        anim = "cs_nigel_dual-10"
    },


}

Config.DefaultClothes = {
    torso = {
        components = {
            { component = 11, default_male = 15,  default_female = 3 },  -- torso
            { component = 8,  default_male = 15, default_female = 15 }  -- tshirt
        }
    },

    shirt = {
        components = {
            { component = 8, default_male = 15, default_female = 14 }
        }
    },

    pants = {
        components = {
            { component = 4, default_male = 14, default_female = 14 }
        }
    },
    shoes = {
        components = {
            { component = 6, default_male = 34, default_female = 0 }
        }
    },
    bag = {
        components = {
            { component = 5, default_male = 0, default_female = 0 }
        }
    },
    vest = {
        components = {
            { component = 9, default_male = 0, default_female = 0 }
        }
    },
    -- arms = {
    --     components = {
    --         { component = 3, default_male = 15, default_female = 15 }
    --     }
    -- },
    gloves = {
        components = {
            { component = 3, default_male = 15, default_female = 10 }
        }
    },
    mask = {
        components = {
            { component = 1, default_male = 0, default_female = 0 }
        }
    },
    hat = {
        components = {
            { component = 0, default_male = -1, default_female = -1, prop = true }
        }
    },
    glasses = {
        components = {
            { component = 1, default_male = -1, default_female = -1, prop = true }
        }
    },
    earrings = {
        components = {
            { component = 2, default_male = -1, default_female = -1, prop = true }
        }
    },
    watch = {
        components = {
            { component = 6, default_male = -1, default_female = -1, prop = true }
        }
    },
    chain = {
        components = {
            { component = 7, default_male = 0, default_female = 0 }
        }
    },
    bracelets = {
        components = {
            { component = 7, default_male = -1, default_female = -1, prop = true }
        }
    }
}

clothesComponentID = {
    1,  -- Mặt nạ
    0,  -- Mũ
    2,  -- Tai (phụ kiện)
    1,  -- Kính
    5,  -- Túi (đã chuyển đến đây)
    8,  -- Áo phông
    11, -- Quần áo trên (phần thân trên)
    9,  -- Áo chống đạn
    7,  -- Vòng tay
    6,  -- Đồng hồ
    7,  -- Dây chuyền (vòng cổ)
    4,  -- Quần
    6,  -- Giày dép
    3,  -- Cánh tay (thân hoặc các phụ kiện có thể nhìn thấy)
    14  -- Quần áo
}


clothesComponentNames = {
    "cloth_mask",      -- Mặt nạ
    "cloth_helmet",    -- Mũ
    "cloth_ears",      -- Phụ kiện tai
    "cloth_glasses",   -- Kính mắt
    "cloth_bags",      -- Túi xách
    "cloth_tshirt",    -- Áo thun
    "cloth_torso",     -- Áo khoác / phần thân trên
    "cloth_bproof",    -- Áo chống đạn
    "cloth_bracelets", -- Vòng tay
    "cloth_watches",   -- Đồng hồ
    "cloth_chain",     -- Dây chuyền
    "cloth_pants",     -- Quần dài
    "cloth_shoes",     -- Giày
    "cloth_arms",      -- Tay (phụ kiện hoặc phần thân)
    "clothes"          -- Quần áo
}


clothesSlotID = {
    calculateSlot(7),  -- Mặt nạ
    calculateSlot(6),  -- Mũ
    calculateSlot(16), -- Tai (phụ kiện)
    calculateSlot(8),  -- Kính
    calculateSlot(17), -- Balo (chuyển vào đây)
    calculateSlot(18), -- Áo thun
    calculateSlot(11), -- Áo khoác (áo trên)
    calculateSlot(19), -- Áo giáp chống đạn
    calculateSlot(20), -- Vòng tay
    calculateSlot(12), -- Đồng hồ
    calculateSlot(9),  -- Dây chuyền (vòng cổ)
    calculateSlot(13), -- Quần
    calculateSlot(21), -- Giày
    calculateSlot(10), -- Tay (phần áo hoặc phụ kiện hiển thị)
    calculateSlot(14)  -- Trang phục
}
