local resourceName = GetCurrentResourceName()

if resourceName ~= "bablo-chopshop" then
  error("Resource name must be 'bablo-chopshop'")
  return
end

local function getNetworkEntity(entityType, netId)
  if entityType == "vehicle" or entityType == "entity" then
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and DoesEntityExist(entity) then
      return entity
    end
  end

  return nil
end

RegisterServerEvent(eventName .. "server:registerVehicle")
AddEventHandler(eventName .. "server:registerVehicle", function(chopShopId, vehicleData)
  local playerSource = source
  local player = Framework:fetchPlayer(playerSource)
  if not player or not chopShopId then
    return
  end

  local requiredPolice = Config.PoliceOnDutyRequired or Config.PoliceRequired or 0
  if requiredPolice > 0 then
    local currentPolice = Framework:getPoliceCount()
    if currentPolice < requiredPolice then
      Framework:Notify(playerSource, (Translate("NOT_ENOUGH_POLICE")):format(requiredPolice))
      return
    end
  end

  if not Sessions:getPlayer(chopShopId, playerSource) then
    Sessions:addPlayer(chopShopId, playerSource)
  end

  Sessions:addVehicle(chopShopId, vehicleData)

  local session = Sessions:Get(chopShopId)
  if not session then
    return
  end

  for sessionPlayer, active in pairs(session.players) do
    if active then
      TriggerClientEvent(eventName .. "client:updateVehicles", sessionPlayer, chopShopId, session.vehicles)
    end
  end
end)

RegisterServerEvent(eventName .. "server:deleteVehicle")
AddEventHandler(eventName .. "server:deleteVehicle", function(netId, chopShopId)
  if not netId then
    return
  end

  local entity = NetworkGetEntityFromNetworkId(netId)

  if chopShopId then
    local session = Sessions:Get(chopShopId)
    if not session then
      return
    end

    Sessions:removeVehicle(chopShopId, entity)
  end

  if entity and DoesEntityExist(entity) then
    DeleteEntity(entity)
  end
end)

RegisterServerEvent(eventName .. "server:leaveZone")
AddEventHandler(eventName .. "server:leaveZone", function(chopShopId)
  local playerSource = source
  local player = Framework:fetchPlayer(playerSource)
  if not player or not chopShopId or not Sessions:Get(chopShopId) then
    return
  end

  if Sessions:getPlayer(chopShopId, playerSource) then
    Sessions:removePlayer(chopShopId, playerSource)
  end
end)

RegisterServerEvent(eventName .. "server:removeVehicleFromContract")
AddEventHandler(eventName .. "server:removeVehicleFromContract", function(vehicleHash)
  local playerSource = source
  local player = Framework:fetchPlayer(playerSource)
  local identifier = Framework:getIdentifier(playerSource)

  if not identifier or not player then
    return
  end

  vehicleHash = tostring(vehicleHash)
  local vehicleConfig = Config.VehicleHashes[vehicleHash]
  if not vehicleConfig then
    return
  end

  local contract = Main:hasVehicleInContract(player, vehicleHash, playerSource)
  if not contract then
    Framework:Notify(playerSource, Translate("VEHICLE_NOT_IN_CONTRACT_SERVER"))
    return
  end

  if contract.info then
    contract.metadata = contract.info
  end

  local metadata = contract.metadata
  if not metadata or not metadata.vehicles then
    return
  end

  local vehicles = metadata.vehicles
  metadata.completed_vehicles = metadata.completed_vehicles or {}

  for spawnName, status in pairs(vehicles) do
    Trace(
      "Removing vehicle from contract:",
      spawnName,
      status,
      vehicleConfig and NormalizeVehicleModel(spawnName) == vehicleConfig.spawnName,
      vehicleHash,
      vehicleConfig
    )

    if vehicleConfig and NormalizeVehicleModel(spawnName) == vehicleConfig.spawnName then
      metadata.completed_vehicles[vehicleConfig.spawnName] = metadata.completed_vehicles[vehicleConfig.spawnName] or "COMPLETED"
      vehicles[spawnName] = nil
      Trace("MOVED to completed_vehicles and removed from active:", spawnName)
    end
  end

  metadata.vehicles = vehicles
  metadata.vehicle_count = (metadata.vehicle_count or 0) - 1

  local activeVehicleLabels = {}
  for spawnName, status in pairs(vehicles) do
    if status == "ON_GOING" then
      local normalizedModel = NormalizeVehicleModel(spawnName)
      table.insert(activeVehicleLabels, Main.globalVehicles[normalizedModel] or Main.globalVehicles[spawnName] or spawnName)
    end
  end

  metadata.vehicle_labels = table.concat(activeVehicleLabels, ", ")
  Inventory:setMetadata(playerSource, {
    slot = contract.slot,
  }, metadata)

  if metadata.vehicle_count <= 0 then
    Main:cleanupMissionVehicle(playerSource)
    TriggerClientEvent(eventName .. "client:stopVehicleSearch", playerSource)
    Framework:Notify(playerSource, Translate("CONTRACT_COMPLETED_GO_BACK"), 8000, "success")
  else
    Main:cleanupMissionVehicle(playerSource)
    TriggerClientEvent(eventName .. "client:stopVehicleSearch", playerSource)
    Framework:Notify(
      playerSource,
      (Translate("VEHICLE_CHOPPED_REMAINING")):format(metadata.vehicle_count, metadata.original_count),
      5000,
      "info"
    )
    Framework:Notify(playerSource, "Hãy mở Hợp đồng trong túi đồ và bấm 'Bắt đầu tìm' cho xe tiếp theo!", 6000, "info")
  end


  Reputation.AddExperience(playerSource, Config.XPPerVehicle)
  sendWebhook(playerSource, "CHOPPED_A_VEHICLE", vehicleConfig.spawnName)

  MySQL.query.await([[
    UPDATE bablo_chop_shop_users
    SET vehicles_chopped = vehicles_chopped + 1
    WHERE identifier = ?
  ]], { identifier })
end)

RegisterServerEvent(eventName .. "server:addStress")
AddEventHandler(eventName .. "server:addStress", function(amount)
  local playerSource = source
  local player = Framework:fetchPlayer(playerSource)
  if not player then
    return
  end

  amount = tonumber(amount) or 1.0

  if Framework.addStress then
    Framework:addStress(playerSource, amount)
  elseif player.Functions and player.Functions.SetMetaData then
    local currentStress = (player.PlayerData and player.PlayerData.metadata and player.PlayerData.metadata["stress"]) or 0
    local newStress = math.min(100, currentStress + amount)
    player.Functions.SetMetaData("stress", newStress)
  end
end)

RegisterServerEvent(eventName .. "server:setEntityStateBag")
AddEventHandler(eventName .. "server:setEntityStateBag", function(entityType, netId, key, value)
  local entity = getNetworkEntity(entityType, netId)
  if not entity then
    return
  end

  Entity(entity).state:set(key, value, true)
end)

RegisterServerEvent(eventName .. "server:removeEntityStateBag")
AddEventHandler(eventName .. "server:removeEntityStateBag", function(entityType, netId, key)
  local entity = getNetworkEntity(entityType, netId)
  if not entity then
    return
  end

  Entity(entity).state:set(key, nil, true)
end)

RegisterServerEvent(eventName .. "server:setPlayerStateBag")
AddEventHandler(eventName .. "server:setPlayerStateBag", function(playerId, key, value)
  if not NetworkIsPlayerActive(playerId) then
    return
  end

  local player = Player(playerId)
  if not player then
    return
  end

  player.state:set(key, value, true)
end)

RegisterServerEvent(eventName .. "server:removePlayerStateBag")
AddEventHandler(eventName .. "server:removePlayerStateBag", function(playerId, key)
  if not NetworkIsPlayerActive(playerId) then
    return
  end

  local player = Player(playerId)
  if not player then
    return
  end

  player.state:set(key, nil, true)
end)

RegisterServerEvent(eventName .. "server:setGlobalStateBag")
AddEventHandler(eventName .. "server:setGlobalStateBag", function(key, value)
  GlobalState:set(key, value, true)
end)

RegisterServerEvent(eventName .. "server:removeGlobalStateBag")
AddEventHandler(eventName .. "server:removeGlobalStateBag", function(key)
  GlobalState:set(key, nil, true)
end)

RegisterServerEvent(eventName .. "server:bulkSetEntityStateBag")
AddEventHandler(eventName .. "server:bulkSetEntityStateBag", function(entityType, netId, values)
  local entity = getNetworkEntity(entityType, netId)
  if not entity or type(values) ~= "table" then
    return
  end

  local state = Entity(entity).state
  for key, value in pairs(values) do
    state:set(key, value, true)
  end
end)

RegisterServerEvent(eventName .. "server:sendNotification")
AddEventHandler(eventName .. "server:sendNotification", function(chopShopId, vehicleModel, playerId)
  if not chopShopId or not vehicleModel or not Config.ChopShops[chopShopId] then
    return
  end

  if tonumber(source) ~= tonumber(playerId) then
    return
  end

  local player = Framework:fetchPlayer(source)
  if not player then
    return
  end

  local vehicleLabel = Main.globalVehicles[vehicleModel] or vehicleModel
  local message = (Translate("LOOK_OUT_FOR_VEHICLE_IN_AREA")):format(vehicleLabel)
  local phoneNumber = exports["lb-phone"]:GetEquippedPhoneNumber(source)

  if phoneNumber then
    exports["lb-phone"]:SendMessage(Config.ChopShops[chopShopId].ped.label, phoneNumber, message)
  end
end)

RegisterServerEvent(eventName .. "server:vehicleFound")
AddEventHandler(eventName .. "server:vehicleFound", function(netId)
  local playerSource = source
  if Main.activeMissions[playerSource] then
    Main.activeMissions[playerSource].found = true
  end
end)

AddEventHandler("playerDropped", function()
  local playerSource = source
  Main:cleanupMissionVehicle(playerSource)
end)
