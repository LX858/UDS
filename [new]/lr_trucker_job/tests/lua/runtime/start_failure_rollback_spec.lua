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

local app = LR.Application:new({
  name = "rollback",
  side = "server",
  logger = LR.Logger:new({ prefix = "rollback", debug = false }),
})

app:RegisterModule({
  id = "a",
  start = "resource",
  create = function()
    push("create:a")
    return {
      OnReady = function()
        push("ready:a")
      end,
      Start = function(_, ctx)
        push("start:a")
        ctx.disposables:Add(function()
          push("dispose:a")
        end)
      end,
      Stop = function()
        push("stop:a")
      end,
    }
  end,
})

app:RegisterModule({
  id = "b",
  dependencies = { "a" },
  start = "resource",
  create = function()
    push("create:b")
    return {
      OnReady = function()
        push("ready:b")
      end,
      Start = function(_, ctx)
        push("start:b")
        ctx.disposables:Add(function()
          push("dispose:b")
        end)
        error("boom")
      end,
      Stop = function()
        push("stop:b")
      end,
    }
  end,
})

local ok = pcall(function()
  app:Start()
end)

if ok then
  error("start failure should bubble")
end

local expected = {
  "create:a",
  "create:b",
  "ready:a",
  "ready:b",
  "start:a",
  "start:b",
  "stop:b",
  "dispose:b",
  "stop:a",
  "dispose:a",
}

for i, value in ipairs(expected) do
  if calls[i] ~= value then
    error(("rollback order mismatch at %s: expected %s, got %s"):format(i, value, tostring(calls[i])))
  end
end

if not app:IsStopped() then
  error("app should be stopped after failed Start rollback")
end
