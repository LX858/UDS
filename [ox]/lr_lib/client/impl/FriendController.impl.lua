---@class CLFriendControllerImpl : Impl
local Impl = NewImpl("FriendController")

function Impl:Init()
  main:LogInfo("%s initialized", self:GetName())
  ---@type number[]
  self.friends = {}
  self:RegisterEvents()
end

function Impl:OnReady()
  main:LogInfo("%s ready", self:GetName())

  local friends, err = lib.callback.await("lr_lib:server:friendcontroller:get", 100)
  print(json.encode(friends))
  if not friends then
    self:LogError(err)
    return
  end
  self.friends = friends
  LocalPlayer.state:set("friends", self.friends)
  TriggerEvent("update")
end

function Impl:RegisterEvents()
  RegisterNetEvent("lr_lib:client:friendcontrol:update", function (data, isNew)
    self.friends = data
    LocalPlayer.state:set("friends", self.friends)
    TriggerEvent("update")
    if isNew then
      ExecuteCommand('e wave8')
      Citizen.SetTimeout(4000, function()
          ExecuteCommand('e c')
      end)
    end
  end)
  AddEventHandler("lr_lib:client:friendcontroller:invite", function (target)
    self:Invite(target)
  end)
  lib.callback.register('lr_lib:client:friendcontrol:request', function(fromId, sessionId)
    local input = lib.inputDialog(('Yêu cầu kết bạn từ %s'):format(fromId), {})
    return input ~= nil
  end)
  AddEventHandler("onResourceStart", function(resource)
    if resource == "mp_nametag" then
      Wait(5000)
      TriggerEvent("update")
    end
  end)
end

function Impl:IsFriend(id)
  for _, friend in ipairs(self.friends) do
    if friend == id then
      return true
    end
  end
  return false
end

function Impl:Invite(target)
  TriggerServerEvent("lr_lib:server:friendcontroller:request", target)
end
