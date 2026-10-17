Config = {}

Config.Dependencies = {} -- Reqired resources loaded to start
Config.Locale = 'vi'

Config.Settings = {
  locale = Locales[Config.Locale] or Locales['default']
}

Config.Debug = true
Config.Nui = false
Config.Dev = false
---@type "qb" | "esx" | "ProjectStarboy" | "standalone"
Config.Framework = "qb" -- "qb" | "esx" | "custom"
Config.ClientLazyLoad = false

Config.Coords = vector3(1676.2930, 2193.6296, 81.3197)

Config.AFKJob = {
  StartCoords = vector3(1676.2930, 2193.6296, 81.3197),
  ZoneRadius = 35.0,
  RandomPointCount = 10,
  FarmPropModel = "bb_prop_32bit_process_strawberry",
  FarmDuration = 7000,
  MaxProgress = 200,
  FarmItem = "afk_item",
  FarmItemAmount = 1,
  RareItem = "afk_rare_reward",
  RareAmount = 1,
}

function L(key, ...)
  if Config.Settings.locale[key] then
    return string.format(Config.Settings.locale[key], ...)
  else
    return key
  end
end
