local QB, ESX
if GetResourceState('qb-core') == 'started' then QB = exports['qb-core']:GetCoreObject()
elseif GetResourceState('es_extended') == 'started' then ESX = exports['es_extended']:getSharedObject() end

local function phoneOf(src)
    if GetResourceState('lb-phone') ~= 'started' then return nil end
    return exports['lb-phone']:GetEquippedPhoneNumber(src)
end

local function player(src)
    if QB then
        local p = QB.Functions.GetPlayer(src); if not p then return end
        local c = p.PlayerData.charinfo
        return {
            id = p.PlayerData.citizenid, name = c.firstname .. ' ' .. c.lastname, phone = phoneOf(src),
            money = function(acc) return p.PlayerData.money[acc] or 0 end,
            remove = function(acc, n) return p.Functions.RemoveMoney(acc, n, 'ubee-taxi') end,
            add = function(acc, n) p.Functions.AddMoney(acc, n, 'ubee-taxi') end,
        }
    elseif ESX then
        local p = ESX.GetPlayerFromId(src); if not p then return end
        local map = { cash = 'money', bank = 'bank' }
        return {
            id = p.identifier, name = p.getName(), phone = phoneOf(src),
            money = function(acc) return p.getAccount(map[acc]).money end,
            remove = function(acc, n)
                if p.getAccount(map[acc]).money < n then return false end
                p.removeAccountMoney(map[acc], n); return true
            end,
            add = function(acc, n) p.addAccountMoney(map[acc], n) end,
        }
    end
end

MySQL.ready(function()
    MySQL.query([[CREATE TABLE IF NOT EXISTS ubee_trips (
        id VARCHAR(36) PRIMARY KEY,
        passenger VARCHAR(64), driver VARCHAR(64), driver_name VARCHAR(100),
        ride VARCHAR(8), pickup VARCHAR(120), dest VARCHAR(120),
        km DECIMAL(8,2), price INT, paid TINYINT(1),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX (passenger), INDEX (driver)
    )]])
end)

local drivers = {}  
local rides = {}    
local passengerRide = {} 

local function uuid()
    return (('xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'):gsub('[xy]', function(c)
        return ('%x'):format(c == 'x' and math.random(0, 15) or math.random(8, 11))
    end))
end

local function pos(src) return GetEntityCoords(GetPlayerPed(src)) end
local function dist2d(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) end

local function fare(r, km) return math.max(Config.MinFare, math.floor(km * Config.Rates[r] + 0.5)) end

local function xy(src) local c = pos(src); return { x = c.x, y = c.y } end

local function view(r)
    if not r then return nil end
    local d = r.driver and drivers[r.driver]
    local live = d and (r.status == 'accepted' or r.status == 'onTrip')
    return {
        driverPos = live and xy(r.driver) or nil, passengerPos = live and xy(r.passenger) or nil,
        id = r.id, status = r.status, ride = r.ride, pickup = r.pickup, dest = r.dest, km = r.km, price = r.price,
        paid = r.paid, at = r.doneAt,
        driver = d and { name = r.driverName, plate = d.plate, phone = r.driverPhone } or (r.driverName and { name = r.driverName }),
        passenger = r.passengerName and { name = r.passengerName, phone = r.passengerPhone },
    }
end

local function push(r)
    if r.passenger then TriggerClientEvent('ubee:ride', r.passenger, view(r)) end
    if r.driver then TriggerClientEvent('ubee:job', r.driver, view(r)) end
end

local function notify(src, title, body)
    if GetResourceState('lb-phone') ~= 'started' then return end
    local appId = (Config.CustomApps and Config.CustomApps['ubee_taxi']) and 'ubee_taxi' or (Config.App and Config.App.id or 'ubee_taxi')
    exports['lb-phone']:SendNotification(src, {
        app = appId,
        title = title,
        content = body
    })
end

local function freeDriver(src)
    local d = drivers[src]; if d then d.job = nil end
end

local function endRide(r, status)
    r.status = status
    push(r)
    passengerRide[r.passenger] = nil
    if r.driver then freeDriver(r.driver) end
    rides[r.id] = nil
end

local function invite(r)
    local best, bestD
    local p = r.pickup
    for src, d in pairs(drivers) do
        if not d.paused and not d.job and d.ride == r.ride and src ~= r.passenger and not r.tried[src] and GetPlayerPing(src) > 0 then
            local dd = dist2d(pos(src), p)
            if not bestD or dd < bestD then best, bestD = src, dd end
        end
    end
    if not best then return false end
    r.tried[best] = true
    r.invitee, r.invitedAt = best, os.time()
    drivers[best].job = r.id
    TriggerClientEvent('ubee:invite', best, view(r))
    notify(best, 'Ubee · Chuyến mới', ('%s → %s · $%d'):format(r.pickup.label, r.dest.label, r.price))
    return true
end

local function skipInvite(r)
    if r.invitee then
        freeDriver(r.invitee)
        TriggerClientEvent('ubee:invite', r.invitee, nil)
        r.invitee = nil
    end
end

local function settle(r)
    local p, d = player(r.passenger), r.driver and player(r.driver)
    local paid = false
    if p then
        paid = (p.money('cash') >= r.price and p.remove('cash', r.price)) or (p.money('bank') >= r.price and p.remove('bank', r.price)) or false
    end
    if paid and d then d.add('bank', math.floor(r.price * Config.DriverShare)) end
    if not paid and p then Config.SendBill(r.passenger, p, d, r, ('Ubee · %s → %s'):format(r.pickup.label, r.dest.label):sub(1, 100)) end
    r.paid = paid
    r.doneAt = os.time()
    MySQL.insert('INSERT INTO ubee_trips (id, passenger, driver, driver_name, ride, pickup, dest, km, price, paid) VALUES (?,?,?,?,?,?,?,?,?,?)',
        { r.id, p and p.id, d and d.id, r.driverName, r.ride, r.pickup.label, r.dest.label, r.km, r.price, paid and 1 or 0 })
end

local function complete(r)
    if r.status ~= 'onTrip' then return end
    settle(r)
    endRide(r, 'done')
end

RegisterNetEvent('ubee:requestRide', function(data)
    local src = source
    if passengerRide[src] or type(data) ~= 'table' or not Config.Rates[data.ride] or type(data.dest) ~= 'table' then return end
    local me = pos(src)
    local pickup = { x = me.x, y = me.y, label = tostring(data.pickupLabel or ''):sub(1, 120) }
    local dest = { x = tonumber(data.dest.x) or 0, y = tonumber(data.dest.y) or 0, label = tostring(data.dest.label or ''):sub(1, 120) }
    local km = math.floor(dist2d(pickup, dest) / 10 + 0.5) / 100
    local p = player(src)
    local r = {
        id = uuid(), passenger = src, passengerName = p and p.name, passengerPhone = p and p.phone,
        ride = data.ride, pickup = pickup, dest = dest, km = km, price = fare(data.ride, km),
        status = 'searching', tried = {}, createdAt = os.time(),
    }
    rides[r.id], passengerRide[src] = r, r.id
    invite(r)
    push(r)
end)

RegisterNetEvent('ubee:cancelRide', function()
    local r = rides[passengerRide[source] or '']
    if not r or r.status == 'onTrip' then return end
    skipInvite(r)
    if r.driver then notify(r.driver, 'Ubee', 'Khách đã hủy chuyến.') end
    endRide(r, 'cancelled')
end)

RegisterNetEvent('ubee:completeRide', function()
    local r = rides[passengerRide[source] or '']
    if r then complete(r) end
end)

RegisterNetEvent('ubee:registerDriver', function(veh)
    local src = source
    if drivers[src] or type(veh) ~= 'table' or not Config.Rates[veh.type] then return end
    local p = player(src)
    if not p or p.money('bank') < Config.RegisterFee or not p.remove('bank', Config.RegisterFee) then
        return TriggerClientEvent('ubee:driver', src, nil, 'Không đủ tiền ngân hàng để đăng ký.')
    end
    drivers[src] = { ride = veh.type, plate = tostring(veh.plate or ''):sub(1, 12), model = tostring(veh.model or ''):sub(1, 40), paused = false }
    TriggerClientEvent('ubee:driver', src, drivers[src])
end)

RegisterNetEvent('ubee:setPaused', function(paused)
    local d = drivers[source]; if not d then return end
    d.paused = paused == true
    TriggerClientEvent('ubee:driver', source, d)
end)

RegisterNetEvent('ubee:unregisterDriver', function()
    local src = source
    local d = drivers[src]
    if not d or (d.job and rides[d.job] and rides[d.job].driver == src) then return end
    drivers[src] = nil
    TriggerClientEvent('ubee:driver', src, nil)
end)

RegisterNetEvent('ubee:answerInvite', function(accept)
    local src = source
    local d = drivers[src]; if not d or not d.job then return end
    local r = rides[d.job]
    if not r or r.invitee ~= src then return end
    r.invitee = nil
    TriggerClientEvent('ubee:invite', src, nil)
    if not accept then
        freeDriver(src)
        return invite(r)
    end
    local p = player(src)
    r.driver, r.driverName, r.driverPhone, r.status = src, p and p.name or 'Tài xế', p and p.phone, 'accepted'
    notify(r.passenger, 'Ubee', ('Tài xế %s đang đến · %s'):format(r.driverName, d.plate))
    push(r)
end)

RegisterNetEvent('ubee:driverCancel', function()
    local src = source
    local d = drivers[src]; local r = d and rides[d.job or '']
    if not r or r.driver ~= src or r.status ~= 'accepted' then return end
    notify(r.passenger, 'Ubee', 'Tài xế đã hủy, đang tìm tài xế khác.')
    freeDriver(src)
    r.driver, r.driverName, r.driverPhone, r.status = nil, nil, nil, 'searching'
    invite(r)
    push(r)
end)

RegisterNetEvent('ubee:contact', function(kind)
    local src = source
    local d = drivers[src]
    local r = rides[passengerRide[src] or ''] or (d and rides[d.job or ''])
    if not r or not r.driver or GetResourceState('lb-phone') ~= 'started' then return end
    local other = r.passenger == src and r.driver or r.passenger
    local number = phoneOf(other)
    if not number then return end
    if kind == 'call' then
        TriggerClientEvent('ubee:makeCall', src, number)
    else
        local myNumber = phoneOf(src) or 'Ubee'
        exports['lb-phone']:SendMessage(myNumber, number, r.passenger == src
            and ('[Ubee] Mình là khách của bạn, đang chờ ở %s.'):format(r.pickup.label)
            or ('[Ubee] Tài xế %s đang đến đón bạn.'):format(r.driverName or ''))
        notify(src, 'Ubee', 'Đã gửi tin nhắn, mở Tin nhắn để trò chuyện tiếp.')
    end
end)

RegisterNetEvent('ubee:history', function(role)
    local src = source
    local p = player(src); if not p then return end
    local col = role == 'driven' and 'driver' or 'passenger'
    MySQL.query(('SELECT id, driver_name, ride, pickup, dest, km, price, paid, UNIX_TIMESTAMP(created_at) AS at FROM ubee_trips WHERE %s = ? ORDER BY created_at DESC LIMIT ?'):format(col),
        { p.id, Config.HistoryLimit }, function(rows)
            TriggerClientEvent('ubee:history', src, role, rows or {})
        end)
end)

local function sendPos(r)
    local d, p = pos(r.driver), pos(r.passenger)
    local v = { math.floor(d.x), math.floor(d.y), math.floor(p.x), math.floor(p.y) }
    local l = r.lastPos
    if l and math.abs(l[1] - v[1]) + math.abs(l[2] - v[2]) + math.abs(l[3] - v[3]) + math.abs(l[4] - v[4]) < 3 then return end
    r.lastPos = v
    TriggerClientEvent('ubee:pos', r.passenger, v[1], v[2], v[3], v[4])
    TriggerClientEvent('ubee:pos', r.driver, v[1], v[2], v[3], v[4])
end

CreateThread(function()
    while true do
        Wait(2000)
        local now = os.time()
        for _, r in pairs(rides) do
            if r.status == 'searching' then
                if r.invitee and now - r.invitedAt >= Config.InviteTimeout then skipInvite(r); invite(r)
                elseif not r.invitee then invite(r) end
                if rides[r.id] and now - r.createdAt >= Config.SearchTimeout then
                    skipInvite(r)
                    notify(r.passenger, 'Ubee', 'Không tìm được tài xế, hãy thử lại.')
                    endRide(r, 'cancelled')
                end
            elseif r.status == 'accepted' then
                local pv = GetVehiclePedIsIn(GetPlayerPed(r.passenger), false)
                local dv = GetVehiclePedIsIn(GetPlayerPed(r.driver), false)
                if pv ~= 0 and pv == dv then
                    r.status, r.startedAt = 'onTrip', now
                    push(r)
                else sendPos(r) end
            elseif r.status == 'onTrip' then
                sendPos(r)
                if dist2d(pos(r.passenger), r.dest) <= Config.ArriveRange then complete(r) end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local r = rides[passengerRide[src] or '']
    if r then
        skipInvite(r)
        if r.status == 'onTrip' then complete(r) else
            if r.driver then notify(r.driver, 'Ubee', 'Khách đã rời thành phố.') end
            endRide(r, 'cancelled')
        end
    end
    local d = drivers[src]
    if d and d.job and rides[d.job] then
        local jr = rides[d.job]
        if jr.invitee == src then jr.invitee = nil
        elseif jr.driver == src then
            if jr.status == 'onTrip' then complete(jr) else
                jr.driver, jr.driverName, jr.status = nil, nil, 'searching'
                push(jr)
            end
        end
    end
    drivers[src] = nil
end)
