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

  return "lr.client"
end

if type(LR.CreateClientFrameworkServices) ~= "function" then
  error("client framework bridge factory is unavailable")
end
local clientFrameworkServices = LR.CreateClientFrameworkServices({
  config = type(Config) == "table" and Config.Framework or nil,
})

local createOk, clientApplication = pcall(LR.CreateClientApplication, {
  resourceName = resolveBootResourceName(),
  debug = type(Config) == "table" and Config.Debug == true,
  services = clientFrameworkServices,
})
if not createOk then
  if clientFrameworkServices.framework then
    pcall(clientFrameworkServices.framework.Dispose, clientFrameworkServices.framework)
  end
  error(clientApplication)
end
local clientResourceStopDisposer

local function stopClientApplicationForResource(resourceName)
  if resourceName ~= clientApplication.resourceName then
    return
  end

  local stopOk, stopErr = pcall(function()
    clientApplication:Stop()
  end)
  local disposeOk, disposeErr = true, nil
  if clientResourceStopDisposer then
    disposeOk, disposeErr = pcall(clientResourceStopDisposer)
    clientResourceStopDisposer = nil
  end
  if not stopOk then error(stopErr) end
  if not disposeOk then error(disposeErr) end
end

if type(addEventHandler) == "function" then
  local token = addEventHandler("onResourceStop", stopClientApplicationForResource)
  if token and type(RemoveEventHandler) == "function" then
    clientResourceStopDisposer = function()
      RemoveEventHandler(token)
    end
  end
end

clientApplication:Start()

return clientApplication
