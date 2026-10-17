local QBCore = exports['qb-core']:GetCoreObject()

-- Hàm tăng tỷ lệ sleepiness
local function IncreaseSleepiness(Player, amount)
    local src = source
    local currentSleepiness = Player.PlayerData.metadata.sleepiness or 0
    local newSleepiness = math.min(100, currentSleepiness + amount) -- Max 100
    --local isCompleted = exports['xn_nhiemvutanthu']:getMissionStatus(src, 2)
    
    Player.Functions.SetMetaData('sleepiness', newSleepiness)

    -- -- Hoàn thành nhiệm vụ từ resource khác (ví dụ từ resource cầu nguyện/chùa)
    -- if not isCompleted then
    --     exports['xn_nhiemvutanthu']:completeMissionExternal(src, 2, false)
    --     TriggerClientEvent('QBCore:Notify', source, 'Bạn đã hoàn thành nhiệm vụ tân thủ #2!', 'success')
    -- end
    
    return newSleepiness
end

-- Event khi player bắt đầu ngủplayer.Functions.SetMetaData('sleepiness'player.Functions.SetMetaData('sleepiness'
RegisterNetEvent('sleep:startSleep', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        return
    end
    
    -- Có thể thêm logic kiểm tra điều kiện ngủ ở đây
    -- Ví dụ: kiểm tra xem player có đang trong combat không
    
    print(('Player %s (%s) started sleeping'):format(Player.PlayerData.name, Player.PlayerData.citizenid))
end)

-- Event khi player hoàn thành việc ngủ
RegisterNetEvent('sleep:finishSleep', function(maxSleepiness, usedItem)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        return
    end
    
    -- Tính toán lượng sleepiness tăng dựa trên giới hạn
    local currentSleepiness = Player.PlayerData.metadata.sleepiness or 0
    local targetSleepiness = maxSleepiness or 100
    
    -- Tính lượng tăng = target - current (không vượt quá target)
    local sleepinessIncrease = math.max(0, targetSleepiness - currentSleepiness)
    
    -- Tăng sleepiness lên đúng target
    local newSleepiness = IncreaseSleepiness(Player, sleepinessIncrease)
    
    -- Chỉ xóa item NẾU đã dùng item chiếu ngủ VÀ config cho phép
    if usedItem and Config.SleepItem.consumeOnUse then
        Player.Functions.RemoveItem(Config.SleepItem.itemName, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.SleepItem.itemName], "remove", 1)
    end
    
    -- Thông báo cho player
    TriggerClientEvent('QBCore:Notify', src, ('Sleepiness đã tăng lên %d%%'):format(newSleepiness), 'success')
    
    if Config.Debug then
        print(('Player %s (%s) finished sleeping. Sleepiness: %d%%'):format(
            Player.PlayerData.name, 
            Player.PlayerData.citizenid, 
            newSleepiness
        ))
    end
end)

-- Command để admin có thể đánh thức player
QBCore.Commands.Add('wakeup', 'Đánh thức một player đang ngủ', {
    {name = 'id', help = 'Player ID'}
}, true, function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('QBCore:Notify', source, 'ID không hợp lệ!', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Player không tồn tại!', 'error')
        return
    end
    
    -- Thông báo cho player bị đánh thức
    TriggerClientEvent('QBCore:Notify', targetId, 'Bạn đã bị admin đánh thức!', 'info')
    TriggerClientEvent('sleep:forceWakeUp', targetId)
    
    -- Thông báo cho admin
    TriggerClientEvent('QBCore:Notify', source, ('Đã đánh thức player %s'):format(targetPlayer.PlayerData.name), 'success')
end, 'admin')

-- Export hàm tăng sleepiness để có thể sử dụng từ resource khác
exports('IncreaseSleepiness', IncreaseSleepiness)

-- Callback để lấy sleepiness hiện tại
QBCore.Functions.CreateCallback('sleep:getSleepiness', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(0)
        return
    end
    
    cb(Player.PlayerData.metadata.sleepiness or 0)
end)

-- Hàm xử lý khi sử dụng vật phẩm chiếu ngủ
local function UseSleepItem(playerId, itemName)
    local Player = QBCore.Functions.GetPlayer(playerId)
    
    if not Player then 
        return false
    end
    
    -- Kiểm tra tính năng có được bật không
    if not Config.SleepItem.enabled then
        TriggerClientEvent('QBCore:Notify', playerId, 'Tính năng chiếu ngủ chưa được kích hoạt!', 'error')
        return false
    end
    
    -- Kiểm tra có đúng item không
    if itemName and itemName ~= Config.SleepItem.itemName then
        return false
    end
    
    -- Kiểm tra player có item không
    local hasItem = Player.Functions.GetItemByName(Config.SleepItem.itemName)
    if not hasItem then
        TriggerClientEvent('QBCore:Notify', playerId, Config.Messages.noSleepItem, 'error')
        return false
    end
    
    -- KHÔNG xóa item ở đây nữa - chỉ trigger client event
    -- Item sẽ được xóa SAU KHI ngủ xong (trong sleep:finishSleep event)
    
    -- Thông báo và trigger client event
    TriggerClientEvent('QBCore:Notify', playerId, Config.Messages.usingSleepItem, 'info')
    TriggerClientEvent('sleep:useSleepItem', playerId)
    
    return true
end

-- Export hàm sử dụng item để ox_inventory có thể gọi
exports('useSleepItem', function(event, item, inventory, slot, data)
    if event == 'usingItem' then
        return UseSleepItem(inventory.id, item.name)
    end
end)

-- Event xử lý khi sử dụng vật phẩm chiếu ngủ (fallback)
RegisterNetEvent('sleep:useItem', function(itemName)
    local src = source
    UseSleepItem(src, itemName)
end)

-- Đăng ký item có thể sử dụng với QBCore
QBCore.Functions.CreateUseableItem(Config.SleepItem.itemName, function(source, item)
    local src = source
    --if exports.ox_inventory:RemoveItem(src, Config.SleepItem.itemName, 1) then
        UseSleepItem(src, item.name)
    -- else
    --     TriggerClientEvent('QBCore:Notify', source, 'Không có chiếu', 'error')
    -- end

end)


QBCore.Commands.Add('checksleep', 'Kiểm tra dữ liệu ngủ của player', {
    {name = 'id', help = 'Player ID (tùy chọn, bỏ trống để kiểm tra bản thân)'}
}, false, function(source, args)
    local targetId = source -- Mặc định kiểm tra bản thân
    local isAdmin = QBCore.Functions.HasPermission(source, 'admin')
    
    -- Nếu có args[1] và là admin thì kiểm tra player khác
    if args[1] and isAdmin then
        targetId = tonumber(args[1])
        if not targetId then
            TriggerClientEvent('QBCore:Notify', source, 'ID không hợp lệ!', 'error')
            return
        end
    elseif args[1] and not isAdmin then
        TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền kiểm tra player khác!', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Player không tồn tại!', 'error')
        return
    end
    
    local sleepiness = targetPlayer.PlayerData.metadata.sleepiness or 0
    local isSleeping = Player(targetId).state.isSleeping or false
    local playerName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
    local citizenId = targetPlayer.PlayerData.citizenid
    
    -- Tạo thông tin chi tiết
    local sleepStatus = isSleeping and "Đang ngủ" or "Đã thức"
    local sleepLevel = ""
    
    if sleepiness >= 80 then
        sleepLevel = "Rất tỉnh táo"
    elseif sleepiness >= 60 then
        sleepLevel = "Tỉnh táo"
    elseif sleepiness >= 40 then
        sleepLevel = "Bình thường"
    elseif sleepiness >= 20 then
        sleepLevel = "Hơi buồn ngủ"
    else
        sleepLevel = "Rất buồn ngủ"
    end
    
    -- Hiển thị thông tin
    if targetId == source then
        -- Kiểm tra bản thân
        TriggerClientEvent('QBCore:Notify', source, 
            string.format('💤 Dữ liệu ngủ của bạn:\n📊 Năng lượng: %d%%\n📈 Trạng thái: %s\n🔄 Hiện tại: %s', 
                sleepiness, sleepLevel, sleepStatus), 'info')
    else
        -- Admin kiểm tra player khác
        TriggerClientEvent('QBCore:Notify', source, 
            string.format('💤 Dữ liệu ngủ của %s (%s):\n📊 Năng lượng: %d%%\n📈 Trạng thái: %s\n🔄 Hiện tại: %s', 
                playerName, citizenId, sleepiness, sleepLevel, sleepStatus), 'info')
    end
    
    -- In ra console để admin có thể xem chi tiết
    if isAdmin and Config.Debug then
        print(string.format('[Sleep System] %s checked sleep data - Player: %s (%s), Sleepiness: %d%%, Status: %s', 
            GetPlayerName(source), playerName, citizenId, sleepiness, sleepStatus))
    end
end)
