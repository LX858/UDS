---@class MainImpl : Impl
local Impl = NewImpl("Main")

function Impl:Init()
  self.await = nil
  self.caseItem = nil
  self:EventHandlers()
  self:LogInfo("%s initialized", self:GetName())
end

function Impl:OnReady()
  SendReactMessage("main:setItems", {})
  SendReactMessage("main:setCount", 0)
end

function Impl:UpdateRewards()
  local rewards = lib.callback.await("vongquaytrungthu:server:getRewards", false)
  SendReactMessage("main:setItems", rewards or Config.Rewards[self.caseItem] or {})
end

function Impl:UpdateCount()
  local count = lib.callback.await("vongquaytrungthu:server:getItemCount", false) or 0
  SendReactMessage("main:setCount", count)
end

function Impl:EventHandlers()
  RegisterNetEvent("vongquaytrungthu:client:show", function(caseItem)
    if not Config.Rewards[caseItem] then return end

    self.caseItem = caseItem
    self:UpdateRewards()
    self:UpdateCount()
    SendReactMessage("main:setShow", true)
    SetNuiFocus(true, true)
  end)

  RegisterNetEvent("vongquaytrungthu:client:showNotify", function(message)
    SendReactMessage("main:showNotify", message)
  end)

  RegisterNUICallback("close", function(data, cb)
    SendReactMessage("main:setShow", false)
    SetNuiFocus(false, false)
    TriggerServerEvent("vongquaytrungthu:server:close")
    self.caseItem = nil
    cb('ok')
  end)

  RegisterNUICallback("GetResult", function(data, cb)
    if self.await then
      cb(nil)
      return
    end
    self.await = true
    local result, msg = lib.callback.await("vongquaytrungthu:server:getReward", 5000, tonumber(data.multiplier) or 1)
    if msg then
      SendReactMessage("main:showNotify", msg)
    end
    self:UpdateCount()
    cb(result)
    Wait(1000)
    self.await = false
  end)
end
