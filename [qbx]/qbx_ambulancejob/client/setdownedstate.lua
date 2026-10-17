local config = require 'config.client'
local sharedConfig = require 'config.shared'
local doctorCount = 0

local function getDoctorCount()
    return lib.callback.await('qbx_ambulancejob:server:getNumDoctors')
end

local function displayRespawnText()
    local deathTime = exports.qbx_medical:GetDeathTime()
    
    -- Kiểm tra xem đã ping chưa và có đang trong chế độ tự động respawn không
    local hasPinged = exports.qbx_medical:HasPingedEMS()
    local autoRespawn = exports.qbx_medical:IsAutoRespawnActive()
    
    if autoRespawn and deathTime > 0 then
        -- Đang đếm ngược tự động respawn (không có bác sĩ)
        qbx.drawText2d({ 
            text = 'Không có bác sĩ online. Tự động respawn sau: ' .. math.ceil(deathTime) .. 's', 
            coords = vec2(1.0, 1.44), 
            scale = 0.6 
        })
    elseif hasPinged then
        -- Đã ping và đang đợi bác sĩ
        qbx.drawText2d({ 
            text = 'Đã gọi bác sĩ! Chờ bác sĩ đến cứu...', 
            coords = vec2(1.0, 1.44), 
            scale = 0.6 
        })
    else
        -- Chưa ping, hiển thị hướng dẫn
        qbx.drawText2d({
            text = '[E] Gọi bác sĩ / Ping EMS',
            coords = vec2(1.0, 1.44),
            scale = 0.6
        })
    end
end

---@param ped number
local function playDeadAnimation(ped)
    if IsInHospitalBed then
        if not IsEntityPlayingAnim(ped, InBedDict, InBedAnim, 3) then
            lib.playAnim(ped, InBedDict, InBedAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    else
        exports.qbx_medical:PlayDeadAnimation()
    end
end

---@param ped number
local function handleDead(ped)
    if not IsInHospitalBed then
        displayRespawnText()
    end

    playDeadAnimation(ped)
end

---Player is able to send a notification to EMS there are any on duty
local function handleRequestingEms()
    if not EmsNotified then
        qbx.drawText2d({ text = locale('info.request_help'), coords = vec2(1.0, 1.40), scale = 0.6 })
        if IsControlJustPressed(0, 47) then
            TriggerServerEvent('hospital:server:ambulanceAlert', locale('info.civ_down'))
            EmsNotified = true
        end
    else
        qbx.drawText2d({ text = locale('info.help_requested'), coords = vec2(1.0, 1.40), scale = 0.6 })
    end
end

local function handleLastStand()
    local laststandTime = exports.qbx_medical:GetLaststandTime()
    if laststandTime > config.laststandTimer or doctorCount == 0 then
        qbx.drawText2d({ text = locale('info.bleed_out', math.ceil(laststandTime)), coords = vec2(1.0, 1.44), scale = 0.6 })
    else
        qbx.drawText2d({ text = locale('info.bleed_out_help', math.ceil(laststandTime)), coords = vec2(1.0, 1.44), scale = 0.6 })
        handleRequestingEms()
    end
end

-- ---Set dead and last stand states.
-- CreateThread(function()
--     Wait(1000)
--     while true do
--         local isDead = exports.qbx_medical:IsDead()
--         local inLaststand = exports.qbx_medical:IsLaststand()
--         if isDead or inLaststand then
--             if isDead then
--                 TriggerEvent('ox_inventory:disarm', cache.playerId, true)
--             elseif inLaststand then
--                 TriggerEvent('ox_inventory:disarm', cache.playerId, true)
--             else
--                TriggerEvent('ox_inventory:disarm', cache.playerId, false)
--             end
--         end
--     end
-- end)

-- Callback để kiểm tra trạng thái người chơi hiện tại
lib.callback.register('qbx_ambulancejob:client:isPlayerDownedOrDead', function()
    local isDead = exports.qbx_medical:IsDead()
    local inLaststand = exports.qbx_medical:IsLaststand()
    return isDead or inLaststand
end)
