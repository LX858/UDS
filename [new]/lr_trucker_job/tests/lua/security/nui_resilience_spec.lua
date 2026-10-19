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

local function validProfile(value)
  if type(value) ~= "table" or type(value.count) ~= "number" or value.count % 1 ~= 0
    or type(value.message) ~= "string" then
    return false, "expected profile"
  end
  for key in pairs(value) do
    if key ~= "count" and key ~= "message" then return false, "unexpected profile field" end
  end
  return true
end

local function validProfilePatch(value)
  if type(value) ~= "table" then return false, "expected profile patch" end
  for key, item in pairs(value) do
    if key == "count" then
      if type(item) ~= "number" or item % 1 ~= 0 then return false, "invalid count" end
    elseif key == "message" then
      if type(item) ~= "string" then return false, "invalid message" end
    else
      return false, "unexpected profile patch field"
    end
  end
  return true
end

local function validTable(value)
  return type(value) == "table"
end

local function logger()
  return { Debug = function() end, Info = function() end, Warn = function() end, Error = function() end }
end

local contract = {
  state = {
    profile = {
      default = { count = 0, message = "ready" },
      validate = validProfile,
      patchValidate = validProfilePatch,
      object = true,
    },
    preferences = {
      default = { compact = false },
      validate = validTable,
      patchValidate = validTable,
      object = true,
    },
    items = {
      default = { "water" },
      validate = validTable,
      object = false,
    },
  },
  events = { toNui = {}, toClient = {} },
  rpc = {
    toNui = { confirm = { request = validTable, response = validTable } },
    toClient = {},
  },
}

local function createBridge(overrides)
  LR = {}
  dofile("client/core/nui.lua")
  LR.JSON_NULL = {}
  local callbacks, messages, timers = {}, {}, {}
  local options = {
    logger = logger(),
    resourceName = "spec",
    contracts = { inventory = { nui = contract } },
    registerCallback = function(name, handler)
      callbacks[name] = handler
      return function() callbacks[name] = nil end
    end,
    send = function(envelope) messages[#messages + 1] = envelope return true end,
    sizeOf = function(value) return value and value.__size or 1 end,
    setTimeout = function(_, callback)
      local id = #timers + 1
      timers[id] = callback
      return id
    end,
    clearTimeout = function(id) timers[id] = nil end,
    sessionSalt = "session",
    stateReplayLimit = 2,
    stateReplayMaxBytes = 3,
  }
  for key, value in pairs(overrides or {}) do options[key] = value end
  local bridge = LR.CreateClientNui(options)
  return bridge, callbacks, messages, timers
end

local function invoke(callbacks, envelope)
  local response
  callbacks["lr_bridge"](envelope, function(value) response = value end)
  return response
end

local function stateCommand(kind, requestId, sessionId, payload)
  return {
    version = 2,
    module = "inventory",
    kind = kind,
    name = "profile",
    requestId = requestId,
    sessionId = sessionId,
    payload = payload,
  }
end

local bridge, callbacks, messages, timers = createBridge()
local inventory = bridge.Inventory()
local profile = inventory.state.profile

local notReady = invoke(callbacks, stateCommand("state.set", "before-ready", "session-a", {
  count = 1,
  message = "early",
}))
assertEqual(notReady.error.code, "NUI_NOT_READY")

local defaultCopy = profile:Get()
defaultCopy.message = "mutated"
assertEqual(profile:Get().message, "ready", "Get must return a DTO clone")
assertTrue(inventory.state.preferences:Set({ compact = true }), "all states must be writable from Lua")
assertError(function() inventory.state.items:Patch({ [1] = "bread" }) end, "object states")

local watcherOrder = {}
local watcherCalls = 0
profile:Watch(function(value)
  watcherCalls = watcherCalls + 1
  watcherOrder[#watcherOrder + 1] = "first"
  value.message = "watcher mutation"
end)
profile:Watch(function(value)
  watcherOrder[#watcherOrder + 1] = "second"
  assertTrue(value.message ~= "watcher mutation", "watchers must receive independent DTO clones")
end)

assertTrue(profile:Set({ count = 1, message = "starting" }))
assertEqual(#messages, 0, "pre-ready state writes must queue rather than send")
assertEqual(watcherOrder[1], "first", "state watchers must run FIFO")
assertEqual(watcherOrder[2], "second", "state watchers must run FIFO")

local readyCalls = 0
local readyAcknowledged = false
bridge:WhenReady(function()
  assertTrue(readyAcknowledged, "ready callbacks must run after the handshake ACK")
  readyCalls = readyCalls + 1
end)
local callableReply = setmetatable({}, {
  __call = function(_, response)
    readyAcknowledged = response.kind == "rpc.response"
      and response.sessionId == "session-a"
      and response.payload.sessionId == "session-a"
  end,
})
callbacks["lr_bridge"]({
  version = 2,
  module = "core",
  kind = "event",
  name = "ready",
  sessionId = "session-a",
  payload = { sessionId = "session-a" },
}, callableReply)
assertTrue(readyAcknowledged, "callable CFX callbacks must receive the ready ACK synchronously")
assertEqual(readyCalls, 0)
timers[1]()
assertEqual(readyCalls, 1)
assertEqual(#messages, 4, "ready must send all three states and the synchronized marker")
local sawDefault, sawProfile = false, false
for _, envelope in ipairs(messages) do
  assertEqual(envelope.version, 2)
  if envelope.name == "items" then
    sawDefault = envelope.revision == 1 and envelope.payload[1] == "water"
  elseif envelope.name == "profile" then
    sawProfile = envelope.kind == "state.snapshot" and envelope.revision == 2
      and envelope.sessionId == "session-a" and envelope.payload.message == "starting"
  end
end
assertTrue(sawDefault, "ready must synchronize untouched defaults at baseline revision 1")
assertTrue(sawProfile, "ready must synchronize the latest queued canonical value")
assertEqual(messages[#messages].module, "core")
assertEqual(messages[#messages].name, "synced")
assertEqual(messages[#messages].payload.sessionId, "session-a")

assertTrue(profile:Patch({ message = "lua" }))
local luaPatchSnapshot = messages[#messages]
assertEqual(luaPatchSnapshot.kind, "state.snapshot", "Lua patches must emit full snapshots")
assertEqual(luaPatchSnapshot.revision, 3)
assertEqual(luaPatchSnapshot.payload.count, 1)
assertEqual(luaPatchSnapshot.payload.message, "lua")

local wireOrder = {}
bridge.send = function(envelope)
  messages[#messages + 1] = envelope
  wireOrder[#wireOrder + 1] = "snapshot"
  return true
end
local browserPatch
callbacks["lr_bridge"](stateCommand("state.patch", "patch-1", "session-a", { count = 4 }), function(value)
  wireOrder[#wireOrder + 1] = "response"
  browserPatch = value
end)
assertEqual(wireOrder[1], "snapshot", "canonical snapshot must be sent before the command response")
assertEqual(wireOrder[2], "response")
assertEqual(browserPatch.kind, "rpc.response")
assertEqual(browserPatch.revision, 4)
assertEqual(browserPatch.payload.count, 4)
assertEqual(browserPatch.payload.message, "lua", "browser patches must merge against latest Lua state")
assertEqual(profile:Get().count, 4)
assertEqual(messages[#messages].kind, "state.snapshot", "browser patches must never emit state.patch")
assertEqual(messages[#messages].payload.message, "lua")

local revisionCommand = stateCommand("state.set", "browser-revision", "session-a", {
  count = 4,
  message = "lua",
})
revisionCommand.revision = 5
local revisionResponse = invoke(callbacks, revisionCommand)
assertEqual(revisionResponse.error.code, "INVALID_STATE_COMMAND", "browser commands must not supply revisions")

assertTrue(profile:Set({ count = 5, message = "lua" }))
local beforeNoopMessages = #messages
local beforeNoopWatchers = watcherCalls
local noopCommand = stateCommand("state.set", "noop-1", "session-a", { count = 5, message = "lua" })
local noopResponse = invoke(callbacks, noopCommand)
assertEqual(noopResponse.revision, 5, "no-op commands must return the current authoritative revision")
assertEqual(noopResponse.payload.count, 5)
assertEqual(#messages, beforeNoopMessages, "no-op commands must not emit snapshots")
assertEqual(watcherCalls, beforeNoopWatchers, "no-op commands must not notify watchers")
assertEqual(profile:Set({ count = 5, message = "lua" }), false, "local no-op writes must share commit semantics")

local replayResponse = invoke(callbacks, noopCommand)
assertEqual(replayResponse.revision, noopResponse.revision, "duplicate commands must replay their original response")
assertEqual(#messages, beforeNoopMessages)
local reusedResponse = invoke(callbacks, stateCommand("state.set", "noop-1", "session-a", {
  count = 6,
  message = "changed",
}))
assertEqual(reusedResponse.error.code, "REQUEST_ID_REUSED")
assertEqual(profile:Get().count, 5, "changed command reuse must be rejected atomically")

invoke(callbacks, stateCommand("state.set", "noop-2", "session-a", { count = 5, message = "lua" }))
assertTrue(#bridge.stateReplayOrder <= 1, "state replay history must honor its byte budget")
assertTrue(bridge.stateReplayBytes <= 3, "state replay byte accounting must remain bounded")

local atomicValue = profile:Get()
local atomicMessages, atomicWatchers = #messages, watcherCalls
local malformed = invoke(callbacks, stateCommand("state.set", "malformed", "session-a", {
  count = "invalid",
  message = "bad",
}))
assertEqual(malformed.error.code, "INVALID_STATE")
local oversized = invoke(callbacks, stateCommand("state.set", "oversized", "session-a", {
  count = 9,
  message = "large",
  __size = 300000,
}))
assertEqual(oversized.error.code, "PAYLOAD_TOO_LARGE")
local originalSizeOf = bridge.sizeOf
bridge.sizeOf = function(value)
  if type(value) == "table" and value.message == "cannot-encode" then error("encoding failed") end
  return originalSizeOf(value)
end
local unserializable = invoke(callbacks, stateCommand("state.set", "unserializable", "session-a", {
  count = 9,
  message = "cannot-encode",
}))
bridge.sizeOf = originalSizeOf
assertEqual(unserializable.error.code, "INVALID_PAYLOAD")
assertEqual(profile:Get().count, atomicValue.count, "rejected writes must not mutate canonical state")
assertEqual(profile:Get().message, atomicValue.message)
assertEqual(#messages, atomicMessages, "rejected writes must not emit snapshots")
assertEqual(watcherCalls, atomicWatchers, "rejected writes must not notify watchers")

local inboundSnapshot = invoke(callbacks, {
  version = 2,
  module = "inventory",
  kind = "state.snapshot",
  name = "profile",
  revision = 99,
  payload = { count = 99, message = "forbidden" },
})
assertEqual(inboundSnapshot.error.code, "STATE_SNAPSHOT_READ_ONLY")

local invalidReady = invoke(callbacks, {
  version = 2,
  module = "core",
  kind = "event",
  name = "ready",
  payload = {},
})
assertEqual(invalidReady.error.code, "INVALID_SESSION")

local replacedRpcError
local replacedRequestId = inventory.rpc.confirm:Call({}, function(_, err)
  replacedRpcError = err and err.code
end)
assertTrue(bridge.pending[replacedRequestId] ~= nil)
local readyB = invoke(callbacks, {
  version = 2,
  module = "core",
  kind = "event",
  name = "ready",
  payload = { sessionId = "session-b" },
})
assertEqual(readyB.sessionId, "session-b")
assertEqual(replacedRpcError, "NUI_SESSION_REPLACED", "new sessions must reject old pending RPCs")
assertEqual(next(bridge.pending), nil)
assertEqual(bridge:IsReady(), false, "a replacement session must synchronize before becoming ready")
local beforeBlockedRpc = #messages
local blockedRpcError
inventory.rpc.confirm:Call({}, function(_, err) blockedRpcError = err and err.code end)
assertEqual(blockedRpcError, "NUI_NOT_READY")
assertEqual(#messages, beforeBlockedRpc, "outgoing RPC must stay blocked while the new session synchronizes")
local stale = invoke(callbacks, stateCommand("state.set", "stale", "session-a", {
  count = 7,
  message = "stale",
}))
assertEqual(stale.error.code, "STALE_SESSION")
assertEqual(profile:Get().count, 5)
local reusedInNewSession = invoke(callbacks, stateCommand("state.set", "noop-1", "session-b", {
  count = 6,
  message = "new session",
}))
assertEqual(reusedInNewSession.revision, 6, "a new ready session must receive a fresh replay window")
timers[2]()
assertEqual(bridge:IsReady(), true)
assertEqual(readyCalls, 1, "re-ready must preserve one-shot ready callback semantics")
local resyncStart = #messages - 3
local resyncedDefault = false
for index = resyncStart, #messages do
  local envelope = messages[index]
  if envelope and envelope.name == "items" and envelope.revision == 1 then resyncedDefault = true end
end
assertTrue(resyncedDefault, "re-ready must resend states that still hold defaults")
assertEqual(messages[#messages].name, "synced")
assertEqual(messages[#messages].sessionId, "session-b")

local fifoBridge = createBridge()
local fifoProfile = fifoBridge.Inventory().state.profile
local reentrantOrder = {}
fifoProfile:Watch(function(value)
  reentrantOrder[#reentrantOrder + 1] = "first:" .. value.message
  if value.message == "outer" then
    fifoProfile:Set({ count = value.count + 1, message = "inner" })
  end
end)
fifoProfile:Watch(function(value)
  reentrantOrder[#reentrantOrder + 1] = "second:" .. value.message
end)
fifoProfile:Set({ count = 1, message = "outer" })
assertEqual(reentrantOrder[1], "first:outer")
assertEqual(reentrantOrder[2], "second:outer", "outer revision must finish before reentrant notifications")
assertEqual(reentrantOrder[3], "first:inner", "reentrant revisions must be queued")
assertEqual(reentrantOrder[4], "second:inner")
fifoBridge:Dispose()

local sizeContract = {
  state = {
    profile = {
      default = { count = 0, message = "123456789" },
      validate = validProfile,
      patchValidate = validProfilePatch,
      object = true,
    },
  },
  events = { toNui = {}, toClient = {} },
  rpc = { toNui = {}, toClient = {} },
}
local sizeBridge, sizeCallbacks, sizeMessages, sizeTimers = createBridge({
  contracts = { inventory = { nui = sizeContract } },
  maxPayload = 10,
  sizeOf = function(value)
    if type(value) == "table" and value.sessionId then return 1 end
    if type(value) == "table" and value.message then
      return #value.message + #tostring(value.count)
    end
    return 1
  end,
})
invoke(sizeCallbacks, {
  version = 2,
  module = "core",
  kind = "event",
  name = "ready",
  payload = { sessionId = "size-session" },
})
sizeTimers[1]()
local sizeMessageCount = #sizeMessages
local mergedOversize = invoke(sizeCallbacks, stateCommand("state.patch", "merge-large", "size-session", {
  count = 10,
}))
assertEqual(mergedOversize.error.code, "PAYLOAD_TOO_LARGE")
assertEqual(sizeBridge.Inventory().state.profile:Get().count, 0, "merged payload size must be checked before mutation")
assertEqual(#sizeMessages, sizeMessageCount)
sizeBridge:Dispose()

local staleProfile = profile
bridge:Dispose()
assertEqual(callbacks["lr_bridge"], nil)
assertEqual(bridge.activeSessionId, nil)
assertEqual(next(bridge.stateReplay), nil)
assertEqual(next(bridge.queuedStates), nil)
assertEqual(next(staleProfile.watchers), nil)
assertError(function() staleProfile:Get() end, "disposed")
assertError(function() staleProfile:Set({ count = 0, message = "disposed" }) end, "disposed")

print("PASS NUI resilience specification")
