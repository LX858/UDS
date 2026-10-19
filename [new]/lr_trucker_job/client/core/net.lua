LR = LR or {}

local VERSION = 1
local DEFAULT_TIMEOUT = 10000
local MAX_TIMEOUT = 30000
local DEFAULT_MAX_PAYLOAD = 128 * 1024

local function noop() end
local function defaultLogger() return { Debug = noop, Info = noop, Warn = noop, Error = noop } end
---@diagnostic disable-next-line: undefined-global
local addEventHandler = AddEventHandler

local function assertModuleName(name)
  if type(name) ~= "string" or not name:match("^[a-z][a-z0-9_]*$") then
    error("module name must match ^[a-z][a-z0-9_]*$")
  end
end

local function assertMemberName(name)
  if type(name) ~= "string" or not name:match("^[A-Za-z][A-Za-z0-9_]*$") then
    error("contract member name is invalid")
  end
end

local ENVELOPE_KEYS = {
  version = true, kind = true, module = true, name = true,
  requestId = true, payload = true, error = true,
}

local function validEnvelopeShape(envelope)
  for key in pairs(envelope) do
    if not ENVELOPE_KEYS[key] then return false end
  end
  if envelope.error ~= nil then
    if type(envelope.error) ~= "table" or type(envelope.error.code) ~= "string" or #envelope.error.code > 64 then
      return false
    end
    if envelope.error.message ~= nil and (type(envelope.error.message) ~= "string" or #envelope.error.message > 512) then
      return false
    end
  end
  return true
end

local function pascalCase(name)
  return (name:gsub("^%l", string.upper):gsub("_([a-z])", function(letter) return letter:upper() end))
end

local function validate(validator, value, label)
  if type(validator) ~= "function" then error(label .. " validator is missing") end
  local ok, valid, detail = pcall(validator, value)
  if not ok or valid ~= true then
    error(label .. " validation failed" .. (detail and (": " .. tostring(detail)) or ""))
  end
end

local function safeCallback(logger, callback, ...)
  if type(callback) ~= "function" then return true end
  local ok = pcall(callback, ...)
  if not ok then logger:Error("Network callback failed") end
  return ok
end

local function fallbackSizeOf(value)
  if json and type(json.encode) == "function" then
    local ok, encoded = pcall(json.encode, value)
    if ok then return #encoded end
    error("JSON encoding failed")
  end
  error("JSON encoder is unavailable")
end

local function defaultRegisterEvent(name, handler)
  RegisterNetEvent(name)
  local token = addEventHandler(name, function(envelope)
    -- FiveM injects this event-origin sentinel dynamically. Read it without
    -- declaring the server-only `source` global in the client LuaLS workspace.
    if rawget(_G, "source") ~= 65535 then return end
    handler(envelope)
  end)
  if token and type(RemoveEventHandler) == "function" then
    return function() RemoveEventHandler(token) end
  end
  return noop
end

local function defaultEmitServer(name, envelope)
  TriggerServerEvent(name, envelope)
end

local function defaultSchedule(milliseconds, callback)
  return SetTimeout(milliseconds, callback)
end

local function defaultCancel(timer)
  if timer and type(ClearTimeout) == "function" then ClearTimeout(timer) end
end

local ClientNet = {}
ClientNet.__index = ClientNet

function ClientNet:_guard(payload)
  local size = self.sizeOf(payload)
  if type(size) ~= "number" or size < 0 then error("payload size calculation failed") end
  if size > self.maxPayload then error(("payload exceeds %d bytes"):format(self.maxPayload)) end
end

function ClientNet:_nextRequestId()
  self.counter = self.counter + 1
  return ("%s-%d"):format(self.sessionSalt, self.counter)
end

function ClientNet:_notify(subscribers, payload)
  for _, callback in pairs(subscribers) do
    local ok = pcall(callback, payload)
    if not ok then self.logger:Error("Network subscriber failed") end
  end
end

function ClientNet:_makeIncomingEvent(moduleRuntime, name, spec)
  assertMemberName(name)
  if moduleRuntime.events[name] then error("duplicate network event endpoint: " .. name) end
  local subscribers, counter = {}, 0
  local endpoint = {}
  function endpoint:On(callback)
    if self.transport.disposed then error("network transport is disposed") end
    if type(callback) ~= "function" then error("event subscriber must be a function") end
    counter = counter + 1
    local id = counter
    subscribers[id] = callback
    return function() subscribers[id] = nil end
  end
  endpoint._dispatch = function(payload)
    validate(spec.validate, payload, ("event %s.%s payload"):format(moduleRuntime.name, name))
    self:_notify(subscribers, payload)
  end
  endpoint.transport = self
  moduleRuntime.events[name] = endpoint
  moduleRuntime.incomingEvents[name] = endpoint
end

function ClientNet:_makeOutgoingEvent(moduleRuntime, name, spec)
  assertMemberName(name)
  if moduleRuntime.events[name] then error("duplicate network event endpoint: " .. name) end
  moduleRuntime.events[name] = {
    Emit = function(_, payload)
      if self.disposed then error("network transport is disposed") end
      validate(spec.validate, payload, ("event %s.%s payload"):format(moduleRuntime.name, name))
      self:_guard(payload)
      self.emitServer(self.events.c2s, {
        version = VERSION,
        kind = "event",
        module = moduleRuntime.name,
        name = name,
        payload = payload,
      })
    end,
  }
end

function ClientNet:_makeOutgoingRpc(moduleRuntime, name, spec)
  assertMemberName(name)
  if moduleRuntime.rpc[name] then error("duplicate network RPC endpoint: " .. name) end
  local endpoint = {}
  function endpoint:Call(payload, callback)
    if self.transport.disposed then error("network transport is disposed") end
    validate(spec.request, payload, ("rpc %s.%s request"):format(moduleRuntime.name, name))
    self.transport:_guard(payload)
    if callback ~= nil and type(callback) ~= "function" then error("RPC callback must be a function") end
    local requestId = self.transport:_nextRequestId()
    local pending = {
      module = moduleRuntime.name,
      name = name,
      response = spec.response,
      callback = callback,
    }
    local timeout = math.min(spec.timeoutMs or spec.timeout or DEFAULT_TIMEOUT, MAX_TIMEOUT)
    if callback == nil and (not promise or not Citizen or type(Citizen.Await) ~= "function") then
      error("synchronous RPC requires FiveM promise/Citizen.Await")
    end
    local waiter = nil
    if callback == nil then
      waiter = promise.new()
      pending.callback = function(result, err) waiter:resolve({ result = result, error = err }) end
    end
    pending.timer = self.transport.schedule(timeout, function()
      if self.transport.pending[requestId] ~= pending then return end
      self.transport.pending[requestId] = nil
      safeCallback(self.transport.logger, pending.callback, nil, { code = "RPC_TIMEOUT" })
    end)
    self.transport.pending[requestId] = pending
    local emitOk, emitErr = pcall(self.transport.emitServer, self.transport.events.c2s, {
      version = VERSION,
      kind = "rpc.request",
      module = moduleRuntime.name,
      name = name,
      requestId = requestId,
      payload = payload,
    })
    if not emitOk then
      self.transport.pending[requestId] = nil
      self.transport.cancel(pending.timer)
      error(emitErr)
    end
    if callback then return requestId end
    local outcome = Citizen.Await(waiter)
    if outcome.error then error(outcome.error.code or "RPC_FAILED") end
    return outcome.result
  end
  endpoint.transport = self
  moduleRuntime.rpc[name] = endpoint
end

function ClientNet:_makeIncomingRpc(moduleRuntime, name, spec)
  assertMemberName(name)
  if moduleRuntime.rpc[name] then error("duplicate network RPC endpoint: " .. name) end
  local endpoint = { handler = nil, request = spec.request, response = spec.response }
  function endpoint:Handle(handler)
    if self.transport.disposed then error("network transport is disposed") end
    if type(handler) ~= "function" then error("RPC handler must be a function") end
    if self.handler then error("RPC handler is already registered") end
    self.handler = handler
    local active = true
    return function()
      if not active then return end
      active = false
      if self.handler == handler then self.handler = nil end
    end
  end
  moduleRuntime.rpc[name] = endpoint
  moduleRuntime.incomingRpc[name] = endpoint
  endpoint.transport = self
end

function ClientNet:RegisterModule(name, contract)
  if self.disposed then error("network transport is disposed") end
  assertModuleName(name)
  if self.modules[name] then error("network module is already registered: " .. name) end
  contract = contract or {}
  local facade = { events = {}, rpc = {} }
  local moduleRuntime = {
    name = name,
    events = facade.events,
    rpc = facade.rpc,
    facade = facade,
    incomingEvents = {},
    incomingRpc = {},
  }

  for eventName, spec in pairs((contract.events or {}).serverToClient or {}) do
    self:_makeIncomingEvent(moduleRuntime, eventName, spec)
  end
  for eventName, spec in pairs((contract.events or {}).clientToServer or {}) do
    self:_makeOutgoingEvent(moduleRuntime, eventName, spec)
  end
  for rpcName, spec in pairs((contract.rpc or {}).clientToServer or {}) do
    self:_makeOutgoingRpc(moduleRuntime, rpcName, spec)
  end
  for rpcName, spec in pairs((contract.rpc or {}).serverToClient or {}) do
    self:_makeIncomingRpc(moduleRuntime, rpcName, spec)
  end

  local accessor = pascalCase(name)
  if self[accessor] ~= nil then error("network module accessor collision: " .. accessor) end
  self.modules[name] = moduleRuntime
  self[accessor] = facade
  self.accessors[#self.accessors + 1] = accessor
  return facade
end

function ClientNet:Module(name)
  local runtime = self.modules[name]
  if not runtime then error("network module is not declared: " .. tostring(name)) end
  return runtime.facade
end

function ClientNet:_validEnvelope(envelope)
  return type(envelope) == "table"
    and validEnvelopeShape(envelope)
    and envelope.version == VERSION
    and type(envelope.module) == "string" and #envelope.module <= 64
    and type(envelope.name) == "string" and #envelope.name <= 64
    and (envelope.requestId == nil or (type(envelope.requestId) == "string" and #envelope.requestId <= 128))
end

function ClientNet:_handleResponse(envelope)
  if not self:_validEnvelope(envelope) or type(envelope.requestId) ~= "string" then return end
  if envelope.kind ~= "rpc.response" and envelope.kind ~= "rpc.error" then return end
  local pending = self.pending[envelope.requestId]
  if not pending or pending.module ~= envelope.module or pending.name ~= envelope.name then return end
  if envelope.payload ~= nil then
    local sizeOk = pcall(function() self:_guard(envelope.payload) end)
    if not sizeOk then
      self.pending[envelope.requestId] = nil
      self.cancel(pending.timer)
      safeCallback(self.logger, pending.callback, nil, { code = "PAYLOAD_TOO_LARGE" })
      return
    end
  end
  self.pending[envelope.requestId] = nil
  self.cancel(pending.timer)
  if envelope.kind == "rpc.error" then
    safeCallback(self.logger, pending.callback, nil, { code = envelope.error and envelope.error.code or "RPC_FAILED" })
    return
  end
  local ok = pcall(validate, pending.response, envelope.payload, "rpc response")
  if not ok then
    safeCallback(self.logger, pending.callback, nil, { code = "INVALID_RESPONSE" })
    return
  end
  safeCallback(self.logger, pending.callback, envelope.payload, nil)
end

function ClientNet:_handleServerEnvelope(envelope)
  if not self:_validEnvelope(envelope) then return end
  local guardOk = pcall(function() self:_guard(envelope.payload) end)
  if not guardOk then return end
  local moduleRuntime = self.modules[envelope.module]
  if not moduleRuntime then return end

  if envelope.kind == "event" then
    local endpoint = moduleRuntime.incomingEvents[envelope.name]
    if endpoint then pcall(endpoint._dispatch, envelope.payload) end
    return
  end
  if envelope.kind == "rpc.request" and type(envelope.requestId) == "string" then
    local endpoint = moduleRuntime.incomingRpc[envelope.name]
    local response = {
      version = VERSION, module = envelope.module, name = envelope.name,
      requestId = envelope.requestId,
    }
    local correlation = envelope.module .. ":" .. envelope.name .. ":" .. envelope.requestId
    if self.incomingSeen[correlation] then
      response.kind = "rpc.error"; response.error = { code = "DUPLICATE_REQUEST" }
    elseif not endpoint or type(endpoint.handler) ~= "function" then
      response.kind = "rpc.error"; response.error = { code = "UNKNOWN_ENDPOINT" }
    else
      self.incomingSeen[correlation] = true
      self.incomingOrder[#self.incomingOrder + 1] = correlation
      if #self.incomingOrder > self.incomingLimit then
        local expired = table.remove(self.incomingOrder, 1)
        self.incomingSeen[expired] = nil
      end
      local ok, result = pcall(function()
        validate(endpoint.request, envelope.payload, "rpc request")
        local value = endpoint.handler(envelope.payload)
        validate(endpoint.response, value, "rpc response")
        self:_guard(value)
        return value
      end)
      if ok then response.kind = "rpc.response"; response.payload = result
      else response.kind = "rpc.error"; response.error = { code = "INVALID_REQUEST" } end
    end
    self.emitServer(self.events.response, response)
  end
end

function ClientNet:Dispose()
  if self.disposed then return end
  self.disposed = true
  for _, unregister in ipairs(self.unregister) do pcall(unregister) end
  local callbacks = {}
  for requestId, pending in pairs(self.pending) do
    self.cancel(pending.timer)
    self.pending[requestId] = nil
    if pending.callback then callbacks[#callbacks + 1] = pending.callback end
  end
  for _, callback in ipairs(callbacks) do
    safeCallback(self.logger, callback, nil, { code = "TRANSPORT_DISPOSED" })
  end
  self.modules = {}
  for _, accessor in ipairs(self.accessors) do self[accessor] = nil end
  self.accessors = {}
end

---@param options? LRClient.NetOptions
---@return LRClient.Net
function LR.CreateClientNet(options)
  options = options or {}
  local resourceName = options.resourceName or (type(GetCurrentResourceName) == "function" and GetCurrentResourceName()) or "lr"
  local instance = setmetatable({
    logger = options.logger or defaultLogger(),
    registerEvent = options.registerEvent or defaultRegisterEvent,
    emitServer = options.emitServer or defaultEmitServer,
    sizeOf = options.sizeOf or fallbackSizeOf,
    schedule = options.schedule or defaultSchedule,
    cancel = options.cancel or defaultCancel,
    maxPayload = options.maxPayload or DEFAULT_MAX_PAYLOAD,
    now = options.now or function() return GetGameTimer() end,
    sessionSalt = options.sessionSalt or tostring(math.random(100000, 999999)),
    counter = 0,
    events = {
      c2s = resourceName .. ":net:c2s",
      s2c = resourceName .. ":net:s2c",
      response = resourceName .. ":net:response",
    },
    modules = {}, accessors = {}, pending = {}, unregister = {}, disposed = false,
    incomingSeen = {}, incomingOrder = {}, incomingLimit = options.incomingLimit or 2048,
  }, ClientNet)

  local initialized, initializeError = pcall(function()
    instance.unregister[#instance.unregister + 1] = instance.registerEvent(instance.events.s2c, function(envelope)
      instance:_handleServerEnvelope(envelope)
    end) or noop
    instance.unregister[#instance.unregister + 1] = instance.registerEvent(instance.events.response, function(envelope)
      instance:_handleResponse(envelope)
    end) or noop
    local contracts = options.contracts or (LR.Generated and LR.Generated.Contracts)
    if type(contracts) == "table" then
      for moduleName, contract in pairs(contracts) do
        if type(contract) == "table" and type(contract.net) == "table" then
          instance:RegisterModule(moduleName, contract.net)
        end
      end
    end
  end)
  if not initialized then
    instance:Dispose()
    error(initializeError)
  end
  return instance
end
