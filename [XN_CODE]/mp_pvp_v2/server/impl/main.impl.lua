---@class SVLibImpl : Impl
local Impl = NewImpl("Main")


function Impl:Init()
  main:LogInfo("%s initialized", self:GetName())
  self.solo = Solo()
  self.dual = nil
  self.trio = nil
  self.history = History()
  main:LogSuccess("All classes loaded")
  self.teams = {}
  self.playerCache = {}
  self.playerData = {}
  self.matchCache = {}
  self.busy = {}
  self.started = true
  self:EnsureDatabase()
  self:CallbackHandler()
  self:EventHandler()
  self:OpenThread()
end

function Impl:EnsureDatabase()
  local ok, result = pcall(function()
    return MySQL.query.await("SHOW COLUMNS FROM mp_pvp LIKE 'solo_negative_locked_at'")
  end)
  if not ok then
    main:LogWarning("Không thể kiểm tra cột solo_negative_locked_at trong bảng mp_pvp")
    return
  end
  if not result or not result[1] then
    MySQL.query.await("ALTER TABLE mp_pvp ADD COLUMN `solo_negative_locked_at` INT NULL DEFAULT NULL")
  end
end

function Impl:OpenThread()
end

function Impl:GetHour()
  return tonumber(os.date("%H", os.time()))
end

function Impl:GetPvpOpenIntervals()
  local openConfig = Config.PvpOpenTime or {}

  if openConfig.intervals and #openConfig.intervals > 0 then
    return openConfig.intervals
  end

  -- Keep the previous single-interval config format working.
  return {
    {
      startHour = openConfig.startHour or 20,
      startMinute = openConfig.startMinute or 0,
      endHour = openConfig.endHour or 10,
      endMinute = openConfig.endMinute or 0,
    }
  }
end

function Impl:IsPvpOpenTime()
  if not Config.PvpOpenTime or Config.PvpOpenTime.enabled == false then
    return true
  end

  local now = os.date("*t", os.time())
  local currentMinute = (tonumber(now.hour) * 60) + tonumber(now.min)
  local intervals = self:GetPvpOpenIntervals()

  for _, interval in ipairs(intervals) do
    local startMinute = ((interval.startHour or 0) * 60) + (interval.startMinute or 0)
    local endMinute = ((interval.endHour or 0) * 60) + (interval.endMinute or 0)

    if startMinute == endMinute then
      return true
    end

    if startMinute < endMinute and currentMinute >= startMinute and currentMinute < endMinute then
      return true
    end

    if startMinute > endMinute and (currentMinute >= startMinute or currentMinute < endMinute) then
      return true
    end
  end

  return false
end

function Impl:FormatPvpTime(hour, minute)
  return string.format("%02d:%02d", hour or 0, minute or 0)
end

function Impl:GetPvpOpenState()
  local openConfig = Config.PvpOpenTime or {}
  local intervals = self:GetPvpOpenIntervals()
  local scheduleLabels = {}

  for _, interval in ipairs(intervals) do
    scheduleLabels[#scheduleLabels + 1] = string.format("%s - %s",
      self:FormatPvpTime(interval.startHour, interval.startMinute),
      self:FormatPvpTime(interval.endHour, interval.endMinute))
  end

  local scheduleLabel = table.concat(scheduleLabels, " | ")

  if openConfig.enabled == false then
    return {
      open = true,
      scheduleLabel = scheduleLabel,
      secondsRemaining = 0,
    }
  end

  local now = os.date("*t", os.time())
  local currentSecond = (tonumber(now.hour) * 3600) + (tonumber(now.min) * 60) + tonumber(now.sec)
  local isOpen = self:IsPvpOpenTime()
  local secondsRemaining = 86400

  for _, interval in ipairs(intervals) do
    local startSecond = ((interval.startHour or 0) * 3600) + ((interval.startMinute or 0) * 60)
    local endSecond = ((interval.endHour or 0) * 3600) + ((interval.endMinute or 0) * 60)

    if startSecond == endSecond then
      return {
        open = true,
        scheduleLabel = scheduleLabel,
        secondsRemaining = 0,
      }
    end

    if isOpen then
      local isCurrentInterval = (startSecond < endSecond and currentSecond >= startSecond and currentSecond < endSecond)
        or (startSecond > endSecond and (currentSecond >= startSecond or currentSecond < endSecond))

      if isCurrentInterval then
        local secondsUntilEnd = endSecond - currentSecond
        if secondsUntilEnd <= 0 then
          secondsUntilEnd = secondsUntilEnd + 86400
        end
        secondsRemaining = math.min(secondsRemaining, secondsUntilEnd)
      end
    else
      local secondsUntilStart = startSecond - currentSecond
      if secondsUntilStart <= 0 then
        secondsUntilStart = secondsUntilStart + 86400
      end
      secondsRemaining = math.min(secondsRemaining, secondsUntilStart)
    end
  end

  return {
    open = isOpen,
    scheduleLabel = scheduleLabel,
    secondsRemaining = secondsRemaining,
  }
end

function Impl:InPVP(id)
  for k, v in pairs(self.matchCache) do
    if self.matchCache[tostring(id)] then
      return true
    end
  end
  return false
end

function Impl:CallbackHandler()
  RegisterCommand('togglepvp', function(source, args, rawCommand)
    self.started = not self.started
  end, true)
  lib.callback.register('mp_pvp_v2:sv:getPlayerData', function(source)
    local xPlayer = GetPlayerFromId(source)
    if not xPlayer then return end
    Player(source).state:set("userId", xPlayer.PlayerData.userId, true)
    local sql =
    "INSERT IGNORE INTO mp_pvp SET `id` = ?, `solo` = ?, `dual` = ?, `trio` = ?, name = ?"
    MySQL.query.await(sql, { xPlayer.PlayerData.userId, 0, 0, 0, GetPlayerName(source) })
    MySQL.update.await("UPDATE mp_pvp SET `name` = ? WHERE `id` = ?", { GetPlayerName(source), xPlayer.PlayerData.userId })
    self:ResetNegativePointIfExpired(xPlayer.PlayerData.userId, "solo")
    local data = MySQL.query.await("SELECT * FROM mp_pvp WHERE id = ? ORDER BY solo DESC LIMIT 1", { xPlayer.PlayerData.userId })
    if data and data[1] then
      local returnData = {
        solo = data[1].solo,
        dual = data[1].dual,
        trio = data[1].trio,
        solo_negative_locked_at = data[1].solo_negative_locked_at,
      }
      self.playerData[tostring(xPlayer.PlayerData.userId)] = returnData
      self.playerCache[tostring(source)] = xPlayer.PlayerData.userId
      if not self.teams[tostring(xPlayer.PlayerData.userId)] then
        local teamData = {}
        teamData.members = {}
        teamData.members[tostring(xPlayer.PlayerData.userId)] =
        {
          id = xPlayer.PlayerData.userId,
          name = GetPlayerName(source),
          solo = data[1].solo,
          dual = data[1].dual,
          trio = data[1].trio,
          leader = true,
          src = tonumber(source)
        }
        teamData.mode = 'solo'
        teamData.leader = tonumber(xPlayer.PlayerData.userId)
        teamData.active = true
        teamData.searching = false
        self.teams[tostring(xPlayer.PlayerData.userId)] = teamData
      else
        self.teams[tostring(xPlayer.PlayerData.userId)].members[tostring(xPlayer.PlayerData.userId)].src = source
        self.teams[tostring(xPlayer.PlayerData.userId)].active = true
      end
      return returnData, self.teams[tostring(xPlayer.PlayerData.userId)], self.history:GetHistory(xPlayer.PlayerData.userId)
    end
    return nil
  end)

  lib.callback.register("mp_pvp_v2:sv:getLeaderBoard", function()
    local soloData = MySQL.query.await("SELECT `id`, MAX(`name`) AS `name`, MAX(`solo`) AS `solo` FROM mp_pvp GROUP BY `id` ORDER BY `solo` DESC LIMIT 30")
    return soloData, {}, {}
  end)

  lib.callback.register("mp_pvp_v2:sv:getPvpOpenState", function()
    return self:GetPvpOpenState()
  end)
end

function Impl:EventHandler()
  RegisterNetEvent("mp_pvp_v2:sv:invitePlayer", function(target)
    local src = source
    TriggerClientEvent("mp_pvp_v2:cl:notify", src, "error", "PVP hiện chỉ hỗ trợ chế độ 1vs1")
    return
  end)

  RegisterNetEvent("mp_pvp_v2:sv:findMatch", function()
    local src = source
    if not self.started or not self:IsPvpOpenTime() then
      TriggerClientEvent("mp_pvp_v2:cl:notify", src, "error", "Minigame chưa bắt đầu")
      return false
    end
    local xPlayer = GetPlayerFromId(src)
    if not xPlayer then return end
    if self:IsOnDuty(xPlayer) then
      TriggerClientEvent("mp_pvp_v2:cl:notify", src, "error", "Bạn đang on duty ban ngành, không thể tham gia PVP")
      return false
    end

    local isLocked, remaining = self:IsNegativePointLocked(xPlayer.PlayerData.userId, "solo")
    if isLocked then
      local days = math.ceil(remaining / 86400)
      TriggerClientEvent("mp_pvp_v2:cl:notify", src, "error",
        string.format("Điểm PVP âm đã xuống %d. Còn %d ngày mới reset hoặc dùng COIN để khôi phục.",
          math.abs(Config.NegativePoint.lockPoint), days))
      return false
    end

    local teamData = self.teams[tostring(xPlayer.PlayerData.userId)]
    if teamData then
      if teamData.searching then
        return TriggerClientEvent("mp_pvp_v2:cl:notify", src, "error", "Đội của bạn đang tìm trận!!!")
      end
      if self.solo:IsPlayerPending(xPlayer.PlayerData.userId) then
        return TriggerClientEvent("mp_pvp_v2:cl:notify", src, "error", "Bạn đang trong bước sẵn sàng trận đấu")
      end
      if self:GetTeamCount(teamData.members) ~= 1 or teamData.mode ~= 'solo' then
        return TriggerClientEvent("mp_pvp_v2:cl:notify", src, "error", "PVP hiện chỉ hỗ trợ chế độ 1vs1")
      end
      local success = self.solo:JoinQueue(teamData.leader, teamData)
      if success then
        self:StartSearching(teamData)
      else
        return TriggerClientEvent("mp_pvp_v2:cl:notify", src, "error", "Lỗi không thể tìm trận!!!")
      end
    end
  end)

  RegisterNetEvent("mp_pvp_v2:sv:readyResponse", function(matchId, accepted)
    local src = source
    local xPlayer = GetPlayerFromId(src)
    if not xPlayer or not matchId then return end
    self.solo:SetReady(matchId, xPlayer.PlayerData.userId, accepted == true)
  end)

  AddEventHandler('mp_pvp_v2:sv:queueMatched', function(teamId)
    local team = self.teams[tostring(teamId)]
    if team then
      self:StopSearching(team)
    end
  end)

  AddEventHandler('mp_pvp_v2:sv:updatePoint', function(id, point, mode)
    if self.playerData[tostring(id)] then
      self.playerData[tostring(id)][mode] = point
      local inTeam = self.busy[tostring(id)]
      if inTeam then
        self.teams[tostring(inTeam)].members[tostring(id)][mode] = point
        self:StopSearching(self.teams[tostring(inTeam)])
      else
        self.teams[tostring(id)].members[tostring(id)][mode] = point
        self:StopSearching(self.teams[tostring(id)])
      end
    end
  end)

  AddEventHandler('mp_pvp_v2:sv:addToMatchCache', function(id, data)
    if not self.matchCache[tonumber(id)] then
      self.matchCache[tonumber(id)] = data
    else
      self.matchCache[tonumber(id)] = data
    end
  end)

  AddEventHandler('mp_pvp_v2:sv:removeFromMatchCache', function(id)
    if self.matchCache[tonumber(id)] then
      self.matchCache[tonumber(id)] = nil
    end
  end)

  RegisterNetEvent('mp_pvp_v2:sv:kickPlayer', function(target)
    local src = source
    local xPlayer = GetPlayerFromId(src)
    if not xPlayer then return end
    local targetPlayer = CORE.GetPlayerFromId(target)
    if not targetPlayer then return end
    if self.teams[tostring(xPlayer.PlayerData.userId)] then
      if self.teams[tostring(xPlayer.PlayerData.userId)].members[tostring(targetPlayer.id)] then
        self.teams[tostring(xPlayer.PlayerData.userId)].members[tostring(targetPlayer.id)] = nil
        self:StopSearching(self.teams[tostring(xPlayer.PlayerData.userId)])
        if self.teams[tostring(xPlayer.PlayerData.userId)].mode == 'trio' then
          self.teams[tostring(xPlayer.PlayerData.userId)].mode = 'dual'
        elseif self.teams[tostring(xPlayer.PlayerData.userId)].mode == 'dual' then
          self.teams[tostring(xPlayer.PlayerData.userId)].mode = 'solo'
        end
        --TODO: stop searching from classes
        self:StopSearchingAllClass(tonumber(xPlayer.PlayerData.userId))
        TriggerClientEvent("mp_pvp_v2:cl:notify", src, "success",
          string.format("%s đã bị kick khỏi team của bạn", targetPlayer.name))
        if self.teams[tostring(targetPlayer.id)] and not self.teams[tostring(targetPlayer.id)].active then
          self.busy[tostring(targetPlayer.id)] = nil
          self.teams[tostring(targetPlayer.id)].active = true
          self:StopSearching(self.teams[tostring(targetPlayer.id)])
          TriggerClientEvent("mp_pvp_v2:cl:notify", tonumber(targetPlayer.source), "success",
            'Bạn đã bị kick khỏi team, bây giờ bạn là chủ đội')
        end
      end
    end
  end)

  RegisterNetEvent("mp_pvp_v2:sv:leaveTeam", function()
    local src = source
    local xPlayer = GetPlayerFromId(src)
    if not xPlayer then return end
    local inTeam = self.busy[tostring(xPlayer.PlayerData.userId)]
    if inTeam then
      if self.teams[tostring(inTeam)] and self.teams[tostring(inTeam)].members[tostring(xPlayer.PlayerData.userId)] then
        self.teams[tostring(inTeam)].members[tostring(xPlayer.PlayerData.userId)] = nil
        self:StopSearching(self.teams[tostring(inTeam)], "Đội của bạn đã ngừng tìm trận do có thành viên rời khỏi team")
        --TODO: stop searching from classes
        self:StopSearchingAllClass(tonumber(inTeam))
        if self.teams[tostring(inTeam)].mode == 'trio' then
          self.teams[tostring(inTeam)].mode = 'dual'
        elseif self.teams[tostring(inTeam)].mode == 'dual' then
          self.teams[tostring(inTeam)].mode = 'solo'
        end
        self.busy[tostring(xPlayer.PlayerData.userId)] = nil
        if self.teams[tostring(xPlayer.PlayerData.userId)] and not self.teams[tostring(xPlayer.PlayerData.userId)].active then
          self.teams[tostring(xPlayer.PlayerData.userId)].active = true
          self.teams[tostring(xPlayer.PlayerData.userId)].mode = 'solo'

          self:StopSearching(self.teams[tostring(xPlayer.PlayerData.userId)], "Ngừng tìm trận")
          TriggerClientEvent("mp_pvp_v2:cl:notify", tonumber(xPlayer.source), "success",
            'Bạn đã rời khỏi team, bây giờ bạn là chủ đội')
        end
      end
    end
  end)

  RegisterNetEvent('mp_pvp_v2:sv:playerDied', function(matchId, mode, idx, playerIdx)
    if mode == 1 then
      self.solo:PlayerDied(matchId, idx, playerIdx)
    end
  end)


  RegisterNetEvent("mp_pvp_v2:sv:resetBucket", function()
    local src = source
    SetPlayerRoutingBucket(tostring(src), 0)
  end)

  RegisterNetEvent("mp_pvp_v2:sv:restoreNegativePoint", function()
    local src = source
    local xPlayer = GetPlayerFromId(src)
    if not xPlayer then return end

    local playerId = xPlayer.PlayerData.userId
    local currentPoint = self:GetPlayerPoint(playerId, "solo")
    if currentPoint > Config.NegativePoint.lockPoint then
      TriggerClientEvent("mp_pvp_v2:cl:notify", src, "info", "Điểm PVP của bạn chưa bị khóa âm")
      return
    end

    local item = Config.NegativePoint.restoreItem
    local amount = Config.NegativePoint.restoreAmount or 1
    if not HasItem(xPlayer, item, amount) then
      TriggerClientEvent("mp_pvp_v2:cl:notify", src, "error",
        string.format("Bạn không đủ %s COIN để khôi phục điểm PVP", amount))
      return
    end

    RemoveItem(xPlayer, item, amount)
    self:SetPlayerPoint(playerId, "solo", Config.NegativePoint.restoreTo, nil)
    TriggerClientEvent("mp_pvp_v2:cl:notify", src, "success", "Đã khôi phục điểm PVP bằng COIN")
  end)

  RegisterNetEvent('mp_pvp_v2:sv:cancelSearch', function()
    local src = source
    local xPlayer = GetPlayerFromId(src)
    if not xPlayer then return end
    local teamId = self.busy[tostring(xPlayer.PlayerData.userId)] or xPlayer.PlayerData.userId
    local teamData = self.teams[tostring(teamId)]
    if teamData then
      if teamData.searching then
        self:StopSearching(teamData, "Ngừng tìm trận")
        self:StopSearchingAllClass(tonumber(teamId))
      end
    end
  end)

  AddEventHandler('playerDropped', function(reason, resourceName, clientDropReason)
    local src = source
    if self.playerCache[tostring(src)] then
      local idLeave = self.playerCache[tostring(src)]
      local inTeam = self.busy[tostring(idLeave)]
      if inTeam then
        if self.teams[tostring(inTeam)] then
          self.teams[tostring(inTeam)].members[tostring(idLeave)] = nil
          self:StopSearching(self.teams[tostring(inTeam)], "Đội của bạn đã ngừng tìm trận do có thành viên rời khỏi team")
          --TODO: stop searching from classes
          self:StopSearchingAllClass(tonumber(inTeam))
          TriggerClientEvent("mp_pvp_v2:cl:notify", tonumber(self.teams[tostring(inTeam)].members[tostring(inTeam)].src),
            "success",
            string.format("%s đã rời khỏi team của bạn", self.playerData[tostring(idLeave)].name))
          self.busy[tostring(idLeave)] = nil
          if self.teams[tostring(inTeam)].mode == 'trio' then
            self.teams[tostring(inTeam)].mode = 'dual'
          elseif self.teams[tostring(inTeam)].mode == 'dual' then
            self.teams[tostring(inTeam)].mode = 'solo'
          end
        end
      else
        self.teams[tostring(idLeave)].active = false
        self.teams[tostring(idLeave)].mode = 'solo'
        self:StopSearchingAllClass(tonumber(idLeave))
        self:KickAllMembers(idLeave)
        --TODO : stop searching from classes
      end

      if self.matchCache[tonumber(idLeave)] then
        local matchData = self.matchCache[tonumber(idLeave)]
        print(json.encode(matchData, { indent = true }))
        if matchData and matchData.matchId and matchData.team and matchData.idx then
          if matchData.mode == 'solo' then
            self.solo:PlayerDied(matchData.matchId, matchData.team, matchData.idx)
          end
        end
        self.matchCache[tonumber(idLeave)] = nil
      else
        self.solo:CancelReadyCheckByPlayer(idLeave, "Một người chơi đã thoát khỏi ready check")
      end
      self.playerCache[tostring(src)] = nil
    end
  end)
end

function Impl:GetPlayerPoint(playerId, mode)
  local data = MySQL.query.await(("SELECT `%s` FROM mp_pvp WHERE id = ? ORDER BY `%s` DESC LIMIT 1"):format(mode, mode),
    { playerId })
  if data and data[1] then
    return tonumber(data[1][mode]) or 0
  end
  return 0
end

function Impl:SetPlayerPoint(playerId, mode, point, lockedAt)
  if mode ~= "solo" then return end
  MySQL.update.await("UPDATE mp_pvp SET `solo` = ?, `solo_negative_locked_at` = ? WHERE `id` = ?",
    { point, lockedAt, playerId })

  if self.playerData[tostring(playerId)] then
    self.playerData[tostring(playerId)].solo = point
    self.playerData[tostring(playerId)].solo_negative_locked_at = lockedAt
  end

  local inTeam = self.busy[tostring(playerId)]
  local teamId = inTeam or playerId
  if self.teams[tostring(teamId)] and self.teams[tostring(teamId)].members[tostring(playerId)] then
    self.teams[tostring(teamId)].members[tostring(playerId)].solo = point
    self:BroadcastTeam(self.teams[tostring(teamId)])
  end
end

function Impl:ResetNegativePointIfExpired(playerId, mode)
  if mode ~= "solo" then return false end
  local data = MySQL.query.await(
    "SELECT `solo`, `solo_negative_locked_at` FROM mp_pvp WHERE id = ? ORDER BY `solo` DESC LIMIT 1",
    { playerId })
  if not data or not data[1] then return false end

  local point = tonumber(data[1].solo) or 0
  local lockedAt = tonumber(data[1].solo_negative_locked_at)
  if point > Config.NegativePoint.lockPoint then
    if lockedAt then
      self:SetPlayerPoint(playerId, "solo", point, nil)
    end
    return false
  end

  if not lockedAt then
    lockedAt = os.time()
    self:SetPlayerPoint(playerId, "solo", point, lockedAt)
    return false
  end

  if os.time() - lockedAt >= Config.NegativePoint.resetAfter then
    self:SetPlayerPoint(playerId, "solo", Config.NegativePoint.restoreTo, nil)
    return true
  end

  return false
end

function Impl:IsNegativePointLocked(playerId, mode)
  self:ResetNegativePointIfExpired(playerId, mode)
  local data = MySQL.query.await(
    "SELECT `solo`, `solo_negative_locked_at` FROM mp_pvp WHERE id = ? ORDER BY `solo` DESC LIMIT 1",
    { playerId })
  if not data or not data[1] then return false, 0 end

  local point = tonumber(data[1].solo) or 0
  local lockedAt = tonumber(data[1].solo_negative_locked_at)
  if point > Config.NegativePoint.lockPoint then
    return false, 0
  end

  if not lockedAt then
    lockedAt = os.time()
    self:SetPlayerPoint(playerId, "solo", point, lockedAt)
  end

  local resetAt = lockedAt + Config.NegativePoint.resetAfter
  return true, math.max(resetAt - os.time(), 0)
end

function Impl:IsOnDuty(xPlayer)
  if not xPlayer or not xPlayer.PlayerData then return false end
  local job = xPlayer.PlayerData.job
  if type(job) == "table" and job.name ~= 'police' and job.name ~= 'ambulance' then 
    return false
  end
  if type(job) == "table" and (job.onduty == true or job.onDuty == true) then
    return true
  end
  local playerSrc = xPlayer.PlayerData.source or xPlayer.source
  if not playerSrc then return false end
  local state = Player(playerSrc).state
  return state and (state.onduty == true or state.onDuty == true or state.duty == true)
end

function Impl:KickAllMembers(teamId)
  local team = self.teams[tostring(teamId)]
  if team then
    for k, v in pairs(team.members) do
      if tostring(teamId) ~= k then
        self.busy[tostring(k)] = nil
        if self.teams[tostring(k)] and not self.teams[tostring(k)].active then
          self.teams[tostring(k)].active = true
          self:StopSearching(self.teams[tostring(k)], "Ngừng tìm trận")
          TriggerClientEvent("mp_pvp_v2:cl:notify", tonumber(v.src), "success",
            'Bạn đã bị kick khỏi team, bây giờ bạn là chủ đội')
        end
        team.members[k] = nil
      end
    end
  end
end

function Impl:GetTeamCount(arrays)
  local count = 0
  for k, v in pairs(arrays) do
    count = count + 1
  end
  return count
end

function Impl:BroadcastTeam(team)
  for _, m in pairs(team.members) do
    TriggerClientEvent("mp_pvp_v2:cl:updateTeam", m.src, team)
  end
end

function Impl:StopSearching(team, reason)
  if team.searching then
    team.searching = false
    for _, m in pairs(team.members) do
      TriggerClientEvent("mp_pvp_v2:cl:searching", m.src, false)
      if reason then
        TriggerClientEvent("mp_pvp_v2:cl:notify", m.src, "error", reason)
      end
    end
  end
  self:BroadcastTeam(team)
end

function Impl:StartSearching(team)
  if not team.searching then
    team.searching = true
    for _, m in pairs(team.members) do
      TriggerClientEvent("mp_pvp_v2:cl:searching", m.src, true)
    end
  end
end

function Impl:StopSearchingAllClass(id)
  if self.solo then
    self.solo:LeaveQueue(id)
  end
  if self.dual then
    self.dual:LeaveQueue(id)
  end
  if self.trio then
    self.trio:LeaveQueue(id)
  end
end
