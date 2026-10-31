-- ============================================================
--  xn_farming — Chiếm khu (zone capture) cho các ruộng có cấu hình `capture`
--  Trạng thái: idle -> capturing -> held -> idle
--  Server chỉ chạy vòng lặp khi đang có người chiếm; lúc rảnh = 0 chi phí.
-- ============================================================

local QBCore = exports['qb-core']:GetCoreObject()

ZoneCapture = {}

local STATE_KEY = 'xnCapture:'
local KVP_KEY = 'xn_farming:capture:'

local zones = {}
local lastAttempt = {}

-- ==================== GANG ====================
function GetGangName(playerData)
    local gang = playerData and playerData.gang
    local gangName = gang and gang.name
    if gangName == nil then return nil end

    gangName = string.lower(tostring(gangName)):gsub('%s+', '')
    if gangName == ''
        or gangName == 'none'
        or gangName == 'nogang'
        or gangName == 'no_gang'
        or gangName == 'unaffiliated'
        or gangName == 'civilian' then
        return nil
    end

    return gangName
end

local function notify(src, msg, kind)
    TriggerClientEvent('QBCore:Notify', src, msg, kind or 'inform')
end

local function fmtTime(sec)
    sec = math.max(0, math.floor(sec))
    return ('%02d:%02d'):format(sec // 60, sec % 60)
end

local function IsDown(src, player)
    local ped = GetPlayerPed(src)
    if ped == 0 or GetEntityHealth(ped) <= 0 then return true end
    local state = Player(src).state
    if state and state.isDead then return true end
    local md = player.PlayerData and player.PlayerData.metadata
    return md and (md.isdead or md.inlaststand) and true or false
end

local function inZone(ped, z)
    return #(GetEntityCoords(ped) - z.center) <= z.radius
end

-- Đếm thành viên còn sống của gang đang đứng trong zone (lọc gang trước, rẻ nhất)
local function CountAliveMembers(z, gang)
    local alive = 0
    local ids = GetPlayers()
    for i = 1, #ids do
        local src = tonumber(ids[i])
        local player = src and QBCore.Functions.GetPlayer(src)
        if player and GetGangName(player.PlayerData) == gang then
            local ped = GetPlayerPed(src)
            if ped ~= 0 and GetPlayerRoutingBucket(src) == 0 and inZone(ped, z) and not IsDown(src, player) then
                alive = alive + 1
            end
        end
    end
    return alive
end

-- Thông báo cho toàn bộ thành viên gang + người đang đứng trong zone
local function NotifyGangAndZone(z, gang, msg, kind)
    local ids = GetPlayers()
    for i = 1, #ids do
        local src = tonumber(ids[i])
        local player = src and QBCore.Functions.GetPlayer(src)
        if player then
            local send = gang and GetGangName(player.PlayerData) == gang
            if not send then
                local ped = GetPlayerPed(src)
                send = ped ~= 0 and inZone(ped, z)
            end
            if send then notify(src, msg, kind) end
        end
    end
end

-- ==================== STATE ====================
local function publish(zoneId, z)
    local now = os.time()
    for g, untilTs in pairs(z.cd) do
        if untilTs <= now then z.cd[g] = nil end
    end

    GlobalState:set(STATE_KEY .. zoneId, {
        phase = z.phase,
        gang = z.gang,
        label = z.label,
        endsAt = z.endsAt,
        cd = z.cd,
    }, true)

    local held = z.phase == 'held'
    SetResourceKvp(KVP_KEY .. zoneId, json.encode({
        held = held,
        gang = held and z.gang or nil,
        label = held and z.label or nil,
        endsAt = held and z.endsAt or nil,
        cd = z.cd,
    }))
end

local function resetToIdle(z)
    z.phase = 'idle'
    z.gang, z.label, z.endsAt = nil, nil, nil
    z.token = z.token + 1
end

local function scheduleExpire(zoneId, z)
    local token = z.token
    SetTimeout(math.max(0, z.endsAt - os.time()) * 1000 + 250, function()
        if z.token ~= token or z.phase ~= 'held' then return end
        local gang = z.gang
        resetToIdle(z)
        local wc = z.cfg.winnerCooldown or 0
        if wc > 0 then z.cd[gang] = os.time() + wc end
        publish(zoneId, z)
        NotifyGangAndZone(z, gang, 'Thời gian chiếm giữ khu vực đã kết thúc. Khu vực mở lại cho mọi người!', 'inform')
    end)
end

local function cancelCapture(zoneId, z, reason)
    local gang = z.gang
    resetToIdle(z)
    z.cd[gang] = os.time() + z.cfg.cooldown
    publish(zoneId, z)
    NotifyGangAndZone(z, gang, ('Chiếm khu bị hủy: %s. Bị khóa chiếm khu %d phút!'):format(reason, z.cfg.cooldown // 60), 'error')
end

local function succeedCapture(zoneId, z)
    local gang, label = z.gang, z.label
    z.phase = 'held'
    z.endsAt = os.time() + z.cfg.holdTime
    z.token = z.token + 1
    publish(zoneId, z)
    scheduleExpire(zoneId, z)
    NotifyGangAndZone(z, gang, ('Xã đoàn %s đã chiếm khu vực thành công! Chỉ xã đoàn này được trồng/khai thác trong %d phút.'):format(label, z.cfg.holdTime // 60), 'success')
end

local function captureLoop(zoneId, z, token)
    CreateThread(function()
        local tick = z.cfg.tickMs or 1000
        while z.phase == 'capturing' and z.token == token do
            Wait(tick)
            if z.phase ~= 'capturing' or z.token ~= token then return end

            if CountAliveMembers(z, z.gang) < z.cfg.keepMembers then
                cancelCapture(zoneId, z, 'toàn bộ thành viên đã gục hoặc rời khỏi khu vực')
                return
            end
            if os.time() >= z.endsAt then
                succeedCapture(zoneId, z)
                return
            end
        end
    end)
end

-- ==================== API CHO HỆ THỐNG TRỒNG CÂY ====================
-- Khu có chiếm khu: chỉ gang đang giữ khu (còn hạn) mới được thao tác.
-- Đặt requireOwner = false trong config.capture để khu trống ai cũng được thao tác.
local function isLockedForGang(z, gang)
    if z.phase == 'held' and z.endsAt and z.endsAt > os.time() then
        return z.gang ~= gang
    end
    return z.cfg.requireOwner ~= false
end

-- Tìm người chơi online theo pid (pid có thể khác citizenid), có cache pid -> src
local pidToSrc = {}

local function findPlayerByPid(pid)
    local cached = pidToSrc[pid]
    if cached then
        local p = QBCore.Functions.GetPlayer(cached)
        if p and (p.PlayerData.pid or p.PlayerData.citizenid) == pid then return p end
        pidToSrc[pid] = nil
    end

    local ids = GetPlayers()
    for i = 1, #ids do
        local src = tonumber(ids[i])
        local p = src and QBCore.Functions.GetPlayer(src)
        if p and (p.PlayerData.pid or p.PlayerData.citizenid) == pid then
            pidToSrc[pid] = src
            return p
        end
    end
    return nil
end

function ZoneCapture.IsLockedFor(playerId, zoneId)
    local z = zones[tonumber(zoneId) or zoneId]
    if not z then return false end
    if z.phase == 'held' then
        local player = findPlayerByPid(playerId)
        return isLockedForGang(z, player and GetGangName(player.PlayerData))
    end
    return isLockedForGang(z, nil)
end

function ZoneCapture.IsLockedForSource(src, zoneId)
    local z = zones[tonumber(zoneId) or zoneId]
    if not z then return false end
    local player = QBCore.Functions.GetPlayer(src)
    return isLockedForGang(z, player and GetGangName(player.PlayerData))
end

function ZoneCapture.GetLockMessage(zoneId)
    local z = zones[tonumber(zoneId) or zoneId]
    if not z then return 'Bạn không thể thao tác ở khu vực này!' end
    if z.phase == 'held' and z.endsAt and z.endsAt > os.time() then
        return ('Khu vực đang bị xã đoàn %s chiếm giữ (còn %s). Bạn không thể thao tác!'):format(z.label or '?', fmtTime(z.endsAt - os.time()))
    end
    return 'Khu vực chưa có xã đoàn sở hữu! Hãy chiếm khu (bấm E tại vòng tròn đỏ) trước khi trồng/khai thác.'
end

function ZoneCapture.NotifyLocked(src, zoneId)
    notify(src, ZoneCapture.GetLockMessage(zoneId), 'error')
end

-- ==================== BẮT ĐẦU CHIẾM ====================
RegisterNetEvent('xn_farming:zone:startCapture', function(zoneId)
    local src = source
    zoneId = tonumber(zoneId)
    local z = zoneId and zones[zoneId]
    if not z then return end

    local now = os.time()
    if (lastAttempt[src] or 0) > now - 2 then return end
    lastAttempt[src] = now

    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local gang = GetGangName(player.PlayerData)
    if not gang then
        return notify(src, 'Bạn cần thuộc một xã đoàn để chiếm khu vực!', 'error')
    end

    local ped = GetPlayerPed(src)
    if ped == 0 or IsDown(src, player) then return end

    local pos = GetEntityCoords(ped)
    if #(vector2(pos.x, pos.y) - vector2(z.center.x, z.center.y)) > z.cfg.markerRadius + 2.0
        or math.abs(pos.z - z.center.z) > 6.0 then
        return
    end

    if z.phase == 'held' and z.endsAt > now then
        return notify(src, ('Khu vực đang bị xã đoàn %s chiếm giữ, còn %s!'):format(z.label, fmtTime(z.endsAt - now)), 'error')
    elseif z.phase == 'capturing' then
        return notify(src, ('Xã đoàn %s đang chiếm khu vực này!'):format(z.label), 'error')
    end

    local cdUntil = z.cd[gang]
    if cdUntil and cdUntil > now then
        return notify(src, ('Xã đoàn của bạn đang bị khóa chiếm khu, còn %s!'):format(fmtTime(cdUntil - now)), 'error')
    end

    local alive = CountAliveMembers(z, gang)
    if alive < z.cfg.minMembers then
        return notify(src, ('Cần tối thiểu %d thành viên xã đoàn trong khu vực (hiện có %d)!'):format(z.cfg.minMembers, alive), 'error')
    end

    z.phase = 'capturing'
    z.gang = gang
    z.label = (player.PlayerData.gang and player.PlayerData.gang.label) or string.upper(gang)
    z.endsAt = now + z.cfg.captureTime
    z.token = z.token + 1
    publish(zoneId, z)
    captureLoop(zoneId, z, z.token)

    NotifyGangAndZone(z, gang, ('Xã đoàn %s bắt đầu chiếm khu vực! Hoàn tất sau %d phút.'):format(z.label, z.cfg.captureTime // 60), 'warning')
end)

AddEventHandler('playerDropped', function()
    lastAttempt[source] = nil
end)

-- ==================== KHỞI TẠO ====================
CreateThread(function()
    for zoneId, zone in pairs(FarmRental and FarmRental.FarmZones or {}) do
        if zone.capture and zone.center and zone.radius then
            local z = {
                cfg = zone.capture,
                center = zone.center,
                radius = zone.radius,
                phase = 'idle',
                cd = {},
                token = 0,
            }
            zones[zoneId] = z

            local raw = GetResourceKvpString(KVP_KEY .. zoneId)
            local saved = raw and json.decode(raw)
            if saved then
                local now = os.time()
                for g, untilTs in pairs(saved.cd or {}) do
                    if untilTs > now then z.cd[g] = untilTs end
                end
                if saved.held and saved.endsAt and saved.endsAt > now then
                    z.phase, z.gang, z.label, z.endsAt = 'held', saved.gang, saved.label, saved.endsAt
                    scheduleExpire(zoneId, z)
                end
            end
            publish(zoneId, z)
        end
    end
end)

local function resetZone(zoneId, z)
    resetToIdle(z)
    z.cd = {}
    publish(zoneId, z)
    NotifyGangAndZone(z, nil, 'Admin đã đặt lại khu vực về trạng thái trống!', 'inform')
end

local function isAdmin(src)
    if src == 0 or IsPlayerAceAllowed(src, 'command') then return true end
    local ok, allowed = pcall(function()
        return QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god')
    end)
    return ok and allowed and true or false
end

-- Lệnh admin: /resetkhu [zoneId] — đưa khu về trạng thái trống, xóa khóa chiếm & cooldown.
-- Không có zoneId thì reset tất cả khu có cấu hình chiếm.
local function resetCommand(src, args)
    local function reply(msg, kind)
        if src == 0 then print(msg) else notify(src, msg, kind) end
    end
    if not isAdmin(src) then return reply('Bạn không có quyền dùng lệnh này!', 'error') end

    local zoneId = tonumber(args[1])
    if zoneId then
        local z = zones[zoneId]
        if not z then return reply(('Khu #%d không có cấu hình chiếm khu!'):format(zoneId), 'error') end
        resetZone(zoneId, z)
        return reply(('Đã reset khu #%d về trạng thái trống'):format(zoneId), 'success')
    end

    local n = 0
    for id, z in pairs(zones) do
        resetZone(id, z)
        n = n + 1
    end
    reply(('Đã reset %d khu về trạng thái trống'):format(n), 'success')
end

RegisterCommand('resetkhu', resetCommand, false)
RegisterCommand('xn_resetcapture', resetCommand, false)
