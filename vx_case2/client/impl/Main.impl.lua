---@class MainImpl : Impl
local Impl = NewImpl("Main")

local function sendEvent(eventName, data)
  SendNUIMessage({
    event = eventName,
    data = data,
  })
end

function Impl:Init()
  self.awaiting = {}
  self:RegisterHandlers()
  self:LogInfo("%s initialized", self:GetName())
end

function Impl:Notify(message, notifyType)
  if not message or message == "" then return end
  local ok = pcall(function()
    exports.qbx_core:Notify(message, notifyType or "inform", 5000)
  end)
  if not ok then
    self:LogWarning("Notify failed: %s", message)
  end
end

function Impl:ServerCallback(name, payload)
  if self.awaiting[name] then
    return { ok = false, message = "Thao tác đang được xử lý" }
  end
  self.awaiting[name] = true
  local callbackOk, response = pcall(function()
    return lib.callback.await(("vx_case2:server:%s"):format(name), false, payload or {})
  end)
  self.awaiting[name] = nil
  if not callbackOk then
    self:LogError("Server callback %s failed: %s", name, response)
    return { ok = false, message = "Không thể kết nối máy chủ" }
  end
  if not response then
    return { ok = false, message = "Máy chủ không phản hồi" }
  end
  if response.state then
    sendEvent("main:setState", response.state)
  end
  if response.message then
    self:Notify(response.message, response.ok and "success" or "error")
  end
  return response
end

function Impl:OpenUI()
  CreateThread(function()
    local response = self:ServerCallback("GetCaseState")
    if not response.ok then
      self:Notify(response.message, "error")
      return
    end
    sendEvent("main:setShow", true)
    SetNuiFocus(true, true)
  end)
end

function Impl:CloseUI()
  sendEvent("main:setShow", false)
  SetNuiFocus(false, false)
end

function Impl:RegisterHandlers()
  RegisterNetEvent("vx_case2:client:open", function()
    self:OpenUI()
  end)

  RegisterNetEvent("vx_case2:client:notify", function(message, notifyType)
    self:Notify(message, notifyType)
  end)

  exports("Open", function()
    self:OpenUI()
  end)

  if Config.Dev then
    RegisterCommand("vxcase2", function()
      self:OpenUI()
    end, false)
  end

  RegisterNUICallback("GetCaseState", function(_, cb)
    cb(self:ServerCallback("GetCaseState"))
  end)

  RegisterNUICallback("Spin", function(data, cb)
    cb(self:ServerCallback("Spin", data))
  end)

  RegisterNUICallback("RefreshItems", function(data, cb)
    cb(self:ServerCallback("RefreshItems", data))
  end)

  RegisterNUICallback("Purchase", function(data, cb)
    cb(self:ServerCallback("Purchase", data))
  end)

  RegisterNUICallback("Close", function(_, cb)
    self:CloseUI()
    cb({ ok = true })
  end)

  RegisterNUICallback("close", function(_, cb)
    self:CloseUI()
    cb({ ok = true })
  end)
end

function Impl:OnResourceStop()
  SetNuiFocus(false, false)
end
