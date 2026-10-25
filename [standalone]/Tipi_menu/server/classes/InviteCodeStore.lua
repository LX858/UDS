-- SQL plans use the same oxmysql transaction connection throughout. The guard serializes
-- identity/eligibility changes across resource instances, not only within one Lua process.
InviteCodeStore = {}
local S = InviteCodeStore
local function add(q, sql, args) q[#q + 1] = { query = sql, values = args or {} } end
local function begin()
    return { { query = 'SELECT id FROM tipi_invite_guard WHERE id = 1 FOR UPDATE', values = {} } }
end

-- Compare all historical identifiers, including offline participants. IP is never collected.
S.duplicateSql = [[
 SELECT other.citizenid FROM tipi_invite_fingerprints mine
 JOIN tipi_invite_fingerprints other ON other.kind = mine.kind AND other.fingerprint = mine.fingerprint
 WHERE mine.citizenid = ? AND other.citizenid <> mine.citizenid
 AND (other.citizenid = ? OR EXISTS (
   SELECT 1 FROM tipi_invite_redemptions p WHERE p.invitee = other.citizenid OR p.inviter = other.citizenid))
 GROUP BY other.citizenid
 HAVING SUM(mine.kind = 'license') > 0 OR COUNT(DISTINCT CASE WHEN mine.kind = 'token' THEN mine.fingerprint END) >= 2
 LIMIT 1
]]

function S.coinTarget()
    local c = Config.QBX.coinColumn
    for _, key in ipairs({ 'table', 'idColumn', 'column' }) do
        assert(type(c[key]) == 'string' and c[key]:match('^[%w_]+$'), 'Invalid Coin column configuration')
    end
    return ('`%s`'):format(c.table), ('`%s`'):format(c.idColumn), ('`%s`'):format(c.column)
end

function S.identity(cid, code, licenses, tokens)
    local q = begin()
    add(q, 'INSERT IGNORE INTO tipi_invite_codes (citizenid, code) VALUES (?, ?)', { cid, code })
    for _, entry in ipairs({ { 'license', licenses }, { 'token', tokens } }) do
        for _, value in ipairs(entry[2]) do
            add(q, [[INSERT IGNORE INTO tipi_invite_fingerprints (citizenid, kind, fingerprint)
                VALUES (?, ?, SHA2(?, 256))]], { cid, entry[1], value })
        end
    end
    add(q, 'UPDATE tipi_invite_codes SET identity_ready = ? WHERE citizenid = ?',
        { #licenses > 0 and #tokens >= 2 and 1 or 0, cid })
    return q
end

function S.redeem(cid, inviter, acceptExhausted)
    local q = begin()
    add(q, 'SET @invite_duplicate = (' .. S.duplicateSql .. ')', { cid, inviter })
    add(q, [[INSERT INTO tipi_invite_redemptions (invitee, inviter)
        SELECT me.citizenid, owner.citizenid FROM tipi_invite_codes me
        JOIN tipi_invite_codes owner ON owner.citizenid = ?
        WHERE me.citizenid = ? AND me.citizenid <> owner.citizenid
          AND me.admin_fraud = 0 AND owner.admin_fraud = 0 AND @invite_duplicate IS NULL
          AND NOT EXISTS (SELECT 1 FROM tipi_invite_redemptions r WHERE r.invitee = me.citizenid)
          AND (? = 1 OR (SELECT COUNT(*) FROM tipi_invite_redemptions r
              WHERE r.inviter = owner.citizenid AND r.reward_slot IS NOT NULL) < ?)]],
        { inviter, cid, acceptExhausted and 1 or 0, Config.InviteCode.MaxRewarded })
    return q
end

function S.checkpoint(snapshots)
    local q = {}
    for _, s in ipairs(snapshots) do
        add(q, 'INSERT IGNORE INTO tipi_invite_sessions (session_key, invitee) VALUES (?, ?)', { s.key, s.cid })
        -- Cumulative per-session checkpoints make retries safe even if the commit reply is lost.
        add(q, [[UPDATE tipi_invite_redemptions r JOIN tipi_invite_sessions s ON s.invitee = r.invitee
            SET r.online_seconds = LEAST(?, r.online_seconds + GREATEST(0, ? - s.seconds))
            WHERE s.session_key = ? AND r.qualified_at IS NULL]], { Config.InviteCode.RequiredSeconds, s.seconds, s.key })
        add(q, 'UPDATE tipi_invite_sessions SET seconds = GREATEST(seconds, ?) WHERE session_key = ?', { s.seconds, s.key })
    end
    return q
end

local function validCount(q, inviter)
    add(q, [[SET @invite_valid = (SELECT COUNT(*) FROM tipi_invite_redemptions r
        JOIN tipi_invite_codes c ON c.citizenid = r.invitee
        WHERE r.inviter = ? AND r.qualified_at IS NOT NULL AND r.auto_fraud = 0
          AND c.admin_fraud = 0 AND c.identity_ready = 1)]], { inviter })
end

local function milestones(q, inviter)
    local t, id = S.coinTarget()
    validCount(q, inviter)
    for _, m in ipairs(Config.InviteCode.Milestones) do
        if m.coin > 0 then
            local key = ('milestone:%s:%d'):format(inviter, m.count)
            add(q, ([[INSERT INTO tipi_invite_reward_log (reward_key, citizenid, amount, kind, batch)
                SELECT ?, c.citizenid, ?, 'milestone', @invite_batch FROM tipi_invite_codes c
                JOIN %s p ON p.%s = c.citizenid
                WHERE c.citizenid = ? AND c.admin_fraud = 0 AND @invite_valid >= ?
                  AND NOT EXISTS (SELECT 1 FROM tipi_invite_reward_log WHERE reward_key = ?)]]):format(t, id),
                { key, m.coin, inviter, m.count, key })
        end
    end
end

local function applyCoin(q)
    local t, id, coin = S.coinTarget()
    add(q, ([[UPDATE %s p JOIN (SELECT citizenid, SUM(amount) amount FROM tipi_invite_reward_log
        WHERE batch = @invite_batch GROUP BY citizenid) rewards ON rewards.citizenid = p.%s
        SET p.%s = COALESCE(p.%s, 0) + rewards.amount]]):format(t, id, coin, coin))
end

function S.recheck(cid, inviter)
    local q = begin()
    add(q, 'SET @invite_duplicate = (' .. S.duplicateSql .. ')', { cid, inviter })
    add(q, 'UPDATE tipi_invite_redemptions SET auto_fraud = (@invite_duplicate IS NOT NULL) WHERE invitee = ?', { cid })
    return q
end

function S.award(cid, inviter)
    local q = begin()
    local t, id = S.coinTarget()
    add(q, 'SELECT citizenid FROM tipi_invite_codes WHERE citizenid = ? FOR UPDATE', { inviter })
    add(q, 'SET @invite_batch = UUID()')
    add(q, 'SET @invite_duplicate = (' .. S.duplicateSql .. ')', { cid, inviter })
    add(q, 'UPDATE tipi_invite_redemptions SET auto_fraud = (@invite_duplicate IS NOT NULL) WHERE invitee = ?', { cid })
    add(q, ([[UPDATE tipi_invite_redemptions r
        JOIN tipi_invite_codes me ON me.citizenid = r.invitee
        JOIN tipi_invite_codes owner ON owner.citizenid = r.inviter
        JOIN %s p1 ON p1.%s = r.invitee JOIN %s p2 ON p2.%s = r.inviter
        SET r.qualified_at = COALESCE(r.qualified_at, CURRENT_TIMESTAMP(6))
        WHERE r.invitee = ? AND r.online_seconds >= ? AND r.auto_fraud = 0
          AND me.identity_ready = 1 AND owner.identity_ready = 1
          AND me.admin_fraud = 0 AND owner.admin_fraud = 0]]):format(t, id, t, id), { cid, Config.InviteCode.RequiredSeconds })
    add(q, [[SET @invite_slots = (SELECT COUNT(*) FROM tipi_invite_redemptions
        WHERE inviter = ? AND reward_slot IS NOT NULL)]], { inviter })
    add(q, ([[UPDATE tipi_invite_redemptions r
        JOIN tipi_invite_codes me ON me.citizenid = r.invitee
        JOIN tipi_invite_codes owner ON owner.citizenid = r.inviter
        JOIN %s p1 ON p1.%s = r.invitee JOIN %s p2 ON p2.%s = r.inviter
        SET r.reward_slot = IF(@invite_slots < ?, @invite_slots + 1, NULL),
            r.reward_state = IF(@invite_slots < ?, 'paid', 'exhausted')
        WHERE r.invitee = ? AND r.reward_state = 'pending' AND r.qualified_at IS NOT NULL
          AND r.auto_fraud = 0 AND me.admin_fraud = 0 AND owner.admin_fraud = 0
          AND me.identity_ready = 1 AND owner.identity_ready = 1]]):format(t, id, t, id),
        { Config.InviteCode.MaxRewarded, Config.InviteCode.MaxRewarded, cid })
    for _, reward in ipairs({ { 'invitee', Config.InviteCode.InviteeCoin }, { 'inviter', Config.InviteCode.InviterCoin } }) do
        local kind, amount = reward[1], reward[2]
        add(q, ([[INSERT INTO tipi_invite_reward_log (reward_key, citizenid, amount, kind, batch)
            SELECT CONCAT(?, r.invitee), r.%s, ?, ?, @invite_batch FROM tipi_invite_redemptions r
            WHERE r.invitee = ? AND r.reward_state = 'paid'
              AND NOT EXISTS (SELECT 1 FROM tipi_invite_reward_log WHERE reward_key = CONCAT(?, r.invitee))]]):format(kind),
            { kind .. ':', amount, kind, cid, kind .. ':' })
    end
    milestones(q, inviter)
    applyCoin(q)
    return q
end

function S.fraud(cid, actor, flag, reason)
    local q = begin()
    add(q, 'UPDATE tipi_invite_codes SET admin_fraud = ? WHERE citizenid = ?', { flag and 1 or 0, cid })
    add(q, [[INSERT INTO tipi_invite_fraud_audit (citizenid, actor, flagged, reason)
        VALUES (?, ?, ?, ?)]], { cid, actor, flag and 1 or 0, reason })
    return q
end

function S.reconcile(inviter)
    local q = begin()
    add(q, 'SET @invite_batch = UUID()')
    milestones(q, inviter)
    applyCoin(q)
    return q
end
