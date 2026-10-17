StateBags = {}
StateBags.__index = StateBags

function StateBags:new()
  local stateBags = setmetatable({
    registeredStateBags = {},
    entityWatchers = {},
    playerWatchers = {},
    globalWatchers = {},
    syncEvents = {},
  }, StateBags)

  stateBags:init()

  return stateBags
end

function StateBags:init()
  self:registerSyncEvents()
end

function StateBags:registerSyncEvents()
  RegisterNetEvent(eventName .. "client:syncStateBag")
  AddEventHandler(eventName .. "client:syncStateBag", function(entityType, entityId, key, value)
    self:handleServerSync(entityType, entityId, key, value)
  end)

  RegisterNetEvent(eventName .. "client:removeStateBag")
  AddEventHandler(eventName .. "client:removeStateBag", function(entityType, entityId, key)
    self:handleServerRemove(entityType, entityId, key)
  end)
end

local function shouldSync(sync)
  return sync ~= false
end

local function validEntity(entity)
  return entity and DoesEntityExist(entity)
end

local function validVehicle(vehicle)
  return validEntity(vehicle) and IsEntityAVehicle(vehicle)
end

function StateBags:setEntityStateBag(entity, key, value, sync)
  if not validEntity(entity) then
    return false
  end

  local netId = NetworkGetNetworkIdFromEntity(entity)
  Entity(entity).state:set(key, value, true)

  if shouldSync(sync) then
    TriggerServerEvent(eventName .. "server:setEntityStateBag", "entity", netId, key, value)
  end

  self:triggerWatchers("entity", netId, key, value)
  return true
end

function StateBags:getEntityStateBag(entity, key)
  if not validEntity(entity) then
    return nil
  end

  return Entity(entity).state[key]
end

function StateBags:removeEntityStateBag(entity, key, sync)
  if not validEntity(entity) then
    return false
  end

  local netId = NetworkGetNetworkIdFromEntity(entity)
  Entity(entity).state:set(key, nil, true)

  if shouldSync(sync) then
    TriggerServerEvent(eventName .. "server:removeEntityStateBag", "entity", netId, key)
  end

  self:triggerWatchers("entity", netId, key, nil)
  return true
end

function StateBags:setVehicleStateBag(vehicle, key, value, sync)
  if not validVehicle(vehicle) then
    return false
  end

  local netId = VehToNet(vehicle)
  Entity(vehicle).state:set(key, value, true)

  if shouldSync(sync) then
    TriggerServerEvent(eventName .. "server:setEntityStateBag", "vehicle", netId, key, value)
  end

  self:triggerWatchers("vehicle", netId, key, value)
  return true
end

function StateBags:getVehicleStateBag(vehicle, key)
  if not validVehicle(vehicle) then
    return nil
  end

  return Entity(vehicle).state[key]
end

function StateBags:removeVehicleStateBag(vehicle, key, sync)
  if not validVehicle(vehicle) then
    return false
  end

  local netId = VehToNet(vehicle)
  Entity(vehicle).state:set(key, nil, true)

  if shouldSync(sync) then
    TriggerServerEvent(eventName .. "server:removeEntityStateBag", "vehicle", netId, key)
  end

  self:triggerWatchers("vehicle", netId, key, nil)
  return true
end

function StateBags:setPlayerStateBag(playerId, key, value, sync)
  if not playerId or not NetworkIsPlayerActive(playerId) then
    return false
  end

  local player = Player(playerId)
  if not player then
    return false
  end

  player.state:set(key, value, true)

  if shouldSync(sync) then
    TriggerServerEvent(eventName .. "server:setPlayerStateBag", playerId, key, value)
  end

  self:triggerWatchers("player", playerId, key, value)
  return true
end

function StateBags:getPlayerStateBag(playerId, key)
  if not playerId or not NetworkIsPlayerActive(playerId) then
    return nil
  end

  local player = Player(playerId)
  if not player then
    return nil
  end

  return player.state[key]
end

function StateBags:removePlayerStateBag(playerId, key, sync)
  if not playerId or not NetworkIsPlayerActive(playerId) then
    return false
  end

  local player = Player(playerId)
  if not player then
    return false
  end

  player.state:set(key, nil, true)

  if shouldSync(sync) then
    TriggerServerEvent(eventName .. "server:removePlayerStateBag", playerId, key)
  end

  self:triggerWatchers("player", playerId, key, nil)
  return true
end

function StateBags:setLocalPlayerStateBag(key, value, sync)
  return self:setPlayerStateBag(PlayerId(), key, value, sync)
end

function StateBags:getLocalPlayerStateBag(key)
  return self:getPlayerStateBag(PlayerId(), key)
end

function StateBags:removeLocalPlayerStateBag(key, sync)
  return self:removePlayerStateBag(PlayerId(), key, sync)
end

function StateBags:setGlobalStateBag(key, value, sync)
  GlobalState:set(key, value, true)

  if shouldSync(sync) then
    TriggerServerEvent(eventName .. "server:setGlobalStateBag", key, value)
  end

  self:triggerWatchers("global", "global", key, value)
  return true
end

function StateBags:getGlobalStateBag(key)
  return GlobalState[key]
end

function StateBags:removeGlobalStateBag(key, sync)
  GlobalState:set(key, nil, true)

  if shouldSync(sync) then
    TriggerServerEvent(eventName .. "server:removeGlobalStateBag", key)
  end

  self:triggerWatchers("global", "global", key, nil)
  return true
end

function StateBags:watchEntity(entity, key, callback)
  if not validEntity(entity) then
    return false
  end

  local watcherId = self:generateWatcherId()
  self.entityWatchers[watcherId] = {
    entityType = "entity",
    entityId = NetworkGetNetworkIdFromEntity(entity),
    key = key,
    callback = callback,
  }

  return watcherId
end

function StateBags:watchVehicle(vehicle, key, callback)
  if not validVehicle(vehicle) then
    return false
  end

  local watcherId = self:generateWatcherId()
  self.entityWatchers[watcherId] = {
    entityType = "vehicle",
    entityId = VehToNet(vehicle),
    key = key,
    callback = callback,
  }

  return watcherId
end

function StateBags:watchPlayer(playerId, key, callback)
  if not playerId or not NetworkIsPlayerActive(playerId) then
    return false
  end

  local watcherId = self:generateWatcherId()
  self.playerWatchers[watcherId] = {
    entityType = "player",
    entityId = playerId,
    key = key,
    callback = callback,
  }

  return watcherId
end

function StateBags:watchGlobal(key, callback)
  local watcherId = self:generateWatcherId()
  self.globalWatchers[watcherId] = {
    entityType = "global",
    entityId = "global",
    key = key,
    callback = callback,
  }

  return watcherId
end

function StateBags:unwatchStateBag(watcherId)
  if self.entityWatchers[watcherId] then
    self.entityWatchers[watcherId] = nil
    return true
  end

  if self.playerWatchers[watcherId] then
    self.playerWatchers[watcherId] = nil
    return true
  end

  if self.globalWatchers[watcherId] then
    self.globalWatchers[watcherId] = nil
    return true
  end

  return false
end

function StateBags:triggerWatchers(entityType, entityId, key, value)
  local watchers = {}

  if entityType == "entity" or entityType == "vehicle" then
    for _, watcher in pairs(self.entityWatchers) do
      if watcher.entityId == entityId and (watcher.key == key or watcher.key == "*") then
        table.insert(watchers, watcher)
      end
    end
  elseif entityType == "player" then
    for _, watcher in pairs(self.playerWatchers) do
      if watcher.entityId == entityId and (watcher.key == key or watcher.key == "*") then
        table.insert(watchers, watcher)
      end
    end
  elseif entityType == "global" then
    for _, watcher in pairs(self.globalWatchers) do
      if watcher.key == key or watcher.key == "*" then
        table.insert(watchers, watcher)
      end
    end
  end

  for _, watcher in pairs(watchers) do
    if watcher.callback then
      watcher.callback(entityType, entityId, key, value)
    end
  end
end

function StateBags:handleServerSync(entityType, entityId, key, value)
  if entityType == "entity" then
    local entity = NetworkGetEntityFromNetworkId(entityId)
    if validEntity(entity) then
      Entity(entity).state:set(key, value, false)
      self:triggerWatchers("entity", entityId, key, value)
    end
  elseif entityType == "vehicle" then
    local vehicle = NetToVeh(entityId)
    if validEntity(vehicle) then
      Entity(vehicle).state:set(key, value, false)
      self:triggerWatchers("vehicle", entityId, key, value)
    end
  elseif entityType == "player" then
    if NetworkIsPlayerActive(entityId) then
      local player = Player(entityId)
      if player then
        player.state:set(key, value, false)
        self:triggerWatchers("player", entityId, key, value)
      end
    end
  elseif entityType == "global" then
    GlobalState:set(key, value, false)
    self:triggerWatchers("global", "global", key, value)
  end
end

function StateBags:handleServerRemove(entityType, entityId, key)
  self:handleServerSync(entityType, entityId, key, nil)
end

function StateBags:generateWatcherId()
  return tostring(GetGameTimer()) .. "_" .. tostring(math.random(1000, 9999))
end

function StateBags:bulkSetEntityStateBag(entity, values, sync)
  if not validEntity(entity) or type(values) ~= "table" then
    return false
  end

  local state = Entity(entity).state
  local netId = NetworkGetNetworkIdFromEntity(entity)

  for key, value in pairs(values) do
    state:set(key, value, true)
    self:triggerWatchers("entity", netId, key, value)
  end

  if shouldSync(sync) then
    TriggerServerEvent(eventName .. "server:bulkSetEntityStateBag", "entity", netId, values)
  end

  return true
end

function StateBags:bulkSetVehicleStateBag(vehicle, values, sync)
  if not validVehicle(vehicle) or type(values) ~= "table" then
    return false
  end

  local state = Entity(vehicle).state
  local netId = VehToNet(vehicle)

  for key, value in pairs(values) do
    state:set(key, value, true)
    self:triggerWatchers("vehicle", netId, key, value)
  end

  if shouldSync(sync) then
    TriggerServerEvent(eventName .. "server:bulkSetEntityStateBag", "vehicle", netId, values)
  end

  return true
end

Statebags = StateBags:new()
