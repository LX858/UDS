LR = LR or {}

LR.MODULE_ID_PATTERN = "^[a-z][a-z0-9_]*$"

LR.ModuleRegistry = {}
LR.ModuleRegistry.__index = LR.ModuleRegistry

---@param self LRShared.ModuleRegistryClass
---@return LRShared.ModuleRegistry
function LR.ModuleRegistry:new()
  ---@type LRShared.ModuleRegistry
  local instance = setmetatable({}, self)
  instance.descriptors = {}
  instance.order = {}
  return instance
end

---@param self LRShared.ModuleRegistry
function LR.ModuleRegistry:ValidateId(id)
  if type(id) ~= "string" or not id:match(LR.MODULE_ID_PATTERN) then
    error("module id must match ^[a-z][a-z0-9_]*$")
  end
end

---@param self LRShared.ModuleRegistry
function LR.ModuleRegistry:ValidateDescriptor(descriptor)
  if type(descriptor) ~= "table" then
    error("module descriptor must be a table")
  end

  self:ValidateId(descriptor.id)

  if descriptor.start ~= nil and descriptor.start ~= "resource" and descriptor.start ~= "player" then
    error(("module %s start must be resource or player"):format(descriptor.id))
  end

  if descriptor.dependencies ~= nil and type(descriptor.dependencies) ~= "table" then
    error(("module %s dependencies must be a table"):format(descriptor.id))
  end

  if type(descriptor.create) ~= "function" then
    error(("module %s create must be a function"):format(descriptor.id))
  end
end

---@param self LRShared.ModuleRegistry
function LR.ModuleRegistry:Register(descriptor)
  self:ValidateDescriptor(descriptor)

  if self.descriptors[descriptor.id] then
    error(("Duplicate module %s"):format(descriptor.id))
  end

  local normalized = {
    id = descriptor.id,
    start = descriptor.start or "resource",
    dependencies = {},
    create = descriptor.create,
  }
  for index, dependencyId in ipairs(descriptor.dependencies or {}) do
    self:ValidateId(dependencyId)
    normalized.dependencies[index] = dependencyId
  end
  self.descriptors[normalized.id] = normalized
  self.order[#self.order + 1] = normalized.id
  return normalized
end

---@param self LRShared.ModuleRegistry
function LR.ModuleRegistry:Get(id)
  return self.descriptors[id]
end

---@param self LRShared.ModuleRegistry
function LR.ModuleRegistry:Descriptors()
  local descriptors = {}
  for index, id in ipairs(self.order) do
    descriptors[index] = self.descriptors[id]
  end
  return descriptors
end

---@param self LRShared.ModuleRegistry
function LR.ModuleRegistry:ResolveStartOrder()
  local sorted = {}
  local visiting = {}
  local visited = {}

  local function visit(id, chain)
    if visited[id] then
      return
    end

    if visiting[id] then
      error(("Cycle detected in module dependencies: %s -> %s"):format(table.concat(chain, " -> "), id))
    end

    local descriptor = self.descriptors[id]
    if not descriptor then
      error(("Missing dependency %s"):format(id))
    end

    visiting[id] = true
    chain[#chain + 1] = id

    for _, dependencyId in ipairs(descriptor.dependencies or {}) do
      local dependency = self.descriptors[dependencyId]
      if not dependency then
        error(("Missing dependency %s required by %s"):format(dependencyId, id))
      end
      if descriptor.start == "resource" and dependency.start == "player" then
        error(("resource module %s cannot depend on player module %s"):format(id, dependencyId))
      end
      visit(dependencyId, LR.shallowCopy(chain))
    end

    visiting[id] = nil
    visited[id] = true
    sorted[#sorted + 1] = descriptor
  end

  for _, id in ipairs(self.order) do
    visit(id, {})
  end

  return sorted
end

local function composeModuleParts(sharedDescriptor, sideDescriptor)
  local first = sharedDescriptor or sideDescriptor
  if not first then error("module composition requires at least one descriptor") end
  if sharedDescriptor and sideDescriptor and sharedDescriptor.start ~= sideDescriptor.start then
    error(("module %s parts must use the same start phase"):format(first.id))
  end

  local parts = {}
  if sharedDescriptor then parts[#parts + 1] = sharedDescriptor end
  if sideDescriptor then parts[#parts + 1] = sideDescriptor end
  local dependencies = {}
  local seenDependencies = {}
  for _, descriptor in ipairs(parts) do
    for _, dependencyId in ipairs(descriptor.dependencies or {}) do
      if not seenDependencies[dependencyId] then
        seenDependencies[dependencyId] = true
        dependencies[#dependencies + 1] = dependencyId
      end
    end
  end

  return {
    id = first.id,
    start = first.start,
    dependencies = dependencies,
    create = function(context)
      local instances = {}
      for _, descriptor in ipairs(parts) do
        local instance = descriptor.create(context)
        if type(instance) ~= "table" then
          error(("module %s part create must return an instance table"):format(first.id))
        end
        instances[#instances + 1] = instance
      end
      local composite = { readyCount = 0 }
      local apiOwners = {}
      ---@type table<string, function>
      local api = {}

      for _, instance in ipairs(instances) do
        for name, member in pairs(instance) do
          if type(member) == "function" and name ~= "OnReady" and name ~= "Start" and name ~= "Stop" then
            if apiOwners[name] then
              error(("module %s parts expose duplicate method %s"):format(first.id, name))
            end
            apiOwners[name] = instance
            local owner = instance
            local method = member
            api[name] = function(_, ...)
              return method(owner, ...)
            end
          end
        end
      end

      function composite:OnReady(readyContext)
        for index, instance in ipairs(instances) do
          self.readyCount = index
          if type(instance.OnReady) == "function" then instance:OnReady(readyContext) end
        end
      end

      function composite:Start(startContext)
        for _, instance in ipairs(instances) do
          if type(instance.Start) == "function" then instance:Start(startContext) end
        end
      end

      function composite:Stop(stopContext)
        local firstError = nil
        for index = self.readyCount, 1, -1 do
          local instance = instances[index]
          if type(instance.Stop) == "function" then
            local ok, err = pcall(function() instance:Stop(stopContext) end)
            if not ok and not firstError then firstError = err end
          end
        end
        self.readyCount = 0
        if firstError then error(firstError) end
      end

      return setmetatable(composite, { __index = api })
    end,
  }
end

---@param sharedRegistry LRShared.ModuleRegistry
---@param sideRegistry LRShared.ModuleRegistry
---@param isEnabled? fun(id: string): boolean
---@return LRShared.ModuleRegistry
function LR.CreateSideModuleRegistry(sharedRegistry, sideRegistry, isEnabled)
  local output = LR.ModuleRegistry:new()
  local sharedById = {}
  local sideById = {}
  local orderedIds = {}
  local seenIds = {}

  local function collect(registry, target)
    for _, descriptor in ipairs(registry:Descriptors()) do
      target[descriptor.id] = descriptor
      if not seenIds[descriptor.id] then
        seenIds[descriptor.id] = true
        orderedIds[#orderedIds + 1] = descriptor.id
      end
    end
  end

  collect(sharedRegistry, sharedById)
  collect(sideRegistry, sideById)
  for _, id in ipairs(orderedIds) do
    if not isEnabled or isEnabled(id) then
      output:Register(composeModuleParts(sharedById[id], sideById[id]))
    end
  end
  return output
end

LR.SharedModules = LR.SharedModules or LR.ModuleRegistry:new()
LR.Modules = LR.SharedModules
