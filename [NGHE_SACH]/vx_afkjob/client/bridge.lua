function GetJob()
  if Config.Framework == 'ProjectStarboy' then
    return Framework.PlayerData.job
  end
  if Config.Framework == "qb" then
    return Framework.Functions.GetPlayerData().job
  end
  if Config.Framework == "esx" then
    return Framework.GetPlayerData().job
  end
end

function GetFactionRank()
  if Config.Framework == 'ProjectStarboy' then
    return Framework.Faction.getPlayerRank()
  end
  if Config.Framework == "esx" then
    return Framework.GetPlayerData().rank
  end
end

function HasFactionPrivilege(privilege)
  if Config.Framework == 'ProjectStarboy' then
    return Framework.Faction.can(privilege)
  end
end

function GetPlayerData()
  if Config.Framework == 'ProjectStarboy' then
    return Framework.PlayerData.data
  end
  if Config.Framework == "qb" then
    return Framework.Functions.GetPlayerData()
  end
  if Config.Framework == "esx" then
    return Framework.GetPlayerData()
  end
end

function GetSkillExp(skill)
  if Config.Framework == 'ProjectStarboy' then
    return GetPlayerData().skills[skill]
  end
  if Config.Framework == "esx" then
    return Framework.GetPlayerData().skills[skill]
  end
end

function GetLevel()
  if Config.Framework == 'ProjectStarboy' then
    return Framework.PlayerData.getLevel()
  end
  if Config.Framework == "esx" then
    return Framework.GetPlayerData().level
  end
end

function GetSkillLevel(skill)
  if Config.Framework == 'ProjectStarboy' then
    return Framework.PlayerData.getSkillLevel(skill)
  end
  if Config.Framework == "esx" then
    return Framework.GetPlayerData().level
  end
end

function ShowNotification(msg, type, duration)
  if not duration then
    duration = 5000
  end
  if Config.Framework == "qb" then
    return Framework.Functions.Notify(msg, type or "primary", duration)
  end
  if Config.Framework == "esx" then
    return Framework.ShowNotification(msg, type, duration)
  end
  print("ShowNotification not implement", msg, type, duration)
end

