-- Run from vx_airdrop with Lua 5.4 or through the local Lupa test runner.
local players = {}
local events = {}
local impl = {}

Config = { Airdrop = {
  Schedule = {}, RegistrationSeconds = 180, MaxParticipants = 100,
  MatchSeconds = 900, ScoreEverySeconds = 20, Bucket = 61432,
} }
function NewImpl() return impl end
function GetPlayerName(src) return players[tonumber(src)] and tostring(src) or nil end
function GetPlayerPed(src) return players[src] and src or 0 end
function DoesEntityExist(ped) return players[ped] ~= nil end
function GetVehiclePedIsIn(ped) return players[ped].vehicle and 1 or 0 end
function GetEntityHealth(ped) return players[ped].health end
function GetEntityCoords() return { x = 0, y = 0, z = 0 } end
function GetEntityHeading() return 0 end
function GetPlayerRoutingBucket(src) return players[tonumber(src)].bucket end
function SetPlayerRoutingBucket(src, bucket) players[tonumber(src)].bucket = bucket end
function Player(src) return players[src] end
function TriggerClientEvent(name, src, ...)
  events[#events + 1] = { name = name, src = src, args = { ... } }
end
WS = { TriggerClientEvent = function() end }
exports = { qbx_core = { GetPlayerCitizenId = function(_, src)
  return players[src] and players[src].citizenid
end } }

dofile('server/impl/main.impl.lua')
impl:Init()
impl.dbReady = true

local function addPlayer(src)
  local state = { ['qbx_medical:deathState'] = 1 }
  function state:set(key, value) self[key] = value end
  players[src] = { citizenid = 'cid' .. src, health = 200, bucket = 0, state = state }
end

local function eventCount(name)
  local count = 0
  for _, event in ipairs(events) do
    if event.name == 'vx_airdrop:' .. name then count = count + 1 end
  end
  return count
end

for src = 1, 101 do addPlayer(src) end
assert(impl:StartRound())
local round = impl.round
for src = 1, 98 do impl:Join(src, round.id) end
assert(round.phase == 'registration' and round.registeredCount == 98)
impl:Join(1, round.id)
assert(round.registeredCount == 98, 'duplicate join must not consume another slot')
impl:Join(99, round.id)
assert(round.phase == 'registration' and round.registeredCount == 99)
impl:RemovePlayer(99, 'left')
assert(round.registeredCount == 98 and not round.registered[99], 'leave must release slot')
impl:Join(99, round.id)
assert(round.phase == 'registration' and round.registeredCount == 99)
impl:Join(100, round.id)
assert(round.phase == 'match', '100th join must start match immediately')
assert(eventCount('cl:begin') == 100, 'exactly 100 players must start')
assert(not round.members[101], '101st player must not enter')
impl:Join(101, round.id)
assert(not round.members[101] and eventCount('cl:begin') == 100)

impl.round = nil
events = {}
assert(impl:StartRound())
round = impl.round
impl:Join(1, round.id)
impl:Join(2, round.id)
assert(round.phase == 'registration', 'below cap must keep waiting')
round.registrationEnds = os.time() - 1
impl:Tick()
assert(round.phase == 'match' and eventCount('cl:begin') == 2, 'timeout must still start match')

print('server-registration-limit: passed')
