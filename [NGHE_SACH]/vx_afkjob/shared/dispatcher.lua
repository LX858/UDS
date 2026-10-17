---@class Dispatcher:Class()
Dispatcher = class()

function Dispatcher:Init(name)
  ---@type table<string, {id: string, handle: function, off: fun()}[]>
  self.listeners = {}
  self.name = ("Dispatcher:%s"):format(name or "")
end

---@param event string
---@param handle function
function Dispatcher:On(event, handle)
  if not self.listeners[event] then
    self.listeners[event] = {}
  end
  local id = GenerateUUID()
  self:LogInfo("On %s: %s", event, id)
  table.insert(self.listeners[event], { id = id, handle = handle })
  return id
end

---@param event string
---@param handle function
function Dispatcher:Once(event, handle)
  if not self.listeners[event] then
    self.listeners[event] = {}
  end
  local id = GenerateUUID()
  self:LogInfo("Once %s: %s", event, id)
  table.insert(self.listeners[event], {
    id = id,
    handle = function(...)
      handle(...)
      self:Off(id)
    end
  })
  return id
end

---@param id string
function Dispatcher:Off(id)
  for _, listeners in pairs(self.listeners) do
    for i = #listeners, 1, -1 do
      if listeners[i].id == id then
        table.remove(listeners, i)
        return
      end
    end
  end
end

---@param event string
function Dispatcher:Emit(event, ...)
  if not self.listeners[event] then
    return
  end
  self:LogInfo("Emit %s", event)
  for _, listener in ipairs(self.listeners[event]) do
    listener.handle(...)
  end
end

function Dispatcher:Destroy()
  self.listeners = {}
  self.destroyed = true
end