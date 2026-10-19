local function equal(actual, expected, reason)
    assert(actual == expected, (reason or 'different') .. ': ' .. tostring(actual) .. ' ~= ' .. tostring(expected))
end

Config = {
    PlayerOwnedGasStationsEnabled = true,
    EnableTruckerjob = true,
    MaxFuelReserves = 1000,
    GasStations = { { label = 'Trạm A', pedcoords = { x = 1, y = 2, z = 3, w = 90 } } },
}
local station = { owner = 'cid', balance = 1000, fuel = 0 }
local ledger = {}
local caller = 'lr_trucker_job'
GetInvokingResource = function() return caller end
QBCore = { Functions = { GetPlayer = function(src)
    if src == 1 then return { PlayerData = { citizenid = 'cid' } } end
end } }

MySQL = {
    single = { await = function(query, params)
        if query:find('SELECT station.owner', 1, true) then
            if params[2] == 1 then return { owner = station.owner, employee_access = 0 } end
            return nil
        end
        if query:find('SELECT label, balance, fuel', 1, true) then
            return { label = 'Trạm A', balance = station.balance, fuel = station.fuel }
        end
        local row = ledger[params[1]]
        if row and params[2] and params[2] ~= row.location then return nil end
        return row
    end },
    update = { await = function(query, params)
        if query:find('INSERT IGNORE INTO fuel_station_procurement_ledger', 1, true) then
            if ledger[params[1]] then return 0 end
            ledger[params[1]] = { location = params[2], amount = params[3] }
            return 1
        end
        if query:find('SET station.balance = station.balance - ledger.amount', 1, true) then
            local row = ledger[params[1]]
            if not row or row.location ~= params[2] or row.debited_at or row.refunded_at
                or station.balance < row.amount then return 0 end
            station.balance = station.balance - row.amount
            row.debited_at = 1
            return 1
        end
        if query:find('UPDATE fuel_station_procurement_ledger SET refunded_at', 1, true) then
            local row = ledger[params[1]]
            if not row or row.location ~= params[2] or row.debited_at
                or row.refunded_at or row.delivery_id then return 0 end
            row.refunded_at = 1
            return 1
        end
        if query:find('SET station.balance = station.balance + ledger.amount', 1, true) then
            local row = ledger[params[1]]
            if not row or row.location ~= params[2] or not row.debited_at
                or row.refunded_at or row.delivery_id then return 0 end
            station.balance = station.balance + row.amount
            row.refunded_at = 1
            return 1
        end
        if query:find('SET station.fuel = station.fuel + ?', 1, true) then
            local row = ledger[params[1]]
            local liters = params[2]
            if not row or row.location ~= params[4] or not row.debited_at
                or row.refunded_at or row.delivery_id or station.fuel + liters > params[6] then return 0 end
            station.fuel = station.fuel + liters
            row.delivery_id = params[3]
            return 2 -- MySQL may count both updated tables.
        end
        error('unexpected SQL: ' .. query)
    end },
}

local registered = {}
exports = setmetatable({ ['qb-core'] = { GetCoreObject = function() return QBCore end } }, {
    __call = function(_, name, fn) registered[name] = fn end,
})
dofile('../../[assets]/cdn-fuel/server/procurement_sv.lua')

local stations = registered.GetProcurementStations()
equal(#stations, 1)
equal(registered.IsTruckerjobEnabled(), true)
equal(stations[1].businessId, 'gas_station_1')
equal(registered.GetProcurementContext({ source = 1, location = 1 }).balance, 1000)
equal(registered.GetProcurementContext({ source = 2, location = 1 }), nil, 'unauthorized employee')

caller = 'foreign_resource'
equal(#registered.GetProcurementStations(), 0, 'foreign station access')
equal(registered.IsTruckerjobEnabled(), false, 'foreign integration status')
equal(registered.DebitProcurementOrder({ source = 1, location = 1, orderId = 'a', amount = 200 }), false)
caller = 'lr_trucker_job'

local function debit(id, amount)
    return registered.DebitProcurementOrder({ source = 1, location = 1, orderId = id, amount = amount })
end
equal(debit('a', 200), true)
equal(station.balance, 800)
equal(debit('a', 200), true, 'idempotent debit')
equal(station.balance, 800, 'duplicate charge')
equal(debit('a', 300), false, 'order id collision')
equal(registered.CreditProcurementDelivery({ location = 1, orderId = 'a', deliveryId = 'a:fuel', liters = 20 }), true)
equal(station.fuel, 20)
equal(registered.CreditProcurementDelivery({ location = 1, orderId = 'a', deliveryId = 'a:fuel', liters = 20 }), true)
equal(station.fuel, 20, 'duplicate delivery')
equal(registered.RefundProcurementOrder({ location = 1, orderId = 'a' }), false, 'refund after delivery')

equal(debit('b', 100), true)
equal(station.balance, 700)
Config.EnableTruckerjob = false
equal(registered.IsTruckerjobEnabled(), false, 'disabled new orders')
equal(#registered.GetProcurementStations(), 1, 'existing order cancellation point hidden')
equal(registered.GetProcurementContext({ source = 1, location = 1 }).balance, 700)
equal(debit('c', 100), false, 'disabled new order')
equal(registered.RefundProcurementOrder({ location = 1, orderId = 'b' }), true, 'refund while disabled')
equal(registered.RefundProcurementOrder({ location = 1, orderId = 'b' }), true, 'idempotent refund')
equal(station.balance, 800, 'duplicate refund')
equal(registered.CreditProcurementDelivery({ location = 1, orderId = 'b', deliveryId = 'b:fuel', liters = 20 }), false)
print('PASS fuel procurement authorization, ledger and disable switch')
