-- shared/mutex.lua
-- Mutex cho FiveM: FIFO queue, re-entrant, try_lock, timeout.
-- Yêu cầu runtime Cfx.re có promise.new() + Citizen.Await (mặc định có).

local Mutex = {}
Mutex.__index = Mutex

local function current_co()
  -- coroutine.running() trả về id của coroutine hiện tại (thread Lua)
  return coroutine.running()
end

function Mutex.new(name)
  return setmetatable({
    name = name or "mutex",
    locked = false,
    owner = nil,          -- coroutine owner
    depth = 0,            -- re-entrant depth
    queue = {},           -- FIFO các waiter: { promise, waiter_id }
  }, Mutex)
end

-- Thử lock ngay lập tức, không chờ.
function Mutex:try_lock()
  local me = current_co()
  if not self.locked then
    self.locked = true
    self.owner = me
    self.depth = 1
    return true
  end
  if self.owner == me then
    -- Re-entrant
    self.depth = self.depth + 1
    return true
  end
  return false
end

-- Lock với optional timeout (ms). Trả về true nếu lấy được, false nếu timeout.
function Mutex:lock(timeoutMs)
  local me = current_co()

  -- Nếu rảnh -> lấy luôn
  if not self.locked then
    self.locked = true
    self.owner = me
    self.depth = 1
    return true
  end

  -- Re-entrant
  if self.owner == me then
    self.depth = self.depth + 1
    return true
  end

  -- Hàng đợi bằng promise (không busy-wait)
  local p = promise.new()
  table.insert(self.queue, { p = p, waiter = me })

  local timedout = false
  if timeoutMs and timeoutMs > 0 then
    CreateThread(function()
      Wait(timeoutMs)
      if p.state == nil then -- vẫn pending
        -- Gỡ khỏi queue
        for i, ent in ipairs(self.queue) do
          if ent.p == p then
            table.remove(self.queue, i)
            break
          end
        end
        timedout = true
        p:reject("timeout")
      end
    end)
  end

  local ok = Citizen.Await(p)  -- resume khi được nhường quyền
  if not ok or timedout then
    return false
  end

  -- Bên unlock() giữ locked=true để chống race.
  -- Người nhận quyền sẽ chỉ cần gắn owner/depth.
  self.locked = true
  self.owner = me
  self.depth = 1
  return true
end

-- Nhả lock. Bắt buộc cùng owner.
function Mutex:unlock()
  local me = current_co()
  if self.owner ~= me then
    error(("Mutex '%s': unlock từ non-owner"):format(self.name))
  end

  self.depth = self.depth - 1
  if self.depth > 0 then
    return
  end

  -- Hết re-entrant depth: chuyển quyền cho next hoặc mở khoá
  self.owner = nil
  if #self.queue > 0 then
    -- Giữ locked=true để không ai chen ngang trước waiter kế tiếp
    local nextEntry = table.remove(self.queue, 1)
    -- Báo cho waiter được quyền (Await sẽ trả true)
    nextEntry.p:resolve(true)
    -- Waiter sẽ set owner/depth sau khi resume
  else
    self.locked = false
  end
end

-- Thao tác tiện lợi: chạy fn trong critical section (tự lock/unlock).
-- Nếu lock thất bại vì timeout -> trả { ok=false, err="timeout" }.
function Mutex:with_lock(fn, timeoutMs)
  local got = self:lock(timeoutMs)
  if not got then
    return { ok = false, err = "timeout" }
  end
  local ok, res1, res2, res3 = pcall(fn)
  self:unlock()
  if not ok then
    return { ok = false, err = res1 }
  end
  return { ok = true, result = res1, _2 = res2, _3 = res3 }
end

return Mutex
