LR = nil
dofile("shared/core/lr.lua")
dofile("shared/core/logger_v2.lua")
dofile("shared/core/disposables.lua")
dofile("shared/core/module_registry.lua")
dofile("shared/core/application.lua")

local calls = {}
local function descriptor(id, side, start)
  return {
    id = id,
    start = start or "resource",
    dependencies = {},
    create = function()
      local instance = {
        side = side,
        OnReady = function() calls[#calls + 1] = "ready:" .. side end,
        Start = function() calls[#calls + 1] = "start:" .. side end,
        Stop = function() calls[#calls + 1] = "stop:" .. side end,
      }
      if side == "client" then
        function instance:Test()
          return self.side
        end
      end
      return instance
    end,
  }
end

LR.SharedModules:Register(descriptor("inventory", "shared"))
LR.ClientModules = LR.ModuleRegistry:new()
LR.ClientModules:Register(descriptor("inventory", "client"))

local registry = LR.CreateSideModuleRegistry(
  LR.SharedModules,
  LR.ClientModules,
  function() return true end
)
local app = LR.CreateApplication({
  name = "parts",
  side = "client",
  registry = registry,
})
app:Start()
if app:GetModule("inventory"):Test() ~= "client" then
  error("composed module must bind custom methods to the owning part instance")
end
app:Stop()

local expected = {
  "ready:shared",
  "ready:client",
  "start:shared",
  "start:client",
  "stop:client",
  "stop:shared",
}
for index, value in ipairs(expected) do
  if calls[index] ~= value then
    error(("module part order %d: expected %s, got %s"):format(index, value, tostring(calls[index])))
  end
end

local mismatched = LR.ModuleRegistry:new()
mismatched:Register(descriptor("inventory", "client", "player"))
local ok, err = pcall(function()
  LR.CreateSideModuleRegistry(LR.SharedModules, mismatched, function() return true end)
end)
if ok or not tostring(err):find("start phase", 1, true) then
  error("shared and side module parts with different start phases must fail clearly")
end

local duplicateShared = LR.ModuleRegistry:new()
local duplicateClient = LR.ModuleRegistry:new()
duplicateShared:Register({
  id = "duplicate_api",
  create = function() return { Test = function() end } end,
})
duplicateClient:Register({
  id = "duplicate_api",
  create = function() return { Test = function() end } end,
})
local duplicateApp = LR.CreateApplication({
  name = "duplicate-api",
  registry = LR.CreateSideModuleRegistry(duplicateShared, duplicateClient),
})
local duplicateOk, duplicateErr = pcall(function() duplicateApp:Start() end)
if duplicateOk or not tostring(duplicateErr):find("duplicate method Test", 1, true) then
  error("duplicate composed module methods must fail clearly")
end

local invalidSide = LR.ModuleRegistry:new()
invalidSide:Register({
  id = "broken",
  create = function() return nil end,
})
local invalidRegistry = LR.CreateSideModuleRegistry(
  LR.ModuleRegistry:new(),
  invalidSide,
  function() return true end
)
local invalidApp = LR.CreateApplication({name = "invalid-part", registry = invalidRegistry})
local invalidOk, invalidErr = pcall(function() invalidApp:Start() end)
if invalidOk or not tostring(invalidErr):find("part create", 1, true) then
  error("invalid module part instances must fail before lifecycle start")
end

print("module_parts_spec: ok")
