LR = LR or {}
---@diagnostic disable-next-line: undefined-global
local addEventHandler = AddEventHandler

local function resolveBootResourceName()
  if type(GetCurrentResourceName) == "function" then
    local ok, resourceName = pcall(GetCurrentResourceName)
    if ok and type(resourceName) == "string" and resourceName ~= "" then
      return resourceName
    end
  end

  return "lr.server"
end

if type(LR.CreateServerFrameworkServices) ~= "function" then
  error("server framework bridge factory is unavailable")
end
local serverFrameworkServices = LR.CreateServerFrameworkServices({
  config = type(Config) == "table" and Config.Framework or nil,
})

local createOk, serverApplication = pcall(LR.CreateServerApplication, {
  resourceName = resolveBootResourceName(),
  debug = type(Config) == "table" and Config.Debug == true,
  services = serverFrameworkServices,
})
if not createOk then
  if serverFrameworkServices.framework then
    pcall(serverFrameworkServices.framework.Dispose, serverFrameworkServices.framework)
  end
  error(serverApplication)
end
local serverResourceStopDisposer

local function stopServerApplicationForResource(resourceName)
  if resourceName ~= serverApplication.resourceName then
    return
  end

  local stopOk, stopErr = pcall(function()
    serverApplication:Stop()
  end)
  local disposeOk, disposeErr = true, nil
  if serverResourceStopDisposer then
    disposeOk, disposeErr = pcall(serverResourceStopDisposer)
    serverResourceStopDisposer = nil
  end
  if not stopOk then error(stopErr) end
  if not disposeOk then error(disposeErr) end
end

if type(addEventHandler) == "function" then
  local token = addEventHandler("onResourceStop", stopServerApplicationForResource)
  if token and type(RemoveEventHandler) == "function" then
    serverResourceStopDisposer = function()
      RemoveEventHandler(token)
    end
  end
end

serverApplication:Start()

return serverApplication
