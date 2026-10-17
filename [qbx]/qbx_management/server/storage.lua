local config = require 'config.server'

MySQL.query('DELETE FROM `player_jobs_activity` WHERE `last_checkout` < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 8 DAY)) OR `last_checkout` IS NULL')

function OnPlayerCheckOut(clockInPayload)
    local checkOutTime = os.time()
    local checkInTime = clockInPayload.time
    if (checkOutTime - checkInTime) / 60 < config.minOnDutyLogTimeMinutes then
        return
    end

    MySQL.insert("INSERT INTO `player_jobs_activity` (`citizenid`, `job`, `last_checkin`, `last_checkout`) VALUES (?, ?, ?, ?)", {
        clockInPayload.citizenid,
        clockInPayload.job,
        checkInTime,
        checkOutTime,
    })
end

---@param citizenid string
---@param job string
---@return table?
function GetPlayerActivityData(citizenid, job)
    local result = MySQL.single.await('SELECT `last_checkin`, ROUND(COALESCE(SUM(last_checkout-last_checkin) / 3600, 0), 2) AS `hours` FROM `player_jobs_activity` WHERE `citizenid` = ? AND `job` = ? GROUP BY `citizenid`', { citizenid, job })
    return { hours = result?.hours or 0, last_checkin = result?.last_checkin and os.date(config.formatDateTime, result?.last_checkin) or 'N/A' }
end

MySQL.query('CREATE TABLE IF NOT EXISTS `player_job_cooldowns` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `citizenid` VARCHAR(50) NOT NULL, `job` VARCHAR(50) NOT NULL, `fire_type` VARCHAR(20) NOT NULL, `reason` TEXT NULL, `fired_by` VARCHAR(50) NOT NULL, `fired_by_name` VARCHAR(100) NULL, `expire_time` INT NOT NULL, `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (`id`), INDEX `citizenid_expire` (`citizenid`, `expire_time`)) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci;')
MySQL.query('DELETE FROM `player_job_cooldowns` WHERE `expire_time` < UNIX_TIMESTAMP()')

---@param citizenid string
---@param job string
---@param fireType string
---@param reason string?
---@param firedBy string
---@param firedByName string?
---@param expireTime integer
function AddJobCooldown(citizenid, job, fireType, reason, firedBy, firedByName, expireTime)
    MySQL.insert.await('INSERT INTO `player_job_cooldowns` (`citizenid`, `job`, `fire_type`, `reason`, `fired_by`, `fired_by_name`, `expire_time`) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        citizenid,
        job,
        fireType,
        reason,
        firedBy,
        firedByName,
        expireTime,
    })
end

---@param citizenid string
---@return table?
function GetActiveCooldown(citizenid)
    return MySQL.single.await('SELECT * FROM `player_job_cooldowns` WHERE `citizenid` = ? AND `expire_time` > UNIX_TIMESTAMP() ORDER BY `expire_time` DESC LIMIT 1', { citizenid })
end

---@return table
function GetAllActiveCooldowns()
    return MySQL.query.await('SELECT * FROM `player_job_cooldowns` WHERE `expire_time` > UNIX_TIMESTAMP() ORDER BY `expire_time` ASC') or {}
end

---@param id number
---@return number
function RemoveJobCooldown(id)
    return MySQL.update.await('DELETE FROM `player_job_cooldowns` WHERE `id` = ?', { id })
end