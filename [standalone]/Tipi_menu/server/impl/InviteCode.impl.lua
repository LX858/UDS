local Impl = NewImpl('InviteCode')
local S = InviteCodeStore
local sessions, sourceEpoch, identities, retired, limits = {}, {}, {}, {}, {}
local ready, busy, stopping = false, false, false
local startupStage, startupError = 'database', nil
local startupMessages = {
    database = 'Đang kết nối cơ sở dữ liệu mã mời. Vui lòng thử lại sau ít giây.',
    store = 'Thiếu thành phần xử lý mã mời trên server. Vui lòng báo quản trị viên.',
    schema = 'Dữ liệu mã mời chưa sẵn sàng trên database của server. Vui lòng báo quản trị viên.',
    coin = 'Chưa thể xác minh dữ liệu Coin trên server. Vui lòng báo quản trị viên.',
}
local reconcileOwners = {}
local inactive = {}
local alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
local function flag(value) return value == true or tonumber(value) == 1 end

local function player(src)
    local p = GetPlayerFromId(src)
    return p and p.identifier and p or nil
end

local function transaction(q)
    if #q == 0 then return end
    assert(MySQL.transaction.await(q), 'Invite transaction failed')
end

local function exclusive(fn)
    while busy do Wait(10) end
    busy = true
    local ok, result = pcall(fn)
    busy = false
    if not ok then
        print('[Tipi_menu:InviteCode] Operation failed; database work will be retried. Check oxmysql diagnostics.')
        return { ok = false, message = 'Hệ thống mã mời đang bận. Vui lòng thử lại.' }
    end
    return result
end

local function code()
    local out = {}
    for i = 1, 12 do local n = math.random(#alphabet); out[i] = alphabet:sub(n, n) end
    return table.concat(out)
end

local function identity(src)
    local licenses, tokens, seen = {}, {}, {}
    for _, value in ipairs(GetPlayerIdentifiers(src)) do
        local v = value:match('^license2?:(.+)$')
        if v and not seen['l' .. v] then licenses[#licenses + 1] = v; seen['l' .. v] = true end
    end
    for i = 0, GetNumPlayerTokens(src) - 1 do
        local v = GetPlayerToken(src, i)
        if v and v ~= '' and not seen['t' .. v] then tokens[#tokens + 1] = v; seen['t' .. v] = true end
    end
    table.sort(licenses); table.sort(tokens)
    return licenses, tokens, table.concat(licenses, ',') .. '/' .. table.concat(tokens, ',')
end

local function stillPlayer(src, cid, epoch)
    local p = player(src)
    return not stopping and p and p.identifier == cid and (sourceEpoch[src] or 0) == epoch
end

local function syncIdentity(src, cid)
    local licenses, tokens, signature = identity(src)
    signature = signature .. ':' .. src .. ':' .. (sourceEpoch[src] or 0)
    if identities[cid] ~= signature then
        local existing = MySQL.scalar.await('SELECT code FROM tipi_invite_codes WHERE citizenid = ?', { cid })
        -- UUID-like public codes are not authentication secrets. Unique DB index handles collisions.
        transaction(S.identity(cid, existing or code(), licenses, tokens))
        assert(MySQL.scalar.await('SELECT code FROM tipi_invite_codes WHERE citizenid = ?', { cid }), 'Retry invite code collision')
        identities[cid] = signature
        local r = MySQL.single.await('SELECT inviter FROM tipi_invite_redemptions WHERE invitee = ?', { cid })
        if r then transaction(S.recheck(cid, r.inviter)); reconcileOwners[r.inviter] = true end
    end
end

local function snapshot(s, now)
    return { cid = s.cid, key = s.key, seconds = math.max(s.saved or 0, math.max(0, now - s.started)) }
end

local function endSource(src)
    sourceEpoch[src] = (sourceEpoch[src] or 0) + 1
    local now = os.time()
    for cid, s in pairs(sessions) do
        if s.source == src then
            retired[#retired + 1] = snapshot(s, now)
            sessions[cid] = nil
            identities[cid] = nil
        end
    end
    for cid, s in pairs(inactive) do
        if s.source == src then inactive[cid] = nil; identities[cid] = nil end
    end
    limits[src] = nil
end

local function attach(src, started, epoch)
    local p = player(src)
    if not p then return end
    local cid = p.identifier
    if not stillPlayer(src, cid, epoch) then return end
    syncIdentity(src, cid)
    if not stillPlayer(src, cid, epoch) then identities[cid] = nil; return end
    local idle = inactive[cid]
    if idle and idle.source == src and idle.epoch == epoch then return end
    local current = sessions[cid]
    if current and current.source == src then return end
    if current then retired[#retired + 1] = snapshot(current, os.time()); sessions[cid] = nil end
    local r = MySQL.single.await('SELECT qualified_at FROM tipi_invite_redemptions WHERE invitee = ?', { cid })
    if not r or r.qualified_at then inactive[cid] = { source = src, epoch = epoch }; return end
    local key = MySQL.scalar.await('SELECT UUID()')
    if stillPlayer(src, cid, epoch) then
        sessions[cid] = { cid = cid, source = src, key = key, started = started }
    end
end

local function flush()
    local batch, frozen = {}, retired
    retired = {}
    for _, s in ipairs(frozen) do batch[#batch + 1] = s end
    local now = os.time()
    for cid, s in pairs(sessions) do
        local p = player(s.source)
        if not p or p.identifier ~= cid then
            -- Unload events normally freeze the exact end time. Poll fallback never credits
            -- the unobserved interval after the last successful checkpoint.
            batch[#batch + 1] = { cid = cid, key = s.key, seconds = s.saved or 0 }
            sessions[cid] = nil; identities[cid] = nil
        else
            batch[#batch + 1] = snapshot(s, now)
        end
    end
    local ok = pcall(function()
        for first = 1, #batch, 50 do
            local chunk = {}
            for i = first, math.min(first + 49, #batch) do chunk[#chunk + 1] = batch[i] end
            transaction(S.checkpoint(chunk))
        end
    end)
    if not ok then
        -- Retrying an already committed chunk cannot credit its seconds twice.
        for _, s in ipairs(batch) do retired[#retired + 1] = s end
        error('Checkpoint failed')
    end
    for _, s in ipairs(batch) do
        if sessions[s.cid] and sessions[s.cid].key == s.key then sessions[s.cid].saved = s.seconds end
    end
end

local function counts(cid)
    local r = MySQL.single.await([[SELECT
        COALESCE(SUM(r.qualified_at IS NOT NULL AND r.auto_fraud = 0 AND c.admin_fraud = 0 AND c.identity_ready = 1), 0) valid,
        COALESCE(SUM(r.auto_fraud = 1 OR c.admin_fraud = 1), 0) rejected,
        COALESCE(SUM(r.auto_fraud = 0 AND c.admin_fraud = 0 AND (r.qualified_at IS NULL OR c.identity_ready = 0)), 0) pending,
        COALESCE(SUM(r.reward_slot IS NOT NULL), 0) used
        FROM tipi_invite_redemptions r JOIN tipi_invite_codes c ON c.citizenid = r.invitee WHERE r.inviter = ?]], { cid })
    for k, v in pairs(r) do r[k] = tonumber(v) or 0 end
    return r
end

local function redemptionEligibility(cid)
    local playtime = main and main:GetImpl('Playtime')
    if not playtime or type(playtime.GetPlaytimeByCitizenid) ~= 'function' then
        return false, 'Chưa thể kiểm tra giờ chơi hiện tại. Vui lòng thử lại sau.'
    end
    -- Use the Playtime module so the current, unsaved session and VIP-added hours
    -- count toward the entry limit. Invite qualification still uses its own timer.
    local seconds = tonumber(playtime:GetPlaytimeByCitizenid(cid))
    if not seconds or seconds ~= seconds or seconds < 0 then
        return false, 'Chưa thể kiểm tra giờ chơi hiện tại. Vui lòng thử lại sau.'
    end
    local maximum = Config.InviteCode.MaxRedeemPlaytimeSeconds
    if seconds >= maximum then
        return false, ('Bạn đã chơi từ %g tiếng trở lên nên không thể nhập mã mời nữa.'):format(maximum / 3600), seconds
    end
    return true, nil, seconds
end

local function state(cid)
    local own = MySQL.single.await('SELECT code, admin_fraud FROM tipi_invite_codes WHERE citizenid = ?', { cid })
    local c = counts(cid)
    local r = MySQL.single.await([[SELECT r.online_seconds seconds, r.qualified_at, r.reward_state,
        r.auto_fraud, me.admin_fraud, me.identity_ready, owner.admin_fraud owner_fraud,
        owner.identity_ready owner_ready, owner.code, r.inviter
        FROM tipi_invite_redemptions r JOIN tipi_invite_codes me ON me.citizenid = r.invitee
        JOIN tipi_invite_codes owner ON owner.citizenid = r.inviter WHERE r.invitee = ?]], { cid })
    local redemption
    if r then
        local status = 'pending'
        if flag(r.auto_fraud) or flag(r.admin_fraud) or flag(r.owner_fraud) then status = 'rejected'
        elseif not flag(r.identity_ready) or not flag(r.owner_ready) then status = 'verification'
        elseif r.qualified_at then status = r.reward_state == 'exhausted' and 'exhausted' or (r.reward_state == 'paid' and 'qualified' or 'processing') end
        redemption = { code = r.code, seconds = tonumber(r.seconds), status = status, ownerSlotsUsed = counts(r.inviter).used }
    end
    local rewards = MySQL.query.await('SELECT reward_key, amount, kind FROM tipi_invite_reward_log WHERE citizenid = ?', { cid })
    local paid, total = {}, 0
    for _, reward in ipairs(rewards) do paid[reward.reward_key] = true; total = total + tonumber(reward.amount) end
    local milestones = {}
    for _, m in ipairs(Config.InviteCode.Milestones) do
        milestones[#milestones + 1] = { count = m.count, coin = m.coin,
            received = m.coin > 0 and paid[('milestone:%s:%d'):format(cid, m.count)] == true,
            reached = c.valid >= m.count }
    end
    local eligible, blockReason, playtimeSeconds = redemptionEligibility(cid)
    return { ok = true, code = own.code, blocked = flag(own.admin_fraud),
        canRedeem = not redemption and not flag(own.admin_fraud) and eligible,
        redeemBlockReason = not redemption and blockReason or nil,
        playtimeSeconds = playtimeSeconds, maxRedeemPlaytimeSeconds = Config.InviteCode.MaxRedeemPlaytimeSeconds,
        requiredSeconds = Config.InviteCode.RequiredSeconds, maxRewarded = Config.InviteCode.MaxRewarded,
        inviteeCoin = Config.InviteCode.InviteeCoin, inviterCoin = Config.InviteCode.InviterCoin,
        counts = c, redemption = redemption, milestones = milestones, totalCoin = total }
end

local function redeem(src, cid, body)
    local input = type(body) == 'table' and body.code or body
    if type(input) ~= 'string' or #input > 64 then return { ok = false, message = 'Mã mời không hợp lệ.' } end
    input = input:match('^%s*(.-)%s*$'):upper()
    if not input:match('^[A-Z2-9]+$') or #input ~= 12 then return { ok = false, message = 'Mã mời gồm 12 chữ cái hoặc chữ số.' } end
    if MySQL.scalar.await('SELECT id FROM tipi_invite_redemptions WHERE invitee = ?', { cid }) then
        return { ok = false, message = 'Bạn đã nhập mã mời. Không thể thay đổi.' }
    end
    local owner = MySQL.single.await('SELECT citizenid, admin_fraud FROM tipi_invite_codes WHERE code = ?', { input })
    if not owner then return { ok = false, message = 'Mã mời không tồn tại.' } end
    if owner.citizenid == cid then return { ok = false, message = 'Không thể nhập mã mời của chính mình.' } end
    local eligible, blockReason = redemptionEligibility(cid)
    if not eligible then return { ok = false, code = 'invite_playtime_limit', message = blockReason } end
    local confirmed = type(body) == 'table' and body.confirmExhausted == true
    transaction(S.redeem(cid, owner.citizenid, confirmed))
    local saved = MySQL.single.await('SELECT inviter FROM tipi_invite_redemptions WHERE invitee = ?', { cid })
    if not saved then
        local duplicate = MySQL.scalar.await(S.duplicateSql, { cid, owner.citizenid })
        local blocked = MySQL.scalar.await('SELECT admin_fraud FROM tipi_invite_codes WHERE citizenid = ?', { cid })
        if duplicate or flag(blocked) or flag(owner.admin_fraud) then
            return { ok = false, message = 'Tài khoản hoặc mã mời không đủ điều kiện tham gia.' }
        end
        if counts(owner.citizenid).used >= Config.InviteCode.MaxRewarded then
            return { ok = false, needsExhaustedConfirmation = true,
                message = 'Mã này đã hết 50 suất. Nếu tiếp tục, cả bạn và người mời đều không nhận Coin từ lượt này.' }
        end
        return { ok = false, message = 'Chưa thể lưu mã mời. Vui lòng thử lại.' }
    end
    inactive[cid] = nil
    attach(src, os.time(), sourceEpoch[src] or 0)
    local result = state(cid)
    result.message = 'Đã lưu mã mời. Bắt đầu tích lũy 50 giờ online.'
    return result
end

local function awards()
    -- Previously verified entries are processed first; records observed in the same
    -- checkpoint are ordered by redemption id. A failed payout stops overtaking.
    local rows = MySQL.query.await([[SELECT r.invitee, r.inviter FROM tipi_invite_redemptions r
        JOIN tipi_invite_codes c ON c.citizenid = r.invitee
        JOIN tipi_invite_codes owner ON owner.citizenid = r.inviter
        WHERE r.online_seconds >= ? AND r.reward_state = 'pending'
          AND r.auto_fraud = 0 AND c.admin_fraud = 0 AND owner.admin_fraud = 0 AND c.identity_ready = 1 AND owner.identity_ready = 1
        ORDER BY r.qualified_at IS NULL, r.qualified_at, r.id LIMIT 100]], { Config.InviteCode.RequiredSeconds })
    local refresh = {}
    for _, r in ipairs(rows) do
        transaction(S.award(r.invitee, r.inviter))
        refresh[r.invitee] = true; refresh[r.inviter] = true
        sessions[r.invitee] = nil
    end
    for cid in pairs(reconcileOwners) do
        transaction(S.reconcile(cid))
        refresh[cid] = true
        reconcileOwners[cid] = nil
    end
    for cid in pairs(refresh) do RefreshPlayerCoinByCitizenid(cid) end
end

local function initialize()
    startupStage = 'database'
    MySQL.ready.await()
    startupStage = 'store'
    S = InviteCodeStore
    assert(type(S) == 'table' and type(S.coinTarget) == 'function',
        'Missing server/classes/InviteCodeStore.lua; deploy the complete resource')
    startupStage = 'schema'
    assert(MySQL.scalar.await('SELECT id FROM tipi_invite_guard WHERE id = 1'),
        'Invite migration missing in the active oxmysql database; import tools/invite_code.sql')
    MySQL.query.await('SELECT reward_slot, qualified_at FROM tipi_invite_redemptions LIMIT 0')
    MySQL.query.await([[SELECT c.identity_ready, f.fingerprint, s.seconds, l.batch, a.reason
        FROM tipi_invite_codes c LEFT JOIN tipi_invite_fingerprints f ON f.citizenid = c.citizenid
        LEFT JOIN tipi_invite_sessions s ON s.invitee = c.citizenid
        LEFT JOIN tipi_invite_reward_log l ON l.citizenid = c.citizenid
        LEFT JOIN tipi_invite_fraud_audit a ON a.citizenid = c.citizenid LIMIT 0]])
    startupStage = 'coin'
    local t, id, coin = S.coinTarget()
    MySQL.query.await(('SELECT %s, %s FROM %s LIMIT 0'):format(id, coin, t))
    local engine = MySQL.scalar.await([[SELECT ENGINE FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?]], { Config.QBX.coinColumn.table })
    assert(type(engine) == 'string' and engine:upper() == 'INNODB', 'Coin table must use InnoDB')
    startupStage, startupError = 'ready', nil
end

function Impl:OnReady()
    for _, action in ipairs({ 'getState', 'redeem' }) do
        lib.callback.register('Tipi_menu:sv:invite:' .. action, function(src, body)
            if not ready or stopping then
                return { ok = false, code = 'invite_not_ready', retryAfter = 30,
                    message = stopping and 'Hệ thống mã mời đang khởi động lại.'
                        or startupMessages[startupStage] or 'Hệ thống mã mời đang khởi tạo.' }
            end
            local now = os.time()
            limits[src] = limits[src] or {}
            if (limits[src][action] or 0) > now then return { ok = false, message = 'Vui lòng chờ một chút rồi thử lại.' } end
            limits[src][action] = now + (action == 'redeem' and 3 or 1)
            local p = player(src)
            if not p then return { ok = false, message = 'Bạn chưa đăng nhập nhân vật.' } end
            local cid, epoch = p.identifier, sourceEpoch[src] or 0
            return exclusive(function()
                if not stillPlayer(src, cid, epoch) then return { ok = false, message = 'Phiên nhân vật đã thay đổi.' } end
                syncIdentity(src, cid)
                if not stillPlayer(src, cid, epoch) then return { ok = false, message = 'Phiên nhân vật đã thay đổi.' } end
                if action == 'redeem' then return redeem(src, cid, body) end
                return state(cid)
            end)
        end)
    end

    local function loaded(data)
        local src = type(data) == 'table' and (data.PlayerData and data.PlayerData.source or data.source) or tonumber(data)
        if not src then return end
        src = tonumber(src)
        local now, epoch = os.time(), sourceEpoch[src] or 0
        CreateThread(function() if ready then exclusive(function() attach(src, now, epoch) end) end end)
    end
    AddEventHandler('QBCore:Server:PlayerLoaded', loaded)
    AddEventHandler('qbx_core:server:playerLoaded', loaded)
    AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
        endSource(tonumber(src))
        CreateThread(function() if ready then exclusive(flush) end end)
    end)
    AddEventHandler('playerDropped', function()
        endSource(tonumber(source))
        CreateThread(function() if ready then exclusive(flush) end end)
    end)
    AddEventHandler('onResourceStop', function(name)
        if name ~= GetCurrentResourceName() or not ready then return end
        stopping = true
        for _, s in pairs(sessions) do retired[#retired + 1] = snapshot(s, os.time()) end
        -- Resource shutdown may cancel callbacks. Periodic checkpoints remain the durable bound.
        for first = 1, #retired, 50 do
            local chunk = {}
            for i = first, math.min(first + 49, #retired) do chunk[#chunk + 1] = retired[i] end
            MySQL.transaction(S.checkpoint(chunk))
        end
    end)
    RegisterCommand('invitefraud', function(src, args)
        if src ~= 0 and not IsPlayerAceAllowed(src, 'command.invitefraud') then return end
        local cid, mode, reason = args[1], args[2], table.concat(args, ' ', 3)
        local function report(message)
            if src == 0 then print('[InviteCode] ' .. message)
            else TriggerClientEvent('ox_lib:notify', src, { description = message, type = 'inform' }) end
        end
        if not ready or not cid or (mode ~= 'on' and mode ~= 'off') or #reason < 1 or #reason > 512 then
            return report('Cú pháp: /invitefraud <citizenid> <on|off> <lý do tối đa 512 ký tự>')
        end
        local admin = src ~= 0 and player(src)
        local result = exclusive(function()
            if not MySQL.scalar.await('SELECT 1 FROM tipi_invite_codes WHERE citizenid = ?', { cid }) then
                return { ok = false, message = 'Không tìm thấy nhân vật trong hệ thống mã mời.' }
            end
            transaction(S.fraud(cid, admin and admin.identifier or 'console', mode == 'on', reason))
            local r = MySQL.single.await('SELECT inviter FROM tipi_invite_redemptions WHERE invitee = ?', { cid })
            if r then transaction(S.recheck(cid, r.inviter)); reconcileOwners[r.inviter] = true end
            reconcileOwners[cid] = true
            return { ok = true, message = 'Đã cập nhật trạng thái và lưu nhật ký. Coin đã trả và suất đã dùng được giữ nguyên.' }
        end)
        report(result.message)
    end, true)

    RegisterCommand('invitestatus', function(src)
        if src ~= 0 and not IsPlayerAceAllowed(src, 'command.invitestatus') then return end
        local status = ('ready=%s stage=%s resource=%s'):format(tostring(ready), startupStage, GetResourcePath(GetCurrentResourceName()))
        print('[Tipi_menu:InviteCode] ' .. status)
        if startupError then print('[Tipi_menu:InviteCode] Last initialization error: ' .. startupError) end
        if src ~= 0 then TriggerClientEvent('ox_lib:notify', src, {
            description = ready and 'Mã mời đã sẵn sàng.' or startupMessages[startupStage], type = 'inform' }) end
    end, true)

    CreateThread(function()
        local lastError
        while not stopping and not ready do
            local ok, err = pcall(initialize)
            if ok then
                ready = true
                print('[Tipi_menu:InviteCode] Ready: database checks passed.')
            else
                startupError = tostring(err)
                if startupError ~= lastError then
                    print(('[Tipi_menu:InviteCode] Initialization failed at %s: %s. Retrying in 30 seconds.')
                        :format(startupStage, startupError))
                    lastError = startupError
                end
                Wait(30000)
            end
        end
        while not stopping do
            exclusive(function()
                for _, value in ipairs(GetPlayers()) do
                    local src = tonumber(value)
                    attach(src, os.time(), sourceEpoch[src] or 0)
                end
                flush()
                awards()
            end)
            Wait(Config.InviteCode.CheckpointMs)
        end
    end)
end
