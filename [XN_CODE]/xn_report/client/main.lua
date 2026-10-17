local isUiOpen = false
local lastReportTime = 0

-- Hàm quét danh sách người chơi trong bán kính Config.NearbyRadius
local function GetNearbyPlayersData()
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local nearbyList = {}

    local activePlayers = GetActivePlayers()
    for _, player in ipairs(activePlayers) do
        local targetPed = GetPlayerPed(player)
        if DoesEntityExist(targetPed) then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(myCoords - targetCoords)

            if distance <= Config.NearbyRadius then
                local serverId = GetPlayerServerId(player)
                local isSelf = (player == PlayerId())

                table.insert(nearbyList, {
                    serverId = serverId,
                    isSelf = isSelf,
                    distance = math.floor(distance * 10) / 10,
                    inVehicle = IsPedInAnyVehicle(targetPed, false)
                })
            end
        end
    end

    return nearbyList
end

-- Hàm định dạng thời gian cooldown hiển thị đẹp mắt
local function FormatCooldownTime(seconds)
    if seconds >= 60 then
        local mins = math.floor(seconds / 60)
        local secs = seconds % 60
        if secs > 0 then
            return ('%s phút %s giây'):format(mins, secs)
        else
            return ('%s phút'):format(mins)
        end
    end
    return ('%s giây'):format(seconds)
end

-- Hàm mở UI Report
local function OpenReportMenu()
    if isUiOpen then return end

    local currentTime = GetGameTimer() / 1000
    local remaining = 0
    if lastReportTime > 0 and (currentTime - lastReportTime) < Config.Cooldown then
        remaining = math.ceil(Config.Cooldown - (currentTime - lastReportTime))
    end

    isUiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        config = {
            apiKey = Config.FiveManage.ApiKey,
            uploadUrl = Config.FiveManage.UploadUrl,
            recordDuration = Config.RecordDuration,
            fps = Config.RecordFPS,
            cooldownRemaining = remaining,
            cooldownTotal = Config.Cooldown
        }
    })
end

-- Đăng ký lệnh mở Report
RegisterCommand(Config.Command, function()
    OpenReportMenu()
end, false)

if Config.CommandAliases then
    for _, alias in ipairs(Config.CommandAliases) do
        RegisterCommand(alias, function()
            OpenReportMenu()
        end, false)
    end
end

-- NUI Callback: Bắt đầu ghi hình (Thả chuột để người chơi nhìn/chơi game bình thường)
RegisterNUICallback('recordingStarted', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- NUI Callback: Đóng giao diện
RegisterNUICallback('close', function(_, cb)
    isUiOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- NUI Callback: Gửi báo cáo
RegisterNUICallback('submitReport', function(data, cb)
    local currentTime = GetGameTimer() / 1000
    if lastReportTime > 0 and (currentTime - lastReportTime) < Config.Cooldown then
        local remaining = math.ceil(Config.Cooldown - (currentTime - lastReportTime))
        local timeFormatted = FormatCooldownTime(remaining)
        if lib and lib.notify then
            lib.notify({
                title = 'Hệ Thống Report',
                description = ('Vui lòng đợi %s nữa trước khi gửi report tiếp theo!'):format(timeFormatted),
                type = 'error',
                duration = 6000
            })
        end
        isUiOpen = false
        SetNuiFocus(false, false)
        cb('cooldown')
        return
    end

    isUiOpen = false
    SetNuiFocus(false, false)
    lastReportTime = GetGameTimer() / 1000

    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local nearbyPlayers = GetNearbyPlayersData()

    local payload = {
        reason = data.reason or 'Không có lý do cụ thể',
        videoUrl = data.videoUrl or nil,
        duration = data.duration or Config.RecordDuration,
        coords = {
            x = math.floor(myCoords.x * 100) / 100,
            y = math.floor(myCoords.y * 100) / 100,
            z = math.floor(myCoords.z * 100) / 100
        },
        nearbyPlayers = nearbyPlayers
    }

    TriggerServerEvent('xn_report:server:submitReport', payload)

    if lib and lib.notify then
        lib.notify({
            title = 'Hệ Thống Report',
            description = 'Báo cáo của bạn đã được ghi hình và gửi đến Admin!',
            type = 'success',
            duration = 6000
        })
    end

    cb('ok')
end)

-- NUI Callback: Lấy danh sách lịch sử report của bản thân
RegisterNUICallback('getReportHistory', function(_, cb)
    local reports = lib.callback.await('xn_report:server:getPlayerReports', false) or {}
    cb(reports)
end)

-- NUI Callback: Thông báo khi copy link thành công
RegisterNUICallback('copyNotify', function(data, cb)
    if lib and lib.notify then
        lib.notify({
            title = 'Sao Chép Thành Công',
            description = 'Đã sao chép link video vào clipboard!',
            type = 'success',
            duration = 3000
        })
    end
    cb('ok')
end)
