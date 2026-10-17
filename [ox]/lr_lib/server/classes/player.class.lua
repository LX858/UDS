---@class sPlayer:Class
---@operator call():sPlayer
sPlayer = class({ name = "sPlayer" })

---@param playerSrc number
function sPlayer:Init(playerSrc)
  self.source = playerSrc
  self.destroy = false
  self.count = 0
  local xPlayer = GetPlayerFromId(playerSrc)
  while not xPlayer do
    main:LogWarning("Waiting for CORE player to load...")
    self.count = self.count + 1
    Wait(2000)
    xPlayer = GetPlayerFromId(playerSrc)
    if self.count > 40 then
      error("Player not found")
      break
    end
  end
  if not xPlayer then
    error("Player not found")
  end
  self.identifier = xPlayer.identifier
  self.name       = xPlayer.name
  self.id         = xPlayer.id
  self.metadata   = {}
  self.changed    = false
  self:GetData()
  self:BasicNeedThread()
end

function sPlayer:BasicNeedThread()
  CreateThread(function()
    while not self.destroy do
      Wait(Config.StatusTick * 60000)
      if self.destroy then
        return
      end

      local player = CORE.GetPlayerFromId(self.id)
      player.removeStat("hunger", Config.StatusRemove)
      player.removeStat("thirst", Config.StatusRemove)
    end
  end)
end

function sPlayer:AddStat(type, amount)
  if self.destroy then
    return
  end
  local player = CORE.GetPlayerFromId(self.id)
  player.addStat(type, amount)
end

function sPlayer:GetData()
  if self.destroy then
    return
  end
  local row = MySQL.single.await("SELECT metadata FROM lr_lib_extended_players WHERE identifier = ?", {
    self.identifier
  })
  if row and row.metadata then
    self.metadata = json.decode(row.metadata)
  else
    MySQL.query.await("INSERT INTO lr_lib_extended_players (identifier, metadata) VALUES (?, ?)", {
      self.identifier,
      json.encode({})
    })
    self.metadata = {}
    self.changed = true
  end
end

function sPlayer:Save()
  MySQL.update.await("UPDATE lr_lib_extended_players SET metadata = ? WHERE identifier = ?", {
    json.encode(self.metadata),
    self.identifier
  })
end

function sPlayer:Destroy()
  self.destroy = true
  self:Save()
end

---@alias PlayerData {source: number; identifier: string; name: string; id: number; metadata: table<string, any>}
---@return PlayerData
function sPlayer:Serialize()
  if self.destroy then
    return
  end
  return {
    source = self.source,
    identifier = self.identifier,
    name = self.name,
    id = self.id,
    metadata = self.metadata
  }
end

---@return any[]
function sPlayer:GetSaveData()
  if self.destroy then
    return
  end
  return {
    self.identifier,
    json.encode(self.metadata)
  }
end

---@param key string
---@param default any
function sPlayer:GetMeta(key, default)
  if self.destroy then
    return
  end
  if self.metadata[key] == nil then
    self.metadata[key] = default
    if default ~= nil then
      self.changed = true
    end
  end
  return self.metadata[key]
end

---@param key string
---@param value any
function sPlayer:SetMeta(key, value)
  if self.destroy then
    return
  end
  if self.metadata[key] ~= value then
    self.metadata[key] = value
    self.changed = true
    TriggerClientEvent("lr_lib:client:playerMetaDataChanged", self.source, key, value)
  end
end

---@param key string
---@return boolean
function sPlayer:HasMeta(key)
  if self.destroy then
    return
  end
  return self.metadata[key] ~= nil
end

---@param key string
---@param amount number
---@return number|nil, string
function sPlayer:IncreaseMeta(key, amount)
  if self.destroy then
    return
  end
  if type(amount) ~= "number" then
    return nil, "amount is not a number"
  end
  if self.metadata[key] == nil then
    self.metadata[key] = amount
    self.changed = true
  else
    if type(self.metadata[key]) ~= "number" then
      return nil, ("%s is not a number"):format(key)
    end
    self.metadata[key] = self.metadata[key] + amount
    self.changed = true
  end
  TriggerClientEvent("lr_lib:client:playerMetaDataChanged", self.source, key, self.metadata[key])
  return self.metadata[key], ""
end

---@param key string
---@param amount number
---@return number|nil, string
function sPlayer:DecreaseMeta(key, amount)
  if self.destroy then
    return
  end
  if type(amount) ~= "number" then
    return nil, "amount is not a number"
  end
  if self.metadata[key] == nil then
    self.metadata[key] = -amount
    self.changed = true
  else
    if type(self.metadata[key]) ~= "number" then
      return nil, ("%s is not a number"):format(key)
    end
    self.metadata[key] = self.metadata[key] - amount
    self.changed = true
  end
  TriggerClientEvent("lr_lib:client:playerMetaDataChanged", self.source, key, self.metadata[key])
  return self.metadata[key], ""
end
