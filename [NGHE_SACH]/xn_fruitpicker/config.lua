Keys = {
    ['ESC'] = 322, ['F1'] = 288, ['F2'] = 289, ['F3'] = 170, ['F5'] = 166, ['F6'] = 167, ['F7'] = 168, ['F8'] = 169, ['F9'] = 56, ['F10'] = 57, ['~'] = 243, ['1'] = 157, ['2'] = 158, ['3'] = 160, ['4'] = 164, ['5'] = 165, ['6'] = 159, ['7'] = 161, ['8'] = 162, ['9'] = 163, ['-'] = 84, ['='] = 83, ['BACKSPACE'] = 177,
    ['TAB'] = 37, ['Q'] = 44, ['W'] = 32, ['E'] = 38, ['R'] = 45, ['T'] = 245, ['Y'] = 246, ['U'] = 303, ['P'] = 199, ['['] = 39, [']'] = 40, ['ENTER'] = 18,
    ['CAPS'] = 137, ['A'] = 34, ['S'] = 8, ['D'] = 9, ['F'] = 23, ['G'] = 47, ['H'] = 74, ['K'] = 311, ['L'] = 182,
    ['LEFTSHIFT'] = 21, ['Z'] = 20, ['X'] = 73, ['C'] = 26, ['V'] = 0, ['B'] = 29, ['N'] = 249, ['M'] = 244, [','] = 82, ['.'] = 81,
    ['LEFTCTRL'] = 36, ['LEFTALT'] = 19, ['SPACE'] = 22, ['RIGHTCTRL'] = 70,
    ['HOME'] = 213, ['PAGEUP'] = 10, ['PAGEDOWN'] = 11, ['DEL'] = 178,
    ['LEFT'] = 174, ['RIGHT'] = 175, ['TOP'] = 27, ['DOWN'] = 173,
}

Config = {}

Config.Debug = false -- Set to true to enable debug prints

Config.Object = {
    usingexport = true, --- Using QBX Core (evolution of QB-Core)
    CoreName = 'qbx_core', --- QBX Core resource name
    event = "QBCore:GetObject",  -- Legacy event (not used with QBX)
}

Config.UseXp = false ---- enabe/disable xp system here
Config.PedModel = 'a_m_m_farmer_01'
Config.UseDrawText = false ---- set to false if you want to use eye target.
Config.RequireJob = false --- enable this if you want to use job only.
Config.JobName = "traindriver" --- job name Note: make sure you add job in your server accordingly your framework.

Config.MinPay = 200 -- min payment on per orange sell.
Config.MaxPay = 500 -- max payment on per orange sell.

Config.UseTimeout = true ---- set to true if you want to use timeout
Config.Timeout = 90000 --- time in mili seconds (90 seconds)

Config.BasketMaxOranges = 20 -- Maximum oranges per basket
Config.BasketDurability = 100 -- Initial basket durability
Config.DurabilityPerOrange = 5 -- Durability lost per orange picked (10% per orange, basket lasts for 10 oranges)

-- Rare item drop configuration
Config.RareItemDrop = {
    enabled = true,
    itemName = "cammuoitu",
    chance = 1, -- 1% chance to drop
    weight = 5000, -- 5kg per rare orange (5000g)
}

-- Special item drop configuration (Thẻ Hái Cam)
Config.TheHaiCamDrop = {
    enabled = true,
    itemName = "the_hai_cam",
    itemLabel = "Thẻ Hái Cam",
    chance = 20, -- 20% chance per orange (1-100)
    -- 'take_from_basket': Khi lấy cam từ sọt ra túi đồ
    -- 'tree': Khi hái cam từ trên cây vào sọt
    -- 'both': Cả 2 trường hợp trên
    triggerOn = 'take_from_basket',
}

Config.Xp = {
    [1] = {
        xp = 10, ----- if player has 10 xp then
        enabletree = 10, --- enable 10 tree
    },
    [2] = {
        xp = 20,
        enabletree = 20,
    },
    [3] = {
        xp = 30,
        enabletree = 30,
    },
    [4] = {
        xp = 40,
        enabletree = 40,
    },
    [5] = {
        xp = 50,
        enabletree = 52, ----we have total 52 tree
    },

}

Config.Blip = {
    ['main_blip'] = {
        enable = true,
        coords = vector3(-807.18, 864.93, 203.15),
        Sprite = 1,
        Scale = 1.0,
        Color = 47,
        Label = '~g~[NGHỀ ĐƠN]~s~ Hái Cam'
    }
    -- ['selling'] = {
    --     enable = true,
    --     coords = vector3(1792.27, 4594.9, 37.68),
    --     heading = 188.28,
    --     Sprite = 88,
    --     Scale = 0.8,
    --     Color = 25,
    --     Label = 'Fruit Market'
    -- }
}

Config.ShopItems = { -- Food Shop
    [1] = {
        name = "fruit_basket", -- Item name
        price = 20, -- Price per item
        amount = 50, -- Stock amount
        info = {},
        type = "item",
        slot = 1, -- Inventory slot item will be displayed
    },
}

InsertValue = function(title, text, name)
    local input = lib.inputDialog(title, {
        {
            type = 'number',
            label = text,
            description = Language['submit'],
            required = true,
            min = 1
        }
    })

    if input then
        return input[1]
    end
    return nil
end


AddTargets = function(targettype, v)
    if targettype == 'fruittree' then
        if Config.Debug then
            print("^2[DEBUG] Adding fruit tree target:^7", v.name, "at", v.coords)
        end
        local zoneId = exports.ox_target:addSphereZone({
            coords = v.coords,
            radius = 1.0,
            debug = false,
            drawSprite = true,
            options = {
                {
                    name = v.name,
                    icon = "fas fa-tree",
                    label = "Hái Cam",
                    onSelect = function()
                        if Config.Debug then
                            print("^2[DEBUG] Target selected:^7", v.name)
                        end
                        TriggerEvent("xn-fruitpicker:stealorange", v)
                    end
                }
            }
        })
        if Config.Debug then
            print("^2[DEBUG] Zone ID:^7", zoneId)
        end
    elseif targettype == "orange" then
        exports.ox_target:addModel({`orange`, `prop_fruit_basket`}, {
            {
                name = "pickup_fruit",
                icon = "fas fa-hand-holding",
                label = "Nhặt cam",
                onSelect = function()
                    TriggerEvent("xn-fruitpicker:pickupfruit")
                end
            }
        })
    end
end


Config.FruitLoc = {
    [1] = vector3(0.14, -0.1, -0.2),
    [2] = vector3(0.05, -0.1, -0.2),
    [3] = vector3(-0.05, -0.1, -0.2),
    [4] = vector3(-0.14, -0.1, -0.2),
    [5] = vector3(0.14, 0.0, -0.2),
    [6] = vector3(0.05, 0.0, -0.2),
    [7] = vector3(-0.05, 0.0, -0.2),
    [8] = vector3(-0.14, 0.0, -0.2),
    [9] = vector3(0.14, 0.1, -0.2),
    [10] = vector3(0.05, 0.1, -0.2),
    [11] = vector3(-0.05, 0.1, -0.2),
    [12] = vector3(-0.14, 0.1, -0.2),
    [13] = vector3(0.11, -0.05, -0.1),
    [14] = vector3(0.0, -0.05, -0.1),
    [15] = vector3(-0.11, -0.05, -0.1),
    [16] = vector3(0.11, 0.05, -0.1),
    [17] = vector3(0.0, 0.05, -0.1),
    [18] = vector3(-0.11, 0.05, -0.1),
    [19] = vector3(0.05, 0.0, -0.02),
    [20] = vector3(-0.05, 0.0, -0.02),
}

Config.Orange = {
    [1] = vector3(-866.5, 838.68, 202.87),
    [2] = vector3(-867.58, 847.61, 202.86),
    [3] = vector3(-863.99, 856.73, 202.87),
    [4] = vector3(-857.87, 866.47, 202.88),
    [5] = vector3(-847.55, 865.15, 202.89),
    [6] = vector3(-842.27, 876.66, 202.9),
    [7] = vector3(-832.35, 879.74, 202.9),
    [8] = vector3(-829.11, 869.29, 202.93),
    [9] = vector3(-831.09, 860.03, 202.89),
    [10] = vector3(-838.28, 852.29, 202.89),
    [11] = vector3(-835.66, 845.3, 202.86),
    [12] = vector3(-826.26, 846.33, 202.89),
    [13] = vector3(-825.03, 857.22, 202.9),
    [14] = vector3(-837.78, 869.54, 202.89),
    [15] = vector3(-852.83, 855.86, 203.06),
    [16] = vector3(-850.99, 842.99, 202.87),
    [17] = vector3(-817.09, 849.47, 203.05),
    [18] = vector3(-811.98, 860.89, 203.13),
    [19] = vector3(-820.93, 865.06, 202.96),
    [20] = vector3(-820.62, 874.06, 203.1),
    [21] = vector3(-816.84, 881.87, 203.18),
    [22] = vector3(-808.84, 852.46, 203.37),
    [23] = vector3(-810.9, 868.89, 203.15),
    [24] = vector3(-806.65, 878.52, 203.18),
    [25] = vector3(-808.8, 887.36, 203.18),
    [26] = vector3(-817.6, 856.42, 203.01),
    [27] = vector3(-797.67, 877.66, 203.15),
    [28] = vector3(-802.14, 869.63, 203.15),
    [29] = vector3(-802.34, 861.68, 203.21),
    [30] = vector3(-800.79, 854.87, 203.48),
    [31] = vector3(-808.71, 845.32, 203.44),
    [32] = vector3(-824.76, 881.99, 203.15),
    [33] = vector3(-841.42, 858.96, 202.89),
    [34] = vector3(-843.25, 846.63, 202.88),
    [35] = vector3(-794.77, 847.81, 204.41),
    [36] = vector3(-794.77, 859.01, 203.25),
    [37] = vector3(-793.58, 869.49, 203.16),
    [38] = vector3(-788.73, 876.33, 203.15),
    [39] = vector3(-791.31, 884.17, 203.22),
    [40] = vector3(-784.14, 881.49, 203.18),
    [41] = vector3(-777.45, 871.35, 203.24),
    [42] = vector3(-785.61, 865.41, 203.2),
    [43] = vector3(-787.22, 852.7, 204.64),
    [44] = vector3(-785.92, 890.58, 203.23),
    [45] = vector3(-798.13, 893.55, 203.54),
}
