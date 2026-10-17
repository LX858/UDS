---@alias CreateCronJobData {callback: fun(id: string, date:osdate), hour?: string, minute?: string, second?: string, wday?: string; day?: string; name: string}
---@alias CronJob {id: string, callback: fun(id: string, date:osdate), hour?: number[], minute?: number[], second?: number[],wday?:number[], day?: number[], invokingResource: string; name: string}
---@alias CronQueue {id: string, stoped?: boolean}
---@class SVCronImpl : Impl
local Impl = NewSyncImpl("Cron")

function Impl:Init()
  AddEventHandler("onResourceStop", function(resource)
    self:OnResourceStopped(resource)
  end)
  self:LogInfo("%s initialized", self:GetName())
  ---@type table<string,sCronJob>
  self.jobs = {}
end

function Impl:OnReady()
  self:LogInfo("%s ready", self:GetName())
  local curTime = os.time()
  --[[ self:NewJob({
    callback = function()
      local newTime = os.time()
      self:LogInfo("Time passed %s", newTime - curTime)
      curTime = newTime
      self:LogInfo("Hello")
    end,
    second = "10,20,30,40,50,0",
    hour = "0-23",
    minute = "10,20,30,40,50,0",
    day = "1-31",
    wday = "1-7",
    name = "Test"
  }) ]]
end

---Create a new cron job
---@param data CreateCronJobData
---@return string|nil id
function Impl:NewJob(data)
  local id = GenerateUUID()
  local invokingResource = GetInvokingResource() or GetCurrentResourceName()
  ---@type CronJob
  local job = {
    id = id,
    callback = data.callback,
    hour = ParseFormatedStringNumber(data.hour or "0-23"),
    minute = ParseFormatedStringNumber(data.minute or "0-59"),
    second = ParseFormatedStringNumber(data.second or "0-59"),
    day = ParseFormatedStringNumber(data.day or "1-31"),
    wday = ParseFormatedStringNumber(data.wday or "1-7"),
    invokingResource = invokingResource,
    name = data.name
  }
  if not self:ValidateCronJob(job, data) then
    return
  end
  ---@type sCronJob
  local jobInstance = sCronJob(job)
  self.jobs[id] = jobInstance
  return id
end

---Validate cron job
---@param job CronJob
---@param input CreateCronJobData
---@return boolean
function Impl:ValidateCronJob(job, input)
  if not job.callback then
    self:LogError("Callback is required")
    return false
  end
  if not input.hour and not input.minute and not input.second and not input.day and not input.wday then
    self:LogError("At least one of hour, minute, second, day, wday is required")
    return false
  end
  if input.hour then
    ---@type number[]
    local newHour = {}
    for _, hour in ipairs(job.hour) do
      if hour < 0 or hour > 23 then
        self:LogWarning("Hour must be between 0 and 23")
      else
        table.insert(newHour, hour)
      end
    end
    job.hour = SortNumberArray(newHour)
  end
  if input.minute then
    ---@type number[]
    local newMinute = {}
    for _, minute in ipairs(job.minute) do
      if minute < 0 or minute > 59 then
        self:LogWarning("Minute must be between 0 and 59")
      else
        table.insert(newMinute, minute)
      end
    end
    job.minute = SortNumberArray(newMinute)
  end
  if input.second then
    ---@type number[]
    local newSecond = {}
    for _, second in ipairs(job.second) do
      if second < 0 or second > 59 then
        self:LogWarning("Second must be between 0 and 59")
      else
        table.insert(newSecond, second)
      end
    end
    job.second = SortNumberArray(newSecond)
  end
  if input.day then
    ---@type number[]
    local newDay = {}
    for _, day in ipairs(job.day) do
      if day < 1 or day > 31 then
        self:LogWarning("Day must be between 1 and 31")
      else
        table.insert(newDay, day)
      end
    end
    job.day = SortNumberArray(newDay)
  end
  if input.wday then
    ---@type number[]
    local newWday = {}
    for _, wday in ipairs(job.wday) do
      if wday < 1 or wday > 7 then
        self:LogWarning("Wday must be between 1 and 7")
      else
        table.insert(newWday, wday)
      end
    end
    job.wday = SortNumberArray(newWday)
  end
  return true
end

function Impl:OnResourceStopped(rsName)
  for id, timeFrame in pairs(self.jobs) do
    if timeFrame.invokingResource == rsName then
      timeFrame.stoped = true
      self.jobs[id] = nil
    end
  end
end

function Impl:GetCron(id)
  return self.jobs[id]
end

Impl.start()
