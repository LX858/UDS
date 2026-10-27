SwordRewards = { ready = false }

local claimLocks = {}

local function log(message)
    print(('[Zc_SwordFlag] %s'):format(message))
end

local function citizenId(src)
    local player = exports.qbx_core:GetPlayer(src)
    return player and player.PlayerData and player.PlayerData.citizenid
end

local function deliver(src, row)
    if citizenId(src) ~= row.citizenid then return false, 'character changed or disconnected' end
    local success, reason = exports.ox_inventory:AddItem(src, row.item, row.amount)
    if not success then return false, reason end

    local updated = MySQL.update.await(
        'UPDATE zc_swordflag_rewards SET status = ? WHERE id = ? AND citizenid = ? AND status = ?',
        { 'delivered', row.id, row.citizenid, 'pending' }
    )
    if updated ~= 1 then
        log(('CRITICAL: item %s x%d was added but reward row %s could not be marked delivered'):format(
            row.item, row.amount, row.id))
    end
    return true
end

MySQL.ready(function()
    local ok, err = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS zc_swordflag_rewards (
                id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                round_id VARCHAR(80) NOT NULL,
                citizenid VARCHAR(64) NOT NULL,
                item VARCHAR(100) NOT NULL,
                amount INT UNSIGNED NOT NULL,
                status VARCHAR(16) NOT NULL DEFAULT 'pending',
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                UNIQUE KEY uq_round_citizen_item (round_id, citizenid, item),
                KEY idx_citizen_status (citizenid, status)
            )
        ]])
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS zc_swordflag_schedule_runs (
                slot_key VARCHAR(32) NOT NULL PRIMARY KEY,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        ]])
    end)
    if not ok then
        log('Cannot initialize reward/schedule tables: ' .. tostring(err))
        return
    end
    SwordRewards.ready = true
    log('Reward and schedule tables ready')
end)

function SwordRewards.ReserveSlot(slotKey)
    if not SwordRewards.ready then return false, 'database not ready' end
    local ok, affected = pcall(MySQL.update.await,
        'INSERT IGNORE INTO zc_swordflag_schedule_runs (slot_key) VALUES (?)', { slotKey })
    if not ok then return false, tostring(affected) end
    return affected ~= nil and affected ~= 0, nil
end

function SwordRewards.Grant(src, roundId, rewards)
    local cid = citizenId(src)
    if not cid or not SwordRewards.ready then return end
    while claimLocks[cid] do Wait(50) end
    claimLocks[cid] = true
    local grantOk, grantError = pcall(function()
    for _, reward in ipairs(rewards or {}) do
        local item, count = reward.name, tonumber(reward.count)
        if type(item) == 'string' and count and count >= 1 and count % 1 == 0
            and exports.ox_inventory:Items(item) then
            local ok, result = pcall(MySQL.insert.await, [[
                INSERT IGNORE INTO zc_swordflag_rewards (round_id, citizenid, item, amount)
                VALUES (?, ?, ?, ?)
            ]], { roundId, cid, item, count })
            if not ok then
                log(('Cannot reserve reward %s x%d for %s: %s'):format(item, count, cid, tostring(result)))
            else
                local rows = MySQL.query.await([[
                    SELECT id, citizenid, item, amount FROM zc_swordflag_rewards
                    WHERE round_id = ? AND citizenid = ? AND item = ? AND status = 'pending'
                ]], { roundId, cid, item })
                local row = rows and rows[1]
                if row then
                    local given, reason = deliver(src, row)
                    if given then
                        log(('Reward %s (%s): %s x%d'):format(GetPlayerName(src) or 'unknown', cid, item, count))
                    else
                        log(('Queued reward %s x%d for %s: %s'):format(item, count, cid, tostring(reason)))
                        exports.qbx_core:Notify(src,
                            ('Túi đồ không nhận được %s x%d. Dùng /swordflagclaim để nhận sau.'):format(item, count),
                            'inform', 7000)
                    end
                end
            end
        else
            log(('Invalid reward item/count: %s / %s'):format(tostring(item), tostring(count)))
        end
    end
    end)
    claimLocks[cid] = nil
    if not grantOk then error(grantError) end
end

RegisterCommand('swordflagclaim', function(src)
    if src <= 0 or not SwordRewards.ready then return end
    local cid = citizenId(src)
    if not cid or claimLocks[cid] then return end
    claimLocks[cid] = true
    local ok, err = pcall(function()
        local rows = MySQL.query.await([[
            SELECT id, citizenid, item, amount FROM zc_swordflag_rewards
            WHERE citizenid = ? AND status = 'pending' ORDER BY id
        ]], { cid })
        if not rows or #rows == 0 then
            exports.qbx_core:Notify(src, 'Không có thưởng SwordFlag đang chờ.', 'inform', 5000)
            return
        end
        local delivered = 0
        for _, row in ipairs(rows) do
            if citizenId(src) ~= cid then break end
            local success = deliver(src, row)
            if success then delivered = delivered + 1 end
        end
        exports.qbx_core:Notify(src,
            ('Đã nhận %d/%d phần thưởng SwordFlag. Nếu túi đầy, hãy dùng lại /swordflagclaim.'):format(delivered, #rows),
            delivered > 0 and 'success' or 'error', 7000)
    end)
    claimLocks[cid] = nil
    if not ok then log(('Claim failed for %s: %s'):format(cid, tostring(err))) end
end, false)
