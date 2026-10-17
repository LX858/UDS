function Response(isSuccess, message, data)
  if not isSuccess then
    return {
      status = "error",
      message = message
    }
  end
  return {
    status = "success",
    data = data,
    message = message
  }
end

function GenerateUUID()
  return tostring(math.floor(GetGameTimer())) .. tostring(math.random(1000))
end

function split(pString, pPattern)
  local Table = {} -- NOTE: use {n = 0} in Lua-5.0
  local fpat = "(.-)" .. pPattern
  local last_end = 1
  local s, e, cap = pString:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
      table.insert(Table, cap)
    end
    last_end = e + 1
    s, e, cap = pString:find(fpat, last_end)
  end
  if last_end <= #pString then
    cap = pString:sub(last_end)
    table.insert(Table, cap)
  end
  return Table
end

---Parse "1,3,4" -> {1,3,4} or "1-3" -> {1,2,3}
---@param numStr string
---@return number[]
function ParseFormatedStringNumber(numStr)
  ---@type number[]
  local result = {}
  local parts = split(numStr, ",")
  for _, part in ipairs(parts) do
    if part:find("-") then
      local range = split(part, "-")
      local start = tonumber(range[1])
      local stop = tonumber(range[2])
      for i = start, stop do
        table.insert(result, i)
      end
    else
      table.insert(result, tonumber(part))
    end
  end
  return result
end

---Short {2,3,1} -> {1,2,3} asc or {2,3,1} -> {3,2,1} desc
---@param arr number[]
---@param desc boolean | nil
---@return number[]
function SortNumberArray(arr, desc)
  table.sort(arr)
  if desc then
    local result = {}
    for i = #arr, 1, -1 do
      table.insert(result, arr[i])
    end
    return result
  end
  return arr
end

---Get the closest number in an array
---@param arr number[]
---@param num number
---@return number
function GetClosestNumberInArray(arr, num)
  local closest = nil
  local diff = nil
  for _, v in ipairs(arr) do
    if not closest then
      closest = v
      diff = math.abs(num - v)
    else
      local newDiff = math.abs(num - v)
      if newDiff < diff then
        closest = v
        diff = newDiff
      end
    end
  end
  return closest
end

function IsLeapYear(year)
  return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

function GetMaxDayInMonth(year, month)
  local days = {
    31,
    IsLeapYear(year) and 29 or 28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31
  }
  return days[month]
end

---Get current Date
---@param second number
function SecondToDateTime(second)
  local day = math.floor(second / 86400)
  second = second % 86400
  local hour = math.floor(second / 3600)
  second = second % 3600
  local min = math.floor(second / 60)
  second = second % 60
  return { day = day, hour = hour, min = min, second = second }
end

function ArrayHasElement(arr, element)
  for _, v in ipairs(arr) do
    if v == element then
      return true
    end
  end
  return false
end
