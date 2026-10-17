local config = require 'config.client'
local sharedConfig = require 'config.shared'
local WEAPONS = exports.qbx_core:GetWeapons()

---blocks until ped is no longer moving
function WaitForPlayerToStopMoving()
    local timeOut = 10000
    while GetEntitySpeed(cache.ped) > 0.1 and IsPedRagdoll(cache.ped) and timeOut > 1 do
        timeOut -= 10 Wait(10)
    end
end

--- low level GTA resurrection
function ResurrectPlayer()
    local pos = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)

    NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z + 0.5, heading, true, false)
    if cache.vehicle then
        SetPedIntoVehicle(cache.ped, cache.vehicle, cache.seat)
    end
end

---remove last stand mode from player.
function EndLastStand()
    TaskPlayAnim(cache.ped, LastStandDict, 'exit', 1.0, 8.0, -1, 1, -1, false, false, false)
    LaststandTime = 0
    TriggerServerEvent('qbx_medical:server:onPlayerLaststandEnd')
end

-- --count down last stand, if last stand is over, put player in death mode and log the killer.
-- local function countdownLastStand()
--     if LaststandTime > 0 then
--         LaststandTime -= 1
--     end
    
--     -- Khi đếm ngược về 0, chuyển sang trạng thái DEAD (Bạn đã nhập hòm)
--     if LaststandTime <= 0 then
--         LaststandTime = 0
--         -- EndLastStand()
--         -- DeathTime = config.deathTime
--         -- OnDeath(nil, nil)
--     end
-- end

---count down last stand, if last stand is over, put player in death mode and log the killer.
local function countdownLastStand()
    if LaststandTime - 1 > 0 then
        LaststandTime -= 1
    else
        LaststandTime = 0
        if not exports.qbx_medical:IsInRedZone() then
            SetEntityHealth(cache.ped, 0)
        end
    end
end


-- -- Lệnh kiểm tra máu và trạng thái nhân vật
RegisterCommand('checkhp', function()
    local ped = cache.ped
    local currentHealth = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    local healthPercent = (currentHealth / maxHealth) * 100
    
    -- Kiểm tra trạng thái chết
    local isDead = IsEntityDead(ped)
    local isInLastStand = false
    local deathState = "Bình thường"
    
    -- Kiểm tra trạng thái Last Stand (nếu có)
    if DeathState then
        if DeathState == sharedConfig.deathState.LAST_STAND then
            isInLastStand = true
            deathState = "LAST STAND"
        elseif DeathState == sharedConfig.deathState.DEAD then
            deathState = "ĐÃ CHẾT"
        end
    end
    
    -- Kiểm tra máu = 0 nhưng chưa chết (có thể đang Last Stand)
    if currentHealth == 0 and not isDead then
        deathState = "LAST STAND (máu = 0)"
    end
    
    -- In thông tin chi tiết
    print("\n========== THÔNG TIN NHÂN VẬT ==========")
    print(string.format("❤️ Máu hiện tại: %d / %d", currentHealth, maxHealth))
    print(string.format("📊 Phần trăm máu: %.1f%%", healthPercent))
    print(string.format("💀 Trạng thái chết: %s", isDead and "ĐÃ CHẾT" or "CÒN SỐNG"))
    print(string.format("🔄 Death State: %s", deathState))
    
    if isInLastStand then
        print(string.format("⏱️ Thời gian Last Stand còn lại: %d giây", LaststandTime or 0))
    end
    
    -- Kiểm tra các trường hợp đặc biệt
    if isDead then
        print("❌ NHÂN VẬT ĐÃ CHẾT - Cần hồi sinh!")
        exports.qbx_core:Notify('❌ Nhân vật đã chết! Cần hồi sinh.', 'error')
    elseif currentHealth == 0 and not isDead then
        print("⚠️ NHÂN VẬT ĐANG Ở TRẠNG THÁI LAST STAND!")
        exports.qbx_core:Notify('⚠️ Đang ở trạng thái Last Stand! Cần được cứu.', 'error')
    elseif currentHealth < (maxHealth * 0.2) then
        print("⚠️ CẢNH BÁO: Máu quá thấp!")
        exports.qbx_core:Notify(string.format('⚠️ Cảnh báo: Máu chỉ còn %.1f%%', healthPercent), 'error')
    else
        exports.qbx_core:Notify(string.format('❤️ HP: %d/%d (%.1f%%) - Trạng thái: %s', 
            currentHealth, maxHealth, healthPercent, 
            isDead and "Đã chết" or "Sống"
        ), 'info')
    end
    
    print("==========================================\n")
    
end, false)

local startLastStandLock = false

---put player in last stand mode and notify EMS.
function StartLastStand(attacker, weapon)
    if startLastStandLock then return end
    startLastStandLock = true
    TriggerEvent('ox_inventory:disarm', cache.playerId, true)
    WaitForPlayerToStopMoving()
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'demo', 0.1)
    LaststandTime = config.timewait or config.laststandReviveInterval
    ResurrectPlayer()
    SetEntityHealth(cache.ped, 150)

    -- BỎ invincible để có thể chết khi bị tấn công thêm
    -- SetEntityInvincible(cache.ped, true)

    SetDeathState(sharedConfig.deathState.LAST_STAND)
    TriggerEvent('qbx_medical:client:onPlayerLaststand', attacker, weapon)

    -- Convert attacker ped to source server ID
    local attackerSource = nil
    if attacker and attacker ~= 0 and attacker ~= cache.ped then
        local attackerPlayerId = NetworkGetPlayerIndexFromPed(attacker)
        if attackerPlayerId and attackerPlayerId ~= -1 then
            attackerSource = GetPlayerServerId(attackerPlayerId)
        end
    end

    TriggerServerEvent('qbx_medical:server:onPlayerLaststand', attackerSource, weapon)
    CreateThread(function()
        while DeathState == sharedConfig.deathState.LAST_STAND do
            local currentHp = GetEntityHealth(cache.ped)
            if currentHp <= 100 or IsEntityDead(cache.ped) then
                EndLastStand()
                DeathTime = config.deathTime
                OnDeath(attacker, weapon)
                break
            end
            countdownLastStand()
            Wait(1000)
        end
    end)

    CreateThread(function()
        while DeathState == sharedConfig.deathState.LAST_STAND do
            DisableControls()
            PlayLastStandAnimation()
            Wait(0)
        end

        -- Reset lock khi hết LAST_STAND
        SetEntityInvincible(cache.ped, false)
        startLastStandLock = false
    end)
end

exports('StartLastStand', StartLastStand)
