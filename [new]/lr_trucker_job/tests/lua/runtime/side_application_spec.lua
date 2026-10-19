LR = nil
Config = {
  Modules = {
    fixture = false,
  },
}

function GetCurrentResourceName()
  return "mock_resource"
end

dofile("shared/core/lr.lua")
dofile("shared/core/logger_v2.lua")
dofile("shared/core/disposables.lua")
dofile("shared/core/module_registry.lua")
dofile("shared/core/application.lua")

LR.CreateClientNui = function(options)
  return { kind = "client-nui", options = options }
end

LR.CreateClientNet = function(options)
  return { kind = "client-net", options = options }
end

LR.CreateServerNet = function(options)
  return { kind = "server-net", options = options }
end

LR.CreateClientPublic = function(options)
  return { kind = "client-public", options = options, External = {} }
end

LR.CreateServerPublic = function(options)
  return { kind = "server-public", options = options, External = {} }
end

dofile("client/core/application.lua")
LR.ClientModules:Register({
  id = "fixture",
  create = function() return {} end,
})

local clientApp = LR.CreateClientApplication({})

if clientApp.resourceName ~= "mock_resource" then
  error("client resourceName should fall back to GetCurrentResourceName")
end

if clientApp:GetService("nui").kind ~= "client-nui" then
  error("client app should register CreateClientNui as nui service")
end

if LR.Nui ~= clientApp:GetService("nui") then
  error("client app should expose nui service as LR.Nui")
end

if clientApp:GetService("net").kind ~= "client-net" then
  error("client app should register CreateClientNet as net service")
end

if LR.Net ~= clientApp:GetService("net") then
  error("client app should expose net service as LR.Net")
end

if clientApp:GetService("public").kind ~= "client-public" then
  error("client app should register CreateClientPublic as public service")
end

if LR.Public ~= clientApp:GetService("public") then
  error("client app should expose public service as LR.Public")
end

if LR.External ~= clientApp:GetService("public").External then
  error("client app should expose the typed consumer facade as LR.External")
end

if clientApp.registry:Get("fixture") then
  error("client fixture should be disabled by Config.Modules.fixture")
end

local enabledClient = LR.CreateClientApplication({
  modules = {
    fixture = true,
  },
})

if not enabledClient.registry:Get("fixture") then
  error("client fixture should be enabled by options.modules.fixture")
end

dofile("server/core/application.lua")
LR.ServerModules:Register({
  id = "fixture",
  create = function() return {} end,
})

local serverApp = LR.CreateServerApplication({})

if serverApp.resourceName ~= "mock_resource" then
  error("server resourceName should fall back to GetCurrentResourceName")
end

if serverApp:GetService("net").kind ~= "server-net" then
  error("server app should register CreateServerNet as net service")
end

if LR.Net ~= serverApp:GetService("net") then
  error("server app should expose net service as LR.Net")
end

if serverApp:GetService("public").kind ~= "server-public" then
  error("server app should register CreateServerPublic as public service")
end

if LR.Public ~= serverApp:GetService("public") then
  error("server app should expose public service as LR.Public")
end

if LR.External ~= serverApp:GetService("public").External then
  error("server app should expose the typed consumer facade as LR.External")
end

if serverApp.registry:Get("fixture") then
  error("server fixture should be disabled by Config.Modules.fixture")
end

local enabledServer = LR.CreateServerApplication({
  modules = {
    fixture = { enabled = true },
  },
})

if not enabledServer.registry:Get("fixture") then
  error("server fixture should be enabled by options.modules.fixture")
end
