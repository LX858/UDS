Reputation = {}

local function failure(message)
  return {
    success = false,
    message = message,
  }
end

local function getXpMultiplier(level)
  local levelConfig = Config.Levels[level]
  return levelConfig and levelConfig.attributes and levelConfig.attributes.XP_MULTIPLIER or 1
end

local repCache = {}

local function updateExperience(identifier, xp, level)
  repCache[identifier] = nil
  return MySQL.query.await([[
    UPDATE bablo_chop_shop_users
    SET xp = ?, level = ?
    WHERE identifier = ?
  ]], { xp, level, identifier })
end

function Reputation.CalculateLevel(xp)
  if not xp or xp < 0 then
    return 1
  end

  for level = #Config.Levels, 1, -1 do
    if xp >= Config.Levels[level].xp then
      return level
    end
  end

  return 1
end

function Reputation.Get(identifier)
  if not identifier then
    return failure("Failed to get identifier")
  end

  local now = GetGameTimer()
  local cached = repCache[identifier]
  if cached and cached.expiry > now then
    return {
      success = true,
      message = "Reputation data found (cached)",
      data = cached.data,
    }
  end

  local query = [[
    SELECT xp, level, contracts_completed, vehicles_chopped, created_at, updated_at
    FROM bablo_chop_shop_users
    WHERE identifier = ?
  ]]

  local result = MySQL.query.await(query, { identifier })
  if not result or #result == 0 then
    MySQL.query.await([[
      INSERT INTO bablo_chop_shop_users (identifier) VALUES (?)
    ]], { identifier })

    result = MySQL.query.await(query, { identifier })
  end

  if not result or #result == 0 then
    return failure("No reputation data found")
  end

  local reputation = result[1]
  local data = {
    xp = reputation.xp,
    level = reputation.level,
    contractsCompleted = reputation.contracts_completed,
    vehiclesChopped = reputation.vehicles_chopped,
    createdAt = reputation.created_at,
    updatedAt = reputation.updated_at,
  }

  repCache[identifier] = {
    data = data,
    expiry = now + 5000, -- Cache trong 5 giây
  }

  return {
    success = true,
    message = "Reputation data found",
    data = data,
  }
end

function Reputation.AddExperience(playerSource, amount)
  local identifier = Framework:getIdentifier(playerSource)
  if not identifier then
    return failure("Failed to get identifier")
  end

  local reputation = Reputation.Get(identifier)
  if not reputation.success or not reputation.data then
    return failure("Failed to get reputation data")
  end

  local oldLevel = reputation.data.level or 1
  local xpAdded = amount * getXpMultiplier(oldLevel)
  local oldXp = reputation.data.xp or 0
  local newXp = oldXp + xpAdded
  local newLevel = Reputation.CalculateLevel(newXp)

  local result = updateExperience(identifier, newXp, newLevel)
  if not result or result.affectedRows == 0 then
    return failure("Failed to add experience")
  end

  local response = {
    success = true,
    message = "Experience added successfully",
    data = {
      xpAdded = xpAdded,
      newXP = newXp,
      oldLevel = oldLevel,
      newLevel = newLevel,
      leveledUp = oldLevel < newLevel,
    },
  }

  if oldLevel < newLevel then
    TriggerClientEvent(eventName .. "client:levelUp", playerSource, {
      oldLevel = oldLevel,
      newLevel = newLevel,
      newXP = newXp,
    })
  end

  return response
end

function Reputation.ReduceExperience(playerSource, amount)
  local identifier = Framework:getIdentifier(playerSource)
  if not identifier then
    return failure("Failed to get identifier")
  end

  local reputation = Reputation.Get(identifier)
  if not reputation.success or not reputation.data then
    return failure("Failed to get reputation data")
  end

  local oldXp = reputation.data.xp or 0
  local newXp = math.max(0, oldXp - amount)
  local oldLevel = reputation.data.level or 1
  local newLevel = Reputation.CalculateLevel(newXp)

  local result = updateExperience(identifier, newXp, newLevel)
  if not result or result.affectedRows == 0 then
    return failure("Failed to reduce experience")
  end

  local response = {
    success = true,
    message = "Experience reduced successfully",
    data = {
      xpRemoved = oldXp - newXp,
      newXP = newXp,
      oldLevel = oldLevel,
      newLevel = newLevel,
      levelChanged = newLevel ~= oldLevel,
    },
  }

  if oldLevel > newLevel then
    TriggerClientEvent(eventName .. "client:levelDown", playerSource, {
      oldLevel = oldLevel,
      newLevel = newLevel,
      newXP = newXp,
    })
  end

  return response
end
