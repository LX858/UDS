LR = LR or {}

LR.ServerModules = LR.ServerModules or LR.ModuleRegistry:new()
LR.Modules = LR.ServerModules

local function resolveResourceName(explicitName)
  if type(explicitName) == "string" and explicitName ~= "" then
    return explicitName
  end

  if type(GetCurrentResourceName) == "function" then
    local ok, resourceName = pcall(GetCurrentResourceName)
    if ok and type(resourceName) == "string" and resourceName ~= "" then
      return resourceName
    end
  end

  return "lr.server"
end

local function resolveModulesConfig(options)
  if type(options.modules) == "table" then
    return options.modules
  end

  if type(Config) == "table" and type(Config.Modules) == "table" then
    return Config.Modules
  end

  return nil
end

local function isModuleEnabled(modulesConfig, moduleId)
  if not modulesConfig then
    return true
  end

  local entry = modulesConfig[moduleId]
  if entry == nil then
    return true
  end

  if type(entry) == "table" then
    return entry.enabled ~= false
  end

  return entry == true
end

local function createConfiguredRegistry(modulesConfig)
  return LR.CreateSideModuleRegistry(
    LR.SharedModules,
    LR.ServerModules,
    function(id) return isModuleEnabled(modulesConfig, id) end
  )
end

---@param options? LRServer.ApplicationOptions
---@return LRShared.Application
function LR.CreateServerApplication(options)
  options = options or {}
  local resourceName = resolveResourceName(options.resourceName)
  local modulesConfig = resolveModulesConfig(options)

  local app = LR.CreateApplication({
    name = options.name or "lr.server",
    side = "server",
    resourceName = resourceName,
    debug = options.debug,
    services = options.services,
    registry = options.registry or createConfiguredRegistry(modulesConfig),
  })

  if LR.CreateServerNet then
    app:RegisterGlobalService("net", "Net", LR.CreateServerNet({
      app = app,
      side = "server",
      resourceName = app.resourceName,
      logger = app.logger:Child("net"),
    }))
  end

  if LR.CreateServerPublic then
    local public = app:RegisterGlobalService("public", "Public", LR.CreateServerPublic({
      app = app,
      side = "server",
      resourceName = app.resourceName,
      logger = app.logger:Child("public"),
    }))
    app:RegisterGlobalService("external", "External", public.External)
  end

  return app
end
