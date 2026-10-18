function ScootColor(value)
  if type(value) ~= "string" then
    return nil
  end

  local hex = value:gsub("%s", ""):gsub("^#", ""):gsub("^0[xX]", "")

  if #hex == 3 then
    hex = hex:gsub("%x", "%0%0")
  end

  if #hex == 8 then
    hex = hex:sub(3)
  end

  if #hex ~= 6 or hex:find("%X") then
    return nil
  end

  return "#" .. hex:lower()
end

function ScootTheme()
  local theme = {}
  for key, value in pairs(ScootConfig.ui) do
    theme[key] = value
  end

  local colorKeys = {
    "accent",
    "accentSecondary",
    "panel",
    "text",
    "muted",
  }

  for _, key in ipairs(colorKeys) do
    local normalized = ScootColor(theme[key])
    if not normalized and theme[key] ~= nil then
      print(("[scootbunker] ui.%s is not a usable colour: %s"):format(key, tostring(theme[key])))
    end
    theme[key] = normalized or nil
  end

  return theme
end
