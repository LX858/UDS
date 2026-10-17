local QBCore = exports['qb-core']:GetCoreObject()
local currentPrices = {}
local availableItems = {} -- Danh sách vật phẩm hiện có sẵn để bán
local currentNPCLocationIndex = 1

-- Helper: Broadcast latent event tới tất cả players với giới hạn BPS
-- BPS thấp = ít tải server, phù hợp dữ liệu không cần realtime
local function BroadcastLatent(eventName, bps, ...)
    local payload = json.encode({...})
    local payloadLen = #payload
    TriggerLatentClientEventInternal(eventName, '-1', payload, payloadLen, bps)
end

-- Chọn ngẫu nhiên vị trí NPC từ danh sách
local function SelectRandomNPCLocation()
    if Config.NPCLocations and #Config.NPCLocations > 0 then
        currentNPCLocationIndex = math.random(1, #Config.NPCLocations)
    else
        currentNPCLocationIndex = 1
    end
    print('[nl_blackitem] Vị trí NPC ngẫu nhiên được chọn: ' .. currentNPCLocationIndex)
    -- Dữ liệu nhỏ (1 số), BPS 5000 là đủ
    BroadcastLatent('nl_blackitem:client:updateNPCLocation', 5000, currentNPCLocationIndex)
end

-- Chọn ngẫu nhiên vật phẩm có sẵn
local function SelectRandomItems()
    availableItems = {}
    
    if Config.RandomItemSelection.enabled then
        -- Chọn ngẫu nhiên 1 vật phẩm từ danh sách
        local randomIndex = math.random(1, #Config.Items)
        table.insert(availableItems, Config.Items[randomIndex])
        
        print('[nl_blackitem] Vật phẩm ngẫu nhiên được chọn: ' .. Config.Items[randomIndex].label)
    else
        -- Nếu không bật chế độ ngẫu nhiên, hiển thị tất cả vật phẩm
        for _, item in pairs(Config.Items) do
            table.insert(availableItems, item)
        end
    end
    
    -- Broadcast danh sách vật phẩm mới cho tất cả clients
    -- Dữ liệu vật phẩm có thể lớn hơn, BPS 15000 để không bị chậm
    BroadcastLatent('nl_blackitem:client:updateAvailableItems', 15000, availableItems)
end

-- Generate random prices for available items
local function GenerateRandomPrices()
    currentPrices = {}
    for _, item in pairs(availableItems) do
        currentPrices[item.item] = math.random(item.minPrice, item.maxPrice)
    end
    
    print('[nl_blackitem] Giá cả đã được cập nhật ngẫu nhiên')
    
    -- Broadcast new prices to all clients
    -- Giá là dữ liệu nhỏ, BPS 8000 là thoải mái
    BroadcastLatent('nl_blackitem:client:updatePrices', 8000, currentPrices)
end

-- Send current prices and available items to specific client
RegisterNetEvent('nl_blackitem:server:requestPrices', function()
    local src = source
    TriggerClientEvent('nl_blackitem:client:updatePrices', src, currentPrices)
    TriggerClientEvent('nl_blackitem:client:updateAvailableItems', src, availableItems)
    TriggerClientEvent('nl_blackitem:client:updateNPCLocation', src, currentNPCLocationIndex)
end)

-- Handle item purchase
RegisterNetEvent('nl_blackitem:server:buyItem', function(itemName, quantity, pricePerItem)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        return
    end
    
    -- Kiểm tra giới hạn số lượng mua
    if quantity > Config.MaxPurchaseQuantity then
        TriggerClientEvent('nl_blackitem:client:purchaseResult', src, false, Config.Lang['max_quantity_exceeded']:format(Config.MaxPurchaseQuantity))
        return
    end
    
    -- Validate item exists in available items
    local itemConfig = nil
    for _, item in pairs(availableItems) do
        if item.item == itemName then
            itemConfig = item
            break
        end
    end
    
    if not itemConfig then
        TriggerClientEvent('nl_blackitem:client:purchaseResult', src, false, 'Vật phẩm không tồn tại')
        return
    end
    
    -- Validate price (prevent client-side manipulation)
    local currentPrice = currentPrices[itemName]
    if not currentPrice or math.abs(pricePerItem - currentPrice) > 1 then
        TriggerClientEvent('nl_blackitem:client:purchaseResult', src, false, 'Giá không hợp lệ, vui lòng thử lại')
        return
    end
    
    local totalCost = pricePerItem * quantity
    
    -- Check if player has enough black money
    local blackMoney = Player.Functions.GetItemByName(Config.CurrencyItem)
    if not blackMoney or blackMoney.amount < totalCost then
        TriggerClientEvent('nl_blackitem:client:purchaseResult', src, false, Config.Lang['not_enough_money']:format(Config.CurrencyLabel))
        return
    end
    
    -- Process transaction - QBCore sẽ tự động kiểm tra túi đồ khi thêm item
    local success = Player.Functions.RemoveItem(Config.CurrencyItem, totalCost)
    if success then
        local addSuccess = Player.Functions.AddItem(itemName, quantity)
        if addSuccess then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'add', quantity)
            TriggerClientEvent('nl_blackitem:client:purchaseResult', src, true, '', itemConfig.label, quantity, totalCost)
            
            -- Log transaction
            print(string.format('[nl_blackitem] %s (%s) đã mua %d x %s với giá %d %s', 
                Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                Player.PlayerData.citizenid,
                quantity,
                itemConfig.label,
                totalCost,
                Config.CurrencyLabel
            ))
            
            -- Làm mới vật phẩm sau khi mua (nếu được bật)
            if Config.RefreshItemAfterPurchase then
                SetTimeout(1000, function() -- Đợi 1 giây để người chơi nhận thông báo trước
                    SelectRandomItems()
                    GenerateRandomPrices()
                    print('[nl_blackitem] Vật phẩm và giá đã được làm mới sau khi mua')
                end)
            end
        else
            -- Refund if adding item failed (túi đồ đầy hoặc lỗi khác)
            Player.Functions.AddItem(Config.CurrencyItem, totalCost)
            TriggerClientEvent('nl_blackitem:client:purchaseResult', src, false, Config.Lang['inventory_full'] or 'Túi đồ đầy hoặc lỗi khi thêm vật phẩm')
        end
    else
        TriggerClientEvent('nl_blackitem:client:purchaseResult', src, false, 'Lỗi khi trừ tiền')
    end
end)

-- Auto refresh prices and items using SetTimeout (better server-side performance)
local function RefreshPricesLoop()
    SetTimeout(Config.PriceRefreshInterval, function()
        -- Nếu bật chế độ ngẫu nhiên, thay đổi vật phẩm theo interval
        if Config.RandomItemSelection.enabled then
            if Config.RandomItemSelection.refreshInterval <= Config.PriceRefreshInterval then
                SelectRandomItems()
            end
        end
        
        -- Thay đổi vị trí NPC nếu được cấu hình
        if Config.ChangeNPCLocationOnRefresh then
            SelectRandomNPCLocation()
        end
        
        GenerateRandomPrices()
        
        RefreshPricesLoop()
    end)
end

-- Thread riêng cho việc thay đổi vật phẩm ngẫu nhiên (sử dụng SetTimeout)
local function RefreshItemsLoop()
    SetTimeout(Config.RandomItemSelection.refreshInterval, function()
        if not Config.RandomItemSelection.enabled then
            return
        end
        
        -- Chỉ thay đổi vật phẩm nếu interval khác với price refresh
        if Config.RandomItemSelection.refreshInterval ~= Config.PriceRefreshInterval then
            SelectRandomItems()
            GenerateRandomPrices() -- Tạo giá mới cho vật phẩm mới
        end
        
        RefreshItemsLoop()
    end)
end

-- Khởi tạo ban đầu
SelectRandomNPCLocation()
SelectRandomItems()
GenerateRandomPrices()
RefreshPricesLoop()
RefreshItemsLoop()

-- Generate prices and items when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(1000)
        SelectRandomNPCLocation()
        SelectRandomItems()
        GenerateRandomPrices()
    end
end)

-- Command to manually refresh prices (for admin testing)
QBCore.Commands.Add('refreshblackprices', 'Làm mới giá chợ đen (Admin Only)', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player and QBCore.Functions.HasPermission(source, 'admin') then
        SelectRandomNPCLocation()
        SelectRandomItems()
        GenerateRandomPrices()
        TriggerClientEvent('QBCore:Notify', source, 'Đã làm mới vật phẩm, vị trí NPC và giá chợ đen', 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền sử dụng lệnh này', 'error')
    end
end, 'admin')

-- Command to check current prices
QBCore.Commands.Add('checkblackprices', 'Kiểm tra giá hiện tại chợ đen', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        local priceList = {}
        for itemName, price in pairs(currentPrices) do
            for _, item in pairs(availableItems) do
                if item.item == itemName then
                    table.insert(priceList, string.format('%s: %d %s', item.label, price, Config.CurrencyLabel))
                    break
                end
            end
        end
        
        local message = 'Không có vật phẩm nào đang bán'
        if #priceList > 0 then
            message = 'Vật phẩm hiện có:\n' .. table.concat(priceList, '\n')
        end
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 255, 0},
            multiline = true,
            args = {'[Chợ Đen]', message}
        })
    end
end)

-- Command to toggle random item selection
QBCore.Commands.Add('toggleblackrandom', 'Bật/tắt chế độ ngẫu nhiên chọn vật phẩm (Admin Only)', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player and QBCore.Functions.HasPermission(source, 'admin') then
        Config.RandomItemSelection.enabled = not Config.RandomItemSelection.enabled
        
        SelectRandomItems()
        GenerateRandomPrices()
        
        local status = Config.RandomItemSelection.enabled and 'BẬT' or 'TẮT'
        TriggerClientEvent('QBCore:Notify', source, 'Đã ' .. status .. ' chế độ ngẫu nhiên chọn vật phẩm', 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền sử dụng lệnh này', 'error')
    end
end, 'admin')
