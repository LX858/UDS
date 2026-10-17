Sessions = {
  data = {},
  trackedVehicles = {},
}

function Sessions:Init()
  self.data = {}
  self.trackedVehicles = {}
  for chopShopId in pairs(Config.ChopShops or {}) do
    self.data[chopShopId] = {
      players = {},
      vehicles = {},
    }
  end
end

function Sessions:Get(chopShopId)
  if not chopShopId or not Config.ChopShops or not Config.ChopShops[chopShopId] then
    return nil
  end

  if not self.data[chopShopId] then
    self.data[chopShopId] = {
      players = {},
      vehicles = {},
    }
  end

  return self.data[chopShopId]
end

function Sessions:addPlayer(chopShopId, playerSource)
  local session = self:Get(chopShopId)
  if session then
    session.players[playerSource] = true
  end
end

function Sessions:removePlayer(chopShopId, playerSource)
  local session = self:Get(chopShopId)
  if session and session.players[playerSource] then
    session.players[playerSource] = nil
  end
end

function Sessions:addVehicle(chopShopId, vehicleData)
  local session = self:Get(chopShopId)
  if session then
    local entity = NetworkGetEntityFromNetworkId(vehicleData.netId)
    vehicleData.entity = entity
    local key = (entity and entity ~= 0) and tostring(entity) or tostring(vehicleData.netId)
    session.vehicles[key] = vehicleData
    if entity and entity ~= 0 then
      self.trackedVehicles[entity] = chopShopId
    end
  end
end

function Sessions:removeVehicle(chopShopId, vehicle)
  local session = self:Get(chopShopId)
  if not session then
    return
  end

  local vehicleKey = tostring(vehicle)
  if session.vehicles[vehicleKey] then
    Trace("Removing vehicle from session: " .. chopShopId, vehicle)
    session.vehicles[vehicleKey] = nil
  end

  for key, data in pairs(session.vehicles) do
    if data.entity == vehicle or (data.netId and tostring(data.netId) == vehicleKey) then
      session.vehicles[key] = nil
    end
  end

  if vehicle and self.trackedVehicles[vehicle] then
    self.trackedVehicles[vehicle] = nil
  end
end

function Sessions:getPlayer(chopShopId, playerSource)
  local session = self:Get(chopShopId)
  return (session and session.players[playerSource] == true) or false
end

function Sessions:doesVehicleExist(vehicle)
  if not vehicle then
    return false
  end

  return self.trackedVehicles[vehicle] or false
end
