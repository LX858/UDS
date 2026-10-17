---@class SVPlayerImpl : Impl
local Impl = NewImpl("Player")

function Impl:Init()
  self:LogInfo("initialized")
  self:RegisterEvents()
  self:CheckDatabase()
  self.players = {} --[[@as table<number, sPlayer>]]
  GlobalState.TimeStamp = os.time()
  GlobalState.PlayerCount = 0
  self.playerCount = 0
  self:TimeStamp()
  self:LoadPlayerCount()
end

function Impl:TimeStamp()
  CreateThread(function()
    while true do
      Wait(1000) -- 1 second
      local currentTime = os.time()
      GlobalState.TimeStamp = currentTime
    end
  end)
end

function Impl:LoadPlayerCount()
  local playerCount = GetNumPlayerIndices()
  GlobalState.PlayerCount = playerCount
  self.playerCount = playerCount
end

function Impl:CheckDatabase()
  MySQL.query.await([[
CREATE TABLE IF NOT EXISTS `lr_lib_extended_players` (
  `identifier` varchar(255) NOT NULL,
  `metadata` longtext DEFAULT NULL,
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
  ]])
end

function Impl:OnReady()
  self:LogInfo("ready")
  self:SaveThread()
end

function Impl:RegisterEvents()
  ---@param source string
  ---@return PlayerData|nil
  lib.callback.register('lr_lib:server:onPlayerLoaded', function(source)
    self:LogInfo("onPlayerLoaded", source)
    local _source = tonumber(source)
    if not _source then
      return nil
    end
    self:OnPlayerLoaded(_source)
    local player = self:GetPlayer(_source)
    if player then
      return player:Serialize()
    end
  end)

  --[[ lib.callback.register('lr_lib:sv:getPlayerLastPosition', function(source)
    local Player = GetPlayerFromId(source)
    if Player then
      local sql = "SELECT coords FROM `users` WHERE id = ?"
      local result = MySQL.scalar.await(sql, { Player.id })
      if result then
        return json.decode(result)
      end
    end
  end) ]]

  ---@param playerSrc string
  ---@param reason string
  AddEventHandler("playerDropped", function(reason, resourceName, clientDropReason)
    local src = source
    self:OnPlayerDropped(src)
  end)

  RegisterNetEvent("lr_lib:sv:addStat", function(itemName, slot)
    local src = source
    local itemData = Config.Items[itemName]
    if not itemData then
      return
    end
    local player = self:GetPlayer(tonumber(src))
    if not player then
      return
    end
    player:AddStat(itemData.type, itemData.status)
    if itemData.remove then
      exports.ox_inventory:RemoveItem(src, itemName, 1, nil, slot)
    end
  end)
end

---@param playerSrc number
function Impl:OnPlayerLoaded(playerSrc)
  if self.players[tostring(playerSrc)] then
    return print("Player already exists:", playerSrc)
  end
  local player = sPlayer(playerSrc)
  self.players[tostring(playerSrc)] = player
  self.playerCount = self.playerCount + 1
  GlobalState.PlayerCount = self.playerCount
end

---@param playerSrc number
function Impl:OnPlayerDropped(playerSrc)
  local player = self.players[tostring(playerSrc)]
  if player then
    player:Destroy()
    self.players[tostring(playerSrc)] = nil
    self.playerCount = self.playerCount - 1
    if self.playerCount < 0 then
      self.playerCount = 0
    end
    GlobalState.PlayerCount = self.playerCount
    print("Dropped Player:", playerSrc)
  end
end

---@param playerSrc number
---@return sPlayer|nil
function Impl:GetPlayer(playerSrc)
  return self.players[tostring(playerSrc)]
end

---@param idCard number
---@return sPlayer|nil
function Impl:GetPlayerByIdCard(idCard)
  for _, player in pairs(self.players) do
    if player.id == idCard then
      return player
    end
  end
end

function Impl:SaveThread()
  CreateThread(function()
    while true do
      Wait(1000 * 60 * 5) -- 5 phút
      local data = {}
      for _, player in pairs(self.players) do
        if player.changed then
          table.insert(data, player:GetSaveData())
          player.changed = false
        end
      end
      if #data > 0 then
        MySQL.prepare.await(
          "INSERT INTO lr_lib_extended_players (identifier, metadata) VALUES (?, ?) ON DUPLICATE KEY UPDATE metadata = ?",
          data)
      end
    end
  end)
end

---@param playerSrc any
---@param method any
---@param ... unknown
---@return unknown
function Impl:CallPlayerMethod(playerSrc, method, ...)
  local _source = tonumber(playerSrc)
  if not _source then
    return nil
  end
  local player = self:GetPlayer(_source)
  if player then
    return player[method](player, ...)
  end
  return nil
end
