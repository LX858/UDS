-- ============================================
-- RATE LIMITING SYSTEM
-- ============================================
local rateLimits = {}
local RATE_LIMIT_CONFIG = {
    useItem = 5000,        -- 5 giây giữa mỗi lần dùng item
    rehab = 10000,         -- 10 giây giữa mỗi lần request cai nghiện
    setCarried = 2000,     -- 2 giây giữa mỗi lần vác
    treatment = 5000,      -- 5 giây giữa mỗi action điều trị
}

-- Kiểm tra rate limit
local function CheckRateLimit(src, action)
    local key = src .. ':' .. action
    local now = GetGameTimer()
    local cooldown = RATE_LIMIT_CONFIG[action] or 1000
    
    if rateLimits[key] and (now - rateLimits[key]) < cooldown then
        return false -- Bị rate limit
    end
    
    rateLimits[key] = now
    return true
end

-- Cleanup rate limits khi player disconnect
AddEventHandler('playerDropped', function()
    local src = source
    for key in pairs(rateLimits) do
        if key:find('^' .. src .. ':') then
            rateLimits[key] = nil
        end
    end
end)

-- Cache bác sĩ online (cập nhật mỗi 30 giây thay vì loop mỗi request)
local cachedDoctorsOnline = false
local lastDoctorCheck = 0
local DOCTOR_CACHE_TIME = 30000 -- 30 giây

local function IsDoctorOnline()
    local currentTime = GetGameTimer()
    if currentTime - lastDoctorCheck < DOCTOR_CACHE_TIME then
        return cachedDoctorsOnline
    end
    
    -- Cập nhật cache
    lastDoctorCheck = currentTime
    cachedDoctorsOnline = false
    
    local jobName = Config.Job and Config.Job.jobName or 'bacsinghien'
    for _, id in ipairs(GetPlayers()) do
        local ply = exports.qbx_core:GetPlayer(tonumber(id))
        if ply and ply.PlayerData.job and ply.PlayerData.job.name == jobName and ply.PlayerData.job.onduty then
            cachedDoctorsOnline = true
            break
        end
    end
    
    return cachedDoctorsOnline
end

-- Lấy addiction data từ metadata
local function GetAddictionData(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return nil end
    
    local data = Player.PlayerData.metadata.ladudu_addiction
    
    if not data then
        data = {
            isAddicted = false,
            minutesOnlineSinceLastUse = 0,
            withdrawalActive = false
        }
    end
    
    return data
end

-- Lưu addiction data vào metadata + statebag
local function SetAddictionData(source, data)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return false end
    
    -- Update metadata (save to database)
    Player.Functions.SetMetaData('ladudu_addiction', data)
    
    return true
end

-- Hàm xử lý sử dụng điếu đu đủ (dieududu)
local function UsePapayaJoint(src, slot)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return false end

    -- Kiểm tra xem người chơi có 1 gói đu đủ sấy khô hay không
    local requiredItem = Config.RequiredItem or 'goi_dudu_say'
    local driedCount = exports.ox_inventory:GetItemCount(src, requiredItem)
    if not driedCount or driedCount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Bạn cần 1 gói đu đủ sấy khô để sử dụng!',
            type = 'error'
        })
        return false
    end

    -- Lấy thông tin điếu đu đủ trong slot
    local item = nil
    if slot then
        item = exports.ox_inventory:GetSlot(src, slot)
    end

    -- Dự phòng tìm slot đầu tiên chứa dieududu nếu slot truyền vào không hợp lệ
    if not item or item.name ~= Config.AddictiveItem then
        local inventory = exports.ox_inventory:GetInventory(src)
        if inventory and inventory.items then
            for s, it in pairs(inventory.items) do
                if it.name == Config.AddictiveItem then
                    item = it
                    slot = s
                    break
                end
            end
        end
    end

    if not item then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Không tìm thấy điếu đu đủ!',
            type = 'error'
        })
        return false
    end

    -- Trừ 1 gói đu đủ sấy khô
    local driedRemoved = exports.ox_inventory:RemoveItem(src, requiredItem, 1)
    if not driedRemoved then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Không thể trừ gói đu đủ sấy khô!',
            type = 'error'
        })
        return false
    end

    -- Lấy độ bền hiện tại từ metadata (mặc định 100 nếu chưa có)
    local currentDurability = 100
    if item.metadata and item.metadata.durability then
        currentDurability = item.metadata.durability
    end

    -- Giảm 10% độ bền
    local newDurability = currentDurability - 10

    if newDurability <= 0 then
        -- Xóa hoàn toàn vật phẩm khỏi slot đó khi hết độ bền
        exports.ox_inventory:RemoveItem(src, item.name, 1, nil, slot)
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Điếu đu đủ của bạn đã hỏng hoàn toàn!',
            type = 'warning'
        })
    else
        -- Cập nhật độ bền mới vào slot
        exports.ox_inventory:SetDurability(src, slot, newDurability)
    end

    -- Xử lý nghiện nếu hệ thống nghiện được bật trong config
    if Config.Addiction and Config.Addiction.enabled then
        local chance = Config.AcidAddictionChance or 90
        local roll = math.random(1, 100)

        local metadata = Player.PlayerData.metadata.ladudu_addiction or {
            isAddicted = false,
            minutesOnlineSinceLastUse = 0,
            withdrawalActive = false
        }

        if roll <= chance then
            metadata.isAddicted = true
            metadata.minutesOnlineSinceLastUse = 0
            metadata.withdrawalActive = false
            SetAddictionData(src, metadata)
            TriggerClientEvent('F7_ladudu_addiction:client:startAddictionMonitor', src)
        else
            if metadata.isAddicted then
                metadata.minutesOnlineSinceLastUse = 0
                metadata.withdrawalActive = false
                SetAddictionData(src, metadata)
                TriggerClientEvent('F7_ladudu_addiction:client:startAddictionMonitor', src)
            end
        end
    end

    -- Kích hoạt hiệu ứng hút điếu đu đủ ở phía client
    TriggerClientEvent('F7_ladudu_addiction:client:useEffect', src)

    return true
end

-- Hook vào khi dùng item (Qbox)
exports.qbx_core:CreateUseableItem(Config.AddictiveItem, function(source, item)
    UsePapayaJoint(source, item and item.slot)
end)

-- Event: Khi dùng item từ client (ox_inventory client export)
RegisterNetEvent('F7_ladudu_addiction:server:useItem', function(slot)
    local src = source
    
    -- Rate limit check
    if not CheckRateLimit(src, 'useItem') then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Vui lòng đợi trước khi sử dụng lại!',
            type = 'error'
        })
        return
    end
    
    UsePapayaJoint(src, slot)
end)

-- Export cho ox_inventory (server-side hook)
exports('UseItemServer', function(event, item, inventory, slot, data)
    local src = inventory.id
    if event == 'usingItem' then
        UsePapayaJoint(src, slot)
    end
    return true
end)

-- Callback: Lấy thời gian kể từ lần dùng cuối
lib.callback.register('F7_ladudu_addiction:server:getTimeSinceLast', function(source)
    local addictionData = GetAddictionData(source)
    
    if not addictionData or not addictionData.isAddicted then
        return 0
    end
    
    local timeSinceSeconds = addictionData.minutesOnlineSinceLastUse * 60  -- Chuyển phút sang giây cho client
    
    if Config.Debug then
        local playerName = GetPlayerName(source)
        print(string.format('[DEBUG SERVER] 📊 Player [%s] - Thời gian kể từ lần dùng cuối: %d giây (%d phút) | Withdrawal threshold: %d giây', 
            playerName,
            timeSinceSeconds,
            addictionData.minutesOnlineSinceLastUse,
            Config.Addiction.withdrawalTimeSeconds
        ))
    end
    
    return timeSinceSeconds
end)

-- Event: Request sync state (khi player login)
RegisterNetEvent('F7_ladudu_addiction:server:requestSync', function()
    local src = source
    local addictionData = GetAddictionData(src)
    
    if addictionData then
        TriggerClientEvent('F7_ladudu_addiction:client:syncState', src, addictionData)
    end
end)

-- Event: Thanh toán trước khi cai nghiện
lib.callback.register('F7_ladudu_addiction:server:payForRehab', function(source, rehabType)
    -- Rate limit check
    if not CheckRateLimit(source, 'rehab') then
        return false, 'Vui lòng đợi trước khi thử lại!'
    end
    
    if not Config.Addiction.rehab.open_rehab then
        return false, 'Tính năng cai nghiện qua NPC hiện đang đóng!'
    end
    
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return false, 'Không tìm thấy người chơi' end

    -- Kiểm tra xem có bị nghiện không TRƯỚC KHI trừ tiền
    local addictionData = GetAddictionData(source)
    if not addictionData or not addictionData.isAddicted then
        return false, 'Bạn không bị nghiện!'
    end

    -- Kiểm tra có bác sĩ online không (fresh check, chỉ cần job đúng, không cần onduty)
    local jobName = Config.Job and Config.Job.jobName or 'ambulancejob'
    local doctorOnline = false
    for _, id in ipairs(GetPlayers()) do
        local ply = exports.qbx_core:GetPlayer(tonumber(id))
        if ply and ply.PlayerData.job then
            print('[DEBUG CAI NGHIEN] Player ' .. tostring(id) .. ' job: ' .. tostring(ply.PlayerData.job.name) .. ' | checking against: ' .. jobName)
            if ply.PlayerData.job.name == jobName then
                doctorOnline = true
                break
            end
        end
    end
    print('[DEBUG CAI NGHIEN] doctorOnline = ' .. tostring(doctorOnline) .. ' | jobName check = ' .. jobName)
    if doctorOnline then
        return false, 'Hiện đang có Bác Sĩ online. Vui lòng liên hệ bác sĩ để được hỗ trợ cai nghiện!'
    end

    -- Lấy cost từ config
    local rehabConfig = Config.Addiction.rehab[rehabType] or Config.Addiction.rehab.normal
    local cost = rehabConfig.cost

    -- Kiểm tra tiền
    local cash = Player.Functions.GetMoney('cash')
    local bank = Player.Functions.GetMoney('bank')

    local hasMoney = false
    local paymentType = ''

    if cash >= cost then
        hasMoney = Player.Functions.RemoveMoney('cash', cost, 'ladudu-rehab')
        paymentType = 'tiền mặt'
    elseif bank >= cost then
        hasMoney = Player.Functions.RemoveMoney('bank', cost, 'ladudu-rehab')
        paymentType = 'ngân hàng'
    end

    if not hasMoney then
        return false, 'Không đủ tiền cai nghiện! (Cần $' .. cost .. ')'
    end

    return true, 'Đã thanh toán $' .. cost .. ' từ ' .. paymentType
end)

-- Callback: Kiểm tra tiền bệnh nhân (chỉ check, không trừ, không teleport)
lib.callback.register('mini_hethongnghien:server:checkPatientMoney', function(source, targetId, packageType)
    local Patient = exports.qbx_core:GetPlayer(targetId)
    if not Patient then return false, '???' end

    local rehabConfig = Config.Addiction.rehab[packageType] or Config.Addiction.rehab.normal
    local cost = rehabConfig.cost

    local cash = Patient.Functions.GetMoney('cash')
    local bank = Patient.Functions.GetMoney('bank')

    if cash >= cost or bank >= cost then
        return true, cost
    end

    return false, cost
end)

-- Callback: Bác sĩ teleport bệnh nhân lên giường (chưa trừ tiền)
lib.callback.register('mini_hethongnghien:server:payForPatient', function(source, targetId, packageType)
    local Doctor = exports.qbx_core:GetPlayer(source)
    if not Doctor then return false, 'Không tìm thấy bác sĩ' end
    
    local Patient = exports.qbx_core:GetPlayer(targetId)
    if not Patient then return false, 'Không tìm thấy bệnh nhân' end
    
    -- Kiểm tra bệnh nhân có nghiện không
    local addictionData = GetAddictionData(targetId)
    if not addictionData or not addictionData.isAddicted then
        return false, 'Bệnh nhân không bị nghiện!'
    end

    -- Chỉ teleport bệnh nhân lên giường, chưa trừ tiền
    local bedCoords = Config.Addiction.rehab.bedCoords
    TriggerClientEvent('mini_hethongnghien:client:teleportToBed', targetId, bedCoords)

    TriggerClientEvent('ox_lib:notify', targetId, {
        description = '🛌 Bạn được nhập viện để cái nghiện. Tiền sẽ trừ khi điều trị xông!',
        type = 'inform',
        duration = 5000
    })
    
    return true, 'Bệnh nhân đã được nhập viện'
end)

RegisterNetEvent('F7_ladudu_addiction:server:completeRehab', function(targetId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    -- Nếu là tự động (NPC), kiểm tra xem tính năng có được mở không
    if not targetId and not Config.Addiction.rehab.open_rehab then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Tính năng cai nghiện qua NPC hiện đang đóng!',
            type = 'error'
        })
        return
    end

    -- Nếu là bác sĩ thực hiện cho người khác (targetId), kiểm tra vị trí và job
    if targetId then
        local job = Player.PlayerData.job
        if not job or job.name ~= (Config.Job and Config.Job.jobName or 'bacsinghien') or not job.onduty then
            TriggerClientEvent('ox_lib:notify', src, {
                description = 'Bạn không phải bác sĩ cai nghiện hoặc chưa onduty!',
                type = 'error'
            })
            return
        end
        -- Kiểm tra vị trí
        local zone = Config.DoctorZone
        if zone then
            local ped = GetPlayerPed(src)
            local coords = GetEntityCoords(ped)
            local dist = #(vector3(coords.x, coords.y, coords.z) - vector3(zone.coords.x, zone.coords.y, zone.coords.z))
            if dist > (zone.radius or 10.0) then
                TriggerClientEvent('ox_lib:notify', src, {
                    description = 'Bạn phải đứng trong khu vực chữa trị để thực hiện!',
                    type = 'error'
                })
                return
            end
        end
        -- Thực hiện cho bệnh nhân (targetId)
        local Target = exports.qbx_core:GetPlayer(tonumber(targetId))
        if not Target then return end
        local resetData = {
            isAddicted = false,
            lastUseTime = 0,
            withdrawalActive = false
        }
        SetAddictionData(targetId, resetData)
        TriggerClientEvent('F7_ladudu_addiction:client:rehabSuccess', tonumber(targetId))
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Cai nghiện thành công',
            description = 'Bạn đã chữa trị thành công cho bệnh nhân!',
            type = 'success'
        })
        TriggerClientEvent('ox_lib:notify', tonumber(targetId), {
            title = 'Cai nghiện thành công',
            description = 'Bạn đã được bác sĩ chữa trị!',
            type = 'success'
        })
        return
    end

    -- Nếu tự động (NPC), kiểm tra lại bác sĩ trước khi hoàn tất
    local jobName2 = Config.Job and Config.Job.jobName or 'ambulancejob'
    for _, id in ipairs(GetPlayers()) do
        local ply = exports.qbx_core:GetPlayer(tonumber(id))
        if ply and ply.PlayerData.job and ply.PlayerData.job.name == jobName2 then
            TriggerClientEvent('ox_lib:notify', src, {
                description = 'Hiện đang có Bác Sĩ online. Cai nghiện NPC bị hủy!',
                type = 'error',
                duration = 7000
            })
            return
        end
    end

    local resetData = {
        isAddicted = false,
        lastUseTime = 0,
        withdrawalActive = false
    }
    SetAddictionData(src, resetData)
    TriggerClientEvent('F7_ladudu_addiction:client:rehabSuccess', src)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Cai nghiện thành công',
        description = 'Bạn đã hoàn thành quá trình điều trị!',
        type = 'success'
    })
end)

-- Callback: Check có bác sĩ online không (fresh check, chỉ cần job đúng)
lib.callback.register('F7_ladudu_addiction:server:isDoctorOnline', function()
    local jobName = Config.Job and Config.Job.jobName or 'ambulancejob'
    for _, id in ipairs(GetPlayers()) do
        local ply = exports.qbx_core:GetPlayer(tonumber(id))
        if ply and ply.PlayerData.job and ply.PlayerData.job.name == jobName then
            return true
        end
    end
    return false
end)

-- Init: Load metadata cho players khi resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Sync tất cả players online
    Wait(2000)
    for _, playerId in ipairs(GetPlayers()) do
        local addictionData = GetAddictionData(tonumber(playerId))
        if addictionData then
            TriggerClientEvent('F7_ladudu_addiction:client:syncState', tonumber(playerId), addictionData)
        end
    end
end)

-- ============================================
-- HEAL PLAYER (Chữa trị - $2,000)
-- ============================================
RegisterNetEvent('mini_hethongnghien:server:healPlayer', function()
    local src = source

    -- Rate limit 5 giây
    if not CheckRateLimit(src, 'useItem') then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Vui lòng đợi trước khi chữa trị lại!',
            type = 'error'
        })
        return
    end

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local HEAL_COST = 2000

    -- Kiểm tra và trừ tiền (ưu tiên tiền mặt, sau đó ngân hàng)
    local cash = Player.Functions.GetMoney('cash')
    local bank = Player.Functions.GetMoney('bank')
    local paid = false
    local paymentType = ''

    if cash >= HEAL_COST then
        paid = Player.Functions.RemoveMoney('cash', HEAL_COST, 'npc-heal-treatment')
        paymentType = 'tiền mặt'
    elseif bank >= HEAL_COST then
        paid = Player.Functions.RemoveMoney('bank', HEAL_COST, 'npc-heal-treatment')
        paymentType = 'ngân hàng'
    end

    if not paid then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Không đủ tiền chữa trị! (Cần $' .. HEAL_COST .. ')',
            type = 'error',
            duration = 5000
        })
        return
    end

    -- Hồi đầy máu phía client
    TriggerClientEvent('mini_hethongnghien:client:fullHeal', src)

    TriggerClientEvent('ox_lib:notify', src, {
        title = '❤️ Chữa trị thành công',
        description = string.format('Đã thanh toán $%d từ %s. Sức khỏe đã được hồi phục hoàn toàn!', HEAL_COST, paymentType),
        type = 'success',
        duration = 5000
    })
end)

-- Command để check addiction status (debug)
if Config.Debug then
    RegisterCommand('checkaddiction', function(source)
        local data = GetAddictionData(source)
        -- Debug info removed
    end, false)
    
    RegisterCommand('resetaddiction', function(source)
        SetAddictionData(source, {
            isAddicted = false,
            minutesOnlineSinceLastUse = 0,
            withdrawalActive = false
        })
        TriggerClientEvent('F7_ladudu_addiction:client:stopWithdrawal', source)
        TriggerClientEvent('ox_lib:notify', source, {
            description = 'Addiction reset!',
            type = 'success'
        })
    end, false)
end

-- Command: Check addiction status của người khác (admin/mod only)
RegisterCommand('checknghien', function(source, args, rawCommand)
    -- Kiểm tra quyền admin hoặc mod
    if not IsPlayerAceAllowed(source, 'command.checknghien') and 
       not IsPlayerAceAllowed(source, 'group.admin') and 
       not IsPlayerAceAllowed(source, 'group.mod') then
        TriggerClientEvent('ox_lib:notify', source, {
            description = '❌ Bạn không có quyền sử dụng lệnh này!',
            type = 'error'
        })
        return
    end
    
    -- Kiểm tra tham số
    if not args[1] then
        TriggerClientEvent('ox_lib:notify', source, {
            description = '❌ Sử dụng: /checknghien [pid]',
            type = 'error'
        })
        return
    end
    
    local targetPid = tonumber(args[1])
    if not targetPid then
        TriggerClientEvent('ox_lib:notify', source, {
            description = '❌ PID không hợp lệ!',
            type = 'error'
        })
        return
    end
    
    -- Tìm player theo pid
    local targetId = nil
    local targetPlayer = nil
    
    for _, playerId in ipairs(GetPlayers()) do
        local ply = exports.qbx_core:GetPlayer(tonumber(playerId))
        if ply and ply.PlayerData.pid == targetPid then
            targetId = tonumber(playerId)
            targetPlayer = ply
            break
        end
    end
    
    -- Kiểm tra player có tồn tại không
    if not targetPlayer or not targetId then
        TriggerClientEvent('ox_lib:notify', source, {
            description = '❌ Không tìm thấy người chơi với PID: ' .. args[1] .. ' (player có thể offline)',
            type = 'error'
        })
        return
    end
    
    -- Lấy addiction data
    local addictionData = GetAddictionData(targetId)
    
    if not addictionData then
        TriggerClientEvent('ox_lib:notify', source, {
            description = '❌ Không thể lấy dữ liệu nghiện của người chơi',
            type = 'error'
        })
        return
    end
    
    -- Tính toán thời gian
    local playerName = GetPlayerName(targetId)
    local minutesOnline = addictionData.minutesOnlineSinceLastUse or 0
    local secondsOnline = minutesOnline * 60
    local withdrawalThreshold = Config.Addiction.withdrawalTimeSeconds
    local remainingSeconds = math.max(0, withdrawalThreshold - secondsOnline)
    
    -- Format thời gian để dễ đọc
    local function formatTime(seconds)
        local hours = math.floor(seconds / 3600)
        local mins = math.floor((seconds % 3600) / 60)
        local secs = seconds % 60
        return string.format("%dh %dm %ds", hours, mins, secs)
    end
    
    -- Tạo message
    local status = addictionData.isAddicted and "🔴 CÓ NGHIỆN" or "🟢 KHÔNG NGHIỆN"
    local withdrawalStatus = addictionData.withdrawalActive and "⚠️ ĐANG CÓ TRIỆU CHỨNG" or "✅ BÌNH THƯỜNG"
    
    local message = string.format([[
╔═══════════════════════════════════╗
  TRẠNG THÁI NGHIỆN - %s (PID: %d)
╠═══════════════════════════════════╣
  Trạng Thái: %s
  Triệu Chứng: %s
  Thời Gian Kể Từ Lần Dùng Cuối: %s
  Thời Gian Còn Lại Đến Withdrawal: %s
╚═══════════════════════════════════╝
    ]], 
        playerName, 
        targetPid,
        status,
        withdrawalStatus,
        formatTime(secondsOnline),
        addictionData.isAddicted and formatTime(remainingSeconds) or "N/A"
    )
    
    -- Gửi thông báo cho admin
    TriggerClientEvent('chat:addMessage', source, {
        color = {255, 194, 14},
        multiline = true,
        args = {message}
    })
    
    -- Log vào console nếu debug mode
    if Config.Debug then
        print('[ADMIN CHECK] Player ' .. GetPlayerName(source) .. ' checked addiction status of ' .. playerName)
    end
end, false)

-- ============================================
-- DOCTOR TREATMENT SYSTEM (Server)
-- ============================================

-- Callback: Check if player is addicted
lib.callback.register('mini_hethongnghien:server:isAddicted', function(source, targetId)
    local target = tonumber(targetId) or source
    local addictionData = GetAddictionData(target)
    if not addictionData then return false end
    
    return addictionData.isAddicted or false
end)

-- Event: Set carried state for patient
RegisterNetEvent('mini_hethongnghien:server:setCarried', function(targetId, state)
    local src = source
    
    if not Config.Addiction.rehab.open_rehab then return end
    if not targetId then return end
    
    -- Rate limit check (chỉ khi bắt đầu vác)
    if state and not CheckRateLimit(src, 'setCarried') then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Vui lòng đợi trước khi vác lại!',
            type = 'error'
        })
        return
    end
    
    -- Verify doctor job
    local Doctor = exports.qbx_core:GetPlayer(src)
    if not Doctor then return end
    
    local isDoctor = false
    for _, job in ipairs(Config.Job.allowedJobs) do
        if Doctor.PlayerData.job and Doctor.PlayerData.job.name == job then
            isDoctor = true
            break
        end
    end
    
    if not isDoctor then
        TriggerClientEvent('ox_lib:notify', src, {
            description = '❌ Bạn không phải bác sĩ!',
            type = 'error'
        })
        return
    end
    
    -- Trigger client event for PATIENT (with doctorId)
    TriggerClientEvent('mini_hethongnghien:client:setCarried', targetId, state, src)
    
    -- Trigger client event for DOCTOR (like qbx_police does)
    TriggerClientEvent('mini_hethongnghien:client:carryingPatient', src, state)
end)

-- Event: Teleport patient to treatment bed
RegisterNetEvent('mini_hethongnghien:server:teleportToBed', function(targetId, bedCoords)
    local src = source
    
    if not Config.Addiction.rehab.open_rehab then return end
    if not targetId or not bedCoords then return end
    
    -- Verify doctor
    local Doctor = exports.qbx_core:GetPlayer(src)
    if not Doctor then return end
    
    local isDoctor = false
    for _, job in ipairs(Config.Job.allowedJobs) do
        if Doctor.PlayerData.job.name == job then
            isDoctor = true
            break
        end
    end
    
    if not isDoctor then
        TriggerClientEvent('ox_lib:notify', src, {
            description = '❌ Bạn không phải bác sĩ!',
            type = 'error'
        })
        return
    end
    
    -- Teleport patient
    TriggerClientEvent('mini_hethongnghien:client:teleportToBed', targetId, bedCoords)
end)

-- Event: Make patient lay on bed
RegisterNetEvent('mini_hethongnghien:server:layOnBed', function(targetId)
    local src = source
    
    if not Config.Addiction.rehab.open_rehab then return end
    if not targetId then return end
    
    -- Gửi bedCoords để client force position
    local bedCoords = Config.DoctorTreatment.treatmentBed
    TriggerClientEvent('mini_hethongnghien:client:layOnBed', targetId, bedCoords)
end)

-- Event: Start seizure (bệnh nhân co giựt)
RegisterNetEvent('mini_hethongnghien:server:startSeizure', function(targetId)
    local src = source
    
    if not Config.Addiction.rehab.open_rehab then return end
    if not targetId then return end
    
    TriggerClientEvent('mini_hethongnghien:client:seizure', targetId)
end)

-- Event: Start patient seizure during treatment (giống như cai nghiện NPC)
RegisterNetEvent('mini_hethongnghien:server:startPatientSeizure', function(targetId, duration)
    local src = source
    
    if not Config.Addiction.rehab.open_rehab then return end
    if not targetId or not duration then return end
    
    -- Verify doctor
    local Doctor = exports.qbx_core:GetPlayer(src)
    if not Doctor then return end
    
    local isDoctor = false
    for _, job in ipairs(Config.Job.allowedJobs) do
        if Doctor.PlayerData.job.name == job then
            isDoctor = true
            break
        end
    end
    
    if not isDoctor then 
        return 
    end
    
    -- Trigger client event cho bệnh nhân để bắt đầu co giật
    TriggerClientEvent('mini_hethongnghien:client:startTreatmentSeizure', targetId, duration)
end)

-- Event: Stop patient seizure (khi bác sĩ hủy điều trị)
RegisterNetEvent('mini_hethongnghien:server:stopPatientSeizure', function(targetId)
    local src = source
    
    if not Config.Addiction.rehab.open_rehab then return end
    if not targetId then return end
    
    -- Verify doctor
    local Doctor = exports.qbx_core:GetPlayer(src)
    if not Doctor then return end
    
    local isDoctor = false
    for _, job in ipairs(Config.Job.allowedJobs) do
        if Doctor.PlayerData.job.name == job then
            isDoctor = true
            break
        end
    end
    
    if not isDoctor then return end
    
    -- Trigger client event cho bệnh nhân để dừng co giật
    TriggerClientEvent('mini_hethongnghien:client:stopTreatmentSeizure', targetId)
end)

-- Event: Stop seizure
RegisterNetEvent('mini_hethongnghien:server:stopSeizure', function(targetId)
    local src = source
    
    if not Config.Addiction.rehab.open_rehab then return end
    if not targetId then return end
    
    TriggerClientEvent('mini_hethongnghien:client:stopSeizure', targetId)
end)

-- Event: Cancel treatment (patient notification)
RegisterNetEvent('mini_hethongnghien:server:cancelTreatment', function(targetId)
    local src = source
    
    if not Config.Addiction.rehab.open_rehab then return end
    if not targetId then return end
    
    TriggerClientEvent('ox_lib:notify', targetId, {
        description = '❌ Quy trình điều trị đã bị hủy!',
        type = 'error',
        duration = 5000
    })
    
    -- Stand up patient
    TriggerClientEvent('mini_hethongnghien:client:standUp', targetId)
end)

-- Event: Complete treatment
RegisterNetEvent('mini_hethongnghien:server:completeTreatment', function(targetId, success, packageType)
    local src = source
    
    if not Config.Addiction.rehab.open_rehab then return end
    -- Rate limit check
    if not CheckRateLimit(src, 'treatment') then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Vui lòng đợi trước khi thực hiện lại!',
            type = 'error'
        })
        return
    end
    
    if not targetId then return end
    
    local Doctor = exports.qbx_core:GetPlayer(src)
    local Patient = exports.qbx_core:GetPlayer(targetId)
    
    if not Doctor or not Patient then return end
    
    if success then
        -- Trừ tiền bệnh nhân sau khi điều trị thành công
        local rehabConfig = Config.Addiction.rehab[packageType] or Config.Addiction.rehab.normal
        local cost = rehabConfig.cost
        local cash = Patient.Functions.GetMoney('cash')
        local bank = Patient.Functions.GetMoney('bank')
        local paid = false
        local paymentType = ''
        if cash >= cost then
            paid = Patient.Functions.RemoveMoney('cash', cost, 'doctor-treatment')
            paymentType = 'tiền mặt'
        elseif bank >= cost then
            paid = Patient.Functions.RemoveMoney('bank', cost, 'doctor-treatment')
            paymentType = 'ngân hàng'
        end
        if not paid then
            -- Không đủ tiền thì vẫn coi như có đủ để không block flow, log lại
            print('[WARN] Bệnh nhân ' .. tostring(targetId) .. ' không đủ tiền trừ sau khi điều trị')
        else
            TriggerClientEvent('ox_lib:notify', targetId, {
                description = string.format('💰 Đã thanh toán $%s từ %s cho cai nghiện', cost, paymentType),
                type = 'info',
                duration = 5000
            })
        end

        -- Cure addiction
        SetAddictionData(targetId, {
            isAddicted = false,
            minutesOnlineSinceLastUse = 0,
            withdrawalActive = false
        })

        -- Stop withdrawal effects on client
        TriggerClientEvent('F7_ladudu_addiction:client:stopWithdrawal', targetId)

        -- Trả hoa hồng cho bác sĩ
        local pkgConfig = Config.DoctorTreatment.packages[packageType] or Config.DoctorTreatment.packages.normal
        local commission = pkgConfig.commission or 0
        if commission > 0 then
            Doctor.Functions.AddMoney('cash', commission, 'doctor-commission')
            TriggerClientEvent('ox_lib:notify', src, {
                description = string.format('✅ Điều trị thành công! Hoa hồng: $%s', commission),
                type = 'success',
                duration = 7000
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                description = '✅ Điều trị thành công',
                type = 'success',
                duration = 5000
            })
        end

        -- Notify patient
        TriggerClientEvent('ox_lib:notify', targetId, {
            description = Config.DoctorTreatment.notifications.treatment_success,
            type = 'success',
            duration = 7000
        })
    else
        -- Treatment failed
        TriggerClientEvent('ox_lib:notify', targetId, {
            description = Config.DoctorTreatment.notifications.treatment_failed,
            type = 'error',
            duration = 5000
        })
        
        TriggerClientEvent('ox_lib:notify', src, {
            description = '❌ Điều trị thất bại',
            type = 'error'
        })
    end
    
    -- Stand up patient after 2 seconds
    Wait(2000)
    TriggerClientEvent('mini_hethongnghien:client:standUp', targetId)
end)

-- ============================================
-- PLAYTIME TRACKER (Chỉ tính khi online)
-- ============================================

-- Invalidate doctor cache khi có người toggle duty
AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
    local jobName = Config.Job and Config.Job.jobName or 'bacsinghien'
    if job and job.name == jobName then
        lastDoctorCheck = 0 -- Reset cache để check lại ngay
    end
end)

-- Mỗi phút tăng minutesOnlineSinceLastUse cho tất cả người nghiện đang online
CreateThread(function()
    while true do
        Wait(60000) -- Mỗi 60 giây (1 phút)
        
        if Config.Addiction and Config.Addiction.enabled then
            if Config.Debug then
                print('[DEBUG SERVER] ⏰ Chạy chu kỳ tăng thời gian nghiện (mỗi 1 phút)...')
            end
            
            for _, playerId in ipairs(GetPlayers()) do
                local src = tonumber(playerId)
                if src then
                    local addictionData = GetAddictionData(src)
                    if addictionData and addictionData.isAddicted then
                        -- Tăng thời gian online lên 1 phút
                        addictionData.minutesOnlineSinceLastUse = (addictionData.minutesOnlineSinceLastUse or 0) + 1
                        SetAddictionData(src, addictionData)
                        
                        if Config.Debug then
                            local playerName = GetPlayerName(src)
                            local currentSeconds = addictionData.minutesOnlineSinceLastUse * 60
                            local remaining = Config.Addiction.withdrawalTimeSeconds - currentSeconds
                            print(string.format('[DEBUG SERVER] ⏱️ Player [%s] - Thời gian nghiện: %d phút (%d giây) | Còn lại để withdrawal: %d giây', 
                                playerName,
                                addictionData.minutesOnlineSinceLastUse,
                                currentSeconds,
                                math.max(0, remaining)
                            ))
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================
-- METHADONE SYSTEM (Server)
-- ============================================

-- Qbox Usable Item hook
exports.qbx_core:CreateUseableItem(Config.MethadoneItem or 'methadone', function(source, item)
    TriggerClientEvent('mini_hethongnghien:client:useMethadone', source, item.slot)
end)

-- Event xử lý khi sử dụng Methadone thành công ở client
RegisterNetEvent('mini_hethongnghien:server:useMethadone', function(slot)
    local src = source
    
    -- Rate limit check
    if not CheckRateLimit(src, 'useItem') then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Vui lòng đợi trước khi sử dụng lại!',
            type = 'error'
        })
        return
    end

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    -- 1. Kiểm tra xem người chơi có bị nghiện không trước khi tiếp tục
    local addictionData = GetAddictionData(src)
    if not addictionData or not addictionData.isAddicted then
        TriggerClientEvent('ox_lib:notify', src, {
            description = Config.Notify.methadone_not_addicted or 'Bạn không bị nghiện để sử dụng Methadone!',
            type = 'error'
        })
        return
    end

    -- 2. Kiểm tra xem người chơi có vật phẩm Methadone hay không
    local methadoneItem = Config.MethadoneItem or 'methadone'
    local methadoneCount = exports.ox_inventory:GetItemCount(src, methadoneItem)
    if not methadoneCount or methadoneCount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Bạn không có Methadone!',
            type = 'error'
        })
        return
    end

    -- 3. Trừ 1 Methadone
    local removed = exports.ox_inventory:RemoveItem(src, methadoneItem, 1, nil, slot)
    if not removed then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Không thể trừ Methadone!',
            type = 'error'
        })
        return
    end

    -- 4. Tính tỷ lệ cai nghiện thành công (mặc định 50%)
    local rate = Config.MethadoneSuccessRate or 50
    local roll = math.random(100)

    if roll <= rate then
        -- Cai nghiện thành công
        addictionData.isAddicted = false
        addictionData.minutesOnlineSinceLastUse = 0
        addictionData.withdrawalActive = false
        SetAddictionData(src, addictionData)

        -- Dừng các hiệu ứng thèm thuốc ở client
        TriggerClientEvent('F7_ladudu_addiction:client:stopWithdrawal', src)

        TriggerClientEvent('ox_lib:notify', src, {
            description = Config.Notify.methadone_success or 'Bạn đã cai nghiện thành công nhờ Methadone!',
            type = 'success',
            duration = 7000
        })
    else
        -- Cai nghiện thất bại
        TriggerClientEvent('ox_lib:notify', src, {
            description = Config.Notify.methadone_failed or 'Sử dụng Methadone không mang lại hiệu quả cai nghiện lần này.',
            type = 'error',
            duration = 7000
        })
    end
end)
