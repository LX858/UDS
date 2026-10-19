LR = LR or {}

local BRIDGE_VERSION = 2
local BRIDGE_ENDPOINT = "lr_bridge"
local DEFAULT_RPC_TIMEOUT = 5000
local MAX_RPC_TIMEOUT = 60000
local DEFAULT_MAX_PAYLOAD = 256 * 1024

local function noop() end

local function isCallable(value)
  if type(value) == "function" then return true end
  if type(value) ~= "table" then return false end
  local metatable = getmetatable(value)
  return type(metatable) == "table" and type(metatable.__call) == "function"
end

local function defaultLogger()
  return { Debug = noop, Info = noop, Warn = noop, Error = noop }
end
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
  version = true, module = true, kind = true, name = true, requestId = true,
  sessionId = true, revision = true, payload = true, error = true,
}
local ERROR_KEYS = { code = true, message = true }

local function hasOnlyEnvelopeKeys(envelope)
  for key in pairs(envelope) do
    if not ENVELOPE_KEYS[key] then return false end
  end
  return true
end

local function hasOnlyKeys(value, allowed)
  for key in pairs(value) do
    if not allowed[key] then return false end
  end
  return true
end

local function isModuleName(name)
  return type(name) == "string" and #name <= 64 and name:match("^[a-z][a-z0-9_]*$") ~= nil
end

local function isMemberName(name)
  return type(name) == "string" and #name <= 64 and name:match("^[a-z][A-Za-z0-9_]*$") ~= nil
end

local function isEnvelopeKind(kind)
  return kind == "state.snapshot" or kind == "state.set" or kind == "state.patch" or kind == "event"
    or kind == "rpc.request" or kind == "rpc.response" or kind == "rpc.error"
end

local function pascalCase(name)
  return (name:gsub("^%l", string.upper):gsub("_([a-z])", function(letter) return letter:upper() end))
end

local function validate(validator, value, label)
  if type(validator) ~= "function" then
    error(label .. " validator is missing")
  end

  local ok, valid, detail = pcall(validator, value)
  if not ok then
    error(label .. " validation failed")
  end
  if valid ~= true then
    error(label .. " validation failed" .. (detail and (": " .. tostring(detail)) or ""))
  end
end

local function cloneDto(value, seen)
  if value == nil or type(value) ~= "table" or value == LR.JSON_NULL then return value end
  seen = seen or {}
  if seen[value] then error("cyclic DTO values are not supported") end
  seen[value] = true
  local copy = {}
  for key, item in pairs(value) do copy[key] = cloneDto(item, seen) end
  seen[value] = nil
  return copy
end

local function dtoEquals(left, right, seen)
  if left == right then return true end
  if type(left) ~= "table" or type(right) ~= "table" then return false end
  seen = seen or {}
  local rightSeen = seen[left]
  if rightSeen and rightSeen[right] then return true end
  if not rightSeen then
    rightSeen = {}
    seen[left] = rightSeen
  end
  rightSeen[right] = true
  for key, value in pairs(left) do
    if not dtoEquals(value, right[key], seen) then return false end
  end
  for key in pairs(right) do
    if left[key] == nil then return false end
  end
  return true
end

local function safeCallback(logger, callback, ...)
  if type(callback) ~= "function" then return true end
  local ok = pcall(callback, ...)
  if not ok then logger:Error("NUI callback failed") end
  return ok
end

local function fallbackSizeOf(value)
  if json and type(json.encode) == "function" then
    local ok, encoded = pcall(json.encode, value)
    if ok and type(encoded) == "string" then
      return #encoded
    end
    error("JSON encoding failed")
  end
  error("JSON encoder is unavailable")
end

local function defaultRegisterCallback(name, handler)
  if type(RegisterNuiCallback) == "function" then
    RegisterNuiCallback(name, handler)
    return noop
  end
  if type(RegisterNuiCallbackType) == "function" and type(addEventHandler) == "function" then
    RegisterNuiCallbackType(name)
    local token = addEventHandler("__cfx_nui:" .. name, handler)
    if token and type(RemoveEventHandler) == "function" then
      return function() RemoveEventHandler(token) end
    end
    return noop
  end
  RegisterNUICallback(name, handler)
  return noop
end

local function defaultSend(envelope)
  SendNUIMessage(envelope)
  return true
end

local function defaultSetTimeout(milliseconds, callback)
  return SetTimeout(milliseconds, callback)
end

local function defaultClearTimeout(timer)
  if timer ~= nil and type(ClearTimeout) == "function" then
    ClearTimeout(timer)
  end
end

local function makeResponse(request, payload)
  local response = {
    version = BRIDGE_VERSION,
    module = request.module,
    kind = "rpc.response",
    name = request.name,
    requestId = request.requestId,
    payload = payload,
  }
  if request.sessionId ~= nil then response.sessionId = request.sessionId end
  return response
end

local function makeAck(request)
  return makeResponse(request, { ok = true })
end

local function makeError(request, code)
  local response = {
    version = BRIDGE_VERSION,
    module = type(request) == "table" and request.module or "core",
    kind = "rpc.error",
    name = type(request) == "table" and request.name or "invalid",
    requestId = type(request) == "table" and request.requestId or nil,
    error = { code = code },
  }
  if type(request) == "table" and type(request.sessionId) == "string" then
    response.sessionId = request.sessionId
  end
  return response
end

local function makeInvalidEnvelopeError(code)
  return {
    version = BRIDGE_VERSION,
    module = "core",
    kind = "rpc.error",
    name = "invalid",
    error = { code = code },
  }
end

local ClientNui = {}
ClientNui.__index = ClientNui

function ClientNui:_guardPayload(payload)
  local ok, size = pcall(self.sizeOf, payload)
  if not ok then error(size) end
  if type(size) ~= "number" or size ~= size or size < 0 or size == math.huge then
    error("payload size calculation failed")
  end
  if size > self.maxPayload then
    error(("payload exceeds %d bytes"):format(self.maxPayload))
  end
end

function ClientNui:_send(envelope)
  if envelope.payload ~= nil then
    self:_guardPayload(envelope.payload)
  end
  return self.send(envelope)
end

function ClientNui:_nextRequestId()
  self.requestCounter = self.requestCounter + 1
  return ("%s-nui-%d"):format(self.sessionSalt, self.requestCounter)
end

function ClientNui:_notify(watchers, value, previous, count)
  local callbacks = {}
  if count == nil then
    for _, callback in pairs(watchers) do callbacks[#callbacks + 1] = callback end
  else
    for id = 1, count do
      if watchers[id] then callbacks[#callbacks + 1] = watchers[id] end
    end
  end
  self.notificationQueue[#self.notificationQueue + 1] = {
    callbacks = callbacks,
    value = cloneDto(value),
    previous = cloneDto(previous),
  }
  if self.notifying then return end

  self.notifying = true
  local index = 1
  while self.notificationQueue[index] do
    local notification = self.notificationQueue[index]
    for _, callback in ipairs(notification.callbacks) do
      local ok = pcall(
        callback,
        cloneDto(notification.value),
        cloneDto(notification.previous)
      )
      if not ok then self.logger:Error("NUI subscriber failed") end
    end
    self.notificationQueue[index] = nil
    index = index + 1
  end
  self.notificationQueue = {}
  self.notifying = false
end

function ClientNui:_registerState(moduleRuntime, name, spec)
  assertMemberName(name)
  validate(spec.validate, spec.default, ("state %s.%s default"):format(moduleRuntime.name, name))
  local defaultValue = cloneDto(spec.default)
  self:_guardPayload(defaultValue)

  local state = {
    bridge = self,
    module = moduleRuntime.name,
    name = name,
    validator = spec.validate,
    patchValidator = spec.patchValidate,
    object = spec.object == true,
    value = defaultValue,
    revision = 1,
    watchers = {},
    watcherCounter = 0,
  }

  function state:Get()
    if self.bridge.disposed then error("NUI bridge is disposed") end
    return cloneDto(self.value)
  end

  function state:Watch(callback)
    if self.bridge.disposed then error("NUI bridge is disposed") end
    if type(callback) ~= "function" then
      error("state watcher must be a function")
    end
    self.watcherCounter = self.watcherCounter + 1
    local id = self.watcherCounter
    self.watchers[id] = callback
    local active = true
    return function()
      if not active then return end
      active = false
      self.watchers[id] = nil
    end
  end

  function state:_candidate(kind, payload)
    local value = payload
    if kind == "state.patch" then
      if not self.object or type(self.value) ~= "table" or type(payload) ~= "table" then
        error("INVALID_STATE_PATCH")
      end
      if self.patchValidator then
        local patchOk = pcall(validate, self.patchValidator, payload, "state patch")
        if not patchOk then error("INVALID_STATE_PATCH") end
      end
      value = {}
      for key, item in pairs(self.value) do value[key] = item end
      for key, item in pairs(payload) do value[key] = item end
    end
    local valid = pcall(validate, self.validator, value, ("state %s.%s"):format(self.module, self.name))
    if not valid then
      error(kind == "state.patch" and "INVALID_STATE_PATCH" or "INVALID_STATE")
    end
    local cloneOk, candidate = pcall(cloneDto, value)
    if not cloneOk then error("INVALID_PAYLOAD") end
    local payloadOk, payloadError = self.bridge:_payloadStatus(candidate)
    if not payloadOk then error(payloadError) end
    return candidate
  end

  function state:_publish()
    local envelope = {
      version = BRIDGE_VERSION,
      module = self.module,
      kind = "state.snapshot",
      name = self.name,
      revision = self.revision,
      payload = cloneDto(self.value),
    }
    if self.bridge.activeSessionId ~= nil then envelope.sessionId = self.bridge.activeSessionId end
    if self.bridge.ready then
      self.bridge.send(envelope)
    else
      self.bridge.queuedStates[self.module .. ":" .. self.name] = envelope
    end
  end

  function state:_commit(kind, payload)
    local candidate = self:_candidate(kind, payload)
    if dtoEquals(candidate, self.value) then return false end
    local previous = self.value
    self.revision = self.revision + 1
    self.value = candidate
    self:_publish()
    self.bridge:_notify(self.watchers, self.value, previous, self.watcherCounter)
    return true
  end

  function state:Set(value)
    if self.bridge.disposed then error("NUI bridge is disposed") end
    return self:_commit("state.set", value)
  end

  function state:Patch(patch)
    if self.bridge.disposed then error("NUI bridge is disposed") end
    if not self.object then error("Patch is only available for object states") end
    return self:_commit("state.patch", patch)
  end

  moduleRuntime.state[name] = state
end

function ClientNui:_registerOutgoingEvent(moduleRuntime, name, spec)
  assertMemberName(name)
  if moduleRuntime.events[name] then error("duplicate NUI event endpoint: " .. name) end
  moduleRuntime.events[name] = {
    Emit = function(_, payload)
      if self.disposed then error("NUI bridge is disposed") end
      validate(spec.validate, payload, ("event %s.%s payload"):format(moduleRuntime.name, name))
      self:_guardPayload(payload)
      if not self.ready then
        self.logger:Debug("Dropped NUI event %s.%s before ready", moduleRuntime.name, name)
        return false
      end
      self:_send({
        version = BRIDGE_VERSION,
        module = moduleRuntime.name,
        kind = "event",
        name = name,
        payload = payload,
      })
      return true
    end,
  }
end

function ClientNui:_registerIncomingEvent(moduleRuntime, name, spec)
  assertMemberName(name)
  if moduleRuntime.events[name] then error("duplicate NUI event endpoint: " .. name) end
  local subscribers = {}
  local counter = 0
  local endpoint = {}
  function endpoint:On(callback)
    if self.bridge.disposed then error("NUI bridge is disposed") end
    if type(callback) ~= "function" then error("event subscriber must be a function") end
    counter = counter + 1
    local id = counter
    subscribers[id] = callback
    return function() subscribers[id] = nil end
  end
  endpoint._dispatch = function(payload)
    validate(spec.validate, payload, ("event %s.%s payload"):format(moduleRuntime.name, name))
    self:_notify(subscribers, payload, nil, counter)
  end
  endpoint.bridge = self
  moduleRuntime.events[name] = endpoint
  moduleRuntime.incomingEvents[name] = endpoint
end

function ClientNui:_registerOutgoingRpc(moduleRuntime, name, spec)
  assertMemberName(name)
  if moduleRuntime.rpc[name] then error("duplicate NUI RPC endpoint: " .. name) end
  local endpoint = {}
  function endpoint:Call(payload, callback)
    if self.bridge.disposed then error("NUI bridge is disposed") end
    validate(spec.request, payload, ("rpc %s.%s request"):format(moduleRuntime.name, name))
    self.bridge:_guardPayload(payload)
    if not self.bridge.ready then
      local err = { code = "NUI_NOT_READY" }
      if callback then callback(nil, err) return nil end
      error(err.code)
    end
    if callback ~= nil and type(callback) ~= "function" then
      error("RPC callback must be a function")
    end

    local requestId = self.bridge:_nextRequestId()
    local timeout = math.min(spec.timeoutMs or spec.timeout or DEFAULT_RPC_TIMEOUT, MAX_RPC_TIMEOUT)
    local pending = {
      module = moduleRuntime.name,
      name = name,
      response = spec.response,
      callback = callback,
    }
    if callback == nil and (not promise or not Citizen or type(Citizen.Await) ~= "function") then
      error("synchronous RPC requires FiveM promise/Citizen.Await")
    end
    local waiter = nil
    if callback == nil then
      waiter = promise.new()
      pending.callback = function(result, err) waiter:resolve({ result = result, error = err }) end
    end
    pending.timer = self.bridge.setTimeout(timeout, function()
      if self.bridge.pending[requestId] ~= pending then return end
      self.bridge.pending[requestId] = nil
      safeCallback(self.bridge.logger, pending.callback, nil, { code = "RPC_TIMEOUT" })
    end)
    self.bridge.pending[requestId] = pending
    local sendOk, sendErr = pcall(function() self.bridge:_send({
      version = BRIDGE_VERSION,
      module = moduleRuntime.name,
      kind = "rpc.request",
      name = name,
      requestId = requestId,
      payload = payload,
    }) end)
    if not sendOk then
      self.bridge.pending[requestId] = nil
      self.bridge.clearTimeout(pending.timer)
      error(sendErr)
    end

    if callback then return requestId end
    local outcome = Citizen.Await(waiter)
    if outcome.error then error(outcome.error.code or "RPC_FAILED") end
    return outcome.result
  end
  endpoint.bridge = self
  moduleRuntime.rpc[name] = endpoint
end

function ClientNui:_registerIncomingRpc(moduleRuntime, name, spec)
  assertMemberName(name)
  if moduleRuntime.rpc[name] then error("duplicate NUI RPC endpoint: " .. name) end
  local endpoint = { handler = nil }
  function endpoint:Handle(handler)
    if self.bridge.disposed then error("NUI bridge is disposed") end
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
  endpoint.request = spec.request
  endpoint.response = spec.response
  endpoint.bridge = self
  moduleRuntime.rpc[name] = endpoint
  moduleRuntime.incomingRpc[name] = endpoint
end

function ClientNui:RegisterModule(name, contract)
  if self.disposed then error("NUI bridge is disposed") end
  assertModuleName(name)
  if self.modules[name] then error("NUI module is already registered: " .. name) end
  contract = contract or {}

  local runtime = {
    name = name,
    state = {},
    events = {},
    rpc = {},
    incomingEvents = {},
    incomingRpc = {},
  }
  for stateName, spec in pairs(contract.state or {}) do
    self:_registerState(runtime, stateName, spec)
  end
  for eventName, spec in pairs((contract.events or {}).toNui or {}) do
    self:_registerOutgoingEvent(runtime, eventName, spec)
  end
  for eventName, spec in pairs((contract.events or {}).toClient or {}) do
    self:_registerIncomingEvent(runtime, eventName, spec)
  end
  for rpcName, spec in pairs((contract.rpc or {}).toNui or {}) do
    self:_registerOutgoingRpc(runtime, rpcName, spec)
  end
  for rpcName, spec in pairs((contract.rpc or {}).toClient or {}) do
    self:_registerIncomingRpc(runtime, rpcName, spec)
  end

  local accessor = pascalCase(name)
  if self[accessor] ~= nil then error("NUI module accessor collision: " .. accessor) end
  self.modules[name] = runtime
  self[accessor] = function() return runtime end
  self.accessors[#self.accessors + 1] = accessor
  return runtime
end

function ClientNui:Module(name)
  local moduleRuntime = self.modules[name]
  if not moduleRuntime then error("NUI module is not declared: " .. tostring(name)) end
  return moduleRuntime
end

function ClientNui:IsReady()
  return self.ready and not self.disposed
end

function ClientNui:WhenReady(callback)
  if self.disposed then error("NUI bridge is disposed") end
  if type(callback) ~= "function" then error("NUI ready callback must be a function") end
  if self.ready then
    callback()
    return noop
  end

  self.readyCallbackCounter = self.readyCallbackCounter + 1
  local id = self.readyCallbackCounter
  self.readyCallbacks[id] = callback
  return function()
    self.readyCallbacks[id] = nil
  end
end

function ClientNui:_payloadStatus(payload)
  local ok, size = pcall(self.sizeOf, payload)
  if not ok or type(size) ~= "number" or size ~= size or size < 0 or size == math.huge then
    return false, "INVALID_PAYLOAD"
  end
  if size > self.maxPayload then return false, "PAYLOAD_TOO_LARGE" end
  return true, nil, size
end

function ClientNui:_rejectPending(code)
  local callbacks = {}
  for requestId, pending in pairs(self.pending) do
    self.clearTimeout(pending.timer)
    self.pending[requestId] = nil
    if pending.callback then callbacks[#callbacks + 1] = pending.callback end
  end
  for _, callback in ipairs(callbacks) do
    safeCallback(self.logger, callback, nil, { code = code })
  end
end

function ClientNui:_activateSession(sessionId)
  if self.activeSessionId ~= sessionId then
    self.ready = false
    self:_rejectPending("NUI_SESSION_REPLACED")
    self.stateReplay = {}
    self.stateReplayOrder = {}
    self.stateReplayBytes = 0
    self.incomingRpcSeen = {}
    self.incomingRpcOrder = {}
  end
  self.activeSessionId = sessionId
end

function ClientNui:_rememberStateCommand(envelope, response)
  local commandOk, _, commandSize = self:_payloadStatus(envelope.payload)
  local responseOk, _, responseSize = self:_payloadStatus(response.payload)
  if not commandOk or not responseOk then return end
  local entrySize = commandSize + responseSize
  self.stateReplay[envelope.requestId] = {
    command = {
      module = envelope.module,
      name = envelope.name,
      kind = envelope.kind,
      sessionId = envelope.sessionId,
      payload = cloneDto(envelope.payload),
    },
    response = cloneDto(response),
    size = entrySize,
  }
  self.stateReplayBytes = self.stateReplayBytes + entrySize
  self.stateReplayOrder[#self.stateReplayOrder + 1] = envelope.requestId
  while #self.stateReplayOrder > self.stateReplayLimit or self.stateReplayBytes > self.stateReplayMaxBytes do
    local expired = table.remove(self.stateReplayOrder, 1)
    local replay = self.stateReplay[expired]
    if replay then self.stateReplayBytes = self.stateReplayBytes - replay.size end
    self.stateReplay[expired] = nil
  end
end

function ClientNui:MarkReady(sessionId)
  if self.disposed then return false end
  sessionId = sessionId or self.activeSessionId
  if sessionId ~= nil and sessionId ~= self.activeSessionId then
    return false
  end
  local wasReady = self.ready
  local queuedCount = 0
  for _ in pairs(self.queuedStates) do queuedCount = queuedCount + 1 end
  self.logger:Info("NUI ready; flushing %d queued state snapshots", queuedCount)
  self.ready = true
  local ok, err = pcall(function()
    for _, moduleRuntime in pairs(self.modules) do
      for _, state in pairs(moduleRuntime.state) do
        local envelope = {
          version = BRIDGE_VERSION,
          module = state.module,
          kind = "state.snapshot",
          name = state.name,
          revision = state.revision,
          payload = cloneDto(state.value),
        }
        if sessionId ~= nil then envelope.sessionId = sessionId end
        self:_send(envelope)
      end
    end
    if sessionId ~= nil then
      self:_send({
        version = BRIDGE_VERSION,
        module = "core",
        kind = "event",
        name = "synced",
        sessionId = sessionId,
        payload = { sessionId = sessionId },
      })
    end
  end)
  if not ok then
    self.ready = false
    error(err)
  end
  self.queuedStates = {}
  if wasReady then return true end
  local callbacks = self.readyCallbacks
  self.readyCallbacks = {}
  for _, callback in pairs(callbacks) do
    if not pcall(callback) then
      self.logger:Error("NUI ready callback failed")
    end
  end
  return true
end

function ClientNui:_handleResponse(envelope)
  local pending = envelope.requestId and self.pending[envelope.requestId] or nil
  if not pending then return end
  if pending.module ~= envelope.module or pending.name ~= envelope.name then return end
  self.pending[envelope.requestId] = nil
  self.clearTimeout(pending.timer)
  if envelope.kind == "rpc.error" then
    safeCallback(self.logger, pending.callback, nil, { code = envelope.error and envelope.error.code or "RPC_FAILED" })
    return
  end
  local ok = pcall(validate, pending.response, envelope.payload, "rpc response")
  if not ok then
    safeCallback(self.logger, pending.callback, nil, { code = "INVALID_RESPONSE" })
    return
  end
  safeCallback(self.logger, pending.callback, cloneDto(envelope.payload), nil)
end

function ClientNui:_handleIncoming(envelope, reply)
  if type(envelope) ~= "table" or envelope.version ~= BRIDGE_VERSION or not hasOnlyEnvelopeKeys(envelope) then
    reply(makeInvalidEnvelopeError("INVALID_ENVELOPE")) return
  end
  if not isModuleName(envelope.module) or not isMemberName(envelope.name) or not isEnvelopeKind(envelope.kind)
    or (envelope.requestId ~= nil and (type(envelope.requestId) ~= "string" or #envelope.requestId < 1 or #envelope.requestId > 128))
    or (envelope.sessionId ~= nil and (type(envelope.sessionId) ~= "string" or #envelope.sessionId < 1 or #envelope.sessionId > 128)) then
    reply(makeInvalidEnvelopeError("INVALID_ENVELOPE")) return
  end
  if envelope.revision ~= nil and (
    type(envelope.revision) ~= "number" or envelope.revision < 1 or envelope.revision % 1 ~= 0
  ) then
    reply(makeError(envelope, "INVALID_REVISION")) return
  end
  if envelope.error ~= nil and (
    type(envelope.error) ~= "table" or not hasOnlyKeys(envelope.error, ERROR_KEYS)
      or type(envelope.error.code) ~= "string" or #envelope.error.code < 1 or #envelope.error.code > 64
      or (envelope.error.message ~= nil and (type(envelope.error.message) ~= "string" or #envelope.error.message > 512))
  ) then
    reply(makeInvalidEnvelopeError("INVALID_ENVELOPE")) return
  end
  if self.disposed then reply(makeError(envelope, "BRIDGE_DISPOSED")) return end
  if envelope.payload ~= nil then
    local payloadOk, payloadError = self:_payloadStatus(envelope.payload)
    if not payloadOk then reply(makeError(envelope, payloadError)) return end
  end
  if envelope.module == "core" and envelope.kind == "event" and envelope.name == "ready" then
    if type(envelope.payload) ~= "table" or not hasOnlyKeys(envelope.payload, { sessionId = true })
      or type(envelope.payload.sessionId) ~= "string" or #envelope.payload.sessionId < 1
      or #envelope.payload.sessionId > 128
      or (envelope.sessionId ~= nil and envelope.sessionId ~= envelope.payload.sessionId) then
      reply(makeError(envelope, "INVALID_SESSION"))
      return
    end
    local sessionId = envelope.payload.sessionId
    self:_activateSession(sessionId)
    self.logger:Info("NUI ready handshake received for session %s", sessionId)
    local acknowledgement = makeAck(envelope)
    acknowledgement.sessionId = sessionId
    acknowledgement.payload.sessionId = sessionId
    reply(acknowledgement)
    local scheduled = pcall(self.setTimeout, 0, function()
      if self.disposed or self.activeSessionId ~= sessionId then return end
      if not pcall(function() self:MarkReady(sessionId) end) then
        self.logger:Error("Failed to complete NUI ready handshake")
      end
    end)
    if not scheduled then self.logger:Error("Failed to schedule NUI ready synchronization") end
    return
  end
  if envelope.kind == "rpc.response" or envelope.kind == "rpc.error" then
    self:_handleResponse(envelope)
    reply(makeAck(envelope))
    return
  end

  local isStateCommand = envelope.kind == "state.set" or envelope.kind == "state.patch"
  if isStateCommand then
    if type(envelope.requestId) ~= "string" or envelope.requestId == "" then
      reply(makeError(envelope, "INVALID_ENVELOPE")) return
    end
    if envelope.revision ~= nil or envelope.error ~= nil then
      reply(makeError(envelope, "INVALID_STATE_COMMAND")) return
    end
    if type(envelope.sessionId) ~= "string" then
      reply(makeError(envelope, "INVALID_SESSION")) return
    end
    if self.activeSessionId == nil then
      reply(makeError(envelope, "NUI_NOT_READY")) return
    end
    if envelope.sessionId ~= self.activeSessionId then
      reply(makeError(envelope, "STALE_SESSION")) return
    end
    local replay = self.stateReplay[envelope.requestId]
    if replay then
      local command = replay.command
      if command.module ~= envelope.module or command.name ~= envelope.name or command.kind ~= envelope.kind
        or command.sessionId ~= envelope.sessionId or not dtoEquals(command.payload, envelope.payload) then
        reply(makeError(envelope, "REQUEST_ID_REUSED"))
      else
        reply(cloneDto(replay.response))
      end
      return
    end
  end

  local moduleRuntime = self.modules[envelope.module]
  if not moduleRuntime then reply(makeError(envelope, "UNKNOWN_MODULE")) return end

  local ok, result = pcall(function()
    if envelope.kind == "event" then
      local endpoint = moduleRuntime.incomingEvents[envelope.name]
      if not endpoint then error("UNKNOWN_ENDPOINT") end
      endpoint._dispatch(envelope.payload)
      return makeAck(envelope)
    end
    if envelope.kind == "state.snapshot" then error("STATE_SNAPSHOT_READ_ONLY") end
    if isStateCommand then
      local state = moduleRuntime.state[envelope.name]
      if not state then error("UNKNOWN_STATE") end
      state:_commit(envelope.kind, envelope.payload)
      local response = makeResponse(envelope, cloneDto(state.value))
      response.revision = state.revision
      self:_rememberStateCommand(envelope, response)
      return response
    end
    if envelope.kind == "rpc.request" then
      if type(envelope.requestId) ~= "string" or envelope.requestId == "" then error("INVALID_ENVELOPE") end
      local correlation = envelope.module .. ":" .. envelope.name .. ":" .. envelope.requestId
      if self.incomingRpcSeen[correlation] then error("DUPLICATE_REQUEST") end
      self.incomingRpcSeen[correlation] = true
      self.incomingRpcOrder[#self.incomingRpcOrder + 1] = correlation
      if #self.incomingRpcOrder > self.incomingRpcLimit then
        local expired = table.remove(self.incomingRpcOrder, 1)
        self.incomingRpcSeen[expired] = nil
      end
      local endpoint = moduleRuntime.incomingRpc[envelope.name]
      if not endpoint or type(endpoint.handler) ~= "function" then error("UNKNOWN_ENDPOINT") end
      validate(endpoint.request, envelope.payload, "rpc request")
      local responsePayload = endpoint.handler(envelope.payload)
      validate(endpoint.response, responsePayload, "rpc response")
      if responsePayload == nil then
        if LR.JSON_NULL == nil then error("NULL_SENTINEL_UNAVAILABLE") end
        responsePayload = LR.JSON_NULL
      end
      local responseSizeOk = pcall(function() self:_guardPayload(responsePayload) end)
      if not responseSizeOk then error("PAYLOAD_TOO_LARGE") end
      return makeResponse(envelope, responsePayload)
    end
    error("INVALID_KIND")
  end)

  if ok then reply(result) else reply(makeError(envelope, tostring(result):match("([A-Z_]+)$") or "INVALID_REQUEST")) end
end

function ClientNui:Dispose()
  if self.disposed then return end
  self.disposed = true
  self.ready = false
  self.unregisterCallback()
  self:_rejectPending("BRIDGE_DISPOSED")
  for _, moduleRuntime in pairs(self.modules) do
    for _, state in pairs(moduleRuntime.state) do
      state.watchers = {}
      state.watcherCounter = 0
    end
  end
  self.activeSessionId = nil
  self.stateReplay = {}
  self.stateReplayOrder = {}
  self.stateReplayBytes = 0
  self.incomingRpcSeen = {}
  self.incomingRpcOrder = {}
  self.notificationQueue = {}
  self.notifying = false
  self.modules = {}
  self.queuedStates = {}
  self.readyCallbacks = {}
  for _, accessor in ipairs(self.accessors) do self[accessor] = nil end
  self.accessors = {}
end

---@param options? LRClient.NuiOptions
---@return LRClient.Nui
function LR.CreateClientNui(options)
  options = options or {}
  local instance = setmetatable({
    resourceName = options.resourceName or (type(GetCurrentResourceName) == "function" and GetCurrentResourceName()) or "lr",
    logger = options.logger or defaultLogger(),
    registerCallback = options.registerCallback or defaultRegisterCallback,
    send = options.send or defaultSend,
    sizeOf = options.sizeOf or fallbackSizeOf,
    setTimeout = options.setTimeout or defaultSetTimeout,
    clearTimeout = options.clearTimeout or defaultClearTimeout,
    maxPayload = options.maxPayload or DEFAULT_MAX_PAYLOAD,
    sessionSalt = options.sessionSalt or tostring(math.random(100000, 999999)),
    requestCounter = 0,
    modules = {},
    accessors = {},
    pending = {},
    queuedStates = {},
    readyCallbacks = {},
    readyCallbackCounter = 0,
    incomingRpcSeen = {},
    incomingRpcOrder = {},
    incomingRpcLimit = options.incomingRpcLimit or 1024,
    activeSessionId = nil,
    stateReplay = {},
    stateReplayOrder = {},
    stateReplayLimit = options.stateReplayLimit or 1024,
    stateReplayBytes = 0,
    stateReplayMaxBytes = options.stateReplayMaxBytes or ((options.maxPayload or DEFAULT_MAX_PAYLOAD) * 4),
    notificationQueue = {},
    notifying = false,
    ready = false,
    disposed = false,
  }, ClientNui)
  local contracts = options.contracts or (LR.Generated and LR.Generated.Contracts)
  if type(contracts) == "table" then
    for moduleName, contract in pairs(contracts) do
      if type(contract) == "table" and type(contract.nui) == "table" then
        instance:RegisterModule(moduleName, contract.nui)
      end
    end
  end
  instance.unregisterCallback = instance.registerCallback(BRIDGE_ENDPOINT, function(envelope, reply)
    instance:_handleIncoming(envelope, isCallable(reply) and reply or noop)
  end) or noop
  instance.logger:Info("Registered NUI bridge endpoint %s", BRIDGE_ENDPOINT)
  return instance
end
