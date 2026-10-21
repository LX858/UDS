Config = {}

Config.Dependencies = {} -- Reqired resources loaded to start
Config.Locale = 'vi'

Config.Settings = {
  locale = Locales[Config.Locale] or Locales['default']
}

--Dont touch this
Config.EnableModules = {
  ["Main"] = {
    enabled = true,
    priority = 2, -- 1 : init on start | 2 : init on player loaded
  },
}
Config.Debug = true
Config.Nui = true
Config.Dev = false
---@type "qbx" | "qb" | "esx" | "ProjectStarboy" | "standalone"
Config.Framework = "qbx"
Config.ClientLazyLoad = false

function L(key, ...)
  if Config.Settings.locale[key] then
    return string.format(Config.Settings.locale[key], ...)
  else
    return key
  end
end

Config.Rewards = {
  ["hom_hlw"] = {
    {
      id = 1,
      name = "the_outfit_hlw",
      rate = 20,
      amount = 1,
      label = "Thẻ Trang Phục",
      type = "item"
    },
    {
      id = 2,
      name = "the_outfit_hlw",
      rate = 8,
      amount = 2,
      label = "Thẻ Trang Phục",
      type = "item"
    },
    {
      id = 3,
      name = "the_skin_hlw",
      rate = 20,
      amount = 1,
      label = "Thẻ Skin",
      type = "item"
    },
    {
      id = 4,
      name = "the_skin_hlw",
      rate = 8,
      amount = 2,
      label = "Thẻ Skin",
      type = "item"
    },
    {
      id = 5,
      name = "the_hlw",
      rate = 20,
      amount = 1,
      label = "Thẻ Trung Thu",
      type = "item"
    },
    {
      id = 6,
      name = "the_hlw",
      rate = 8,
      amount = 2,
      label = "Thẻ Trung Thu",
      type = "item"
    },
    {
      id = 7,
      name = "pumpkin_basket",
      rate = 1,
      amount = 1,
      label = "Giỏ bí ngô",
      type = "item"
    },
    {
      id = 8,
      name = "pumpkin_basket",
      rate = 1,
      amount = 2,
      label = "Giỏ bí ngô",
      type = "item"
    },
    {
      id = 9,
      name = "money",
      rate = 14,
      amount = 5000,
      label = "ingame",
      type = "item"
    }, 
    {
      id = 10,
      name = "skin_machete_ba",
      rate = 0,
      amount = 1,
      label = "Skin Baby Tree 2026",
      type = "item"
    },
    {
      id = 11,
      name = "skin_machete_hai",
      rate = 0,
      amount = 1,
      label = "Skin RICH 2026",
      type = "item"
    },
  },

  ["hom_hlw_ig"] = {
    {
      id = 1,
      name = "the_outfit_hlw",
      rate = 30,
      amount = 1,
      label = "Thẻ Trang Phục",
      type = "item"
    },
    {
      id = 2,
      name = "the_outfit_hlw",
      rate = 13,
      amount = 2,
      label = "Thẻ Trang Phục",
      type = "item"
    },
    {
      id = 3,
      name = "the_skin_hlw",
      rate = 20,
      amount = 1,
      label = "Thẻ Skin",
      type = "item"
    },
    {
      id = 4,
      name = "the_skin_hlw",
      rate = 10,
      amount = 2,
      label = "Thẻ Skin",
      type = "item"
    },
    {
      id = 5,
      name = "the_hlw",
      rate = 4,
      amount = 1,
      label = "Thẻ Trung Thu",
      type = "item"
    },
    {
      id = 6,
      name = "the_hlw",
      rate = 1,
      amount = 2,
      label = "Thẻ Trung Thu",
      type = "item"
    },
    {
      id = 7,
      name = "pumpkin_basket",
      rate = 1,
      amount = 1,
      label = "Giỏ bí ngô",
      type = "item"
    },
    {
      id = 8,
      name = "pumpkin_basket",
      rate = 1,
      amount = 2,
      label = "Giỏ bí ngô",
      type = "item"
    },
    {
      id = 9,
      name = "money",
      rate = 20,
      amount = 5000,
      label = "ingame",
      type = "item"
    }, 
    {
      id = 10,
      name = "skin_machete_ba",
      rate = 0,
      amount = 1,
      label = "Skin Baby Tree 2026",
      type = "item"
    },
    {
      id = 11,
      name = "skin_machete_hai",
      rate = 0,
      amount = 1,
      label = "Skin RICH 2026",
      type = "item"
    },
  }
}

