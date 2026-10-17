-- Client side cho hệ thống độ bền

-- Function kiểm tra độ bền local (client-side only)
local function CheckItemDurability(name)
    local angelSlots = exports.ox_inventory:GetSlotsWithItem(name)
    for _, item in ipairs(angelSlots) do
        if item and item.metadata and item.metadata.durability and tonumber(item.metadata.durability) > 0.1 then
            return tonumber(item.metadata.durability)
        end
    end
    return 0
end

-- Function thêm độ bền cho item (gọi server)
---@param itemname string Tên item cần thêm độ bền
---@param number number Số lượng độ bền cần thêm
local function AddDurability(itemname, number)
    if not itemname or not number then
        return print('[Durability] Thiếu thông tin item hoặc số lượng độ bền')
    end
    TriggerServerEvent('XN_DevMode:server:ActiveAddDurability', itemname, number)
end

-- Function trừ độ bền cho item (gọi server)
---@param itemname string Tên item cần trừ độ bền
local function RemoveDurability(itemname)
    if not itemname then
        return print('[Durability] Thiếu thông tin item')
    end
    TriggerServerEvent('XN_DevMode:server:ActiveRemoveDurability', itemname)
end

-- Function kiểm tra độ bền với server validation (async)
---@param itemname string Tên item cần kiểm tra
---@return boolean Trả về true nếu item còn độ bền > 0.1
local function CheckDurability(itemname)
    if not itemname then
        print('[Durability] Thiếu thông tin item')
        return false
    end
    return lib.callback.await('XN_DevMode:server:ActiveCheckDurability', false, itemname)
end

-- Export functions
exports('CheckItemDurability', CheckItemDurability)
exports('AddDurability', AddDurability)
exports('RemoveDurability', RemoveDurability)
exports('CheckDurability', CheckDurability)

--[[
    Ví dụ sử dụng:
    
    -- Thêm độ bền
    exports.XN_DevMode:AddDurability('lockpick', 10)
    
    -- Trừ độ bền theo config
    exports.XN_DevMode:RemoveDurability('lockpick')
    
    -- Kiểm tra độ bền (client-side)
    local durability = exports.XN_DevMode:CheckItemDurability('lockpick')
    
    -- Kiểm tra độ bền với server validation
    local hasDurability = exports.XN_DevMode:CheckDurability('lockpick')
]]