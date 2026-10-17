Solo = class()

function Solo:Init()
  print("Solo class initialized")
  self.teams = {}
  self.bucket = {}
  self.playingMatches = {}
  self.pendingMatches = {}
  self.readyTimeout = 15
  self:SearchThread()
end

function Solo:JoinQueue(key, teamData)
  if not teamData then return false end
  local copyTeamData = ShallowCopy(teamData)
  if not self.teams[key] then
    copyTeamData.members = self:FormatMembers(copyTeamData.members)
    self.teams[key] = copyTeamData
    return true
  end
  return false
end

function Solo:LeaveQueue(key)
  if not self.teams[key] then return false end
  self.teams[key] = nil
  return true
end

function Solo:SearchThread()
  CreateThread(function()
    while true do
      self:ProcessSoloMatchmaking()
      Wait(5000)
    end
  end)
end

function Solo:ProcessSoloMatchmaking()
  local soloQueue = {}
  for k, v in pairs(self.teams) do
    if v.members then
      table.insert(soloQueue, {
        teamId = k,
        members = v.members
      })
    end
  end

  if #soloQueue > 0 then
    print(string.format("Solo Queue: %d người đang tìm trận", #soloQueue))
  end

  table.sort(soloQueue, function(a, b)
    return (a.members[1].solo or 0) < (b.members[1].solo or 0)
  end)

  local matched = {}
  for i = 1, #soloQueue do
    if not matched[i] then
      local team1 = soloQueue[i]
      local bestMatch = nil
      local bestMatchIndex = nil
      local smallestDiff = math.huge

      for j = i + 1, #soloQueue do
        if not matched[j] then
          local team2 = soloQueue[j]
          local pointDiff = math.abs((team1.members[1].solo or 0) - (team2.members[1].solo or 0))

          if pointDiff <= 500 and pointDiff < smallestDiff then
            bestMatch = team2
            bestMatchIndex = j
            smallestDiff = pointDiff
          end
        end
      end


      if bestMatch then
        matched[i] = true
        matched[bestMatchIndex] = true

        print(string.format("Ghép cặp: %s (%d điểm) vs %s (%d điểm) - Chênh lệch: %d điểm",
          team1.members[1].name,
          team1.members[1].solo or 0,
          bestMatch.members[1].name,
          bestMatch.members[1].solo or 0,
          smallestDiff
        ))

        local success = self:CreateSoloMatch(team1, bestMatch)
        if success then
          self:RemoveFromSoloQueue(team1.teamId)
          self:RemoveFromSoloQueue(bestMatch.teamId)
        end
      end
    end
  end
end

function Solo:CreateSoloMatch(team1, team2)
  local matchId = self:GenerateMatchId()
  if self.playingMatches[matchId] then
    return false
  end

  if self.pendingMatches[matchId] then
    return false
  end

  local bucket = self:CreateRandomBucketOptimized()
  if not bucket then
    return false
  end

  local randomWeapon = math.random(1, 3)
  self.pendingMatches[matchId] = {
    bucket = bucket,
    a = team1.members[1],
    b = team2.members[1],
    weapon = randomWeapon,
    ready = {},
    expiresAt = os.time() + self.readyTimeout
  }

  TriggerEvent('mp_pvp_v2:sv:queueMatched', team1.teamId)
  TriggerEvent('mp_pvp_v2:sv:queueMatched', team2.teamId)

  TriggerClientEvent('mp_pvp_v2:cl:readyCheck', team1.members[1].src, {
    matchId = matchId,
    duration = self.readyTimeout,
    readyCount = 0,
    total = 2,
    opponentName = team2.members[1].name
  })
  TriggerClientEvent('mp_pvp_v2:cl:readyCheck', team2.members[1].src, {
    matchId = matchId,
    duration = self.readyTimeout,
    readyCount = 0,
    total = 2,
    opponentName = team1.members[1].name
  })

  CreateThread(function()
    Wait(self.readyTimeout * 1000)
    local pending = self.pendingMatches[matchId]
    if pending then
      self:CancelReadyCheck(matchId, "Một người chơi không sẵn sàng")
    end
  end)

  return true
end

function Solo:SetReady(matchId, playerId, accepted)
  local match = self.pendingMatches[matchId]
  if not match then return false end

  local playerKey = tostring(playerId)
  if tostring(match.a.id) ~= playerKey and tostring(match.b.id) ~= playerKey then
    return false
  end

  if not accepted then
    self:CancelReadyCheck(matchId, "Một người chơi đã từ chối trận đấu")
    return true
  end

  match.ready[playerKey] = true
  local readyCount = self:GetReadyCount(match)

  self:BroadcastReadyState(match, readyCount)

  if readyCount >= 2 then
    self:StartReadyMatch(matchId)
  end

  return true
end

function Solo:GetReadyCount(match)
  local count = 0
  if match.ready[tostring(match.a.id)] then count = count + 1 end
  if match.ready[tostring(match.b.id)] then count = count + 1 end
  return count
end

function Solo:BroadcastReadyState(match, readyCount)
  local data = {
    readyCount = readyCount,
    total = 2
  }
  TriggerClientEvent('mp_pvp_v2:cl:readyCheckState', match.a.src, data)
  TriggerClientEvent('mp_pvp_v2:cl:readyCheckState', match.b.src, data)
end

function Solo:CancelReadyCheck(matchId, reason)
  local match = self.pendingMatches[matchId]
  if not match then return false end

  TriggerClientEvent('mp_pvp_v2:cl:readyCheckCancel', match.a.src, reason)
  TriggerClientEvent('mp_pvp_v2:cl:readyCheckCancel', match.b.src, reason)

  if match.bucket and self.bucket[match.bucket] then
    self.bucket[match.bucket] = nil
  end

  self.pendingMatches[matchId] = nil
  return true
end

function Solo:CancelReadyCheckByPlayer(playerId, reason)
  local playerKey = tostring(playerId)
  for matchId, match in pairs(self.pendingMatches) do
    if tostring(match.a.id) == playerKey or tostring(match.b.id) == playerKey then
      self:CancelReadyCheck(matchId, reason)
      return true
    end
  end
  return false
end

function Solo:IsPlayerPending(playerId)
  local playerKey = tostring(playerId)
  for _, match in pairs(self.pendingMatches) do
    if tostring(match.a.id) == playerKey or tostring(match.b.id) == playerKey then
      return true
    end
  end
  return false
end

function Solo:StartReadyMatch(matchId)
  local match = self.pendingMatches[matchId]
  if not match then return false end

  match.a.die = false
  match.b.die = false
  self.playingMatches[matchId] = {
    bucket = match.bucket,
    a = match.a,
    b = match.b,
  }
  self.pendingMatches[matchId] = nil

  if match.bucket then
    SetPlayerRoutingBucket(tostring(match.a.src), match.bucket)
    SetPlayerRoutingBucket(tostring(match.b.src), match.bucket)
  end

  TriggerClientEvent('mp_pvp_v2:cl:readyCheckClose', match.a.src)
  TriggerClientEvent('mp_pvp_v2:cl:readyCheckClose', match.b.src)

  TriggerClientEvent('mp_pvp_v2:cl:startMatch', match.a.src, match.weapon, 1, matchId, 1, 'a')
  TriggerClientEvent('mp_pvp_v2:cl:startMatch', match.b.src, match.weapon, 1, matchId, 1, 'b')

  local cache1 = {
    team = 'a',
    matchId = matchId,
    idx = 1,
    mode = 'solo'
  }
  local cache2 = {
    team = 'b',
    matchId = matchId,
    idx = 1,
    mode = 'solo'
  }
  TriggerEvent('mp_pvp_v2:sv:addToMatchCache', match.a.id, cache1)
  TriggerEvent('mp_pvp_v2:sv:addToMatchCache', match.b.id, cache2)

  return true
end

function Solo:PlayerDied(matchId, idx, playerIdx)
  local match = self.playingMatches[matchId]
  if not match then return end


  if idx == 'a' then
    match.a.die = true
  elseif idx == 'b' then
    match.b.die = true
  else
    return
  end

  local aDead, bDead = match.a.die, match.b.die

  if aDead and bDead then
    print(string.format("Trận %s kết thúc: Hòa", matchId))
    TriggerClientEvent('mp_pvp_v2:cl:matchEnded', tonumber(match.a.src), 'draw')
    TriggerClientEvent('mp_pvp_v2:cl:matchEnded', tonumber(match.b.src), 'draw')
  else
    local winner, loser
    if aDead then
      winner, loser = match.b, match.a
    elseif bDead then
      winner, loser = match.a, match.b
    else
      return
    end
    
    TriggerClientEvent('mp_pvp_v2:cl:matchEnded', tonumber(winner.src), 'win')
    TriggerClientEvent('mp_pvp_v2:cl:matchEnded', tonumber(loser.src), 'lose')


    local winPoint = Config.MatchPoint.win or 10
    local losePoint = Config.MatchPoint.lose or 10

    TriggerEvent("mp_pvp_v2:sv:addHistory", winner.id, "win", "1vs1", winPoint)
    TriggerEvent("mp_pvp_v2:sv:addHistory", loser.id, "lose", "1vs1", losePoint)


    loser.solo = loser.solo - losePoint
    winner.solo = winner.solo + winPoint


    self:SavePoint(winner.id, winner.solo)
    self:SavePoint(loser.id, loser.solo)
    self:TryGiveWinReward(winner)


    TriggerEvent('mp_pvp_v2:sv:updatePoint', winner.id, winner.solo, 'solo')
    TriggerEvent('mp_pvp_v2:sv:updatePoint', loser.id, loser.solo, 'solo')
  end

  SetPlayerRoutingBucket(tostring(match.a.src), 0)
  SetPlayerRoutingBucket(tostring(match.b.src), 0)
  TriggerEvent('mp_pvp_v2:sv:removeFromMatchCache', match.a.id)
  TriggerEvent('mp_pvp_v2:sv:removeFromMatchCache', match.b.id)
  if match.bucket and self.bucket[match.bucket] then
    self.bucket[match.bucket] = nil
  end
  self.playingMatches[matchId] = nil
end

function Solo:RemoveFromSoloQueue(teamId)
  if self.teams[tonumber(teamId)] then
    self.teams[tonumber(teamId)] = nil
  end
end

function Solo:FormatMembers(objects)
  local members = {}
  for _, obj in pairs(objects) do
    table.insert(members, obj)
  end
  return members
end

function Solo:GenerateMatchId()
  return string.format("solo_%d_%d", os.time(), math.random(1, 9999))
end

function Solo:CreateRandomBucketOptimized()
  local maxAttempts = 100
  local attempts = 0

  while attempts < maxAttempts do
    local randomNumber = math.random(1, 100)

    if not self.bucket[randomNumber] then
      self.bucket[randomNumber] = true
      return randomNumber
    end

    attempts = attempts + 1
  end

  print("Cảnh báo: Không thể tạo bucket mới!")
  return nil
end

function Solo:SavePoint(id, point)
  if Config.NegativePoint and point <= Config.NegativePoint.lockPoint then
    local sql = "UPDATE mp_pvp SET `solo` = ?, `solo_negative_locked_at` = COALESCE(`solo_negative_locked_at`, ?) WHERE `id` = ?"
    MySQL.update.await(sql, { point, os.time(), id })
  else
    local sql = "UPDATE mp_pvp SET `solo` = ?, `solo_negative_locked_at` = NULL WHERE `id` = ?"
    MySQL.update.await(sql, { point, id })
  end
end

function Solo:TryGiveWinReward(winner)
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
