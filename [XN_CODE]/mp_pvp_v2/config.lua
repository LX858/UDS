Config = {}
Config.Anticheat = GetConvarInt('sv:anticheat', 1) == 1

Config.Dependencies = {} -- Reqired resources loaded to start
Config.Locale = 'vi'

Config.Settings = {
  locale = Locales[Config.Locale] or Locales['default']
}

Config.Anticheat = GetConvarInt('sv:anticheat', 1) == 1


Config.PlateLetters   = 3
Config.PlateNumbers   = 3
Config.PlateUseSpace  = true

--Dont touch this
Config.EnableModules  = {
  ["Main"] = {
    enabled = true,
    client = true, -- enable client side
    priority = 2,  -- 1 : init on start | 2 : init on playerloaded
  },
}
Config.Debug          = true
Config.Nui            = true
Config.Dev            = false
---@type "qb" | "esx" | "ProjectStarboy" | "standalone" | "old_esx"
Config.Framework      = "qb" -- "qb" | "esx" | "custom" | "old_esx"
Config.ClientLazyLoad = false

Config.PvpNpc = {
  enabled = true,
  model = "s_m_y_blackops_01",
  coords = vector4(232.0762, -758.8872, 30.8566, 162.3061),
  interactDistance = 2.0,
}

function L(key, ...)
  if Config.Settings.locale[key] then
    return string.format(Config.Settings.locale[key], ...)
  else
    return key
  end
end

Config.Ranks = {
  ['dong'] = {
    min = 0,
    max = 500,
    label = "Đồng"
  },
  ['bac'] = {
    min = 501,
    max = 1000,
    label = "Bạc"
  },
  ['vang'] = {
    min = 1001,
    max = 1500,
    label = "Vàng"
  },
  ['bachkim'] = {
    min = 1501,
    max = 2000,
    label = "Bạch Kim"
  },
  ['lucbao'] = {
    min = 2001,
    max = 2500,
    label = "Lục Bảo"
  },
  ['kimcuong'] = {
    min = 2501,
    max = 3500,
    label = "Kim Cương"
  },
  ['caothu'] = {
    min = 3001,
    max = 4000,
    label = "Cao Thủ"
  },
  ['thachdau'] = {
    min = 4001,
    label = "Thách Đấu"
  },
}

Config.PointWhenWin = {
  ['dong'] = 10,
  ['bac'] = 10,
  ['vang'] = 10,
  ['bachkim'] = 10,
  ['lucbao'] = 10,
  ['kimcuong'] = 10,
  ['caothu'] = 10,
  ['thachdau'] = 10,
}

Config.MatchPoint = {
  win = 10,
  lose = 10,
}

Config.NegativePoint = {
  mode = "solo",
  lockPoint = -150,
  resetAfter = 7 * 24 * 60 * 60,
  restoreTo = 0,
  restoreItem = "coin",
  restoreAmount = 1,
}

Config.WinReward = {
  enabled = true,
  item = "the_pvp",
  amount = 1,
  chance = 10,
  cycleSize = 10, 
}

Config.PvpOpenTime = {
  enabled = true,
  intervals = {
    { startHour = 13, startMinute = 0, endHour = 17, endMinute = 0 },
    { startHour = 21, startMinute = 0, endHour = 23, endMinute = 99 },
  },
}

Config.PointWhenLose = {
  ['dong'] = 10,
  ['bac'] = 10,
  ['vang'] = 10,
  ['bachkim'] = 10,
  ['lucbao'] = 10,
  ['kimcuong'] = 10,
  ['caothu'] = 10,
  ['thachdau'] = 10,
}

Config.TeamCoords = {
  [1] = {
    a = { vector4(5408.7515, 6792.2910, 778.6828, 89.9935) },
    b = { vector4(5360.0981, 6792.2295, 778.6829, 267.9099) }
  },
}



Config.Weapons = {
  [1] = {
    name = 'WEAPON_POOLCUE',
  },
  [2] = {
    name = 'WEAPON_MACHETE',
  },
  [3] = {
    name = 'WEAPON_SWITCHBLADE'
  },
}
