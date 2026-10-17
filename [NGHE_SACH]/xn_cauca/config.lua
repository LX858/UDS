Config = {}

-- Debug mode
Config.Debug = false

-- Framework Configuration
Config.Framework = "QBCore" -- Framework being used (QBCore)
Config.UseOxInventory = true -- Set to true if using ox_inventory
Config.UseOxLib = true -- Set to true if using ox_lib for notifications and skillchecks

-- XP System Configuration
Config.EnableXPSystem = true -- Set to false to disable XP requirements and rewards entirely

-- Level System Configuration - XP required for each level
Config.RequiredXP = {
    [1] = 0,        -- Level 1 bắt đầu từ 0 XP
    [2] = 600,      -- Level 2 cần 600 XP
    [3] = 700,      -- Level 3 cần 700 XP
    [4] = 900,      -- Level 4 cần 900 XP
    [5] = 1400,     -- Level 5 cần 1400 XP
    [6] = 2000,     -- Level 6 cần 2000 XP
    [7] = 2700,     -- Level 7 cần 2700 XP
    [8] = 3500,     -- Level 8 cần 3500 XP
    [9] = 4400,     -- Level 9 cần 4400 XP
    [10] = 5400,    -- Level 10 cần 5400 XP

    [11] = 6500,    -- Level 11 cần 6500 XP
    [12] = 7700,    -- Level 12 cần 7700 XP
    [13] = 9000,    -- Level 13 cần 9000 XP
    [14] = 10400,   -- Level 14 cần 10400 XP
    [15] = 11900,   -- Level 15 cần 11900 XP
    [16] = 13500,   -- Level 16 cần 13500 XP
    [17] = 15200,   -- Level 17 cần 15200 XP
    [18] = 17000,   -- Level 18 cần 17000 XP
    [19] = 18900,   -- Level 19 cần 18900 XP
    [20] = 20900,   -- Level 20 cần 20900 XP

    [21] = 22400,   -- Level 21 cần 22400 XP
    [22] = 24000,   -- Level 22 cần 24000 XP
    [23] = 25700,   -- Level 23 cần 25700 XP
    [24] = 27500,   -- Level 24 cần 27500 XP
    [25] = 29400,   -- Level 25 cần 29400 XP
    [26] = 31400,   -- Level 26 cần 31400 XP
    [27] = 33500,   -- Level 27 cần 33500 XP
    [28] = 35700,   -- Level 28 cần 35700 XP
    [29] = 38000,   -- Level 29 cần 38000 XP
    [30] = 40400,   -- Level 30 cần 40400 XP

    [31] = 42900,   -- Level 31 cần 42900 XP
    [32] = 45500,   -- Level 32 cần 45500 XP
    [33] = 48200,   -- Level 33 cần 48200 XP
    [34] = 51000,   -- Level 34 cần 51000 XP
    [35] = 53900,   -- Level 35 cần 53900 XP
    [36] = 56900,   -- Level 36 cần 56900 XP
    [37] = 60000,   -- Level 37 cần 60000 XP
    [38] = 63200,   -- Level 38 cần 63200 XP
    [39] = 66500,   -- Level 39 cần 66500 XP
    [40] = 69900,   -- Level 40 cần 69900 XP

    [41] = 73400,   -- Level 41 cần 73400 XP
    [42] = 77000,   -- Level 42 cần 77000 XP
    [43] = 80700,   -- Level 43 cần 80700 XP
    [44] = 84500,   -- Level 44 cần 84500 XP
    [45] = 88400,   -- Level 45 cần 88400 XP
    [46] = 92400,   -- Level 46 cần 92400 XP
    [47] = 96500,   -- Level 47 cần 96500 XP
    [48] = 100700,  -- Level 48 cần 100700 XP
    [49] = 105000,  -- Level 49 cần 105000 XP
    [50] = 109400   -- Level 50 cần 109400 XP - max level
}

-- Maximum level
Config.MaxLevel = 20

-- Water Detection Settings (Simplified)
Config.WaterDetection = {
    enabled = true,        -- Set to false for basic water detection only
    checkRadius = 5.0      -- Radius to check around player (simplified)
}

-- Fishing zones configuration
Config.FishingZones = {
    {
        name = "beginner_zone", ---câu cá bình thường (Level 1+)
        Label = "Khu câu cá mới bắt đầu",
        coords = vector3(1685.64, 40.05, 161.77),
        radius = 100.0,
        requiredXP = 0, -- Level 1 (0 XP)
        maxXP = 999999,
        fish = {"tramco", "rophi", "cachep"},
        fishRates = {
            ["tramco"] = 55,
            ["rophi"] = 30,
            ["cachep"] = 20
        },
        specialReward = {
            item = "the_cau_ca",
            label = "Thẻ Câu Cá",
            chance = 10, -- 10% tỷ lệ nhận được
            amount = 1
        },
        allowedRods = {
            "fishingrod1",      -- Basic wooden rod
            "fishingrod2",    -- Steel rod  
            "fishingrod3",  -- Carbon rod
            "fishingrod4",   -- Titanium rod
            "fishingrod5"      -- VIP rod
        }
    },

    {
        name = "intermediate_zone", ---câu cá trung cấp (Level 5+)
        Label = "Khu câu cá trung cấp",
        coords = vector3(718.95, 3913.64, 31.46),
        radius = 100.0,
        requiredXP = 700, -- Level 5 (700 XP)
        maxXP = 999999,
        fish = {"rophi", "cachep", "ca_chim", "ca_hoi"},
        fishRates = {
            ["rophi"] = 40,
            ["cachep"] = 20,
            ["ca_chim"] = 15,
            ["ca_hoi"] = 10
        },
        specialReward = {
            item = "the_cau_ca",
            label = "Thẻ Câu Cá",
            chance = 20, -- 20% tỷ lệ nhận được
            amount = 1
        },
        allowedRods = {
            "fishingrod2",    -- Steel rod  
            "fishingrod3",  -- Carbon rod
            "fishingrod4",   -- Titanium rod
            "fishingrod5"      -- VIP rod
        }
    },

    {
        name = "advanced_zone", -- câu cá cao cấp (Level 10+) 
        Label = "Khu câu cá cao cấp",
        coords = vector3(-2156.2202, -1855.3816, 1.9948),
        radius = 100.0,
        requiredXP = 2700, -- Level 10 (2700 XP)
        maxXP = 999999,
        fish = {"ca_thu", "tom_hum", "ca_ngu", "shark"},
        fishRates = {
            ["ca_thu"] = 40,
            ["tom_hum"] = 30,
            ["ca_ngu"] = 20,
            ["shark"] = 3
        },
        specialReward = {
            item = "the_cau_ca",
            label = "Thẻ Câu Cá",
            chance = 30, -- 30% tỷ lệ nhận được
            amount = 1
        },
        allowedRods = {
            "fishingrod4",   -- Titanium rod
            "fishingrod5"      -- VIP rod
        },
        allowedHours = {
            { start = 3, ["end"] = 5 },
            { start = 20, ["end"] = 22 },
            { start = 14, ["end"] = 16 }
        }
    }
}

-- Helper function to check if current hour is within allowed ranges
function Config.IsTimeAllowed(allowedHours, currentHour)
    if not allowedHours then return true end
    
    -- Support single range configuration
    if allowedHours.start and allowedHours["end"] then
        local startH = allowedHours.start
        local endH = allowedHours["end"]
        if startH <= endH then
            return currentHour >= startH and currentHour <= endH
        else
            return currentHour >= startH or currentHour <= endH
        end
    end
    
    -- Support multiple ranges configuration
    for _, range in ipairs(allowedHours) do
        local startH = range.start
        local endH = range["end"]
        if startH and endH then
            if startH <= endH then
                if currentHour >= startH and currentHour <= endH then
                    return true
                end
            else
                if currentHour >= startH or currentHour <= endH then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Helper function to format allowed hours string for notifications/UI
function Config.GetAllowedHoursString(allowedHours)
    if not allowedHours then return "" end
    
    if allowedHours.start and allowedHours["end"] then
        return string.format("%02d:00 - %02d:00", allowedHours.start, allowedHours["end"])
    end
    
    local parts = {}
    for _, range in ipairs(allowedHours) do
        if range.start and range["end"] then
            table.insert(parts, string.format("%02d:00 - %02d:00", range.start, range["end"]))
        end
    end
    
    return table.concat(parts, ", ")
end

-- Fish configuration with individual minigame settings
Config.FishSettings = {

    ["tramco"] = {
        name = "Cá Trắm cỏ",
        difficulty = "easy",
        rarity = "common",
        xpReward = 5
    },

    ["cachep"] = {
        name = "Cá Chép hồ",
        difficulty = "medium",
        rarity = "uncommon",
        xpReward = 10
    },
    
    -- Intermediate fish (Level 5+ Zone)
    ["rophi"] = {
        name = "Cá rô",
        difficulty = "easy",
        rarity = "common",
        xpReward = 8
    },

    ["ca_chim"] = {
        name = "Cá chim",
        difficulty = "medium",
        rarity = "uncommon",
        xpReward = 15
    },

    ["ca_hoi"] = {
        name = "Cá Hồi",
        difficulty = "hard",
        rarity = "rare",
        xpReward = 15
    },

    -- Advanced fish (Level 10+ Zone)

    ["ca_thu"] = {
        name = "Cá thu",
        difficulty = "medium",
        rarity = "common",
        xpReward = 8
    },

    ["tom_hum"] = {
        name = "Tôm hùm",
        difficulty = "hard",
        rarity = "uncommon",
        xpReward = 20
    },
    
    ["ca_ngu"] = {
        name = "Cá ngừ",
        difficulty = "hard",
        rarity = "rare",
        xpReward = 25
    },
    
    ["shark"] = {
        name = "Cá mập",
        difficulty = "veryhard",
        rarity = "legendary",
        xpReward = 40
    }
}

-- Required items
Config.RequiredItems = {
    rods = {
        "fishingrod1",      -- Basic wooden rod
        "fishingrod2",    -- Steel rod  
        "fishingrod3",  -- Carbon rod
        "fishingrod4",   -- Titanium rod
        "fishingrod5",      -- VIP rod
    },
    bait = "moi_cau"
}

-- Fishing rod configuration
Config.FishingRods = {
    
    ["fishingrod1"] = {
        name = "Cần câu LV1",
        durabilityLoss = 5,     -- Loses 6% durability per use
        maxDurability = 100,    -- 100% durability when new
        tier = 2,
        description = "Cần câu chắc chắn làm từ thép"
    },
    ["fishingrod2"] = {
        name = "Cần câu LV2",
        durabilityLoss = 3,     -- Loses 5% durability per use
        maxDurability = 100,    -- 100% durability when new
        tier = 3,
        description = "Cần câu nhẹ và bền làm từ carbon"
    },
    ["fishingrod3"] = {
        name = "Cần câu LV3",
        durabilityLoss = 1,     -- Loses 2% durability per use
        maxDurability = 100,    -- 100% durability when new
        tier = 4,
        description = "Cần câu cao cấp làm từ titan"
    },
    ["fishingrod4"] = {
        name = "Cần câu VIP",
        durabilityLoss = 0.5,     -- Loses 1% durability per use
        maxDurability = 100,    -- 100% durability when new
        tier = 5,
        description = "Cần câu đặc biệt với độ bền vượt trội"
    },
    ["fishingrod5"] = {
        name = "Cần câu LV5",
        durabilityLoss = 0.1,     -- Loses 2% durability per use
        maxDurability = 100,    -- 100% durability when new
        tier = 6,
        description = "Cần câu cao cấp làm từ titan"
    }
}

-- Fishing rods that won't be destroyed when durability reaches 0
Config.IndestructibleRods = {
    "fishingrod2",
    "fishingrod3",
    "fishingrod4",
    "fishingrod5"
}

-- Rod repair system for indestructible rods
Config.RodRepairSystem = {
    enabled = true,
    
    -- Repair requirements for each indestructible rod
    repairRequirements = {
        ['fishingrod2'] = {
            materials = {
                ['may_cau'] = 1
            },
            repairAmount = 100 -- Repair to 100% durability
        },
        ['fishingrod3'] = {
            materials = {
                ['may_cau'] = 2
            },
            repairAmount = 100 -- Repair to 100% durability
        },
        ['fishingrod4'] = {
            materials = {
                ['may_cau'] = 3
            },
            repairAmount = 100 -- Repair to 100% durability
        },
        ['fishingrod5'] = {
            materials = {
                ['may_cau'] = 4
            },
            repairAmount = 100 -- Repair to 100% durability
        }
    }
}

-- Minigame settings for xx_fishinggame
Config.MinigameDifficulty = {
    easy = {
        description = "Dễ - Cá nhỏ, ít kháng cự"
    },
    medium = {
        description = "Trung bình - Cá lớn hơn, kháng cự vừa phải"
    },
    hard = {
        description = "Khó - Cá lớn, kháng cự mạnh"
    },
    veryhard = {
        description = "Rất khó - Boss cá, cực kỳ khó"
    }
}

-- Cài đặt thời gian câu cá (dựa trên sự hiếm và khó khăn của cá)
Config.FishingTime = {
    min = 5000,
    max = 7000,
    -- Thời gian bổ sung dựa trên sự hiếm có của cá
    rarityMultiplier = {
        common = 1.0,
        uncommon = 1.5,
        rare = 2.0,
        epic = 3.0,
        legendary = 4.0
    }
}


Config.FishingBlips = {
    {
        coords = vector3(1685.64, 40.05, 161.77),
        sprite = 68,
        color = 0,
        scale = 1.0,
        name = "Khu câu cá mới bắt đầu (Cấp 1+)",
        distance = 100.0,
        showZoneCircle = false,
        zoneCircleColor = 0
    },
    {
        coords = vector3(718.95, 3913.64, 31.46),
        sprite = 68,
        color = 5,
        scale = 1.0,
        name = "Khu câu cá trung cấp (Cấp 5+)",
        distance = 100.0,
        showZoneCircle = false,
        zoneCircleColor = 5
    }
}

-- Shop Configuration
Config.FishingShop = {
    npcLocation = vector3(-1815.0, -1212.4, 13.02),
    npcHeading = 200.0,
    prices = {
        rods = {
            -- ['can_cau_go'] = 500
        },
        bait = 10 -- Price per bait
    }
}

-- Fishing Rod Upgrade System
Config.RodUpgradeSystem = {
    enabled = true,
    
    -- Rod tier to rarity mapping for metadata
    tierRarity = {
        [1] = "Common",     -- can_cau_go (Wooden rod)
        [2] = "Uncommon",   -- can_cau_thep (Steel rod)
        [3] = "Rare",       -- can_cau_carbon (Carbon rod)
        [4] = "Epic",       -- can_cau_titan (Titanium rod)
        [5] = "Legendary"   -- can_cau_vip (VIP rod)
    },
    
    -- Rod upgrade chain (from -> to)
    upgradeChain = {
        ['fishingrod1'] = 'fishingrod2',
        ['fishingrod2'] = 'fishingrod3', 
        ['fishingrod3'] = 'fishingrod4',
        ['fishingrod4'] = 'fishingrod5'
    },
    
    -- Upgrade requirements for each rod
    upgradeRequirements = {
        ['fishingrod1'] = {
            targetRod = 'fishingrod2',
            successRate = 85, -- 85% success rate
            materials = {
                ['money'] = 1000,
                ['aluminum'] = 3,
                ['plastic'] = 3,
                ['ls_iron_ingot'] = 5
            }
        },
        ['fishingrod2'] = {
            targetRod = 'fishingrod3',
            successRate = 50, -- 70% success rate
            materials = {
                ['money'] = 2000,
                ['carbon'] = 5,
                ['ls_silver_ingot'] = 5,
                ['ls_iron_ingot'] = 10
            }
        },
        ['fishingrod3'] = {
            targetRod = 'fishingrod4',
            successRate = 30, -- 55% success rate
            materials = {
                ['money'] = 3000,
                ['carbon'] = 10,
                ['ls_silver_ingot'] = 10,
                ['may_cau'] = 1,
                ['ls_iron_ingot'] = 10
            }
        },
        ['fishingrod4'] = {
            targetRod = 'fishingrod5',
            successRate = 5, -- 40% success rate
            materials = {
                ['money'] = 5000,
                ['carbon'] = 20,
                ['ls_silver_ingot'] = 20,
                ['may_cau'] = 5,
                ['ls_iron_ingot'] = 20
            }
        }
    },
    
    -- Material display names
    materialNames = {
        ['money'] = 'Sao Allstars',
        ['aluminum'] = 'Nhôm',
        ['plastic'] = 'Nhựa',
        ['ls_iron_ingot'] = 'Thỏi thép',
        ['ls_copper_ingot'] = 'Thỏi đồng',
        ['carbon'] = 'carbon',
        ['may_cau'] = 'Máy câu',
        ['ls_silver_ingot'] = 'Thỏi bạc'
    }
}

-- Performance Optimization Settings
Config.Performance = {
    -- Event-driven settings
    zoneMovementThreshold = 50.0,      -- Distance player must move to trigger zone check
    zoneCheckThrottle = 2000,          -- Min time between zone checks (ms)
    playerDataRefreshOnEvents = true,  -- Only refresh player data on events (no loops)
    
    -- Thread timings (for remaining loops)
    movementCheckInterval = 5000,      -- How often to check player movement (5 seconds)
    npcInteractionDistance = 10.0,     -- Distance to start checking NPC interaction
    npcInteractionFarWait = 500,       -- Wait time when far from NPC
    npcInteractionNearWait = 100,      -- Wait time when near but not close to NPC
    
    -- Loading timeouts (attempts)
    maxLoadAttempts = 50,              -- Max attempts to load models/animations
    loadWaitTime = 50,                 -- Wait time between load attempts (ms)
    
    -- Cleanup settings
    propCleanupAttempts = 3,           -- Reduced prop cleanup iterations
    propCleanupWaitTime = 300,         -- Wait time between cleanup attempts
}