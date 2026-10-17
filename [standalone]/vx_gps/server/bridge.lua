function HasItem(player, itemName, amount)
  if Config.Framework == 'ProjectStarboy' then
    return player.hasItem({
      itemName = itemName,
      amount = amount
    })
  elseif Config.Framework == 'qbx' then
    local item = player.Functions.GetItemByName(itemName)
    return item ~= nil and (item.amount or item.count or 0) >= amount
  elseif Config.Framework == 'esx' then
    local xItem = player.hasItem(itemName)
    if not xItem then return false end
    return xItem.count >= amount
  end
end

function RemoveItem(player, itemName, amount)
  if Config.Framework == 'ProjectStarboy' then
    return player.removeInventoryItem({
      itemName = itemName,
      amount = amount
    })
  elseif Config.Framework == 'qbx' then
    return player.Functions.RemoveItem(itemName, amount)
  elseif Config.Framework == 'esx' then
    return player.removeInventoryItem(itemName, amount)
  end
end

function AddMoney(player, type, amount)
  if Config.Framework == 'ProjectStarboy' then
    return player.addAccountMoney(type, amount)
  elseif Config.Framework == 'qbx' then
    return player.Functions.AddMoney(type, amount, 'vx_gps')
  elseif Config.Framework == 'esx' then
    return player.addMoney(amount)
  end
end

function HasMoney(player, type, amount)
  if Config.Framework == 'ProjectStarboy' then
    return player.getAccountMoney(type) >= amount
  elseif Config.Framework == 'qbx' then
    local money = player.PlayerData.money or {}
    return (money[type] or 0) >= amount
  elseif Config.Framework == 'esx' then
    return player.getAccountMoney(type).money >= amount
  end
end

function RemoveMoney(player, type, amount)
  if Config.Framework == 'ProjectStarboy' then
    return player.removeAccountMoney(type, amount)
  elseif Config.Framework == 'qbx' then
    return player.Functions.RemoveMoney(type, amount, 'vx_gps')
  elseif Config.Framework == 'esx' then
    return player.addMoney(amount)
  end
end

function GetPlayerFromId(playerSrc)
  if Config.Framework == 'ProjectStarboy' then
    return Framework.GetPlayerFromSource(playerSrc)
  elseif Config.Framework == 'qbx' then
    return exports.qbx_core:GetPlayer(playerSrc)
  elseif Config.Framework == 'esx' then
    return Framework.GetPlayerFromId(playerSrc)
  end
end

function GetFrameworkPlayerJob(player)
  if not player then return nil end
  if Config.Framework == 'qbx' then
    return player.PlayerData and player.PlayerData.job
  end
  return player.job
end

function IsFrameworkPlayerOnDuty(player)
  local job = GetFrameworkPlayerJob(player)
  if Config.Framework == 'qbx' then
    -- print(player.PlayerData.name, job.onduty, type(job.onduty))
    return job ~= nil and job.onduty
  end
  return true
end

function GetFrameworkPlayerName(player)
  if not player then return 'Unknown' end
  if Config.Framework == 'qbx' then
    local playerData = player.PlayerData or {}
    local charinfo = playerData.charinfo or {}
    local fullName = ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or ''):gsub('^%s*(.-)%s*$', '%1')
    return fullName ~= '' and fullName or playerData.name or 'Unknown'
  end
  return player.name or 'Unknown'
end

function ShowNotification(playerSrc, message, type)
  if Config.Framework == "ProjectStarboy" then
    return TriggerClientEvent("Player:ShowNotification", playerSrc, {
      message = message,
      type = type
    })
  elseif Config.Framework == "qbx" then
    return exports.qbx_core:Notify(playerSrc, message, type)
  end
end

function AddExp(playerSrc, amount)
  if Config.Framework == "ProjectStarboy" then
    return exports.ProjectStarboy:addExp(playerSrc, amount)
  end
end

function AddSkillExp(playerSrc, skill, amount)
  if Config.Framework == "ProjectStarboy" then
    return exports.ProjectStarboy:addSkillExp(playerSrc, skill, amount)
  end
end
