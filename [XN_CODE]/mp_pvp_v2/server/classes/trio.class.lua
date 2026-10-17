Trio = class()

function Trio:Init()
  print("Trio class initialized")
  self.teams = {}
  self.bucket = {}
  self.playingMatches = {}
  self:SearchThread()
end

function Trio:SearchThread()
  CreateThread(function()
    while true do
      self:ProcessTrioMatchmaking()
      Wait(5000)
    end
  end)
end

function Trio:JoinQueue(key, teamData)
  if not teamData then return false end
  local copyTeamData = ShallowCopy(teamData)
  if not self.teams[key] then
    copyTeamData.members = self:FormatMembers(copyTeamData.members)
    self.teams[key] = copyTeamData
    return true
  end
  return false
end

function Trio:LeaveQueue(key)
  if not self.teams[key] then return false end
  self.teams[key] = nil
  return true
end

function Trio:ProcessTrioMatchmaking()
  local trioQueue = {}
  for k, v in pairs(self.teams) do
    if v.members then
      table.insert(trioQueue, {
        teamId = k,
        members = v.members
      })
    end
  end

  if #trioQueue > 0 then
    print(string.format("Trio Queue: %d đội đang tìm trận", #trioQueue))
  end

  local matched = {}
  for i = 1, #trioQueue do
    if not matched[i] then
      local team1 = trioQueue[i]
      local bestMatch = nil
      local bestMatchIndex = nil
      for j = i + 1, #trioQueue do
        if not matched[j] then
          bestMatch = trioQueue[j]
          bestMatchIndex = j
        end
      end

      if bestMatch then
        matched[i] = true
        matched[bestMatchIndex] = true

        print(string.format("Ghép cặp đội: %s vs %s", team1.teamId, bestMatch.teamId))

        local success = self:CreateTrioMatch(team1, bestMatch)
        if success then
          self:LeaveQueue(team1.teamId)
          self:LeaveQueue(bestMatch.teamId)
        end
      end
    end
  end
end

function Trio:CreateTrioMatch(team1, team2)
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
      mode = 'trio'
    }
    TriggerEvent('mp_pvp_v2:sv:addToMatchCache', v.id, cache)
    TriggerClientEvent('mp_pvp_v2:cl:matchFound', v.src, randomWeapon, cache.idx, matchId, 3, 'a')

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
      mode = 'trio'
    }
    TriggerEvent('mp_pvp_v2:sv:addToMatchCache', v.id, cache)
    TriggerClientEvent('mp_pvp_v2:cl:matchFound', v.src, randomWeapon, cache.idx, matchId, 3, 'b')
    v.die = false
  end
  self.playingMatches[matchId] = {
    bucket = bucket,
    a = team1.members,
    b = team2.members,
  }
  return true
end

function Trio:PlayerDied(matchId, idx, playerIdx)
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
    match.ended = true
    print(string.format("Trận %s kết thúc: %s thắng", matchId, winTeam))
    local winTeamData = match[winTeam]
    local loseTeamData = match[idx]
    for k, v in pairs(winTeamData) do
      local winRank = GetRank(v.trio or 0) or { name = 'dong' }
      local winPoint = Config.PointWhenWin[winRank.name] or 0
      local old = v.trio or 0
      v.trio = old + winPoint
      if Config.Debug then
        print(("[TRIO][WIN] id=%s old=%d +%d => %d rank=%s"):format(v.id or 'nil', old, winPoint, v.trio,
          winRank.name or 'nil'))
      end
      TriggerEvent("mp_pvp_v2:sv:addHistory", v.id, "win", "3vs3", winPoint)
      TriggerEvent('mp_pvp_v2:sv:updatePoint', v.id, v.trio, 'trio')
      TriggerClientEvent('mp_pvp_v2:cl:matchEnded', v.src, 'win')
      SetPlayerRoutingBucket(tostring(v.src), 0)
      TriggerEvent('mp_pvp_v2:sv:removeFromMatchCache', v.id)
      self:SavePoint(v.id, v.trio)
      self:TryGiveWinReward(v)
    end
    for k, v in pairs(loseTeamData) do
      local loseRank = GetRank(v.trio or 0) or { name = 'dong' }
      local losePoint = Config.PointWhenLose[loseRank.name] or 0
      local old = v.trio or 0
      v.trio = old - losePoint
      if Config.Debug then
        print(("[TRIO][LOSE] id=%s old=%d -%d => %d rank=%s"):format(v.id or 'nil', old, losePoint, v.trio,
          loseRank.name or 'nil'))
      end
      TriggerEvent("mp_pvp_v2:sv:addHistory", v.id, "lose", "3vs3", losePoint)
      TriggerEvent('mp_pvp_v2:sv:updatePoint', v.id, v.trio, 'trio')
      TriggerClientEvent('mp_pvp_v2:cl:matchEnded', v.src, 'lose')
      SetPlayerRoutingBucket(tostring(v.src), 0)
      TriggerEvent('mp_pvp_v2:sv:removeFromMatchCache', v.id)
      self:SavePoint(v.id, v.trio)
    end
    if match.bucket and self.bucket[match.bucket] then
      self.bucket[match.bucket] = nil
    end
    self.playingMatches[matchId] = nil
  end
end

function Trio:GenerateMatchId()
  return string.format("trio_%d_%d", os.time(), math.random(1, 9999))
end

function Trio:CreateRandomBucketOptimized()
  local maxAttempts = 100
  local attempts = 0

  while attempts < maxAttempts do
    local randomNumber = math.random(202, 303)

    if not self.bucket[randomNumber] then
      self.bucket[randomNumber] = true
      return randomNumber
    end

    attempts = attempts + 1
  end

  print("Cảnh báo: Không thể tạo bucket mới!")
  return nil
end

function Trio:FormatMembers(objects)
  local members = {}
  for _, obj in pairs(objects) do
    table.insert(members, obj)
  end
  return members
end

function Trio:CheckAllDead(team)
  for _, player in pairs(team) do
    if not player.die then
      return false
    end
  end
  return true
end

function Trio:SavePoint(id, point)
  local sql = "UPDATE mp_pvp SET `trio` = ? WHERE `id` = ?"
  MySQL.update.await(sql, { point, id })
end

function Trio:TryGiveWinReward(winner)
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
