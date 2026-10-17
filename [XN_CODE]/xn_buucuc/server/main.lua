local QBX = exports.qbx_core
local registeredStashes = {}

-- Đăng ký hook để tính phí khi lấy đồ từ kho
local moveHook = exports.ox_inventory:registerHook('swapItems', function(payload)
    -- Kiểm tra nếu đang lấy đồ từ kho cá nhân (fromInventory có chứa "buucuc_")
    if payload.fromInventory and string.find(payload.fromInventory, 'buucuc_') and Config.WithdrawalFee.enabled then
        -- Lấy player từ source
        local player = exports.qbx_core:GetPlayer(payload.source)
        
        if player and payload.count and payload.count > 0 then
            local fee = Config.WithdrawalFee.perItem and (Config.WithdrawalFee.amount * payload.count) or Config.WithdrawalFee.amount
            local playerMoney = player.Functions.GetMoney('cash')
            
            if Config.Debug then
                print('[XN_BUUCUC] Withdrawal detected - Fee: $' .. fee .. ', Player Cash: $' .. playerMoney)
            end
            
            -- Kiểm tra xem player có đủ tiền không
            if playerMoney < fee then
                TriggerClientEvent('xn_buucuc:client:notify', player.PlayerData.source, {
                    title = 'Kho cá nhân',
                    description = 'Bạn không đủ tiền! Cần $' .. fee .. ' để lấy đồ.',
                    type = 'error'
                })
                return false -- Chặn việc lấy item
            end
            
            -- Trừ tiền
            if player.Functions.RemoveMoney('cash', fee, 'buucuc-withdrawal-fee') then
                TriggerClientEvent('xn_buucuc:client:notify', player.PlayerData.source, {
                    title = 'Kho cá nhân',
                    description = 'Đã trả phí lấy đồ: $' .. fee,
                    type = 'info'
                })
            end
        end
    end
    
    return true -- Cho phép swap
end, {
    print = Config.Debug
})

-- Đăng ký hook để chặn swap item vào kho cá nhân
local depositHook = exports.ox_inventory:registerHook('swapItems', function(payload)
    -- Kiểm tra nếu đang chuyển vào kho cá nhân (toInventory có chứa "buucuc_")
    if payload.toInventory and string.find(payload.toInventory, 'buucuc_') then
        if Config.Debug then
            print('[XN_BUUCUC] Blocked swap attempt to personal storage: ' .. payload.toInventory)
        end
        
        -- Gửi thông báo cho player
        local player = exports.qbx_core:GetPlayer(payload.fromInventory)
        if player then
            TriggerClientEvent('xn_buucuc:client:notify', player.PlayerData.source, {
                title = 'Kho cá nhân',
                description = 'Không thể chuyển đồ vào kho! Vui lòng sử dụng các phương pháp khác.',
                type = 'error'
            })
        end
        
        return false -- Chặn việc chuyển item
    end
    
    -- Cho phép swap bình thường với các inventory khác
    return true
end, {
    print = Config.Debug
})

-- Khởi tạo khi server start
-- CreateThread(function()
--     Wait(2000) -- Đợi ox_inventory load xong
    
--     if Config.Debug then
--         print('[XN_BUUCUC] Server initialized')
--         print('[XN_BUUCUC] Storage config - Slots: ' .. Config.Storage.slots .. ', Weight: ' .. Config.Storage.weight)
--         print('[XN_BUUCUC] Swap hook registered successfully')
--     end
-- end)

-- Hàm đăng ký stash mới
local function registerStash(stashId)
    if registeredStashes[stashId] then
        return -- Stash đã được đăng ký
    end
    
    -- Đăng ký stash với ox_inventory
    exports.ox_inventory:RegisterStash(stashId, 'Kho cá nhân', Config.Storage.slots, Config.Storage.weight)
    registeredStashes[stashId] = true
    
    if Config.Debug then
        print('[XN_BUUCUC] Registered new stash: ' .. stashId)
        print('[XN_BUUCUC] Slots: ' .. Config.Storage.slots .. ', Weight: ' .. Config.Storage.weight)
    end
end

-- Event xử lý đăng ký stash từ client
RegisterNetEvent('xn_buucuc:server:registerStash', function(stashId)
    local src = source
    local player = QBX:GetPlayer(src)
    
    if not player then
        return
    end
    
    -- Kiểm tra stashId có đúng format không
    local expectedStashId = 'buucuc_' .. player.PlayerData.citizenid
    if stashId ~= expectedStashId then
        if Config.Debug then
            print('[XN_BUUCUC] Invalid stash ID from player ' .. src .. ': ' .. stashId)
        end
        return
    end
    
    -- Đăng ký stash
    registerStash(stashId)
    
    -- Gửi thông báo thành công về client
    TriggerClientEvent('xn_buucuc:client:notify', src, {
        title = 'Kho cá nhân',
        description = 'Đã mở kho cá nhân của bạn',
        type = 'success'
    })
end)

-- Event xử lý xóa kho cá nhân
RegisterNetEvent('xn_buucuc:server:clearStorage', function()
    local src = source
    local player = QBX:GetPlayer(src)
    
    if not player then
        return
    end
    
    -- Tạo stash ID
    local stashId = 'buucuc_' .. player.PlayerData.citizenid
    
    -- Đảm bảo stash đã được đăng ký
    registerStash(stashId)
    
    -- Xóa toàn bộ items trong kho
    exports.ox_inventory:ClearInventory(stashId)
    
    if Config.Debug then
        print('[XN_BUUCUC] Cleared storage for player: ' .. player.PlayerData.citizenid)
        print('[XN_BUUCUC] Stash ID: ' .. stashId)
    end
    
    -- Gửi thông báo về client
    TriggerClientEvent('xn_buucuc:client:notify', src, {
        title = 'Kho cá nhân',
        description = 'Đã xóa toàn bộ đồ trong kho',
        type = 'success'
    })
end)

-- Khởi tạo khi server start
CreateThread(function()
    Wait(2000) -- Đợi ox_inventory load xong
    
    if Config.Debug then
        print('[XN_BUUCUC] Server initialized')
        print('[XN_BUUCUC] Storage config - Slots: ' .. Config.Storage.slots .. ', Weight: ' .. Config.Storage.weight)
        print('[XN_BUUCUC] Export functions registered:')
        print('  - AddItemToPersonalStorage')
        print('  - RemoveItemFromPersonalStorage') 
        print('  - GetItemFromPersonalStorage')
        print('  - CanAddToPersonalStorage')
        print('  - GetPersonalStorageInfo')
        print('  - ClearPersonalStorage')
    end
end)
--         print('[XN_BUUCUC] Storage config - Slots: ' .. Config.Storage.slots .. ', Weight: ' .. Config.Storage.weight)
--     end
-- end)

-- Command để admin kiểm tra stash của người chơi (chỉ khi debug = true)
if Config.Debug then
    lib.addCommand('buucuc_check', {
        help = 'Kiểm tra kho của người chơi (Admin)',
        params = {
            {
                name = 'citizenid',
                type = 'string',
                help = 'Citizen ID của người chơi',
            },
        },
        restricted = 'group.admin'
    }, function(source, args, raw)
        local src = source
        local citizenid = args.citizenid
        
        if not citizenid then
            TriggerClientEvent('xn_buucuc:client:notify', src, {
                title = 'Lỗi',
                description = 'Vui lòng nhập Citizen ID',
                type = 'error'
            })
            return
        end
        
        local stashId = 'buucuc_' .. citizenid
        
        -- Đăng ký stash nếu chưa có
        registerStash(stashId)
        
        -- Mở kho cho admin
        TriggerClientEvent('xn_buucuc:client:notify', src, {
            title = 'Admin',
            description = 'Đang mở kho của ' .. citizenid,
            type = 'info'
        })
        
        -- Có thể thêm logic mở kho cho admin ở đây
    end)
    
    lib.addCommand('buucuc_stats', {
        help = 'Thống kê kho đã đăng ký (Admin)',
        restricted = 'group.admin'
    }, function(source, args, raw)
        local src = source
        local count = 0
        for _ in pairs(registeredStashes) do
            count = count + 1
        end
        
        TriggerClientEvent('xn_buucuc:client:notify', src, {
            title = 'Thống kê kho',
            description = 'Đã đăng ký ' .. count .. ' kho cá nhân',
            type = 'info'
        })
        
        if Config.Debug then
            print('[XN_BUUCUC] Registered stashes: ' .. count)
            for stashId in pairs(registeredStashes) do
                print('  - ' .. stashId)
            end
        end
    end)
end

-- =================== EXPORT FUNCTIONS ===================

-- Export: Thêm item vào kho cá nhân của người chơi
exports('AddItemToPersonalStorage', function(citizenid, item, count, metadata)
    if Config.Debug then
        print('[XN_BUUCUC] AddItemToPersonalStorage called with:')
        print('  - citizenid: ' .. tostring(citizenid))
        print('  - item: ' .. tostring(item))
        print('  - count: ' .. tostring(count))
        print('  - metadata: ' .. (metadata and json.encode(metadata) or 'nil'))
    end
    
    if not citizenid or not item or not count then
        if Config.Debug then
            print('[XN_BUUCUC] AddItemToPersonalStorage: Missing required parameters')
        end
        return false
    end
    
    local stashId = 'buucuc_' .. citizenid
    
    -- Đăng ký stash nếu chưa có
    registerStash(stashId)
    
    -- Đợi một chút để đảm bảo stash được đăng ký
    Wait(50)
    
    -- Thử thêm item bằng ox_inventory
    local success = false
    
    -- Thử với exports.ox_inventory:AddItem
    success = exports.ox_inventory:AddItem(stashId, item, count, metadata or {})
    
    if Config.Debug then
        print('[XN_BUUCUC] AddItemToPersonalStorage result: ' .. tostring(success))
        print('  - StashId: ' .. stashId)
        print('  - Item: ' .. item .. ', Count: ' .. count)
    end
    
    return success
end)

-- Export: Xóa item khỏi kho cá nhân của người chơi
exports('RemoveItemFromPersonalStorage', function(citizenid, item, count, metadata)
    if not citizenid or not item or not count then
        if Config.Debug then
            print('[XN_BUUCUC] RemoveItemFromPersonalStorage: Missing required parameters')
        end
        return false, 'Missing required parameters'
    end
    
    local stashId = 'buucuc_' .. citizenid
    
    -- Đăng ký stash nếu chưa có
    registerStash(stashId)
    
    -- Xóa item khỏi kho
    local success = exports.ox_inventory:RemoveItem(stashId, item, count, metadata)
    
    if Config.Debug then
        print('[XN_BUUCUC] RemoveItemFromPersonalStorage: ' .. tostring(success) .. ' - Item: ' .. item .. ', Count: ' .. count .. ', Citizen: ' .. citizenid)
    end
    
    return success, success and 'Item removed successfully' or 'Failed to remove item'
end)

-- Export: Kiểm tra item trong kho cá nhân của người chơi
exports('GetItemFromPersonalStorage', function(citizenid, item)
    if not citizenid then
        if Config.Debug then
            print('[XN_BUUCUC] GetItemFromPersonalStorage: Missing citizenid')
        end
        return nil
    end
    
    local stashId = 'buucuc_' .. citizenid
    
    -- Đăng ký stash nếu chưa có
    registerStash(stashId)
    
    if item then
        -- Lấy thông tin item cụ thể
        local itemData = exports.ox_inventory:GetItem(stashId, item)
        return itemData
    else
        -- Lấy toàn bộ inventory
        local inventory = exports.ox_inventory:GetInventory(stashId)
        return inventory
    end
end)

-- Export: Kiểm tra xem kho có đủ chỗ không
exports('CanAddToPersonalStorage', function(citizenid, item, count)
    if not citizenid or not item or not count then
        return false, 'Missing required parameters'
    end
    
    local stashId = 'buucuc_' .. citizenid
    
    -- Đăng ký stash nếu chưa có
    registerStash(stashId)
    
    -- Kiểm tra xem có thể thêm item không
    local canAdd = exports.ox_inventory:CanCarryItem(stashId, item, count)
    
    return canAdd, canAdd and 'Can add item' or 'Cannot add item (insufficient space or weight)'
end)

-- Export: Lấy thông tin kho của người chơi
exports('GetPersonalStorageInfo', function(citizenid)
    if not citizenid then
        return nil, 'Missing citizenid'
    end
    
    local stashId = 'buucuc_' .. citizenid
    
    -- Đăng ký stash nếu chưa có
    registerStash(stashId)
    
    local inventory = exports.ox_inventory:GetInventory(stashId)
    
    if inventory then
        return {
            stashId = stashId,
            citizenid = citizenid,
            slots = inventory.slots,
            weight = inventory.weight,
            maxWeight = inventory.maxWeight,
            items = inventory.items
        }, 'Success'
    end
    
    return nil, 'Failed to get storage info'
end)

-- Export: Làm sạch kho (xóa toàn bộ items)
exports('ClearPersonalStorage', function(citizenid)
    if not citizenid then
        return false, 'Missing citizenid'
    end
    
    local stashId = 'buucuc_' .. citizenid
    
    -- Đăng ký stash nếu chưa có
    registerStash(stashId)
    
    local inventory = exports.ox_inventory:GetInventory(stashId)
    
    if inventory and inventory.items then
        local cleared = 0
        for slot, item in pairs(inventory.items) do
            if exports.ox_inventory:RemoveItem(stashId, item.name, item.count) then
                cleared = cleared + 1
            end
        end
        
        if Config.Debug then
            print('[XN_BUUCUC] ClearPersonalStorage: Cleared ' .. cleared .. ' items from ' .. citizenid)
        end
        
        return true, 'Storage cleared successfully (' .. cleared .. ' items removed)'
    end
    
    return false, 'Failed to clear storage'
end)