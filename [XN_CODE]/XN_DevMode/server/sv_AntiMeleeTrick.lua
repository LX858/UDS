-- Server side Anti Melee Trick
-- Log và xử lý người chơi abuse melee trick

local meleeAbuseLogs = {}

-- [[
RegisterNetEvent('XN_DevMode:server:LogMeleeAbuse', function(punchCount)
    local source = source
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    local playerName = GetPlayerName(source)
    
    -- Khởi tạo log cho player nếu chưa có
    if not meleeAbuseLogs[citizenid] then
        meleeAbuseLogs[citizenid] = {
            count = 0,
            lastTime = 0
        }
    end
    
    local currentTime = os.time()
    local timeSinceLastLog = currentTime - meleeAbuseLogs[citizenid].lastTime
    
    -- Nếu spam trong vòng 5 phút
    if timeSinceLastLog < 300 then
        meleeAbuseLogs[citizenid].count = meleeAbuseLogs[citizenid].count + 1
    else
        meleeAbuseLogs[citizenid].count = 1
    end
    
    meleeAbuseLogs[citizenid].lastTime = currentTime
    
    -- Log vào console
    print(('[Anti-Melee] %s (%s) đã bị phát hiện spam đấm: %d lần'):format(
        playerName,
        citizenid,
        punchCount
    ))
    
    -- Nếu vi phạm quá nhiều lần (5 lần trong 5 phút)
    if meleeAbuseLogs[citizenid].count >= 5 then
        -- Gửi cảnh báo cho admin
        TriggerClientEvent('chat:addMessage', -1, {
            template = '<div class="chat-message system"><b>ANTI-CHEAT:</b> Người chơi {0} đã bị phát hiện lạm dụng melee trick nhiều lần!</div>',
            args = {playerName}
        })
        
        -- Có thể thêm hành động như kick hoặc ban tạm thời
        -- DropPlayer(source, 'Bạn đã bị kick do lạm dụng melee trick!')
        
        -- Reset counter
        meleeAbuseLogs[citizenid].count = 0
    end
end)
--]]

-- Command cho admin kiểm tra log
lib.addCommand('checkmeleeabuse', {
    help = 'Kiểm tra log melee abuse',
    restricted = 'group.admin'
}, function(source)
    local logMessage = '===== MELEE ABUSE LOGS =====\n'
    local hasLogs = false
    
    for citizenid, data in pairs(meleeAbuseLogs) do
        if data.count > 0 then
            hasLogs = true
            logMessage = logMessage .. string.format('CitizenID: %s - Vi phạm: %d lần - Lần cuối: %s\n',
                citizenid,
                data.count,
                os.date('%Y-%m-%d %H:%M:%S', data.lastTime)
            )
        end
    end
    
    if not hasLogs then
        logMessage = logMessage .. 'Không có log vi phạm nào.\n'
    end
    
    logMessage = logMessage .. '============================'
    print(logMessage)
    
    TriggerClientEvent('chat:addMessage', source, {
        args = {'SYSTEM', 'Check console để xem log melee abuse'}
    })
end)
