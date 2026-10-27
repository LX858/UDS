-- Run from the resource directory with: npx --package=fengari-node-cli fengari tests/schedule_harness.lua
Config = {
    AdminAce = 'AdminMenu',
    Commands = { startUI = 'cuopco', startNoUI = 'cuopco2', stop = 'dungcuopco' },
    JoinWaitSeconds = 600,
    GameDurationMinutes = 10,
    Schedule = { '12:00', '23:00' },
    ScheduledMode = 'Random',
    ScheduledTeamCount = 2,
    TeamData = { {}, {} },
    MaxPlayersPerTeam = 40,
    Server = { startDelayBeforeTimerSeconds = 0 },
    Rewards = { WinnerDefault = { { name = 'gachabox2', count = 5 } }, Consolation = {} },
}

local now = 1792990740 -- 2026-10-26 11:59 Bangkok
local originalTime = os.time
os.time = function() return now end
local scheduled = {}
local slots = {}
local registrations = {}
local countdowns = {}
local handlers = {}
local commands = {}
local joinedTeams = {}
local grants = {}

SwordRewards = {
    ready = true,
    ReserveSlot = function(key)
        if slots[key] then return false end
        slots[key] = true
        return true
    end,
    Grant = function(src, _, rewards)
        grants[#grants + 1] = { src = src, rewards = rewards }
    end,
}

Citizen = { CreateThread = function(fn) scheduled[#scheduled + 1] = fn end }
function Wait() coroutine.yield() end
function AddEventHandler(name, fn) handlers[name] = fn end
function RegisterNetEvent(name, fn) if fn then handlers[name] = fn end end
function RegisterCommand(name, fn) commands[name] = fn end
function IsPlayerAceAllowed() return true end
function GetCurrentResourceName() return 'Zc_SwordFlag' end
function TriggerEvent(name, ...)
    if handlers[name] then handlers[name](...) end
end
function AlertServer() end
exports = { ox_inventory = { Items = function(_, item) return item == 'testItem' end } }
function TriggerClientEvent(name, target, ...)
    if name == 'zcSword_Register' then registrations[#registrations + 1] = { ... } end
    if name == 'zcSword_AddTeamMember' then joinedTeams[target] = (...) end
end
function GetGameTimer() return 12345 end
GlobalState = {}

dofile('server/server.lua')
local realCountdown = StartCountDownSV
StartCountDownSV = function(seconds, duration)
    countdowns[#countdowns + 1] = { seconds, duration }
end

local clock = coroutine.create(scheduled[1])
local function tick(thread)
    local ok, err = coroutine.resume(thread)
    assert(ok, tostring(err))
end

tick(clock)
assert(#registrations == 0, '11:59 must not open')
now = now + 60
tick(clock)
assert(#registrations == 1, '12:00 must open once')
assert(registrations[1][1] == 'Random' and registrations[1][2] == 2, 'scheduled teams must be random and two')
assert(countdowns[1][1] == 600 and countdowns[1][2] == 10, 'registration and match timing')
tick(clock)
assert(#registrations == 1, 'same minute must not open twice')

-- Simulate resource restart while still in 12:00. The slot table survives.
dofile('server/server.lua')
realCountdown = StartCountDownSV
StartCountDownSV = function(seconds, duration)
    countdowns[#countdowns + 1] = { seconds, duration }
end
clock = coroutine.create(scheduled[2])
tick(clock)
assert(#registrations == 1, 'restart in same minute must not reopen')

now = 1793030340 -- 2026-10-26 22:59 Bangkok
tick(clock)
assert(#registrations == 1, '22:59 must not open')
SW = true -- another event or admin reservation
now = now + 60
tick(clock)
assert(#registrations == 1 and slots['2026-10-26 23:00'], 'busy 23:00 slot must be consumed')
SW = false
tick(clock)
assert(#registrations == 1, 'busy slot must not catch up')
now = now + 86400 - 60 -- next day 22:59 Bangkok
tick(clock)
assert(#registrations == 1, 'next-day 22:59 must not open')
now = now + 60
tick(clock)
assert(#registrations == 2 and registrations[2][1] == 'Random', 'next-day 23:00 must open')
SW = false -- Finish this simulated round before the payout tests below.

-- Scheduled/manual paths both pay the configured winner reward. Auto pays no loser.
handlers.zcSword_Auto('Random', 2, 10)
assert(registrations[3][1] == 'Random')
for src = 1, 2 do
    source = src
    local join = coroutine.create(handlers.zcSword_SvRandomTeam)
    tick(join)
end
assert(joinedTeams[1] ~= joinedTeams[2], 'random assignment must balance two teams')
realCountdown(1, 10)
local start = coroutine.create(scheduled[#scheduled])
tick(start)
tick(start)
tick(start)
GlobalState['Score' .. joinedTeams[1]] = 10
GlobalState['Score' .. joinedTeams[2]] = 0
handlers.zcSword_EndSV()
assert(#grants == 1 and grants[1].src == 1, 'auto must pay winner only')
assert(grants[1].rewards[1].name == 'gachabox2' and grants[1].rewards[1].count == 5)

dofile('server/server.lua')
realCountdown = StartCountDownSV
StartCountDownSV = function(seconds, duration)
    countdowns[#countdowns + 1] = { seconds, duration }
end
joinedTeams, grants = {}, {}
source = 99
commands.cuopco(99)
handlers['yip:sv:startevent']('Select', 2, 10,
    { { name = 'testItem', count = 2 } }, { { name = 'testItem', count = 99 } })
for src = 1, 2 do
    source = src
    local join = coroutine.create(function() handlers.zcSword_SelectTeam(src) end)
    tick(join)
end
realCountdown(1, 10)
start = coroutine.create(scheduled[#scheduled])
tick(start)
tick(start)
tick(start)
GlobalState.Score1, GlobalState.Score2 = 10, 0
handlers.zcSword_EndSV()
assert(#grants == 2, 'manual must pay winner and selected loser')
assert(grants[1].rewards[1].name == 'gachabox2' and grants[1].rewards[1].count == 5,
    'manual winner reward cannot be overridden')
assert(grants[2].rewards[1].name == 'testItem' and grants[2].rewards[1].count == 2,
    'manual loser reward should remain selectable')

os.time = originalTime
print('schedule harness passed')
