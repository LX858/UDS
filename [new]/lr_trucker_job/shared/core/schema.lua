LR = LR or {}

LR.Schema = LR.Schema or {}
LR.JSON_NULL = LR.JSON_NULL or setmetatable({}, {
  __tostring = function() return "null" end,
  __metatable = false,
})

local function fail(path, message)
  return false, (path or "$" ) .. ": " .. message
end

local function valueEquals(left, right, active)
  if left == right then return true end
  if type(left) ~= type(right) or type(left) ~= "table" then return false end
  active = active or {}
  if active[left] == right then return true end
  active[left] = right
  for key, value in pairs(left) do
    if not valueEquals(value, right[key], active) then return false end
  end
  for key in pairs(right) do
    if left[key] == nil then return false end
  end
  return true
end

local function stringLength(value)
  if utf8 and type(utf8.len) == "function" then
    local length = utf8.len(value)
    if length then return length end
  end
  return #value
end

local function isInteger(value)
  return type(value) == "number" and value == value and value % 1 == 0
end

local function validateNode(schema, value, path, active)
  if type(schema) ~= "table" then return fail(path, "schema must be a table") end

  if type(schema.anyOf) == "table" then
    for index, candidate in ipairs(schema.anyOf) do
      local ok = validateNode(candidate, value, path, active)
      if ok then return true end
    end
    return fail(path, "value did not match any allowed schema")
  end

  if schema.const ~= nil and not valueEquals(value, schema.const) then
    return fail(path, "value did not match const")
  end
  if type(schema.enum) == "table" then
    local matched = false
    for _, candidate in ipairs(schema.enum) do
      if valueEquals(value, candidate) then matched = true break end
    end
    if not matched then return fail(path, "value was not in enum") end
  end

  local schemaType = schema.type
  if type(schemaType) == "table" then
    for _, candidateType in ipairs(schemaType) do
      local candidate = {}
      for key, item in pairs(schema) do candidate[key] = item end
      candidate.type = candidateType
      local ok = validateNode(candidate, value, path, active)
      if ok then return true end
    end
    return fail(path, "value did not match any allowed type")
  end

  if schemaType == "null" then
    if value == nil or value == LR.JSON_NULL then return true end
    return fail(path, "expected null")
  elseif schemaType == "boolean" then
    if type(value) ~= "boolean" then return fail(path, "expected boolean") end
  elseif schemaType == "string" then
    if type(value) ~= "string" then return fail(path, "expected string") end
    local length = stringLength(value)
    if schema.minLength and length < schema.minLength then return fail(path, "string is too short") end
    if schema.maxLength and length > schema.maxLength then return fail(path, "string is too long") end
    if schema.pattern then
      local patternOk, matched = pcall(string.match, value, schema.pattern)
      if not patternOk or matched == nil then return fail(path, "string did not match pattern") end
    end
  elseif schemaType == "integer" then
    if not isInteger(value) then return fail(path, "expected integer") end
    if schema.minimum and value < schema.minimum then return fail(path, "number is below minimum") end
    if schema.maximum and value > schema.maximum then return fail(path, "number is above maximum") end
    if schema.exclusiveMinimum and value <= schema.exclusiveMinimum then return fail(path, "number is below exclusive minimum") end
    if schema.exclusiveMaximum and value >= schema.exclusiveMaximum then return fail(path, "number is above exclusive maximum") end
  elseif schemaType == "number" then
    if type(value) ~= "number" or value ~= value then return fail(path, "expected finite number") end
    if schema.minimum and value < schema.minimum then return fail(path, "number is below minimum") end
    if schema.maximum and value > schema.maximum then return fail(path, "number is above maximum") end
    if schema.exclusiveMinimum and value <= schema.exclusiveMinimum then return fail(path, "number is below exclusive minimum") end
    if schema.exclusiveMaximum and value >= schema.exclusiveMaximum then return fail(path, "number is above exclusive maximum") end
  elseif schemaType == "array" then
    if type(value) ~= "table" then return fail(path, "expected array") end
    if active[value] then return fail(path, "cyclic values are not supported") end
    active[value] = true
    local length, count = #value, 0
    for key in pairs(value) do
      if not isInteger(key) or key < 1 or key > length then
        active[value] = nil
        return fail(path, "expected a dense array")
      end
      count = count + 1
    end
    if count ~= length then active[value] = nil return fail(path, "expected a dense array") end
    if schema.minItems and length < schema.minItems then active[value] = nil return fail(path, "array is too short") end
    if schema.maxItems and length > schema.maxItems then active[value] = nil return fail(path, "array is too long") end
    if schema.items then
      for index = 1, length do
        local ok, detail = validateNode(schema.items, value[index], path .. "/" .. index, active)
        if not ok then active[value] = nil return false, detail end
      end
    end
    active[value] = nil
  elseif schemaType == "object" then
    if type(value) ~= "table" or value == LR.JSON_NULL then return fail(path, "expected object") end
    if active[value] then return fail(path, "cyclic values are not supported") end
    active[value] = true
    local properties = schema.properties or {}
    local required = {}
    for _, key in ipairs(schema.required or {}) do required[key] = true end
    for key in pairs(required) do
      if value[key] == nil then active[value] = nil return fail(path .. "/" .. key, "required property is missing") end
    end
    for key, item in pairs(value) do
      if type(key) ~= "string" then active[value] = nil return fail(path, "object keys must be strings") end
      local propertySchema = properties[key]
      if propertySchema then
        local ok, detail = validateNode(propertySchema, item, path .. "/" .. key, active)
        if not ok then active[value] = nil return false, detail end
      else
        local matched = false
        for pattern, patternSchema in pairs(schema.patternProperties or {}) do
          local patternOk, result = pcall(string.match, key, pattern)
          if patternOk and result ~= nil then
            matched = true
            local ok, detail = validateNode(patternSchema, item, path .. "/" .. key, active)
            if not ok then active[value] = nil return false, detail end
          end
        end
        if not matched and schema.additionalProperties == false then
          active[value] = nil
          return fail(path .. "/" .. key, "additional property is not allowed")
        elseif not matched and type(schema.additionalProperties) == "table" then
          local ok, detail = validateNode(schema.additionalProperties, item, path .. "/" .. key, active)
          if not ok then active[value] = nil return false, detail end
        end
      end
    end
    active[value] = nil
  elseif schemaType ~= nil then
    return fail(path, "unsupported schema type " .. tostring(schemaType))
  end

  return true
end

function LR.Schema.Compile(schema)
  if type(schema) ~= "table" then error("schema must be a table") end
  return function(value)
    return validateNode(schema, value, "$", {})
  end
end

local function compileEvents(events)
  local compiled = {}
  for direction, endpoints in pairs(events or {}) do
    compiled[direction] = {}
    for name, schema in pairs(endpoints) do
      compiled[direction][name] = { validate = LR.Schema.Compile(schema) }
    end
  end
  return compiled
end

local function compileRpc(rpc)
  local compiled = {}
  for direction, endpoints in pairs(rpc or {}) do
    compiled[direction] = {}
    for name, endpoint in pairs(endpoints) do
      compiled[direction][name] = {
        request = LR.Schema.Compile(endpoint.request),
        response = LR.Schema.Compile(endpoint.response),
        timeoutMs = endpoint.timeoutMs,
        mutating = endpoint.mutating,
        rateLimit = endpoint.rateLimit,
      }
    end
  end
  return compiled
end

function LR.Schema.CompileContract(contract)
  if type(contract) ~= "table" or type(contract.id) ~= "string" then
    error("contract id is required")
  end

  local state = {}
  for name, definition in pairs(contract.state or {}) do
    state[name] = {
      default = definition.default,
      validate = LR.Schema.Compile(definition.schema),
      patchValidate = definition.patch and LR.Schema.Compile(definition.patch) or nil,
      object = definition.schema.type == "object",
    }
  end

  return {
    id = contract.id,
    version = contract.version or 1,
    nui = {
      state = state,
      events = compileEvents(contract.nui and contract.nui.events),
      rpc = compileRpc(contract.nui and contract.nui.rpc),
    },
    net = {
      events = compileEvents(contract.net and contract.net.events),
      rpc = compileRpc(contract.net and contract.net.rpc),
    },
    exports = compileRpc(contract.exports),
  }
end
