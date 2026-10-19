LR = LR or {}

LR.DisposableStack = {}
LR.DisposableStack.__index = LR.DisposableStack

---@param self LRShared.DisposableStackClass
---@return LRShared.DisposableStack
function LR.DisposableStack:new()
  ---@type LRShared.DisposableStack
  local instance = setmetatable({}, self)
  instance.items = {}
  instance.disposed = false
  return instance
end

---@param self LRShared.DisposableStack
function LR.DisposableStack:Add(disposable)
  if self.disposed then
    error("Cannot add disposable after stack was disposed")
  end

  if disposable == nil then
    return nil
  end

  local itemType = type(disposable)
  if itemType ~= "function" and itemType ~= "table" then
    error("Disposable must be a function or table")
  end

  self.items[#self.items + 1] = disposable
  return disposable
end

---@param self LRShared.DisposableStack
function LR.DisposableStack:DisposeOne(disposable)
  if type(disposable) == "function" then
    disposable()
    return
  end

  if type(disposable.Dispose) == "function" then
    disposable:Dispose()
    return
  end

  if type(disposable.Stop) == "function" then
    disposable:Stop()
    return
  end

  error("Disposable table must expose Dispose or Stop")
end

---@param self LRShared.DisposableStack
function LR.DisposableStack:DisposeAll()
  if self.disposed then
    return
  end

  self.disposed = true
  local firstError = nil

  for index = #self.items, 1, -1 do
    local ok, err = pcall(function()
      self:DisposeOne(self.items[index])
    end)

    if not ok and not firstError then
      firstError = err
    end
  end

  self.items = {}

  if firstError then
    error(firstError)
  end
end
