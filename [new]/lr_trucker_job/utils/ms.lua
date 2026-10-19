Ms = {
  -- Parse duration strings into milliseconds (e.g. "5m", "2h")
  parse = function(str)
    if type(str) ~= "string" then
      error("Invalid input")
    end
    local patterns = {
      { "ms", 1 },     -- milliseconds must be checked before minutes
      { "d",  86400000 }, -- days
      { "h",  3600000 },  -- hours
      { "m",  60000 },    -- minutes
      { "s",  1000 }      -- seconds
    }

    for _, pattern in ipairs(patterns) do
      local unit, multiplier = pattern[1], pattern[2]
      local num = tonumber(str:match("^%s*(%d+)%s*" .. unit .. "%s*$"))
      if num then
        return num * multiplier
      end
    end

    return nil
  end,

  -- Convert milliseconds back to a friendly duration string
  tostring = function(ms)
    if type(ms) ~= "number" then
      error("Invalid input")
    end
    local timeUnits = {
      { "d",  86400000 },
      { "h",  3600000 },
      { "m",  60000 },
      { "s",  1000 },
      { "ms", 1 }
    }

    for _, unit in ipairs(timeUnits) do
      local name, value = unit[1], unit[2]
      if ms >= value then
        local time = ms / value
        return string.format("%.0f%s", time, name)
      end
    end

    return ms .. "ms"
  end
}
