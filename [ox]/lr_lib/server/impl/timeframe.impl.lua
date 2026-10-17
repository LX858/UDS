---@alias TimeFrameTime {second?: string, minute?: string, hour?: string, day?: string, wday?: string}
---@alias TimeFrameData {startAt: TimeFrameTime, endAt: TimeFrameTime, onStart: fun(), onEnd: fun(), invokingResource: string, id: string, name: string}

---@class SVTimeFrameImpl : Impl
local Impl = NewSyncImpl("TimeFrame")

function Impl:Init()
  AddEventHandler("onResourceStop", function(resource)
    self:OnResourceStopped(resource)
  end)
  self:LogInfo("%s initialized", self:GetName())
  ---@type table<string, sTimeFrame>
  self.timeFrames = {}
end

function Impl:OnReady()
  self:LogInfo("%s ready", self:GetName())
end

function Impl:NewTimeFrame(data)
  local id = GenerateUUID()
  local invokingResource = GetInvokingResource() or GetCurrentResourceName()

  local instance = sTimeFrame({
    id = id,
    startAt = data.startAt,
    endAt = data.endAt,
    invokingResource = invokingResource,
    onStart = data.onStart,
    onEnd = data.onEnd,
    name = data.name
  })
  self.timeFrames[id] = instance
end

function Impl:OnResourceStopped(rsName)
  for id, timeFrame in pairs(self.timeFrames) do
    if timeFrame.invokingResource == rsName then
      timeFrame.stoped = true
      self.timeFrames[id] = nil
    end
  end
end

Impl.start()
