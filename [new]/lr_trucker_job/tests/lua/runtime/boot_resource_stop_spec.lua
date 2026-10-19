LR = nil
Config = {
  Debug = false,
  Framework = { Name = "standalone" },
  Modules = {},
}

local handlers = {}
local removed = {}

function GetCurrentResourceName()
  return "mock_resource"
end

function AddEventHandler(name, handler)
  local token = #handlers + 1
  handlers[token] = { name = name, handler = handler }
  return token
end

function RemoveEventHandler(token)
  removed[token] = true
end

dofile("shared/core/lr.lua")
dofile("shared/core/logger_v2.lua")
dofile("shared/core/disposables.lua")
dofile("shared/core/module_registry.lua")
dofile("shared/core/application.lua")
dofile("client/core/application.lua")
dofile("server/core/application.lua")

local clientFrameworkDisposeCount = 0
local serverFrameworkDisposeCount = 0
LR.CreateClientFrameworkServices = function(options)
  if options.config ~= Config.Framework then error("client boot must forward framework config") end
  return {
    framework = {
      Dispose = function() clientFrameworkDisposeCount = clientFrameworkDisposeCount + 1 end,
    },
    readiness = LR.StandaloneReadinessProvider:new(),
  }
end
LR.CreateServerFrameworkServices = function(options)
  if options.config ~= Config.Framework then error("server boot must forward framework config") end
  return {
    framework = {
      Dispose = function() serverFrameworkDisposeCount = serverFrameworkDisposeCount + 1 end,
    },
    readiness = LR.StandaloneReadinessProvider:new(),
  }
end

local clientApplication = dofile("client/boot.lua")

if clientApplication == nil then
  error("client boot should return its application without publishing boot state on LR")
end

if LR.ClientApplication ~= nil or LR.ClientResourceStopDisposer ~= nil then
  error("client boot lifecycle state must remain private")
end

if not handlers[1] or handlers[1].name ~= "onResourceStop" then
  error("client boot should register onResourceStop")
end

handlers[1].handler("other_resource")

if clientApplication:IsStopped() then
  error("client app should ignore other resource stops")
end

handlers[1].handler("mock_resource")

if not clientApplication:IsStopped() then
  error("client app should stop when current resource stops")
end

if not removed[1] then
  error("client boot should remove resource stop handler token")
end
if clientFrameworkDisposeCount ~= 1 then
  error("client boot must let the application dispose its bridge")
end

local serverApplication = dofile("server/boot.lua")

if serverApplication == nil then
  error("server boot should return its application without publishing boot state on LR")
end

if LR.ServerApplication ~= nil or LR.ServerResourceStopDisposer ~= nil then
  error("server boot lifecycle state must remain private")
end

if not handlers[2] or handlers[2].name ~= "onResourceStop" then
  error("server boot should register onResourceStop")
end

handlers[2].handler("mock_resource")

if not serverApplication:IsStopped() then
  error("server app should stop when current resource stops")
end

if not removed[2] then
  error("server boot should remove resource stop handler token")
end
if serverFrameworkDisposeCount ~= 1 then
  error("server boot must let the application dispose its bridge")
end

local function assertBootDisposesBridgeWhenConstructionFails(bootPath, factoryName, counter)
  local previousFactory = LR[factoryName]
  LR[factoryName] = function() error("application construction failed") end
  local before = counter()
  local ok = pcall(dofile, bootPath)
  LR[factoryName] = previousFactory
  if ok then error("boot must expose application construction failure") end
  if counter() ~= before + 1 then
    error("boot must dispose its framework bridge after application construction failure")
  end
end

assertBootDisposesBridgeWhenConstructionFails(
  "client/boot.lua",
  "CreateClientApplication",
  function() return clientFrameworkDisposeCount end
)
assertBootDisposesBridgeWhenConstructionFails(
  "server/boot.lua",
  "CreateServerApplication",
  function() return serverFrameworkDisposeCount end
)

local function assertBootDisposesHandlerWhenStopFails(bootPath, factoryName, disposerKey)
  local token = #handlers + 1
  local stopped = false
  LR[factoryName] = function()
    return {
      resourceName = "mock_resource",
      Start = function() end,
      Stop = function()
        stopped = true
        error("stop failed")
      end,
    }
  end

  dofile(bootPath)
  local ok = pcall(handlers[token].handler, "mock_resource")
  if ok then error("boot stop failure must remain observable") end
  if not stopped then error("boot must attempt application stop") end
  if not removed[token] then
    error("boot must remove its resource stop handler even when application stop fails")
  end
  if LR[disposerKey] ~= nil then
    error("boot must clear its resource stop disposer after a stop failure")
  end
end

assertBootDisposesHandlerWhenStopFails(
  "client/boot.lua",
  "CreateClientApplication",
  "ClientResourceStopDisposer"
)
assertBootDisposesHandlerWhenStopFails(
  "server/boot.lua",
  "CreateServerApplication",
  "ServerResourceStopDisposer"
)
