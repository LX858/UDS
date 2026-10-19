LR = LR or {}

local ClassMethods = {}
local InstanceMethods = {}
local ClassNamespace = {}
local knownClasses = setmetatable({}, { __mode = "k" })
local classMetatable

local function assertClass(value, label)
  if not knownClasses[value] then
    error((label or "value") .. " must be an LR class")
  end
end

local function findClassValue(class, key)
  while class do
    local value = rawget(class, key)
    if value ~= nil then
      return value
    end
    class = rawget(class, "__base")
  end
  return nil
end

local function findProperty(class, key)
  while class do
    local properties = rawget(class, "__properties")
    local property = properties and rawget(properties, key)
    if property ~= nil then
      return property
    end
    class = rawget(class, "__base")
  end
  return nil
end

local function readProperty(instance, property)
  local stored = rawget(instance, property.storage)
  if property.get then
    return property.get(instance, stored)
  end
  return stored
end

local function instanceIndex(instance, key)
  local class = getmetatable(instance)
  local property = findProperty(class, key)
  if property then
    return readProperty(instance, property)
  end

  local value = findClassValue(class, key)
  if value ~= nil then
    return value
  end
  return InstanceMethods[key]
end

local function instanceNewIndex(instance, key, value)
  local class = getmetatable(instance)
  local property = findProperty(class, key)
  if not property then
    rawset(instance, key, value)
    return
  end
  if property.readonly then
    error(("property %s.%s is readonly"):format(rawget(class, "__name"), key))
  end

  local previous = rawget(instance, property.storage)
  if property.validate then
    local valid, message = property.validate(instance, value)
    if valid ~= true then
      error(message or ("invalid value for property %s.%s"):format(rawget(class, "__name"), key))
    end
  end
  local nextValue = value
  if property.set then
    nextValue = property.set(instance, value, previous)
  end

  rawset(instance, property.storage, nextValue)
  if property.afterSet then
    property.afterSet(instance, nextValue, previous)
  end
end

function ClassMethods:New(...)
  assertClass(self, "class")
  local argumentCount = select("#", ...)
  if argumentCount > 1 then
    error(("class %s constructor accepts at most one argument"):format(rawget(self, "__name")))
  end
  local instance = setmetatable({}, self)
  local initializer = findClassValue(self, "init")
  if initializer ~= nil then
    if type(initializer) ~= "function" then
      error(("class %s init must be a function"):format(rawget(self, "__name")))
    end
    initializer(instance, ...)
  end
  return instance
end

function ClassMethods:Extend(name)
  assertClass(self, "base class")
  return ClassNamespace:Define(name, self)
end

function ClassMethods:Property(name, definition)
  assertClass(self, "class")
  LR.assertName(name, "property name")
  definition = definition or {}
  if type(definition) ~= "table" then
    error("property definition must be a table")
  end

  local allowed = {
    storage = true,
    readonly = true,
    get = true,
    set = true,
    validate = true,
    afterSet = true,
  }
  for key in pairs(definition) do
    if not allowed[key] then
      error("unsupported property option: " .. tostring(key))
    end
  end
  for _, key in ipairs({ "get", "set", "validate", "afterSet" }) do
    if definition[key] ~= nil and type(definition[key]) ~= "function" then
      error("property " .. key .. " must be a function")
    end
  end
  if definition.readonly ~= nil and type(definition.readonly) ~= "boolean" then
    error("property readonly must be a boolean")
  end
  if definition.readonly and definition.set then
    error("readonly property cannot define a setter")
  end

  local storage = definition.storage or ("_" .. name)
  LR.assertName(storage, "property storage")
  if storage == name then
    error("property storage must differ from its public name")
  end
  if findClassValue(self, name) ~= nil then
    error("property conflicts with class member: " .. name)
  end

  local properties = rawget(self, "__properties")
  if rawget(properties, name) ~= nil then
    error("property is already declared on class: " .. name)
  end
  properties[name] = {
    storage = storage,
    readonly = definition.readonly == true,
    get = definition.get,
    set = definition.set,
    validate = definition.validate,
    afterSet = definition.afterSet,
  }
  return self
end

function ClassMethods:IsSubclassOf(target)
  assertClass(self, "class")
  if not knownClasses[target] then
    return false
  end

  local class = self
  while class do
    if class == target then
      return true
    end
    class = rawget(class, "__base")
  end
  return false
end

function InstanceMethods:IsA(target)
  return ClassNamespace:IsInstance(self, target)
end

function InstanceMethods:GetClass()
  local class = getmetatable(self)
  if knownClasses[class] then
    return class
  end
  return nil
end

classMetatable = {
  __index = function(class, key)
    local method = ClassMethods[key]
    if method ~= nil then
      return method
    end
    return findClassValue(rawget(class, "__base"), key)
  end,
}

function ClassNamespace:Define(name, base)
  LR.assertName(name, "class name")
  if base ~= nil then
    assertClass(base, "base class")
  end

  local class = {
    __name = name,
    __base = base,
    __properties = {},
    __index = instanceIndex,
    __newindex = instanceNewIndex,
  }
  knownClasses[class] = true
  return setmetatable(class, classMetatable)
end

function ClassNamespace:IsClass(value)
  return knownClasses[value] == true
end

function ClassNamespace:IsInstance(value, target)
  if type(value) ~= "table" or not knownClasses[target] then
    return false
  end

  local class = getmetatable(value)
  while knownClasses[class] do
    if class == target then
      return true
    end
    class = rawget(class, "__base")
  end
  return false
end

LR.Class = ClassNamespace
