LR = LR or {}

local descriptors = {}
local aliases = {
  none = "standalone",
  qbox = "qbx",
}

local defaultGetResourceState = GetResourceState
local defaultExports = exports
---@diagnostic disable-next-line: undefined-global
local defaultAddEventHandler = AddEventHandler
local defaultRemoveEventHandler = RemoveEventHandler
local defaultRegisterNetEvent = RegisterNetEvent

local function isCallable(value)
  if type(value) == "function" then return true end
  if type(value) ~= "table" then return false end
  local metatable = getmetatable(value)
  return type(metatable) == "table" and type(metatable.__call) == "function"
end

local function createSignal()
  local listeners = {}
  local nextId = 0
  local disposed = false
  local signal = {}

  function signal:Subscribe(callback)
    if disposed then error("framework signal is disposed") end
    if type(callback) ~= "function" then error("framework listener must be a function") end

    nextId = nextId + 1
    local id = nextId
    listeners[id] = callback
    local active = true

    return function()
      if not active then return end
      active = false
      listeners[id] = nil
    end
  end

  function signal:Emit(...)
    if disposed then return end

    local callbacks = {}
    for id = 1, nextId do
      if listeners[id] then callbacks[#callbacks + 1] = listeners[id] end
    end
    local firstError
    for index = 1, #callbacks do
      local ok, err = pcall(callbacks[index], ...)
      if not ok and not firstError then firstError = err end
    end
    if firstError then error(firstError) end
  end

  function signal:Dispose()
    if disposed then return end
    disposed = true
    listeners = {}
  end

  return signal
end

local function asNonEmptyString(value)
  if type(value) == "string" and value ~= "" then return value end
  return nil
end

local function asInteger(value)
  local numberValue = tonumber(value)
  if not numberValue then return nil end
  return math.floor(numberValue)
end

local function normalizeGroup(group)
  if type(group) ~= "table" then return nil end

  local grade = group.grade
  local gradeName = group.grade_name
  local gradeLabel = group.grade_label
  local isBoss = group.isboss == true
  if type(grade) == "table" then
    gradeName = gradeName or grade.name
    gradeLabel = gradeLabel or grade.label
    isBoss = isBoss or grade.isboss == true
    grade = grade.level or grade.grade
  end
  local onDuty
  if type(group.onduty) == "boolean" then
    onDuty = group.onduty
  elseif type(group.onDuty) == "boolean" then
    onDuty = group.onDuty
  end

  return {
    name = asNonEmptyString(group.name),
    label = asNonEmptyString(group.label),
    type = asNonEmptyString(group.type),
    grade = asInteger(grade),
    gradeName = asNonEmptyString(gradeName),
    gradeLabel = asNonEmptyString(gradeLabel),
    onDuty = onDuty,
    isBoss = isBoss,
  }
end

local function normalizePlayer(raw, fallbackSource)
  if type(raw) ~= "table" then return nil end

  local charInfo = type(raw.charinfo) == "table" and raw.charinfo or {}
  local firstName = asNonEmptyString(raw.firstName)
    or asNonEmptyString(raw.firstname)
    or asNonEmptyString(charInfo.firstname)
  local lastName = asNonEmptyString(raw.lastName)
    or asNonEmptyString(raw.lastname)
    or asNonEmptyString(charInfo.lastname)
  local name
  if firstName or lastName then
    name = ((firstName or "") .. " " .. (lastName or "")):match("^%s*(.-)%s*$")
  end
  name = name or asNonEmptyString(raw.name)

  return {
    source = asInteger(raw.source) or asInteger(fallbackSource),
    identifier = asNonEmptyString(raw.identifier) or asNonEmptyString(raw.license),
    citizenId = asNonEmptyString(raw.citizenid),
    name = name,
    firstName = firstName,
    lastName = lastName,
    job = normalizeGroup(raw.job),
    gang = normalizeGroup(raw.gang),
  }
end

local function normalizeNotification(notification)
  if type(notification) ~= "table" then error("framework notification must be a table") end
  local message = asNonEmptyString(notification.message)
  if not message then error("framework notification.message must be a non-empty string") end

  local notificationType = notification.type or "inform"
  if notificationType ~= "inform"
    and notificationType ~= "success"
    and notificationType ~= "warning"
    and notificationType ~= "error" then
    error("framework notification.type is invalid")
  end

  local duration = notification.duration
  if duration ~= nil then
    duration = asInteger(duration)
    if not duration or duration < 1 then
      error("framework notification.duration must be a positive integer")
    end
  end

  return {
    message = message,
    type = notificationType,
    duration = duration,
    title = asNonEmptyString(notification.title),
  }
end

local function createRuntime(options)
  local runtime = {}
  local eventDisposers = {}
  local disposed = false
  local getResourceState = options.getResourceState or defaultGetResourceState
  local exportRoot = options.exports or defaultExports
  local addEventHandler = options.addEventHandler or defaultAddEventHandler
  local removeEventHandler = options.removeEventHandler or defaultRemoveEventHandler
  local registerNetEvent = options.registerNetEvent or defaultRegisterNetEvent

  function runtime:GetResourceState(resourceName)
    if type(getResourceState) ~= "function" then return nil end
    local ok, state = pcall(getResourceState, resourceName)
    if not ok or type(state) ~= "string" then return nil end
    return state
  end

  function runtime:CallExport(resourceName, exportName, ...)
    if type(exportRoot) ~= "table" then
      error("FiveM exports are unavailable for the selected framework")
    end

    local resourceOk, resourceExports = pcall(function()
      return exportRoot[resourceName]
    end)
    if not resourceOk or resourceExports == nil then
      error(("framework export resource %s is unavailable"):format(resourceName))
    end

    local exportOk, exported = pcall(function()
      return resourceExports[exportName]
    end)
    if not exportOk or not isCallable(exported) then
      error(("framework export %s:%s is unavailable"):format(resourceName, exportName))
    end

    local results = table.pack(pcall(exported, resourceExports, ...))
    if not results[1] then
      error(("framework export %s:%s failed: %s"):format(
        resourceName,
        exportName,
        tostring(results[2])
      ))
    end
    return table.unpack(results, 2, results.n)
  end

  function runtime:IsCallable(value)
    return isCallable(value)
  end

  function runtime:Call(callable, ...)
    if not isCallable(callable) then error("framework value is not callable") end
    local results = table.pack(pcall(callable, ...))
    if not results[1] then error(("framework call failed: %s"):format(tostring(results[2]))) end
    return table.unpack(results, 2, results.n)
  end

  function runtime:On(eventName, callback)
    if disposed then error("framework runtime is disposed") end
    if type(eventName) ~= "string" or eventName == "" then
      error("framework event name must be a non-empty string")
    end
    if type(callback) ~= "function" then error("framework event handler must be a function") end
    if type(addEventHandler) ~= "function" then
      error("AddEventHandler is unavailable for the selected framework")
    end

    local active = true
    local token = addEventHandler(eventName, function(...)
      if active then return callback(...) end
    end)
    local removed = false
    local dispose = function()
      if removed then return end
      removed = true
      active = false
      if token ~= nil and type(removeEventHandler) == "function" then
        removeEventHandler(token)
      end
    end
    eventDisposers[#eventDisposers + 1] = dispose
    return dispose
  end

  function runtime:OnNet(eventName, callback)
    if type(registerNetEvent) ~= "function" then
      error("RegisterNetEvent is unavailable for the selected framework")
    end
    registerNetEvent(eventName)
    return self:On(eventName, callback)
  end

  function runtime:CreateSignal()
    return createSignal()
  end

  function runtime:NormalizePlayer(raw, fallbackSource)
    return normalizePlayer(raw, fallbackSource)
  end

  function runtime:NormalizeNotification(notification)
    return normalizeNotification(notification)
  end

  function runtime:Dispose()
    if disposed then return end
    disposed = true
    local firstError
    for index = #eventDisposers, 1, -1 do
      local ok, err = pcall(eventDisposers[index])
      if not ok and not firstError then firstError = err end
    end
    eventDisposers = {}
    if firstError then error(firstError) end
  end

  return runtime
end

local function normalizeName(value)
  if type(value) ~= "string" then return nil end
  local normalized = value:lower()
  return aliases[normalized] or normalized
end

local function resolveSelection(options, runtime)
  local config = options.config
  local name = options.name
  local resourceName = options.resourceName
  if name == nil and type(config) == "string" then
    name = config
  elseif type(config) == "table" then
    name = config.Name or config.name
    resourceName = resourceName or config.Resource or config.resource
  end

  name = normalizeName(name or "standalone")
  if name == "auto" then
    local matches = {}
    for descriptorName, descriptor in pairs(descriptors) do
      if descriptorName ~= "standalone"
        and runtime:GetResourceState(descriptor.resourceName) == "started" then
        matches[#matches + 1] = descriptorName
      end
    end
    table.sort(matches)
    if #matches > 1 then
      error(("framework auto detection is ambiguous: %s"):format(table.concat(matches, ", ")))
    end
    name = matches[1] or "standalone"
  end

  local descriptor = descriptors[name]
  if not descriptor then
    error(("unsupported client framework %s"):format(tostring(name)))
  end

  resourceName = resourceName or descriptor.resourceName
  if descriptor.resourceName
    and runtime:GetResourceState(resourceName) ~= "started" then
    error(("selected client framework %s requires started resource %s"):format(name, resourceName))
  end
  return descriptor, resourceName
end

local function validateBridge(bridge)
  if type(bridge) ~= "table" then error("client framework factory must return a bridge table") end
  local required = {
    "GetPlayerData",
    "IsPlayerLoaded",
    "Notify",
    "OnPlayerLoaded",
    "OnPlayerUnloaded",
    "OnPlayerDataChanged",
  }
  for index = 1, #required do
    if type(bridge[required[index]]) ~= "function" then
      error(("client framework bridge is missing %s"):format(required[index]))
    end
  end
end

---@param descriptor LRClient.FrameworkDescriptor
function LR.RegisterClientFrameworkBridge(descriptor)
  if type(descriptor) ~= "table" then error("client framework descriptor must be a table") end
  local name = normalizeName(descriptor.name)
  if not name or name == "auto" or name == "none" then
    error("client framework descriptor.name is invalid")
  end
  if descriptors[name] then error(("duplicate client framework %s"):format(name)) end
  if type(descriptor.create) ~= "function" then
    error(("client framework %s create must be a function"):format(name))
  end
  if descriptor.resourceName ~= nil
    and (type(descriptor.resourceName) ~= "string" or descriptor.resourceName == "") then
    error(("client framework %s resourceName is invalid"):format(name))
  end

  descriptor.name = name
  descriptors[name] = descriptor
  return descriptor
end

---@param options? LRClient.FrameworkBridgeOptions
---@return LRClient.FrameworkServices
function LR.CreateClientFrameworkServices(options)
  options = options or {}
  local runtime = createRuntime(options)
  local selectionOk, descriptor, resourceName = pcall(resolveSelection, options, runtime)
  if not selectionOk then
    runtime:Dispose()
    error(descriptor)
  end

  local readiness = LR.StandaloneReadinessProvider:new({ ready = descriptor.name == "standalone" })
  local createOk, bridge = pcall(descriptor.create, {
    name = descriptor.name,
    resourceName = resourceName,
    runtime = runtime,
    readiness = readiness,
  })
  if not createOk then
    runtime:Dispose()
    error(bridge)
  end

  local validateOk, validateErr = pcall(validateBridge, bridge)
  if not validateOk then
    runtime:Dispose()
    error(validateErr)
  end

  bridge.name = descriptor.name
  bridge.resourceName = resourceName
  local bridgeDispose = bridge.Dispose
  local disposed = false
  bridge.Dispose = function(self)
    if disposed then return end
    disposed = true
    local bridgeOk, bridgeErr = true, nil
    if type(bridgeDispose) == "function" then
      bridgeOk, bridgeErr = pcall(bridgeDispose, self)
    end
    local runtimeOk, runtimeErr = pcall(function() runtime:Dispose() end)
    if not bridgeOk then error(bridgeErr) end
    if not runtimeOk then error(runtimeErr) end
  end

  return {
    framework = bridge,
    readiness = readiness,
  }
end

---@diagnostic disable-next-line: inject-field
function LR.GetBusinessProcurementPoints()
  local points = {}
  for businessId, business in pairs(Config.BusinessOrders.Businesses or {}) do
    points[#points + 1] = {
      businessId = businessId,
      label = business.label,
      coords = business.orderPoint,
    }
  end
  if type(GetResourceState) == "function" and GetResourceState("cdn-fuel") == "started" then
    local ok, stations = pcall(function()
      return exports["cdn-fuel"]:GetProcurementStations()
    end)
    if ok and type(stations) == "table" then
      for _, station in ipairs(stations) do
        points[#points + 1] = {
          businessId = station.businessId,
          label = station.label,
          coords = vector4(station.x, station.y, station.z, station.h),
        }
      end
    end
  end
  return points
end

LR.RegisterClientFrameworkBridge({
  name = "standalone",
  create = function()
    local bridge = {}

    function bridge:GetPlayerData() return nil end
    function bridge:IsPlayerLoaded() return false end
    function bridge:Notify(_notification) return false end
    function bridge:OnPlayerLoaded(_callback) return function() end end
    function bridge:OnPlayerUnloaded(_callback) return function() end end
    function bridge:OnPlayerDataChanged(_callback) return function() end end

    return bridge
  end,
})
