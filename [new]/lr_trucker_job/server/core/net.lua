LR = LR or {}

local VERSION = 1
local DEFAULT_TIMEOUT = 10000
local MAX_TIMEOUT = 30000
local DEFAULT_MAX_PAYLOAD = 128 * 1024
local DEFAULT_RATE = 10
local DEFAULT_BURST = 20
local DEFAULT_INGRESS_RATE = 50
local DEFAULT_INGRESS_BURST = 100
local SEEN_TTL = 30000

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

local function isPlayerSource(value)
  return type(value) == "number" and value > 0 and value % 1 == 0
end

local function isClientEventTarget(value)
  return value == -1 or isPlayerSource(value)
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
    handler(source, envelope)
  end)
  if token and type(RemoveEventHandler) == "function" then
    return function() RemoveEventHandler(token) end
  end
  return noop
end

local function defaultEmitClient(name, playerSource, envelope)
  TriggerClientEvent(name, playerSource, envelope)
end

local function defaultSchedule(milliseconds, callback)
  return SetTimeout(milliseconds, callback)
end

local function defaultCancel(timer)
  if timer and type(ClearTimeout) == "function" then ClearTimeout(timer) end
end

local function defaultRegisterPlayerDropped(handler)
  if type(addEventHandler) ~= "function" then return noop end
  local token = addEventHandler("playerDropped", function()
    handler(source)
  end)
  if token and type(RemoveEventHandler) == "function" then
    return function() RemoveEventHandler(token) end
  end
  return noop
end

local ServerNet = {}
ServerNet.__index = ServerNet

function ServerNet:_guard(payload)
  local size = self.sizeOf(payload)
  if type(size) ~= "number" or size < 0 then error("payload size calculation failed") end
  if size > self.maxPayload then error(("payload exceeds %d bytes"):format(self.maxPayload)) end
end

function ServerNet:_nextRequestId(playerSource)
  self.counter = self.counter + 1
  return ("%s-%s-%d"):format(self.sessionSalt, tostring(playerSource), self.counter)
end

function ServerNet:_consume(playerSource, bucketKey, rateLimit)
  local current = self.now()
  local requestsPerSecond = rateLimit and rateLimit.requestsPerSecond or self.rate
  local burst = rateLimit and rateLimit.burst or self.burst
  local key = tostring(playerSource) .. ":" .. bucketKey
  local bucket = self.buckets[key]
  if not bucket then
    bucket = { tokens = burst, updatedAt = current }
    self.buckets[key] = bucket
  end
  local elapsed = math.max(0, current - bucket.updatedAt)
  bucket.tokens = math.min(burst, bucket.tokens + (elapsed / 1000) * requestsPerSecond)
  bucket.updatedAt = current
  if bucket.tokens < 1 then return false end
  bucket.tokens = bucket.tokens - 1
  return true
end

function ServerNet:_emitResponse(playerSource, request, kind, payload, code)
  local envelope = {
    version = VERSION,
    module = request.module,
    name = request.name,
    requestId = request.requestId,
    kind = kind,
  }
  if kind == "rpc.response" then
    self:_guard(payload)
    envelope.payload = payload
  else envelope.error = { code = code or "REQUEST_FAILED" } end
  self.emitClient(self.events.response, playerSource, envelope)
end

function ServerNet:_makeIncomingHandler(moduleRuntime, name, spec, isRpc)
  assertMemberName(name)
  local endpoints = isRpc and moduleRuntime.rpc or moduleRuntime.events
  if endpoints[name] then
    error((isRpc and "duplicate network RPC endpoint: " or "duplicate network event endpoint: ") .. name)
  end
  local endpoint = { handler = nil }
  function endpoint:Handle(handler)
    if self.transport.disposed then error("network transport is disposed") end
    local normalized
    if type(handler) == "function" then normalized = { Execute = handler }
    elseif type(handler) == "table" then normalized = handler
    else error("handler must be a function or table") end
    if type(normalized.Execute) ~= "function" then error("handler Execute must be a function") end
    if spec.mutating == true and type(normalized.Authorize) ~= "function" then
      error(("mutating handler %s.%s requires Authorize"):format(moduleRuntime.name, name))
    end
    if normalized.Authorize ~= nil and type(normalized.Authorize) ~= "function" then
      error("Authorize must be a function")
    end
    if self.handler then error("network handler is already registered") end
    self.handler = normalized
    local active = true
    return function()
      if not active then return end
      active = false
      if self.handler == normalized then self.handler = nil end
    end
  end
  endpoint.spec = spec
  endpoint.transport = self
  endpoints[name] = endpoint
  if isRpc then moduleRuntime.incomingRpc[name] = endpoint
  else moduleRuntime.incomingEvents[name] = endpoint end
end

function ServerNet:_makeOutgoingEvent(moduleRuntime, name, spec)
  assertMemberName(name)
  if moduleRuntime.events[name] then error("duplicate network event endpoint: " .. name) end
  moduleRuntime.events[name] = {
    Emit = function(_, playerSource, payload)
      if self.disposed then error("network transport is disposed") end
      if not isClientEventTarget(playerSource) then
        error("client event target must be -1 or a positive integer")
      end
      validate(spec.validate, payload, ("event %s.%s payload"):format(moduleRuntime.name, name))
      self:_guard(payload)
      self.emitClient(self.events.s2c, playerSource, {
        version = VERSION,
        kind = "event",
        module = moduleRuntime.name,
        name = name,
        payload = payload,
      })
    end,
  }
end

function ServerNet:_makeOutgoingRpc(moduleRuntime, name, spec)
  assertMemberName(name)
  if moduleRuntime.rpc[name] then error("duplicate network RPC endpoint: " .. name) end
  local endpoint = {}
  function endpoint:Call(playerSource, payload, callback)
    if self.transport.disposed then error("network transport is disposed") end
    if not isPlayerSource(playerSource) then error("player source must be a positive integer") end
    validate(spec.request, payload, ("rpc %s.%s request"):format(moduleRuntime.name, name))
    self.transport:_guard(payload)
    if callback ~= nil and type(callback) ~= "function" then error("RPC callback must be a function") end
    local requestId = self.transport:_nextRequestId(playerSource)
    local correlation = tostring(playerSource) .. ":" .. requestId
    local pending = {
      source = playerSource, module = moduleRuntime.name, name = name,
      response = spec.response, callback = callback,
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
      if self.transport.pending[correlation] ~= pending then return end
      self.transport.pending[correlation] = nil
      safeCallback(self.transport.logger, pending.callback, nil, { code = "RPC_TIMEOUT" })
    end)
    self.transport.pending[correlation] = pending
    local emitOk, emitErr = pcall(self.transport.emitClient, self.transport.events.s2c, playerSource, {
      version = VERSION, kind = "rpc.request", module = moduleRuntime.name,
      name = name, requestId = requestId, payload = payload,
    })
    if not emitOk then
      self.transport.pending[correlation] = nil
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

function ServerNet:RegisterModule(name, contract)
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

  for eventName, spec in pairs((contract.events or {}).clientToServer or {}) do
    self:_makeIncomingHandler(moduleRuntime, eventName, spec, false)
  end
  for eventName, spec in pairs((contract.events or {}).serverToClient or {}) do
    self:_makeOutgoingEvent(moduleRuntime, eventName, spec)
  end
  for rpcName, spec in pairs((contract.rpc or {}).clientToServer or {}) do
    self:_makeIncomingHandler(moduleRuntime, rpcName, spec, true)
  end
  for rpcName, spec in pairs((contract.rpc or {}).serverToClient or {}) do
    self:_makeOutgoingRpc(moduleRuntime, rpcName, spec)
  end

  local accessor = pascalCase(name)
  if self[accessor] ~= nil then error("network module accessor collision: " .. accessor) end
  self.modules[name] = moduleRuntime
  self[accessor] = facade
  self.accessors[#self.accessors + 1] = accessor
  return facade
end

function ServerNet:Module(name)
  local runtime = self.modules[name]
  if not runtime then error("network module is not declared: " .. tostring(name)) end
  return runtime.facade
end

function ServerNet:_validEnvelope(envelope)
  return type(envelope) == "table"
    and validEnvelopeShape(envelope)
    and envelope.version == VERSION
    and type(envelope.module) == "string" and #envelope.module <= 64
    and type(envelope.name) == "string" and #envelope.name <= 64
    and (envelope.requestId == nil or (type(envelope.requestId) == "string" and #envelope.requestId <= 128))
end

function ServerNet:_isDuplicate(playerSource, requestId)
  if type(requestId) ~= "string" then return true end
  local current = self.now()
  local partition = self.seen[playerSource]
  if not partition then
    partition = { entries = {}, queue = {}, head = 1 }
    self.seen[playerSource] = partition
  end
  while partition.head <= #partition.queue do
    local candidate = partition.queue[partition.head]
    if candidate.expiresAt > current then break end
    partition.head = partition.head + 1
    if partition.entries[candidate.requestId] == candidate.expiresAt then
      partition.entries[candidate.requestId] = nil
    end
  end
  if partition.head > 256 and partition.head > (#partition.queue / 2) then
    local compacted = {}
    for index = partition.head, #partition.queue do
      compacted[#compacted + 1] = partition.queue[index]
    end
    partition.queue = compacted
    partition.head = 1
  end
  local existing = partition.entries[requestId]
  if existing and existing > current then return true end
  local expiresAt = current + SEEN_TTL
  partition.entries[requestId] = expiresAt
  partition.queue[#partition.queue + 1] = { requestId = requestId, expiresAt = expiresAt }
  return false
end

function ServerNet:_executeIncoming(playerSource, envelope, endpoint, isRpc)
  if not endpoint or not endpoint.handler then
    if isRpc then self:_emitResponse(playerSource, envelope, "rpc.error", nil, "UNKNOWN_ENDPOINT") end
    return
  end
  local spec, handler = endpoint.spec, endpoint.handler
  local requestOk = pcall(validate, spec.request or spec.validate, envelope.payload, "network request")
  if not requestOk then
    if isRpc then self:_emitResponse(playerSource, envelope, "rpc.error", nil, "INVALID_REQUEST") end
    return
  end

  if handler.Authorize then
    local authorizeOk, authorized = pcall(handler.Authorize, playerSource, envelope.payload)
    if not authorizeOk or authorized ~= true then
      if isRpc then self:_emitResponse(playerSource, envelope, "rpc.error", nil, "UNAUTHORIZED") end
      return
    end
  end

  local executeOk, result = pcall(handler.Execute, playerSource, envelope.payload)
  if not executeOk then
    self.logger:Error("Network handler %s.%s failed", envelope.module, envelope.name)
    if isRpc then self:_emitResponse(playerSource, envelope, "rpc.error", nil, "HANDLER_FAILED") end
    return
  end

  if isRpc then
    local responseOk = pcall(validate, spec.response, result, "network response")
    if not responseOk then
      self.logger:Error("Network handler %s.%s returned an invalid response", envelope.module, envelope.name)
      self:_emitResponse(playerSource, envelope, "rpc.error", nil, "INVALID_RESPONSE")
      return
    end
    local sizeOk = pcall(function() self:_guard(result) end)
    if not sizeOk then
      self:_emitResponse(playerSource, envelope, "rpc.error", nil, "PAYLOAD_TOO_LARGE")
      return
    end
    self:_emitResponse(playerSource, envelope, "rpc.response", result)
  end
end

function ServerNet:_handleClientEnvelope(playerSource, envelope)
  if not isPlayerSource(playerSource) then return end
  if not self:_consume(playerSource, "ingress", {
    requestsPerSecond = self.ingressRate,
    burst = self.ingressBurst,
  }) then
    if type(envelope) == "table" and envelope.kind == "rpc.request" and self:_validEnvelope(envelope) then
      self:_emitResponse(playerSource, envelope, "rpc.error", nil, "RATE_LIMITED")
    end
    return
  end
  if not self:_validEnvelope(envelope) then return end
  local guardOk = pcall(function() self:_guard(envelope.payload) end)
  if not guardOk then
    if envelope.kind == "rpc.request" then self:_emitResponse(playerSource, envelope, "rpc.error", nil, "PAYLOAD_TOO_LARGE") end
    return
  end
  local moduleRuntime = self.modules[envelope.module]
  if not moduleRuntime then
    if not self:_consume(playerSource, "unknown", nil) then
      if envelope.kind == "rpc.request" then self:_emitResponse(playerSource, envelope, "rpc.error", nil, "RATE_LIMITED") end
      return
    end
    if envelope.kind == "rpc.request" then self:_emitResponse(playerSource, envelope, "rpc.error", nil, "UNKNOWN_MODULE") end
    return
  end
  local endpoint
  if envelope.kind == "event" then endpoint = moduleRuntime.incomingEvents[envelope.name]
  elseif envelope.kind == "rpc.request" then endpoint = moduleRuntime.incomingRpc[envelope.name] end
  local endpointSpec = endpoint and endpoint.spec or nil
  local bucketKey = endpoint and (envelope.module .. ":" .. envelope.name) or (envelope.module .. ":unknown_endpoint")
  if not self:_consume(playerSource, bucketKey, endpointSpec and endpointSpec.rateLimit or nil) then
    if envelope.kind == "rpc.request" then self:_emitResponse(playerSource, envelope, "rpc.error", nil, "RATE_LIMITED") end
    return
  end
  if envelope.kind == "event" then
    self:_executeIncoming(playerSource, envelope, endpoint, false)
  elseif envelope.kind == "rpc.request" then
    if self:_isDuplicate(playerSource, envelope.requestId) then
      self:_emitResponse(playerSource, envelope, "rpc.error", nil, "DUPLICATE_REQUEST")
      return
    end
    self:_executeIncoming(playerSource, envelope, endpoint, true)
  end
end

function ServerNet:_handleResponse(playerSource, envelope)
  if not isPlayerSource(playerSource) then return end
  if not self:_consume(playerSource, "ingress", {
    requestsPerSecond = self.ingressRate,
    burst = self.ingressBurst,
  }) then return end
  if not self:_validEnvelope(envelope) or type(envelope.requestId) ~= "string" then return end
  if envelope.kind ~= "rpc.response" and envelope.kind ~= "rpc.error" then return end
  local correlation = tostring(playerSource) .. ":" .. envelope.requestId
  local pending = self.pending[correlation]
  if not pending or pending.module ~= envelope.module or pending.name ~= envelope.name then return end
  if envelope.payload ~= nil then
    local sizeOk = pcall(function() self:_guard(envelope.payload) end)
    if not sizeOk then
      self.pending[correlation] = nil
      self.cancel(pending.timer)
      safeCallback(self.logger, pending.callback, nil, { code = "PAYLOAD_TOO_LARGE" })
      return
    end
  end
  self.pending[correlation] = nil
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

function ServerNet:ForgetPlayer(playerSource)
  local prefix = tostring(playerSource) .. ":"
  for key in pairs(self.buckets) do
    if key:sub(1, #prefix) == prefix then self.buckets[key] = nil end
  end
  self.seen[playerSource] = nil
  local callbacks = {}
  for correlation, pending in pairs(self.pending) do
    if pending.source == playerSource then
      self.cancel(pending.timer)
      self.pending[correlation] = nil
      if pending.callback then callbacks[#callbacks + 1] = pending.callback end
    end
  end
  for _, callback in ipairs(callbacks) do
    safeCallback(self.logger, callback, nil, { code = "PLAYER_DROPPED" })
  end
end

function ServerNet:Dispose()
  if self.disposed then return end
  self.disposed = true
  for _, unregister in ipairs(self.unregister) do pcall(unregister) end
  local callbacks = {}
  for correlation, pending in pairs(self.pending) do
    self.cancel(pending.timer)
    self.pending[correlation] = nil
    if pending.callback then callbacks[#callbacks + 1] = pending.callback end
  end
  for _, callback in ipairs(callbacks) do
    safeCallback(self.logger, callback, nil, { code = "TRANSPORT_DISPOSED" })
  end
  self.modules, self.buckets, self.seen = {}, {}, {}
  for _, accessor in ipairs(self.accessors) do self[accessor] = nil end
  self.accessors = {}
end

---@param options? LRServer.NetOptions
---@return LRServer.Net
function LR.CreateServerNet(options)
  options = options or {}
  local resourceName = options.resourceName or (type(GetCurrentResourceName) == "function" and GetCurrentResourceName()) or "lr"
  local instance = setmetatable({
    logger = options.logger or defaultLogger(),
    registerEvent = options.registerEvent or defaultRegisterEvent,
    emitClient = options.emitClient or defaultEmitClient,
    sizeOf = options.sizeOf or fallbackSizeOf,
    schedule = options.schedule or defaultSchedule,
    cancel = options.cancel or defaultCancel,
    registerPlayerDropped = options.registerPlayerDropped or defaultRegisterPlayerDropped,
    now = options.now or function() return os.time() * 1000 end,
    maxPayload = options.maxPayload or DEFAULT_MAX_PAYLOAD,
    rate = options.rate or DEFAULT_RATE,
    burst = options.burst or DEFAULT_BURST,
    ingressRate = options.ingressRate or DEFAULT_INGRESS_RATE,
    ingressBurst = options.ingressBurst or DEFAULT_INGRESS_BURST,
    sessionSalt = options.sessionSalt or tostring(math.random(100000, 999999)),
    counter = 0,
    events = {
      c2s = resourceName .. ":net:c2s",
      s2c = resourceName .. ":net:s2c",
      response = resourceName .. ":net:response",
    },
    modules = {}, accessors = {}, pending = {}, buckets = {}, seen = {}, unregister = {}, disposed = false,
  }, ServerNet)

  local initialized, initializeError = pcall(function()
    instance.unregister[#instance.unregister + 1] = instance.registerEvent(instance.events.c2s, function(playerSource, envelope)
      instance:_handleClientEnvelope(playerSource, envelope)
    end) or noop
    instance.unregister[#instance.unregister + 1] = instance.registerEvent(instance.events.response, function(playerSource, envelope)
      instance:_handleResponse(playerSource, envelope)
    end) or noop
    instance.unregister[#instance.unregister + 1] = instance.registerPlayerDropped(function(playerSource)
      instance:ForgetPlayer(playerSource)
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
