LR = nil
dofile("shared/core/lr.lua")
dofile("shared/core/logger_v2.lua")
dofile("shared/core/disposables.lua")
dofile("shared/core/module_registry.lua")
dofile("shared/core/application.lua")

local calls = {}

local function push(value)
  calls[#calls + 1] = value
end

local readiness = LR.StandaloneReadinessProvider:new({ ready = false })
local app = LR.Application:new({
  name = "readiness",
  side = "client",
  readiness = readiness,
  logger = LR.Logger:new({ prefix = "readiness", debug = false }),
})

app:RegisterModule({
  id = "resource_mod",
  start = "resource",
  create = function()
    push("create:resource")
    return {
      Start = function()
        push("start:resource")
      end,
    }
  end,
})

app:RegisterModule({
  id = "player_mod",
  start = "player",
  dependencies = { "resource_mod" },
  create = function()
    push("create:player")
    return {
      Start = function()
        push("start:player")
      end,
    }
  end,
})

app:Start()

if calls[1] ~= "create:resource" or calls[2] ~= "start:resource" then
  error("resource module should start immediately")
end

if calls[3] ~= nil then
  error("player module should wait for readiness")
end

readiness:MarkReady()

if calls[3] ~= "create:player" or calls[4] ~= "start:player" then
  error("player module should start after readiness")
end

local standalone = LR.Application:new({
  name = "standalone",
  side = "server",
  logger = LR.Logger:new({ prefix = "standalone", debug = false }),
})

standalone:RegisterModule({
  id = "standalone_player",
  start = "player",
  create = function()
    return { Start = function() push("start:standalone-player") end }
  end,
})

standalone:Start()

if calls[5] ~= "start:standalone-player" then
  error("default standalone readiness should be ready immediately")
end

local injectedReadiness = LR.StandaloneReadinessProvider:new({ ready = false })
local injectedScheduler = LR.Scheduler:new()
local injectedCalls = 0
local injected = LR.Application:new({
  name = "injected",
  side = "client",
  services = {
    readiness = injectedReadiness,
    scheduler = injectedScheduler,
  },
  logger = LR.Logger:new({ prefix = "injected", debug = false }),
})

injected:RegisterModule({
  id = "injected_player",
  start = "player",
  create = function(context)
    if context.scheduler ~= injectedScheduler then
      error("module context must use the injected scheduler service")
    end
    return { Start = function() injectedCalls = injectedCalls + 1 end }
  end,
})

injected:Start()
if injectedCalls ~= 0 then
  error("injected readiness service must gate player modules")
end
injectedReadiness:MarkReady()
if injectedCalls ~= 1 then
  error("injected readiness service must start player modules")
end
