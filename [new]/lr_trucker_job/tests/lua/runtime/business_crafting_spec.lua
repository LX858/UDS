local function equal(a, b, why) assert(a == b, (why or 'different') .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b)) end
function vec3(x, y, z) return { x = x, y = y, z = z } end
dofile('../../[DOANHNGHIEP]/xn_banhnuoc/config.lua')
dofile('../../[DOANHNGHIEP]/xn_banhnuoc/server/crafting_service.lua')
local config = Config
local now, stock, results = 0, {}, {}
local job = { name = 'quanan', onduty = true, grade = { level = 0 } }
local pos = config.Crafting.restaurant_crafting.coords
local failRemove, failAdd, reenter, service
local function reset()
    stock = {
        { name = 'gao', count = 5, slot = 1, metadata = { deliveryId = 'rice' } },
        { name = 'conheo', count = 4, slot = 2, metadata = { deliveryId = 'pork' } },
        { name = 'dua_soche', count = 1, slot = 3, metadata = { deliveryId = 'coconut' } },
        { name = 'tra_kho', count = 1, slot = 4, metadata = { deliveryId = 'tea' } },
    }
    results = {}
end
reset()
service = XnCrafting.Create({
    config = config, now = function() return now end,
    player = function() return { PlayerData = { job = job } } end,
    coords = function() return pos end,
    items = function() return stock end,
    canCarry = function() return true end,
    remove = function(_, name, amount, metadata, slot)
        if reenter then
            reenter = false
            equal(service:IsLocked('restaurant_shop_sell'), true)
            equal(service:Complete(2, 'restaurant_crafting', 'com_suon_tam_9h', 1), false, 'parallel craft')
        end
        if failRemove == name then return false end
        equal(stock[slot].metadata.deliveryId, metadata.deliveryId)
        if stock[slot].count < amount then return false end
        stock[slot].count = stock[slot].count - amount
        return true
    end,
    add = function(stash, name, amount, metadata, slot)
        if stash:match('_sell$') then
            if failAdd then return false end
            results[name] = (results[name] or 0) + amount
        else
            equal(stock[slot].metadata.deliveryId, metadata.deliveryId, 'rollback metadata')
            stock[slot].count = stock[slot].count + amount
        end
        return true
    end,
    log = function() end,
})
local fake = { name = 'com_suon_tam_9h', count = 999999, duration = 0, ingredients = {} }
equal(service:Begin(1, 'restaurant_crafting', fake, -1), false)
equal(service:Begin(1, 'restaurant_crafting', fake, 0/0), false)
equal(service:Begin(1, 'restaurant_crafting', fake, 11), false)
equal(service:Begin(1, 'restaurant_crafting', 'gao', 1), false)
job.onduty = false
equal(service:Begin(1, 'restaurant_crafting', fake, 1), false)
job.onduty, job.grade.level = true, -1
equal(service:Begin(1, 'restaurant_crafting', fake, 1), false)
job.grade.level = 0
pos = vec3(0, 0, 0)
equal(service:Begin(1, 'restaurant_crafting', fake, 1), false)
pos = config.Crafting.restaurant_crafting.coords
equal(service:Complete(1, 'restaurant_crafting', fake, 1), false, 'no session')
equal(service:Begin(1, 'restaurant_crafting', fake, 1), true)
equal(service:Complete(1, 'restaurant_crafting', fake, 1), false, 'skipped duration')
now = now + 2000
job.onduty = false
equal(service:Complete(1, 'restaurant_crafting', fake, 1), false, 'went off duty during progress')
job.onduty = true
pos = vec3(0, 0, 0)
equal(service:Complete(1, 'restaurant_crafting', fake, 1), false, 'moved away during progress')
pos = config.Crafting.restaurant_crafting.coords
equal(service:Complete(1, 'restaurant_crafting', fake, 1), true)
equal(results.com_suon_tam_9h, 8, 'client yield trusted')
equal(stock[1].count, 0, 'server ingredients ignored')
equal(service:Complete(1, 'restaurant_crafting', fake, 1), false, 'duplicate completion')
reset()
equal(service:Begin(1, 'restaurant_crafting', 'com_suon_tam_9h', 1), true)
equal(service:Begin(2, 'restaurant_crafting', 'com_suon_tam_9h', 1), true)
now = now + 2000
reenter, failAdd = true, true
equal(service:Complete(1, 'restaurant_crafting', 'com_suon_tam_9h', 1), false)
equal(stock[1].count, 5, 'rice rollback')
equal(stock[2].count, 4, 'pork rollback')
equal(next(results), nil, 'failed craft granted product')
failAdd = false
equal(service:Begin(1, 'restaurant_crafting', 'com_suon_tam_9h', 1), true)
now = now + 2000
failRemove = 'conheo'
equal(service:Complete(1, 'restaurant_crafting', 'com_suon_tam_9h', 1), false)
equal(stock[1].count, 5)
equal(stock[2].count, 4)
failRemove = nil
equal(service:Begin(1, 'restaurant_crafting', 'com_suon_tam_9h', 1), true)
now = now + 2000
equal(service:Complete(1, 'restaurant_crafting', 'com_suon_tam_9h', 1), true)
equal(results.com_suon_tam_9h, 8)
reset()
job.name, pos = 'quannuoc', config.Crafting.bar_crafting.coords
for _, name in ipairs({ 'nuocdua_utso', 'trada_utso' }) do
    equal(service:Begin(1, 'bar_crafting', name, 1), true)
    now = now + 2000
    equal(service:Complete(1, 'bar_crafting', name, 1), true)
    equal(results[name], 1)
end
stock = { { name = 'coconut', count = 100, slot = 1 }, { name = 'la_che', count = 100, slot = 2 } }
equal(service:Begin(1, 'bar_crafting', 'nuocdua_utso', 1), false, 'raw coconut crafted')
equal(service:Begin(1, 'bar_crafting', 'trada_utso', 1), false, 'raw tea crafted')
print('PASS business crafting security and transactions')
