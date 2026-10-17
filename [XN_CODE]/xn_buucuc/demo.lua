-- Demo file để test xn_buucuc exports

-- Event demo cho lootbox (đã fix lỗi)
RegisterNetEvent('xn_buucuc:demo:getLootboxItem', function(winner)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        print('[XN_BUUCUC DEMO] Player not found for source: ' .. src)
        return
    end
    
    -- Lấy citizenid từ server Player object (đúng cách)
    local citizenid = Player.PlayerData.citizenid
    
    if Config.Debug then
        print('[XN_BUUCUC DEMO] Processing lootbox for citizen: ' .. citizenid)
    end
    
    -- Demo data cho test
    local loot = {
        name = 'cloth_shirt',
        type = 'clothing',
        component = 11,
        drawable = 15,
        sex = 'male',
        label = 'Áo Thun Demo',
        rarity = 'Rare',
        imageUrl = 'https://example.com/shirt.png'
    }
    
    local MetaData = {
        type = loot.component,
        drawable = loot.drawable,
        texture = 0,
        sex = loot.sex,
        id = loot.component,
        label = loot.label..' '..loot.drawable,
        description = (loot.sex == "male" and " Nam" or " Nữ"),
        imageurl = loot.imageUrl,
        DoHiem = loot.rarity,
        prop = false,
        clothesSlotID = loot.component,
    }
    
    if Config.Debug then
        print('[XN_BUUCUC DEMO] Item data:')
        print('  - citizenid: ' .. citizenid)
        print('  - item: ' .. loot.name)
        print('  - metadata: ' .. json.encode(MetaData))
    end
    
    -- Kiểm tra player có thể mang item không
    if not exports.ox_inventory:CanCarryItem(src, loot.name, 1) then
        -- Player không thể mang, chuyển vào kho bưu cục
        local success = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, loot.name, 1, MetaData)
        
        if success then
            TriggerClientEvent('xn_buucuc:client:notify', src, {
                title = 'Bưu cục',
                description = 'Kho đồ cá nhân đầy! Vật phẩm đã được chuyển về bưu cục',
                type = 'success'
            })
            
            if Config.Debug then
                print('[XN_BUUCUC DEMO] Item added to personal storage successfully')
            end
        else
            TriggerClientEvent('xn_buucuc:client:notify', src, {
                title = 'Lỗi',
                description = 'Không thể thêm vật phẩm vào bưu cục',
                type = 'error'
            })
            
            if Config.Debug then
                print('[XN_BUUCUC DEMO] Failed to add item to personal storage')
            end
        end
    else
        -- Player có thể mang, thêm vào inventory
        local success = exports.ox_inventory:AddItem(src, loot.name, 1, MetaData)
        
        if success then
            TriggerClientEvent('xn_buucuc:client:notify', src, {
                title = 'Nhận vật phẩm',
                description = 'Bạn đã nhận được ' .. loot.label,
                type = 'success'
            })
        end
    end
end)

-- Command để test AddItem
if Config.Debug then
    print('[XN_BUUCUC DEMO] Registering debug commands...')
    
    RegisterCommand('buucuc_test_add', function(source, args, rawCommand)
        print('[XN_BUUCUC DEMO] Command buucuc_test_add triggered by source: ' .. source)
        
        local src = source
        local Player = exports.qbx_core:GetPlayer(src)
        
        if not Player then
            print('[XN_BUUCUC DEMO] Player not found for source: ' .. src)
            TriggerClientEvent('chat:addMessage', src, {
                color = {255, 0, 0},
                multiline = true,
                args = {"ERROR", "Player not found!"}
            })
            return
        end
        
        local citizenid = Player.PlayerData.citizenid
        local itemName = args[1] or 'bread'
        local count = tonumber(args[2]) or 1
        
        print('[XN_BUUCUC DEMO] Testing with:')
        print('  - Source: ' .. src)
        print('  - CitizenID: ' .. citizenid)
        print('  - Item: ' .. itemName)
        print('  - Count: ' .. count)
        
        local success = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, itemName, count, {
            quality = 100,
            description = 'Test item từ command'
        })
        
        print('[XN_BUUCUC DEMO] AddItemToPersonalStorage returned: ' .. tostring(success))
        
        if success then
            TriggerClientEvent('xn_buucuc:client:notify', src, {
                title = 'Test thành công',
                description = 'Đã thêm ' .. count .. 'x ' .. itemName .. ' vào bưu cục',
                type = 'success'
            })
            
            TriggerClientEvent('chat:addMessage', src, {
                color = {0, 255, 0},
                multiline = true,
                args = {"SUCCESS", "Added " .. count .. "x " .. itemName .. " to storage!"}
            })
        else
            TriggerClientEvent('xn_buucuc:client:notify', src, {
                title = 'Test thất bại',
                description = 'Không thể thêm item vào bưu cục',
                type = 'error'
            })
            
            TriggerClientEvent('chat:addMessage', src, {
                color = {255, 0, 0},
                multiline = true,
                args = {"FAILED", "Could not add item to storage!"}
            })
        end
    end, false)
    
    -- Command để test RemoveItem
    RegisterCommand('buucuc_test_remove', function(source, args, rawCommand)
        local src = source
        local Player = exports.qbx_core:GetPlayer(src)
        
        if not Player then
            return
        end
        
        local citizenid = Player.PlayerData.citizenid
        local itemName = args[1] or 'bread'
        local count = tonumber(args[2]) or 1
        
        local success = exports.xn_buucuc:RemoveItemFromPersonalStorage(citizenid, itemName, count)
        
        if success then
            TriggerClientEvent('xn_buucuc:client:notify', src, {
                title = 'Test thành công',
                description = 'Đã xóa ' .. count .. 'x ' .. itemName .. ' khỏi bưu cục',
                type = 'success'
            })
        else
            TriggerClientEvent('xn_buucuc:client:notify', src, {
                title = 'Test thất bại',
                description = 'Không thể xóa item khỏi bưu cục',
                type = 'error'
            })
        end
    end, false)
    
    -- Command để kiểm tra thông tin kho
    RegisterCommand('buucuc_test_info', function(source, args, rawCommand)
        local src = source
        local Player = exports.qbx_core:GetPlayer(src)
        
        if not Player then
            return
        end
        
        local citizenid = Player.PlayerData.citizenid
        local storageInfo = exports.xn_buucuc:GetPersonalStorageInfo(citizenid)
        
        if storageInfo then
            TriggerClientEvent('xn_buucuc:client:notify', src, {
                title = 'Thông tin bưu cục',
                description = 'Slots: ' .. storageInfo.slots .. ', Weight: ' .. storageInfo.weight .. '/' .. storageInfo.maxWeight,
                type = 'info'
            })
            
            print('[XN_BUUCUC] Storage info for ' .. citizenid .. ':')
            print('  - Slots: ' .. storageInfo.slots)
            print('  - Weight: ' .. storageInfo.weight .. '/' .. storageInfo.maxWeight)
            print('  - Items count: ' .. (storageInfo.items and #storageInfo.items or 0))
        else
            TriggerClientEvent('xn_buucuc:client:notify', src, {
                title = 'Lỗi',
                description = 'Không thể lấy thông tin bưu cục',
                type = 'error'
            })
        end
    end, false)
    
    -- Command để trigger demo lootbox
    RegisterCommand('buucuc_test_lootbox', function(source, args, rawCommand)
        TriggerEvent('xn_buucuc:demo:getLootboxItem', 0)
    end, false)
    
    -- Command cơ bản để test
    RegisterCommand('buucuc_simple_test', function(source, args, rawCommand)
        print('[XN_BUUCUC] Simple test command triggered by source: ' .. source)
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 255},
            multiline = true,
            args = {"BUUCUC", "Simple test command working!"}
        })
        
        -- Test export function trực tiếp
        local testResult = exports.xn_buucuc:AddItemToPersonalStorage('TEST123', 'bread', 1, {})
        print('[XN_BUUCUC] Direct export test result: ' .. tostring(testResult))
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 255, 0},
            multiline = true,
            args = {"BUUCUC", "Export test result: " .. tostring(testResult)}
        })
    end, false)
    
    print('[XN_BUUCUC DEMO] All commands registered successfully!')
end

-- Test ngay khi resource start
CreateThread(function()
    Wait(5000) -- Đợi 5 giây để các resource khác load xong
    
    print('[XN_BUUCUC DEMO] Testing export availability...')
    
    -- Test xem export có hoạt động không
    if exports.xn_buucuc then
        print('[XN_BUUCUC DEMO] Export xn_buucuc is available')
        
        if exports.xn_buucuc.AddItemToPersonalStorage then
            print('[XN_BUUCUC DEMO] AddItemToPersonalStorage function is available')
        else
            print('[XN_BUUCUC DEMO] ERROR: AddItemToPersonalStorage function NOT available')
        end
    else
        print('[XN_BUUCUC DEMO] ERROR: Export xn_buucuc NOT available')
    end
    
    print('[XN_BUUCUC DEMO] Testing commands availability...')
    print('[XN_BUUCUC DEMO] Use: /buucuc_simple_test')
    print('[XN_BUUCUC DEMO] Use: /buucuc_test_add bread 5')
end)