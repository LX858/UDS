Ms = {
  -- Hàm chuyển đổi chuỗi thành milliseconds
  parse = function(str)
    if type(str) ~= "string" then
      error("Invalid input")
    end
    local patterns = {
      { "d",  86400000 }, -- ngày
      { "h",  3600000 },  -- giờ
      { "m",  60000 },    -- phút
      { "s",  1000 },     -- giây
      { "ms", 1 }         -- milliseconds
    }

    for _, pattern in ipairs(patterns) do
      local unit, multiplier = pattern[1], pattern[2]
      local num = tonumber(str:match("(%d+)" .. unit))
      if num then
        return num * multiplier
      end
    end

    return nil
  end,

  -- Hàm chuyển đổi milliseconds thành chuỗi định dạng
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
