local QBCore = exports['qb-core']:GetCoreObject()
local isSleeping = false
local isPlayerSleeping = false -- 🆕 Biến state mới
local currentSleepLocation = nil -- 🆕 Lưu vị trí ngủ hiện tại
local originalPed = nil
local originalCoords = nil
local originalHeading = nil
local sleepEntity = nil
local targetZones = {} -- Lưu trữ các zones đã tạo
local occupiedLocations = {} -- 🆕 Theo dõi các vị trí đang được sử dụng
local sleepBlurActive = false -- 🆕 Theo dõi trạng thái blur khi ngủ

-- Forward declaration
local StartSleepAtLocation

-- Hàm bật hiệu ứng blur khi ngủ
local function EnableSleepBlur()
    if sleepBlurActive then return end
    
    sleepBlurActive = true
    
    -- Áp dụng hiệu ứng một lần thay vì liên tục
    SetTimecycleModifier(Config.SleepProtection.blurTimecycle or 'sleeping')
    SetTimecycleModifierStrength(Config.SleepProtection.blurStrength or 0.5)
    
    -- Chỉ start screen effect một lần để tránh rung
    StartScreenEffect(Config.SleepProtection.blurEffectName or 'DeathFailMPIn', 0, false)
    
    -- Tạo thread để duy trì hiệu ứng mà không gây rung
    CreateThread(function()
        while sleepBlurActive do
            -- Chỉ duy trì timecycle, không start screen effect liên tục
            SetTimecycleModifier(Config.SleepProtection.blurTimecycle or 'sleeping')
            SetTimecycleModifierStrength(Config.SleepProtection.blurStrength or 0.5)
            
            -- Sử dụng interval từ config để giảm rung
            Wait(Config.SleepProtection.blurUpdateInterval or 500)
        end
        
        -- Dọn dẹp hiệu ứng khi thoát
        ClearTimecycleModifier()
        StopScreenEffect(Config.SleepProtection.blurEffectName or 'DeathFailMPIn')
    end)
end

-- Hàm tắt hiệu ứng blur khi thức dậy
local function DisableSleepBlur()
    if not sleepBlurActive then return end
    
    sleepBlurActive = false
    
    -- Dọn dẹp hiệu ứng ngay lập tức
    ClearTimecycleModifier()
    StopScreenEffect(Config.SleepProtection.blurEffectName or 'DeathFailMPIn')
    
    -- Fade out mượt mà
    CreateThread(function()
        local fadeTime = 2000 -- 2 giây
        local startTime = GetGameTimer()
        
        while GetGameTimer() - startTime < fadeTime do
            local progress = (GetGameTimer() - startTime) / fadeTime
            local strength = 0.8 * (1.0 - progress)
            
            if strength > 0 then
                SetTimecycleModifier('sleeping')
                SetTimecycleModifierStrength(strength)
            else
                ClearTimecycleModifier()
                break
            end
            
            Wait(50)
        end
        
        -- Đảm bảo dọn dẹp hoàn toàn
        ClearTimecycleModifier()
        StopScreenEffect(Config.SleepProtection.blurEffectName or 'DeathFailMPIn')
    end)
end

-- Hàm disable screen shake để giảm rung
local function DisableScreenShake()
    if not Config.SleepProtection.reduceScreenShake then return end
    
    -- Disable các loại screen shake
    StopScreenEffect('DrugsMichaelAliensFightIn')
    StopScreenEffect('DrugsMichaelAliensFightOut') 
    StopScreenEffect('SwitchHudMichaelOut')
    StopScreenEffect('SwitchHudMichaelIn')
    StopScreenEffect('HeistCelebPass')
    
    -- Disable game shake
    SetGameplayCamShakeAmplitude(0.0)
    StopGameplayCamShaking(true)
end

-- Hàm áp dụng bảo vệ tối ưu khi ngủ
local function ApplySleepProtection(ped)
    -- ĐƠN GIẢN: Chỉ tắt ragdoll để nằm yên, KHÔNG có bảo vệ nào khác
    -- Player có thể bị tấn công, mất máu, bị xe cán hoàn toàn bình thường
    -- Chỉ phát hiện damage và tự động wake up
    
    -- Tắt ragdoll để player nằm yên
    -- SetPedCanRagdoll(ped, false)
    -- SetPedCanBeKnockedOffVehicle(ped, 1)
    
    -- Tắt controls để không thể di chuyển
    DisableAllControlActions(0)
    DisableAllControlActions(1)
    DisableAllControlActions(2)
    
    -- Bật hiệu ứng blur nếu config cho phép
    if Config.SleepProtection.enableBlurEffect then
        EnableSleepBlur()
    end
    
    DisableScreenShake()
end

-- Hàm bỏ bảo vệ khi thức dậy
local function RemoveSleepProtection(ped)
    -- Khôi phục ragdoll
    -- SetPedCanRagdoll(ped, true)
    -- SetPedCanBeKnockedOffVehicle(ped, 0)
    
    -- Khôi phục controls
    EnableAllControlActions(0)
    EnableAllControlActions(1)
    EnableAllControlActions(2)
    
    -- Tắt hiệu ứng blur nếu đang bật
    if Config.SleepProtection.enableBlurEffect then
        DisableSleepBlur()
    end
end

-- Hàm tạo ox_target zones cho vị trí ngủ
local function CreateSleepTargets()
    if not Config.UseTarget then return end
    
    for i, location in ipairs(Config.SleepLocations) do
        local zoneId = 'sleep_zone_' .. i
        
        local targetOption = {
            name = zoneId,
            icon = Config.TargetIcon,
            label = Config.TargetLabel .. ' (' .. location.label .. ')',
            groups = location.jobs, -- ox_target tự kiểm tra jobs
            onSelect = function()
                StartSleepAtLocation(location)
            end,
            canInteract = function()
                return not isSleeping
            end
        }
        
        local success = exports.ox_target:addSphereZone({
            coords = vec3(location.coords.x, location.coords.y, location.coords.z),
            radius = location.radius,
            debug = Config.DebugTarget, -- Sử dụng config để debug
            options = { targetOption }
        })
        
        if success then
            table.insert(targetZones, zoneId)
            if Config.Debug then
                print('Created sleep target zone:', zoneId, 'at', location.coords.x, location.coords.y, location.coords.z)
            end
        else
            if Config.Debug then
                print('Failed to create sleep target zone:', zoneId)
            end
        end
    end
    
    if Config.Debug then
        print('Total sleep zones created:', #targetZones)
    end
end

-- Hàm xóa ox_target zones
local function RemoveSleepTargets()
    for _, zoneId in ipairs(targetZones) do
        exports.ox_target:removeZone(zoneId)
    end
    targetZones = {}
end

-- Hàm kiểm tra xem có ai đang ngủ tại vị trí này không
local function IsLocationOccupied(location)
    local locationKey = string.format("%.2f_%.2f_%.2f", location.coords.x, location.coords.y, location.coords.z)
    
    -- Kiểm tra trong bảng occupiedLocations
    if occupiedLocations[locationKey] then
        return true, occupiedLocations[locationKey].playerId
    end
    
    -- Kiểm tra bằng cách tìm kiếm player gần vị trí ngủ
    local sleepCoords = vec3(location.coords.x, location.coords.y, location.coords.z)
    local players = GetActivePlayers()
    
    for _, playerId in ipairs(players) do
        if playerId ~= PlayerId() then -- Bỏ qua chính mình
            local playerPed = GetPlayerPed(playerId)
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(sleepCoords - playerCoords)
            
            -- Nếu có player khác trong bán kính 1.5m từ vị trí ngủ
            if distance <= 1.5 then
                -- Kiểm tra xem player đó có đang ngủ không
                local playerServerId = GetPlayerServerId(playerId)
                if Player(playerServerId) and Player(playerServerId).state.isSleeping then
                    return true, playerServerId
                end
            end
        end
    end
    
    return false, nil
end

-- Hàm đánh dấu vị trí là đang được sử dụng
local function MarkLocationOccupied(location, playerId)
    local locationKey = string.format("%.2f_%.2f_%.2f", location.coords.x, location.coords.y, location.coords.z)
    occupiedLocations[locationKey] = {
        playerId = playerId,
        timestamp = GetGameTimer(),
        location = location
    }
end

-- Hàm bỏ đánh dấu vị trí đang được sử dụng
local function MarkLocationFree(location)
    if not location then return end
    local locationKey = string.format("%.2f_%.2f_%.2f", location.coords.x, location.coords.y, location.coords.z)
    occupiedLocations[locationKey] = nil
end

-- Hàm tính toán thời gian ngủ dựa trên sleepiness hiện tại
local function CalculateSleepTime(currentSleepiness, maxSleepiness)
    if not Config.SleepTimeCalculation.enabled then
        return Config.SleepDuration * 1000 -- Trả về thời gian cố định (ms)
    end
    
    -- Đảm bảo currentSleepiness là số và trong khoảng 0-100
    currentSleepiness = math.max(0, math.min(100, tonumber(currentSleepiness) or 0))
    
    -- Xác định giới hạn tối đa (mặc định 100%)
    local targetSleepiness = maxSleepiness or 100
    
    -- Tính % sleepiness cần tăng
    local sleepinessNeeded = targetSleepiness - currentSleepiness
    
    -- Nếu đã đủ maxSleepiness, không cần ngủ
    if sleepinessNeeded <= 0 then
        return 0
    end
    
    -- Tính thời gian ngủ (giây)
    local sleepTimeSeconds = sleepinessNeeded * Config.SleepTimeCalculation.timePerPercent
    
    -- Áp dụng giới hạn min/max
    sleepTimeSeconds = math.max(Config.SleepTimeCalculation.minSleepTime, sleepTimeSeconds)
    sleepTimeSeconds = math.min(Config.SleepTimeCalculation.maxSleepTime, sleepTimeSeconds)
    
    -- Trả về thời gian tính bằng milliseconds
    return math.floor(sleepTimeSeconds * 1000)
end

-- Hàm format thời gian để hiển thị
local function FormatSleepTime(timeMs)
    local totalSeconds = math.floor(timeMs / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    
    if minutes > 0 then
        return string.format("%d phút %d giây", minutes, seconds)
    else
        return string.format("%d giây", seconds)
    end
end

-- Hàm bắt đầu ngủ tại vị trí cụ thể
StartSleepAtLocation = function(location)
    if isSleeping then
        QBCore.Functions.Notify(Config.Messages.alreadySleeping, 'error')
        return
    end

    -- Kiểm tra xem player có đang dưới nước không
    local ped = PlayerPedId()
    if IsPedSwimming(ped) or IsPedSwimmingUnderWater(ped) then
        QBCore.Functions.Notify('Bạn không thể ngủ dưới nước!', 'error')
        return
    end

    -- 🔍 Kiểm tra xem có ai đang ngủ tại vị trí này không
    local isOccupied, occupiedByPlayer = IsLocationOccupied(location)
    if isOccupied then
        exports.ox_lib:notify({
            title = 'Vị trí đã có người',
            description = 'Có người khác đang ngủ tại vị trí này rồi!',
            type = 'error',
            duration = 3000
        })
        return
    end

    -- 🆕 Thiết lập trạng thái ngủ
    isPlayerSleeping = true
    LocalPlayer.state:set('isSleeping', true, true) -- 🆕 Set player state cho QBCore loop
    currentSleepLocation = location -- 🆕 Lưu vị trí ngủ hiện tại
    
    -- 🔍 Đánh dấu vị trí này là đang được sử dụng
    MarkLocationOccupied(location, GetPlayerServerId(PlayerId()))
    
    local playerPed = PlayerPedId()
    
    -- 🔍 Kiểm tra sleepiness hiện tại và tính toán thời gian ngủ
    local currentSleepiness = LocalPlayer.state.sleepiness or 0
    currentSleepiness = tonumber(currentSleepiness) or 0 -- 🔧 Đảm bảo là số
    currentSleepiness = math.floor(currentSleepiness) -- 🔧 Đảm bảo là số nguyên
    
    -- Xác định giới hạn sleepiness cho vị trí này
    local maxSleepiness = location.maxSleepiness or 100
    local sleepinessNeeded = maxSleepiness - currentSleepiness -- Số % cần tăng
    
    -- 🆕 Tính toán thời gian ngủ: dùng túi ngủ (isTemporary) là 60s (60000ms), không dùng túi ngủ là 30s (30000ms)
    local sleepTimeMs = location.isTemporary and 60000 or 30000
    
    -- Kiểm tra nếu sleepiness đã đạt giới hạn hoặc thời gian ngủ = 0
    if currentSleepiness >= maxSleepiness or sleepTimeMs <= 0 then
        local limitText = maxSleepiness < 100 and string.format(' (giới hạn %d%%)', maxSleepiness) or ''
        exports.ox_lib:notify({
            title = 'Không cần ngủ',
            description = 'Bạn đã đủ năng lượng rồi!' .. limitText,
            type = 'error',
            duration = 3000
        })
        
        -- Reset trạng thái
        isPlayerSleeping = false
        LocalPlayer.state:set('isSleeping', false, true)
        
        -- 🔧 BUG FIX: Trả lại trạng thái ghế trống khi không cần ngủ
        MarkLocationFree(location)
        currentSleepLocation = nil
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Sử dụng tọa độ CỐ ĐỊNH từ config, không phải vị trí player
    local sleepCoords = vec3(location.coords.x, location.coords.y, location.coords.z)
    local sleepHeading = location.coords.w

    isSleeping = true
    
    -- Lưu thông tin ped ban đầu (vị trí hiện tại của player)
    originalPed = ped
    originalCoords = coords -- Lưu vị trí hiện tại để restore
    originalHeading = GetEntityHeading(ped)
    
    -- 🔍 Hiển thị thông báo với thông tin sleepiness và thời gian ngủ
    local locationText = Config.Messages.startSleep
    if location and location.label then
        locationText = locationText .. ' tại ' .. location.label
    end
    
    -- Thêm thông tin sleepiness và thời gian ngủ
    local sleepTimeText = FormatSleepTime(sleepTimeMs)
    local targetSleepiness = location.maxSleepiness or 100
    locationText = locationText .. string.format(' ', 
        currentSleepiness, targetSleepiness, sleepTimeText)
    
    QBCore.Functions.Notify(locationText, 'info')
    
    -- Xử lý vị trí Z theo config
    local groundZ = sleepCoords.z -- Mặc định sử dụng Z từ config
    
    if not Config.UseExactCoords then
        -- Chỉ tìm ground nếu config cho phép (cho outdoor locations)
        local found, z = GetGroundZFor_3dCoord(sleepCoords.x, sleepCoords.y, sleepCoords.z + 10.0, false)
        if found then
            groundZ = z
        end
    end
    
    -- Đặt ped tại vị trí ngủ
    SetEntityCoords(ped, sleepCoords.x, sleepCoords.y, groundZ + Config.PedOffset, false, false, false, true)
    SetEntityHeading(ped, sleepHeading)
    
    -- Tạo prop chiếu nếu đang dùng túi ngủ (location tạm thời)
    if location.isTemporary then
        local propModel = GetHashKey('prop_yoga_mat_02')
        RequestModel(propModel)
        
        while not HasModelLoaded(propModel) do
            Wait(1)
        end
        
        -- Tạo prop chiếu ở dưới người chơi
        sleepEntity = CreateObject(propModel, sleepCoords.x, sleepCoords.y, groundZ - 0.2, true, true, false)
        SetEntityHeading(sleepEntity, sleepHeading)
        FreezeEntityPosition(sleepEntity, true)
        SetEntityCollision(sleepEntity, false, false)
    end
    
    -- Phát animation ngủ
    RequestAnimDict(Config.SleepAnimation.dict)
    while not HasAnimDictLoaded(Config.SleepAnimation.dict) do
        Wait(1)
    end
    TaskPlayAnim(ped, Config.SleepAnimation.dict, Config.SleepAnimation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- Áp dụng các biện pháp bảo vệ tối ưu
    ApplySleepProtection(ped)
    
    -- Gửi thông báo tới server
    TriggerServerEvent('sleep:startSleep')
    
    -- Bắt đầu progressbar với thời gian ngủ được tính toán
    exports['progressbar']:Progress({
        name = "sleep_progress",
        duration = sleepTimeMs, -- 🆕 Sử dụng thời gian ngủ được tính toán (túi ngủ 60s, bình thường 30s)
        label = Config.ProgressBar.label,
        useWhileDead = Config.ProgressBar.useWhileDead,
        canCancel = Config.ProgressBar.canCancel,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = Config.ProgressBar.anim,
        prop = {},
        propTwo = {}
    }, function(cancelled)
        if not cancelled then
            -- Hoàn thành việc ngủ
            WakeUp()
        else
            -- Hủy bỏ việc ngủ
            isSleeping = false
        
            local ped = PlayerPedId()
            
            -- Sử dụng hàm bỏ bảo vệ
            RemoveSleepProtection(ped)
            
            -- Xóa prop chiếu nếu có
            if sleepEntity and DoesEntityExist(sleepEntity) then
                DeleteObject(sleepEntity)
                sleepEntity = nil
            end
            
            -- Dừng animation ngủ
            ClearPedTasks(ped)
            
            -- Đặt lại vị trí ped về vị trí GỐC
            if originalCoords and originalHeading then
                if Config.UseExactRestore then
                    -- Sử dụng chính xác Z coordinate gốc, không tìm ground
                    SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, true)
                else
                    -- Tìm ground cho vị trí gốc (cho trường hợp outdoor)
                    local originalGroundZ = originalCoords.z
                    local found, z = GetGroundZFor_3dCoord(originalCoords.x, originalCoords.y, originalCoords.z + 10.0, false)
                    if found then
                        originalGroundZ = z
                    end
                    SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalGroundZ + 0.1, false, false, false, true)
                end
                SetEntityHeading(ped, originalHeading)
            end
            
            QBCore.Functions.Notify('Bạn đã hủy việc ngủ!', 'error')
            
            -- 🆕 Reset các trạng thái mới
            isPlayerSleeping = false
            LocalPlayer.state:set('isSleeping', false, true)
            
            -- 🔍 Bỏ đánh dấu vị trí đang được sử dụng
            MarkLocationFree(currentSleepLocation)
            currentSleepLocation = nil
            
            -- Reset variables
            originalPed = nil
            originalCoords = nil
            originalHeading = nil
        end
    end)
end

-- Hàm bắt đầu ngủ (fallback cho command)
local function StartSleep()
    -- Tìm vị trí ngủ gần nhất
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestLocation = nil
    local closestDistance = math.huge
    
    for _, location in ipairs(Config.SleepLocations) do
        local distance = #(coords - vec3(location.coords.x, location.coords.y, location.coords.z))
        if distance <= location.radius and distance < closestDistance then
            closestDistance = distance
            closestLocation = location
        end
    end
    
    if closestLocation then
        StartSleepAtLocation(closestLocation)
    else
        QBCore.Functions.Notify(Config.Messages.cannotSleep, 'error')
    end
end

-- Hàm thức dậy
function WakeUp()
    if not isSleeping then
        return
    end
    
    isSleeping = false
    
    local ped = PlayerPedId()
    
    -- Sử dụng hàm bỏ bảo vệ
    RemoveSleepProtection(ped)
    
    -- Xóa prop chiếu nếu có
    if sleepEntity and DoesEntityExist(sleepEntity) then
        DeleteObject(sleepEntity)
        sleepEntity = nil
    end
    
    -- Dừng animation ngủ
    ClearPedTasks(ped)
    
    -- Đặt lại vị trí ped về vị trí GỐC
    if originalCoords and originalHeading then
        if Config.UseExactRestore then
            -- Sử dụng chính xác Z coordinate gốc, không tìm ground
            SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, true)
        else
            -- Tìm ground cho vị trí gốc (cho trường hợp outdoor)
            local originalGroundZ = originalCoords.z
            local found, z = GetGroundZFor_3dCoord(originalCoords.x, originalCoords.y, originalCoords.z + 10.0, false)
            if found then
                originalGroundZ = z
            end
            SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalGroundZ + 0.1, false, false, false, true)
        end
        SetEntityHeading(ped, originalHeading)
    end
    
    QBCore.Functions.Notify(Config.Messages.wakeUp, 'success')
    
    -- Gửi thông báo tới server để tăng sleepiness (với giới hạn nếu có)
    local maxSleepiness = currentSleepLocation and currentSleepLocation.maxSleepiness or 100
    local usedItem = currentSleepLocation and currentSleepLocation.isTemporary or false
    TriggerServerEvent('sleep:finishSleep', maxSleepiness, usedItem)
    
    -- 🆕 Reset các trạng thái mới
    isPlayerSleeping = false
    LocalPlayer.state:set('isSleeping', false, true)
    
    -- 🔍 Bỏ đánh dấu vị trí đang được sử dụng
    MarkLocationFree(currentSleepLocation)
    currentSleepLocation = nil
    
    -- Reset variables
    originalPed = nil
    originalCoords = nil
    originalHeading = nil
end

-- -- Command để ngủ
-- RegisterCommand('sleep', function()
--     StartSleep()
-- end, false)

-- -- Command để thức dậy sớm
-- RegisterCommand('wakeup', function()
--     WakeUp()
-- end, false)

-- Command để reload targets (debug)
RegisterCommand('reloadsleeptargets', function()
    RemoveSleepTargets()
    Wait(1000)
    CreateSleepTargets()
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {"System", "Sleep targets reloaded!"}
    })
end, false)

-- Command để force clear tất cả ghế (admin debug)
RegisterCommand('clearsleepstatus', function()
    occupiedLocations = {}
    if Config.Debug then
        print("Đã xóa tất cả trạng thái ghế ngủ")
    end
    
    -- Cũng reset current player state nếu cần
    if not isSleeping then
        isPlayerSleeping = false
        LocalPlayer.state:set('isSleeping', false, true)
        currentSleepLocation = nil
    end
end, false)

-- -- Key mapping
-- RegisterKeyMapping('sleep', 'Bắt đầu ngủ', 'keyboard', 'F9')
-- RegisterKeyMapping('wakeup', 'Thức dậy', 'keyboard', 'F10')

-- Event để thức dậy từ server
RegisterNetEvent('sleep:forceWakeUp', function()
    WakeUp()
end)

-- Event khi player spawn
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- Reset sleeping state khi player load
    isSleeping = false
    
    -- 🌙 Tắt hiệu ứng blur nếu có
    DisableSleepBlur()
    
    local ped = PlayerPedId()
    
    -- -- Đảm bảo ped được unfreeze và khôi phục hoàn toàn
    -- FreezeEntityPosition(ped, false)
    -- SetEntityInvincible(ped, false)
    -- SetEntityCanBeDamaged(ped, true)
    -- SetEntityProofs(ped, false, false, false, false, false, false, false, false)
    -- SetEntityVisible(ped, true, true)
    -- SetEntityCollision(ped, true, true)
    -- SetEntityAlpha(ped, 255, false)
    
    -- -- Khôi phục targeting và ragdoll
    -- SetPedCanBeTargetted(ped, true)
    -- SetPedCanBeTargettedByPlayer(ped, PlayerId(), true)
    -- SetPedCanBeTargettedByTeam(ped, GetPlayerTeam(PlayerId()), true)
    -- SetPedCanRagdoll(ped, true)
    -- SetPedCanBeKnockedOffVehicle(ped, 0)
    
    -- Xóa prop chiếu nếu có
    if sleepEntity and DoesEntityExist(sleepEntity) then
        DeleteObject(sleepEntity)
        sleepEntity = nil
    end
    
    -- Dừng animation nếu đang ngủ
    ClearPedTasks(ped)
    
    -- Tạo ox_target zones
    Wait(2000) -- Đợi lâu hơn để đảm bảo player đã load hoàn toàn
    CreateSleepTargets()
end)

-- Event khi resource start (cho trường hợp player đã online)
CreateThread(function()
    Wait(5000) -- Đợi để đảm bảo tất cả đã load
    if QBCore.Functions.GetPlayerData() then
        CreateSleepTargets()
    end
end)

-- Event khi player unload
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    RemoveSleepTargets()
    
    -- 🔍 Dọn dẹp vị trí đang sử dụng
    MarkLocationFree(currentSleepLocation)
end)

-- Event khi resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RemoveSleepTargets()
    end
end)

-- Thread kiểm tra damage và tự động hủy ngủ khi bị tấn công
CreateThread(function()
    local lastHealth = 0
    local lastArmour = 0
    local healthInitialized = false
    
    while true do
        local waitTime = 1000
        
        if isSleeping then
            waitTime = Config.SleepProtection.damageCheckInterval or 100
            local ped = PlayerPedId()
            local currentHealth = GetEntityHealth(ped)
            local currentArmour = GetPedArmour(ped)
            
            -- Khởi tạo health lần đầu khi bắt đầu ngủ
            if not healthInitialized then
                lastHealth = currentHealth
                lastArmour = currentArmour
                healthInitialized = true
            end
            
            -- Kiểm tra nếu player rơi xuống nước
            if IsPedSwimming(ped) or IsPedSwimmingUnderWater(ped) then
                if Config.Debug then
                    print('[Sleep Debug] Player in water! Waking up...')
                end
                QBCore.Functions.Notify('Bạn rơi xuống nước và thức dậy!', 'error')
                
                -- Reset flag
                healthInitialized = false
                isSleeping = false
                
                -- Cancel progressbar
                TriggerEvent('progressbar:client:cancel')
                Wait(100)
                
                -- Cleanup
                RemoveSleepProtection(ped)
                if sleepEntity and DoesEntityExist(sleepEntity) then
                    DeleteObject(sleepEntity)
                    sleepEntity = nil
                end
                ClearPedTasks(ped)
                
                -- Reset states
                isPlayerSleeping = false
                LocalPlayer.state:set('isSleeping', false, true)
                MarkLocationFree(currentSleepLocation)
                currentSleepLocation = nil
                originalPed = nil
                originalCoords = nil
                originalHeading = nil
            -- Kiểm tra nếu bị xe cán hoặc va chạm mạnh
            elseif HasEntityBeenDamagedByAnyVehicle(ped) or HasEntityBeenDamagedByAnyPed(ped) then
                if Config.Debug then
                    print('[Sleep Debug] Vehicle/Ped collision detected! Waking up...')
                end
                QBCore.Functions.Notify('Bạn bị va chạm và thức dậy!', 'error')
                
                -- Clear damage flags
                ClearEntityLastDamageEntity(ped)
                
                -- Reset flag
                healthInitialized = false
                isSleeping = false
                
                -- Cancel progressbar
                TriggerEvent('progressbar:client:cancel')
                Wait(100)
                
                -- Cleanup
                RemoveSleepProtection(ped)
                if sleepEntity and DoesEntityExist(sleepEntity) then
                    DeleteObject(sleepEntity)
                    sleepEntity = nil
                end
                ClearPedTasks(ped)
                
                -- Đặt lại vị trí ped về vị trí GỐC nếu có
                if originalCoords and originalHeading then
                    if Config.UseExactRestore then
                        SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, true)
                    else
                        local originalGroundZ = originalCoords.z
                        local found, z = GetGroundZFor_3dCoord(originalCoords.x, originalCoords.y, originalCoords.z + 10.0, false)
                        if found then
                            originalGroundZ = z
                        end
                        SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalGroundZ + 0.1, false, false, false, true)
                    end
                    SetEntityHeading(ped, originalHeading)
                end
                
                -- Reset states
                isPlayerSleeping = false
                LocalPlayer.state:set('isSleeping', false, true)
                MarkLocationFree(currentSleepLocation)
                currentSleepLocation = nil
                originalPed = nil
                originalCoords = nil
                originalHeading = nil
            -- Kiểm tra nếu bị tấn công (mất máu hoặc giáp)
            elseif Config.SleepProtection.cancelOnDamage then
                if currentHealth < lastHealth or currentArmour < lastArmour then
                    -- Bị tấn công, hủy ngủ
                    if Config.Debug then
                        print('[Sleep Debug] Damage detected! Current HP:', currentHealth, 'Last HP:', lastHealth)
                    end
                    QBCore.Functions.Notify('Bạn bị tấn công và thức dậy!', 'error')
                    
                    -- Reset flag trước
                    healthInitialized = false
                    
                    -- Set isSleeping = false để tránh loop
                    isSleeping = false
                    
                    -- Cancel progressbar
                    TriggerEvent('progressbar:client:cancel')
                    
                    -- Đợi một chút rồi mới cleanup
                    Wait(100)
                    
                    -- Gọi WakeUp để dọn dẹp (không gọi lại nếu đã false)
                    local ped = PlayerPedId()
                    RemoveSleepProtection(ped)
                    
                    -- Xóa prop chiếu nếu có
                    if sleepEntity and DoesEntityExist(sleepEntity) then
                        DeleteObject(sleepEntity)
                        sleepEntity = nil
                    end
                    
                    -- Dừng animation ngủ
                    ClearPedTasks(ped)
                    
                    -- Đặt lại vị trí ped về vị trí GỐC
                    if originalCoords and originalHeading then
                        if Config.UseExactRestore then
                            SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, true)
                        else
                            local originalGroundZ = originalCoords.z
                            local found, z = GetGroundZFor_3dCoord(originalCoords.x, originalCoords.y, originalCoords.z + 10.0, false)
                            if found then
                                originalGroundZ = z
                            end
                            SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalGroundZ + 0.1, false, false, false, true)
                        end
                        SetEntityHeading(ped, originalHeading)
                    end
                    
                    -- Reset các trạng thái
                    isPlayerSleeping = false
                    LocalPlayer.state:set('isSleeping', false, true)
                    MarkLocationFree(currentSleepLocation)
                    currentSleepLocation = nil
                    originalPed = nil
                    originalCoords = nil
                    originalHeading = nil
                else
                    -- Cập nhật health và armour nếu không bị tấn công
                    lastHealth = currentHealth
                    lastArmour = currentArmour
                end
            else
                -- Cập nhật health và armour khi không bật cancelOnDamage
                lastHealth = currentHealth
                lastArmour = currentArmour
            end
            
            -- Kiểm tra và duy trì trạng thái ngủ (chỉ khi vẫn đang ngủ)
            if isSleeping then
                -- Đảm bảo animation ngủ vẫn đang chạy
                if not IsEntityPlayingAnim(ped, Config.SleepAnimation.dict, Config.SleepAnimation.anim, 3) then
                    TaskPlayAnim(ped, Config.SleepAnimation.dict, Config.SleepAnimation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
                end
                
                -- Duy trì tắt controls
                DisableAllControlActions(0)
                DisableAllControlActions(1)
                DisableAllControlActions(2)
            end
        else
            -- Reset health tracking và flag khi không ngủ
            healthInitialized = false
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then
                lastHealth = GetEntityHealth(ped)
                lastArmour = GetPedArmour(ped)
            end
        end
        
        Wait(waitTime)
    end
end)

-- Thread dọn dẹp các vị trí cũ
CreateThread(function()
    while true do
        Wait(30000) -- Kiểm tra mỗi 30 giây
        
        local currentTime = GetGameTimer()
        local locationsToClean = {}
        
        -- Tìm các vị trí đã được đánh dấu quá lâu (5 phút)
        for locationKey, data in pairs(occupiedLocations) do
            if currentTime - data.timestamp > 300000 then -- 5 phút
                table.insert(locationsToClean, locationKey)
            end
        end
        
        -- Dọn dẹp các vị trí cũ
        for _, locationKey in ipairs(locationsToClean) do
            occupiedLocations[locationKey] = nil
        end
    end
end)

-- 🔍 Debug function để kiểm tra trạng thái ghế
local function GetOccupiedLocationsStatus()
    local status = {}
    for locationKey, data in pairs(occupiedLocations) do
        table.insert(status, {
            location = locationKey,
            playerId = data.playerId,
            timestamp = data.timestamp,
            timeAgo = math.floor((GetGameTimer() - data.timestamp) / 1000) -- giây
        })
    end
    return status
end

-- Command debug để kiểm tra trạng thái ghế
-- RegisterCommand('checksleepstatus', function()
--     local status = GetOccupiedLocationsStatus()
--     print("=== TRẠNG THÁI GHẾ NGỦ ===")
    
--     if #status == 0 then
--         print("Tất cả ghế đều trống")
--     else
--         for i, data in ipairs(status) do
--             print(string.format("Ghế %s: Player %s (đã %d giây)", 
--                 data.location, data.playerId, data.timeAgo))
--         end
--     end
    
--     print("Current player sleeping:", isPlayerSleeping)
--     print("Current location:", currentSleepLocation and currentSleepLocation.label or "None")
-- end, false)

-- Command debug để test thời gian ngủ
RegisterCommand('testsleeptime', function(source, args)
    if args[1] then
        local testSleepiness = tonumber(args[1]) or 0
        testSleepiness = math.max(0, math.min(100, testSleepiness))
        
        local sleepTimeMs = CalculateSleepTime(testSleepiness)
        local sleepTimeText = FormatSleepTime(sleepTimeMs)
        local sleepinessNeeded = 100 - testSleepiness
        
        if Config.Debug then
            print("=== TEST THỜI GIAN NGỦ ===")
            print("Sleepiness hiện tại:", testSleepiness, "%")
            print("Sleepiness cần tăng:", sleepinessNeeded, "%")
            print("Thời gian ngủ:", sleepTimeText)
            print("Thời gian (ms):", sleepTimeMs)
            print("Công thức:", sleepinessNeeded, "% × 1.8s/% =", (sleepinessNeeded * 1.8), "giây")
        end
        
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            multiline = true,
            args = {"Sleep Test", string.format("Sleepiness %d%% → 100%% = %s", testSleepiness, sleepTimeText)}
        })
    else
        if Config.Debug then
            print("Usage: /testsleeptime <sleepiness_percent>")
            print("Example: /testsleeptime 50")
        end
    end
end, false)

-- Hàm ngủ bằng chiếu tại vị trí hiện tại
local function SleepWithItem()
    if isSleeping then
        QBCore.Functions.Notify(Config.Messages.alreadySleeping, 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Áp dụng offset Z từ config (hạ xuống thấp hơn)
    local zOffset = Config.SleepItem.zOffset or 1.0
    local adjustedZ = coords.z - zOffset

    -- Tạo location tạm thời dựa trên vị trí người chơi
    local tempLocation = {
        coords = vec4(coords.x, coords.y, adjustedZ, heading),
        label = Config.SleepItem.label,
        radius = 2.0,
        isTemporary = true -- Đánh dấu là vị trí tạm thời
    }

    -- Bắt đầu ngủ tại vị trí này
    StartSleepAtLocation(tempLocation)
end

-- Event xử lý khi sử dụng vật phẩm chiếu ngủ
RegisterNetEvent('sleep:useSleepItem', function()
    if not Config.SleepItem.enabled then return end
    
    SleepWithItem()
end)

-- Export StartSleepAtLocation function
exports('StartSleepAtLocation', StartSleepAtLocation)

-- Export SleepWithItem function
exports('SleepWithItem', SleepWithItem)

-- Export hàm ngủ với tọa độ và maxSleepiness tùy chỉnh cho resource khác sử dụng
-- Tham số: 
--   coord (vector4) - Tọa độ để ngủ (x, y, z, heading), nếu nil sẽ dùng vị trí hiện tại
--   maxSleepiness (number) - Giới hạn sleepiness tối đa (mặc định 100)
exports('SleepWithMaxSleepiness', function(coord, maxSleepiness)
    if isSleeping then
        QBCore.Functions.Notify(Config.Messages.alreadySleeping, 'error')
        return false
    end

    local ped = PlayerPedId()
    local sleepCoords, sleepHeading
    
    -- Xử lý tọa độ
    if coord then
        sleepCoords = vec3(coord.x, coord.y, coord.z)
        sleepHeading = coord.w
    else
        -- Nếu không có coord, dùng vị trí hiện tại
        sleepCoords = GetEntityCoords(ped)
        sleepHeading = GetEntityHeading(ped)
    end

    -- Áp dụng offset Z từ config
    local zOffset = Config.SleepItem.zOffset or 1.0
    local adjustedZ = sleepCoords.z - zOffset

    -- Tạo location tạm thời với maxSleepiness tùy chỉnh
    local tempLocation = {
        coords = vec4(sleepCoords.x, sleepCoords.y, adjustedZ, sleepHeading),
        label = "Ngủ tạm thời",
        radius = 2.0,
        isTemporary = false, -- Không dùng item nên không trừ độ bền
        maxSleepiness = maxSleepiness or 100 -- Sử dụng giá trị tùy chỉnh hoặc mặc định 100
    }

    -- Bắt đầu ngủ tại vị trí này
    StartSleepAtLocation(tempLocation)
    return true
end)
