local function assertEqual(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. (": expected %s, got %s"):format(tostring(expected), tostring(actual)))
  end
end

local function assertTrue(value, message)
  if value ~= true then
    error(message or ("expected true, got " .. tostring(value)))
  end
end

local function assertError(fn, expected)
  local ok, err = pcall(fn)
  if ok then
    error("expected operation to fail")
  end

  if expected and not tostring(err):find(expected, 1, true) then
    error(("expected error containing %q, got %q"):format(expected, tostring(err)))
  end
end

local function validObject(value)
  if type(value) == "table" then
    return true
  end
  return false, "expected object"
end

local function makeLogger()
  return {
    Debug = function() end,
    Info = function() end,
    Warn = function() end,
    Error = function() end,
  }
end

local function resetLR()
  LR = {}
end

local function testClientNui()
  resetLR()
  dofile("client/core/nui.lua")
  LR.JSON_NULL = {}

  local callbacks = {}
  local messages = {}
  local timers = {}
  local nextTimer = 0

  local bridge = LR.CreateClientNui({
    resourceName = "spec",
    logger = makeLogger(),
    registerCallback = function(name, handler)
      callbacks[name] = handler
      return function()
        callbacks[name] = nil
      end
    end,
    send = function(envelope)
      messages[#messages + 1] = envelope
      return true
    end,
    sizeOf = function(value)
      return value and value.__size or 1
    end,
    setTimeout = function(_, callback)
      nextTimer = nextTimer + 1
      timers[nextTimer] = callback
      return nextTimer
    end,
    clearTimeout = function(id)
      timers[id] = nil
    end,
  })

  bridge:RegisterModule("inventory", {
    state = {
      playerSnapshot = { default = {}, validate = validObject },
      filters = { default = {}, validate = validObject },
    },
    events = {
      toNui = { toast = { validate = validObject } },
      toClient = { selectedItem = { validate = validObject } },
    },
    rpc = {
      toNui = {
        confirmDrop = { request = validObject, response = validObject },
      },
      toClient = {
        useItem = { request = validObject, response = validObject },
        toggle = {
          request = validObject,
          response = function(value) return type(value) == "boolean" end,
        },
        nullResult = {
          request = validObject,
          response = function(value) return value == nil or value == LR.JSON_NULL end,
        },
      },
    },
  })

  assertTrue(type(callbacks["lr_bridge"]) == "function", "NUI must expose exactly the lr_bridge callback")
  local readyCalls = 0
  local readyAcknowledged = false
  bridge:WhenReady(function()
    assertTrue(readyAcknowledged, "NUI ready request must be acknowledged before ready callbacks run")
    readyCalls = readyCalls + 1
  end)

  local inventory = bridge:Module("inventory")
  assertEqual(bridge.Inventory(), inventory, "NUI module must expose a deterministic typed accessor")
  inventory.state.playerSnapshot:Set({ version = 1 })
  inventory.state.playerSnapshot:Set({ version = 2 })
  inventory.events.toast:Emit({ text = "not ready" })
  assertEqual(#messages, 0, "state must coalesce and events must drop before ready")

  local readyReply = setmetatable({}, {
    __call = function(_, response)
      readyAcknowledged = response.kind == "rpc.response"
    end,
  })
  callbacks["lr_bridge"]({
    version = 2,
    module = "core",
    kind = "event",
    name = "ready",
    sessionId = "browser-session",
    payload = { sessionId = "browser-session" },
  }, readyReply)
  assertTrue(readyAcknowledged, "NUI bridge must invoke callable CFX callback references")
  assertEqual(readyCalls, 0, "NUI ready callbacks must wait until the request handler returns")
  timers[nextTimer]()
  assertEqual(readyCalls, 1, "NUI ready callbacks must run after the bridge becomes ready")
  bridge:WhenReady(function() readyCalls = readyCalls + 1 end)
  assertEqual(readyCalls, 2, "late NUI ready callbacks must run immediately")
  assertEqual(#messages, 3, "ready must send every state followed by the synced marker")
  local playerSnapshot
  for _, message in ipairs(messages) do
    if message.module == "inventory" and message.name == "playerSnapshot" then playerSnapshot = message end
  end
  assertEqual(playerSnapshot.kind, "state.snapshot")
  assertEqual(playerSnapshot.revision, 3)
  assertEqual(playerSnapshot.sessionId, "browser-session")
  assertEqual(playerSnapshot.payload.version, 2)
  assertEqual(messages[#messages].module, "core")
  assertEqual(messages[#messages].name, "synced")
  assertEqual(messages[#messages].payload.sessionId, "browser-session")

  inventory.state.filters:Set({ search = "lua" })
  assertEqual(inventory.state.filters:Get().search, "lua", "every state must be writable from Lua")

  local selected
  inventory.events.selectedItem:On(function(payload)
    selected = payload.id
  end)

  local response
  callbacks["lr_bridge"]({
    version = 2,
    module = "inventory",
    kind = "event",
    name = "selectedItem",
    payload = { id = "water" },
  }, function(value)
    response = value
  end)
  assertEqual(selected, "water")
  assertEqual(response.kind, "rpc.response")

  local filterRevision = ""
  inventory.state.filters:Watch(function(value)
    filterRevision = value.search
  end)

  local stateResponse
  callbacks["lr_bridge"]({
    version = 2,
    module = "inventory",
    kind = "state.set",
    name = "filters",
    requestId = "state-1",
    sessionId = "browser-session",
    payload = { search = "browser" },
  }, function(value) stateResponse = value end)
  assertEqual(filterRevision, "browser", "browser state commands must update canonical state")
  assertEqual(stateResponse.kind, "rpc.response")
  assertEqual(stateResponse.revision, 3)
  assertEqual(stateResponse.payload.search, "browser")

  local firstCalls, secondCalls = 0, 0
  local disposeFirst = inventory.events.selectedItem:On(function() firstCalls = firstCalls + 1 end)
  inventory.events.selectedItem:On(function() secondCalls = secondCalls + 1 end)
  disposeFirst()
  callbacks["lr_bridge"]({
    version = 2,
    module = "inventory",
    kind = "event",
    name = "selectedItem",
    payload = { id = "bread" },
  }, function() end)
  assertEqual(firstCalls, 0, "disposing the first subscription must remove the first subscription")
  assertEqual(secondCalls, 1)

  inventory.rpc.toggle:Handle(function() return false end)
  local booleanResponse
  callbacks["lr_bridge"]({
    version = 2,
    module = "inventory",
    kind = "rpc.request",
    name = "toggle",
    requestId = "toggle-1",
    payload = {},
  }, function(value) booleanResponse = value end)
  assertEqual(booleanResponse.payload, false, "false is a valid RPC response payload")

  inventory.rpc.nullResult:Handle(function() return nil end)
  local nullResponse
  callbacks["lr_bridge"]({
    version = 2,
    module = "inventory",
    kind = "rpc.request",
    name = "nullResult",
    requestId = "null-1",
    payload = {},
  }, function(value) nullResponse = value end)
  assertEqual(nullResponse.payload, LR.JSON_NULL, "null RPC response must not become an ACK object")

  local rpcResult
  local requestId = inventory.rpc.confirmDrop:Call({ item = "water" }, function(result, err)
    rpcResult = result or err
  end)
  assertTrue(type(requestId) == "string")
  local request = messages[#messages]
  assertEqual(request.kind, "rpc.request")
  assertEqual(request.requestId, requestId)

  callbacks["lr_bridge"]({
    version = 2,
    module = "inventory",
    kind = "rpc.response",
    name = "confirmDrop",
    requestId = requestId,
    payload = { confirmed = true },
  }, function() end)
  assertTrue(rpcResult.confirmed)

  assertError(function()
    inventory.events.toast:Emit({ __size = 262145 })
  end, "payload exceeds")

  local cancelled
  inventory.rpc.confirmDrop:Call({ item = "bread" }, function(_, err)
    cancelled = err and err.code
  end)
  bridge:Dispose()
  assertEqual(cancelled, "BRIDGE_DISPOSED")
  assertEqual(callbacks["lr_bridge"], nil)
  assertError(function()
    inventory.state.playerSnapshot:Set({ version = 3 })
  end, "disposed")
end

local function makeEventRuntime()
  local registered = {}
  local emitted = {}
  return {
    registered = registered,
    emitted = emitted,
    register = function(name, handler)
      registered[name] = handler
      return function()
        registered[name] = nil
      end
    end,
    emit = function(...)
      emitted[#emitted + 1] = { ... }
    end,
  }
end

local function testClientNet()
  resetLR()
  dofile("client/core/net.lua")

  local runtime = makeEventRuntime()
  local now = 100
  local callbacks = {}
  local net = LR.CreateClientNet({
    resourceName = "spec",
    logger = makeLogger(),
    registerEvent = runtime.register,
    emitServer = runtime.emit,
    now = function() return now end,
    sizeOf = function(value) return value and value.__size or 1 end,
    schedule = function(_, callback)
      callbacks[#callbacks + 1] = callback
      return #callbacks
    end,
    cancel = function(id) callbacks[id] = nil end,
    sessionSalt = "session",
  })

  net:RegisterModule("inventory", {
    events = {
      serverToClient = { notification = { validate = validObject } },
    },
    rpc = {
      clientToServer = {
        useItem = { request = validObject, response = validObject, timeout = 10000 },
      },
    },
  })

  assertTrue(type(runtime.registered["spec:net:s2c"]) == "function")
  assertTrue(type(runtime.registered["spec:net:response"]) == "function")

  local inventory = net:Module("inventory")
  assertEqual(net.Inventory, inventory, "client net module must expose a deterministic typed accessor")
  local notification
  inventory.events.notification:On(function(payload) notification = payload.text end)
  local firstNotifications, secondNotifications = 0, 0
  local disposeFirstNotification = inventory.events.notification:On(function() firstNotifications = firstNotifications + 1 end)
  inventory.events.notification:On(function() secondNotifications = secondNotifications + 1 end)
  disposeFirstNotification()
  runtime.registered["spec:net:s2c"]({
    version = 1,
    kind = "event",
    module = "inventory",
    name = "notification",
    payload = { text = "hello" },
  })
  assertEqual(notification, "hello")
  assertEqual(firstNotifications, 0)
  assertEqual(secondNotifications, 1)

  local resolved
  local requestId = inventory.rpc.useItem:Call({ item = "water" }, function(result)
    resolved = result.ok
  end)
  assertEqual(runtime.emitted[#runtime.emitted][1], "spec:net:c2s")
  assertEqual(runtime.emitted[#runtime.emitted][2].requestId, requestId)

  runtime.registered["spec:net:response"]({
    version = 1,
    kind = "event",
    module = "inventory",
    name = "useItem",
    requestId = requestId,
    payload = { ok = true },
  })
  assertEqual(resolved, nil, "non-response kind must not resolve a pending RPC")

  runtime.registered["spec:net:response"]({
    version = 1,
    kind = "rpc.response",
    module = "inventory",
    name = "useItem",
    requestId = requestId,
    payload = { ok = true },
  })
  assertTrue(resolved)

  assertError(function()
    inventory.rpc.useItem:Call({ __size = 131073 }, function() end)
  end, "payload exceeds")

  local timedOut
  inventory.rpc.useItem:Call({ item = "bread" }, function(_, err)
    timedOut = err and err.code
  end)
  callbacks[#callbacks]()
  assertEqual(timedOut, "RPC_TIMEOUT")

  local disposed
  inventory.rpc.useItem:Call({ item = "cola" }, function(_, err)
    disposed = err and err.code
  end)
  net:Dispose()
  assertEqual(disposed, "TRANSPORT_DISPOSED")
  assertError(function()
    inventory.rpc.useItem:Call({ item = "after-dispose" }, function() end)
  end, "disposed")
end

local function testServerNet()
  resetLR()
  dofile("server/core/net.lua")

  local runtime = makeEventRuntime()
  local clock = 0
  local timers = {}
  local net = LR.CreateServerNet({
    resourceName = "spec",
    logger = makeLogger(),
    registerEvent = runtime.register,
    emitClient = runtime.emit,
    now = function() return clock end,
    sizeOf = function(value) return value and value.__size or 1 end,
    schedule = function(_, callback) timers[#timers + 1] = callback return #timers end,
    cancel = function(id) timers[id] = nil end,
  })

  net:RegisterModule("inventory", {
    rpc = {
      clientToServer = {
        useItem = {
          request = validObject,
          response = validObject,
          mutating = true,
        },
        slowItem = {
          request = validObject,
          response = validObject,
          mutating = true,
          rateLimit = { requestsPerSecond = 1, burst = 1 },
        },
      },
      serverToClient = {
        clientCheck = { request = validObject, response = validObject },
      },
    },
    events = {
      serverToClient = {
        notification = { validate = validObject },
      },
    },
  })

  local inventory = net:Module("inventory")
  assertEqual(net.Inventory, inventory, "server net module must expose a deterministic typed accessor")
  assertError(function()
    inventory.rpc.useItem:Handle({ Execute = function() return {} end })
  end, "Authorize")

  local executions = 0
  inventory.rpc.useItem:Handle({
    Authorize = function(playerSource, payload)
      return playerSource == 12 and payload.allowed == true
    end,
    Execute = function(playerSource)
      executions = executions + 1
      return { source = playerSource }
    end,
  })

  runtime.registered["spec:net:c2s"](12, {
    version = 1,
    kind = "rpc.request",
    module = "inventory",
    name = "useItem",
    requestId = "one",
    payload = { allowed = false },
  })
  local unauthorized = runtime.emitted[#runtime.emitted]
  assertEqual(unauthorized[1], "spec:net:response")
  assertEqual(unauthorized[2], 12)
  assertEqual(unauthorized[3].error.code, "UNAUTHORIZED")

  runtime.registered["spec:net:c2s"](12, {
    version = 1,
    kind = "rpc.request",
    module = "inventory",
    name = "useItem",
    requestId = "two",
    payload = { allowed = true },
  })
  assertEqual(executions, 1)
  assertEqual(runtime.emitted[#runtime.emitted][3].payload.source, 12)

  for index = 1, 18 do
    runtime.registered["spec:net:c2s"](12, {
      version = 1,
      kind = "rpc.request",
      module = "inventory",
      name = "useItem",
      requestId = "burst-" .. index,
      payload = { allowed = true },
    })
  end
  assertEqual(executions, 19, "burst 20 includes the earlier authorized request")

  runtime.registered["spec:net:c2s"](12, {
    version = 1,
    kind = "rpc.request",
    module = "inventory",
    name = "useItem",
    requestId = "limited",
    payload = { allowed = true },
  })
  assertEqual(runtime.emitted[#runtime.emitted][3].error.code, "RATE_LIMITED")

  clock = 1000
  runtime.registered["spec:net:c2s"](12, {
    version = 1,
    kind = "rpc.request",
    module = "inventory",
    name = "useItem",
    requestId = "refilled",
    payload = { allowed = true },
  })
  assertEqual(executions, 20, "bucket should refill at 10 requests/second")

  runtime.registered["spec:net:c2s"](13, {
    version = 1,
    kind = "rpc.request",
    module = "inventory",
    name = "useItem",
    requestId = "duplicate",
    payload = { allowed = false },
  })
  local responsesBeforeDuplicate = #runtime.emitted
  runtime.registered["spec:net:c2s"](13, {
    version = 1,
    kind = "rpc.request",
    module = "inventory",
    name = "useItem",
    requestId = "duplicate",
    payload = { allowed = true },
  })
  assertEqual(#runtime.emitted, responsesBeforeDuplicate + 1)
  assertEqual(runtime.emitted[#runtime.emitted][3].error.code, "DUPLICATE_REQUEST")
  assertEqual(executions, 20, "duplicate correlation must never execute a handler")

  local slowExecutions = 0
  inventory.rpc.slowItem:Handle({
    Authorize = function() return true end,
    Execute = function()
      slowExecutions = slowExecutions + 1
      return { ok = true }
    end,
  })
  for index = 1, 2 do
    runtime.registered["spec:net:c2s"](14, {
      version = 1,
      kind = "rpc.request",
      module = "inventory",
      name = "slowItem",
      requestId = "slow-" .. index,
      payload = {},
    })
  end
  assertEqual(slowExecutions, 1, "endpoint rate-limit override must be enforced")
  assertEqual(runtime.emitted[#runtime.emitted][3].error.code, "RATE_LIMITED")

  net:ForgetPlayer(12)
  runtime.registered["spec:net:c2s"](12, {
    version = 1,
    kind = "rpc.request",
    module = "inventory",
    name = "useItem",
    requestId = "one",
    payload = { allowed = true },
  })
  assertEqual(executions, 21, "disconnect cleanup must clear rate and replay state")

  inventory.events.notification:Emit(12, { text = "done" })
  local notification = runtime.emitted[#runtime.emitted]
  assertEqual(notification[1], "spec:net:s2c")
  assertEqual(notification[2], 12)

  assertError(function()
    inventory.events.notification:Emit(12, { __size = 131073 })
  end, "payload exceeds")

  local serverRpcResult
  local serverRequestId = inventory.rpc.clientCheck:Call(12, {}, function(result)
    serverRpcResult = result
  end)
  runtime.registered["spec:net:response"](12, {
    version = 1,
    kind = "event",
    module = "inventory",
    name = "clientCheck",
    requestId = serverRequestId,
    payload = { ok = true },
  })
  assertEqual(serverRpcResult, nil, "server RPC must ignore a forged non-response kind")
  runtime.registered["spec:net:response"](12, {
    version = 1,
    kind = "rpc.response",
    module = "inventory",
    name = "clientCheck",
    requestId = serverRequestId,
    payload = { ok = true },
  })
  assertTrue(serverRpcResult.ok)

  for index = 1, 30 do
    runtime.registered["spec:net:c2s"](15, {
      version = 1,
      kind = "rpc.request",
      module = "inventory",
      name = "unknown" .. index,
      requestId = "unknown-" .. index,
      payload = {},
    })
  end
  local sourceFifteenBuckets = 0
  for key in pairs(net.buckets) do
    if key:sub(1, 3) == "15:" and key ~= "15:ingress" then
      sourceFifteenBuckets = sourceFifteenBuckets + 1
    end
  end
  assertEqual(sourceFifteenBuckets, 1, "unknown endpoints must share one bounded rate bucket")
  net:Dispose()
  assertError(function()
    inventory.events.notification:Emit(12, { text = "after-dispose" })
  end, "disposed")
end

local function testEncodingFailureIsClosed()
  resetLR()
  local previousJson = json
  json = { encode = function() error("cannot encode cyclic value") end }
  dofile("client/core/nui.lua")
  local callback
  local bridge = LR.CreateClientNui({
    logger = makeLogger(),
    registerCallback = function(_, handler) callback = handler return function() end end,
    send = function() return true end,
  })
  bridge:RegisterModule("encoding", {
    events = { toNui = { changed = { validate = validObject } }, toClient = {} },
    rpc = { toNui = {}, toClient = {} },
  })
  bridge:MarkReady()
  local cyclic = {}
  cyclic.self = cyclic
  assertError(function()
    bridge.Encoding().events.changed:Emit(cyclic)
  end, "JSON encoding failed")
  bridge:Dispose()
  assertTrue(type(callback) == "function")
  json = previousJson
end

local function testGeneratedRegistryIntegration()
  resetLR()
  dofile("shared/core/schema.lua")
  dofile("client/generated/contracts.lua")
  dofile("client/generated/contracts/trucker.lua")
  dofile("client/core/nui.lua")
  dofile("client/core/net.lua")
  dofile("client/core/public.lua")

  local callbacks = {}
  local clientRuntime = makeEventRuntime()
  local nui = LR.CreateClientNui({
    registerCallback = function(name, handler) callbacks[name] = handler return function() end end,
    send = function() return true end,
    sizeOf = function() return 1 end,
    logger = makeLogger(),
  })
  local clientNet = LR.CreateClientNet({
    resourceName = "spec",
    registerEvent = clientRuntime.register,
    emitServer = clientRuntime.emit,
    sizeOf = function() return 1 end,
    logger = makeLogger(),
  })
  local clientPublic = LR.CreateClientPublic({
    registerExport = function() return function() end end,
    invokeExport = function() return {} end,
    logger = makeLogger(),
  })
  assertTrue(type(nui.Trucker) == "function")
  assertTrue(type(nui.Trucker().state.snapshot.Set) == "function")
  assertTrue(type(clientNet.Trucker.rpc.getState.Call) == "function")
  assertTrue(type(clientPublic.Trucker.Register) == "function")
  nui:Dispose()
  clientNet:Dispose()
  clientPublic:Dispose()

  resetLR()
  dofile("shared/core/schema.lua")
  dofile("server/generated/contracts.lua")
  dofile("server/generated/contracts/trucker.lua")
  dofile("server/core/net.lua")
  local serverRuntime = makeEventRuntime()
  local serverNet = LR.CreateServerNet({
    resourceName = "spec",
    registerEvent = serverRuntime.register,
    emitClient = serverRuntime.emit,
    sizeOf = function() return 1 end,
    logger = makeLogger(),
  })
  assertTrue(type(serverNet.Trucker.rpc.getState.Handle) == "function")
  assertTrue(type(serverNet.Trucker.events.notice.Emit) == "function")
  serverNet:Dispose()
end

testClientNui()
testClientNet()
testServerNet()
testEncodingFailureIsClosed()
testGeneratedRegistryIntegration()

print("PASS transport security specification")
