---@class MainImpl : Impl
local Impl = NewImpl("Main")

function Impl:Init()
  main:LogInfo("%s initialized", self:GetName())
  self.GlobalPositions = {}
  self.GlobalPlayers = {}
  self.GlobalCounts = {}
  self.GlobalJobs = {}
end

function Impl:OnReady()
  self:InitDefaultGps()
  self:EventHandlers()
end

function Impl:InitDefaultGps()
  local defaultGps = Config.DefautGps
  for jobName, gpsData in pairs(defaultGps) do
    self.GlobalPositions[jobName] = GlobalPosition(jobName, gpsData)
  end
end

function Impl:CreateGlobalPosition(name, gpsData)
  if not self.GlobalPositions[name] then
    self.GlobalPositions[name] = GlobalPosition(name, gpsData)
  end
end

function Impl:AddPlayerToGlobalPosition(name, playerId, xPlayer)
  self:LogInfo("AddPlayerToGlobalPosition %s %s", name, playerId)
  if not xPlayer then 
    xPlayer = GetPlayerFromId(playerId)
  end
  if not xPlayer then
    self:LogError("AddPlayerToGlobalPosition xPlayer is nil [%s]", playerId)
    return false, "xPlayer is nil"
  end
  if not IsFrameworkPlayerOnDuty(xPlayer) then
    return false, "Player is not on duty"
  end
  if not self.GlobalPositions[name] then
    self:CreateGlobalPosition(name, {
      sprite = 1,
      color = 3,
      scale = 1.0,
      display = 4,
      name = string.upper(name),
    })
  end
  if self:GetPlayerGlobal(playerId) then return self:LogError("Player %s is already in a global position", playerId) end
  self.GlobalPositions[name]:AddPlayer(playerId, GetFrameworkPlayerName(xPlayer), GetEntityCoords(GetPlayerPed(playerId), true))
  return true, nil
end

function Impl:RemovePlayerFromGlobalPosition(name, playerId)
  if not self.GlobalPositions[name] then
    self:LogError("RemovePlayerFromGlobalPosition GlobalPosition not found for job %s", name)
    return false, "GlobalPosition not found"
  end
  if self:GetPlayerGlobal(playerId) ~= name then return end
  self.GlobalPositions[name]:RemovePlayer(playerId)
  return true, nil
end


function Impl:OnPlayerLoaded(playerId, xPlayer)
  if not xPlayer then return end
  local job = GetFrameworkPlayerJob(xPlayer)
  self:OnJobUpdate(playerId, job)
end

function Impl:GetLastJob(playerId)
  return self.GlobalJobs[tonumber(playerId)]
end

function Impl:OnJobUpdate(playerId, job, removed)
  playerId = tonumber(playerId)
  if not playerId then return end
  local lastJob = self:GetLastJob(playerId)
  local jobName = not removed and job and job.name or nil
  local onDuty = jobName ~= nil and (Config.Framework ~= 'qbx' or job.onduty == true)

  if lastJob and lastJob.jobName == jobName and lastJob.onDuty == onDuty then return end

  if lastJob and lastJob.onDuty then
    local cName = ("%s_count"):format(lastJob.jobName)
    self.GlobalCounts[cName] = math.max(0, (self.GlobalCounts[cName] or 0) - 1)
    GlobalState[cName] = self.GlobalCounts[cName]
  end

  if not jobName then
    self.GlobalJobs[playerId] = nil
    return
  end

  local cName = ("%s_count"):format(jobName)
  if self.GlobalCounts[cName] == nil then
    self.GlobalCounts[cName] = 0
    GlobalState[cName] = 0
  end
  self.GlobalJobs[playerId] = { jobName = jobName, onDuty = onDuty }
  if onDuty then
    self.GlobalCounts[cName] = self.GlobalCounts[cName] + 1
    GlobalState[cName] = self.GlobalCounts[cName]
  end
end

function Impl:EventHandlers()
  -- AddStateBagChangeHandler(nil, nil, function(bag, key, value)
  --   print("StateBagChangeHandler", bag, key, value)
  -- end)
  exports("RemovePlayerFromGlobalPosition", function(...)
    return self:RemovePlayerFromGlobalPosition(...)
  end)
  exports("AddPlayerToGlobalPosition", function(...)
    return self:AddPlayerToGlobalPosition(...)
  end)
  RegisterNetEvent("vinx-gps:server:playerLoaded", function()
    local playerId = source
    local xPlayer = GetPlayerFromId(playerId)
    self:CheckGlobalPosition(playerId, xPlayer)
    self:OnPlayerLoaded(playerId, xPlayer)
  end)

  RegisterNetEvent("QBCore:Server:OnPlayerLoaded", function()
    if Config.Framework ~= 'qbx' then return end
    local playerId = source
    local xPlayer = GetPlayerFromId(playerId)
    self:CheckGlobalPosition(playerId, xPlayer)
    self:OnPlayerLoaded(playerId, xPlayer)
  end)

  AddEventHandler("QBCore:Server:OnJobUpdate", function(playerId, job)
    if Config.Framework ~= 'qbx' then return end
    local global = self:GetPlayerGlobal(playerId)
    if global and (global ~= job.name or job.onduty ~= true) then
      self.GlobalPositions[global]:RemovePlayer(playerId)
    end
    local xPlayer = GetPlayerFromId(playerId)
    self:CheckGlobalPosition(playerId, xPlayer)
    self:OnJobUpdate(playerId, job)
  end)

  AddEventHandler('QBCore:Server:SetDuty', function(playerId, value)
    local xPlayer = GetPlayerFromId(playerId)
    local job = GetFrameworkPlayerJob(xPlayer)
    local jobName = (job and job.name)
    if not jobName then
      return
    end
    job.onduty = value
    self:OnJobUpdate(playerId, job)
    local global = self:GetPlayerGlobal(playerId)
    if global and (global ~= jobName or value ~= true) then
      self.GlobalPositions[global]:RemovePlayer(playerId)
    end
    local xPlayer = GetPlayerFromId(playerId)
    self:CheckGlobalPosition(playerId, xPlayer)
  end)

  AddEventHandler("QBCore:Server:OnPlayerUnload", function(playerId)
    if Config.Framework ~= 'qbx' then return end

    self:OnJobUpdate(playerId, nil, true)

    local global = self:GetPlayerGlobal(playerId)
    if not global then return end
    self.GlobalPositions[global]:RemovePlayer(playerId)
  end)

  AddEventHandler("playerDropped", function(reason)
    local playerId = source
    self:OnJobUpdate(playerId, nil, true)
    local global = self:GetPlayerGlobal(playerId)
    if not global then return end
    self.GlobalPositions[global]:RemovePlayer(playerId)
  end)
end

function Impl:GetPlayerGlobal(playerId)
  for k, v in pairs(self.GlobalPositions) do
    if v:HasPlayer(playerId) then
      return k
    end
  end
  return nil
end

function Impl:CheckGlobalPosition(playerId, xPlayer)
  print("CheckGlobalPosition", playerId, xPlayer)
  if not xPlayer then
    return self:LogError("CheckGlobalPosition xPlayer is nil [%s]", playerId)
  end
  local job = GetFrameworkPlayerJob(xPlayer)
  local jobName = (job and job.name)
  if not jobName then
    return
  end
  if not IsFrameworkPlayerOnDuty(xPlayer) then
    local global = self:GetPlayerGlobal(playerId)
    if global then
      self.GlobalPositions[global]:RemovePlayer(playerId)
    end
    self:LogInfo('Player %s not onduty', xPlayer.PlayerData.name)
    return
  end
  -- self:LogInfo('JobName: %s %s', jobName, self.GlobalPositions[jobName]==nil)
  if self.GlobalPositions[jobName] then
    local posistion = GetEntityCoords(GetPlayerPed(playerId), false)
    self.GlobalPositions[jobName]:AddPlayer(playerId, GetFrameworkPlayerName(xPlayer), posistion)
  end
end

function Impl:SetPlayerGlobal(playerId, global)
  self.GlobalPlayers[tostring(playerId)] = global
end
