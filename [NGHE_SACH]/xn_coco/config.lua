Config = {
    Reward = 1, --Coconut Reward Amount
    Blip = true,
    RewardItemName = "coconut", -- Coconut Item Name (Trái dừa thông thường - 99% cơ hội nhận được)
    ItemRequire = true, -- Item require to pickup coconut
    ItemRequireName = "keo", -- Name of Item require to pickup coconut
    PickingProgressbarTime = 15000, --Time to pickup (progressbar)
    UsingMinigameToPickup = false, --Using minigame to pickup (disabled)
    
    -- Rare Drop Configuration - 100% nhận trái
    -- Dừa thông thường (coconut): 99%
    -- Dừa lòng (dua_long): 1%
    RareDrops = {
        enabled = true,
        rareItemName = "co_bon_la_5", -- Tên vật phẩm dừa lòng (trái hiếm 1%)
        rareItemLabel = "Cỏ Bốn Lá 5",
        rareChance = 20, -- Tỉ lệ: 1% (còn lại 99% nhận coconut)
        rareAmount = 1 -- Số lượng
    },
    
    -- Event Special Reward (Phần thưởng đặc biệt)
    Event = {
        enabled = false, -- Bật/tắt hệ thống phần thưởng đặc biệt
        chance = 10, -- Tỉ lệ % ra phần thưởng đặc biệt (10 = 10%)
        rewards = {
            {item = "money", chance = 100}  -- 25% nhận manhghep5 (100% tích lũy)
        }
    },
    
    -- NPC Shop Configuration
    NPCShop = {
        enabled = true,
        location = vector4(-1855.54, -644.1, 10.78, 157.37),
        model = "a_m_m_beach_01", -- NPC model
        blip = {
            enabled = true,
            sprite = 52,
            color = 3,
            scale = 0.8,
            name = "Cửa hàng dụng cụ"
        },
        items = {
            {
                name = "keo",
                label = "Kéo hái dừa",
                price = 50,
                description = "Dụng cụ để hái dừa từ cây"
            }
        }
    },
    
    SpawnTrees = { -- Palm Trees Spawn Locations
        vector4(-1850.456, -657.1502, 10.175859, 0.0003746),
        vector4(-1859.478, -649.929, 10.249967, 0.0003244),
        vector4(-1841.327, -664.9401, 10.175312, 0.0003493),
        vector4(-1832.183, -672.5061, 10.204788, 0.0003604),
        vector4(-1840.729, -673.627, 10.176979, 0.0003427),
        vector4(-1849.31, -666.369, 10.175546, 359.99966),
        vector4(-1858.909, -658.1519, 10.142694, 0.0003749),
        vector4(-1863.1055, -654.6390, 10.8885, 340.0747),
        vector4(-1867.3439, -659.6735, 10.5652, 312.8606),
        vector4(-1862.7589, -662.4703, 10.5327, 309.5783),
        vector4(-1854.6233, -662.2737, 10.7029, 313.1484),
        vector4(-1857.6436, -666.5005, 10.4539, 310.1026),
        vector4(-1852.6143, -670.8472, 10.3645, 322.5179),
        vector4(-1844.1686, -677.9730, 10.2149, 301.8828),
        vector4(-1839.7063, -682.0706, 10.1336, 229.9733),
        vector4(-1834.9226, -678.3370, 10.3538, 56.4766)
    },
    Locations =  {
        ['Blips'] = { name = "~g~[NGHỀ ĐƠN]~s~ Hái dừa", coords = vector4(-1850.456, -657.1502, 19.175859, 0.0003746), sprite = 836, col = 5, size = 0.9, display = 6, blipTrue = true},
    },
    MaxLimit = 3, -- Amount limit in one SpawnTrees
    TimeCanPick = 140, -- Cooldown time Limit (Seconds)
    TargetPickIcon = "fa fa-lemon",
    Debug = false,
}

Languages = {
    Picking = "Hái dừa",
    ProgressPicking = "Đang hái dừa...",
    Wait = "Cây dừa này đã hết trái, vui lòng đợi ",
    Second = " giây",
    LoseMinigame = "Bạn cần tập trung, thử lại!",
    
    -- NPC Shop Languages
    ShopTitle = "Cửa hàng dụng cụ",
    ShopDescription = "Mua các dụng cụ cần thiết để hái dừa",
    BuyItem = "Mua",
    EnterQuantity = "Nhập số lượng",
    QuantityLabel = "Số lượng",
    NotEnoughMoney = "Bạn không có đủ tiền!",
    PurchaseSuccess = "Bạn đã mua thành công!",
    InvalidQuantity = "Số lượng không hợp lệ!",
}