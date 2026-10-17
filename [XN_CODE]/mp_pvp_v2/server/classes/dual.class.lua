Dual = class()

function Dual:Init()
  print("Dual class initialized")
  self.teams = {}
  self.bucket = {}
  self.playingMatches = {}
  self:SearchThread()
end

function Dual:SearchThread()
  CreateThread(function()
    while true do
      self:ProcessDualMatchmaking()
      Wait(5000)
    end
  end)
end

function Dual:JoinQueue(key, teamData)
  if not teamData then return false end
  local copyTeamData = ShallowCopy(teamData)
  if not self.teams[key] then
    copyTeamData.members = self:FormatMembers(copyTeamData.members)
    self.teams[key] = copyTeamData
    return true
  end
  return false
end

function Dual:LeaveQueue(key)
  if not self.teams[key] then return false end
  self.teams[key] = nil
  return true
end

function Dual:ProcessDualMatchmaking()
  local dualQueue = {}
  for k, v in pairs(self.teams) do
    if v.members then
      table.insert(dualQueue, {
        teamId = k,
        members = v.members
      })
    end
  end

  if #dualQueue > 0 then
    print(string.format("Dual Queue: %d đội đang tìm trận", #dualQueue))
  end

  local matched = {}
  for i = 1, #dualQueue do
    if not matched[i] then
      local team1 = dualQueue[i]
      local bestMatch = nil
      local bestMatchIndex = nil
      for j = i + 1, #dualQueue do
        if not matched[j] then
          bestMatch = dualQueue[j]
          bestMatchIndex = j
        end
      end

      if bestMatch then
        matched[i] = true
        matched[bestMatchIndex] = true

        print(string.format("Ghép cặp đội: %s vs %s", team1.teamId, bestMatch.teamId))

        local success = self:CreateDualMatch(team1, bestMatch)
        if success then
          self:LeaveQueue(team1.teamId)
          self:LeaveQueue(bestMatch.teamId)
        end
      end
    end
  end
end

function Dual:CreateDualMatch(team1, team2)
  local matchId = self:GenerateMatchId()
  local bucket = self:CreateRandomBucketOptimized()
  if not bucket then
    return false
  end
  if self.playingMatches[matchId] then
    return false
  end
  local randomWeapon = math.random(1, 4)
  for k, v in pairs(team1.members) do
    if bucket then
      SetPlayerRoutingBucket(tostring(v.src), bucket)
    end
    local cache = {
      team = 'a',
      matchId = matchId,
      idx = k,
      mode = 'dual'
    }
    TriggerEvent('mp_pvp_v2:sv:addToMatchCache', v.id, cache)
    TriggerClientEvent('mp_pvp_v2:cl:matchFound', v.src, randomWeapon, cache.idx, matchId, 2, 'a')

    v.die = false
  end
  for k, v in pairs(team2.members) do
    if bucket then
      SetPlayerRoutingBucket(tostring(v.src), bucket)
    end
    local cache = {
      team = 'b',
      matchId = matchId,
      idx = k,
      mode = 'dual'
    }
    TriggerEvent('mp_pvp_v2:sv:addToMatchCache', v.id, cache)
    TriggerClientEvent('mp_pvp_v2:cl:matchFound', v.src, randomWeapon, cache.idx, matchId, 2, 'b')
    v.die = false
  end
  self.playingMatches[matchId] = {
    bucket = bucket,
    a = team1.members,
    b = team2.members,
  }
  return true
end

function Dual:PlayerDied(matchId, idx, playerIdx)
  local match = self.playingMatches[matchId]
  if not match or match.ended then return end
  match[idx][playerIdx].die = true
  local allDead = self:CheckAllDead(match[idx])
  local winTeam = nil
  if allDead and idx == 'a' then
    winTeam = 'b'
  elseif allDead and idx == 'b' then
    winTeam = 'a'
  end

  if winTeam then
    match.ended = true -- tránh trừ điểm nhiều lần nếu hàm bị gọi lại
    print(string.format("Trận %s kết thúc: %s thắng", matchId, winTeam))
    local winTeamData = match[winTeam]
    local loseTeamData = match[idx]
    for k, v in pairs(winTeamData) do
      local winRank = GetRank(v.dual or 0) or { name = 'dong' }
      local winPoint = Config.PointWhenWin[winRank.name] or 0
      local old = v.dual or 0
      v.dual = old + winPoint
      if Config.Debug then
        print(("[DUAL][WIN] id=%s old=%d +%d => %d rank=%s"):format(v.id or 'nil', old, winPoint, v.dual,
          winRank.name or 'nil'))
      end
      TriggerEvent("mp_pvp_v2:sv:addHistory", v.id, "win", "2vs2", winPoint)
      TriggerEvent('mp_pvp_v2:sv:updatePoint', v.id, v.dual, 'dual')
      TriggerClientEvent('mp_pvp_v2:cl:matchEnded', v.src, 'win')
      SetPlayerRoutingBucket(tostring(v.src), 0)
      TriggerEvent('mp_pvp_v2:sv:removeFromMatchCache', v.id)
      self:SavePoint(v.id, v.dual)
      self:TryGiveWinReward(v)
    end
    for k, v in pairs(loseTeamData) do
      local loseRank = GetRank(v.dual or 0) or { name = 'dong' }
      local losePoint = Config.PointWhenLose[loseRank.name] or 0
      local old = v.dual or 0
      v.dual = old - losePoint
      if Config.Debug then
        print(("[DUAL][LOSE] id=%s old=%d -%d => %d rank=%s"):format(v.id or 'nil', old, losePoint, v.dual,
          loseRank.name or 'nil'))
      end
      TriggerEvent("mp_pvp_v2:sv:addHistory", v.id, "lose", "2vs2", losePoint)
      TriggerEvent('mp_pvp_v2:sv:updatePoint', v.id, v.dual, 'dual')
      TriggerClientEvent('mp_pvp_v2:cl:matchEnded', v.src, 'lose')
      SetPlayerRoutingBucket(tostring(v.src), 0)
      TriggerEvent('mp_pvp_v2:sv:removeFromMatchCache', v.id)
      self:SavePoint(v.id, v.dual)
    end
    if match.bucket and self.bucket[match.bucket] then
      self.bucket[match.bucket] = nil
    end
    self.playingMatches[matchId] = nil
  end
end

function Dual:GenerateMatchId()
  return string.format("dual_%d_%d", os.time(), math.random(1, 9999))
end

function Dual:CreateRandomBucketOptimized()
  local maxAttempts = 100
  local attempts = 0

  while attempts < maxAttempts do
    local randomNumber = math.random(101, 201)

    if not self.bucket[randomNumber] then
      self.bucket[randomNumber] = true
      return randomNumber
    end

    attempts = attempts + 1
  end

  print("Cảnh báo: Không thể tạo bucket mới!")
  return nil
end

function Dual:FormatMembers(objects)
  local members = {}
  for _, obj in pairs(objects) do
    table.insert(members, obj)
  end
  return members
end

function Dual:CheckAllDead(team)
  for _, player in pairs(team) do
    if not player.die then
      return false
    end
  end
  return true
end

function Dual:SavePoint(id, point)
  local sql = "UPDATE mp_pvp SET `dual` = ? WHERE `id` = ?"
  MySQL.update.await(sql, { point, id })
end

function Dual:TryGiveWinReward(winner)
  if not Config.WinReward or not Config.WinReward.enabled then return end
  if not ShouldGiveWinReward(winner.id or winner.src) then return end

  local xPlayer = GetPlayerFromId(winner.src)
  if not xPlayer then return end

  local amount = Config.WinReward.amount or 1
  if AddItem(xPlayer, Config.WinReward.item, amount) then
    TriggerClientEvent("mp_pvp_v2:cl:notify", winner.src, "success",
      string.format("Bạn nhận được %sx thẻ PVP", amount))
  end
end
