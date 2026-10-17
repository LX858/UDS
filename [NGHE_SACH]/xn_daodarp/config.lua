Config = {}

-- Rock spawn locations
Config.RockLocations = {
    vector3(2954.1692, 2786.8306, 41.4692),
    vector3(2942.7913, 2786.4353, 39.9313),
    vector3(2943.7139, 2778.7959, 39.3459),
    vector3(2946.87, 2793.99, 40.63),
    vector3(2964.24, 2792.84, 40.47),
    vector3(2934.19, 2791.61, 40.29)
}
-- Rock processing locations (multiple locations)
Config.ProcessingLocations = {
    {coords = vector3(2952.97, 2745.72, 43.45), heading = 195.72},
    {coords = vector3(2958.09, 2746.45, 43.49), heading = 195.72},
    {coords = vector3(2961.34, 2747.71, 43.4), heading = 195.72},
    {coords = vector3(2965.48, 2749.16, 43.28), heading = 195.72},
    {coords = vector3(2963.32, 2747.98, 43.36), heading = 195.72}
}

-- Processing prop settings
Config.ProcessingProp = {
    model = 'prop_bandsaw_01',
    spawnOffset = vector3(0.0, 0.0, 0.0) -- Offset from processing location
}

-- Rock settings
Config.RockModel = 'prop_rock_3_f'
Config.RockRespawnTime = 60000 -- 5 seconds for testing

Config.InteractionDistance = 3.0
Config.HideTextDistance = 5.0

-- Animation settings
Config.Animation = {
    dict = "amb@world_human_const_drill@male@drill@base",
    anim = "base",
    flag = 1
}

-- Carrying rock animation settings
Config.CarryingAnimation = {
    dict = "anim@heists@box_carry@",
    anim = "idle",
    flag = 49, -- Loop animation
    movementClipset = "anim@heists@box_carry@"
}

-- Drill prop settings for ox_lib progressBar
Config.Prop = {
    bone = 28422, -- Right hand bone
    model = 'hei_prop_heist_drill',
}

-- Prop placement configuration for drill (positioned for downward drilling)
-- Format: {X pos, Y pos, Z pos, X rotation, Y rotation, Z rotation}
Config.PropMapPlacement = {0.0, 0.0, 0.0, 90.0, 0.0, 90.0}

-- Processing animation settings
Config.ProcessingAnimation = {
    dict = "amb@prop_human_bum_shopping_cart@male@idle_a",
    anim = "idle_c",
    flag = 1
}

-- Processing prop settings (for cutting animation with ox_lib progressBar)
Config.ProcessingHandProp = {
    model = 'bzzz_prop_mine_iron_b', -- Temporary prop, will replace with better cutting tool
    bone = 28422, -- Right hand
    pos = vector3(0.0, 0.0, 0.0),
    rot = vector3(0.0, 0.0, 0.0)
}


-- New carrying rock placement (box carry style)
Config.CarryingRockPlacement = {
    pos = vector3(0.0, 0.0, 0.0),
    rot = vector3(0.0, 0.0, 0.0),
    bone = 28422, -- Right hand bone
    model = "bzzz_prop_mine_iron_b" -- Use beer log model instead of rock
}

-- Items
Config.RewardItem = 'ls_coal_ore'
Config.RewardAmount = 1

-- Required item to mine
Config.RequiredItem = 'may_khoan_da' -- Drill item name
Config.DurabilityLoss = 5 -- 5% durability loss per mining

-- Item Labels Configuration
Config.ItemLabels = {
    -- Mining Items
    ['ls_coal_ore'] = 'Than đá thô',
    ['may_khoan_da'] = 'Máy khoan đá',
    ['stones'] = 'Đá thô',
    
    -- Smelting Rewards
    ['ls_iron_ingot'] = 'Thỏi sắt',
    ['ls_copper_ingot'] = 'Thỏi đồng',
    ['carbon'] = 'Carbon',
    
    -- Gems
    ['ngoc_luc_bao_tho'] = 'Ngọc lục bảo thô',
    ['ngoc_luc_bao_tinh_khiet'] = 'Ngọc lục bảo tinh khiết',
    ['ngoc_ruby'] = 'Ngọc ruby',
    ['hoang_thach_tho'] = 'Hoàng thạch thô',
    
    -- Upgrade Stones
    ['da_cuong_hoa_vk'] = 'Đá cường hóa vũ khí',
    ['da_cuong_hoa_balo'] = 'Đá cường hóa balo',
    ['da_che_tao'] = 'Đá chế tạo',
    ['da_che_tao_2'] = 'Đá chế tạo bậc 2',
    
    -- Props/Models (for reference)
    ['bzzz_prop_mine_iron_b'] = 'Khối quặng sắt',
    ['prop_rock_3_f'] = 'Tảng đá lớn',
    ['prop_bandsaw_01'] = 'Máy cắt đá',
    ['hei_prop_heist_drill'] = 'Máy khoan'
}

-- Helper function to get item label
function Config.GetItemLabel(itemName)
    return Config.ItemLabels[itemName] or itemName
end

-- Helper function to check if player is in vehicle
function Config.IsPlayerInVehicle()
    local ped = PlayerPedId()
    return IsPedInAnyVehicle(ped, false)
end

-- Mining settings
Config.MiningTime = math.random(10000, 15000) -- 5 seconds in milliseconds

-- Carrying rock restrictions
Config.DisableControlsWhileCarrying = true -- Enable/disable control restrictions
Config.AggressiveProtection = true -- Enable aggressive animation protection (temporarily disable controls to force animation)
Config.DisabledControls = {
    0, -- Next camera
    1, -- Look left/right
    2, -- Look up/down
    3, -- Move left/right
    4, -- Move forward/backward
    5, -- Move up/down
    6, -- Move left/right (alternative)
    18, -- Enter/Exit/Secondary attack
    19, -- Alt key (hands up alternative)
    21, -- Sprint
    22, -- Jump
    23, -- Enter vehicle
    24, -- Attack
    25, -- Aim
    26, -- Look behind
    27, -- Phone
    29, -- Special ability (B)
    36, -- Duck/Crouch
    37, -- Weapon wheel (select)
    44, -- Cover
    45, -- Reload
    47, -- Weapon wheel
    50, -- Weapon wheel (prev)
    51, -- Weapon wheel (next)
    52, -- Weapon wheel (left)
    53, -- Weapon wheel (right)
    54, -- Weapon wheel (up)
    55, -- Weapon wheel (down)
    56, -- Weapon wheel (confirm)
    57, -- Weapon wheel (cancel)
    58, -- Weapon wheel (X axis)
    59, -- Weapon wheel (Y axis)
    73, -- Map
    74, -- Character wheel
    75, -- Character wheel (confirm)
    76, -- Character wheel (cancel)
    140, -- Melee attack (light)
    141, -- Melee attack (heavy)
    142, -- Melee attack (alternate)
    143, -- Melee block
    157, -- Select/Accept (Enter)
    158, -- Cancel (Backspace)
    167, -- Phone
    168, -- Phone (cancel)
    169, -- Phone (confirm)
    170, -- Interaction menu
    177, -- Cancel emote/action (X key)
    178, -- Emote/quick action
    194, -- Secondary cancel
    199, -- Pause menu
    200, -- Pause menu (confirm)
    201, -- Pause menu (cancel)
    202, -- Pause menu (ESC)
    257, -- Attack 2
    263, -- Melee attack (Y)
    264, -- Melee attack (B)
    289, -- Melee (Y)
    322, -- ESC (Pause Menu)
    323, -- X key / Hands up
    326, -- Scroll wheel
}

-- Hands up animations to block while carrying
Config.BlockedHandsUpAnimations = {
    {dict = "random@mugging3", anim = "handsup_standing_base"},
    {dict = "missminuteman_1ig_2", anim = "handsup_base"},
    {dict = "mp_arresting", anim = "idle"},
    {dict = "random@arrests@busted", anim = "idle_a"},
}

-- Notification settings
Config.Notifications = {
    success = 'success',
    error = 'error',
    info = 'inform'
}

-- Blip settings
Config.Blips = {
    Mining = {
        enabled = true,
        coords = vector3(2954.16, 2786.83, 41.46),
        sprite = 618, -- Mine icon
        color = 5, -- Yellow
        scale = 0.8,
        label = 'Khai thác đá'
    },
    Cutting = {
        enabled = true,
        coords = vector3(2952.97, 2745.72, 43.45),
        sprite = 365, -- Saw icon
        color = 47, -- Orange/Yellow
        scale = 0.8,
        label = 'Sẻ đá'
    },
    Smelting = {
        enabled = true,
        coords = vector3(1110.54, -2008.49, 31.83),
        sprite = 436, -- Furnace icon
        color = 6, -- Purple
        scale = 0.8,
        label = 'Nung đá'
    },
    DrillShop = {
        enabled = true,
        coords = vector3(2944.26, 2746.50, 43.36),
        sprite = 521, -- Shop/Store icon
        color = 25, -- Green
        scale = 0.8,
        label = 'Cửa hàng máy khoan'
    }
}

-- NPC shop settings
Config.ShopNPC = {
    enabled = true,
    model = 's_m_m_dockwork_01', -- Ped model (Miner)
    coords = vector4(2944.2607, 2746.5012, 43.3697, 291.7460), -- vec4 position
    price = 500, -- Price of the may_khoan_da (drill) in $
    label = 'Mua Máy Khoan Đá',
    icon = 'fas fa-shopping-cart',
    distance = 2.0
}

-- Smelting settings
Config.Smelting = {
    location = vector3(1110.54, -2008.49, 31.83),
    interactionDistance = 3.0,
    duration = 8000, -- thoi gian rua da
    requiredItem = 'ls_coal_ore',
    requiredAmount = 1,
    animation = {
        dict = "amb@world_human_bum_wash@male@low@idle_a",
        anim = "idle_a",
        flag = 1
    }
}

-- Smelting rewards with chances (must total 100%)
Config.SmeltingRewards = {
    {item = "ls_iron_ingot", chance = 50, name = "Thỏi sắt"},
    {item = "ls_copper_ingot", chance = 30, name = "Thỏi đồng"},
    {item = "ls_silver_ingot", chance = 15, name = "Thỏi Bạc"},
    {item = "carbon", chance = 4, name = "carbon"},
    {item = "the_dao_da", chance = 1, name = "Thẻ đào đá"},
}

-- Smelting UI Text
Config.SmeltingText = {
    interaction = 'Nung đá',
    progressLabel = 'Đang nung đá...',
    successTitle = 'Nung đá thành công',
    noReward = 'Không có gì được tìm thấy...',
    cancelTitle = 'Nung đá',
    cancelDesc = 'Đã hủy việc nung đá!',
    noJob = 'Bạn không có nghề phù hợp để nung đá!',
    needMiner = 'Bạn cần nghề Thợ mỏ để nung đá',
    noStones = 'Bạn cần có ít nhất 1 than đá thô để nung!',
    menuTitle = 'Lò nung',
    menuSubtitle = 'Chọn loại nung',
    regularSmelt = 'Nung đá thường',
    gemSmelt = 'Nung ngọc quý',
    gemMenuTitle = 'Nung ngọc quý',
    gemMenuSubtitle = 'Chọn loại ngọc cần nung',
    backButton = '← Quay lại',
    noGem = 'Bạn không có ngọc này!'
}

-- Gem smelting configuration
Config.GemSmelting = {
    duration = 10000, -- 10 seconds for gem smelting
    animation = {
        dict = "amb@world_human_bum_wash@male@low@idle_a",
        anim = "idle_a",
        flag = 1
    },
    gems = {
        {
            item = "ngoc_luc_bao_tho",
            name = "Ngọc lục bảo thô",
            rewards = {
                {item = "da_cuong_hoa_vk", chance = 100, name = "Đá cường hóa vũ khí"}
            }
        },
        {
            item = "ngoc_luc_bao_tinh_khiet",
            name = "Ngọc lục bảo tinh khiết",
            rewards = {
                {item = "da_cuong_hoa_balo", chance = 100, name = "Đá cường hóa Balo"}
            }
        },
        {
            item = "ngoc_ruby",
            name = "Ngọc ruby",
            rewards = {
                {item = "da_che_tao", chance = 100, name = "Đá chế tạo"}
            }
        },
        {
            item = "hoang_thach_tho",
            name = "Hoàng thạch thô",
            rewards = {
                {item = "da_che_tao_2", chance = 100, name = "Đá chế bậc 2"}
            }
        }
    }
}
