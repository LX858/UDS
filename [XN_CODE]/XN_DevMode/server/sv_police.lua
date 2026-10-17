RegisterNetEvent('motuido')
AddEventHandler('motuido', function()
	exports.ox_inventory:forceOpenInventory(1, 'stash', 'society_police')
end)


local stash = {
	id = 'society_police',
	label = 'Kho tịch thu đồ',
	slots = 100,
	weight = 9999999999999,
	owner = false,
	-- groups = {['police'] = 10},
}

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == 'ox_inventory' or resourceName == GetCurrentResourceName() then
        exports.ox_inventory:RegisterStash(stash.id, stash.label, stash.slots, stash.weight, stash.owner)
    end
end)

--block kho do canh sat . cap duoi ko lay dc vat pham ra khoi kho do
local hookId = exports.ox_inventory:registerHook('swapItems', function(payload)
    --print(json.encode(payload, { indent = true }))
    if getGrade(payload.source) < 9  then
        if payload.fromType =='player' and payload.action ~= 'swap' then
            return true
        end
        return false
    end
    return true
end, {
    print = false,
    --itemFilter = {
    --    --money = true,
    --},
    inventoryFilter = {
        '^society_police',
    }
})


-- Đăng ký hook cho sự kiện swapItems
local hookId = exports.ox_inventory:registerHook('swapItems', function(payload)
    -- Lấy thông tin về vật phẩm
    local source = payload.source
    local fromInventory = payload.fromInventory
    local toInventory = payload.toInventory
    local fromType = payload.fromType
    local toType = payload.toType
    local fromSlot = payload.fromSlot
    local toSlot = payload.toSlot
    
    -- Kiểm tra xem vật phẩm có phải là ⭐ hay không
    if fromSlot.name == 'money' or toSlot?.name == 'money' then
        -- Nếu là ⭐, kiểm tra điều kiện
        
        -- Nếu đang di chuyển ⭐ từ kho đồ không phải người chơi sang túi đồ người chơi
        if fromType ~= 'player' and toSlot?.name == 'money' then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = 'Bạn không thể lấy ⭐ từ kho đồ'
            })
            return false
        end
        
        -- Kiểm tra xem đang cố gắng vứt ⭐ hay không
        if toType == 'drop' then
            -- Ngăn chặn vứt ⭐
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = 'Bạn không thể vứt ⭐'
            })
            return false
        end
        
        -- Kiểm tra xem đang cố gắng chuyển ⭐ vào kho đồ khác (không phải túi người chơi khác)
        if toType ~= 'player' then
            -- Ngăn chặn chuyển ⭐ vào kho đồ
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = 'Bạn chỉ có thể đưa ⭐ cho người chơi khác'
            })
            return false
        end

        -- Kiểm tra xem đang cố gắng chuyển ⭐ vào kho đồ khác (không phải túi người chơi khác)

    end
    
    -- Cho phép các hành động khác
    return true
end, {
    print = false, -- Thay đổi thành false để không in ra console
    itemFilter = { money = true }, -- Chỉ áp dụng filter cho tiền
})


-- CreateThread(function()
--     local ox = exports.ox_inventory
--     ox:registerHook('swapItems', function(payload)
--         -- print(json.encode(payload, { indent = true }))
--         if (payload.action == 'move' or payload.action == 'stack') 
--         -- or payload.action == 'trunk'
--         and payload.fromType == 'player' and payload.fromInventory ~= payload.source and exports.qbx_core:GetPlayer(payload.toInventory).PlayerData.job.name == 'police' then
--         -- and exports.qbx_core:GetPlayer(payload.toInventory).PlayerData.job.name == 'police'
--         --    or payload.fromType == 'trunk'
--             -- Nếu đang di chuyển ⭐ từ kho đồ không phải người chơi sang túi đồ người chơi
--             if payload.fromSlot.name == 'money' then
--                 TriggerClientEvent('ox_lib:notify', payload.source, {
--                     type = 'error',
--                     description = 'Bạn không thể lấy ⭐ từ kho đồ'
--                 })
--                 return false
--             end

--             local clothingItems = {
--                 'cloth_torso', 'cloth_outfit', 'cloth_tshirt', 'cloth_arms', 'cloth_pants', 'cloth_shoes', 'cloth_decals',
--                 'cloth_ears', 'cloth_mask', 'cloth_bproof', 'cloth_chain', 'cloth_bags', 'cloth_glasses', 'cloth_watches', 'cloth_bracelets', 'cloth_helmet', 'clothes'
--             }
            
--             for _, item in ipairs(clothingItems) do
--                 if payload.fromSlot.name == item then
--                     TriggerClientEvent('ox_lib:notify', payload.source, {
--                         type = 'error',
--                         description = 'Bạn không thể lấy quần áo của người chơi khác'
--                     })
--                     return false
--                 end
--             end
            
--             Citizen.CreateThread(function()
--                 if ox:RemoveItem(payload.toInventory, payload.fromSlot.name, payload.count) then
--                     ox:AddItem('society_police', payload.fromSlot.name, payload.count, payload.fromSlot.metadata)
--                 end
--             end)

--             TriggerClientEvent('ox_lib:notify', payload.source, {
--                 type = 'success',
--                 description = "Bạn tịch thu: x"..payload.count.." "..payload.fromSlot.label
--             })

--             if payload.fromType == 'player' then
--                 TriggerClientEvent('ox_lib:notify', payload.fromInventory, {
--                     type = 'error',
--                     description = "Bạn đã bị tịch thu: x"..payload.count.." "..payload.fromSlot.label
--                 })
--             end
           
--         end

--     end, {
--         print = false,
--     })
-- end)
