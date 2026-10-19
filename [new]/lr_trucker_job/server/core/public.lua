LR = LR or {}

local DEFAULT_MAX_PAYLOAD = 128 * 1024

local function noop() end
local function defaultLogger() return { Debug = noop, Info = noop, Warn = noop, Error = noop } end
---@diagnostic disable-next-line: undefined-global
local addEventHandler = AddEventHandler

local function assertModuleName(name)
  if type(name) ~= "string" or not name:match("^[a-z][a-z0-9_]*$") then
    error("module name must match ^[a-z][a-z0-9_]*$")
  end
end

local function assertMemberName(name)
  if type(name) ~= "string" or not name:match("^[A-Za-z][A-Za-z0-9_]*$") then
    error("export name is invalid")
  end
end

local function validate(validator, value, label)
  if type(validator) ~= "function" then error(label .. " validator is missing") end
  local ok, valid, detail = pcall(validator, value)
  if not ok or valid ~= true then
    error(label .. " validation failed" .. (detail and (": " .. tostring(detail)) or ""))
  end
end

local function fallbackSizeOf(value)
  if json and type(json.encode) == "function" then
    local ok, encoded = pcall(json.encode, value)
    if ok and type(encoded) == "string" then return #encoded end
    error("JSON encoding failed")
  end
  error("JSON encoder is unavailable")
end

local function pascalCase(name)
  return (name:gsub("^%l", string.upper):gsub("_([a-z])", function(letter) return letter:upper() end))
end

local function defaultRegisterExport(resourceName, name, handler)
  local token = addEventHandler(("__cfx_export_%s_%s"):format(resourceName, name), function(setCallback)
    setCallback(handler)
  end)
  if token and type(RemoveEventHandler) == "function" then
    return function() RemoveEventHandler(token) end
  end
  return noop
end

local function defaultInvokeExport(resource, name, payload)
  local resourceExports = exports[resource]
  return resourceExports[name](resourceExports, payload)
end

local function defaultGetInvokingResource()
  if type(GetInvokingResource) ~= "function" then return nil end
  return GetInvokingResource()
end

local function disposeRegistered(registry, exportNames, expected)
  for index = #exportNames, 1, -1 do
    local exportName = exportNames[index]
    local disposer = registry.registered[exportName]
    if disposer and (not expected or expected[exportName] == disposer) then
      pcall(disposer)
      if registry.registered[exportName] == disposer then
        registry.registered[exportName] = nil
      end
    end
  end
end

local ServerPublic = {}
ServerPublic.__index = ServerPublic

function ServerPublic:_guard(payload)
  local size = self.sizeOf(payload)
  if type(size) ~= "number" or size < 0 then error("payload size calculation failed") end
  if size > self.maxPayload then error(("payload exceeds %d bytes"):format(self.maxPayload)) end
end

function ServerPublic:_installModuleFacade(moduleName)
  assertModuleName(moduleName)
  local accessor = pascalCase(moduleName)
  if self[accessor] ~= nil or self.External[accessor] ~= nil then
    error("public module accessor collision: " .. accessor)
  end
  local registry = self
  self[accessor] = {
    Register = function(_, handlers) return registry:Register(moduleName, handlers) end,
  }
  self.External[accessor] = function(resourceName)
    return registry:_CreateExternal(moduleName, resourceName)
  end
end

function ServerPublic:_moduleContracts(name)
  local contract = self.contracts[name]
  if type(contract) == "table" and type(contract.exports) == "table" then
    contract = contract.exports.server
  end
  if type(contract) ~= "table" then error("public module is not declared: " .. tostring(name)) end
  return contract
end

function ServerPublic:Register(moduleName, handlers)
  if self.disposed then error("public registry is disposed") end
  assertModuleName(moduleName)
  if type(handlers) ~= "table" then error("public handlers must be a table") end
  local contracts = self:_moduleContracts(moduleName)
  local staged = {}

  for name, handler in pairs(handlers) do
    assertMemberName(name)
    local spec = contracts[name]
    if type(spec) ~= "table" then error(("public method %s.%s is not declared"):format(moduleName, name)) end
    local normalized
    if spec.mutating == true then
      if type(handler) ~= "table" then
        error(("mutating public handler %s.%s requires Authorize and Execute"):format(moduleName, name))
      end
      if type(handler.Execute) ~= "function" then
        error(("mutating public handler %s.%s requires Execute"):format(moduleName, name))
      end
      if type(handler.Authorize) ~= "function" then
        error(("mutating public handler %s.%s requires Authorize"):format(moduleName, name))
      end
      normalized = handler
    else
      if type(handler) ~= "function" then error("public handler must be a function") end
      normalized = { Execute = handler }
    end
    local exportName = moduleName .. "_" .. name
    if self.registered[exportName] then error("public export is already registered: " .. exportName) end
    staged[#staged + 1] = { name = name, handler = normalized, spec = spec, exportName = exportName }
  end

  local disposers = {}
  local owned = {}
  local registered, registrationError = pcall(function()
    for _, entry in ipairs(staged) do
      local active = true
      local rawDisposer = self.registerExport(entry.exportName, function(payload)
        if not active or self.disposed then error("EXPORT_DISPOSED") end
        self:_guard(payload)
        validate(entry.spec.request, payload, "request")
        local invokingResource = self.getInvokingResource()
        if entry.spec.mutating == true then
          if type(invokingResource) ~= "string" or invokingResource == "" then
            error("UNAUTHORIZED")
          end
          local authorizeOk, authorized = pcall(entry.handler.Authorize, invokingResource, payload)
          if not authorizeOk or authorized ~= true then error("UNAUTHORIZED") end
        end
        local ok, result
        if entry.spec.mutating == true then
          ok, result = pcall(entry.handler.Execute, invokingResource, payload)
        else
          ok, result = pcall(entry.handler.Execute, payload)
        end
        if not ok then
          self.logger:Error("Public export %s failed", entry.exportName)
          error("public export handler failed")
        end
        validate(entry.spec.response, result, "response")
        self:_guard(result)
        return result
      end)
      if rawDisposer ~= nil and type(rawDisposer) ~= "function" then
        error("public export disposer must be a function")
      end
      local disposer = function()
        if not active then return end
        active = false
        if rawDisposer then rawDisposer() end
      end
      self.registered[entry.exportName] = disposer or noop
      owned[entry.exportName] = disposer
      disposers[#disposers + 1] = entry.exportName
    end
  end)

  if not registered then
    disposeRegistered(self, disposers, owned)
    pcall(self.logger.Error, self.logger, "Public export registration failed for %s: %s", moduleName, tostring(registrationError))
    error("public export registration failed")
  end

  return function()
    disposeRegistered(self, disposers, owned)
  end
end

function ServerPublic:_CreateExternal(moduleName, resourceName)
  if self.disposed then error("public registry is disposed") end
  assertModuleName(moduleName)
  if type(resourceName) ~= "string" or resourceName == "" then error("resource name is required") end
  local contracts = self:_moduleContracts(moduleName)
  local proxy = {}
  for name, spec in pairs(contracts) do
    assertMemberName(name)
    if type(spec) ~= "table" then error("public contract entry must be a table") end
    local methodName = pascalCase(name)
    if proxy[methodName] then error("public method name collision: " .. methodName) end
    proxy[methodName] = function(_, payload)
      self:_guard(payload)
      validate(spec.request, payload, "request")
      local ok, result = pcall(self.invokeExport, resourceName, moduleName .. "_" .. name, payload)
      if not ok then error("external public export failed") end
      validate(spec.response, result, "response")
      self:_guard(result)
      return result
    end
  end
  return proxy
end

function ServerPublic:Dispose()
  if self.disposed then return end
  self.disposed = true
  for exportName, disposer in pairs(self.registered) do
    pcall(disposer)
    self.registered[exportName] = nil
  end
  for name in pairs(self.External) do
    self.External[name] = nil
  end
end

---@param options? LRServer.PublicOptions
---@return LRServer.Public
function LR.CreateServerPublic(options)
  options = options or {}
  local resourceName = options.resourceName or (type(GetCurrentResourceName) == "function" and GetCurrentResourceName()) or "lr"
  local registerExport = options.registerExport or function(name, handler)
    return defaultRegisterExport(resourceName, name, handler)
  end
  local instance = setmetatable({
    logger = options.logger or defaultLogger(),
    contracts = options.contracts or (LR.Generated and LR.Generated.Contracts) or {},
    registerExport = registerExport,
    invokeExport = options.invokeExport or defaultInvokeExport,
    getInvokingResource = options.getInvokingResource or defaultGetInvokingResource,
    sizeOf = options.sizeOf or fallbackSizeOf,
    maxPayload = options.maxPayload or DEFAULT_MAX_PAYLOAD,
    registered = {},
    External = {},
    disposed = false,
  }, ServerPublic)
  for moduleName in pairs(instance.contracts) do instance:_installModuleFacade(moduleName) end
  return instance
end
