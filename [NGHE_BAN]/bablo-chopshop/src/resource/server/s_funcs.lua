Main = {
  globalVehicles = {},
  vehicleEntitites = {},
  activeMissions = {},
  usableItems = {
    {
      name = "bchop_contract",
      use = function(playerSource, item)
        TriggerClientEvent(eventName .. "client:useContractItem", playerSource, item)
      end,
    },
  },
}

local contractCooldowns = {}

function Main:Init()
  math.randomseed(GetGameTimer() + os.time())
  math.random()
  math.random()
  math.random()

  Sessions:Init()

  if Inventory and Inventory.Init then
    Inventory:Init()
  else
    local attempts = 0
    while not (Inventory and Inventory.Init) and attempts < 30 do
      attempts = attempts + 1
      Wait(100)
    end

    if Inventory and Inventory.Init then
      Inventory:Init()
    else
      Trace("^3[bablo-chopshop] Notice: Inventory:Init not defined or already initialized.^0")
    end
  end
end

function Main:hasContracts(playerOrSource)
  if not playerOrSource then
    return false
  end

  local playerSource = type(playerOrSource) == "table" and (playerOrSource.source or (playerOrSource.PlayerData and playerOrSource.PlayerData.source)) or playerOrSource
  if not playerSource then
    return false
  end

  local inventory = Inventory:getPlayerInventory(playerSource) or {}
  for _, item in pairs(inventory) do
    if item.item == "bchop_contract" then
      return true
    end
  end

  return false
end

function Main:hasFinishedContract(_, playerSource)
  if not playerSource then
    return false
  end

  local inventory = Inventory:getPlayerInventory(playerSource) or {}
  for _, item in pairs(inventory) do
    if item.item == "bchop_contract" then
      if item.info then
        item.metadata = item.info
      end

      local metadata = item.metadata or {}
      local vehicleCount = tonumber(metadata.vehicle_count)
      if vehicleCount and vehicleCount <= 0 then
        return item
      end
    end
  end

  return false
end

function tableFind(list, predicate)
  if not list or not predicate then
    return nil
  end

  for _, value in pairs(list) do
    if predicate(value) then
      return value
    end
  end

  return nil
end

function Main:hasVehicleInContract(_, vehicleHash, playerSource)
  if not vehicleHash then
    return false
  end

  vehicleHash = tostring(vehicleHash)
  local vehicleConfig = Config.VehicleHashes[vehicleHash]
  if not vehicleConfig then
    return false
  end

  local inventory = Inventory:getPlayerInventory(playerSource)
  if not inventory or #inventory == 0 then
    return false
  end

  for _, item in ipairs(inventory) do
    if item.item == "bchop_contract" then
      if item.info then
        item.metadata = item.info
      end

      local contractVehicles = item.metadata and item.metadata.vehicles
      if contractVehicles then
        for spawnName, status in pairs(contractVehicles) do
          if NormalizeVehicleModel(spawnName) == vehicleConfig.spawnName and status == "ON_GOING" then
            return item
          end
        end
      end
    end
  end

  return false
end

function Main:generateRewardTree(vehicleCount, contractType)
  if type(vehicleCount) ~= "number" then
    vehicleCount = 1
  end
  if not contractType or type(contractType) ~= "string" then
    contractType = "easy"
  end

  local rewardTree = {}
  local rewardConfig = Config.Rewards

  local function resolveCount(count)
    if type(count) == "table" then
      return math.random(count[1], count[2])
    end
    return count
  end

  local function hasValue(tbl, val)
    if not tbl then return false end
    for _, v in ipairs(tbl) do
      if v == val then return true end
    end
    return false
  end

  -- 1. Filter eligible rewards based on contract type
  local eligibleRewards = {}
  for _, reward in ipairs(rewardConfig) do
    if not reward.contract_type or hasValue(reward.contract_type, contractType) then
      table.insert(eligibleRewards, {
        name = reward.name,
        count = reward.count,
        percent = reward.percent or 30,
        limit = reward.limit or 1,
      })
    end
  end

  -- 2. Roll special/additional rewards based on vehicleCount
  local selectedExtra = {}

  if vehicleCount == 1 then
    -- "chỉ được thưởng thêm tối đa 1 vật phẩm đặc biệt nếu nhiệm vụ có 1 xe"
    Shuffle(eligibleRewards)
    for _, reward in ipairs(eligibleRewards) do
      if math.random(100) <= reward.percent then
        table.insert(selectedExtra, {
          name = reward.name,
          count = resolveCount(reward.count),
        })
        Trace("Added 1 special reward for 1-vehicle contract:", reward.name)
        break
      end
    end
  else
    -- "nếu nhiệm vụ có 2 xe trở lên dựa vào số xe trong nhiệm vụ = số lượng đồ thưởng thêm"
    local attempts = 0
    while #selectedExtra < vehicleCount and #eligibleRewards > 0 and attempts < 100 do
      attempts = attempts + 1
      Shuffle(eligibleRewards)
      local addedThisPass = false

      for i = #eligibleRewards, 1, -1 do
        local reward = eligibleRewards[i]
        if math.random(100) <= reward.percent then
          table.insert(selectedExtra, {
            name = reward.name,
            count = resolveCount(reward.count),
          })
          addedThisPass = true
          
          reward.limit = reward.limit - 1
          if reward.limit <= 0 then
            table.remove(eligibleRewards, i)
          end

          if #selectedExtra >= vehicleCount then
            break
          end
        end
      end

      -- If we didn't add anything this pass (due to low percent rolls),
      -- force-add one random item from the eligible pool to guarantee we reach the correct amount
      if not addedThisPass and #eligibleRewards > 0 then
        local randIndex = math.random(#eligibleRewards)
        local reward = eligibleRewards[randIndex]
        table.insert(selectedExtra, {
          name = reward.name,
          count = resolveCount(reward.count),
        })
        
        reward.limit = reward.limit - 1
        if reward.limit <= 0 then
          table.remove(eligibleRewards, randIndex)
        end
      end
    end
  end

  -- 3. Merge extra rewards into tree
  for _, reward in ipairs(selectedExtra) do
    table.insert(rewardTree, reward)
  end

  Trace("Final Reward Tree:", json.encode(rewardTree))
  return rewardTree
end

function Main:getCharacterLevel(identifier)
  local result = MySQL.query.await([[
    SELECT xp, level FROM bablo_chop_shop_users WHERE identifier = ?
  ]], { identifier })

  if result and #result > 0 then
    return {
      level = tonumber(result[1].level),
      xp = result[1].xp,
    }
  end

  MySQL.query.await([[
    INSERT INTO bablo_chop_shop_users (identifier) VALUES (?)
  ]], { identifier })

  Trace("Created new user: %s", identifier)

  return {
    level = 1,
    xp = 0,
  }
end

function Main:getPlayerAnalytics(identifier)
  local result = MySQL.query.await([[
    SELECT
      identifier,
      xp,
      level,
      contracts_completed,
      vehicles_chopped
    FROM bablo_chop_shop_users
    WHERE identifier = ?
  ]], { identifier })

  if not result or not result[1] then
    return {
      level = 1,
      xp = 0,
      contracts_completed = 0,
      vehicles_chopped = 0,
      rank = nil,
    }
  end

  local analytics = result[1]
  local rankResult = MySQL.query.await([[
    SELECT COUNT(*) + 1 as player_rank
    FROM bablo_chop_shop_users
    WHERE xp > ?
  ]], { analytics.xp })

  if rankResult and rankResult[1] then
    analytics.rank = rankResult[1].player_rank
  end

  return analytics
end

function Main:canGetContract(identifier)
  if not Config.ContractCooldown or not Config.ContractCooldown.enabled then
    return { allowed = true }
  end

  if not identifier then
    return { allowed = true }
  end

  local lastContractAt = contractCooldowns[identifier]
  if lastContractAt then
    local remaining = Config.ContractCooldown.cooldown - (os.time() - lastContractAt)
    if remaining > 0 then
      return {
        allowed = false,
        remaining = math.ceil(remaining),
      }
    end
  end

  return { allowed = true }
end

function Main:setContractCooldown(identifier)
  if Config.ContractCooldown and Config.ContractCooldown.enabled then
    contractCooldowns[identifier] = os.time()
  end
end

function Main:playerHasScanner(playerSource)
  local inventory = Inventory:getPlayerInventory(playerSource) or {}
  for _, item in pairs(inventory) do
    local itemName = item.item or item.name or ""
    if itemName:lower() == "weapon_digiscanner" or itemName:upper() == "WEAPON_DIGISCANNER" then
      return true
    end
  end
  return false
end

function Main:spawnMissionVehicle(model, coords)
  local normalizedModel = NormalizeVehicleModel(model)
  local modelHash = GetHashKey(normalizedModel)

  local vehicle = CreateVehicle(
    modelHash,
    coords.x,
    coords.y,
    coords.z,
    coords.w or 0.0,
    true,
    true
  )

  local attempts = 0
  while not DoesEntityExist(vehicle) and attempts < 20 do
    attempts = attempts + 1
    Citizen.Wait(50)
  end

  if not DoesEntityExist(vehicle) then
    vehicle = CreateVehicleServerSetter(
      modelHash,
      "automobile",
      coords.x,
      coords.y,
      coords.z,
      coords.w or 0.0
    )
    attempts = 0
    while not DoesEntityExist(vehicle) and attempts < 20 do
      attempts = attempts + 1
      Citizen.Wait(50)
    end
  end

  if not DoesEntityExist(vehicle) then
    Trace("Notice: Server entity not ready immediately, client fallback will create vehicle:", model)
    return nil, 0
  end

  SetVehicleDoorsLocked(vehicle, 2)

  local netId = NetworkGetNetworkIdFromEntity(vehicle)
  Entity(vehicle).state:set("isChopContractVehicle", true, true)

  return vehicle, netId
end

function Main:startContractMissionForVehicle(playerSource, targetModel)
  if not playerSource or not targetModel then
    return false, "Dữ liệu không hợp lệ"
  end

  local normalizedModel = NormalizeVehicleModel(targetModel)

  -- Clean up old vehicle if any
  self:cleanupMissionVehicle(playerSource)

  -- Pick random location from Config.VehicleCoords
  local spawnCoordsList = Config.VehicleCoords or {}
  if #spawnCoordsList == 0 then
    Trace("No Config.VehicleCoords configured!")
    return false, "Chưa cấu hình tọa độ xe!"
  end

  local locIndex = math.random(1, #spawnCoordsList)
  local loc = spawnCoordsList[locIndex]

  local vehicleEntity, netId = self:spawnMissionVehicle(normalizedModel, loc.coords)

  self.activeMissions[playerSource] = {
    entity = vehicleEntity,
    netId = netId or 0,
    coords = loc.coords,
    radarCoords = loc.radarCoords or loc.coords,
    model = normalizedModel,
  }

  TriggerClientEvent(eventName .. "client:startVehicleSearch", playerSource, {
    netId = netId or 0,
    coords = loc.coords,
    radarCoords = loc.radarCoords or loc.coords,
    model = normalizedModel,
  })

  Trace("Started vehicle search mission for player:", playerSource, "Model:", normalizedModel, "NetID:", tostring(netId))
  return true
end

function Main:startContractMissionForPlayer(playerSource, contractItem)
  if not playerSource or not contractItem then
    return
  end

  local metadata = contractItem.metadata or contractItem.info or {}
  local vehicles = metadata.vehicles or {}

  -- Find first ongoing vehicle in contract
  local targetModel = nil
  for model, status in pairs(vehicles) do
    if status == "ON_GOING" or status == "ongoing" then
      targetModel = model
      break
    end
  end

  if not targetModel then
    Trace("No ongoing vehicle found in contract for player:", playerSource)
    return
  end

  self:startContractMissionForVehicle(playerSource, targetModel)
end


function Main:cleanupMissionVehicle(playerSource)
  if self.activeMissions[playerSource] then
    local veh = self.activeMissions[playerSource].entity
    if veh and DoesEntityExist(veh) then
      DeleteEntity(veh)
    end
    self.activeMissions[playerSource] = nil
  end
end
