---Get next time in array
---@param arr number[]
---@param cur number
local function getNextTimeInArray(arr, cur)
  for k, v in ipairs(arr) do
    if v >= cur then
      return v
    end
  end
  return arr[1]
end


---@class sCronJob
sCronJob = class()

---Create cron job intance
---@param data CronJob
function sCronJob:Init(data)
  self.id = data.id
  self.callback = data.callback
  self.hour = data.hour
  self.minute = data.minute
  self.second = data.second
  self.day = data.day
  self.wday = data.wday
  self.invokingResource = data.invokingResource
  self.name = data.name
  self.stoped = false
  self:Run()
end

function sCronJob:IsTimeValid(curTime, type)
  local curDate = os.date("*t", curTime);
  if type == "day" then
    return ArrayHasElement(self.day, curDate.day)
  end
  if type == "wday" then
    return ArrayHasElement(self.wday, curDate.wday)
  end
  if type == "hour" then
    return ArrayHasElement(self.hour, curDate.hour) and self:IsTimeValid(curTime, "day") and
        self:IsTimeValid(curTime, "wday")
  end
  if type == "minute" then
    return ArrayHasElement(self.minute, curDate.min) and self:IsTimeValid(curTime, "hour")
  end
  if type == "second" then
    return ArrayHasElement(self.second, curDate.sec) and self:IsTimeValid(curTime, "minute")
  end
  return true
end

function sCronJob:GetNextCron()
  local curTime = os.time();
  local offset = 0;
  local modified = {}
  while not self:IsTimeValid(curTime, "day") or not self:IsTimeValid(curTime, "wday") do
    offset = offset + 86400
    curTime = curTime + 86400
    modified["day"] = true
  end
  if modified["day"] then
    offset = offset - 86400
    curTime = curTime - 86400
  end
  while not self:IsTimeValid(curTime, "hour") do
    offset = offset + 3600
    curTime = curTime + 3600
    modified["hour"] = true
  end
  if modified["hour"] then
    offset = offset - 3600
    curTime = curTime - 3600
  end
  while not self:IsTimeValid(curTime, "minute") do
    offset = offset + 60
    curTime = curTime + 60
    modified["minute"] = true
  end
  if modified["minute"] then
    offset = offset - 60
    curTime = curTime - 60
  end
  while not self:IsTimeValid(curTime, "second") do
    offset = offset + 1
    curTime = curTime + 1
  end
  return offset
end

function sCronJob:Run()
  local sec = self:GetNextCron()
  local previos = self:GetPreviosCron()
  --local executeDate = os.date("%d-%m-%Y, %H:%M:%S", os.time() + sec)
  local executeDate = os.date("*t", os.time() + sec)
  print(string.format("^3cron [%s|%s] - %s start in %s (after %ss) ^0", self.id, self.invokingResource, self.name,
    os.date("%d-%m-%Y, %H:%M:%S", os.time() + sec), sec))
  print(string.format("^3cron [%s|%s] - %s previos start in %s (before %ss) ^0", self.id, self.invokingResource,
    self.name,
    os.date("%d-%m-%Y, %H:%M:%S", os.time() + previos), previos))
  if sec > 0 then
    SetTimeout(sec * 1000, function()
      if not self.stoped then
        --self.callback(self.id, executeDate)
        local res, err = pcall(self.callback, self.id, executeDate)
        if not res then
          print(err)
        else
          print(string.format("^2cron [%s|%s] - %s executed in %s ^0", self.id, self.invokingResource, self.name,
            os.date("%d-%m-%Y, %H:%M:%S", os.time())))
        end
        Wait(1000)
        self:Run()
      end
    end)
  else
    Citizen.CreateThread(function()
      if not self.stoped then
        --self.callback(self.id, executeDate)
        local res, err = pcall(self.callback, self.id, executeDate)
        if not res then
          print(err)
        else
          print(string.format("^2cron [%s|%s] - %s executed in %s ^0", self.id, self.invokingResource, self.name,
            os.date("%d-%m-%Y, %H:%M:%S", os.time())))
        end
        Wait(1000)
        self:Run()
      end
    end)
  end
end

function sCronJob:IsTimeValidReverse(curTime, type)
  local curDate = os.date("*t", curTime);
  local date = os.date("%d-%m-%Y, %H:%M:%S", curTime);
  print(date, type)
  if type == "second" then
    return ArrayHasElement(self.second, curDate.sec)
  end
  if type == "minute" then
    return ArrayHasElement(self.minute, curDate.min) and self:IsTimeValidReverse(curTime, "second")
  end
  if type == "hour" then
    return ArrayHasElement(self.hour, curDate.hour) and self:IsTimeValidReverse(curTime, "minute")
  end
  if type == "day" then
    return ArrayHasElement(self.day, curDate.day) and self:IsTimeValidReverse(curTime, "hour")
  end
  if type == "wday" then
    return ArrayHasElement(self.wday, curDate.wday) and self:IsTimeValidReverse(curTime, "day")
  end
  return true
end

function sCronJob:GetPreviosCron()
  local curTime = os.time();
  local offset = 0;
  local modified = {}
  while not self:IsTimeValid(curTime, "day") or not self:IsTimeValid(curTime, "wday") do
    offset = offset - 86400
    curTime = curTime - 86400
    modified["day"] = true
  end
  if modified["day"] then
    offset = offset + 86400
    curTime = curTime + 86400
  end
  while not self:IsTimeValid(curTime, "hour") do
    offset = offset - 3600
    curTime = curTime - 3600
    modified["hour"] = true
  end
  if modified["hour"] then
    offset = offset + 3600
    curTime = curTime + 3600
  end
  while not self:IsTimeValid(curTime, "minute") do
    offset = offset - 60
    curTime = curTime - 60
    modified["minute"] = true
  end
  if modified["minute"] then
    offset = offset + 60
    curTime = curTime + 60
  end
  while not self:IsTimeValid(curTime, "second") do
    offset = offset - 1
    curTime = curTime - 1
  end


  return offset
end
