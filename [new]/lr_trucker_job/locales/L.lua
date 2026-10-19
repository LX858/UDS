Locales = Locales or {}

local function getActiveLocale()
  if Config and Config.Settings and Config.Settings.locale then
    return Config.Settings.locale
  end
  return Locales.default or {}
end

local function formatWithTable(pattern, replacements)
  for k, v in pairs(replacements) do
    pattern = pattern:gsub(":{" .. k .. "}", tostring(v))
  end
  return pattern
end

local function formatWithArgs(pattern, args)
  if #args == 0 then
    return pattern
  end
  local ok, formatted = pcall(string.format, pattern, table.unpack(args))
  if ok then
    return formatted
  end
  return pattern
end

function L(key, ...)
  local activeLocale = getActiveLocale()
  local pattern = activeLocale[key] or key
  local args = { ... }
  if #args == 1 and type(args[1]) == "table" then
    return formatWithTable(pattern, args[1])
  end
  return formatWithArgs(pattern, args)
end

function SetLocale(localeKey)
  local target = Locales[localeKey] or Locales.default or {}
  if Config then
    Config.Settings = Config.Settings or {}
    Config.Settings.locale = target
  end
  return target
end
