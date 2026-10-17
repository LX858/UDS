local Config = require 'config.config'

-- Hàm kiểm tra item trong kho
local function CheckSlotItem(source, name)
    return exports.ox_inventory:GetSlotsWithItem(source, name, {})
end

local function ActiveRemoveDurability(source, name)
    local ItemCheckDurabilty = CheckSlotItem(source, name)
    if ItemCheckDurabilty and ItemCheckDurabilty[1] then
        local ItemData = ItemCheckDurabilty[1] 
        local ItemDataMetaData = ItemData.metadata
        local currentDurability = tonumber(ItemDataMetaData.durability) or 100
        local newDurability = math.max(currentDurability - Config.RemoveDurabilityQuanlity[name], 0) -- Đảm bảo độ bền không dưới 0
        exports.ox_inventory:SetDurability(source, ItemData.slot, newDurability)
        if newDurability <= 1 then 
            exports.ox_inventory:RemoveItem(source, name, 1)
        end
    end
end
local function ActiveAddDurability(source, name, number)
    local ItemCheckDurabilty = CheckSlotItem(source, name)
    if ItemCheckDurabilty and ItemCheckDurabilty[1] then
        local ItemData = ItemCheckDurabilty[1]
        local ItemDataMetaData = ItemData.metadata
        local currentDurability = tonumber(ItemDataMetaData.durability) or 100
        local newDurability = math.min(currentDurability + number, 100)
        exports.ox_inventory:SetDurability(source, ItemData.slot, newDurability)
    end
end

local function ActiveCheckDurability(source, name)
    local ItemCheckDurabilty = CheckSlotItem(source, name)
    if ItemCheckDurabilty and ItemCheckDurabilty[1] then
        local ItemData = ItemCheckDurabilty[1]
        local ItemDataMetaData = ItemData.metadata
        if ItemDataMetaData.durability ~= nil then 
            if tonumber(ItemDataMetaData.durability)  > 0.1 then 
                return true
            end
        else 
            exports.qbx_core:Notify(source, 'Vật phẩm đã được cập nhật lại độ bền, hãy thử lại', 'info')
            exports.ox_inventory:SetDurability(source, ItemData.slot, 100)
        end
    end
    return false
end


-- Event cho client gọi đến server để thêm độ bền
RegisterNetEvent('XN_DevMode:server:ActiveAddDurability', function(itemname, number)
    local source = source
    if not itemname or not number then
        return exports.qbx_core:Notify(source, 'Thiếu thông tin item hoặc số lượng độ bền', 'error')
    end
    ActiveAddDurability(source, itemname, number)
end)

-- Event cho client gọi đến server để trừ độ bền
RegisterNetEvent('XN_DevMode:server:ActiveRemoveDurability', function(itemname)
    local source = source
    if not itemname then
        return exports.qbx_core:Notify(source, 'Thiếu thông tin item', 'error')
    end
    ActiveRemoveDurability(source, itemname)
end)

-- Event cho client kiểm tra độ bền (trả về callback)
lib.callback.register('XN_DevMode:server:ActiveCheckDurability', function(source, itemname)
    if not itemname then
        return false
    end
    return ActiveCheckDurability(source, itemname)
end)

-- Export functions cho server to server
exports("ActiveAddDurability", ActiveAddDurability)
exports("ActiveRemoveDurability", ActiveRemoveDurability)
exports("ActiveCheckDurability", ActiveCheckDurability)
