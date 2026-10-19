LR = LR or {}

LR.Logger = {}
LR.Logger.__index = LR.Logger

---@param self LRShared.LoggerClass
---@param options? LRShared.LoggerOptions
---@return LRShared.Logger
function LR.Logger:new(options)
  ---@type LRShared.Logger
  local instance = setmetatable({}, self)
  options = options or {}
  instance.prefix = options.prefix or "LR"
  instance.debug = options.debug == true
  instance.sink = options.sink or print
  return instance
end

---@param self LRShared.Logger
function LR.Logger:Child(scope)
  return LR.Logger:new({
    prefix = ("%s:%s"):format(self.prefix, scope),
    debug = self.debug,
    sink = self.sink,
  })
end

---@param self LRShared.Logger
function LR.Logger:Format(level, message, ...)
  local ok, formatted = pcall(string.format, message, ...)
  if not ok then
    formatted = tostring(message)
  end

  return ("[%s] [%s] %s"):format(level, self.prefix, formatted)
end

---@param self LRShared.Logger
function LR.Logger:Write(level, message, ...)
  if level == "DEBUG" and not self.debug then
    return
  end

  self.sink(self:Format(level, message, ...))
end

---@param self LRShared.Logger
function LR.Logger:Debug(message, ...)
  self:Write("DEBUG", message, ...)
end

---@param self LRShared.Logger
function LR.Logger:Info(message, ...)
  self:Write("INFO", message, ...)
end

---@param self LRShared.Logger
function LR.Logger:Warn(message, ...)
  self:Write("WARN", message, ...)
end

---@param self LRShared.Logger
function LR.Logger:Error(message, ...)
  self:Write("ERROR", message, ...)
end
