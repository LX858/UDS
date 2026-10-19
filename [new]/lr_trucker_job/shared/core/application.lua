LR = LR or {}

LR.StandaloneReadinessProvider = {}
LR.StandaloneReadinessProvider.__index = LR.StandaloneReadinessProvider

---@param self LRShared.StandaloneReadinessProviderClass
---@param options? { ready?: boolean }
---@return LRShared.StandaloneReadinessProvider
function LR.StandaloneReadinessProvider:new(options)
  ---@type LRShared.StandaloneReadinessProvider
  local instance = setmetatable({}, self)
  options = options or {}
  instance.ready = options.ready ~= false
  instance.callbacks = {}
  return instance
end

---@param self LRShared.StandaloneReadinessProvider
function LR.StandaloneReadinessProvider:IsReady()
  return self.ready
end

---@param self LRShared.StandaloneReadinessProvider
function LR.StandaloneReadinessProvider:WhenReady(callback)
  if type(callback) ~= "function" then
    error("readiness callback must be a function")
  end

  if self.ready then
    callback()
    return function() end
  end

  local entry = { active = true, callback = callback }
  self.callbacks[#self.callbacks + 1] = entry

  return function()
    entry.active = false
  end
end

---@param self LRShared.StandaloneReadinessProvider
function LR.StandaloneReadinessProvider:MarkReady()
  if self.ready then
    return
  end

  self.ready = true
  local callbacks = self.callbacks
  self.callbacks = {}

  for _, entry in ipairs(callbacks) do
    if entry.active then
      entry.callback()
    end
  end
end

LR.Scheduler = {}
LR.Scheduler.__index = LR.Scheduler

---@param self LRShared.SchedulerClass
---@param options? LRShared.SchedulerOptions
---@return LRShared.Scheduler
function LR.Scheduler:new(options)
  ---@type LRShared.Scheduler
  local instance = setmetatable({}, self)
  options = options or {}
  instance.setTimeout = options.setTimeout
  instance.clearTimeout = options.clearTimeout
  return instance
end

---@param self LRShared.Scheduler
function LR.Scheduler:Delay(milliseconds, callback)
  if type(self.setTimeout) == "function" then
    return self.setTimeout(milliseconds, callback)
  end

  callback()
  return nil
end

---@param self LRShared.Scheduler
function LR.Scheduler:Cancel(timer)
  if timer and type(self.clearTimeout) == "function" then
    self.clearTimeout(timer)
  end
end

LR.Application = {}
LR.Application.__index = LR.Application

---@param self LRShared.ApplicationClass
---@param options? LRShared.ApplicationOptions
---@return LRShared.Application
function LR.Application:new(options)
  options = options or {}

  ---@type LRShared.Application
  local instance = setmetatable({}, self)
  instance.name = options.name or "lr"
  instance.side = options.side or "shared"
  instance.resourceName = options.resourceName or instance.name
  instance.logger = options.logger or LR.Logger:new({ prefix = instance.name, debug = options.debug == true })
  instance.registry = options.registry or LR.ModuleRegistry:new()
  instance.started = {}
  instance.activeModules = {}
  instance.instances = {}
  instance.moduleContexts = {}
  instance.playerStarted = false
  instance.stopped = true
  instance.services = options.services or {}
  instance.serviceOrder = options.serviceOrder or {}
  instance.globalServices = {}
  if #instance.serviceOrder == 0 then
    for name in pairs(instance.services) do
      instance.serviceOrder[#instance.serviceOrder + 1] = name
    end
    table.sort(instance.serviceOrder)
  end
  instance.servicesDisposed = false
  if options.scheduler and instance.services.scheduler and options.scheduler ~= instance.services.scheduler then
    error("scheduler option conflicts with services.scheduler")
  end
  if options.readiness and instance.services.readiness and options.readiness ~= instance.services.readiness then
    error("readiness option conflicts with services.readiness")
  end
  instance.scheduler = options.scheduler or instance.services.scheduler or LR.Scheduler:new(options.schedulerOptions)
  instance.readiness = options.readiness or instance.services.readiness or LR.StandaloneReadinessProvider:new()
  instance.readinessDisposer = nil

  if not instance.services.scheduler then
    instance:RegisterService("scheduler", instance.scheduler)
  end
  if not instance.services.readiness then
    instance:RegisterService("readiness", instance.readiness)
  end

  return instance
end

---@param self LRShared.Application
function LR.Application:RegisterModule(descriptor)
  return self.registry:Register(descriptor)
end

---@param self LRShared.Application
function LR.Application:RegisterService(name, service)
  LR.assertName(name, "service.name")
  if service == nil then
    error(("service %s is nil"):format(name))
  end
  if self.services[name] then
    error(("Duplicate service %s"):format(name))
  end
  self.services[name] = service
  self.serviceOrder[#self.serviceOrder + 1] = name
  self.servicesDisposed = false
  return service
end

---@param self LRShared.Application
function LR.Application:RegisterGlobalService(name, globalName, service)
  self:RegisterService(name, service)
  LR.assertName(globalName, "global service name")
  LR[globalName] = service
  self.globalServices[name] = {
    key = globalName,
    service = service,
  }
  return service
end

---@param self LRShared.Application
function LR.Application:GetService(name)
  return self.services[name]
end

---@param self LRShared.Application
function LR.Application:HasService(name)
  return self.services[name] ~= nil
end

---@generic T : LRShared.ModuleInstance
---@param self LRShared.Application
---@param id string
---@return T
function LR.Application:GetModule(id)
  self.registry:ValidateId(id)
  local instance = self.instances[id]
  if not instance then
    error(("module %s is not available"):format(id))
  end
  if not self.activeModules[id] then
    error(("module %s is not ready"):format(id))
  end
  return instance
end

---@param self LRShared.Application
function LR.Application:DisposeService(service)
  if type(service) == "table" and type(service.Dispose) == "function" then
    service:Dispose()
  end
end

---@param self LRShared.Application
function LR.Application:ClearGlobalService(name)
  local binding = self.globalServices[name]
  if not binding then
    return
  end

  if LR[binding.key] == binding.service then
    LR[binding.key] = nil
  end
end

---@param self LRShared.Application
function LR.Application:DisposeServices()
  if self.servicesDisposed then
    return
  end

  self.servicesDisposed = true
  local firstError = nil

  for index = #self.serviceOrder, 1, -1 do
    local name = self.serviceOrder[index]
    local service = self.services[name]
    local disposeOk, disposeErr = pcall(function()
      self:DisposeService(service)
    end)
    if not disposeOk and not firstError then
      firstError = disposeErr
    end

    local clearOk, clearErr = pcall(function()
      self:ClearGlobalService(name)
    end)
    if not clearOk and not firstError then
      firstError = clearErr
    end
  end

  if firstError then
    error(firstError)
  end
end

---@param self LRShared.Application
function LR.Application:CreateModuleContext(descriptor)
  local app = self
  local modules = setmetatable({}, {
    __index = function(_, id)
      return app:GetModule(id)
    end,
    __newindex = function()
      error("module map is read-only")
    end,
  })
  return {
    app = self,
    descriptor = descriptor,
    id = descriptor.id,
    side = self.side,
    resourceName = self.resourceName,
    logger = self.logger:Child(descriptor.id),
    scheduler = self.scheduler,
    disposables = LR.DisposableStack:new(),
    services = self.services,
    nui = self.services.nui,
    net = self.services.net,
    public = self.services.public,
    external = self.services.external,
    modules = modules,
    GetModule = function(_, id)
      return app:GetModule(id)
    end,
  }
end

---@param self LRShared.Application
function LR.Application:CreateModule(descriptor)
  local context = self:CreateModuleContext(descriptor)
  local instance = descriptor.create(context)
  if type(instance) ~= "table" then
    error(("module %s create must return an instance table"):format(descriptor.id))
  end

  self.instances[descriptor.id] = instance
  self.moduleContexts[descriptor.id] = context
  return instance, context
end

---@param self LRShared.Application
function LR.Application:StartModule(descriptor)
  local instance = self.instances[descriptor.id]
  local context = self.moduleContexts[descriptor.id]
  if not instance or not context then
    error(("module %s must be created before Start"):format(descriptor.id))
  end
  self.logger:Info("Starting module %s", descriptor.id)

  if type(instance.Start) == "function" then
    instance:Start(context)
  end

  self.logger:Info("Started module %s", descriptor.id)
end

---@param self LRShared.Application
function LR.Application:ReadyModule(descriptor)
  local instance = self.instances[descriptor.id]
  local context = self.moduleContexts[descriptor.id]
  if not instance or not context then
    error(("module %s must be created before OnReady"):format(descriptor.id))
  end

  self.logger:Info("Preparing module %s", descriptor.id)
  self.activeModules[descriptor.id] = true
  if type(instance.OnReady) == "function" then
    instance:OnReady(context)
  end
  self.logger:Info("Prepared module %s", descriptor.id)
end

---@param self LRShared.Application
function LR.Application:StartMatchingModules(predicate)
  local orderedDescriptors = self.registry:ResolveStartOrder()
  local pending = {}

  for _, descriptor in ipairs(orderedDescriptors) do
    if predicate(descriptor) and not self.instances[descriptor.id] then
      self:CreateModule(descriptor)
      self.started[#self.started + 1] = descriptor
      pending[#pending + 1] = descriptor
    end
  end

  for _, descriptor in ipairs(pending) do
    self:ReadyModule(descriptor)
  end

  for _, descriptor in ipairs(pending) do
    self:StartModule(descriptor)
  end
end

---@param self LRShared.Application
function LR.Application:StartPlayerModules()
  if self.playerStarted or self.stopped then
    return
  end

  self.playerStarted = true

  local ok, err = pcall(function()
    self:StartMatchingModules(function(descriptor)
      return descriptor.start == "player"
    end)
  end)

  if not ok then
    local cleanupOk, cleanupErr = pcall(function()
      self:Stop()
    end)

    if cleanupOk then
      error(err)
    end

    error(("%s | cleanup_error: %s"):format(tostring(err), tostring(cleanupErr)))
  end
end

---@param self LRShared.Application
function LR.Application:Start()
  if not self.stopped then
    return
  end

  self.stopped = false
  self.playerStarted = false

  local ok, err = pcall(function()
    self:StartMatchingModules(function(descriptor)
      return descriptor.start == "resource"
    end)

    if self.readiness:IsReady() then
      self:StartPlayerModules()
    else
      self.readinessDisposer = self.readiness:WhenReady(function()
        self:StartPlayerModules()
      end)
    end
  end)

  if not ok then
    local cleanupOk, cleanupErr = pcall(function()
      self:Stop()
    end)

    if cleanupOk then
      error(err)
    end

    error(("%s | cleanup_error: %s"):format(tostring(err), tostring(cleanupErr)))
  end
end

---@param self LRShared.Application
function LR.Application:Stop()
  if self.stopped then
    return
  end

  local firstError = nil

  if self.readinessDisposer then
    local ok, err = pcall(self.readinessDisposer)
    if not ok and not firstError then
      firstError = err
    end
    self.readinessDisposer = nil
  end

  for index = #self.started, 1, -1 do
    local descriptor = self.started[index]
    local instance = self.instances[descriptor.id]
    local context = self.moduleContexts[descriptor.id]
    self.logger:Info("Stopping module %s", descriptor.id)

    if self.activeModules[descriptor.id] and type(instance.Stop) == "function" then
      local stopOk, stopErr = pcall(function()
        instance:Stop(context)
      end)
      if not stopOk and not firstError then
        firstError = stopErr
      end
    end

    if context then
      local disposeOk, disposeErr = pcall(function()
        context.disposables:DisposeAll()
      end)
      if not disposeOk and not firstError then
        firstError = disposeErr
      end
    end
  end

  local servicesOk, servicesErr = pcall(function()
    self:DisposeServices()
  end)

  if not servicesOk and not firstError then
    firstError = servicesErr
  end

  self.started = {}
  self.activeModules = {}
  self.instances = {}
  self.moduleContexts = {}
  self.playerStarted = false
  self.stopped = true

  if firstError then
    error(firstError)
  end
end

---@param self LRShared.Application
function LR.Application:IsStopped()
  return self.stopped
end

---@param options? LRShared.ApplicationOptions
---@return LRShared.Application
function LR.CreateApplication(options)
  return LR.Application:new(options)
end
