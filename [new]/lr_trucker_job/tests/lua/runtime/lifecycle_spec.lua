LR = nil
dofile("shared/core/lr.lua")
dofile("shared/core/logger_v2.lua")
dofile("shared/core/disposables.lua")
dofile("shared/core/module_registry.lua")
dofile("shared/core/application.lua")

local calls = {}
local logs = {}

local function push(value)
  calls[#calls + 1] = value
end

local function descriptor(id, dependencies)
  return {
    id = id,
    dependencies = dependencies or {},
    start = "resource",
    create = function(context)
      push("create:" .. id)
      if not context.logger or not context.scheduler or not context.disposables then
        error("context missing core fields")
      end
      if context.nui ~= context.services.nui or context.net ~= context.services.net or context.public ~= context.services.public then
        error("context transport shortcuts should mirror services")
      end
      return {
        Test = function()
          return id
        end,
        OnReady = function(_, readyContext)
          if not readyContext.app.instances.a
            or (readyContext.app.registry:Get("b") and not readyContext.app.instances.b) then
            error("all module instances must exist before OnReady")
          end
          push("ready:" .. id)
        end,
        Start = function(_, startContext)
          if not startContext.app.activeModules.a
            or (startContext.app.registry:Get("b") and not startContext.app.activeModules.b) then
            error("all modules must be ready before Start")
          end
          push("start:" .. id)
          if id == "b" then
            push("call:" .. startContext.modules.a:Test())
          end
          startContext.disposables:Add(function()
            push("dispose:" .. id)
          end)
        end,
        Stop = function()
          push("stop:" .. id)
        end,
      }
    end,
  }
end

local app = LR.Application:new({
  name = "spec",
  side = "client",
  logger = LR.Logger:new({
    prefix = "spec",
    debug = false,
    sink = function(message)
      logs[#logs + 1] = message
    end,
  }),
  services = {
    nui = {},
    net = {},
    public = {},
  },
  serviceOrder = { "nui", "net", "public" },
})

app:RegisterModule(descriptor("a"))
app:RegisterModule(descriptor("b", { "a" }))

app:Start()

local completedStartLog = false
for _, message in ipairs(logs) do
  if message:find("Started module a", 1, true) then
    completedStartLog = true
    break
  end
end
if not completedStartLog then
  error("successful module startup must emit a completion log")
end

app:Stop()

local expected = {
  "create:a",
  "create:b",
  "ready:a",
  "ready:b",
  "start:a",
  "start:b",
  "call:a",
  "stop:b",
  "dispose:b",
  "stop:a",
  "dispose:a",
}

for i, value in ipairs(expected) do
  if calls[i] ~= value then
    error(("lifecycle order mismatch at %s: expected %s, got %s"):format(i, value, tostring(calls[i])))
  end
end

if not app:IsStopped() then
  error("app should be stopped after Stop")
end

local secondApp = LR.Application:new({
  name = "spec2",
  side = "client",
  logger = LR.Logger:new({ prefix = "spec2", debug = false }),
})
secondApp:RegisterModule(descriptor("a"))
secondApp:Start()

if app.instances.a == secondApp.instances.a then
  error("module create must produce a fresh instance per application")
end

secondApp:Stop()

local disposedAfterStopFailure = false
local failureApp = LR.Application:new({
  name = "stop-failure",
  side = "client",
  logger = LR.Logger:new({ prefix = "stop-failure", debug = false }),
})
failureApp:RegisterModule({
  id = "failing",
  create = function()
    return {
      Start = function(_, context)
        context.disposables:Add(function()
          disposedAfterStopFailure = true
        end)
      end,
      Stop = function()
        error("stop failed")
      end,
    }
  end,
})
failureApp:Start()
local stopOk = pcall(function()
  failureApp:Stop()
end)
if stopOk then
  error("module Stop failure should bubble")
end
if not disposedAfterStopFailure then
  error("module disposables must run even when Stop fails")
end
if not failureApp:IsStopped() then
  error("application must still reach stopped state after Stop failure")
end
