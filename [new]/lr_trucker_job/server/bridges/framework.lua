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
  local getEventSource = options.getEventSource or function() return source end

  function runtime:GetResourceState(resourceName)
    if type(getResourceState) ~= "function" then return nil end
    local ok, state = pcall(getResourceState, resourceName)
    if not ok or type(state) ~= "string" then return nil end
    return state
  end

  function runtime:GetEventSource()
    if type(getEventSource) ~= "function" then return nil end
    local ok, value = pcall(getEventSource)
    if not ok then return nil end
    return asInteger(value)
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
    error(("unsupported server framework %s"):format(tostring(name)))
  end

  resourceName = resourceName or descriptor.resourceName
  if descriptor.resourceName
    and runtime:GetResourceState(resourceName) ~= "started" then
    error(("selected server framework %s requires started resource %s"):format(name, resourceName))
  end
  return descriptor, resourceName
end

local function validateBridge(bridge)
  if type(bridge) ~= "table" then error("server framework factory must return a bridge table") end
  local required = {
    "GetPlayer",
    "IsPlayerLoaded",
    "Notify",
    "OnPlayerLoaded",
    "OnPlayerUnloaded",
    "OnPlayerDataChanged",
  }
  for index = 1, #required do
    if type(bridge[required[index]]) ~= "function" then
      error(("server framework bridge is missing %s"):format(required[index]))
    end
  end
end

---@param descriptor LRServer.FrameworkDescriptor
function LR.RegisterServerFrameworkBridge(descriptor)
  if type(descriptor) ~= "table" then error("server framework descriptor must be a table") end
  local name = normalizeName(descriptor.name)
  if not name or name == "auto" or name == "none" then
    error("server framework descriptor.name is invalid")
  end
  if descriptors[name] then error(("duplicate server framework %s"):format(name)) end
  if type(descriptor.create) ~= "function" then
    error(("server framework %s create must be a function"):format(name))
  end
  if descriptor.resourceName ~= nil
    and (type(descriptor.resourceName) ~= "string" or descriptor.resourceName == "") then
    error(("server framework %s resourceName is invalid"):format(name))
  end

  descriptor.name = name
  descriptors[name] = descriptor
  return descriptor
end

---@param options? LRServer.FrameworkBridgeOptions
---@return LRServer.FrameworkServices
function LR.CreateServerFrameworkServices(options)
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

---@param resourceName? string
---@return table
function LR.CreateDatabaseBridge(resourceName)
  resourceName = resourceName or "oxmysql"
  local bridge = {}

  local function invoke(method, ...)
    local resourceExports = defaultExports[resourceName]
    if resourceExports == nil then error(("database resource %s is unavailable"):format(resourceName)) end
    local exported = resourceExports[method]
    if not isCallable(exported) then
      error(("database export %s:%s is unavailable"):format(resourceName, method))
    end
    return exported(resourceExports, ...)
  end

  function bridge:Query(query, parameters)
    return invoke("query_async", query, parameters or {})
  end

  function bridge:Single(query, parameters)
    return invoke("single_async", query, parameters or {})
  end

  function bridge:Update(query, parameters)
    return invoke("update_async", query, parameters or {})
  end

  function bridge:Transaction(queries)
    return invoke("transaction_async", queries)
  end

  return bridge
end

-- Narrow optional integrations used by business procurement. Keeping every raw
-- external export here makes service code testable and allows the trucker job to
-- keep running when an integration is stopped.
---@diagnostic disable-next-line: inject-field
function LR.CreateBusinessIntegrationBridge()
  local bridge = {}
  local failures = {}

  local function reportFailure(resourceName, method, reason)
    local key = resourceName .. ":" .. method
    local now = type(GetGameTimer) == "function" and GetGameTimer() or math.floor(os.clock() * 1000)
    local previous = failures[key]
    local detail = tostring(reason):gsub("[\r\n]+", " "):sub(1, 1200)
    if not previous or previous.detail ~= detail or now - previous.at >= 30000 then
      print(("[lr_trucker_job:integration] %s failed: %s"):format(key, detail))
      failures[key] = { at = now, detail = detail }
    end
  end

  local function started(resourceName)
    return type(GetResourceState) == "function" and GetResourceState(resourceName) == "started"
  end

  local function call(resourceName, method, ...)
    -- FiveM can throw while resolving exports[resource][method], before invocation.
    -- Protect both operations so an optional provider cannot break the NUI RPC.
    local results = table.pack(pcall(function(...)
      local state = type(GetResourceState) == "function" and GetResourceState(resourceName) or "unknown"
      if state ~= "started" then error("RESOURCE_NOT_STARTED: " .. tostring(state), 0) end
      local resource = exports[resourceName]
      local exported = resource and resource[method]
      if not isCallable(exported) then error("EXPORT_UNAVAILABLE: " .. method, 0) end
      return exported(resource, ...)
    end, ...))
    if not results[1] then
      reportFailure(resourceName, method, results[2])
      return false, results[2]
    end
    return true, table.unpack(results, 2, results.n)
  end

  function bridge:IsSourceOnline()
    return started("xn-sellitem")
  end

  function bridge:IsBusinessEnabled(_businessId)
    local ok, enabled = call("xn_banhnuoc", "IsTruckerjobEnabled")
    return ok and enabled == true
  end

  function bridge:IsFuelEnabled()
    local ok, enabled = call("cdn-fuel", "IsTruckerjobEnabled")
    return ok and enabled == true
  end

  function bridge:ReleaseNpcHolds()
    local ok, result = call("xn-sellitem", "ReleaseNpcDeliveryReservations")
    return ok and type(result) == "table" and result.success == true
  end

  function bridge:GetCatalog()
    local ok, catalog = call("xn-sellitem", "GetBusinessDeliveryCatalog")
    if ok and type(catalog) ~= "table" then
      reportFailure("xn-sellitem", "GetBusinessDeliveryCatalog", "INVALID_CATALOG: " .. type(catalog))
    elseif ok then
      failures["xn-sellitem:GetBusinessDeliveryCatalog"] = nil
    end
    return ok and type(catalog) == "table" and catalog or nil
  end

  function bridge:ReserveLine(reservationId, itemName, amount)
    local ok, result = call("xn-sellitem", "ReserveCleanDelivery", {
      reservationId = reservationId,
      itemName = itemName,
      amount = amount,
    })
    if not ok then return false, "SOURCE_UNAVAILABLE" end
    if type(result) ~= "table" then return false, "SOURCE_PROTOCOL_ERROR" end
    if result.success == true then return true, "" end
    local reason = tostring(result.error or "")
    return false, reason ~= "" and reason or "RESERVATION_REJECTED"
  end

  function bridge:SettleLine(reservationId, delivered)
    local ok, result = call("xn-sellitem", "SettleCleanDelivery", {
      reservationId = reservationId,
      delivered = delivered == true,
    })
    return ok and type(result) == "table" and result.success == true,
      type(result) == "table" and tostring(result.error or "") or "SOURCE_UNAVAILABLE"
  end

  function bridge:GetSocietyBalance(account)
    local ok, amount = call("Renewed-Banking", "getAccountMoney", account)
    return ok and math.max(0, math.floor(tonumber(amount) or 0)) or nil
  end

  function bridge:DebitSociety(account, amount)
    local ok, result = call("Renewed-Banking", "removeAccountMoney", account, amount)
    return ok and result == true
  end

  function bridge:RefundSociety(account, amount)
    local ok, result = call("Renewed-Banking", "addAccountMoney", account, amount)
    return ok and result == true
  end

  function bridge:GetFuelStations()
    local ok, stations = call("cdn-fuel", "GetProcurementStations")
    return ok and type(stations) == "table" and stations or {}
  end

  function bridge:GetFuelContext(playerSource, location)
    local ok, context = call("cdn-fuel", "GetProcurementContext", {
      source = playerSource,
      location = location,
    })
    return ok and type(context) == "table" and context or nil
  end

  function bridge:DebitFuel(playerSource, location, orderId, amount)
    local ok, result = call("cdn-fuel", "DebitProcurementOrder", {
      source = playerSource,
      location = location,
      orderId = orderId,
      amount = amount,
    })
    return ok and result == true
  end

  function bridge:RefundFuel(location, orderId)
    local ok, result = call("cdn-fuel", "RefundProcurementOrder", {
      location = location,
      orderId = orderId,
    })
    return ok and result == true
  end

  function bridge:CreditFuel(location, orderId, deliveryId, liters)
    local ok, result, reason = call("cdn-fuel", "CreditProcurementDelivery", {
      location = location,
      orderId = orderId,
      deliveryId = deliveryId,
      liters = liters,
    })
    return ok and result == true, tostring(reason or "")
  end

  function bridge:CanCarryStash(stashId, itemName, amount, metadata)
    local ok, result = call("ox_inventory", "CanCarryItem", stashId, itemName, amount, metadata)
    return ok and result == true
  end

  function bridge:CanCarryStashBasket(stashId, lines)
    local ok, inventory = call("ox_inventory", "GetInventory", stashId)
    if not ok or type(inventory) ~= "table" or type(inventory.items) ~= "table"
      or not inventory.slots or not inventory.maxWeight or not inventory.weight then return false end
    local weight, neededSlots, occupied = inventory.weight, 0, 0
    for _, slot in pairs(inventory.items) do if slot and slot.count > 0 then occupied = occupied + 1 end end
    for _, line in ipairs(lines) do
      if line.destinationUnit ~= "item" or not line.destinationItemId or line.destinationItemId == "" then return false end
      local found, item = call("ox_inventory", "Items", line.destinationItemId)
      local amount = line.destinationAmount
      if not found or type(item) ~= "table" or type(item.weight) ~= "number"
        or type(amount) ~= "number" or amount < 1 or amount > 1000000 or amount % 1 ~= 0 then return false end
      -- Each line has unique delivery metadata, so it cannot reuse existing stacks.
      neededSlots = neededSlots + (item.stack and 1 or amount)
      weight = weight + item.weight * amount
    end
    return occupied + neededSlots <= inventory.slots and weight <= inventory.maxWeight
  end

  function bridge:AddStashItem(stashId, itemName, amount, metadata)
    local ok, result = call("ox_inventory", "AddItem", stashId, itemName, amount, metadata)
    return ok and result == true
  end

  function bridge:HasStashDelivery(stashId, itemName, deliveryId)
    local ok, slots = call("ox_inventory", "Search", stashId, "slots", itemName, {
      deliveryId = deliveryId,
    })
    return ok and type(slots) == "table" and next(slots) ~= nil
  end

  return bridge
end

LR.RegisterServerFrameworkBridge({
  name = "standalone",
  create = function()
    local bridge = {}

    function bridge:GetPlayer(_source) return nil end
    function bridge:IsPlayerLoaded(_source) return false end
    function bridge:Notify(_source, _notification) return false end
    function bridge:OnPlayerLoaded(_callback) return function() end end
    function bridge:OnPlayerUnloaded(_callback) return function() end end
    function bridge:OnPlayerDataChanged(_callback) return function() end end

    return bridge
  end,
})
