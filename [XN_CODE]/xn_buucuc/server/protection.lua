-- Server-side protection cho personal storage
-- File này chạy sau main.lua để override các hàm cần thiết

CreateThread(function()
    Wait(3000) -- Đợi tất cả resource load xong
    
    -- Danh sách các event cần chặn
    local blockedEvents = {
        'ox_inventory:swapItems',
        'ox_inventory:moveItem',
        'ox_inventory:setSlot', 
        'ox_inventory:giveItem',
        'ox_inventory:takeItem'
    }
    
    -- Đăng ký handler cho các event để chặn
    for _, eventName in ipairs(blockedEvents) do
        RegisterNetEvent(eventName, function(...)
            local src = source
            local args = {...}
            
            -- Kiểm tra nếu có tham số nào liên quan đến kho cá nhân
            local blocked = false
            for _, arg in ipairs(args) do
                if type(arg) == 'string' and string.find(arg, 'buucuc_') then
                    blocked = true
                    break
                elseif type(arg) == 'table' then
                    for key, value in pairs(arg) do
                        if type(value) == 'string' and string.find(value, 'buucuc_') then
                            blocked = true
                            break
                        end
                    end
                    if blocked then break end
                end
            end
            
            if blocked then
                print('[XN_BUUCUC] BLOCKED: Server event ' .. eventName .. ' from source ' .. src)
                
                -- Gửi thông báo cho player
                TriggerClientEvent('xn_buucuc:client:notify', src, {
                    title = 'Kho cá nhân',
                    description = 'Hành động không được phép với kho cá nhân!',
                    type = 'error'
                })
                
                return -- Chặn event
            end
        end)
    end
    
    -- Override thêm các exports có thể bị lạm dụng
    local protectedExports = {
        'AddItem',
        'RemoveItem', 
        'SetSlot',
        'SwapSlots',
        'GiveItem'
    }
    
    for _, exportName in ipairs(protectedExports) do
        local originalExport = exports.ox_inventory[exportName]
        if originalExport then
            exports.ox_inventory[exportName] = function(inventory, ...)
                -- Chặn nếu inventory là kho cá nhân và không được gọi từ resource này
                if inventory and type(inventory) == "string" and string.find(inventory, 'buucuc_') then
                    local info = debug.getinfo(2, "S")
                    local source_file = info.source
                    
                    -- Chỉ cho phép từ resource xn_buucuc hoặc qbx_core (cho admin commands)
                    if not (string.find(source_file, "xn_buucuc") or string.find(source_file, "qbx_core")) then
                        print('[XN_BUUCUC] BLOCKED: External ' .. exportName .. ' attempt to personal storage: ' .. inventory)
                        print('[XN_BUUCUC] Source: ' .. tostring(source_file))
                        return false
                    end
                end
                
                -- Gọi hàm gốc nếu được phép
                return originalExport(inventory, ...)
            end
            
            if Config.Debug then
                print('[XN_BUUCUC] Protected export: ' .. exportName)
            end
        end
    end
    
    if Config.Debug then
        print('[XN_BUUCUC] Server protection layer activated')
    end
end)

-- Chặn commands có thể được sử dụng để thêm item
AddEventHandler('chatMessage', function(source, name, message)
    if message then
        local msg = string.lower(message)
        -- Chặn các lệnh có thể thêm item vào kho cá nhân
        if (string.find(msg, '/giveitem') or string.find(msg, '/additem') or string.find(msg, '/spawn')) 
           and string.find(msg, 'buucuc_') then
            
            print('[XN_BUUCUC] BLOCKED: Chat command attempt to modify personal storage from ' .. source)
            
            TriggerClientEvent('xn_buucuc:client:notify', source, {
                title = 'Kho cá nhân', 
                description = 'Không thể sử dụng lệnh với kho cá nhân!',
                type = 'error'
            })
            
            CancelEvent() -- Chặn lệnh
        end
    end
end)