function GetJob()
  if Config.Framework == 'ProjectStarboy' then
    return Framework.PlayerData.job
  end
  if Config.Framework == "qbx" then
    return QBX.PlayerData.job
  end
  if Config.Framework == "esx" then
    return Framework.GetPlayerData().job
  end
end

function GetFactionRank()
  if Config.Framework == 'ProjectStarboy' then
    return Framework.Faction.getPlayerRank()
  end
  if Config.Framework == "qbx" then
    local job = QBX.PlayerData.job
    return job and job.grade and job.grade.level
  end
  if Config.Framework == "esx" then
    return Framework.GetPlayerData().rank
  end
end

function HasFactionPrivilege(privilege)
  if Config.Framework == 'ProjectStarboy' then
    return Framework.Faction.can(privilege)
  end
  if Config.Framework == "qbx" then
    return false
  end
end

function GetPlayerData()
  if Config.Framework == 'ProjectStarboy' then
    return Framework.PlayerData.data
  end
  if Config.Framework == "qbx" then
    return QBX.PlayerData
  end
  if Config.Framework == "esx" then
    return Framework.GetPlayerData()
  end
end

function GetSkillExp(skill)
  if Config.Framework == 'ProjectStarboy' then
    return GetPlayerData().skills[skill]
  end
  if Config.Framework == "qbx" then
    local playerData = GetPlayerData()
    return playerData.metadata and playerData.metadata.skills and playerData.metadata.skills[skill]
  end
  if Config.Framework == "esx" then
    return Framework.GetPlayerData().skills[skill]
  end
end

function GetLevel()
  if Config.Framework == 'ProjectStarboy' then
    return Framework.PlayerData.getLevel()
  end
  if Config.Framework == "qbx" then
    local metadata = QBX.PlayerData.metadata or {}
    return metadata.level or 0
  end
  if Config.Framework == "esx" then
    return Framework.GetPlayerData().level
  end
end

function GetSkillLevel(skill)
  if Config.Framework == 'ProjectStarboy' then
    return Framework.PlayerData.getSkillLevel(skill)
  end
  if Config.Framework == "qbx" then
    local metadata = QBX.PlayerData.metadata or {}
    local skillLevels = metadata.skillLevels or metadata.skillsLevel or {}
    return skillLevels[skill] or 0
  end
  if Config.Framework == "esx" then
    return Framework.GetPlayerData().level
  end
end

function ShowNotification(msg, type, duration)
  if not duration then
    duration = 5000
  end
  if Config.Framework == "esx" then
    return Framework.ShowNotification(msg, type, duration)
  end
  if Config.Framework == "qbx" then
    return exports.qbx_core:Notify(msg, type, duration)
  end
  print("ShowNotification not implement", msg, type, duration)
end

