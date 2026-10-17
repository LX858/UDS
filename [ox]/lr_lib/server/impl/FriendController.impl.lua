---@class SVFriendControllerImpl : Impl
local Impl = NewImpl("FriendController")

---@alias FriendData table<number, number[]>
---@alias InviteSession {fromSrc: string, fromId: number, toSrc: string, toId: number}

function Impl:Init()
  main:LogInfo("%s initialized", self:GetName())
  ---@type FriendData
  self.friendsData = {}
  self.sessionId = 0
  ---@type table<number, InviteSession>
  self.inviteSessions = {}
  self:CreateDatabase()
  self:RegisterEvents()
end

function Impl:OnReady()
  main:LogInfo("%s ready", self:GetName())
end

function Impl:CreateDatabase()
  local response = MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `lr_friends` (
      `id` int(11) DEFAULT NULL,
      `data` longtext DEFAULT NULL,
      KEY `FK__users` (`id`),
      CONSTRAINT `FK__users` FOREIGN KEY (`id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
  ]])
  self:LogInfo("%s", json.encode(response))
end

function Impl:GetFriends(playerId)
  if self.friendsData[playerId] then
    return self.friendsData[playerId]
  end
  local response = MySQL.query.await("SELECT * FROM lr_friends WHERE id = @id", {
    ['@id'] = playerId
  })
  if response[1] then
    self.friendsData[playerId] = json.decode(response[1].data)
    return self.friendsData[playerId]
  end
end

function Impl:RegisterEvents()
  ---lr_lib:server:friendcontroller:get
  ---@param source string
  ---@return number[]|false, string|nil
  lib.callback.register('lr_lib:server:friendcontroller:get', function(source)
    local xPlayer = GetPlayerFromId(source)
    if not xPlayer then
      return false, "Player not found"
    end
    local friends = self:GetFriends(xPlayer.idcard)
    if not friends then
      MySQL.insert.await('INSERT INTO `lr_friends` (id, data) VALUES (?, ?)', {
        xPlayer.idcard, json.encode({})
      })
      return {}
    end
    return friends
  end)
  RegisterNetEvent('lr_lib:server:friendcontroller:request', function (targetSrc)
    local _source = source
    self:RequestInvite(_source, targetSrc)
  end)
end

function Impl:AddFriend(playerId, targetId)
  local friends = self:GetFriends(playerId)
  if not friends then
    return
  end
  for _, friendId in ipairs(friends) do
    if friendId == targetId then
      return
    end
  end
  table.insert(friends, targetId)
  MySQL.update.await('UPDATE `lr_friends` SET data = ? WHERE id = ?', {
    json.encode(friends), playerId
  })
end

function Impl:RemoveFriend(playerId, targetId)
  local friends = self:GetFriends(playerId)
  if not friends then
    return
  end
  for i, friendId in ipairs(friends) do
    if friendId == targetId then
      table.remove(friends, i)
      break
    end
  end
  MySQL.update.await('UPDATE `lr_friends` SET data = ? WHERE id = ?', {
    json.encode(friends), playerId
  })
end

function Impl:RequestInvite(fromSrc, toSrc)
  local fromPlayer = GetPlayerFromId(fromSrc)
  local toPlayer = GetPlayerFromId(toSrc)
  if not fromPlayer or not toPlayer then
    return
  end
  local fromFriends = self:GetFriends(fromPlayer.idcard)
  for k, v in ipairs(fromFriends) do 
    if v == toPlayer.idcard then
      fromPlayer.showNotification("Đã kết bạn rồi", "error", 5000)
      return
    end
  end
  
  for k, v in pairs(self.inviteSessions) do 
    if v.fromId == fromPlayer.idcard or v.toId == fromPlayer.idcard then
      fromPlayer.showNotification("Đang bận", "error", 5000)
      return
    end
    if v.toId == toPlayer.idcard or v.fromId == toPlayer.idcard then
      toPlayer.showNotification("Đang bận", "error", 5000)
      return
    end
  end
  self.sessionId = self.sessionId + 1
  self.inviteSessions[self.sessionId] = {
    fromSrc = fromSrc,
    fromId = fromPlayer.idcard,
    toSrc = toSrc,
    toId = toPlayer.idcard
  }
  local result = lib.callback.await('lr_lib:client:friendcontrol:request', toSrc, fromPlayer.idcard, self.sessionId)
  self.inviteSessions[self.sessionId] = nil
  if not result then
    fromPlayer.showNotification("Người chơi không online hoặc không chấp nhận lời mời", "error", 5000)
    return
  end
  fromPlayer.showNotification(("%s đã chấp nhận lời mời kết bạn"):format(toPlayer.name), "success", 5000)
  self:AddFriend(fromPlayer.idcard, toPlayer.idcard)
  TriggerClientEvent('lr_lib:client:friendcontrol:update', fromSrc, fromFriends, true)
  self:AddFriend(toPlayer.idcard, fromPlayer.idcard)
  local toFriends = self:GetFriends(toPlayer.idcard)
  TriggerClientEvent('lr_lib:client:friendcontrol:update', toSrc, toFriends, true)
end