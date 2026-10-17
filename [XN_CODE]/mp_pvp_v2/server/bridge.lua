function HasItem(player, itemName, amount)
  if Config.Framework == 'ProjectStarboy' then
    return player.hasItem({
      itemName = itemName,
      amount = amount
    })
  elseif Config.Framework == 'esx' then
    local xItem = player.hasItem(itemName)
    if not xItem then return false end
    return xItem.count >= amount
  else
    local xItem = player.Functions.GetItemByName(itemName)
    if not xItem then return false end
    return xItem.amount >= amount
  end
end

function RemoveItem(player, itemName, amount)
  if Config.Framework == 'ProjectStarboy' then
    return player.removeInventoryItem({
      itemName = itemName,
      amount = amount
    })
  elseif Config.Framework == 'esx' then
    return player.removeInventoryItem(itemName, amount)
  else
    return player.Functions.RemoveItem(itemName, amount)
  end
end

function AddItem(player, itemName, amount)
  if Config.Framework == 'ProjectStarboy' then
    return player.addInventoryItem({
      itemName = itemName,
      amount = amount
    })
  elseif Config.Framework == 'esx' then
    return player.addInventoryItem(itemName, amount)
  else
    return player.Functions.AddItem(itemName, amount)
  end
end

local winRewardBags = {}

function ShouldGiveWinReward(playerId)
  if not Config.WinReward or not Config.WinReward.enabled then return false end

  local chance = math.max(0, math.min(100, tonumber(Config.WinReward.chance) or 50))
  local cycleSize = math.max(1, math.floor(tonumber(Config.WinReward.cycleSize) or 10))
  local rewardCount = math.floor((cycleSize * chance / 100) + 0.5)
  local key = tostring(playerId)
  local bag = winRewardBags[key]

  if not bag or #bag == 0 then
    bag = {}
    for index = 1, cycleSize do
      bag[index] = index <= rewardCount
    end

    for index = cycleSize, 2, -1 do
      local swapIndex = math.random(index)
      bag[index], bag[swapIndex] = bag[swapIndex], bag[index]
    end

    winRewardBags[key] = bag
  end

  return table.remove(bag)
end

function AddMoney(player, amount)
  if Config.Framework == 'ProjectStarboy' then
    return player.addAccountMoney("money", amount)
  elseif Config.Framework == 'esx' then
    return player.addMoney(amount)
  else
    return player.Functions.AddMoney("cash", amount)
  end
end

local playersCache = {}

function GetPlayerFromId(playerSrc)
  if Config.Framework == 'ProjectStarboy' then
    return Framework.GetPlayerFromSource(playerSrc)
  elseif Config.Framework == 'esx' then
    return Framework.GetPlayerFromId(playerSrc)
  else
    if playersCache[playerSrc] then 
      return playersCache[playerSrc]
    end
    playersCache[playerSrc] = Framework.Functions.GetPlayer(playerSrc)
    return playersCache[playerSrc]
  end
end

AddEventHandler('playerDropped', function()
  local src = source 
  playersCache[src] = nil
end)

function ShowNotification(player, msg)
  return player.showNotification(msg)
end
