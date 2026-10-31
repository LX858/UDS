local QBX = exports.qbx_core
local playerLastDamageTime = {}
local playerLastVehicleHit = {}
local lastScreenshotUrl = nil -- Lưu link ảnh screenshot gần nhất

-- Target system active flag
local targetSystemActive = false

-- ox_lib zones system
local forbiddenZones = {}
local isInForbiddenZone = false
local currentZoneName = ""

-- UI state
local isWarningUIOpen = false

-- Hàm hiển thị cảnh báo UI đẹp
local function ShowWarningUI(reputation, reason, displayTime, skipVehiclePenalty)
    local playerData = QBX:GetPlayerData()
    local playerName = playerData.charinfo and (playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname) or 'Unknown'
    
    local ped = PlayerPedId()
    
    -- Chỉ thực hiện vehicle penalties nếu KHÔNG skip
    if not skipVehiclePenalty then
        -- Xử lý khi tông xe: tắt máy, khóa cửa, đẩy ra khỏi xe, freeze
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            
            -- Dừng xe ngay lập tức
            SetVehicleForwardSpeed(vehicle, 0.0)
            SetEntityVelocity(vehicle, 0.0, 0.0, 0.0)
            
            -- Tắt động cơ xe
            SetVehicleEngineOn(vehicle, false, true, true)
            
            -- Khóa cửa xe
            SetVehicleDoorsLocked(vehicle, 2)
            
            -- Đợi một chút để xe dừng hẳn
            Wait(500)
            
            -- Mở cửa và xuống xe bình thường (bên trái)
            TaskLeaveVehicle(ped, vehicle, 256) -- 256 = leave from left side
            
            -- Đợi người chơi xuống xe hoàn toàn
            Wait(2000)
            
            -- Đóng cửa xe
            SetVehicleDoorShut(vehicle, 0, false) -- 0 = driver door (left front)
            
            Wait(500)
        end
    end
    
    -- Luôn freeze và YORA animation cho mọi trường hợp
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_YOGA", 0, true)
    
    -- Tạo thread để giữ YORA animation suốt thời gian UI hiển thị
    local uiDisplayTime = displayTime or Config.ReputationSystem.warningUIDisplayTime or 10
    local startTime = GetGameTimer()
    local duration = uiDisplayTime * 1000 -- Convert to milliseconds
    
    CreateThread(function()
        while isWarningUIOpen do
            Wait(100)
            
            local currentTime = GetGameTimer()
            local elapsedTime = currentTime - startTime
            
            -- Kiểm tra xem animation có bị gián đoạn không
            if not IsPedUsingScenario(ped, "WORLD_HUMAN_YOGA") then
                -- Animation bị gián đoạn, phát lại
                TaskStartScenarioInPlace(ped, "WORLD_HUMAN_YOGA", 0, true)
            end
            
            -- Kiểm tra xem có quá thời gian chưa
            if elapsedTime >= duration then
                break
            end
        end
    end)
    
    local messageData = {
        action = 'showWarning',
        playerName = playerName,
        reputation = reputation,
        maxReputation = Config.ReputationSystem.maxReputation or 100,
        reason = reason or 'Bạn đã vi phạm quy định và bị trừ điểm uy tín!',
        playSound = true,
        displayTime = displayTime or Config.ReputationSystem.warningUIDisplayTime or 10
    }
    
    -- Send data to NUI
    SendNUIMessage(messageData)
    
    isWarningUIOpen = true
end

-- NUI Callback để đóng UI
RegisterNUICallback('closeWarning', function(data, cb)
    -- Hủy animation yoga và unfreeze
    if isWarningUIOpen then
        local ped = PlayerPedId()
        
        -- Unfreeze và clear yoga animation
        FreezeEntityPosition(ped, false)
        ClearPedTasks(ped)
    end
    
    isWarningUIOpen = false
    cb('ok')
end)

-- Hàm kiểm tra khoảng cách
local function getDistance(pos1, pos2)
    return #(pos1 - pos2)
end

-- Hàm kiểm tra xem có trong khu vực KHÔNG bị trừ điểm không (PvP zone tự do)
local function checkNoPenaltyZone(coords)
    if not coords then return false end
    for _, zone in ipairs(Config.ReputationSystem.noPenaltyZones or {}) do
        local dist = #(coords - zone.coords)
        if dist <= zone.radius then
            return true, zone.name
        end
    end
    return false, ""
end

-- Hàm kiểm tra xem có trong khu vực cấm nào không
-- Dùng distance check thực tế từ coords truyền vào (chính xác hơn, không phụ thuộc vào ox_lib callback state)
local function checkForbiddenZone(coords)
    if not coords then
        return isInForbiddenZone, currentZoneName
    end
    for _, zone in ipairs(Config.ReputationSystem.forbiddenCombatZones) do
        local dist = #(coords - zone.coords)
        if dist <= zone.radius then
            return true, zone.name
        end
    end
    return false, ""
end

-- Hàm kiểm tra xem vũ khí có thuộc danh sách được phép dùng trong vùng an toàn hay không
local function isWeaponAllowedInZone(weaponData)
    if not weaponData then return true end
    local allowedList = Config.ReputationSystem.allowedWeaponsInZone or { 'WEAPON_STUNGUN', 'weapon_stungun' }
    for _, allowed in ipairs(allowedList) do
        if type(allowed) == 'string' then
            if string.lower(weaponData.name or "") == string.lower(allowed) then
                return true
            end
        elseif type(allowed) == 'number' then
            if weaponData.hash == allowed or weaponData.hash == joaat(tostring(allowed)) then
                return true
            end
        end
    end
    return false
end

-- Khởi tạo ox_lib zones cho các khu vực cấm
CreateThread(function()
    -- Tạo sphere zones cho mỗi khu vực cấm
    for i, zoneConfig in ipairs(Config.ReputationSystem.forbiddenCombatZones) do
        local zone = lib.zones.sphere({
            coords = zoneConfig.coords,
            radius = zoneConfig.radius,
            debug = false,
            onEnter = function(self)
                isInForbiddenZone = true
                currentZoneName = zoneConfig.name
                --print('[DIEMUYTIN] ✅ Entered forbidden zone: ' .. zoneConfig.name)
                
                -- Thông báo khi vào vùng an toàn (nhắc nhở không được dùng vũ khí)
                exports.qbx_core:Notify('🛡️ Vùng an toàn: ' .. zoneConfig.name .. ' (Nghiêm cấm sử dụng vũ khí!)', 'success', 5000)

                -- Tự động cất vũ khí nếu đang cầm vũ khí không được phép (dùng ox_inventory export có sẵn)
                if Config.ReputationSystem.autoDisarmInZone ~= false then
                    local currentWeapon = exports.ox_inventory:getCurrentWeapon()
                    if currentWeapon and not isWeaponAllowedInZone(currentWeapon) then
                        TriggerEvent('ox_inventory:disarm', true)
                        exports.qbx_core:Notify('🚫 Vũ khí đã được tự động cất khi vào vùng an toàn!', 'warning', 4000)
                    end
                end
            end,
            onExit = function(self)
                isInForbiddenZone = false
                currentZoneName = ""
                --print('[DIEMUYTIN] 🚪 Left forbidden zone: ' .. zoneConfig.name)
                
                -- Thông báo khi rời khỏi vùng an toàn
                exports.qbx_core:Notify('⚠️ Bạn đã rời khỏi vùng an toàn: ' .. zoneConfig.name, 'warning', 5000)
            end
        })
        
        table.insert(forbiddenZones, zone)
       --print('[DIEMUYTIN] 🎯 Created forbidden zone: ' .. zoneConfig.name .. ' (radius: ' .. zoneConfig.radius .. 'm)')
    end
    
    --print('[DIEMUYTIN] ✅ All ' .. #forbiddenZones .. ' forbidden zones initialized with ox_lib')
end)

-- Tự động cất vũ khí khi player CHỦ ĐỘNG rút vũ khí trong vùng an toàn
-- Notify chỉ hiện ở đây (event = player vừa rút vũ khí từ người)
-- FIX: Dùng checkForbiddenZone(coords) thực tế thay vì isInForbiddenZone để tránh race condition với ox_lib callback
AddEventHandler('ox_inventory:currentWeapon', function(currentWeapon)
    if not currentWeapon then return end
    if Config.ReputationSystem.autoDisarmInZone == false then return end
    local coords = GetEntityCoords(PlayerPedId())
    if checkForbiddenZone(coords) and not isWeaponAllowedInZone(currentWeapon) then
        TriggerEvent('ox_inventory:disarm', true)
        exports.qbx_core:Notify('🚫 Đây là vùng an toàn, không được phép sử dụng vũ khí!', 'error', 4000)
    end
end)

-- Thread kiểm tra định kỳ: cưỡng chế cất vũ khí nếu player đang trong forbidden zone
-- Chạy thầm lặng (không notify) - chỉ disarm để bắt các trường hợp event bị miss
CreateThread(function()
    while true do
        Wait(1000) -- Kiểm tra mỗi 1 giây
        if Config.ReputationSystem.autoDisarmInZone == false then
            Wait(5000)
            goto continueWeaponLoop
        end
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        if checkForbiddenZone(coords) then
            local currentWeapon = exports.ox_inventory:getCurrentWeapon()
            if currentWeapon and not isWeaponAllowedInZone(currentWeapon) then
                -- Disarm thầm lặng, không notify (notify đã hiện khi player rút vũ khí)
                TriggerEvent('ox_inventory:disarm', true)
            end
        end
        ::continueWeaponLoop::
    end
end)

-- Hàm hiển thị menu điểm uy tín cho bản thân
local function showReputationMenu(charName, reputation)
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'reputation_menu',
            title = 'Thông Tin Uy Tín',
            options = {
                {
                    title = 'Tên nhân vật',
                    description = charName,
                    icon = 'user'
                },
                {
                    title = 'Điểm uy tín',
                    description = reputation .. '/100',
                    icon = 'star',
                    iconColor = reputation > 50 and 'green' or reputation > 20 and 'orange' or 'red'
                },
                {
                    title = 'Đóng',
                    icon = 'times',
                    onSelect = function()
                        if lib and lib.hideContext then
                            lib.hideContext()
                        end
                    end
                }
            }
        })
        
        lib.showContext('reputation_menu')
    else
        -- Fallback notification nếu không có ox_lib
        exports.qbx_core:Notify('Tên: ' .. charName .. ' | Điểm uy tín: ' .. reputation .. '/100', 'primary', 5000)
    end
end

-- Hàm hiển thị menu điểm uy tín cho target
local function showTargetReputationMenu(displayName, reputation, isPolice, targetPID)
    -- Validate và convert dữ liệu
    displayName = tostring(displayName or 'Không xác định')
    reputation = tonumber(reputation) or 0
    isPolice = isPolice == true
    targetPID = tostring(targetPID or 'N/A')
    
    -- Debug log
    --print('[DIEMUYTIN DEBUG] showTargetReputationMenu called with:')
    --print('  displayName: ' .. displayName .. ' (type: ' .. type(displayName) .. ')')
    --print('  reputation: ' .. reputation .. ' (type: ' .. type(reputation) .. ')')
    --print('  isPolice: ' .. tostring(isPolice) .. ' (type: ' .. type(isPolice) .. ')')
    --print('  targetPID: ' .. targetPID .. ' (type: ' .. type(targetPID) .. ')')
    
    if lib and lib.registerContext then
        local statusIcon = reputation > 50 and 'shield-check' or reputation > 20 and 'exclamation-triangle' or 'skull-crossbones'
        local statusColor = reputation > 50 and 'green' or reputation > 20 and 'orange' or 'red'
        
        local options = {}
        
        -- Tên nhân vật - hiển thị cho tất cả
        table.insert(options, {
            title = 'Tên nhân vật',
            description = displayName,
            icon = isPolice and 'user-tie' or 'user-secret'
        })
        
        -- PID - hiển thị cho tất cả
        table.insert(options, {
            title = 'PID (Player ID)',
            description = targetPID,
            icon = 'id-card',
            iconColor = 'blue'
        })
        
        if isPolice then
            -- Công an xem được tất cả thông tin
            table.insert(options, {
                title = 'Điểm uy tín',
                description = reputation .. '/100',
                icon = statusIcon,
                iconColor = statusColor
            })
            
            table.insert(options, {
                title = 'Quyền truy cập',
                description = 'Bạn có quyền truy cập đầy đủ thông tin với vai trò công an',
                icon = 'eye',
                iconColor = 'blue'
            })
        else
            -- Dân thường chỉ thấy PID và thông báo hạn chế
            table.insert(options, {
                title = 'Điểm uy tín',
                description = 'Thông tin bị ẩn - chỉ công an mới xem được',
                icon = 'eye-slash',
                iconColor = 'gray'
            })
            
            table.insert(options, {
                title = 'Quyền truy cập',
                description = 'Thông tin hạn chế - bạn chỉ có thể xem PID',
                icon = 'exclamation-triangle',
                iconColor = 'orange'
            })
        end
        
        -- Nút đóng
        table.insert(options, {
            title = 'Đóng',
            icon = 'times',
            onSelect = function()
                if lib and lib.hideContext then
                    lib.hideContext()
                end
            end
        })
        
        lib.registerContext({
            id = 'target_reputation_menu',
            title = 'Kiểm Tra thông tin',
            options = options
        })
        
        lib.showContext('target_reputation_menu')
    else
        -- Fallback notification nếu không có ox_lib
        if isPolice then
            local status = 'Police Check'
            exports.qbx_core:Notify(status .. ' - Tên: ' .. displayName .. ' | PID: ' .. targetPID .. ' | Uy tín: ' .. reputation .. '/100', 'primary', 5000)
        else
            exports.qbx_core:Notify('Civilian Check - Tên: ' .. displayName .. ' | PID: ' .. targetPID .. ' | Uy tín: Bị ẩn', 'primary', 5000)
        end
    end
end

-- Event nhận thông tin để hiển thị menu
RegisterNetEvent('diemuytin:showReputationMenu', function(charName, reputation)
    showReputationMenu(charName, reputation)
end)

-- Event client để kiểm tra điểm uy tín của chính mình
RegisterNetEvent('diemuytin:checkMyReputation', function()
    TriggerServerEvent('diemuytin:requestMyReputation')
end)

-- Event nhận thông tin target reputation menu
RegisterNetEvent('diemuytin:showTargetReputationMenu', function(displayName, reputation, isPolice, targetPID)
    showTargetReputationMenu(displayName, reputation, isPolice, targetPID)
end)

-- Event nhận yêu cầu kiểm tra uy tín từ người khác
RegisterNetEvent('diemuytin:requestReputationCheck', function(checkerSource, checkerName)
    if not lib or not lib.alertDialog then
        -- Fallback nếu không có ox_lib - tự động chấp nhận
        TriggerServerEvent('diemuytin:respondReputationCheck', checkerSource, true)
        return
    end
    
    local alert = lib.alertDialog({
        header = '🔍 Yêu Cầu Kiểm Tra Thông Tin',
        content = string.format('**%s** muốn kiểm tra thông tin của bạn.\n\nBạn có đồng ý chia sẻ thông tin không?', checkerName),
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Đồng ý',
            cancel = 'Từ chối'
        }
    })
    
    if alert == 'confirm' then
        -- Người chơi đồng ý
        TriggerServerEvent('diemuytin:respondReputationCheck', checkerSource, true)
    else
        -- Người chơi từ chối
        TriggerServerEvent('diemuytin:respondReputationCheck', checkerSource, false)
        exports.qbx_core:Notify('Bạn đã từ chối yêu cầu kiểm tra thông tin từ ' .. checkerName, 'inform', 3000)
    end
end)

-- Event nhận điểm uy tín từ server (cho developers)
RegisterNetEvent('diemuytin:receiveReputation', function(reputation)
    -- Event này có thể được sử dụng bởi các developers khác
    -- Để lấy điểm uy tín của người chơi hiện tại
    --print('[DIEMUYTIN] Điểm uy tín hiện tại: ' .. reputation)
end)

-- Event để hiển thị cảnh báo uy tín thấp với UI mới
RegisterNetEvent('diemuytin:showReputationWarning', function(data)
    
    -- Hiển thị UI cảnh báo đẹp
    local reason = 'Điểm uy tín của bạn đã xuống dưới ngưỡng an toàn!'
    
    if data.reason then
        reason = data.reason
    end
    
    -- Kiểm tra xem có phải combat không (skipVehiclePenalty = true cho combat)
    local skipVehiclePenalty = data.skipVehiclePenalty or false
    local displayTime = data.displayTime or Config.ReputationSystem.warningUIDisplayTime or 10
    
    ShowWarningUI(data.reputation, reason, displayTime, skipVehiclePenalty)
    
    -- Cũng hiển thị notification nhỏ
    local message = string.format("⚠️ CẢNH BÁO: Uy tín còn %d/%d (%d%%)! Nguy cơ tù liên bang khi < %d điểm!", 
        data.reputation, 100, data.percentage, data.threshold)
    QBX:Notify(message, "warning", 5000)
end)

-- Test event để trigger UI trực tiếp
RegisterNetEvent('diemuytin:testShowUI', function()
    ShowWarningUI(64, 'Test UI - Đây là test!')
end)

-- Event yêu cầu gửi link screenshot khi bị đưa đi tù
RegisterNetEvent('diemuytin:requestScreenshotForPrison', function()
    -- Gửi link screenshot nếu có, nếu không có thì gửi nil
    if lastScreenshotUrl then
        TriggerServerEvent('diemuytin:sendScreenshotForPrison', lastScreenshotUrl)
        -- Reset link sau khi gửi
        lastScreenshotUrl = nil
    else
        TriggerServerEvent('diemuytin:sendScreenshotForPrison', nil)
    end
end)

-- Khởi tạo ox_target cho kiểm tra uy tín
if Config.TargetSystem.enabled and exports.ox_target then
    exports.ox_target:addGlobalPlayer({
        {
            name = 'diemuytin_check_reputation',
            icon = Config.TargetSystem.icon,
            label = Config.TargetSystem.label,
            canInteract = function(entity, distance, coords, name, bone)
                -- Kiểm tra xem người chơi có phải là police onduty không
                local playerData = QBX:GetPlayerData()
                if not playerData or not playerData.job then return false end
                
                local isPoliceJob = false
                for _, policeJob in ipairs(Config.TargetSystem.policeJobs) do
                    if playerData.job.name == policeJob then
                        isPoliceJob = true
                        break
                    end
                end
                
                -- Chỉ police onduty mới thấy target option
                return isPoliceJob and playerData.job.onduty
            end,
            onSelect = function(data)
                local targetEntity = data.entity
                if not targetEntity then return end
                
                local targetPlayerId = NetworkGetPlayerIndexFromPed(targetEntity)
                if targetPlayerId == -1 then return end
                
                local targetServerId = GetPlayerServerId(targetPlayerId)
                if targetServerId == GetPlayerServerId(PlayerId()) then
                    -- Không thể target chính mình
                    exports.qbx_core:Notify('Không thể kiểm tra thông tin của chính mình!', 'error', 3000)
                    return
                end
                
                TriggerServerEvent('diemuytin:checkTargetReputation', targetServerId)
            end,
            distance = Config.TargetSystem.maxDistance
        }
    })
end

-- Thread kiểm tra combat trong khu vực cấm - ĐÃ TẮT
-- BUG: Thread này trừ điểm người BỊ đánh (victim) thay vì người TẤN CÔNG.
-- Việc phát hiện tấn công đã được xử lý đúng bởi gameEventTriggered (attacker == PlayerPedId()).
--[[
CreateThread(function()
    local lastHealthCheck = {}
    local lastArmourCheck = {}
    
    while true do
        Wait(500) -- Giữ nguyên wait time
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local playerId = PlayerId()
        
        -- Kiểm tra xem người chơi có trong bất kỳ khu vực cấm nào không
        local inForbiddenZone, currentZoneName = checkForbiddenZone(playerCoords)
        
        if inForbiddenZone then
            -- Debug: In ra khi ở trong khu vực cấm
            if GetGameTimer() % 10000 < 500 then -- In mỗi 10 giây
                --print('[DIEMUYTIN DEBUG] Đang ở trong khu vực cấm: ' .. currentZoneName)
            end
            
            local currentHealth = GetEntityHealth(playerPed)
            local currentArmour = GetPedArmour(playerPed)
            
            -- Khởi tạo giá trị ban đầu nếu chưa có
            if not lastHealthCheck[playerId] then
                lastHealthCheck[playerId] = currentHealth
                lastArmourCheck[playerId] = currentArmour
            end
            
            -- CÁCH MỚI: Chỉ trigger khi có DAMAGE THỰC SỰ
            local healthLost = lastHealthCheck[playerId] - currentHealth
            local armourLost = lastArmourCheck[playerId] - currentArmour
            
            -- Chỉ kiểm tra nếu có damage đáng kể (tránh damage từ fall, etc.)
            if (healthLost > 10 or armourLost > 5) then
                --print('[DIEMUYTIN DEBUG] Phát hiện damage: Health lost=' .. healthLost .. ', Armour lost=' .. armourLost)
                
                -- Kiểm tra xem damage có từ người chơi khác không
                local damageFromPlayer = false
                local players = GetActivePlayers()
                
                for _, otherPlayerId in ipairs(players) do
                    if otherPlayerId ~= playerId then
                        local otherPed = GetPlayerPed(otherPlayerId)
                        local otherCoords = GetEntityCoords(otherPed)
                        local distance = getDistance(playerCoords, otherCoords)
                        
                        -- Kiểm tra người chơi khác gần đó và đang có weapon hoặc vừa bắn
                        if distance < 15.0 then -- Tăng range để catch sniper, etc.
                            local weaponHash = GetSelectedPedWeapon(otherPed)
                            local hasWeapon = weaponHash ~= GetHashKey("WEAPON_UNARMED")
                            
                            -- Kiểm tra người khác có firing gần đây hoặc đang combat
                            if hasWeapon and (IsPedShooting(otherPed) or IsPedInCombat(otherPed, 0)) then
                                damageFromPlayer = true
                                --print('[DIEMUYTIN DEBUG] Damage từ người chơi khác được xác nhận!')
                                break
                            end
                        end
                    end
                end
                
                if damageFromPlayer then
                    local currentTime = GetGameTimer()
                    local lastDamageTime = playerLastDamageTime[playerId] or 0
                    
                    -- Cooldown 10 giây để tránh spam
                    if (currentTime - lastDamageTime) > 10000 then
                        --print('[DIEMUYTIN DEBUG] Trigger server event: combatInForbiddenZone trong ' .. currentZoneName)
                        
                        -- Chụp ảnh và gửi Discord A
                        if Config.DiscordWebhook.enabled then
                            CreateThread(function()
                                Wait(100)
                                
                                if exports[Config.DiscordWebhook.screenshotResource] then
                                    exports[Config.DiscordWebhook.screenshotResource]:requestScreenshotUpload(Config.DiscordWebhook.combatScreenshotURL, 'files[]', {
                                        encoding = 'png',
                                        quality = 1.0
                                    }, function(data)
                                        local resp = json.decode(data)
                                        if resp and resp.attachments and resp.attachments[1] then
                                            -- Lưu link ảnh để gửi sang server nếu bị tù
                                            lastScreenshotUrl = resp.attachments[1].proxy_url or resp.attachments[1].url
                                        else
                                            lastScreenshotUrl = nil
                                        end
                                    end)
                                end
                            end)
                        end
                        
                        TriggerServerEvent('diemuytin:combatInForbiddenZone', currentZoneName)
                        playerLastDamageTime[playerId] = currentTime
                    end
                end
            end
            
            -- Cập nhật giá trị cho lần kiểm tra tiếp theo
            lastHealthCheck[playerId] = currentHealth
            lastArmourCheck[playerId] = currentArmour
        end
    end
end)
--]]

-- Vehicle ramming detection - Sử dụng collision + damage check (> 15 máu)
local lastVehicleRamming = {}
local trackedPedHealth = {}

-- Tra cứu model xe bị bỏ qua bằng hash (tránh joaat + vòng lặp mỗi tick)
local ignoredVehicleModels = {}
for _, modelName in ipairs(Config.ReputationSystem.vehicleRammingDetection.ignoredVehicles or {}) do
    ignoredVehicleModels[joaat(modelName)] = true
end

-- Thread kiểm tra collision với người chơi
-- Khi không lái xe chạy chậm 500ms/tick và không tốn native nào tới danh sách người chơi
CreateThread(function()
    local nextWait = 500
    while true do
        Wait(nextWait)
        nextWait = 500
        local trackCoords = nil
        
        local playerPed = PlayerPedId()
        
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            -- Kiểm tra là tài xế
            if GetPedInVehicleSeat(vehicle, -1) == playerPed then
                nextWait = Config.ReputationSystem.vehicleRammingDetection.checkInterval
                
                -- Bỏ qua xe nằm trong danh sách ignoredVehicles
                if ignoredVehicleModels[GetEntityModel(vehicle)] then goto skipRamming end

                local vehicleSpeed = GetEntitySpeed(vehicle) * 3.6 -- km/h
                
                -- Chỉ theo dõi máu người xung quanh khi xe đã chạy đủ nhanh
                if vehicleSpeed > Config.ReputationSystem.vehicleRammingDetection.minSpeed * 0.5 then
                    trackCoords = GetEntityCoords(vehicle)
                end
                
                -- Chỉ check khi tốc độ > config minSpeed
                if vehicleSpeed > Config.ReputationSystem.vehicleRammingDetection.minSpeed then
                    -- Bỏ qua nếu đang ở khu vực không trừ điểm
                    local vehicleCoords = GetEntityCoords(vehicle)
                    local inNoPenalty = checkNoPenaltyZone(vehicleCoords)
                    if inNoPenalty then goto skipRamming end
                    
                    -- Kiểm tra va chạm
                    if HasEntityCollidedWithAnything(vehicle) then
                        local vehicleCoords = GetEntityCoords(vehicle)
                        local players = GetActivePlayers()
                        
                        for _, playerId in ipairs(players) do
                            if playerId ~= PlayerId() then
                                local otherPed = GetPlayerPed(playerId)
                                local otherVehicle = GetVehiclePedIsIn(otherPed, false)
                                
                                -- CHỈ trừ điểm khi đâm người ĐI BỘ (không trong xe)
                                if otherVehicle == 0 and DoesEntityExist(otherPed) then
                                    local otherCoords = GetEntityCoords(otherPed)
                                    local distance = #(vehicleCoords - otherCoords)
                                    
                                    -- Kiểm tra khoảng cách gần
                                    if distance < Config.ReputationSystem.vehicleRammingDetection.detectionDistance then
                                        local currentTime = GetGameTimer()
                                        local lastHitTime = lastVehicleRamming[PlayerId()] or 0
                                        
                                        -- Cooldown từ config
                                        if (currentTime - lastHitTime) > Config.ReputationSystem.vehicleRammingDetection.cooldownMs then
                                            -- Lấy lượng máu/giáp ban đầu trước khi va chạm từ cache tracking
                                            local initialData = trackedPedHealth[playerId]
                                            -- Bỏ cache quá cũ để tránh tính dư sát thương
                                            if initialData and (currentTime - initialData.t) > 1000 then
                                                initialData = nil
                                            end
                                            local initialHp = initialData and initialData.hp or GetEntityHealth(otherPed)
                                            local initialArmour = initialData and initialData.armour or GetPedArmour(otherPed)
                                            
                                            -- Đợi 200ms để GTA V engine tính toán sát thương va chạm
                                            Wait(200)
                                            
                                            local currentHp = GetEntityHealth(otherPed)
                                            local currentArmour = GetPedArmour(otherPed)
                                            
                                            local hpLost = initialHp - currentHp
                                            local armourLost = initialArmour - currentArmour
                                            local totalDamage = math.max(0, hpLost) + math.max(0, armourLost)
                                            
                                            local minDamage = Config.ReputationSystem.vehicleRammingDetection.minDamage or 15
                                            
                                            local victimServerId = GetPlayerServerId(playerId)
                                            local isPenalized = totalDamage > minDamage
                                            
                                            -- CHỈ trừ uy tín khi gây sát thương > minDamage
                                            if isPenalized then
                                                -- GỬI EVENT NGAY để trừ điểm và dừng xe
                                                TriggerServerEvent('diemuytin:vehicleRamming', victimServerId)
                                            end
                                            
                                            -- LUÔN chụp ảnh + gửi log CRM khi sát thương > logMinDamage, kể cả khi chưa đủ để bị trừ điểm
                                            local logMinDamage = Config.ReputationSystem.vehicleRammingDetection.logMinDamage or 2
                                            if Config.DiscordWebhook.enabled and totalDamage > logMinDamage then
                                                CreateThread(function()
                                                    Wait(100)
                                                    
                                                    if exports[Config.DiscordWebhook.screenshotResource] then
                                                        exports[Config.DiscordWebhook.screenshotResource]:requestScreenshotUpload(Config.DiscordWebhook.combatScreenshotURL, 'files[]', {
                                                            encoding = 'png',
                                                            quality = 1.0
                                                        }, function(data)
                                                            local resp = json.decode(data)
                                                            if resp and resp.attachments and resp.attachments[1] then
                                                                local screenshotUrl = resp.attachments[1].proxy_url or resp.attachments[1].url
                                                                -- GỬI URL LÊN SERVER (event riêng)
                                                                TriggerServerEvent('diemuytin:sendScreenshotUrl', screenshotUrl, victimServerId, totalDamage)
                                                            end
                                                        end)
                                                    end
                                                end)
                                            end
                                            
                                            lastVehicleRamming[PlayerId()] = currentTime
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            ::skipRamming::
        end
        
        -- Cập nhật trackedPedHealth cho các player xung quanh khi bình thường
        -- Chỉ lưu người trong bán kính 30m quanh xe; bảng được dựng lại mỗi tick nên không giữ người đã đi xa/thoát
        if trackCoords then
            local myId = PlayerId()
            local fresh = {}
            local now = GetGameTimer()
            for _, playerId in ipairs(GetActivePlayers()) do
                if playerId ~= myId then
                    local otherPed = GetPlayerPed(playerId)
                    if DoesEntityExist(otherPed) and #(GetEntityCoords(otherPed) - trackCoords) < 30.0 then
                        fresh[playerId] = {
                            hp = GetEntityHealth(otherPed),
                            armour = GetPedArmour(otherPed),
                            t = now
                        }
                    end
                end
            end
            trackedPedHealth = fresh
        elseif next(trackedPedHealth) then
            trackedPedHealth = {}
        end
    end
end)

-- Biến và Thread theo dõi hành động tấn công chủ động của người chơi để tránh lỗi trừ điểm sai do lag hoặc lưu vết cũ (fall damage, environment)
local lastLocalPlayerAttackTime = 0
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        if IsPedShooting(playerPed) or IsPedInMeleeCombat(playerPed) or 
           IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24) or 
           IsControlPressed(0, 140) or IsDisabledControlPressed(0, 140) then
            lastLocalPlayerAttackTime = GetGameTimer()
            Wait(100) -- Khi đang có tương tác combat, check nhanh hơn
        else
            Wait(300) -- Khi bình thường, check chậm hơn để tối ưu tuyệt đối hiệu năng (0.00 ms)
        end
    end
end)

-- Event kiểm tra va chạm khi người chơi bị thương
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
        local weapon = args[7]
        
        -- Event này bắn cho mọi sát thương trong tầm; bỏ qua ngay nếu không phải do chính mình gây ra
        local playerPed = PlayerPedId()
        if attacker ~= playerPed then return end
        
        -- CASE 1: Kiểm tra nếu attacker là người chơi hiện tại và victim là người chơi khác
        if attacker == PlayerPedId() and IsPedAPlayer(victim) and victim ~= PlayerPedId() then
            -- 1. Bỏ qua các sát thương do môi trường / đâm xe / té ngã
            local damageType = GetWeaponDamageType(weapon)
            local isEnvironmentOrVehicle = false
            
            local ignoredWeapons = {
                [GetHashKey("WEAPON_FALL")] = true,
                [GetHashKey("WEAPON_RAMMED_BY_CAR")] = true,
                [GetHashKey("WEAPON_RUN_OVER")] = true,
                [GetHashKey("WEAPON_HELI_CRASH")] = true,
                [GetHashKey("WEAPON_BLEEDING")] = true,
                [GetHashKey("WEAPON_DROWNING")] = true,
                [GetHashKey("WEAPON_DROWNING_IN_VEHICLE")] = true,
                [GetHashKey("WEAPON_BARBED_WIRE")] = true,
                [GetHashKey("WEAPON_HIT_BY_WATER_CANNON")] = true
            }
            
            if damageType == 4 or damageType == 8 or ignoredWeapons[weapon] then
                isEnvironmentOrVehicle = true
            end
            
            if isEnvironmentOrVehicle then
                return
            end

            local attackerCoords = GetEntityCoords(attacker)
            local victimCoords = GetEntityCoords(victim)
            local distance = #(attackerCoords - victimCoords)
            
            -- 2. Kiểm tra khoảng cách hợp lý dựa trên loại vũ khí
            local isMelee = (weapon == GetHashKey("WEAPON_UNARMED") or weapon == 0 or IsPedArmed(attacker, 1) or damageType == 2)
            local maxAllowedDistance = isMelee and 5.0 or 80.0
            
            if distance > maxAllowedDistance then
                --print(('[DIEMUYTIN DEBUG] Bỏ qua PvP damage vì khoảng cách quá xa (%f m) so với loại vũ khí!'):format(distance))
                return
            end
            
            -- 3. Kiểm tra xem người chơi có thực sự chủ động tấn công gần đây không (trong vòng 5 giây)
            local currentTime = GetGameTimer()
            if (currentTime - lastLocalPlayerAttackTime) > 5000 then
                --print('[DIEMUYTIN DEBUG] Bỏ qua PvP damage vì người chơi không chủ động bấm tấn công gần đây!')
                return
            end
            
            -- Bỏ qua nếu đang ở khu vực không trừ điểm (PvP zone tự do)
            local inNoPenalty = checkNoPenaltyZone(attackerCoords)
            if inNoPenalty then return end
            
            -- Kiểm tra xem có trong bất kỳ khu vực cấm nào không
            local inForbiddenZone, currentZoneName = checkForbiddenZone(attackerCoords)
            
            if inForbiddenZone then
                local currentTime = GetGameTimer()
                local lastDamageTime = playerLastDamageTime[PlayerId()] or 0
                
                -- Cooldown từ config
                if (currentTime - lastDamageTime) > Config.ReputationSystem.combatDetection.cooldownMs then
                    --print('[DIEMUYTIN DEBUG] Player vs Player combat trong ' .. currentZoneName .. ' - trigger combatInForbiddenZone')
                    
                    local victimPlayerId = NetworkGetPlayerIndexFromPed(victim)
                    local victimServerId = GetPlayerServerId(victimPlayerId)
                    
                    -- Chụp ảnh và gửi Discord A
                    if Config.DiscordWebhook.enabled then
                        CreateThread(function()
                            Wait(100)
                            
                            if exports[Config.DiscordWebhook.screenshotResource] then
                                exports[Config.DiscordWebhook.screenshotResource]:requestScreenshotUpload(Config.DiscordWebhook.combatScreenshotURL, 'files[]', {
                                    encoding = 'png',
                                    quality = 1.0
                                }, function(data)
                                    local resp = json.decode(data)
                                    if resp and resp.attachments and resp.attachments[1] then
                                        -- Lưu link ảnh để gửi sang server nếu bị tù
                                        lastScreenshotUrl = resp.attachments[1].proxy_url or resp.attachments[1].url
                                        -- GỬI URL LÊN SERVER để log chi tiết
                                        TriggerServerEvent('diemuytin:sendCombatScreenshotUrl', lastScreenshotUrl, victimServerId, currentZoneName)
                                    else
                                        lastScreenshotUrl = nil
                                    end
                                end)
                            end
                        end)
                    end
                    
                    TriggerServerEvent('diemuytin:combatInForbiddenZone', currentZoneName, victimServerId)
                    playerLastDamageTime[PlayerId()] = currentTime
                end
            end
        end
        
        -- CASE 2: NPC Combat Detection - ĐÃ TẮT THEO YÊU CẦU
        -- Code này đã được comment out - không trừ điểm khi đánh NPC nữa
        --[[
        if attacker == PlayerPedId() and victim ~= PlayerPedId() and not IsPedAPlayer(victim) and DoesEntityExist(victim) then
            local attackerCoords = GetEntityCoords(attacker)
            
            -- Thêm debug để kiểm tra detection
            --print('[DIEMUYTIN DEBUG] NPC detected - Entity: ' .. victim .. ', Type: ' .. GetEntityType(victim))
            
            -- Kiểm tra xem có trong bất kỳ khu vực cấm nào không
            local inForbiddenZone, currentZoneName = checkForbiddenZone(attackerCoords)
            
            if inForbiddenZone then
                local currentTime = GetGameTimer()
                local lastDamageTime = playerLastDamageTime[PlayerId()] or 0
                
                -- Cooldown từ config
                if (currentTime - lastDamageTime) > Config.ReputationSystem.combatDetection.cooldownMs then
                    --print('[DIEMUYTIN DEBUG] Player vs NPC combat trong ' .. currentZoneName .. ' - trigger npcCombatInForbiddenZone')
                    TriggerServerEvent('diemuytin:npcCombatInForbiddenZone', currentZoneName)
                    playerLastDamageTime[PlayerId()] = currentTime
                else
                    --print('[DIEMUYTIN DEBUG] NPC combat cooldown active')
                end
            else
                --print('[DIEMUYTIN DEBUG] NPC combat outside forbidden zone - no penalty')
            end
        end
        --]]
        
        -- CASE 3: Self Vehicle Damage - ĐÃ TẮT THEO YÊU CẦU
        -- Code này đã được comment out - không trừ điểm khi tự gây sát thương bằng xe nữa
        --[[
        if victim == PlayerPedId() and IsEntityAVehicle(attacker) then
            -- Kiểm tra xem người chơi có phải là chủ sở hữu hoặc người lái xe không
            local vehicleOwner = NetworkGetEntityOwner(attacker)
            local playerPed = PlayerPedId()
            
            -- Kiểm tra nếu đây là xe của người chơi hoặc người chơi vừa ra khỏi xe này
            if vehicleOwner == PlayerId() or GetVehiclePedIsIn(playerPed, true) == attacker then
                local currentTime = GetGameTimer()
                local lastSelfDamageTime = playerLastDamageTime[PlayerId()] or 0
                
                -- Cooldown 3 giây để tránh spam
                if (currentTime - lastSelfDamageTime) > 3000 then
                    --print('[DIEMUYTIN DEBUG] Self vehicle damage detected - trigger selfVehicleDamage')
                    TriggerServerEvent('diemuytin:selfVehicleDamage')
                    playerLastDamageTime[PlayerId()] = currentTime
                end
            end
        end
        --]]
        
        -- CASE 4: Vehicle Ramming đã được xử lý trong thread riêng
        -- Không cần xử lý tại đây nữa vì event này trigger trên client victim, không phải attacker
    end
end)

-- -- Debug commands để theo dõi hệ thống
-- RegisterCommand('debugreputation', function()
--     local debugInfo = string.format([[
-- === DEBUG REPUTATION SYSTEM ===
-- Player ID: %d
-- Health: %d/%d
-- Armour: %d
-- In Vehicle: %s
-- Vehicle Speed: %s km/h
-- Last Damage Time: %s
-- Last Vehicle Hit: %s
-- ====================
-- ]], 
--         PlayerId(),
--         GetEntityHealth(PlayerPedId()),
--         GetEntityMaxHealth(PlayerPedId()),
--         GetPedArmour(PlayerPedId()),
--         tostring(IsPedInAnyVehicle(PlayerPedId(), false)),
--         IsPedInAnyVehicle(PlayerPedId(), false) and math.floor(GetEntitySpeed(GetVehiclePedIsIn(PlayerPedId(), false)) * 3.6) or "N/A",
--         playerLastDamageTime[PlayerId()] or "Never",
--         playerLastVehicleHit[PlayerId()] or "Never"
--     )
    
--     print(debugInfo)
--     exports.qbx_core:Notify("Check console for debug info", "info")
-- end, false)

-- RegisterCommand('debugtargetmenu', function()
--     -- Test target reputation menu với data mẫu
--     showTargetReputationMenu("Test Player", 75, false, 1234)
--     exports.qbx_core:Notify("Testing target menu (civilian view)", "info")
-- end, false)

-- RegisterCommand('debugtargetmenupolice', function()
--     -- Test target reputation menu với data mẫu (police view)
--     showTargetReputationMenu("Test Player", 75, true, 1234)
--     exports.qbx_core:Notify("Testing target menu (police view)", "info")
-- end, false)

-- RegisterCommand('togglerepdebug', function()
--     -- Toggle debug mode (uncomment debug prints)
--     exports.qbx_core:Notify("Debug mode toggle - check client console for details", "info")
--     print('[DIEMUYTIN] Debug mode toggled. Restart client script to see effect.')
-- end, false)
