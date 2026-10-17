-- GlobalState cho hệ thống trộm chó (atomic block + cooldown)
GlobalState['xn_tromcho_Block'] = false       -- Đang có người trộm
GlobalState['xn_tromcho_ActiveRobber'] = 0    -- Player ID đang trộm
GlobalState['xn_tromcho_RobStartTime'] = 0    -- Thời gian bắt đầu (auto-timeout)
GlobalState['xn_tromcho_CooldownUntil'] = 0   -- Hết cooldown lúc (os.time())

local function formatCooldownTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    if minutes > 0 then
        return string.format("%d phút %d giây", minutes, secs)
    else
        return string.format("%d giây", secs)
    end
end

-- Auto cleanup khi player disconnect
AddEventHandler('playerDropped', function(reason)
    local src = source
    if GlobalState['xn_tromcho_ActiveRobber'] == src then
        GlobalState['xn_tromcho_Block'] = false
        GlobalState['xn_tromcho_ActiveRobber'] = 0
        GlobalState['xn_tromcho_RobStartTime'] = 0
        print('[xn_tromcho] Player ' .. src .. ' disconnect, đã reset Block')
    end
end)

RegisterNetEvent("nyo-tromcho:server:BanCho", function(Cho)
    local src = source 
    local Player = CoreName.Functions.GetPlayer(src)

    if Config.BanCho.LoaiTien == "tiensach" then 
        for k, v in pairs(Config.BanCho.GiaCho) do
            if  Cho == k then 
                Player.Functions.AddMoney("cash", Config.BanCho.GiaCho[k], "BanCho")
                TriggerClientEvent(''..Config.Framework..':Notify', src, "Đã bán chó thành công..", 'success')
            end
        end 
    else 
        if Config.Framework == "QBCore" then 
            for k, v in pairs(Config.BanCho.GiaCho) do 
                if Cho == k then 
                    local info = {}
                    info.worth = Config.BanCho.GiaCho[k]
                    TriggerClientEvent(''..Config.Framework..':Notify', src, "Đã bán chó thành công..", 'success')
                    TriggerClientEvent('inventory:client:ItemBox', source, CoreName.Shared.Items['markedbills'], "add")
                    Player.Functions.AddItem("markedbills", 1, false, info)
                end 
            end 
        else 
            for k, v in pairs(Config.BanCho.GiaCho) do 
                if Cho == k then 
                    TriggerClientEvent(''..Config.Framework..':Notify', src, "Đã bán chó thành công..", 'success')
                    TriggerClientEvent('pepe-inventory:client:ItemBox', src, CoreName.Shared.Items['money-roll'], "add")
                    Player.Functions.AddItem("money-roll", Config.BanCho.GiaCho[k])
                end 
            end 
        end 
    end 
end)

-- Event mới: Give item chó sau khi bắt thành công
RegisterNetEvent('xn_tromcho:server:GiveChoItem', function(itemName, usedItem)
    local src = source
    local Player = CoreName.Functions.GetPlayer(src)
    local tile2 = math.random(1, 100)
    if not Player then return end
    Player.Functions.SetMetaData("stress", 30.0)
    -- Give item chó vào inventory
    if exports.ox_inventory then
        exports.ox_inventory:AddItem(src, itemName, 1)
    else
        Player.Functions.AddItem(itemName, 1)
    end
    
    -- Remove the correct catching item used
    if usedItem then
        if exports.ox_inventory then
            exports.ox_inventory:RemoveItem(src, usedItem, 1)
        else
            Player.Functions.RemoveItem(usedItem, 1)
        end
    else
        if exports.ox_inventory then
            exports.ox_inventory:RemoveItem(src, 'xichcho', 1)
        else
            Player.Functions.RemoveItem('xichcho', 1)
        end
    end


    if Config.Event and Config.Event.enabled then
        if math.random(1, 100) <= Config.Event.chance then
            local roll = math.random(1, 100)
            local cumulativeChance = 0
            for _, reward in ipairs(Config.Event.rewards) do
                cumulativeChance = cumulativeChance + reward.chance
                if roll <= cumulativeChance then
                    exports.ox_inventory:AddItem(src, reward.item, 1)
                    break
                end
            end
        end
    end

    -- Hệ thống phần thưởng đặc biệt
    if Config.Event2 and Config.Event2.enabled then
        if math.random(1, 100) <= Config.Event2.chance then
            local roll2 = math.random(1, 100)
            local cumulativeChance2 = 0
            for _, reward in ipairs(Config.Event2.rewards) do
                cumulativeChance2 = cumulativeChance2 + reward.chance
                if roll2 <= cumulativeChance2 then
                    exports.ox_inventory:AddItem(src, reward.item, 1)
                    break
                end
            end
        end
    end
    
    TriggerClientEvent('inventory:client:ItemBox', src, CoreName.Shared.Items[itemName], "add")
end)

-- Callback: Kiểm tra có item chó không, nếu có thì remove và give tiền
CoreName.Functions.CreateCallback('xn_tromcho:server:CheckAndSellDog', function(source, cb, itemName)
    local src = source
    local Player = CoreName.Functions.GetPlayer(src)
    
    if not Player then 
        cb(false)
        return 
    end
    
    -- Kiểm tra có item không
    local hasItem = false
    if exports.ox_inventory then
        local item = exports.ox_inventory:GetItem(src, itemName, nil, true)
        hasItem = item and item > 0
    else
        local item = Player.Functions.GetItemByName(itemName)
        hasItem = item and item.amount > 0
    end
    
    if not hasItem then
        cb(false)
        return
    end
    
    -- Remove item
    if exports.ox_inventory then
        exports.ox_inventory:RemoveItem(src, itemName, 1)
    else
        Player.Functions.RemoveItem(itemName, 1)
    end
    
    -- Give tiền
    local price = Config.BanCho.GiaCho[itemName] or 0
    
    if Config.BanCho.LoaiTien == "tiensach" then
        Player.Functions.AddMoney("cash", price, "BanCho")
        TriggerClientEvent(''..Config.Framework..':Notify', src, "Đã bán chó thành công..", 'success')
    else
        if Config.Framework == "QBCore" then
            local info = {}
            info.worth = price
            Player.Functions.AddItem("markedbills", 1, false, info)
            TriggerClientEvent('inventory:client:ItemBox', src, CoreName.Shared.Items['markedbills'], "add")
            TriggerClientEvent(''..Config.Framework..':Notify', src, "Đã bán chó thành công..", 'success')
        else
            Player.Functions.AddItem("money-roll", price)
            TriggerClientEvent('pepe-inventory:client:ItemBox', src, CoreName.Shared.Items['money-roll'], "add")
            TriggerClientEvent(''..Config.Framework..':Notify', src, "Đã bán chó thành công..", 'success')
        end
    end
    
    cb(true)
end)

-- Callback: Huấn luyện chó
CoreName.Functions.CreateCallback('xn_tromcho:server:TrainDog', function(source, cb, itemName)
    local src = source
    local Player = CoreName.Functions.GetPlayer(src)
    
    if not Player then 
        cb(false, false)
        return 
    end
    
    -- Kiểm tra có item không
    local hasItem = false
    if exports.ox_inventory then
        local item = exports.ox_inventory:GetItem(src, itemName, nil, true)
        hasItem = item and item > 0
    else
        local item = Player.Functions.GetItemByName(itemName)
        hasItem = item and item.amount > 0
    end
    
    if not hasItem then
        cb(false, false)
        return
    end
    
    -- Remove item (luôn luôn trừ)
    if exports.ox_inventory then
        exports.ox_inventory:RemoveItem(src, itemName, 1)
    else
        Player.Functions.RemoveItem(itemName, 1)
    end
    
    -- Tỉ lệ thành công
    local successRate = 0
    if type(Config.HuanLuyenCho.SuccessRate) == "table" then
        successRate = Config.HuanLuyenCho.SuccessRate[itemName] or 0
    else
        successRate = Config.HuanLuyenCho.SuccessRate or 0
    end
    local isSuccess = math.random(1, 100) <= successRate
    
    if isSuccess then
        -- Lấy item pet tương ứng
        local petItemName = Config.HuanLuyenCho.Items[itemName]
        if petItemName then
            if exports.ox_inventory then
                exports.ox_inventory:AddItem(src, petItemName, 1)
            else
                Player.Functions.AddItem(petItemName, 1)
            end
            TriggerClientEvent('inventory:client:ItemBox', src, CoreName.Shared.Items[petItemName], "add")
        end
        
        -- Log Discord webhook
        if Config.HuanLuyenCho.Webhook and Config.HuanLuyenCho.Webhook ~= "" then
            local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
            local citizenId = Player.PlayerData.citizenid
            local logMessage = playerName .. " (" .. citizenId .. ") đã huấn luyện thành công " .. itemName
            
            PerformHttpRequest(Config.HuanLuyenCho.Webhook, function(err, text, headers) end, 'POST', json.encode({
                username = "Huấn Luyện Chó",
                embeds = {{
                    title = "🐕 Huấn Luyện Chó Thành Công",
                    description = logMessage,
                    color = 3066993,
                    fields = {
                        {name = "Người chơi", value = playerName, inline = true},
                        {name = "ID", value = citizenId, inline = true},
                        {name = "Chó huấn luyện", value = itemName, inline = true},
                        {name = "Nhận được", value = petItemName or "N/A", inline = true}
                    },
                    footer = {text = "xn_tromcho | " .. os.date("%d/%m/%Y %H:%M:%S")}
                }}
            }), {['Content-Type'] = 'application/json'})
        end
        
        cb(true, true) -- Trả về (có item để trừ, huấn luyện thành công)
    else
        cb(true, false) -- Trả về (có item để trừ, huấn luyện thất bại)
    end
end)

-- Routing bucket: đặt entity vào đúng bucket của player ngay sau khi client spawn
-- Được gọi từ cả 3 nơi spawn chó (SpawnDog, SpawnFollowingDog, decoration dog)
RegisterNetEvent('xn_tromcho:server:RegisterEntityBucket', function(netId)
    local src = source
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        SetEntityRoutingBucket(entity, GetPlayerRoutingBucket(src))
    end
end)

-- Routing bucket: xóa entity bị orphan khi client mất access do đổi bucket
RegisterNetEvent('xn_tromcho:server:DeleteOrphanEntity', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end)

-- Callback: atomic check + lock toàn server trước khi bắt chó
lib.callback.register('xn_tromcho:sv:CheckCanRob', function(source)
    local src = source
    -- Kiểm tra global cooldown
    if os.time() < (GlobalState['xn_tromcho_CooldownUntil'] or 0) then
        local timeLeft = GlobalState['xn_tromcho_CooldownUntil'] - os.time()
        exports.qbx_core:Notify(src, 'Toàn server đang chờ: ' .. formatCooldownTime(timeLeft), 'error')
        return false
    end
    -- Auto-timeout nếu player trước bị stuck
    if GlobalState['xn_tromcho_Block'] and GlobalState['xn_tromcho_RobStartTime'] > 0 then
        if os.time() - GlobalState['xn_tromcho_RobStartTime'] > (Config.TimeoutAuto or 120) then
            GlobalState['xn_tromcho_Block'] = false
            GlobalState['xn_tromcho_ActiveRobber'] = 0
            GlobalState['xn_tromcho_RobStartTime'] = 0
            print('[xn_tromcho] Auto-reset Block vì timeout')
        end
    end
    -- Kiểm tra có ai đang trộm không
    if GlobalState['xn_tromcho_Block'] then
        exports.qbx_core:Notify(src, 'Đang có người trộm chó!', 'error')
        return false
    end
    -- Atomic lock
    GlobalState['xn_tromcho_Block'] = true
    GlobalState['xn_tromcho_ActiveRobber'] = src
    GlobalState['xn_tromcho_RobStartTime'] = os.time()
    return true
end)

-- Event: trộm thành công → set cooldown 3 phút + reset Block
RegisterNetEvent('xn_tromcho:server:SuccessRob', function()
    GlobalState['xn_tromcho_Block'] = false
    GlobalState['xn_tromcho_ActiveRobber'] = 0
    GlobalState['xn_tromcho_RobStartTime'] = 0
    GlobalState['xn_tromcho_CooldownUntil'] = os.time() + 60 * (Config.CooldownToanServer or 3)
end)

-- Event: trộm thất bại → set cooldown ngắn + reset Block
RegisterNetEvent('xn_tromcho:server:FailRob', function()
    GlobalState['xn_tromcho_Block'] = false
    GlobalState['xn_tromcho_ActiveRobber'] = 0
    GlobalState['xn_tromcho_RobStartTime'] = 0
    GlobalState['xn_tromcho_CooldownUntil'] = os.time() + (Config.CooldownThatBai or 10)
end)

-- Event: hủy progressbar → chỉ reset Block, không cooldown
RegisterNetEvent('xn_tromcho:server:ResetRob', function()
    local src = source
    if GlobalState['xn_tromcho_ActiveRobber'] == src then
        GlobalState['xn_tromcho_Block'] = false
        GlobalState['xn_tromcho_ActiveRobber'] = 0
        GlobalState['xn_tromcho_RobStartTime'] = 0
    end
end)

-- Admin command: reset toàn bộ trạng thái trộm chó
RegisterCommand('resettromcho', function(source, args, rawCommand)
    local isAdmin = source == 0
    if not isAdmin then
        local Player = CoreName.Functions.GetPlayer(source)
        isAdmin = Player and (Player.PlayerData.group == 'admin' or Player.PlayerData.group == 'superadmin')
    end
    if isAdmin then
        GlobalState['xn_tromcho_Block'] = false
        GlobalState['xn_tromcho_ActiveRobber'] = 0
        GlobalState['xn_tromcho_RobStartTime'] = 0
        GlobalState['xn_tromcho_CooldownUntil'] = 0
        if source ~= 0 then
            TriggerClientEvent(''..Config.Framework..':Notify', source, 'Đã reset trộm chó', 'success')
        else
            print('[xn_tromcho] Đã reset trộm chó')
        end
    else
        TriggerClientEvent(''..Config.Framework..':Notify', source, 'Bạn không có quyền sử dụng lệnh này', 'error')
    end
end, false)