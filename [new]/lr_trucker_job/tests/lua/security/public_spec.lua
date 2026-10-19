local function assertEqual(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. (": expected %s, got %s"):format(tostring(expected), tostring(actual)))
  end
end

local function assertTrue(value, message)
  if value ~= true then error(message or ("expected true, got " .. tostring(value))) end
end

local function assertError(fn, expected)
  local ok, err = pcall(fn)
  if ok then error("expected operation to fail") end
  if expected and not tostring(err):find(expected, 1, true) then
    error(("expected error containing %q, got %q"):format(expected, tostring(err)))
  end
end

local function validObject(value)
  return type(value) == "table"
end

local function makeLogger()
  return { Debug = function() end, Info = function() end, Warn = function() end, Error = function() end }
end

local function testPublicExports(path, constructorName, side)
  LR = {}
  dofile(path)
  local registered, externalCalls = {}, {}
  local public = LR[constructorName]({
    logger = makeLogger(),
    sizeOf = function() return 1 end,
    contracts = {
      inventory = { getSnapshot = { request = validObject, response = validObject } },
    },
    registerExport = function(name, handler)
      registered[name] = handler
      return function() registered[name] = nil end
    end,
    invokeExport = function(resource, name, payload)
      externalCalls[#externalCalls + 1] = { resource, name, payload }
      return { ok = true }
    end,
  })

  assertTrue(type(public.Inventory) == "table", "public module facade must be deterministic")
  assertTrue(type(public.Inventory.Register) == "function")
  assertEqual(public.Inventory.External, nil, "provider facade must not expose consumer methods")
  assertTrue(type(public.External.Inventory) == "function")
  assertError(function()
    public:Register("inventory", { arbitrary = function() end })
  end, "not declared")

  public.Inventory:Register({
    getSnapshot = function(payload) return { id = payload.id, side = side } end,
  })
  assertTrue(type(registered.inventory_getSnapshot) == "function")
  assertEqual(registered.inventory_getSnapshot({ id = 4 }).side, side)
  assertError(function() registered.inventory_getSnapshot("invalid") end, "request validation failed")

  local result = public.External.Inventory("other_resource"):GetSnapshot({ id = 10 })
  assertTrue(result.ok)
  assertEqual(externalCalls[1][1], "other_resource")
  assertEqual(externalCalls[1][2], "inventory_getSnapshot")
  assertEqual(public.External.Unknown, nil, "undeclared modules must not get an external accessor")
  public:Dispose()
  assertEqual(registered.inventory_getSnapshot, nil)
  assertEqual(public.External.Inventory, nil, "external accessors must be cleared on dispose")
end

local function testDefaultExportInvocation()
  LR = {}
  local previousExports = exports
  local resourceProxy = {}
  resourceProxy.inventory_getSnapshot = function(self, payload)
    if self ~= resourceProxy then error("export proxy self was not forwarded") end
    return { id = payload.id }
  end
  exports = { other_resource = resourceProxy }
  dofile("client/core/public.lua")
  local public = LR.CreateClientPublic({
    sizeOf = function() return 1 end,
    contracts = { inventory = { getSnapshot = { request = validObject, response = validObject } } },
    registerExport = function() return function() end end,
  })
  local result = public.External.Inventory("other_resource"):GetSnapshot({ id = 42 })
  assertEqual(result.id, 42, "FiveM export proxy must receive its implicit self argument")
  exports = previousExports
end

local function testDefaultExportRegistration()
  LR = {}
  local previousGetCurrentResourceName = GetCurrentResourceName
  local previousAddEventHandler = AddEventHandler
  local previousRemoveEventHandler = RemoveEventHandler
  local eventName, eventHandler, removed
  GetCurrentResourceName = function() return "spec" end
  AddEventHandler = function(name, handler)
    eventName, eventHandler = name, handler
    return 91
  end
  RemoveEventHandler = function(token) removed = token end
  dofile("server/core/public.lua")
  local public = LR.CreateServerPublic({
    sizeOf = function() return 1 end,
    contracts = { inventory = { getSnapshot = { request = validObject, response = validObject } } },
  })
  public.Inventory:Register({ getSnapshot = function(payload) return { id = payload.id } end })
  assertEqual(eventName, "__cfx_export_spec_inventory_getSnapshot")
  local exported
  eventHandler(function(handler) exported = handler end)
  assertEqual(exported({ id = 7 }).id, 7)
  public:Dispose()
  assertEqual(removed, 91, "public export handler must be removable")
  GetCurrentResourceName = previousGetCurrentResourceName
  AddEventHandler = previousAddEventHandler
  RemoveEventHandler = previousRemoveEventHandler
end

local function testRegistrationRollsBackWhenALaterExportFails(path, constructorName)
  LR = {}
  dofile(path)
  local active, registrationCount = {}, 0
  local public = LR[constructorName]({
    logger = makeLogger(),
    sizeOf = function() return 1 end,
    contracts = {
      inventory = {
        first = { request = validObject, response = validObject },
        second = { request = validObject, response = validObject },
      },
    },
    registerExport = function(name)
      registrationCount = registrationCount + 1
      if registrationCount == 2 then error("simulated registration failure") end
      active[name] = true
      return function() active[name] = nil end
    end,
  })

  assertError(function()
    public.Inventory:Register({
      first = function(payload) return payload end,
      second = function(payload) return payload end,
    })
  end, "public export registration failed")
  assertEqual(next(active), nil, "partially registered exports must be removed")
  assertEqual(next(public.registered), nil, "registry must remain unchanged after rollback")
end

local function testMutatingExportAuthorization(path, constructorName)
  LR = {}
  dofile(path)
  local registered = {}
  local invokingResource = "evil_resource"
  local public = LR[constructorName]({
    logger = makeLogger(),
    sizeOf = function() return 1 end,
    contracts = {
      inventory = {
        setBalance = {
          request = validObject,
          response = validObject,
          mutating = true,
        },
      },
    },
    getInvokingResource = function() return invokingResource end,
    registerExport = function(name, handler)
      registered[name] = handler
      return function() registered[name] = nil end
    end,
  })

  assertError(function()
    public.Inventory:Register({ setBalance = function(payload) return payload end })
  end, "requires Authorize")

  public.Inventory:Register({
    setBalance = {
      Authorize = function(resourceName, payload)
        return resourceName == "trusted_resource" and payload.allowed == true
      end,
      Execute = function(resourceName, payload)
        return { resource = resourceName, value = payload.value }
      end,
    },
  })

  assertError(function()
    registered.inventory_setBalance({ allowed = true, value = 10 })
  end, "UNAUTHORIZED")
  invokingResource = nil
  assertError(function()
    registered.inventory_setBalance({ allowed = true, value = 10 })
  end, "UNAUTHORIZED")
  invokingResource = "trusted_resource"
  local result = registered.inventory_setBalance({ allowed = true, value = 10 })
  assertEqual(result.resource, "trusted_resource")
  assertEqual(result.value, 10)
end

local function testExportLifetimeAndBounds(path, constructorName)
  LR = {}
  dofile(path)
  local registered = {}
  local executions = 0
  local public = LR[constructorName]({
    logger = makeLogger(),
    maxPayload = 8,
    sizeOf = function(value) return value and value.__size or 1 end,
    contracts = {
      inventory = { getSnapshot = { request = validObject, response = validObject } },
    },
    registerExport = function(name, handler)
      registered[name] = handler
      return function()
        if registered[name] == handler then registered[name] = nil end
      end
    end,
    invokeExport = function(_, _, payload) return payload end,
  })

  local disposeFirst = public.Inventory:Register({
    getSnapshot = function(payload)
      executions = executions + 1
      if payload.largeResponse then return { __size = 9 } end
      return payload
    end,
  })
  local captured = registered.inventory_getSnapshot
  assertError(function() captured({ __size = 9 }) end, "payload exceeds")
  assertError(function() captured({ largeResponse = true }) end, "payload exceeds")
  disposeFirst()
  local beforeReplacement = executions

  local disposeSecond = public.Inventory:Register({
    getSnapshot = function(payload) executions = executions + 10 return payload end,
  })
  disposeFirst()
  registered.inventory_getSnapshot({ ok = true })
  assertEqual(executions, beforeReplacement + 10, "stale public disposer must not remove a replacement registration")
  disposeSecond()

  public.Inventory:Register({
    getSnapshot = function(payload) executions = executions + 100 return payload end,
  })
  local cached = registered.inventory_getSnapshot
  public:Dispose()
  assertError(function() cached({ ok = true }) end, "EXPORT_DISPOSED")
  assertEqual(executions, beforeReplacement + 10, "cached callbacks must not execute after dispose")

end

testPublicExports("client/core/public.lua", "CreateClientPublic", "client")
testPublicExports("server/core/public.lua", "CreateServerPublic", "server")
testDefaultExportInvocation()
testDefaultExportRegistration()
testRegistrationRollsBackWhenALaterExportFails("client/core/public.lua", "CreateClientPublic")
testRegistrationRollsBackWhenALaterExportFails("server/core/public.lua", "CreateServerPublic")
testMutatingExportAuthorization("client/core/public.lua", "CreateClientPublic")
testMutatingExportAuthorization("server/core/public.lua", "CreateServerPublic")
testExportLifetimeAndBounds("client/core/public.lua", "CreateClientPublic")
testExportLifetimeAndBounds("server/core/public.lua", "CreateServerPublic")

print("PASS public export security specification")
