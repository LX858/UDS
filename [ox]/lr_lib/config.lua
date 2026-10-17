Config = {}

Config.Dependencies = {} -- Reqired resources loaded to start
Config.Locale = 'vi'

Config.Settings = {
  locale = Locales[Config.Locale] or Locales['default']
}

--Dont touch this
Config.EnableModules = {
  ["Logger"] = {
    enabled = true,
    client = false, -- enable client side
    priority = 1,  -- 1 : init on start | 2 : init on player loaded
  },
  ["Player"] = {
    enabled = false,
    client = true, -- enable client side
    priority = 1,  -- 1 : init on start | 2 : init on player loaded
  },
  ["Items"] = {
    enabled = false,
    client = true, -- enable client side
    priority = 2,  -- 1 : init on start | 2 : init on player loaded
  },
  ["DiscordWebhook"] = {
    enabled = false,
    client = true, -- enable client side
    priority = 1,  -- 1 : init on start | 2 : init on player loaded
  },
  ["CruiseControl"] = {
    enabled = false,
    client = true, -- enable client side
    priority = 2,  -- 1 : init on start | 2 : init on player loaded
  },
  ["FriendController"] = {
    enabled = false,
    client = true, -- enable client side
    priority = 2,  -- 1 : init on start | 2 : init on player loaded
  },
  ["Dev"] = {
    enabled = false,
    client = false, -- enable client side
    priority = 2,   -- 1 : init on start | 2 : init on player loaded
  },
  ["DevTool"] = {
    enabled = true,
    client = true, -- enable client side
    priority = 2,  -- 1 : init on start | 2 : init on player loaded
  },
  ["Command"] = {
    enabled = true,
    client = true, -- enable client side
    priority = 2,  -- 1 : init on start | 2 : init on player loaded
  },

}
Config.Debug = true
Config.Nui = true
Config.Dev = false
---@type "qb" | "esx" | "ProjectStarboy" | "standalone"
Config.Framework = "qb" -- "qb" | "esx" | "custom"
Config.ClientLazyLoad = false

function L(key, ...)
  if Config.Settings.locale[key] then
    return string.format(Config.Settings.locale[key], ...)
  else
    return key
  end
end

Config.Items = {
  ["hunger1"] = {
    type = "hunger",
    label = "Đang Ăn...",
    duration = 3000,
    prop = {
      bone = 60309,
      model = "prop_taco_01",
      pos = vec3(0.017090005424848, 0.010670316917294, -0.040158531009835),
      rot = vec3(0, 0, -97.591390301991)
    },
    anim = {
      dict = "mp_player_inteat@burger",
      clip = "mp_player_int_eat_burger"
    },
    status = 250,
    remove = true,
  },
  ["hunger2"] = {
    type = "hunger",
    label = "Đang Ăn...",
    duration = 3000,
    prop = {
      bone = 18905,
      model = "prop_cs_burger_01",
      pos = vec3(0.13, 0.05, 0.02),
      rot = vec3(-50.0, 16.0, 60.0)
    },
    anim = {
      dict = "mp_player_inteat@burger",
      clip = "mp_player_int_eat_burger"
    },
    status = 500,
    remove = true,
  },
  ["hunger3"] = {
    type = "hunger",
    label = "Đang Ăn...",
    duration = 5000,
    prop = {
      {
        bone = 60309,
        model = "prop_cs_plate_01",
        pos = vec3(0.0, 0.0, 0.0),
        rot = vec3(0.0, 0.0, 0.0)
      },
      {
        bone = 28422,
        model = "h4_prop_h4_caviar_spoon_01a",
        pos = vec3(0.0, 0.0, 0.0),
        rot = vec3(0.0, 0.0, 0.0)
      }
    },
    anim = {
      dict = "anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1",
      clip = "base_idle"
    },
    status = 750,
    remove = true,
  },

  ["hunger4"] = {
    type = "hunger",
    label = "Đang Ăn...",
    duration = 5000,
    prop = {
      {
        bone = 60309,
        model = "prop_cs_plate_01",
        pos = vec3(0.0, 0.0, 0.0),
        rot = vec3(0.0, 0.0, 0.0)
      },
      {
        bone = 28422,
        model = "h4_prop_h4_caviar_spoon_01a",
        pos = vec3(0.0, 0.0, 0.0),
        rot = vec3(0.0, 0.0, 0.0)
      }
    },
    anim = {
      dict = "anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1",
      clip = "base_idle"
    },
    status = 1000,
    remove = true,
  },

  ["thirst1"] = {
    type = "thirst",
    label = "Đang uống...",
    duration = 3000,
    prop = {
      bone = 18905,
      model = "prop_ld_flow_bottle",
      pos = vec3(0.12, 0.008, 0.03),
      rot = vec3(240.0, -60.0, 0.0)
    },
    anim = {
      dict = "mp_player_intdrink",
      clip = "loop_bottle"
    },
    disable = {},
    status = 250,
    remove = true,
  },

  ["thirst2"] = {
    type = "thirst",
    label = "Đang uống...",
    duration = 3000,
    prop = {
      bone = 18905,
      model = "prop_ld_flow_bottle",
      pos = vec3(0.12, 0.008, 0.03),
      rot = vec3(240.0, -60.0, 0.0)
    },
    anim = {
      dict = "mp_player_intdrink",
      clip = "loop_bottle"
    },
    disable = {},
    status = 500,
    remove = true,
  },

  ["thirst3"] = {
    type = "thirst",
    label = "Đang uống...",
    duration = 5000,
    prop = {
      bone = 28422,
      model = "brum_cherryshake_strawberry",
      pos = vec3(0.093814252996367, 0.029746797217875, -0.039276347011741),
      rot = vec3(-87.523644338215, 0.61652089550273, -19.274288377318)
    },
    anim = {
      dict = "smo@milkshake_idle",
      clip = "milkshake_idle_clip"
    },
    disable = {},
    status = 750,
    remove = true,
  },

  ["thirst4"] = {
    type = "thirst",
    label = "Đang uống...",
    duration = 5000,
    prop = {
      bone = 28422,
      model = "brum_cherryshake_raspberry",
      pos = vec3(0.093814252996367, 0.029746797217875, -0.039276347011741),
      rot = vec3(-87.523644338215, 0.61652089550273, -19.274288377318)
    },
    anim = {
      dict = "smo@milkshake_idle",
      clip = "milkshake_idle_clip"
    },
    disable = {},
    status = 1000,
    remove = true,
  },


  ["bandage"] = {
    type = "heal",
    label = "Đang hồi máu",
    duration = 5000,
    prop = {},
    anim = {
      dict = "anim@heists@narcotics@funding@gang_idle",
      clip = "gang_chatting_idle01",
      flag = 1
    },
    disable = { move = true, car = true },
    remove = true,
  },
}


Config.StatusTick = 1   -- phút

Config.StatusRemove = 9 -- remove 8.3/phút -> 120 phút sẽ hết hoàn toàn
