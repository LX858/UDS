Config = {}

Config.Dependencies = {} -- Reqired resources loaded to start
Config.Locale = 'vi'

Config.Settings = {
  locale = Locales[Config.Locale] or Locales['default']
}

Config.Debug = true
Config.Nui = true
Config.Dev = false
---@type "qb" | "esx" | "ProjectStarboy" | "standalone"
Config.Framework = "qb" -- "qb" | "esx" | "custom"
Config.ClientLazyLoad = false

-- All times are Asia/Bangkok (UTC+7). An empty list disables automatic starts.
Config.Airdrop = {
  Schedule = { '15:00', '21:00' },
  RegistrationSeconds = 60 * 3,
  MatchSeconds = 15 * 60,
  ScoreEverySeconds = 20,
  ScoreRadius = 30.0,
  RespawnSeconds = 2,
  ResultSeconds = 10,
  JoinPosition = vector3(-5284.181, 2679.840, 320.000), -- Reserved for future use.
  DropPosition = vector3(-5284.4434, 2680.2986, 247.8109),
  DropModel = 'bb_prop_32bit_airdrop',
  Bucket = 61432,
  Teams = {
    A = { spawn = vector3(-5284.5469, 2748.4897, 247.8106), heading = 0.0 },
    B = { spawn = vector3(-5284.0537, 2611.1379, 247.8110), heading = 180.0 },
  },
  Weapons = {
    { id = 'machete', name = 'WEAPON_MACHETE', image = 'WEAPON_MACHETE.png' },
    { id = 'bottle', name = 'WEAPON_BOTTLE', image = 'WEAPON_BOTTLE.png' },
    { id = 'poolcue', name = 'WEAPON_POOLCUE', image = 'WEAPON_POOLCUE.png' },
  },
  Rewards = {
    { name = 'gachabox2', count = 5 },
  },
  -- Sample freemode outfits. Admins can replace drawable and texture values.
  -- Face and hair components are intentionally excluded.
  -- Mỗi giá trị là {drawableId, textureId}; prop drawableId = -1 nghĩa là tháo prop.
  Uniforms = {
    A = {
      male = {
        components = {
          [1] = {0, 0},   -- Mặt nạ
          [3] = {180, 0},  -- Tay / thân trên
          [4] = {260, 2},   -- Quần / chân
          [5] = {0, 0},   -- Túi / dù
          [6] = {5, 3},   -- Giày
          [7] = {0, 0},   -- Phụ kiện cổ (dây chuyền, khăn, cà vạt)
          [8] = {15, 0},  -- Áo trong
          [9] = {0, 0},   -- Áo giáp (phần hiển thị)
          [10] = {0, 0},  -- Huy hiệu / decal
          [11] = {804, 3},  -- Áo ngoài
        },
        props = {
          [0] = {-1, 0}, -- Mũ / nón
          [1] = {-1, 0}, -- Kính
          [2] = {-1, 0}, -- Phụ kiện tai
          [6] = {-1, 0}, -- Đồng hồ
          [7] = {-1, 0}, -- Vòng tay
        },
      },
      female = {
        components = {
          [1] = {0, 0},   -- Mặt nạ
          [3] = {268, 0},  -- Tay / thân trên
          [4] = {272, 0},   -- Quần / chân
          [5] = {0, 0},   -- Túi / dù
          [6] = {340, 0},   -- Giày
          [7] = {0, 0},   -- Phụ kiện cổ (dây chuyền, khăn, cà vạt)
          [8] = {639, 0},  -- Áo trong
          [9] = {0, 0},   -- Áo giáp (phần hiển thị)
          [10] = {0, 0},  -- Huy hiệu / decal
          [11] = {1000, 3},  -- Áo ngoài
        },
        props = {
          [0] = {224, 0}, -- Mũ / nón
          [1] = {-1, 0}, -- Kính
          [2] = {-1, 0}, -- Phụ kiện tai
          [6] = {-1, 0}, -- Đồng hồ
          [7] = {-1, 0}, -- Vòng tay
        },
      },
    },
    B = {
      male = {
        components = {
          [1] = {0, 0},   -- Mặt nạ
          [3] = {180, 0},  -- Tay / thân trên
          [4] = {260, 3},  -- Quần / chân
          [5] = {0, 0},   -- Túi / dù
          [6] = {5, 3},  -- Giày
          [7] = {1, 0},   -- Phụ kiện cổ (dây chuyền, khăn, cà vạt)
          [8] = {15, 0},  -- Áo trong
          [9] = {0, 0},   -- Áo giáp (phần hiển thị)
          [10] = {0, 0},  -- Huy hiệu / decal
          [11] = {804, 2}, -- Áo ngoài
        },
        props = {
          [0] = {-1, 0}, -- Mũ / nón
          [1] = {0, 0},  -- Kính
          [2] = {-1, 0}, -- Phụ kiện tai
          [6] = {-1, 0}, -- Đồng hồ
          [7] = {-1, 0}, -- Vòng tay
        },
      },
      female = {
        components = {
          [1] = {0, 0},   -- Mặt nạ
          [3] = {268, 0},  -- Tay / thân trên
          [4] = {272, 0},  -- Quần / chân
          [5] = {0, 0},   -- Túi / dù
          [6] = {340, 0},  -- Giày
          [7] = {0, 0},   -- Phụ kiện cổ (dây chuyền, khăn, cà vạt)
          [8] = {639, 0},  -- Áo trong
          [9] = {0, 0},   -- Áo giáp (phần hiển thị)
          [10] = {0, 0},  -- Huy hiệu / decal
          [11] = {1000, 2}, -- Áo ngoài
        },
        props = {
          [0] = {-1, 0}, -- Mũ / nón
          [1] = {0, 0},  -- Kính
          [2] = {-1, 0}, -- Phụ kiện tai
          [6] = {-1, 0}, -- Đồng hồ
          [7] = {-1, 0}, -- Vòng tay
        },
      },
    },
  },
}

function L(key, ...)
  if Config.Settings.locale[key] then
    return string.format(Config.Settings.locale[key], ...)
  else
    return key
  end
end
