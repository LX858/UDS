---@class MainImpl : Impl
local Impl = NewImpl('Main')
local prefix = 'vx_airdrop:'
local deathKey = 'qbx_medical:deathState'
local killEventWindowMs = 2000

local function online(src)
  return GetPlayerName(src) ~= nil
end

local function onFoot(src)
  local ped = GetPlayerPed(src)
  return ped ~= 0 and DoesEntityExist(ped) and GetVehiclePedIsIn(ped, false) == 0
end

local function alive(src)
  local ped = GetPlayerPed(src)
  local state = Player(src).state[deathKey]
  return ped ~= 0 and DoesEntityExist(ped) and GetEntityHealth(ped) > 0 and state ~= 2 and state ~= 3
end

local function citizenId(src)
  local player = exports.qbx_core:GetPlayer(src)
  return player and player.PlayerData and player.PlayerData.citizenid
end

local function notify(src, message, kind)
  if src == 0 then
    print(('[vx_airdrop] %s'):format(message))
  elseif online(src) then
    TriggerClientEvent(prefix .. 'cl:notify', src, message, kind or 'inform')
  end
end

local function clearClothingState(src, roundId)
  if not online(src) then return end
  local state = Player(src).state
  if roundId and state.vxAirdropRound ~= roundId then return end
  state:set('vxAirdropActive', false, true)
  state:set('vxAirdropTeam', nil, true)
  state:set('vxAirdropRound', nil, true)
end

local function clearClothingStateAfterRestore(src, roundId)
  SetTimeout(5000, function()
    clearClothingState(src, roundId)
  end)
end

function Impl:Init()
  self.round = nil
  self.protectionReset = nil
  self.lastScheduleMinute = nil
  self.claimLocks = {}
  self.dbReady = false
end

function Impl:OnReady()
  local ok, err = pcall(function()
    MySQL.query.await([[
      CREATE TABLE IF NOT EXISTS `vx_airdrop_pending_rewards` (
        `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
        `round_id` VARCHAR(64) NOT NULL,
        `citizenid` VARCHAR(64) NOT NULL,
        `item` VARCHAR(100) NOT NULL,
        `amount` INT UNSIGNED NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `round_reward` (`round_id`, `citizenid`, `item`),
        KEY `citizenid` (`citizenid`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
  end)
  self.dbReady = ok
  if not ok then self:LogError('Reward table creation failed: %s', tostring(err)) end

  RegisterCommand('airdropstart', function(src)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'vx_airdrop.admin') then
      return notify(src, 'Bạn không có quyền mở airdrop.', 'error')
    end
    local started, reason = self:StartRound()
    notify(src, started and 'Đã mở đăng ký airdrop.' or reason, started and 'success' or 'error')
  end, false)
  RegisterCommand('airdropcancel', function(src)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'vx_airdrop.admin') then
      return notify(src, 'Bạn không có quyền hủy airdrop.', 'error')
    end
    if not self.round then return notify(src, 'Không có lượt airdrop đang chạy.', 'error') end
    if self.round.phase == 'result' then return notify(src, 'Kết quả đã chốt và phần thưởng đã phát.', 'error') end
    self:CancelRound('Admin đã hủy airdrop.')
    notify(src, 'Đã hủy airdrop.', 'success')
  end, false)
  RegisterCommand('airdropcleargodmode', function(src)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'vx_airdrop.admin') then
      return notify(src, 'Bạn không có quyền dùng lệnh này.', 'error')
    end
    self:StartProtectionReset(src)
  end, false)
  RegisterCommand('airdropclaim', function(src)
    if src == 0 then return notify(src, 'Lệnh này chỉ dùng trong game.') end
    self:ClaimRewards(src)
  end, false)

  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'sv:ready', function() self:SyncPlayer(source) end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'sv:join', function(roundId) self:Join(source, roundId) end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'sv:vehicle', function(roundId)
    local src, round = source, self.round
    if round and round.id == roundId and not onFoot(src) then
      self:RemovePlayer(src, 'Bạn đã lên xe nên bị gỡ khỏi airdrop.')
    end
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'sv:chooseWeapon', function(roundId, weaponId)
    self:ChooseWeapon(source, roundId, weaponId)
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'sv:died', function(roundId)
    self:HandleDeath(source, roundId)
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'sv:clothingRestored', function(roundId)
    clearClothingState(source, roundId)
  end)
  self.eventHandlers[#self.eventHandlers + 1] = RegisterNetEvent(prefix .. 'sv:protectionResetAck', function(token, status)
    self:HandleProtectionResetAck(source, token, status)
  end)
  self.eventHandlers[#self.eventHandlers + 1] = AddEventHandler('neons_ddame:server:kill', function(playerId, attackerId)
    self:HandleKill(playerId, attackerId)
  end)
  self.eventHandlers[#self.eventHandlers + 1] = AddEventHandler('playerDropped', function()
    self:RemovePlayer(source, nil, true)
  end)

  CreateThread(function()
    while not self.destroyed do
      Wait(1000)
      self:Tick()
    end
  end)
end

function Impl:OnResourceStop()
  if self.round then self:CleanRound('Airdrop đã dừng.', true) end
end

function Impl:OnDestroy()
  if self.round then self:CleanRound('Airdrop đã được tải lại.', true) end
end

function Impl:FinishProtectionReset(request)
  if self.protectionReset ~= request then return end
  self.protectionReset = nil
  local cleared, skipped, missing = 0, {}, {}
  for src, status in pairs(request.results) do
    if status == 'cleared' then
      cleared = cleared + 1
    else
      skipped[#skipped + 1] = ('%d:%s'):format(src, status)
    end
  end
  for src in pairs(request.pending) do missing[#missing + 1] = src end
  table.sort(skipped)
  table.sort(missing)
  local message = ('Đã tắt bất tử cho %d/%d người online. Bỏ qua: %s. Không phản hồi: %s.')
    :format(cleared, request.total, #skipped > 0 and table.concat(skipped, ', ') or 'không',
      #missing > 0 and table.concat(missing, ', ') or 'không')
  print('[vx_airdrop] ' .. message)
  if request.requester ~= 0 then notify(request.requester, message, 'inform') end
end

function Impl:HandleProtectionResetAck(src, token, status)
  local request = self.protectionReset
  if not request or request.token ~= token or request.pending[src] == nil
    or (request.pending[src] and citizenId(src) ~= request.pending[src]) then return end
  if status ~= 'cleared' and status ~= 'dead' and status ~= 'in_match' and status ~= 'ped_missing' then return end
  request.pending[src] = nil
  request.results[src] = status
  if not next(request.pending) then self:FinishProtectionReset(request) end
end

function Impl:StartProtectionReset(requester)
  if self.round then return notify(requester, 'Hãy chờ trận airdrop kết thúc rồi dùng lệnh.', 'error') end
  if self.protectionReset then return notify(requester, 'Đang kiểm tra trạng thái bất tử.', 'error') end
  local pending, total = {}, 0
  for _, id in ipairs(GetPlayers()) do
    local src = tonumber(id)
    if src and online(src) then
      pending[src] = citizenId(src) or false
      total = total + 1
    end
  end
  if total == 0 then return notify(requester, 'Không có người chơi online.') end
  local request = {
    token = ('%d-%06d'):format(GetGameTimer(), math.random(0, 999999)),
    requester = requester, pending = pending, results = {}, total = total,
  }
  self.protectionReset = request
  for src in pairs(pending) do
    TriggerClientEvent(prefix .. 'cl:clearInvincibility', src, request.token)
  end
  notify(requester, ('Đang tắt bất tử và chờ phản hồi từ %d người chơi.'):format(total))
  SetTimeout(14000, function()
    if self.protectionReset ~= request then return end
    for src in pairs(request.pending) do
      if online(src) then TriggerClientEvent(prefix .. 'cl:clearInvincibility', src, request.token) end
    end
    SetTimeout(14000, function() self:FinishProtectionReset(request) end)
  end)
end

function Impl:StartRound()
  if self.round then return false, 'Đã có lượt airdrop đang chạy.' end
  if self.protectionReset then return false, 'Đang kiểm tra trạng thái bất tử của người chơi.' end
  if not self.dbReady then return false, 'Cơ sở dữ liệu phần thưởng chưa sẵn sàng.' end
  local now = os.time()
  self.round = {
    id = ('%d-%06d'):format(now, math.random(0, 999999)),
    phase = 'registration', registrationEnds = now + Config.Airdrop.RegistrationSeconds,
    registered = {}, members = {}, killEvents = {}, scores = { A = 0, B = 0 },
  }
  TriggerClientEvent(prefix .. 'cl:registration', -1, self.round.id, self.round.registrationEnds, false, now)
  return true
end

function Impl:SyncPlayer(src)
  local round = self.round
  if not round then return TriggerClientEvent(prefix .. 'cl:reset', src) end
  if round.phase == 'registration' then
    TriggerClientEvent(prefix .. 'cl:registration', src, round.id, round.registrationEnds, round.registered[src] == true, os.time())
  elseif round.phase == 'match' and round.members[src] then
    local member = round.members[src]
    TriggerClientEvent(prefix .. 'cl:matchSync', src, round.id, member.team, round.endsAt,
      round.scores, round.overtime, member.selecting, os.time())
    WS.TriggerClientEvent(prefix .. 'cl:uniforms', src, round.id, self:GetUniformRoster())
  else
    TriggerClientEvent(prefix .. 'cl:reset', src)
  end
end

function Impl:Join(src, roundId)
  local round = self.round
  if not round or round.phase ~= 'registration' or round.id ~= roundId or os.time() >= round.registrationEnds then return end
  if not online(src) or not citizenId(src) or not onFoot(src) or not alive(src) then
    return notify(src, 'Bạn phải vào nhân vật, còn sống và xuống xe để tham gia.', 'error')
  end
  round.registered[src] = true
  TriggerClientEvent(prefix .. 'cl:joined', src, round.id)
end

function Impl:BeginMatch()
  local round = self.round
  if not round or round.phase ~= 'registration' then return end
  local players = {}
  for src in pairs(round.registered) do
    if online(src) and citizenId(src) and onFoot(src) and alive(src) then players[#players + 1] = src end
  end
  if #players <= 1 then return self:CancelRound('Airdrop bị hủy vì có dưới 2 người tham gia.') end
  for i = #players, 2, -1 do
    local j = math.random(i)
    players[i], players[j] = players[j], players[i]
  end
  local now = os.time()
  round.phase = 'match'
  round.endsAt = now + Config.Airdrop.MatchSeconds
  round.nextScoreAt = now + Config.Airdrop.ScoreEverySeconds
  round.overtime = false
  for i, src in ipairs(players) do
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local team = i % 2 == 1 and 'A' or 'B'
    round.members[src] = {
      team = team,
      citizenid = citizenId(src),
      origin = { x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(ped) },
      bucket = GetPlayerRoutingBucket(tostring(src)), selecting = true, respawnPending = false,
    }
    Player(src).state:set('vxAirdropRound', round.id, true)
    Player(src).state:set('vxAirdropTeam', team, true)
    Player(src).state:set('vxAirdropActive', true, true)
    SetPlayerRoutingBucket(tostring(src), Config.Airdrop.Bucket)
  end
  for src, member in pairs(round.members) do
    TriggerClientEvent(prefix .. 'cl:begin', src, round.id, member.team, round.endsAt, round.scores, now)
  end
  self:BroadcastUniforms()
  round.registered = {}
  TriggerClientEvent(prefix .. 'cl:reset', -1, round.id)
  self:BroadcastScore()
end

function Impl:GetUniformRoster()
  local roster = {}
  local round = self.round
  if not round then return roster end
  for src, member in pairs(round.members) do
    roster[#roster + 1] = { source = src, team = member.team }
  end
  return roster
end

function Impl:BroadcastUniforms()
  local round = self.round
  if not round or (round.phase ~= 'match' and round.phase ~= 'result') then return end
  local roster = self:GetUniformRoster()
  for src in pairs(round.members) do
    WS.TriggerClientEvent(prefix .. 'cl:uniforms', src, round.id, roster)
  end
end

function Impl:BroadcastScore()
  local round = self.round
  if not round or round.phase ~= 'match' then return end
  for src in pairs(round.members) do
    WS.TriggerClientEvent(prefix .. 'cl:score', src, round.id, round.scores, round.endsAt, round.overtime, os.time())
  end
end

function Impl:ScoreZone()
  local round = self.round
  if not round or round.phase ~= 'match' then return end
  local present = { A = false, B = false }
  for src, member in pairs(round.members) do
    if online(src) and citizenId(src) == member.citizenid and onFoot(src) and alive(src)
      and GetPlayerRoutingBucket(tostring(src)) == Config.Airdrop.Bucket
      and #(GetEntityCoords(GetPlayerPed(src)) - Config.Airdrop.DropPosition) <= Config.Airdrop.ScoreRadius then
      present[member.team] = true
    end
  end
  if present.A == present.B then return end
  local team = present.A and 'A' or 'B'
  round.scores[team] = round.scores[team] + 1
  self:BroadcastScore()
end

function Impl:ChooseWeapon(src, roundId, weaponId)
  local round = self.round
  local member = round and round.members[src]
  if not round or round.id ~= roundId or round.phase ~= 'match' or not member or not member.selecting or member.respawnPending then return end
  if not alive(src) or not onFoot(src) then return end
  for _, weapon in ipairs(Config.Airdrop.Weapons) do
    if weapon.id == weaponId then
      member.selecting = false
      TriggerClientEvent(prefix .. 'cl:weaponApproved', src, round.id, weapon.name)
      return
    end
  end
end

function Impl:CreditKill(victimSrc)
  local round = self.round
  if not round or round.phase ~= 'match' then return end
  local victim = round.members[victimSrc]
  local killEvent = round.killEvents[victimSrc]
  if not victim or not victim.respawnPending or victim.killCredited or not victim.deathStartedAt or not killEvent then return end
  if math.abs(killEvent.at - victim.deathStartedAt) > killEventWindowMs then return end
  local attacker = round.members[killEvent.attackerSrc]
  if not attacker or attacker.team == victim.team or attacker.team ~= killEvent.team
    or attacker.citizenid ~= killEvent.attackerCitizenid or victim.citizenid ~= killEvent.victimCitizenid
    or not online(killEvent.attackerSrc) or not online(victimSrc)
    or citizenId(killEvent.attackerSrc) ~= attacker.citizenid or citizenId(victimSrc) ~= victim.citizenid then return end

  victim.killCredited = true
  round.killEvents[victimSrc] = nil
  round.scores[attacker.team] = round.scores[attacker.team] + 1
  if Config.Debug then
    print(('[vx_airdrop] Kill score: %s(%s) -> %s(%s), score A=%d B=%d')
      :format(killEvent.attackerSrc, attacker.team, victimSrc, victim.team, round.scores.A, round.scores.B))
  end
  self:BroadcastScore()
end

function Impl:HandleKill(victimSrc, attackerSrc)
  victimSrc, attackerSrc = tonumber(victimSrc), tonumber(attackerSrc)
  if not victimSrc then return end
  local round = self.round
  if not round or round.phase ~= 'match' then return end
  round.killEvents[victimSrc] = nil
  if not attackerSrc or victimSrc == attackerSrc then return end
  local victim, attacker = round.members[victimSrc], round.members[attackerSrc]
  if not victim or not attacker or victim.team == attacker.team or victim.killCredited then return end
  local now = GetGameTimer()
  if victim.respawnPending and (not victim.deathStartedAt or now - victim.deathStartedAt > killEventWindowMs) then return end
  if not online(victimSrc) or not online(attackerSrc)
    or citizenId(victimSrc) ~= victim.citizenid or citizenId(attackerSrc) ~= attacker.citizenid
    or not onFoot(victimSrc) or not onFoot(attackerSrc) or not alive(attackerSrc)
    or GetPlayerRoutingBucket(tostring(victimSrc)) ~= Config.Airdrop.Bucket
    or GetPlayerRoutingBucket(tostring(attackerSrc)) ~= Config.Airdrop.Bucket then return end
  local drop, radius = Config.Airdrop.DropPosition, Config.Airdrop.ScoreRadius
  if #(GetEntityCoords(GetPlayerPed(victimSrc)) - drop) > radius
    or #(GetEntityCoords(GetPlayerPed(attackerSrc)) - drop) > radius then return end

  round.killEvents[victimSrc] = {
    attackerSrc = attackerSrc, attackerCitizenid = attacker.citizenid,
    victimCitizenid = victim.citizenid, team = attacker.team, at = now,
  }
  if victim.respawnPending then
    self:CreditKill(victimSrc)
  elseif not alive(victimSrc) then
    self:HandleDeath(victimSrc, round.id)
  end
end

function Impl:HandleDeath(src, roundId)
  local round = self.round
  local member = round and round.members[src]
  if not round or round.id ~= roundId or round.phase ~= 'match' or not member or member.respawnPending then return end
  if alive(src) then return end
  member.respawnPending = true
  member.deathStartedAt = GetGameTimer()
  member.killCredited = false
  member.selecting = false
  self:CreditKill(src)
  TriggerClientEvent(prefix .. 'cl:respawnWait', src, round.id, Config.Airdrop.RespawnSeconds)
  SetTimeout(Config.Airdrop.RespawnSeconds * 1000, function()
    if self.round ~= round or round.phase ~= 'match' or round.members[src] ~= member or not online(src) then return end
    member.deathStartedAt = nil
    round.killEvents[src] = nil
    exports.qbx_medical:Revive(src)
    SetTimeout(800, function()
      if self.round ~= round or round.phase ~= 'match' or round.members[src] ~= member or not online(src) then return end
      member.respawnPending = false
      member.killCredited = false
      member.selecting = true
      TriggerClientEvent(prefix .. 'cl:respawn', src, round.id, member.team)
    end)
  end)
end

function Impl:RemovePlayer(src, reason, dropped, skipTeamCheck)
  local round = self.round
  if not round then return end
  if round.phase == 'registration' then
    if round.registered[src] then
      round.registered[src] = nil
      if not dropped then TriggerClientEvent(prefix .. 'cl:unjoined', src, round.id, reason) end
    end
    return
  end
  local member = round.members[src]
  if not member then return end
  round.killEvents[src] = nil
  for victimSrc, killEvent in pairs(round.killEvents) do
    if killEvent.attackerSrc == src then round.killEvents[victimSrc] = nil end
  end
  round.members[src] = nil
  if round.phase == 'match' then self:BroadcastUniforms() end
  if not dropped and online(src) and citizenId(src) == member.citizenid then
    exports.qbx_medical:Revive(src)
    TriggerClientEvent(prefix .. 'cl:leave', src, round.id, member.origin, reason)
    SetPlayerRoutingBucket(tostring(src), member.bucket)
    clearClothingStateAfterRestore(src, round.id)
  end
  if round.phase == 'match' and not skipTeamCheck then self:CheckTeams() end
end

function Impl:CheckTeams()
  local round = self.round
  if not round or round.phase ~= 'match' then return end
  local a, b = 0, 0
  for src in pairs(round.members) do
    if not online(src) or not onFoot(src) or citizenId(src) ~= round.members[src].citizenid
      or GetPlayerRoutingBucket(tostring(src)) ~= Config.Airdrop.Bucket then
      self:RemovePlayer(src, 'Bạn đã rời điều kiện tham gia airdrop.', not online(src), true)
    end
  end
  for src, member in pairs(round.members) do
    if online(src) then
      if member.team == 'A' then a = a + 1 else b = b + 1 end
    end
  end
  if a == 0 and b == 0 then
    self:CancelRound('Airdrop bị hủy vì không còn người tham gia.')
  elseif a == 0 then
    self:FinishRound('B')
  elseif b == 0 then
    self:FinishRound('A')
  end
end

function Impl:FinishRound(winner)
  local round = self.round
  if not round or round.phase ~= 'match' then return end
  round.phase = 'result'
  round.killEvents = {}
  for src, member in pairs(round.members) do
    if online(src) and citizenId(src) == member.citizenid then
      if member.team == winner then self:GrantRewards(src, round.id) end
      if member.respawnPending or not alive(src) then exports.qbx_medical:Revive(src) end
      TriggerClientEvent(prefix .. 'cl:result', src, round.id, member.team == winner, Config.Airdrop.ResultSeconds)
    end
  end
  SetTimeout(Config.Airdrop.ResultSeconds * 1000, function()
    if self.round == round then self:CleanRound() end
  end)
end

function Impl:GrantRewards(src, roundId)
  local cid = citizenId(src)
  if not cid then return self:LogError('Missing citizenid for reward: %s', src) end
  for _, reward in ipairs(Config.Airdrop.Rewards) do
    local added = exports.ox_inventory:AddItem(src, reward.name, reward.count)
    if not added then
      local ok, err = pcall(function()
        MySQL.query.await([[
          INSERT INTO vx_airdrop_pending_rewards (round_id, citizenid, item, amount)
          VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE amount = VALUES(amount)
        ]], { roundId, cid, reward.name, reward.count })
      end)
      if ok then
        notify(src, ('Túi đầy: %s x%d đã được lưu. Dùng /airdropclaim khi còn chỗ.'):format(reward.name, reward.count))
      else
        self:LogError('Could not queue reward for %s: %s', cid, tostring(err))
      end
    end
  end
end

function Impl:ClaimRewards(src)
  if not self.dbReady then return notify(src, 'Hệ thống thưởng chưa sẵn sàng.', 'error') end
  local cid = citizenId(src)
  if not cid then return notify(src, 'Nhân vật chưa sẵn sàng.', 'error') end
  if self.claimLocks[cid] then return end
  self.claimLocks[cid] = true
  local ok, err = pcall(function()
    local rows = MySQL.query.await('SELECT id, item, amount FROM vx_airdrop_pending_rewards WHERE citizenid = ? ORDER BY id', { cid })
    if not rows or #rows == 0 then return notify(src, 'Bạn không có phần thưởng chờ nhận.') end
    local claimed = 0
    for _, row in ipairs(rows) do
      if not online(src) or citizenId(src) ~= cid then break end
      if exports.ox_inventory:AddItem(src, row.item, row.amount) then
        MySQL.query.await('DELETE FROM vx_airdrop_pending_rewards WHERE id = ? AND citizenid = ?', { row.id, cid })
        claimed = claimed + 1
      end
    end
    notify(src, claimed > 0 and ('Đã nhận %d loại phần thưởng.'):format(claimed)
      or 'Túi chưa đủ chỗ hoặc vật phẩm chưa được cấu hình.', claimed > 0 and 'success' or 'error')
  end)
  self.claimLocks[cid] = nil
  if not ok then self:LogError('Claim failed for %s: %s', cid, tostring(err)) end
end

function Impl:CleanRound(reason, clearImmediately)
  local round = self.round
  if not round then return end
  self.round = nil
  TriggerClientEvent(prefix .. 'cl:reset', -1, round.id, reason)
  for src, member in pairs(round.members) do
    if online(src) and citizenId(src) == member.citizenid then
      exports.qbx_medical:Revive(src)
      TriggerClientEvent(prefix .. 'cl:leave', src, round.id, member.origin)
      SetPlayerRoutingBucket(tostring(src), member.bucket)
      if clearImmediately then
        clearClothingState(src, round.id)
      else
        clearClothingStateAfterRestore(src, round.id)
      end
    end
  end
end

function Impl:CancelRound(reason)
  self:CleanRound(reason)
end

function Impl:Tick()
  local now = os.time()
  local bangkok = os.date('!*t', now + 7 * 3600)
  local minuteKey = ('%04d-%02d-%02d %02d:%02d'):format(bangkok.year, bangkok.month, bangkok.day, bangkok.hour, bangkok.min)
  if minuteKey ~= self.lastScheduleMinute then
    self.lastScheduleMinute = minuteKey
    local time = ('%02d:%02d'):format(bangkok.hour, bangkok.min)
    for _, scheduled in ipairs(Config.Airdrop.Schedule) do
      if scheduled == time then
        local started, reason = self:StartRound()
        if not started then self:LogWarning('Scheduled start skipped: %s', reason) end
        break
      end
    end
  end
  local round = self.round
  if not round then return end
  if round.phase == 'registration' then
    for src in pairs(round.registered) do
      if not online(src) or not onFoot(src) then self:RemovePlayer(src, 'Bạn đã lên xe nên bị gỡ khỏi airdrop.', not online(src)) end
    end
    if now >= round.registrationEnds then self:BeginMatch() end
  elseif round.phase == 'match' then
    for src in pairs(round.members) do
      local member = round.members[src]
      if not online(src) or not onFoot(src) or citizenId(src) ~= member.citizenid
        or GetPlayerRoutingBucket(tostring(src)) ~= Config.Airdrop.Bucket then
        self:RemovePlayer(src, 'Bạn đã rời điều kiện tham gia airdrop.', not online(src))
      end
      if self.round ~= round or round.phase ~= 'match' then return end
    end
    if now >= round.nextScoreAt then
      round.nextScoreAt = now + Config.Airdrop.ScoreEverySeconds
      self:ScoreZone()
    end
    if now >= round.endsAt then
      -- Let a down near the deadline receive its neons kill event before locking the result.
      for _, member in pairs(round.members) do
        if member.respawnPending and member.deathStartedAt and not member.killCredited
          and GetGameTimer() - member.deathStartedAt < killEventWindowMs then return end
      end
      if round.scores.A ~= round.scores.B then
        self:FinishRound(round.scores.A > round.scores.B and 'A' or 'B')
      elseif not round.overtime then
        round.overtime = true
        self:BroadcastScore()
      end
    end
  end
end
