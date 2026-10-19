LR = nil
dofile("shared/core/lr.lua")
dofile("shared/core/logger_v2.lua")
dofile("shared/core/disposables.lua")
dofile("shared/core/module_registry.lua")
dofile("shared/core/application.lua")

local app = LR.Application:new({
  name = "services",
  side = "client",
  logger = LR.Logger:new({ prefix = "services", debug = false }),
})

local calls = {}
local nui = {
  name = "nui",
  Dispose = function()
    calls[#calls + 1] = "dispose:nui"
  end,
}
local net = {
  name = "net",
  Dispose = function()
    calls[#calls + 1] = "dispose:net"
  end,
}

app:RegisterService("nui", nui)
app:RegisterService("net", net)

if not app:HasService("nui") then
  error("registered service should be discoverable")
end

if app:GetService("nui") ~= nui then
  error("GetService should return registered service instance")
end

local seenService = nil
app:RegisterModule({
  id = "consumer",
  create = function()
    return {
      Start = function(_, ctx)
        seenService = ctx.services.nui
      end,
    }
  end,
})

app:Start()
app:Stop()

if seenService ~= nui then
  error("module context should receive the app service bag")
end

if calls[1] ~= "dispose:net" or calls[2] ~= "dispose:nui" then
  error("services should be disposed in reverse registration order after modules stop")
end

local seededCalls = {}
local seeded = LR.Application:new({
  name = "seeded",
  side = "server",
  logger = LR.Logger:new({ prefix = "seeded", debug = false }),
  services = {
    first = {
      Dispose = function()
        seededCalls[#seededCalls + 1] = "first"
      end,
    },
    second = {
      Dispose = function()
        seededCalls[#seededCalls + 1] = "second"
      end,
    },
  },
  serviceOrder = { "first", "second" },
})

seeded:Start()
seeded:Stop()

if seededCalls[1] ~= "second" or seededCalls[2] ~= "first" then
  error("seeded services should respect explicit reverse serviceOrder")
end

local globalCalls = {}
local globalApp = LR.Application:new({
  name = "global",
  side = "client",
  logger = LR.Logger:new({ prefix = "global", debug = false }),
})

local globalNui = {
  Dispose = function()
    globalCalls[#globalCalls + 1] = "dispose:global-nui"
  end,
}

globalApp:RegisterGlobalService("nui", "Nui", globalNui)

if LR.Nui ~= globalNui then
  error("RegisterGlobalService should assign the owned instance to LR.Nui")
end

globalApp:Start()
globalApp:Stop()

if LR.Nui ~= nil then
  error("Stop should clear LR.Nui when it still points to the owned service")
end

if globalCalls[1] ~= "dispose:global-nui" then
  error("global service should still be disposed")
end

local replacementApp = LR.Application:new({
  name = "replacement",
  side = "client",
  logger = LR.Logger:new({ prefix = "replacement", debug = false }),
})

local ownedNet = { Dispose = function() end }
local replacementNet = {}

replacementApp:RegisterGlobalService("net", "Net", ownedNet)
LR.Net = replacementNet
replacementApp:Start()
replacementApp:Stop()

if LR.Net ~= replacementNet then
  error("Stop must not clear LR.Net when another owner replaced the pointer")
end

LR.Net = nil

local continuedAfterFailure = false
local failingServiceApp = LR.Application:new({
  name = "failing-service",
  side = "client",
  logger = LR.Logger:new({ prefix = "failing-service", debug = false }),
})
failingServiceApp:RegisterService("healthy", {
  Dispose = function()
    continuedAfterFailure = true
  end,
})
failingServiceApp:RegisterGlobalService("failing", "Nui", {
  Dispose = function()
    error("service dispose failed")
  end,
})
failingServiceApp:Start()
local failingStopOk = pcall(function()
  failingServiceApp:Stop()
end)
if failingStopOk then
  error("service Dispose failure should bubble")
end
if LR.Nui ~= nil then
  error("owned global must clear even when service Dispose fails")
end
if not continuedAfterFailure then
  error("remaining services must dispose after another service fails")
end
