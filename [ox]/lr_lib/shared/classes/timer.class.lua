---@class cTimer
cTimer = class()

function cTimer:Init(playerSrc)
  self.source = playerSrc
  self.initTime = GetGameTimer()
  self.passedTime = 0
  self.destroyed = false
  ---@type table<string, {time: number, handler: function, invokingResource: string}>
  self.onWhenHandlers = {}
  ---@type table<string, {handler: function, invokingResource: string}>
  self.onTickHandlers = {}
  ---@type table<string, {time: number, handler: function, invokingResource: string}>
  self.onEveryHandlers = {}
  self:MainThread()
end

function cTimer:Destroy()
  self.destroyed = true
end

function cTimer:MainThread()
  Citizen.CreateThread(function()
    local delayTime = 1000
    local last = 0
    while not self.destroyed do
      Wait(delayTime)
      local passedTime = GetGameTimer() - self.initTime
      local offset = passedTime - last - 1000
      delayTime = delayTime - offset
      last = passedTime
      self.passedTime = math.floor(passedTime / 1000)
      Citizen.CreateThread(function()
        for id, handler in pairs(self.onWhenHandlers) do
          if handler.time == self.passedTime then
            local status, err = pcall(handler.handler, self.source, self.passedTime, id)
            if not status then
              print(err)
            end
            self.onWhenHandlers[id] = nil
          end
        end
        for id, handler in pairs(self.onTickHandlers) do
          local status, err = pcall(handler.handler, self.source, self.passedTime, id)
          if not status then
            print(err)
          end
        end
        for id, data in pairs(self.onEveryHandlers) do
          local surplus = self.passedTime % data.time
          if surplus == 0 then
            local status, err = pcall(data.handler, self.source, self.passedTime, id)
            if not status then
              print(err)
            end
          end
        end
      end)
    end
  end)
end

function cTimer:OnTick(invokingResource, handler)
  local id = GenerateUUID()
  self.onTickHandlers[id] = { handler = handler, invokingResource = invokingResource }
  return id
end

function cTimer:OffTick(id)
  self.onTickHandlers[id] = nil
end

function cTimer:OnWhen(invokingResource, time, handler)
  local id = GenerateUUID()
  self.onWhenHandlers[id] = { time = time, handler = handler, invokingResource = invokingResource }
  return id
end

function cTimer:OffWhen(id)
  self.onWhenHandlers[id] = nil
end

function cTimer:OnEvery(invokingResource, time, handler)
  local id = GenerateUUID()
  self.onEveryHandlers[id] = { time = time, handler = handler, invokingResource = invokingResource }
  return id
end

function cTimer:OffEvery(id)
  self.onEveryHandlers[id] = nil
end

function cTimer:OnResourceStopped(resourceName)
  for k, v in pairs(self.onEveryHandlers) do
    if v.invokingResource == resourceName then
      self.onEveryHandlers[k] = nil
    end
  end
  for k, v in pairs(self.onTickHandlers) do
    if v.invokingResource == resourceName then
      self.onTickHandlers[k] = nil
    end
  end
  for k, v in pairs(self.onWhenHandlers) do
    if v.invokingResource == resourceName then
      self.onWhenHandlers[k] = nil
    end
  end
end
