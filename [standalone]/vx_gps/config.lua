Config = {}

Config.Dependencies = {} -- Reqired resources loaded to start
Config.Locale = 'vi'

Config.Settings = {
  locale = Locales[Config.Locale] or Locales['default']
}


Config.DefautGps = {
  ["ambulance"] = {
    sprite = 1,
    color = 3,
    scale = 1.0,
    display = 4,
    name = "EMS",
  },
  ["police"] = {
    sprite = 1,
    color = 38,
    scale = 1.0,
    display = 4,
    name = "CA",
  },
  -- ["police"] = {
  --   sprite = 1,
  --   color = 1,
  --   scale = 0.6,
  --   display = 4,
  --   name = "EMS",
  -- },
}

Config.Debug = true
Config.Nui = true
Config.Dev = false
---@type "qbx" | "qb" | "esx" | "ProjectStarboy" | "standalone"
Config.Framework = "qbx" -- "qbx" | "qb" | "esx" | "ProjectStarboy" | "standalone"
Config.ClientLazyLoad = false

function L(key, ...)
  if Config.Settings.locale[key] then
    return string.format(Config.Settings.locale[key], ...)
  else
    return key
  end
end
