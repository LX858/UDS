Config = Config or {}

-- Keymapping tên item sang nhãn hiển thị trong UI
Config.TradeShopItemLabels = {
    ["manhtatto_s"] = "Thẻ tattoo",
    ["manhtatto_a"] = "Thẻ tattoo Premium",
    ["manhtatto_b"] = "Thẻ tattoo Classic"
}

Config.TradeShop = {
    Coords = vec3(322.7420, 181.0918, 103.5865),
    BlipsName = "Cửa hàng Tattoo",
    BlipsId = 75,
    BlipColor = 1,
    Category = { "gloves", "pants" },
    DrawText = "Mở cửa hàng Tattoo",
    RefundRate = 0.5,           -- 50% số thẻ nhận lại khi quy đổi ngược
    RefundItem = "manhtatto_s", -- Tên item thẻ nhận lại khi quy đổi ngược
    
    AllowedDrawables = {
        gloves = {
            male = { 228, 237, 245, 248, 270, 272, 273, 274, 275, 276, 278, 279, 280, 229, 231, 232, 233, 234, 266,
            281, 244, 246, 268, 269, 235, 236, 247, 249, 251, 255, 258, 259, 261, 262, 263, 264, 265, 277, 282, 283, 284 },
            female = { 266, 271, 272, 273, 275, 276, 277, 278, 279, 280, 281, 282 }
        },
        pants = {
            male = {316, 317, 361, 632, 363, 364, 365},
            female = {288, 289, 295, 296}
        }
    },

    -- Cấu hình đổi vật phẩm ở phía Server và Client
    Items = {
        gloves = {
            male = {
                [225] = { rarity = "rare", item = "manhtatto_s", count = 200 },
                [228] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [237] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [245] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [248] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [270] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [272] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [273] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [274] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [275] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [276] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [278] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [279] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [280] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [229] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [231] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [232] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [234] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [233] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [281] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [244] = { rarity = "rare", item = "manhtatto_s", count = 100 },
                [246] = { rarity = "rare", item = "manhtatto_s", count = 100 },
                [219] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [254] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [260] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [269] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [266] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [268] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [269] = { rarity = "legendary", item = "manhtatto_s", count = 300 },

                [235] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [236] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [247] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [249] = { rarity = "epic", item = "manhtatto_s", count = 200 }, 
                [251] = { rarity = "legendary", item = "manhtatto_s", count = 250 },
                [255] = { rarity = "rare", item = "manhtatto_s", count = 100 },
                [258] = { rarity = "rare", item = "manhtatto_s", count = 100 },
                [259] = { rarity = "rare", item = "manhtatto_s", count = 100 },
                [261] = { rarity = "legendary", item = "manhtatto_s", count = 250 },
                [262] = { rarity = "legendary", item = "manhtatto_s", count = 250 },
                [263] = { rarity = "legendary", item = "manhtatto_s", count = 250 },
                [264] = { rarity = "legendary", item = "manhtatto_s", count = 250 },
                [265] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [277] = { rarity = "rare", item = "manhtatto_s", count = 150 },
                [282] = { rarity = "legendary", item = "manhtatto_s", count = 250 },
                [283] = { rarity = "legendary", item = "manhtatto_s", count = 250 },
                [284] = { rarity = "legendary", item = "manhtatto_s", count = 250 }

            },
            female = {
                [266] = { rarity = "rare", item = "manhtatto_s", count = 100 },
                [271] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [272] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [273] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [275] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [276] = { rarity = "epic", item = "manhtatto_s", count = 250 },
                [277] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [278] = { rarity = "legendary", item = "manhtatto_s", count = 300 },
                [279] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [280] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [281] = { rarity = "epic", item = "manhtatto_s", count = 200 },
                [282] = { rarity = "legendary", item = "manhtatto_s", count = 300 }
            }
        },
        pants = {
            male = {
               [316] = { rarity = "epic", item = "manhtatto_s", count = 100 },
               [317] = { rarity = "epic", item = "manhtatto_s", count = 100 },
               [361] = { rarity = "epic", item = "manhtatto_s", count = 200 },
               [362] = { rarity = "epic", item = "manhtatto_s", count = 200 },
               [363] = { rarity = "epic", item = "manhtatto_s", count = 200 },
               [364] = { rarity = "epic", item = "manhtatto_s", count = 200 },
               [365] = { rarity = "epic", item = "manhtatto_s", count = 200 }
            },
            female = {
                [288] = { rarity = "epic", item = "manhtatto_s", count = 100 },
                [289] = { rarity = "epic", item = "manhtatto_s", count = 100 },
                [295] = { rarity = "epic", item = "manhtatto_s", count = 100 },
                [296] = { rarity = "epic", item = "manhtatto_s", count = 100 }
            }
        }
    }
}
