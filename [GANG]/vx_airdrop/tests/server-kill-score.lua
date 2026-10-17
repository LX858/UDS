-- Run from vx_airdrop with: npm exec --yes --package=fengari-node-cli -- fengari tests/server-kill-score.lua
local now, timers = 10000, {}
local players = {}
local hitHandlers = {}
local scoreBroadcasts = 0

local vectorMeta = {}
function vectorMeta.__sub(a, b)
  return setmetatable({ x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }, vectorMeta)
end
function vectorMeta.__len(v)
  return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end
local function vec(x, y, z)
  return setmetatable({ x = x, y = y, z = z or 0 }, vectorMeta)
end

Config = { Airdrop = { DropPosition = vec(0, 0), ScoreRadius = 10, ScoreEverySeconds = 20, Bucket = 61432, RespawnSeconds = 2 } }
local impl = {}
function NewImpl() return impl end
function GetGameTimer() return now end
function GetPlayerName(src) return players[src] and players[src].online and tostring(src) or nil end
function GetPlayerPed(src) return players[src] and src or 0 end
function DoesEntityExist(ped) return players[ped] ~= nil end
function GetVehiclePedIsIn(ped) return players[ped].vehicle and 1 or 0 end
function GetEntityHealth(ped) return players[ped].health end
function GetEntityCoords(ped) return players[ped].coords end
function GetPlayerRoutingBucket(src) return players[tonumber(src)].bucket end
function Player(src) return { state = players[src].state } end
function TriggerClientEvent(name)
  if name == 'vx_airdrop:cl:score' then scoreBroadcasts = scoreBroadcasts + 1 end
end
function SetTimeout(delay, callback)
  timers[#timers + 1] = { at = now + delay, callback = callback }
end
local function advance(ms)
  now = now + ms
  local changed = true
  while changed do
    changed = false
    for i = #timers, 1, -1 do
      if timers[i].at <= now then
        local timer = table.remove(timers, i)
        timer.callback()
        changed = true
      end
    end
  end
end
exports = {
  qbx_core = { GetPlayer = function(_, src)
    return players[src] and { PlayerData = { citizenid = players[src].citizenid } }
  end },
  qbx_medical = { Revive = function(_, src)
    players[src].health = 200
    players[src].state['qbx_medical:deathState'] = 1
  end },
}

dofile('server/impl/main.impl.lua')
lib = { callback = { register = function() end } }
WS = {
  RegisterEventHandler = function(name, callback) hitHandlers[name] = callback end,
  TriggerClientEvent = function() end,
}
function AddEventHandler() end
function RegisterNetEvent() end
function TriggerEvent(name, ...)
  if name == 'neons_ddame:server:kill' then impl:HandleKill(...) end
end
dofile('../[standalone]/neons_ddame/server.lua')

local function newRound()
  timers, scoreBroadcasts = {}, 0
  now = now + 5000
  for src = 1, 4 do
    players[src] = {
      online = true, citizenid = 'cid' .. src, bucket = Config.Airdrop.Bucket,
      coords = vec(0, 0), health = 200, state = { ['qbx_medical:deathState'] = 1 },
    }
  end
  impl.round = {
    id = 'test', phase = 'match', scores = { A = 0, B = 0 }, killEvents = {},
    nextScoreAt = os.time() + 100,
    members = {
      [1] = { team = 'A', citizenid = 'cid1' },
      [2] = { team = 'B', citizenid = 'cid2' },
      [3] = { team = 'A', citizenid = 'cid3' },
      [4] = { team = 'B', citizenid = 'cid4' },
    },
  }
  return impl.round
end

local function hit(victim, attacker, damage)
  hitHandlers['neons_ddame:server:hit'](victim, attacker, damage, 0)
end
local function down(victim)
  players[victim].state['qbx_medical:deathState'] = 2
  impl:HandleDeath(victim, 'test')
end

local round = newRound()
hit(2, 1, 14)
assert(round.scores.A == 0, 'A nonfatal hit must not score')
down(2)
assert(round.scores.A == 0, 'A down without a neons kill event must not score')

round = newRound()
hit(2, 1, 100)
assert(round.scores.A == 0, 'A kill event must wait for confirmed death')
down(2)
assert(round.scores.A == 1 and scoreBroadcasts == 4, 'A confirmed enemy kill must score and broadcast once')
hit(2, 1, 100)
down(2)
assert(round.scores.A == 1, 'Repeated kill events in one death must not score twice')
advance(2000)
advance(800)
hit(2, 1, 100)
down(2)
assert(round.scores.A == 2, 'A new life must score again')

round = newRound()
down(2)
advance(200)
hit(2, 1, 100)
assert(round.scores.A == 1, 'A late kill event within the correlation window must score')

round = newRound()
hit(2, 1, 100)
advance(2001)
down(2)
assert(round.scores.A == 0, 'A stale kill event must not score')

round = newRound()
down(2)
assert(round.scores.A == 0 and round.scores.B == 0, 'A down without a neons kill event must not score')

round = newRound()
players[2].health = 0
players[2].state['qbx_medical:deathState'] = 2
hit(2, 1, 100)
assert(round.scores.A == 1 and round.members[2].respawnPending,
  'The kill event must invoke death handling when the server already sees the victim dead')

round = newRound()
players[1].coords = vec(11, 0)
hit(2, 1, 100)
down(2)
assert(round.scores.A == 0, 'Attacker outside the red circle must not score')

round = newRound()
players[2].coords = vec(11, 0)
hit(2, 1, 100)
down(2)
assert(round.scores.A == 0, 'Victim outside the red circle must not score')

round = newRound()
hit(2, 4, 100)
down(2)
assert(round.scores.B == 0, 'Friendly fire must not score')

round = newRound()
hit(2, 2, 100)
down(2)
assert(round.scores.B == 0, 'Self damage must not score')

round = newRound()
players[1].bucket = 999
hit(2, 1, 100)
down(2)
assert(round.scores.A == 0, 'Wrong bucket must not score')

round = newRound()
hit(2, 1, 100)
hit(2, 4, 100)
down(2)
assert(round.scores.A == 0, 'A later friendly kill event must invalidate an earlier enemy event')

round = newRound()
round.overtime = true
down(2)
hit(2, 1, 100)
assert(round.scores.A == 1, 'A confirmed overtime down must break the tie')

round = newRound()
Config.Airdrop.Schedule = {}
round.endsAt = os.time() - 1
down(2)
impl:Tick()
assert(round.phase == 'match' and not round.overtime, 'The result must wait for a pending kill event')
advance(2001)
impl:Tick()
assert(round.overtime == true, 'The result can proceed when the kill event window closes')

round = newRound()
round.endsAt = os.time() + 100
round.nextScoreAt = os.time() - 1
players[2].coords, players[4].coords = vec(11, 0), vec(11, 0)
impl:Tick()
assert(round.scores.A == 1 and round.scores.B == 0 and scoreBroadcasts == 4,
  'Two A players alone in the zone must earn only one point per interval')
impl:Tick()
assert(round.scores.A == 1 and scoreBroadcasts == 4, 'The same interval must not score twice')

round = newRound()
players[1].coords, players[3].coords = vec(11, 0), vec(11, 0)
impl:ScoreZone()
assert(round.scores.A == 0 and round.scores.B == 1 and scoreBroadcasts == 4,
  'Only team B in the zone must earn one point')

round = newRound()
impl:ScoreZone()
assert(round.scores.A == 0 and round.scores.B == 0 and scoreBroadcasts == 0,
  'A contested zone must not score')

round = newRound()
for src = 1, 4 do players[src].coords = vec(11, 0) end
impl:ScoreZone()
assert(round.scores.A == 0 and round.scores.B == 0 and scoreBroadcasts == 0,
  'An empty zone must not score')

round = newRound()
players[2].coords, players[4].coords = vec(11, 0), vec(11, 0)
players[1].health, players[3].health = 0, 0
impl:ScoreZone()
assert(round.scores.A == 0 and round.scores.B == 0,
  'Dead players must not capture the zone')

print('server-kill-score: all scenarios passed')
