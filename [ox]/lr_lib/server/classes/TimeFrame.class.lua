---@class sTimeFrame
sTimeFrame = class()

---@param data TimeFrameData
function sTimeFrame:Init(data)
  self.id = data.id
  self.startAt = data.startAt
  self.endAt = data.endAt
  self.onStart = data.onStart
  self.onEnd = data.onEnd
  self.invokingResource = data.invokingResource
  self.name = data.name
  self.stoped = false

  ---@type SVCronImpl
  local cronImpl = main:GetImpl("Cron")

  -- Start time frame
  local startCronId = cronImpl:NewJob({
    callback = function()
      self:OnStart()
    end,
    second = self.startAt.second,
    minute = self.startAt.minute,
    hour = self.startAt.hour,
    day = self.startAt.day,
    wday = self.startAt.wday,
    name = "START:" .. self.name
  })
  if not startCronId then
    main:LogError("Error creating start cron job")
    return
  end
  self.startCron = cronImpl:GetCron(startCronId)

  -- End time frame
  local endCronId = cronImpl:NewJob({
    callback = function()
      self:OnEnd()
    end,
    second = self.endAt.second,
    minute = self.endAt.minute,
    hour = self.endAt.hour,
    day = self.endAt.day,
    wday = self.endAt.wday,
    name = "END:" .. self.name
  })

  if not endCronId then
    main:LogError("Error creating start cron job")
    return
  end
  self.endCron = cronImpl:GetCron(endCronId)

  if self:IsInFrame() then
    main:LogInfo("Time frame %s is in frame", self.name)
    self:OnStart()
  else
    main:LogInfo("Time frame %s is not in frame", self.name)
    --self:OnEnd()
  end
end

function sTimeFrame:OnStart()
  if self.stoped then
    return
  end
  local curTime = os.time()
  local nextEnd = self.endCron:GetNextCron()
  local nextEndDate = os.date("%d-%m-%Y, %H:%M:%S", curTime + nextEnd)
  local err, msg = pcall(self.onStart, nextEndDate)
  if not err then
    main:LogError("Error on start time frame %s", msg)
  end
end

function sTimeFrame:OnEnd()
  if self.stoped then
    return
  end
  local curTime = os.time()
  local nextStart = self.startCron:GetNextCron()
  local nextStartDate = os.date("%d-%m-%Y, %H:%M:%S", curTime + nextStart)
  local err, msg = pcall(self.onEnd, nextStartDate)
  if not err then
    main:LogError("Error on end time frame %s", msg)
  end
end

function sTimeFrame:IsInFrame()
  local previosStart = self.startCron:GetPreviosCron()
  local nextStart = self.startCron:GetNextCron()
  local previosEnd = self.endCron:GetPreviosCron()
  local nextEnd = self.endCron:GetNextCron()
  local curTime = os.time()
  --[[ local previosStartDate = os.date("%d-%m-%Y, %H:%M:%S", curTime + previosStart)
  local nextStartDate = os.date("%d-%m-%Y, %H:%M:%S", curTime + nextStart)
  local previosEndDate = os.date("%d-%m-%Y, %H:%M:%S", curTime + previosEnd)
  local nextEndDate = os.date("%d-%m-%Y, %H:%M:%S", curTime + nextEnd)
  print(previosStart, nextStart, previosEnd, nextEnd)
  print(previosStartDate, nextStartDate, previosEndDate, nextEndDate) ]]
  if curTime + previosStart > curTime + previosEnd then
    return true
  end
  return false
end
