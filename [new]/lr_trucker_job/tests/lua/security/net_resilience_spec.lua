local function assertEqual(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. (": expected %s, got %s"):format(tostring(expected), tostring(actual)))
  end
end

local function assertTrue(value, message)
  if value ~= true then error(message or "expected true") end
end

local function assertError(fn, expected)
  local ok, err = pcall(fn)
  if ok then error("expected operation to fail") end
  if expected and not tostring(err):find(expected, 1, true) then
    error(("expected error containing %q, got %q"):format(expected, tostring(err)))
  end
end

local function validObject(value) return type(value) == "table" end
local function logger()
  return { Debug = function() end, Info = function() end, Warn = function() end, Error = function() end }
end

local function eventRuntime()
  local handlers, emitted = {}, {}
  return {
    handlers = handlers,
    emitted = emitted,
    register = function(name, handler)
      handlers[name] = handler
      return function()
        if handlers[name] == handler then handlers[name] = nil end
      end
    end,
    emit = function(...) emitted[#emitted + 1] = { ... } end,
  }
end

local function clientNet(options)
  LR = {}
  dofile("client/core/net.lua")
  local runtime = eventRuntime()
  local timers = {}
  local config = {
    resourceName = "spec",
    logger = logger(),
    registerEvent = runtime.register,
    emitServer = runtime.emit,
    sizeOf = function(value) return value and value.__size or 1 end,
    schedule = function(_, callback)
      local id = #timers + 1
      timers[id] = callback
      return id
    end,
    cancel = function(id) timers[id] = nil end,
    sessionSalt = "client",
  }
  for key, value in pairs(options or {}) do config[key] = value end
  return LR.CreateClientNet(config), runtime, timers
end

local client, clientRuntime, clientTimers = clientNet({ maxPayload = 8 })
client:RegisterModule("inventory", {
  events = { clientToServer = { useItem = { validate = validObject } } },
  rpc = {
    clientToServer = { useItem = { request = validObject, response = validObject } },
    serverToClient = { refresh = { request = validObject, response = validObject } },
  },
})
assertTrue(client.Inventory.events.useItem ~= nil and client.Inventory.rpc.useItem ~= nil,
  "event and RPC endpoints may share a name")

local responseError
local requestId = client.Inventory.rpc.useItem:Call({}, function(_, err) responseError = err and err.code end)
clientRuntime.handlers["spec:net:response"]({
  version = 1, kind = "rpc.response", module = "inventory", name = "useItem",
  requestId = requestId, payload = { __size = 9 },
})
assertEqual(responseError, "PAYLOAD_TOO_LARGE", "oversized client RPC responses must fail closed")

local firstHandlerCalls, replacementHandlerCalls = 0, 0
local oldDisposer = client.Inventory.rpc.refresh:Handle(function()
  firstHandlerCalls = firstHandlerCalls + 1
  return {}
end)
oldDisposer()
client.Inventory.rpc.refresh:Handle(function()
  replacementHandlerCalls = replacementHandlerCalls + 1
  return {}
end)
oldDisposer()
local incoming = {
  version = 1, kind = "rpc.request", module = "inventory", name = "refresh",
  requestId = "refresh-1", payload = {},
}
clientRuntime.handlers["spec:net:s2c"](incoming)
clientRuntime.handlers["spec:net:s2c"](incoming)
assertEqual(firstHandlerCalls, 0)
assertEqual(replacementHandlerCalls, 1, "replacement handler must survive stale disposer and replay")
assertEqual(clientRuntime.emitted[#clientRuntime.emitted][2].error.code, "DUPLICATE_REQUEST")

client:Dispose()

local failedClient, _, failedClientTimers = clientNet({
  emitServer = function() error("emit failed") end,
})
failedClient:RegisterModule("inventory", {
  rpc = { clientToServer = { useItem = { request = validObject, response = validObject } } },
})
assertError(function()
  failedClient.Inventory.rpc.useItem:Call({}, function() end)
end, "emit failed")
assertEqual(next(failedClient.pending), nil, "client send failure must rollback pending state")
assertEqual(next(failedClientTimers), nil, "client send failure must cancel its timer")

failedClient.emitServer = function() end
local cleanupNotified = false
failedClient.Inventory.rpc.useItem:Call({}, function() error("consumer failed") end)
failedClient.Inventory.rpc.useItem:Call({}, function() cleanupNotified = true end)
assertTrue(pcall(function() failedClient:Dispose() end), "client cleanup must isolate consumer callbacks")
assertEqual(next(failedClient.pending), nil)
assertTrue(cleanupNotified)

local rollbackRuntime = eventRuntime()
LR = {}
dofile("client/core/net.lua")
assertError(function()
  LR.CreateClientNet({
    resourceName = "rollback",
    logger = logger(),
    registerEvent = rollbackRuntime.register,
    emitServer = rollbackRuntime.emit,
    sizeOf = function() return 1 end,
    contracts = {
      broken = {
        net = {
          events = {
            clientToServer = { ping = { validate = validObject } },
            serverToClient = { ping = { validate = validObject } },
          },
        },
      },
    },
  })
end, "duplicate network event endpoint")
assertEqual(next(rollbackRuntime.handlers), nil, "failed client construction must rollback raw listeners")

local function serverNet(options)
  LR = {}
  dofile("server/core/net.lua")
  local runtime = eventRuntime()
  local timers = {}
  local config = {
    resourceName = "spec",
    logger = logger(),
    registerEvent = runtime.register,
    registerPlayerDropped = function() return function() end end,
    emitClient = runtime.emit,
    sizeOf = function(value) return value and value.__size or 1 end,
    schedule = function(_, callback)
      local id = #timers + 1
      timers[id] = callback
      return id
    end,
    cancel = function(id) timers[id] = nil end,
    now = function() return 0 end,
    sessionSalt = "server",
  }
  for key, value in pairs(options or {}) do config[key] = value end
  return LR.CreateServerNet(config), runtime, timers
end

local sizeCalls = 0
local server, serverRuntime = serverNet({
  maxPayload = 8,
  ingressRate = 1,
  ingressBurst = 1,
  sizeOf = function(value)
    sizeCalls = sizeCalls + 1
    return value and value.__size or 1
  end,
})
server:RegisterModule("inventory", {
  events = {
    clientToServer = { mutate = { validate = validObject } },
    serverToClient = { notification = { validate = validObject } },
  },
  rpc = {
    clientToServer = { mutate = { request = validObject, response = validObject } },
    serverToClient = { inspect = { request = validObject, response = validObject } },
  },
})
assertTrue(server.Inventory.events.mutate ~= nil and server.Inventory.rpc.mutate ~= nil,
  "event and RPC endpoints may share a name")
server.Inventory.rpc.mutate:Handle(function() return { __size = 9 } end)

server.Inventory.events.notification:Emit(-1, {})
assertEqual(serverRuntime.emitted[#serverRuntime.emitted][2], -1, "-1 must broadcast server events")
assertError(function() server.Inventory.events.notification:Emit(0, {}) end, "-1 or a positive integer")
sizeCalls = 0
assertError(function() server.Inventory.rpc.inspect:Call(-1, {}, function() end) end, "positive integer")
assertError(function() server.Inventory.rpc.inspect:Call(0, {}, function() end) end, "positive integer")
assertError(function() server.Inventory.rpc.inspect:Call(1.5, {}, function() end) end, "positive integer")

local oversized = {
  version = 1, kind = "rpc.request", module = "inventory", name = "mutate",
  requestId = "large-1", payload = { __size = 9 },
}
serverRuntime.handlers["spec:net:c2s"](10, oversized)
oversized.requestId = "large-2"
serverRuntime.handlers["spec:net:c2s"](10, oversized)
assertEqual(sizeCalls, 1, "coarse ingress limiting must run before payload encoding")

local responseServer, responseRuntime = serverNet({maxPayload = 8})
responseServer:RegisterModule("inventory", {
  rpc = {
    clientToServer = { mutate = { request = validObject, response = validObject } },
    serverToClient = { inspect = { request = validObject, response = validObject } },
  },
})
responseServer.Inventory.rpc.mutate:Handle(function() return { __size = 9 } end)
responseRuntime.handlers["spec:net:c2s"](11, {
  version = 1, kind = "rpc.request", module = "inventory", name = "mutate",
  requestId = "mutate-1", payload = {},
})
assertEqual(responseRuntime.emitted[#responseRuntime.emitted][3].error.code, "PAYLOAD_TOO_LARGE")

local serverResponseError
local serverRequestId = responseServer.Inventory.rpc.inspect:Call(11, {}, function(_, err)
  serverResponseError = err and err.code
end)
responseRuntime.handlers["spec:net:response"](11, {
  version = 1, kind = "rpc.response", module = "inventory", name = "inspect",
  requestId = serverRequestId, payload = { __size = 9 },
})
assertEqual(serverResponseError, "PAYLOAD_TOO_LARGE")

responseServer.emitClient = function() error("emit failed") end
assertError(function()
  responseServer.Inventory.rpc.inspect:Call(12, {}, function() end)
end, "emit failed")
for _, pending in pairs(responseServer.pending) do
  if pending.source == 12 then error("server send failure leaked pending state") end
end

responseServer.emitClient = function() end
local droppedNotified = false
responseServer.Inventory.rpc.inspect:Call(13, {}, function() error("consumer failed") end)
responseServer.Inventory.rpc.inspect:Call(13, {}, function() droppedNotified = true end)
assertTrue(pcall(function() responseServer:ForgetPlayer(13) end))
assertTrue(droppedNotified, "ForgetPlayer must notify every pending callback")
responseServer:Dispose()

local serverRollbackRuntime = eventRuntime()
LR = {}
dofile("server/core/net.lua")
assertError(function()
  LR.CreateServerNet({
    resourceName = "rollback",
    logger = logger(),
    registerEvent = serverRollbackRuntime.register,
    registerPlayerDropped = function(handler)
      serverRollbackRuntime.handlers.playerDropped = handler
      return function() serverRollbackRuntime.handlers.playerDropped = nil end
    end,
    emitClient = serverRollbackRuntime.emit,
    sizeOf = function() return 1 end,
    contracts = {
      broken = {
        net = {
          events = {
            clientToServer = { ping = { validate = validObject } },
            serverToClient = { ping = { validate = validObject } },
          },
        },
      },
    },
  })
end, "duplicate network event endpoint")
assertEqual(next(serverRollbackRuntime.handlers), nil, "failed server construction must rollback raw listeners")

print("PASS network resilience specification")
