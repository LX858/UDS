QBCore = exports['qb-core']:GetCoreObject()
local scriptname = GetCurrentResourceName()

-- Dữ liệu phòng
local roomData = {
    status = 'idle', -- idle, waiting, running
    players = {},
    playersBySource = {},
    playerBomb = {},
    playerBombSet = {},
    losers = {}, -- Danh sách người thua (đã chết)
    maxPlayers = 20,
    map = 'map1',
    waitTime = 30,
    entryFee = 0,
    winner = nil,
    adminSource = nil,
    autoNotify = true, -- Bật/tắt thông báo tự động
    rewardGiven = false, -- Đã trao thưởng chưa
    totalPlayersAtStart = 0, -- Tổng số người tham gia ban đầu (dùng để tính tiền)
    isEnding = false,         -- Flag chống race condition
    endGameScheduled = false, -- Đã lên lịch EndBomberEvent chưa
    lastBomber = nil          -- Source của người cầm bom cuối cùng khi nổ (người THUA)
}

-- Per-player transfer cooldown (tránh double-assign khi nhiều request đến cùng lúc)
local playerTransferCooldown = {}

local function AddPlayerBomb(src)
    if roomData.playerBombSet[src] then return false end
    roomData.playerBombSet[src] = true
    table.insert(roomData.playerBomb, src)
    return true
end

local function RemovePlayerBomb(src)
    if not roomData.playerBombSet[src] then return false end
    roomData.playerBombSet[src] = nil
    for k, v in ipairs(roomData.playerBomb) do
        if v == src then
            table.remove(roomData.playerBomb, k)
            break
        end
    end
    -- Giải phóng cooldown transfer nếu player bị xóa bom (chết/quit giữa chuyển)
    playerTransferCooldown[src] = nil
    return true
end

local function BroadcastBomberList()
    local bomberList = roomData.playerBomb
    for _, player in ipairs(roomData.players) do
        TriggerClientEvent(scriptname .. ':updateBomberList', player.source, bomberList)
    end
end

local function IsPlayerInRoom(src)
    if not src then return false end
    local srcNum = tonumber(src)
    for _, p in ipairs(roomData.players) do
        if tonumber(p.source) == srcNum then
            return true
        end
    end
    return false
end

-- Lệnh admin mở UI
RegisterCommand('bom', function(source, args, rawCommand)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then 
        return 
    end
    
    -- Kiểm tra quyền admin/mod
    if QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god') or QBCore.Functions.HasPermission(src, 'mod') then
        roomData.adminSource = src
        TriggerClientEvent(scriptname .. ':openAdminPanel', src, roomData)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có quyền sử dụng lệnh này!', 'error')
    end
end, false)

-- Hàm xử lý yêu cầu tham gia
local function RequestJoin(src)
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local mapNames = {
        ['map1'] = 'Vị trí tùy chỉnh'
    }
    
    local playerList = {}
    for _, p in pairs(roomData.players) do
        playerList[#playerList + 1] = {
            source = p.source,
            name = p.name,
            hasQuit = p.hasQuit or false
        }
    end
    
    if roomData.status ~= 'waiting' then
        TriggerClientEvent(scriptname .. ':showJoinUI', src, {
            map = roomData.map,
            mapName = mapNames[roomData.map],
            maxPlayers = roomData.maxPlayers,
            playerCount = #roomData.players,
            gameTime = roomData.waitTime,
            entryFee = roomData.entryFee,
            alreadyJoined = IsPlayerInRoom(src),
            players = playerList,
            status = roomData.status
        })
        TriggerClientEvent('QBCore:Notify', src, 'Hiện không có sự kiện nào đang mở!', 'error')
        return
    end
    
    -- Kiểm tra đã tham gia chưa
    if IsPlayerInRoom(src) then
        TriggerClientEvent(scriptname .. ':showJoinUI', src, {
            map = roomData.map,
            mapName = mapNames[roomData.map],
            maxPlayers = roomData.maxPlayers,
            playerCount = #roomData.players,
            gameTime = roomData.waitTime,
            entryFee = roomData.entryFee,
            alreadyJoined = true,
            players = playerList,
            status = roomData.status
        })
        return
    end
    
    -- Kiểm tra số lượng
    if #roomData.players >= roomData.maxPlayers then
        TriggerClientEvent(scriptname .. ':showJoinUI', src, {
            map = roomData.map,
            mapName = mapNames[roomData.map],
            maxPlayers = roomData.maxPlayers,
            playerCount = #roomData.players,
            gameTime = roomData.waitTime,
            entryFee = roomData.entryFee,
            alreadyJoined = false,
            players = playerList,
            status = roomData.status
        })
        TriggerClientEvent('QBCore:Notify', src, 'Phòng đã đầy!', 'error')
        return
    end
    
    -- Hiển thị UI cho người chơi
    TriggerClientEvent(scriptname .. ':showJoinUI', src, {
        map = roomData.map,
        mapName = mapNames[roomData.map],
        maxPlayers = roomData.maxPlayers,
        playerCount = #roomData.players,
        gameTime = roomData.waitTime,
        entryFee = roomData.entryFee,
        alreadyJoined = false,
        players = playerList,
        status = roomData.status
    })
end

-- Lệnh người chơi tham gia
RegisterCommand('bomber', function(source, args, rawCommand)
    RequestJoin(source)
end, false)

-- Event người chơi tham gia qua Target
RegisterNetEvent(scriptname .. ':requestJoin', function()
    RequestJoin(source)
end)

-- Lệnh reset skin
RegisterCommand(Config.LenhResetSkin, function(source, args, rawCommand)
    local src = source
    TriggerClientEvent(scriptname .. 'restskinall', src)
end, false)

-- NUI Callbacks
RegisterNetEvent(scriptname .. ':createRoom', function(data)
    local src = source
    
    if src ~= roomData.adminSource then return end
    
    roomData.maxPlayers = data.maxPlayers
    roomData.map = data.map
    roomData.entryFee = data.entryFee or 0
    roomData.waitTime = data.waitTime
    roomData.autoNotify = data.autoNotify == nil and true or data.autoNotify -- Mặc định bật
    roomData.status = 'waiting'
    roomData.winner = nil
    roomData.players = {}
    roomData.losers = {}
    roomData.rewardGiven = false
    roomData.isEnding = false
    roomData.endGameScheduled = false
    roomData.lastBomber = nil
    
    -- Không thông báo cho tất cả người chơi (đã tắt)
    -- TriggerClientEvent('QBCore:Notify', -1, 'Sự kiện Bomber đã mở! Gõ /bomber để tham gia', 'success')
    
    UpdateAdminUI()
end)

RegisterNetEvent(scriptname .. ':startBomberEvent', function(data)
    local src = source
    
    if src ~= roomData.adminSource then return end
    
    if roomData.status ~= 'waiting' then
        TriggerClientEvent('QBCore:Notify', src, 'Chưa tạo phòng hoặc đã bắt đầu rồi!', 'error')
        return
    end
    
    if #roomData.players <= 1 then
        TriggerClientEvent('QBCore:Notify', src, 'Cần tối thiểu 2 người chơi để bắt đầu sự kiện!', 'error')
        return
    end
    
    -- Bắt đầu game ngay lập tức
    StartGame()
end)
-- Người chơi xác nhận tham gia
RegisterNetEvent(scriptname .. ':confirmJoin', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    if roomData.status ~= 'waiting' then
        TriggerClientEvent('QBCore:Notify', src, 'Sự kiện đã đóng hoặc đã bắt đầu!', 'error')
        return
    end
    
    -- Kiểm tra đã tham gia chưa
    if IsPlayerInRoom(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn đã tham gia rồi!', 'error')
        return
    end
    
    -- Kiểm tra số lượng
    if #roomData.players >= roomData.maxPlayers then
        TriggerClientEvent('QBCore:Notify', src, 'Phòng đã đầy!', 'error')
        return
    end
    
    -- Kiểm tra và trừ tiền
    if roomData.entryFee > 0 then
        local money = Player.Functions.GetMoney('cash')
        if money < roomData.entryFee then
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không đủ tiền! Cần $' .. roomData.entryFee, 'error')
            return
        end
        
        Player.Functions.RemoveMoney('cash', roomData.entryFee, 'bomber-entry-fee')
    end
    
    -- Thêm người chơi
    local playerEntry = {
        source = src,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        identifier = Player.PlayerData.citizenid,
        hasQuit = false -- Đánh dấu người chơi chưa quit
    }
    table.insert(roomData.players, playerEntry)
    roomData.playersBySource[src] = playerEntry
    
    TriggerClientEvent('QBCore:Notify', src, 'Bạn đã tham gia sự kiện Bomber thành công!', 'success')
    
    -- Cập nhật UI admin
    UpdateAdminUI()
    
    -- Gọi hàm log
    join(src)
end)


RegisterNetEvent(scriptname .. ':stopBomberEvent', function()
    local src = source
    
    if src ~= roomData.adminSource then return end
    
    EndBomberEvent()
end)

RegisterNetEvent(scriptname .. ':requestRoomPlayers', function()
    local src = source
    local playerList = {}
    for _, p in pairs(roomData.players) do
        playerList[#playerList + 1] = {
            source = p.source,
            name = p.name,
            hasQuit = p.hasQuit or false
        }
    end

    TriggerClientEvent(scriptname .. ':showJoinUI', src, {
        map = roomData.map,
        mapName = 'Vị trí tùy chỉnh',
        maxPlayers = roomData.maxPlayers,
        playerCount = #roomData.players,
        gameTime = roomData.waitTime,
        entryFee = roomData.entryFee,
        alreadyJoined = IsPlayerInRoom(src),
        players = playerList,
        status = roomData.status
    })
end)

RegisterNetEvent(scriptname .. ':closeAdminPanel', function()
    -- Đóng UI
end)

RegisterNetEvent(scriptname .. ':sendNotificationStart', function()
    local src = source
    
    if src ~= roomData.adminSource then return end
    
    -- Gọi export xn_thongbao để gửi thông báo bắt đầu
    local notifyConfig = Config.ThongBaoSuKien.BatDau
    
    exports['xn_thongbao']:SendAnnouncementToAll(
        'SERVER',
        notifyConfig.Message,
        notifyConfig.Duration
    )
end)

RegisterNetEvent(scriptname .. ':sendNotificationEnd', function()
    local src = source
    
    if src ~= roomData.adminSource then return end
    
    -- Nếu tắt auto notify, cộng tiền khi admin bấm nút này
    if not roomData.autoNotify then
        GiveReward()
    end
    
    -- Gọi export xn_thongbao để gửi thông báo kết thúc
    local notifyConfig = Config.ThongBaoSuKien.KetThuc
    local winnerName = roomData.winner and roomData.winner.name or 'Không có người thắng'
    
    -- Thay thế {winner} bằng tên người thắng
    local message = string.gsub(notifyConfig.Message, '{winner}', winnerName)
    
    exports['xn_thongbao']:SendAnnouncementToAll(
        'SERVER',
        message,
        notifyConfig.Duration
    )
end)

-- Admin A/D: chuyển sang player kế tiếp / trước trong danh sách
RegisterNetEvent(scriptname .. ':adminGetNextPlayer', function(currentSource, direction)
    local src = source
    if src ~= roomData.adminSource then return end
    if not roomData.players or #roomData.players == 0 then return end

    local currentIndex = 1
    for i, p in ipairs(roomData.players) do
        if p.source == currentSource then
            currentIndex = i
            break
        end
    end

    local newIndex = currentIndex + direction
    if newIndex < 1 then newIndex = #roomData.players end
    if newIndex > #roomData.players then newIndex = 1 end

    local newTarget = roomData.players[newIndex].source
    TriggerClientEvent(scriptname .. ':adminSwitchTarget', src, newTarget)
end)

-- Event từ client sau khi vỗ tay xong (nếu bật auto notify)
RegisterNetEvent(scriptname .. ':finishAwardCeremony', function()
    local src = source
    
    -- Chỉ cộng tiền nếu bật auto notify
    if roomData.autoNotify and roomData.winner and roomData.winner.source == src then
        GiveReward()
    end
end)

-- Hàm cập nhật UI admin
function UpdateAdminUI()
    if roomData.adminSource then
        TriggerClientEvent(scriptname .. ':updateRoomData', roomData.adminSource, roomData)
    end
end

-- Hàm hồi sinh người chơi đa nền tảng (server-side)
function RevivePlayer(src)
    if GetResourceState('qbx_medical') == 'started' then
        pcall(function()
            exports['qbx_medical']:Revive(src)
        end)
    elseif GetResourceState('qb-ambulancejob') == 'started' then
        TriggerClientEvent('hospital:client:Revive', src)
    elseif GetResourceState('wasabi_ambulance') == 'started' then
        pcall(function()
            exports['wasabi_ambulance']:Revive(src)
        end)
    else
        -- Fallback
        TriggerClientEvent('hospital:client:Revive', src)
    end
end

-- Revive player (server-side)
RegisterNetEvent(scriptname .. ':reviveMe', function()
    local src = source
    RevivePlayer(src)
end)

-- Khai báo trước StartGame để cả StartGame lẫn event handler dùng chung 1 biến
local countdownReadySet = {}

-- Bắt đầu game
function StartGame()
    roomData.status = 'running'
    roomData.totalPlayersAtStart = #roomData.players -- Lưu tổng số người ban đầu để tính tiền
    countdownReadySet = {} -- Reset danh sách vote countdown mỗi ván mới
    
    local mapConfig = Config.Maps[roomData.map]
    
    -- Teleport tất cả người chơi vào map
    for k, player in pairs(roomData.players) do
        local src = player.source
        
        -- Gửi dữ liệu map cho client
        TriggerClientEvent(scriptname .. ':startGame', src, {
            coords = mapConfig.coords,
            radius = mapConfig.radius,
            dimension = mapConfig.dimension,
            spawnRange = Config.PhamViSpawnNgauNhien,
            waitTime = roomData.waitTime or 30
        })
    end
    
    UpdateAdminUI()
    -- SelectBomber sẽ được gọi khi client báo countdownDone (không dùng timer cộng thêm nữa)
end

-- Client báo countdown kết thúc → chọn người cầm bom
RegisterNetEvent(scriptname .. ':countdownDone', function()
    local src = source
    if roomData.status ~= 'running' then return end

    -- Kiểm tra src có trong danh sách người chơi không
    local inGame = false
    for _, p in ipairs(roomData.players) do
        if p.source == src then inGame = true; break end
    end
    if not inGame then return end

    countdownReadySet[src] = true

    -- Đếm số người đã báo xong
    local readyCount = 0
    for _ in pairs(countdownReadySet) do readyCount = readyCount + 1 end

    -- Nếu đây là người đầu tiên báo → đặt timeout 3s chờ những người lag
    -- (cũng là fallback nếu một số client không bao giờ báo)
    if readyCount == 1 then
        Citizen.SetTimeout(3000, function()
            if roomData.status == 'running' and #roomData.playerBomb == 0 then
                countdownReadySet = {}
                SelectBomber()
            end
        end)
    end

    -- Nếu tất cả đã báo xong trước timeout → gọi ngay, không cần đợi 3s
    if readyCount >= #roomData.players and #roomData.playerBomb == 0 then
        countdownReadySet = {}
        SelectBomber()
    end
end)

-- Tính số lượng bom cần thiết dựa vào số người còn sống
-- <= 5 người = 1 bom; cứ thêm 5 người = thêm 1 bom
function GetBombCount(playerCount)
    if playerCount <= 0 then return 0 end
    return math.floor((playerCount - 1) / 5) + 1
end

-- Giảm bom về đúng số cần thiết khi số người còn sống giảm
-- Gọi sau mỗi lần có người chết/quit (TRƯỚC khi SelectBomber mới)
function AdjustBombCount()
    local needed = GetBombCount(#roomData.players)
    local current = #roomData.playerBomb
    
    -- Nếu đang có nhiều bom hơn mức cần, xóa bớt
    while #roomData.playerBomb > needed do
        -- Lấy người cầm bom cuối cùng trong danh sách để xóa bom
        local src = roomData.playerBomb[#roomData.playerBomb]
        RemovePlayerBomb(src)
        -- Báo client xóa bom (clearBomb không nổ)
        TriggerClientEvent(scriptname .. ':clearBomb', src)
    end
    
    if current ~= needed then
        -- Cập nhật danh sách mới
        BroadcastBomberList()
    end
end

-- Chọn người cầm bom
function SelectBomber()
    -- Reset thời gian bom về ban đầu khi chọn bomber mới
    roomData.bombTimeRemaining = nil
    
    -- Tính số bom cần dựa theo số người còn sống
    local needed = GetBombCount(#roomData.players)
    if needed <= 0 then return end
    
    -- Số bom còn thiếu (so với đang active)
    local toAssign = needed - #roomData.playerBomb
    if toAssign <= 0 then
        BroadcastBomberList()
        return
    end
    
    -- Lấy danh sách người chưa cầm bom để chọn ngẫu nhiên
    local tempPlayers = {}
    for _, player in ipairs(roomData.players) do
        if not roomData.playerBombSet[player.source] then
            tempPlayers[#tempPlayers + 1] = player
        end
    end
    
    for i = 1, toAssign do
        if #tempPlayers == 0 then break end
        local randomIndex = math.random(1, #tempPlayers)
        local selectedPlayer = tempPlayers[randomIndex]
        AddPlayerBomb(selectedPlayer.source)
        TriggerClientEvent(scriptname .. ':holdBomb', selectedPlayer.source, nil)
        table.remove(tempPlayers, randomIndex)
    end
    
    -- Gửi danh sách người cầm bom cho tất cả
    BroadcastBomberList()
end

-- Kiểm tra điều kiện thắng: KHÔNG tự động kết thúc, chỉ khi admin bấm Stop
function CheckWinCondition()
    -- Không làm gì, game chạy cho đến khi admin bấm Stop
    -- Admin sẽ quyết định khi nào kết thúc
end

-- Chuyển bom
RegisterNetEvent(scriptname .. ':transferBomb', function(targetSource, currentBombTime)
    local src = source

    -- Chặn chuyển bom khi còn <= 3 giây
    if currentBombTime and currentBombTime <= 3 then
        TriggerClientEvent('QBCore:Notify', src, '⏰ Bom còn quá ít thời gian! Không thể chuyển!', 'error')
        return
    end

    -- Cooldown per-player: chỉ lock người GỬI để tránh double-send
    -- KHÔNG lock target ngay (target chưa nhận bom, lock sẽ block người khác chuyển cho target)
    if playerTransferCooldown[src] then return end
    playerTransferCooldown[src] = true

    -- Kiểm tra src đang thực sự cầm bom
    if not roomData.playerBombSet[src] then
        playerTransferCooldown[src] = nil
        return
    end

    -- Kiểm tra target còn trong game không (chưa chết/quit)
    local targetAlive = false
    for _, player in ipairs(roomData.players) do
        if player.source == targetSource then
            targetAlive = true
            break
        end
    end
    if not targetAlive then
        TriggerClientEvent('QBCore:Notify', src, '❌ Người chơi đó đã thoát hoặc không hợp lệ!', 'error')
        playerTransferCooldown[src] = nil
        return
    end

    -- Kiểm tra target chưa đang cầm bom (tránh gán 2 lần)
    if roomData.playerBombSet[targetSource] then
        TriggerClientEvent('QBCore:Notify', src, '💣 Người chơi đó đang cầm bom rồi!', 'error')
        playerTransferCooldown[src] = nil
        return
    end

    if not RemovePlayerBomb(src) then
        playerTransferCooldown[src] = nil
        return
    end

    -- Lưu thời gian bom nếu config bật
    if Config.BomNoCodinh and currentBombTime then
        roomData.bombTimeRemaining = currentBombTime
    end

    -- Thêm người nhận vào danh sách
    AddPlayerBomb(targetSource)

    -- Xóa bom của người gửi
    TriggerClientEvent(scriptname .. ':clearBomb', src)

    -- Cập nhật danh sách ngay lập tức
    BroadcastBomberList()

    -- Dùng SetTimeout để không block thread, lock target trong thời gian chờ
    -- Lock target TẠI ĐÂY (sau khi đã add vào playerBomb) để tránh transfer kép
    playerTransferCooldown[targetSource] = true
    local waitMs = Config.ThoiGianChoTruocKhiChuyen * 1000
    Citizen.SetTimeout(waitMs, function()
        -- Kiểm tra lại target vẫn còn trong set bom
        if roomData.playerBombSet[targetSource] then
            TriggerClientEvent(scriptname .. ':holdBomb', targetSource, Config.BomNoCodinh and roomData.bombTimeRemaining or nil)
        end
        -- Gỡ cooldown sau khi hoàn thành
        playerTransferCooldown[src] = nil
        playerTransferCooldown[targetSource] = nil
    end)
end)

-- Người chơi chết trong ván (không cầm bom, chết do nổ lây) → xóa khỏi danh sách
RegisterNetEvent(scriptname .. ':playerDiedInGame', function()
    local src = source
    local srcNum = tonumber(src)
    if roomData.status ~= 'running' then return end

    -- Xóa khỏi danh sách cầm bom (nếu có)
    RemovePlayerBomb(src)

    -- Lưu vào losers TRƯỚC KHI xóa khỏi players
    -- Đánh dấu đây là người chết do nổ lây (không phải bomber)
    for k, player in pairs(roomData.players) do
        if tonumber(player.source) == srcNum then
            local playerCopy = {}
            for key, val in pairs(player) do playerCopy[key] = val end
            playerCopy.diedFromExplosion = true -- chết do nổ lây, không phải cầm bom
            table.insert(roomData.losers, playerCopy)
            break
        end
    end

    -- Xóa khỏi danh sách người chơi
    local removed = false
    for k, player in pairs(roomData.players) do
        if tonumber(player.source) == srcNum then
            table.remove(roomData.players, k)
            removed = true
            break
        end
    end

    if not removed then return end

    -- Cập nhật admin UI
    if roomData.adminSource then
        TriggerClientEvent(scriptname .. ':updateRoomData', roomData.adminSource, roomData)
    end

    -- Kiểm tra điều kiện kết thúc game
    if Config.TestModeAllDead then
        if #roomData.players == 0 then
            ScheduleEndGame()
            return
        end
    else
        if #roomData.players <= 1 then
            ScheduleEndGame()
            return
        end
    end

    -- Điều chỉnh số bom phù hợp với số người còn sống
    AdjustBombCount()

    -- Sau khi điều chỉnh, nếu vẫn thiếu bom → chọn người mới cầm
    local needed = GetBombCount(#roomData.players)
    if #roomData.playerBomb < needed and roomData.status == 'running' then
        Citizen.SetTimeout(3000, function()
            if #roomData.players > 0 then
                SelectBomber()
            end
        end)
    else
        BroadcastBomberList()
    end
end)

-- Người chơi chết khi cầm bom (người này là NGƯỜI THUA)
RegisterNetEvent(scriptname .. ':bomberDied', function()
    local src = source
    if roomData.status ~= 'running' then return end

    -- Ghi lại người cầm bom cuối cùng khi nổ → đây là người THUA
    roomData.lastBomber = src

    local srcNum = tonumber(src)
    -- Xóa khỏi danh sách cầm bom (dùng RemovePlayerBomb để đồng bộ cả playerBombSet)
    RemovePlayerBomb(src)

    -- Lưu vào losers TRƯỚC KHI xóa khỏi players
    -- Đánh dấu đây là người cầm bom (bomber)
    for k, player in pairs(roomData.players) do
        if tonumber(player.source) == srcNum then
            local playerCopy = {}
            for key, val in pairs(player) do playerCopy[key] = val end
            playerCopy.wasBomber = true -- người cầm bom = người thua
            table.insert(roomData.losers, playerCopy)
            break
        end
    end

    -- Xóa người chết khỏi danh sách người chơi
    for k, player in pairs(roomData.players) do
        if tonumber(player.source) == srcNum then
            table.remove(roomData.players, k)
            break
        end
    end

    -- Kiểm tra điều kiện kết thúc game
    if Config.TestModeAllDead then
        if #roomData.players == 0 then
            ScheduleEndGame()
            return
        end
    else
        if #roomData.players <= 1 then
            ScheduleEndGame()
            return
        end
    end

    -- Điều chỉnh số bom phù hợp với số người còn sống
    AdjustBombCount()

    -- Sau khi điều chỉnh, nếu vẫn thiếu bom → chọn người mới cầm
    local needed = GetBombCount(#roomData.players)
    if #roomData.playerBomb < needed and roomData.status == 'running' then
        Citizen.SetTimeout(3000, function()
            if #roomData.players > 0 then
                SelectBomber()
            end
        end)
    else
        BroadcastBomberList()
    end
end)

-- Người chơi quit sớm khỏi ván
RegisterNetEvent(scriptname .. ':playerQuit', function()
    local src = source
    local srcNum = tonumber(src)
    
    -- Thêm vào losers nếu còn sống (còn trong players list)
    for k, player in pairs(roomData.players) do
        if tonumber(player.source) == srcNum then
            player.hasQuit = true
            table.insert(roomData.losers, player)
            break
        end
    end
    
    -- Xóa khỏi danh sách người chơi
    local inRoom = false
    for k, player in pairs(roomData.players) do
        if tonumber(player.source) == srcNum then
            table.remove(roomData.players, k)
            inRoom = true
            break
        end
    end
    
    if inRoom then
        roomData.playersBySource[src] = nil
        roomData.playersBySource[srcNum] = nil
    end
    
    -- Xóa khỏi bảng cầm bom nếu đang cầm
    RemovePlayerBomb(src)
    
    -- Kiểm tra điều kiện kết thúc game
    if Config.TestModeAllDead then
        if #roomData.players == 0 then
            ScheduleEndGame()
            return
        end
    else
        if #roomData.players <= 1 then
            ScheduleEndGame()
            return
        end
    end

    -- Điều chỉnh số bom phù hợp với số người còn sống
    AdjustBombCount()

    -- Sau khi điều chỉnh, nếu vẫn thiếu bom → chọn người mới cầm
    local needed = GetBombCount(#roomData.players)
    if #roomData.playerBomb < needed and roomData.status == 'running' and #roomData.players > 0 then
        Citizen.SetTimeout(3000, function()
            if #roomData.players > 0 then
                SelectBomber()
            end
        end)
    else
        BroadcastBomberList()
    end
end)

-- Lên lịch EndBomberEvent sau 300ms để chờ tất cả death event đồng thời xử lý xong
function ScheduleEndGame()
    if roomData.endGameScheduled or roomData.isEnding then return end
    roomData.endGameScheduled = true
    Citizen.SetTimeout(300, function()
        if roomData.status == 'running' and not roomData.isEnding then
            EndBomberEvent()
        end
    end)
end

-- Kết thúc sự kiện
function EndBomberEvent()
    -- Chống race condition: nếu đang kết thúc rồi thì bỏ qua
    if roomData.isEnding then return end
    roomData.isEnding = true

    -- Trường hợp 1: Còn 1 người thắng
    if #roomData.players == 1 then
        -- Chỉ còn 1 người → người đó thắng
        local winner = roomData.players[1]
        roomData.winner = winner
        roomData.rewardGiven = false
        
        -- Hiển thị người thắng trên UI admin
        if roomData.adminSource then
            TriggerClientEvent(scriptname .. ':showWinner', roomData.adminSource, winner)
        end
        
        -- Xóa prop bom
        TriggerClientEvent(scriptname .. ':removeBombProp', winner.source)
        Citizen.Wait(500)
        
        -- REVIVE TẤT CẢ NGƯỜI THUA TRƯỚC (để client event handler có thể chạy)
        for k, loser in pairs(roomData.losers) do
            RevivePlayer(loser.source)
        end
        
        -- Đợi revive hoàn tất (qbx_medical cần thời gian xử lý)
        Citizen.Wait(2000)
        
        -- CELEBRATION - Teleport người thắng đến WinnerBase
        TriggerClientEvent(scriptname .. ':teleportToCelebration', winner.source, {
            position = Config.CelebrationLocations.WinnerBase,
            isWinner = true
        })

        -- Trao thưởng cho người thắng
        GiveReward()
        
        -- CELEBRATION - Teleport người thua xếp hàng ngang (5 người/hàng, LoserBase là điểm giữa)
        local loserIndex = 0
        for k, loser in pairs(roomData.losers) do
            -- Bỏ qua người đã quit
            if not loser.hasQuit then
                local row = math.floor(loserIndex / 5)  -- Hàng thứ mấy (0, 1, 2...)
                local col = loserIndex % 5              -- Vị trí trong hàng (0-4)
                
                local basePos = Config.CelebrationLocations.LoserBase
                local spacing = 0.8  -- Khoảng cách giữa mỗi người (mét)
                
                -- Offset ngang: -2, -1, 0, 1, 2 (vị trí 2 là giữa - tại LoserBase)
                local offsetX = (col - 2) * spacing
                -- Offset dọc về phía sau (mỗi hàng cách 0.8m)
                local offsetY = row * (-spacing)
                
                -- Tính toán dựa trên heading của LoserBase (xoay theo hướng nhìn)
                local heading = basePos.w
                local rad = math.rad(heading)
                
                local finalX = basePos.x + (offsetX * math.cos(rad)) + (offsetY * math.sin(rad))
                local finalY = basePos.y + (offsetX * math.sin(rad)) - (offsetY * math.cos(rad))
                
                TriggerClientEvent(scriptname .. ':teleportToCelebration', loser.source, {
                    position = vec4(finalX, finalY, basePos.z, basePos.w),
                    isWinner = false
                })
                
                loserIndex = loserIndex + 1
            end
        end
        
        -- Sau celebration time, teleport tất cả về vị trí ban đầu
        Citizen.SetTimeout((Config.CelebrationTime or 15) * 1000, function()
            -- Teleport người thắng về (nếu chưa quit)
            if not winner.hasQuit then
                TriggerClientEvent(scriptname .. ':endGame', winner.source)
            end
            
            -- Teleport người thua về (bỏ qua người đã quit)
            for k, loser in pairs(roomData.losers) do
                if not loser.hasQuit then
                    TriggerClientEvent(scriptname .. ':endGame', loser.source)
                end
            end
        end)
        
    -- Trường hợp 2: Còn 0 người (tất cả chết - thường do 2 người cuối cùng cùng chết)
    elseif #roomData.players == 0 and #roomData.losers > 0 then
        -- Xác định winner: người chết do nổ lây (diedFromExplosion = true) là THẮNG
        -- Người cầm bom (wasBomber = true / lastBomber) là THUA
        local winner = nil
        local winnerIdxInLosers = nil

        if roomData.lastBomber then
            -- Tìm người không phải bomber trong losers → đó là người chết do nổ lây = THẮNG
            for i, loser in ipairs(roomData.losers) do
                if loser.source ~= roomData.lastBomber then
                    winner = loser
                    winnerIdxInLosers = i
                    break
                end
            end
        end

        if winner then
            -- Xóa winner khỏi losers để không teleport về loser base
            table.remove(roomData.losers, winnerIdxInLosers)

            roomData.winner = winner
            roomData.rewardGiven = false

            -- Báo admin
            if roomData.adminSource then
                TriggerClientEvent(scriptname .. ':showWinner', roomData.adminSource, winner)
            end

            -- Revive tất cả losers (bomber và những người thua khác)
            for k, loser in pairs(roomData.losers) do
                RevivePlayer(loser.source)
            end

            Citizen.Wait(2000)

            -- Teleport winner lên celebration
            TriggerClientEvent(scriptname .. ':teleportToCelebration', winner.source, {
                position = Config.CelebrationLocations.WinnerBase,
                isWinner = true
            })

            -- Trao thưởng cho người thắng
            GiveReward()

            -- Teleport losers xếp hàng
            local loserIndex = 0
            for k, loser in pairs(roomData.losers) do
                if not loser.hasQuit then
                    local row = math.floor(loserIndex / 5)
                    local col = loserIndex % 5
                    local basePos = Config.CelebrationLocations.LoserBase
                    local spacing = 0.8
                    local offsetX = (col - 2) * spacing
                    local offsetY = row * (-spacing)
                    local heading = basePos.w
                    local rad = math.rad(heading)
                    local finalX = basePos.x + (offsetX * math.cos(rad)) + (offsetY * math.sin(rad))
                    local finalY = basePos.y + (offsetX * math.sin(rad)) - (offsetY * math.cos(rad))
                    TriggerClientEvent(scriptname .. ':teleportToCelebration', loser.source, {
                        position = vec4(finalX, finalY, basePos.z, basePos.w),
                        isWinner = false
                    })
                    loserIndex = loserIndex + 1
                end
            end

            -- Sau celebration time, teleport tất cả về
            Citizen.SetTimeout((Config.CelebrationTime or 15) * 1000, function()
                if not winner.hasQuit then
                    TriggerClientEvent(scriptname .. ':endGame', winner.source)
                end
                for k, loser in pairs(roomData.losers) do
                    if not loser.hasQuit then
                        TriggerClientEvent(scriptname .. ':endGame', loser.source)
                    end
                end
            end)
        else
            -- Không xác định được winner (không có lastBomber, hoặc chỉ 1 người)
            roomData.winner = nil
            for k, loser in pairs(roomData.losers) do
                if not loser.hasQuit then
                    TriggerClientEvent(scriptname .. ':endGame', loser.source)
                end
            end
        end
        
    -- Trường hợp 3: Admin dừng sớm
    elseif #roomData.players > 1 then
        -- Còn nhiều người → admin dừng sớm, không có người thắng
        -- Xóa prop bom và tele tất cả về (bỏ qua người đã quit)
        for k, player in pairs(roomData.players) do
            if not player.hasQuit then
                TriggerClientEvent(scriptname .. ':removeBombProp', player.source)
            end
        end
        
        Citizen.Wait(500)
        
        for k, player in pairs(roomData.players) do
            if not player.hasQuit then
                TriggerClientEvent(scriptname .. ':endGame', player.source)
            end
        end
        
        for k, loser in pairs(roomData.losers) do
            if not loser.hasQuit then
                TriggerClientEvent(scriptname .. ':endGame', loser.source)
            end
        end
    end
    
    -- Reset dữ liệu sau celebration time + 5s
    Citizen.SetTimeout(((Config.CelebrationTime or 15) + 5) * 1000, function()
        roomData.status = 'idle'
        roomData.players = {}
        roomData.playerBomb = {}
        roomData.playerBombSet = {}
        roomData.losers = {}
        roomData.rewardGiven = false
        roomData.totalPlayersAtStart = 0
        roomData.isEnding = false
        roomData.endGameScheduled = false
        roomData.lastBomber = nil
        -- Reset cả cooldown transfer
        playerTransferCooldown = {}
        UpdateAdminUI()
    end)
end

-- Hàm trao thưởng cho người thắng
function GiveReward()
    if roomData.rewardGiven then return end
    if not roomData.winner then return end
    
    local Player = QBCore.Functions.GetPlayer(roomData.winner.source)
    if Player then
        local winnerSrc = roomData.winner.source

        -- ── 1. Tiền thưởng ──────────────────────────────────────────────
        local totalPool = roomData.entryFee * roomData.totalPlayersAtStart
        local taxAmount = totalPool * (Config.TaxPercent / 100)
        local winnerReward = math.floor(totalPool - taxAmount)
        
        if winnerReward > 0 then
            Player.Functions.AddMoney('cash', winnerReward)
            TriggerClientEvent('QBCore:Notify', winnerSrc, 
                string.format('Chúc mừng! Bạn đã thắng sự kiện Bomber và nhận được $%s!', 
                QBCore.Shared.CommaValue(winnerReward)), 'success')
            reward(winnerSrc, 'money', winnerReward)
        else
            TriggerClientEvent('QBCore:Notify', winnerSrc, 'Chúc mừng! Bạn đã thắng sự kiện Bomber!', 'success')
        end

        -- ── 2. Item QBCore thường ────────────────────────────────────────
        if Config.PhanThuongItem and Config.PhanThuongItem.items then
            for _, itemCfg in ipairs(Config.PhanThuongItem.items) do
                Player.Functions.AddItem(itemCfg.name, itemCfg.count)
                TriggerClientEvent('QBCore:Notify', winnerSrc,
                    string.format('🎁 Nhận được %dx %s!', itemCfg.count, itemCfg.label or itemCfg.name), 'success')
            end
        end

        -- ── 3. Quần áo qua XNClothes ────────────────────────────────────
        if Config.PhanThuongItem and Config.PhanThuongItem.clothes then
            -- Lấy giới tính của người thắng
            local gender = 'male'
            if Player.PlayerData and Player.PlayerData.charinfo and Player.PlayerData.charinfo.gender == 1 then
                gender = 'female'
            end

            for _, clothCfg in ipairs(Config.PhanThuongItem.clothes) do
                local count = clothCfg.count or 1
                for i = 1, count do
                    pcall(function()
                        exports['XNClothes']:GiveClothingItemBySex(winnerSrc, clothCfg.type, clothCfg.id, clothCfg.texture or 0, gender)
                    end)
                end
                TriggerClientEvent('QBCore:Notify', winnerSrc,
                    string.format('👕 Nhận được %dx trang phục đặc biệt!', count), 'success')
            end
        end
        
        roomData.rewardGiven = true
    end
end

-- Chuyển dimension
RegisterNetEvent(scriptname .. ':changeDimension', function(dimension)
    local src = source
    SetPlayerRoutingBucket(src, dimension)
end)

-- Người chơi thoát server
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    -- Xóa khỏi danh sách tham gia (chuyển sang losers nếu đang chơi)
    local player = roomData.playersBySource[src]
    if player then
        if roomData.status == 'running' then
            player.hasQuit = true
            table.insert(roomData.losers, player)
        end
        roomData.playersBySource[src] = nil
        for k, v in ipairs(roomData.players) do
            if v.source == src then
                table.remove(roomData.players, k)
                break
            end
        end
        UpdateAdminUI()
    end
    
    -- Xóa khỏi danh sách cầm bom
    local wasBombCarrier = RemovePlayerBomb(src)
    if wasBombCarrier then
        -- Nếu không còn ai cầm bom, chọn người mới
        if #roomData.playerBomb == 0 and roomData.status == 'running' and #roomData.players > 0 then
            SelectBomber()
        else
            BroadcastBomberList()
        end
    end
    
    -- Xóa khỏi losers nếu đã chết trước đó (tránh trigger endGame cho người offline)
    for k, loser in pairs(roomData.losers) do
        if loser.source == src then
            roomData.losers[k].hasQuit = true -- đánh dấu để bỏ qua celebration/endGame
            break
        end
    end
    
    -- Kiểm tra điều kiện kết thúc game khi drop
    if roomData.status == 'running' then
        if Config.TestModeAllDead then
            if #roomData.players == 0 then
                ScheduleEndGame()
            end
        else
            if #roomData.players <= 1 then
                ScheduleEndGame()
            end
        end
    end
end)

-- Client yêu cầu danh sách người còn sống để spectate
RegisterNetEvent(scriptname .. ':requestSpectateList', function()
    local src = source
    
    if roomData.status ~= 'running' then
        TriggerClientEvent(scriptname .. ':updateSpectateList', src, {})
        return
    end
    
    -- Lấy danh sách server IDs của người còn sống
    local aliveServerIds = {}
    for _, player in ipairs(roomData.players) do
        -- Bỏ qua chính người yêu cầu (người đang spectate)
        if player.source ~= src then
            table.insert(aliveServerIds, player.source)
        end
    end
    
    TriggerClientEvent(scriptname .. ':updateSpectateList', src, aliveServerIds)
end)
