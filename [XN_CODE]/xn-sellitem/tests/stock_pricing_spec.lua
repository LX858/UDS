-- Run from the resources directory with a Lua 5.3+ runner.
local handlers, protected, threads, events = {}, {}, {}, {}
local persisted = {
    coconut = { category = 'traicay', price = 77, amount = 49, sold = 0 },
    custom = { category = 'custom', price = 77, amount = 49, sold = 0 },
    traidudu = { category = 'choden', price = 310, amount = 17, sold = 0 },
}

local function itemConfig(itemName, min, max)
    local row = persisted[itemName]
    return {
        Label = itemName, Min = min, Max = max, CurrentPrice = row.price,
        CurrentAmount = row.amount, AmountSold = row.sold,
        AmountToChange = 50, RangeChange = { 1, 4 },
    }
end

DatabaseConfig = {
    traicay = { coconut = itemConfig('coconut', 50, 100) },
    custom = { custom = itemConfig('custom', 50, 100) },
    choden = { traidudu = itemConfig('traidudu', 200, 400) },
}

Config = {
    EnableTruckerjob = true,
    TuDong_ThayDoiGia = true,
    ThoiGian_CapNhat = 30,
    TruckerIntegration = {
        AllowedResource = 'lr_trucker_job', CleanCategories = { traicay = true },
    },
    Items = {
        traicay = { coconut = { Label = 'coconut', Min = 50, Max = 100 } },
        choden = { traidudu = { Label = 'traidudu', Min = 200, Max = 400 } },
    },
    Locations = {},
    RouletteSell = {},
}

local core = {
    Functions = { CreateCallback = function() end },
    Commands = { Add = function() end },
}
exports = setmetatable({}, {
    __call = function(_, name, callback) handlers[name] = callback end,
    __index = function(_, resource)
        if resource == 'qb-core' then return { GetCoreObject = function() return core end } end
        if resource == 'monitors' then
            return { RegisterProtectedEvent = function(_, name, callback)
                protected[name] = callback
            end }
        end
        error('unexpected resource: ' .. tostring(resource))
    end,
})

TriggerEvent = function() end
TriggerClientEvent = function(name, _, ...)
    events[#events + 1] = { name = name, args = { ... } }
end
RegisterNetEvent = function() end
RegisterServerEvent = function() end
AddEventHandler = function() end
GetInvokingResource = function() return 'lr_trucker_job' end
Wait = function() end
Citizen = {
    Wait = function() end,
    CreateThread = function(callback) threads[#threads + 1] = callback end,
}
MySQL = {
    ready = function(callback) callback() end,
    query = { await = function() return {} end },
    update = { await = function() return 1 end },
    transaction = { await = function(queries)
        for _, query in ipairs(queries) do
            if query.query:find('UPDATE xn_sellitem_config', 1, true) then
                local amount, price, category, itemName = table.unpack(query.values)
                assert(category == persisted[itemName].category)
                persisted[itemName].amount, persisted[itemName].price = amount, price
            end
        end
        return true
    end },
}

BuildAdminItemsCache = function() end
UpdateItemPrice = function(category, itemName, price)
    assert(category == persisted[itemName].category)
    persisted[itemName].price = price
    DatabaseConfig[category][itemName].CurrentPrice = price
end
UpdateItemAmountSold = function(category, itemName, amount)
    assert(category == persisted[itemName].category)
    persisted[itemName].sold = persisted[itemName].sold + amount
end
UpdateItemEconomyState = function(category, itemName, price, amount, sold)
    assert(category == persisted[itemName].category)
    local row = persisted[itemName]
    row.price, row.amount, row.sold = price, amount, row.sold + sold
    local cached = DatabaseConfig[category][itemName]
    cached.CurrentPrice, cached.CurrentAmount, cached.AmountSold = row.price, row.amount, row.sold
    return true
end

assert(loadfile('[XN_CODE]/xn-sellitem/server/main.lua'))()

local function findUpvalue(callback, name)
    for index = 1, 100 do
        local key, value = debug.getupvalue(callback, index)
        if not key then break end
        if key == name then return value end
    end
    error('missing upvalue: ' .. name)
end

local sell = findUpvalue(protected['xn-sellitem:cfx:action'], 'ProcessPriceDropOnSell')
local originalRandom = math.random
math.random = function(minimum) return minimum end

assert(DATA.coconut.Price == 77 and DATA.coconut.CurrentAmount == 49)
assert(DATA.custom.Price == 77 and DATA.custom.CurrentAmount == 49,
    'database-only stock price must not snap to a six-step price')
assert(DATA.traidudu.Price == 320, 'choden must retain six-step pricing')

sell('coconut', 1)
assert(DATA.coconut.Price == 76 and DATA.coconut.CurrentAmount == 50)
sell('coconut', 100)
assert(DATA.coconut.Price == 74 and DATA.coconut.CurrentAmount == 150)
assert(persisted.coconut.price == 74 and persisted.coconut.amount == 150 and persisted.coconut.sold == 101)

sell('custom', 1)
assert(DATA.custom.Price == 76 and DATA.custom.CurrentAmount == 50,
    'a non-trucker category must also use persistent stock pricing')
local candidates = handlers.GetCleanDeliveryCandidates()
for _, candidate in ipairs(candidates) do
    assert(candidate.itemName ~= 'custom' and candidate.itemName ~= 'traidudu',
        'stock pricing must not expand trucker delivery eligibility')
end

sell('traidudu', 50)
assert(DATA.traidudu.Price == 319 and DATA.traidudu.CurrentAmount == 17,
    'choden must retain its legacy sale pricing')

local reserve = handlers.ReserveCleanDelivery
local settle = handlers.SettleCleanDelivery
assert(reserve({ reservationId = 'order-1', itemName = 'coconut', amount = 50 }).success)
assert(DATA.coconut.Price == 74 and DATA.coconut.CurrentAmount == 150,
    'reserving stock must not change price or amount')
assert(settle({ reservationId = 'order-1', delivered = true }).success)
assert(DATA.coconut.Price == 75 and DATA.coconut.CurrentAmount == 100)
assert(persisted.coconut.price == 75 and persisted.coconut.amount == 100)

assert(reserve({ reservationId = 'order-2', itemName = 'coconut', amount = 50 }).success)
assert(settle({ reservationId = 'order-2', delivered = false }).success)
assert(DATA.coconut.Price == 75 and DATA.coconut.CurrentAmount == 100,
    'cancelled delivery must not change price or amount')

DATA.coconut.Price = DATA.coconut.Min
persisted.coconut.price = DATA.coconut.Min
sell('coconut', 50)
assert(DATA.coconut.Price == DATA.coconut.Min, 'price must not fall below Min')
DATA.coconut.Price = DATA.coconut.Max
persisted.coconut.price = DATA.coconut.Max
assert(reserve({ reservationId = 'order-3', itemName = 'coconut', amount = 50 }).success)
assert(settle({ reservationId = 'order-3', delivered = true }).success)
assert(DATA.coconut.Price == DATA.coconut.Max, 'price must not rise above Max')

local stockPrice, stockAmount = persisted.coconut.price, persisted.coconut.amount
InitEconomy()
assert(DATA.coconut.Price == stockPrice and DATA.coconut.CurrentAmount == stockAmount,
    'restart must restore price and stock from persisted state')

events = {}
local chodenPriceBeforeTick = DATA.traidudu.Price
Citizen.Wait = function(duration) coroutine.yield(duration) end
local scheduled = coroutine.create(threads[#threads])
assert(coroutine.resume(scheduled)) -- initial 30-minute wait
assert(coroutine.resume(scheduled)) -- one scheduled update, then next wait
assert(DATA.coconut.Price == stockPrice and DATA.coconut.CurrentAmount == stockAmount)
assert(DATA.custom.Price == 76 and DATA.custom.CurrentAmount == 50)
assert(DATA.traidudu.Price ~= chodenPriceBeforeTick, 'choden must still update on schedule')
local chodenUpdates = 0
for _, event in ipairs(events) do
    assert(event.name ~= 'xn-sellitem:setPrices', 'scheduled update must not broadcast the full catalog')
    if event.name == 'xn-sellitem:update' then
        assert(event.args[1] == 'traidudu', 'scheduled update touched a stock-priced item')
        chodenUpdates = chodenUpdates + 1
    end
end
assert(chodenUpdates == 1)

local vectorMeta = {}
vectorMeta.__sub = function(first, second)
    return setmetatable({
        x = first.x - second.x, y = first.y - second.y, z = first.z - second.z,
    }, vectorMeta)
end
vectorMeta.__len = function(value)
    return math.sqrt(value.x * value.x + value.y * value.y + value.z * value.z)
end
vector3 = function(x, y, z) return setmetatable({ x = x, y = y, z = z }, vectorMeta) end
GetPlayerPed = function() return 1 end
GetEntityCoords = function() return vector3(0, 0, 0) end
Config.Items.nuoithu = { conheo = {} }
Config.Locations = {{
    Items = Config.Items.traicay,
    ExtraItems = Config.Items.nuoithu,
    Coords = { x = 1, y = 0, z = 0 },
}}
local isNearCategory = findUpvalue(protected['xn-sellitem:cfx:action'], 'IsPlayerNearSellCategory')
assert(isNearCategory(1, 'nuoithu', 5.0), 'livestock must be authorized at the combined merchant')
assert(isNearCategory(1, 'traicay', 5.0), 'produce must stay authorized at the combined merchant')
assert(not isNearCategory(1, 'choden', 5.0), 'black-market goods must stay restricted')
Config.Locations[1].Coords.x = 6
assert(not isNearCategory(1, 'nuoithu', 5.0), 'category sale requires player proximity')

math.random = originalRandom
print('stock_pricing_spec: ok')
