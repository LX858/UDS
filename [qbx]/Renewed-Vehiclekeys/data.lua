return {
    lockChance = 1.0, -- (100%) Tất cả xe địa phương đều bị khóa
    lockChanceAI = 1.0, -- (100%) Tất cả xe AI đều bị khóa

    useWeaponRobbery = false, -- Be able to rob driving peds for their vehicle keys

    useKeybindKey = true, -- Thời tiết hoặc không sử dụng bản dựng trong hệ thống Keybind
    useHotwireSystem = true, -- Thời tiết hoặc không sử dụng hệ thống hotwire

    vehicleAutoStart = true, -- Nếu người chơi có chìa khóa ô tô thì nó có tự động khởi động khi họ vào xe không
    
    autoTurnOffEngine = false, -- Tự động tắt máy khi lên xe không có chìa khóa (true = tắt máy tự động, false = không tắt)

    useKeyItem = true, -- set to true if you want to use a item based key system

    engineKey = 'G', -- Key to toggle the engine on and off
    lockKey = 'L', -- Key to toggle the lock on and off

    circleProgress = true, -- Uses the circle progress bar instead of the default one from ox_lib

    -- Các xe được miễn khoá (chủ yếu là xe đạp)
    immune = {
        [`bmx`] = true,           -- BMX
        [`cruiser`] = true,       -- Beach Cruiser
        [`fixter`] = true,        -- Fixter (Fixed Gear)
        [`scorcher`] = true,      -- Scorcher (Mountain Bike)
        [`tribike`] = true,       -- Tri-Cycles Race Bike
        [`tribike2`] = true,      -- Tri-Cycles Race Bike 2
        [`tribike3`] = true,      -- Tri-Cycles Race Bike 3
        [`whippet`] = true,       -- Whippet Race Bike
    },

    -- Những cánh cửa cụ thể luôn bị khóa bất kể điều gì
    doorsBlocked = {
        [`stockade`] = {[1] = true, [2] = true}
    },

    searchPercent = 0.03, -- 3% chance of getting a item from searching a vehicle
    rewards = {
        { name = 'money', amount = 20, },
        { name = 'key' } -- we don't need to specify amount here as it will just give u 1 or if not using items give u the key
    },

    -- Minigame settings

    -- Whichs possible keys can show up when they lockpick / hotwire the vehicle
    keys = {'r', 'e', 'n', 'e', 'w', 'e', 'd'},

    difficulties = {
        slow = { time = {min = 75, max = 150}, turns = {min = 3, max = 5} },
        medium = { time = {min = 50, max = 100}, turns = {min = 2, max = 4} },
        fast = { time = {min = 25, max = 50}, turns = {min = 1, max = 2} }
    },

    -- t3_lockpick settings
    lockpickSettings = {
        easy = { difficulty = 0.6, pins = 3 },
        medium = { difficulty = 0.8, pins = 4 },
        hard = { difficulty = 1.0, pins = 5 }
    },

    -- Vehicle Config
    vehicles = {
        -- Compacts --
        [0] = {
            pickable = true, -- Xe này có mở khóa được không?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.6, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 3, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.6,
                    pins = 3,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },


        -- Sedans --
        [1] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.6, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 3, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.6,
                    pins = 3,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },


        -- SUVS --
        [2] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.7, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 4, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.7,
                    pins = 4,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },


        -- COUPES --
        [3] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.7, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 4, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.7,
                    pins = 4,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },


        -- MUSCLES --
        [4] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.7, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 4, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.7,
                    pins = 4,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },

        -- SPORT CLASSICS --
        [5] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.8, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 5, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.8,
                    pins = 5,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },

        -- Sports --
        [6] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.8, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 5, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.8,
                    pins = 5,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },

        -- SUPERS --
        [7] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 1.0, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 5, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 1.0,
                    pins = 5,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },

        -- MOTORCYCLES --
        [8] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.5, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 3, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.5,
                    pins = 3,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
            noLocks = false, -- This vehicle cannot be locked!
        },

        -- OFF-ROAD --
        [9] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.6, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 3, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.6,
                    pins = 3,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },


        -- Industrial --
        [10] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.6, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 3, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.6,
                    pins = 3,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },

        -- Utility --
        [11] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.6, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 3, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.6,
                    pins = 3,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },

        -- Vans --
        [12] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.6, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 3, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.6,
                    pins = 3,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },

        -- Cycles --
        [13] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.4, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 2, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.4,
                    pins = 2,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
            noLocks = false, -- This vehicle cannot be locked!
        },

        -- Boats --
        [14] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                advalockpicknced = {
                    difficulty = 0.8, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 4, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 1}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },

        -- Helicopters --
        [15] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                advalockpicknced = {
                    difficulty = 0.95, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 5, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 1}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },


        -- Planes --
        [16] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                advalockpicknced = {
                    difficulty = 1.0, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 5, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 1}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },

        -- Service --
        [17] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.6, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 3, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.6,
                    pins = 3,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },

        -- Emergency --
        [18] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 1.0, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 5, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 1.0,
                    pins = 5,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = false, -- Can this vehicle be hotwired?
            search = false, -- Can this vehicle be searched?
        },

        -- Military --
        [19] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 1.0, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 5, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 1.0,
                    pins = 5,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },

        -- Commercial --
        [20] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.7, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 4, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.7,
                    pins = 4,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },

        -- Trains --
        [21] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.7, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 4, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.7,
                    pins = 4,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },

        -- Open Wheel --
        [22] = {
            pickable = true, -- Can this vehicle be lock picked?
            pickItem = {  -- What item is required to lock pick this vehicle?
                lockpick = {
                    difficulty = 0.9, -- t3_lockpick difficulty (0.0 - 1.0)
                    pins = 5, -- Number of pins for t3_lockpick
                    degrade = {min = 0, max = 2}
                },
                advalockpicknced = {
                    difficulty = 0.9,
                    pins = 5,
                    degrade = {min = 0, max = 2}
                }
            },
            hotwire = 'medium', -- The difficulty of hotwiring this vehicle, false if it cannot be hotwired
            search = 5000, -- Time it takes to search this vehicle, if false it cannot be searched
        },
    },


    -- List of all the weapons that peds do not become scared of when you aim at them
    blockedWeapons = {
        [`WEAPON_UNARMED`] = true,
        [`WEAPON_KNIFE`] = true,
        [`WEAPON_NIGHTSTICK`] = true,
        [`WEAPON_HAMMER`] = true,
        [`WEAPON_BAT`] = true,
        [`WEAPON_CROWBAR`] = true,
        [`WEAPON_GOLFCLUB`] = true,
        [`WEAPON_BOTTLE`] = true,
        [`WEAPON_DAGGER`] = true,
        [`WEAPON_HATCHET`] = true,
        [`WEAPON_MACHETE`] = true,
        [`WEAPON_FLASHLIGHT`] = true,
        [`WEAPON_SWITCHBLADE`] = true,
        [`WEAPON_POOLCUE`] = true,
        [`WEAPON_WRENCH`] = true,
        [`WEAPON_BATTLEAXE`] = true,
        [`WEAPON_GRENADE`] = true,
        [`WEAPON_STICKYBOMB`] = true,
        [`WEAPON_BZGAS`] = true,
        [`WEAPON_MOLOTOV`] = true,
        [`WEAPON_FIREEXTINGUISHER`] = true,
        [`WEAPON_PETROLCAN`] = true,
        [`WEAPON_FLARE`] = true,
        [`WEAPON_BALL`] = true,
        [`WEAPON_SNOWBALL`] = true,
        [`WEAPON_SMOKEGRENADE`] = true,
    }
}