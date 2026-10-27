-- Run from the resource directory with: npx --package=fengari-node-cli fengari tests/rewards_harness.lua
local rows = {}
local slots = {}
local nextId = 1
local playerCid = 'citizen-A'
local fullBag = true
local itemsGiven = 0
local commands = {}

exports = {
    qbx_core = {
        GetPlayer = function(_, src)
            if src ~= 1 then return nil end
            return { PlayerData = { citizenid = playerCid } }
        end,
        Notify = function() end,
    },
    ox_inventory = {
        Items = function(_, item) return item == 'gachabox2' end,
        AddItem = function(_, src, item, amount)
            if fullBag then return false, 'inventory_full' end
            assert(src == 1 and item == 'gachabox2')
            itemsGiven = itemsGiven + amount
            return true
        end,
    },
}
function GetPlayerName() return 'Tester' end
function RegisterCommand(name, fn) commands[name] = fn end
function Wait() end

MySQL = {
    ready = function(fn) fn() end,
    insert = { await = function(_, args)
        for _, row in ipairs(rows) do
            if row.round_id == args[1] and row.citizenid == args[2] and row.item == args[3] then
                return 0
            end
        end
        rows[#rows + 1] = {
            id = nextId, round_id = args[1], citizenid = args[2], item = args[3],
            amount = args[4], status = 'pending',
        }
        nextId = nextId + 1
        return nextId - 1
    end },
    query = { await = function(sql, args)
        if sql:find('CREATE TABLE') then return {} end
        local found = {}
        for _, row in ipairs(rows) do
            if row.status == 'pending' and
                (sql:find('round_id =') and row.round_id == args[1] and row.citizenid == args[2] and row.item == args[3]
                    or not sql:find('round_id =') and row.citizenid == args[1]) then
                found[#found + 1] = row
            end
        end
        return found
    end },
    update = { await = function(sql, args)
        if sql:find('INSERT IGNORE') then
            if slots[args[1]] then return 0 end
            slots[args[1]] = true
            return 1
        end
        for _, row in ipairs(rows) do
            if row.id == args[2] and row.citizenid == args[3] and row.status == args[4] then
                row.status = args[1]
                return 1
            end
        end
        return 0
    end },
}

dofile('server/rewards.lua')
assert(SwordRewards.ready)
assert(SwordRewards.ReserveSlot('2026-10-26 12:00'))
assert(not SwordRewards.ReserveSlot('2026-10-26 12:00'))

local reward = { { name = 'gachabox2', count = 5 } }
SwordRewards.Grant(1, 'round-1', reward)
assert(#rows == 1 and rows[1].status == 'pending' and itemsGiven == 0, 'full bag queues reward')
commands.swordflagclaim(1)
assert(rows[1].status == 'pending' and itemsGiven == 0, 'full bag keeps pending reward')

-- Simulate relog/resource restart: SQL rows remain, local locks and command are recreated.
dofile('server/rewards.lua')
fullBag = false
commands.swordflagclaim(1)
assert(rows[1].status == 'delivered' and itemsGiven == 5, 'claim after relog delivers x5')
commands.swordflagclaim(1)
SwordRewards.Grant(1, 'round-1', reward)
assert(itemsGiven == 5 and #rows == 1, 'repeat claim and repeat payout do not duplicate')

fullBag = true
SwordRewards.Grant(1, 'round-2', reward)
playerCid = 'citizen-B'
fullBag = false
commands.swordflagclaim(1)
assert(itemsGiven == 5 and rows[2].status == 'pending', 'other character cannot claim')
playerCid = 'citizen-A'
commands.swordflagclaim(1)
assert(itemsGiven == 10 and rows[2].status == 'delivered', 'owner can claim later')
print('rewards harness passed')
