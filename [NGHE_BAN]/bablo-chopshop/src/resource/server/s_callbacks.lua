local function response(status, message)
  return {
    status = status,
    message = message,
  }
end

local function fetchPlayer(playerSource)
  local player = Framework:fetchPlayer(playerSource)
  if not player then
    return nil, response(false, "Character not found")
  end

  return player
end

local function getIdentifier(playerSource)
  local identifier = Framework:getIdentifier(playerSource)
  if not identifier then
    return nil, response(false, "Identifier not found")
  end

  return identifier
end

RegisterServerCallback({
  eventName = eventName .. "server:getDialougeData",
  eventCallback = function(playerSource)
    local player, err = fetchPlayer(playerSource)
    if not player then
      return err
    end

    local finishedContract = Main:hasFinishedContract(player, playerSource)
    local identifier, identifierErr = getIdentifier(playerSource)
    if not identifier then
      return identifierErr
    end

    local reputation = Reputation.Get(identifier)
    if not reputation.success then
      return response(false, "Failed to get reputation data")
    end

    return {
      status = true,
      hasContracts = finishedContract,
      user = {
        level = reputation.data.level,
        xp = reputation.data.xp,
      },
    }
  end,
})

RegisterServerCallback({
  eventName = eventName .. "server:giveReward",
  eventCallback = function(playerSource)
    local player, err = fetchPlayer(playerSource)
    if not player then
      return err
    end

    local contract = Main:hasFinishedContract(player, playerSource)
    if not contract then
      return response(false, "No finished contracts found")
    end

    local removedContract
    if contract.slot then
      removedContract = Inventory:removeSpecificPlayerItem(playerSource, contract, 1)
    else
      removedContract = Inventory:removePlayerItem(playerSource, contract.item, 1)
    end

    if not removedContract then
      return response(false, "Failed to remove the completed contract item")
    end

    local identifier, identifierErr = getIdentifier(playerSource)
    if not identifier then
      return response(false, identifierErr.message or "Failed to get identifier")
    end

    local metadata = contract.metadata or {}
    local vehicleCount = tonumber(metadata.original_count) or 1
    local rewardPointsPerVehicle = Config.RewardPointsPerVehicle or 6
    local rewardPoints = vehicleCount * rewardPointsPerVehicle

    local reputation = Reputation.Get(identifier)
    if reputation.success and reputation.data then
      local level = reputation.data.level or 1
      local extraRewardPoints = Config.Levels[level]
        and Config.Levels[level].attributes
        and Config.Levels[level].attributes.EXTRA_REWARDS_POINTS
        or 0

      rewardPoints = rewardPoints + extraRewardPoints
    end

    local contractType = metadata.contract_type
    if not contractType then
      if vehicleCount >= 4 then
        contractType = "hard"
      elseif vehicleCount == 3 then
        contractType = "medium"
      else
        contractType = "easy"
      end
    end

    local rewards = Main:generateRewardTree(vehicleCount, contractType)
    local rewardText = ""
    local moneyReward = 0
    local xpReward = vehicleCount * Config.XPPerVehicle * 2
    local xpResult = Reputation.AddExperience(playerSource, xpReward)

    if xpResult.success and xpResult.data.leveledUp then
      Framework:Notify(
        playerSource,
        (Translate("CONTRACT_XP_GAINED")):format(xpReward),
        3000,
        "info"
      )
    end

    MySQL.query.await([[
      UPDATE bablo_chop_shop_users
      SET contracts_completed = contracts_completed + 1
      WHERE identifier = ?
    ]], { identifier })

    if rewards then
      for index, reward in ipairs(rewards) do
        if reward.name == "money" then
          Framework:addMoney(playerSource, reward.count)
          moneyReward = moneyReward + reward.count
        else
          local itemLabel = reward.name
          if Inventory.getItems then
            for _, item in ipairs(Inventory:getItems() or {}) do
              if item.name == reward.name then
                itemLabel = item.label or reward.name
                break
              end
            end
          end

          local itemName = reward.name
          if reward.Blueprint then
            itemName = "bp_" .. reward.name
          end

          local added = Inventory:addPlayerItem(playerSource, itemName, reward.count)
          if not added then
            Trace("Failed to give item:", reward.name, "count:", reward.count)
          end

          rewardText = rewardText .. string.lower(itemLabel) .. (index < #rewards and ", " or "")
        end

        Citizen.Wait(15)
      end

      if moneyReward > 0 then
        if rewardText ~= "" then
          rewardText = rewardText .. " and " .. moneyReward .. " cash"
        else
          rewardText = moneyReward .. " cash"
        end
      end

      local _, contractTypeTranslation = GetContractTypeForCount(vehicleCount)
      local contractType = Translate(contractTypeTranslation)

      Framework:Notify(
        playerSource,
        (Translate("CONTRACT_COMPLETED_REWARD")):format(contractType, rewardText)
      )

      sendWebhook(playerSource, "COMPLETED_CONTRACT", contractType .. " and got " .. rewardText)
    end

    Main:cleanupMissionVehicle(playerSource)
    TriggerClientEvent(eventName .. "client:stopVehicleSearch", playerSource)

    return {
      status = true,
    }
  end,
})

RegisterServerCallback({
  eventName = eventName .. "server:giveContract",
  eventCallback = function(playerSource, contractType)
    local player, err = fetchPlayer(playerSource)
    if not player then
      return err
    end

    local contractConfig = Config.Contracts[contractType]
    if not contractConfig then
      return response(false, "Invalid contract type")
    end

    local identifier, identifierErr = getIdentifier(playerSource)
    if not identifier then
      return identifierErr
    end

    if Main:hasContracts(playerSource) then
      return response(false, Translate("ALREADY_HAVE_ACTIVE_CONTRACT"))
    end

    local cooldown = Main:canGetContract(identifier)
    if not cooldown.allowed then
      local remaining = cooldown.remaining or 0
      local minutes = math.floor(remaining / 60)
      local seconds = remaining % 60
      local formattedTime

      if minutes > 0 and seconds > 0 then
        formattedTime = ("%d phút %d giây"):format(minutes, seconds)
      elseif minutes > 0 then
        formattedTime = ("%d phút"):format(minutes)
      else
        formattedTime = ("%d giây"):format(seconds)
      end

      return response(false, (Translate("CONTRACT_COOLDOWN")):format(formattedTime))
    end

    local contractPrice = contractConfig.price or Config.ContractPrice or 10000
    if type(contractPrice) == "number" and contractPrice > 0 then
      local cash = Framework:getMoney(playerSource, "cash") or 0
      local bank = Framework:getMoney(playerSource, "bank") or 0
      if cash < contractPrice and bank < contractPrice then
        return response(false, (Translate("NOT_ENOUGH_MONEY_CONTRACT")):format(string.format("%d", contractPrice)))
      end
    end

    local minLevelRequired = contractConfig.minLevelRequired or 1
    if minLevelRequired > 1 then
      local reputation = Reputation.Get(identifier)
      local level = reputation.success and (reputation.data.level or 1) or 1

      if minLevelRequired > level then
        return response(false, (Translate("CONTRACT_LOCKED_LEVEL")):format(minLevelRequired))
      end
    end

    local vehiclePool = {}
    local vehiclePoolLookup = {}
    for _, model in ipairs(contractConfig.vehicles) do
      local normalizedModel = NormalizeVehicleModel(model)
      local vehicleData = Config.VehicleSpawnNames and Config.VehicleSpawnNames[normalizedModel]

      if vehicleData and not vehiclePoolLookup[normalizedModel] then
        vehiclePoolLookup[normalizedModel] = true
        table.insert(vehiclePool, normalizedModel)
      elseif not vehicleData then
        Trace(("Skipping invalid contract vehicle model: %s"):format(tostring(model)))
      end
    end

    if #vehiclePool == 0 then
      return response(false, "No valid vehicles configured for this contract type")
    end

    Shuffle(vehiclePool)

    local vehicleCount = math.random(contractConfig.min, math.min(contractConfig.max, #vehiclePool))
    local contractVehicles = {}
    for index = 1, vehicleCount do
      contractVehicles[vehiclePool[index]] = "ON_GOING"
    end

    local labels = {}
    for model in pairs(contractVehicles) do
      table.insert(labels, Main.globalVehicles[model] or model)
    end

    local vehicleLabels = table.concat(labels, ", ")
    local contractVehicleCount = TableLength(contractVehicles)
    local itemData = {
      name = "bchop_contract",
      amount = 1,
      metadata = {
        vehicles = contractVehicles,
        completed_vehicles = {},
        vehicle_count = contractVehicleCount,
        original_count = contractVehicleCount,
        vehicle_labels = vehicleLabels,
        display = false,
        contract_type = contractType,
      },
    }

    if type(contractPrice) == "number" and contractPrice > 0 then
      local removed = Framework:removeMoney(playerSource, contractPrice)
      if not removed then
        return response(false, (Translate("NOT_ENOUGH_MONEY_CONTRACT")):format(string.format("%d", contractPrice)))
      end
    end

    Inventory:addPlayerItem(playerSource, itemData.name, itemData.amount, itemData.metadata, {
      label = contractConfig.label,
    })

    Main:setContractCooldown(identifier)
    sendWebhook(playerSource, "RECEIVED_CONTRACT", contractConfig.label)


    return {
      status = true,
      message = "Contract given successfully",
      vehicleModel = contractVehicleCount == 1 and vehiclePool[1] or nil,
    }
  end,
})

RegisterServerCallback({
  eventName = eventName .. "server:startSearchVehicle",
  eventCallback = function(playerSource, data)
    local player, err = fetchPlayer(playerSource)
    if not player then
      return err
    end

    local targetModel = data
    if type(data) == "table" then
      targetModel = data.model or data[1]
    end

    if not targetModel or targetModel == "" then
      return response(false, "Mẫu xe không hợp lệ")
    end

    local success, msg = Main:startContractMissionForVehicle(playerSource, targetModel)
    if not success then
      return response(false, msg or "Không thể bắt đầu tìm xe")
    end

    return {
      status = true,
      activeModel = NormalizeVehicleModel(targetModel),
    }
  end,
})

RegisterServerCallback({
  eventName = eventName .. "server:stopSearchVehicle",
  eventCallback = function(playerSource)
    Main:cleanupMissionVehicle(playerSource)
    TriggerClientEvent(eventName .. "client:stopVehicleSearch", playerSource)
    return {
      status = true,
    }
  end,
})

RegisterServerCallback({
  eventName = eventName .. "server:getActiveMission",
  eventCallback = function(playerSource)
    local mission = Main.activeMissions[playerSource]
    if mission then
      return {
        status = true,
        mission = {
          netId = mission.netId,
          coords = mission.coords,
          radarCoords = mission.radarCoords,
          model = mission.model,
        },
      }
    end
    return { status = false }
  end,
})


RegisterServerCallback({
  eventName = eventName .. "server:enterZone",
  eventCallback = function(playerSource, chopShopId)
    local session = Sessions:Get(chopShopId)
    if not session then
      return response(false, "Invalid chop index")
    end

    Sessions:addPlayer(chopShopId, playerSource)

    if not session.vehicles or TableLength(session.vehicles) == 0 then
      return response(false, "Hiện không có xe nào đang được hiển thị tại điểm tháo dỡ xe này.")
    end

    return {
      status = true,
      vehicles = session.vehicles,
    }
  end,
})

RegisterServerCallback({
  eventName = eventName .. "server:isVehicleInContract",
  eventCallback = function(playerSource, vehicleHash)
    local player, err = fetchPlayer(playerSource)
    if not player then
      return err
    end

    return {
      status = Main:hasVehicleInContract(player, vehicleHash, playerSource),
    }
  end,
})

RegisterServerCallback({
  eventName = eventName .. "server:spawnVehicle",
  eventCallback = function(playerSource, vehicleData)
    local player, err = fetchPlayer(playerSource)
    if not player then
      return err
    end

    local vehicleSpawns = vehicleData.vehicleSpawns
    if not vehicleSpawns then
      return response(false, Translate("NO_PARKING_SPOT_FOUND"))
    end

    local vehicleSpawn = GetEmptyParkingSpot(vehicleSpawns)
    if not vehicleSpawn then
      return response(false, Translate("NO_FREE_PARKING_SPOT"))
    end

    local vehicle = SpawnVehicle(GetHashKey(NormalizeVehicleModel(vehicleData.model)), vehicleSpawn)

    return {
      status = true,
      vehicleSpawn = vehicleSpawn,
      netid = NetworkGetNetworkIdFromEntity(vehicle),
    }
  end,
})

RegisterServerCallback({
  eventName = eventName .. "server:getLeaderboards",
  eventCallback = function()
    local leaderboard = Framework:getTopPlayers()
    if not leaderboard then
      return response(false, "Failed to fetch leaderboard data")
    end

    return {
      status = true,
      leaderboard = leaderboard,
    }
  end,
})

RegisterServerCallback({
  eventName = eventName .. "server:getPlayerAnalytics",
  eventCallback = function(playerSource)
    local player, err = fetchPlayer(playerSource)
    if not player then
      return response(false, "Player not found")
    end

    local identifier = Framework:getIdentifier(playerSource)
    local analytics = Main:getPlayerAnalytics(identifier)
    if not analytics then
      return response(false, "Failed to fetch player analytics")
    end

    return {
      status = true,
      analytics = analytics,
    }
  end,
})

RegisterServerCallback({
  eventName = eventName .. "server:getPoliceCount",
  eventCallback = function(playerSource)
    local count = Framework:getPoliceCount()
    return {
      status = true,
      policeCount = count or 0,
    }
  end,
})

