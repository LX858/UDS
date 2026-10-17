local QBX = exports.qbx_core

-- Function kiểm tra quyền truy cập stash
local function hasStashPermission(src, stashConfig)
    local player = QBX:GetPlayer(src)
    if not player then return false end
    
    local playerJob = player.PlayerData.job
    if not playerJob then return false end
    
    -- Nếu không có groups trong config, cho phép tất cả
    if not stashConfig.groups then return true end
    
    -- Kiểm tra job và grade
    for jobName, requiredGrade in pairs(stashConfig.groups) do
        if playerJob.name == jobName and playerJob.grade.level >= requiredGrade then
            return true
        end
    end
    
    return false
end

-- Khởi tạo kho đồ trong ox_inventory
local function initializeStashes()
    -- Đăng ký job stashes
    for jobName, stashData in pairs(Config.Stashes) do
        exports.ox_inventory:RegisterStash(stashData.stashId, stashData.label, stashData.slots, stashData.weight, false)
        print(string.format('[XN_STASH] Đã khởi tạo kho đồ job: %s (%s)', stashData.label, stashData.stashId))
    end
    
    -- Personal stashes sẽ được đăng ký động khi player sử dụng
    print('[XN_STASH] Personal stashes sẽ được tạo động khi sử dụng')
end

-- Function để tạo personal stash cho player
local function createPersonalStash(citizenid, stashId, stashData)
    local personalStashId = citizenid .. '_' .. stashId
    
    -- Kiểm tra xem stash đã được đăng ký chưa
    local success = pcall(function()
        exports.ox_inventory:RegisterStash(personalStashId, stashData.label, stashData.slots, stashData.weight, false)
    end)
    
    if success then
        print(string.format('[XN_STASH] Tạo kho đồ cá nhân: %s cho %s', personalStashId, citizenid))
    end
    
    return personalStashId
end

-- Event khi player mở personal stash
RegisterNetEvent('xn_stash:server:createPersonalStash', function(stashId)
    local src = source
    local player = QBX:GetPlayer(src)
    
    if not player then return end
    
    -- Validate input
    if not stashId or type(stashId) ~= 'string' then return end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Tìm stash config
    for personalName, stashData in pairs(Config.PersonalStashes) do
        if stashData.stashId == stashId then
            -- Kiểm tra quyền truy cập
            if not hasStashPermission(src, stashData) then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Thông báo',
                    description = Config.Notifications.noPermission,
                    type = 'error'
                })
                return
            end
            
            local personalStashId = createPersonalStash(citizenid, stashId, stashData)
            -- Gửi signal cho client mở stash
            TriggerClientEvent('xn_stash:client:openPersonalStash', src, personalStashId)
            break
        end
    end
end)

-- Event kiểm tra quyền truy cập job stash
RegisterNetEvent('xn_stash:server:checkJobStashAccess', function(stashId)
    local src = source
    
    -- Validate input
    if not stashId or type(stashId) ~= 'string' then return end
    
    -- Tìm stash config
    for jobName, stashData in pairs(Config.Stashes) do
        if stashData.stashId == stashId then
            if hasStashPermission(src, stashData) then
                TriggerClientEvent('xn_stash:client:openStash', src, stashId)
            else
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Thông báo',
                    description = Config.Notifications.noPermission,
                    type = 'error'
                })
            end
            return
        end
    end
end)

-- Event khi resource start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(1000) -- Đợi ox_inventory load
        initializeStashes()
    end
end)

-- Function lấy config của kho đồ theo ID
local function getStashConfig(inventoryId)
    if not inventoryId then return nil end
    
    -- Check Job Stashes
    for _, stashData in pairs(Config.Stashes) do
        if stashData.stashId == inventoryId then
            return stashData
        end
    end
    
    -- Check Personal Stashes
    for _, stashData in pairs(Config.PersonalStashes) do
        local suffix = '_' .. stashData.stashId
        if string.sub(inventoryId, -#suffix) == suffix then
            return stashData
        end
    end
    
    return nil
end

-- Function kiểm tra item có trong whitelist hay không
local function isItemWhitelisted(item, whitelist)
    if not whitelist then return true end
    
    for k, v in pairs(whitelist) do
        if type(k) == 'number' and v == item then
            return true
        elseif k == item and v == true then
            return true
        end
    end
    return false
end

-- Hook của ox_inventory khi di chuyển item
exports.ox_inventory:registerHook('swapItems', function(payload)
    -- Nếu di chuyển nội bộ trong cùng 1 kho, cho phép
    if payload.fromInventory == payload.toInventory then return true end
    
    -- 1. KIỂM TRA KHO ĐỒ NHẬN ITEM (toInventory)
    local toStashConfig = getStashConfig(payload.toInventory)
    if toStashConfig then
        -- Nếu kho đồ chỉ cho phép lấy ra (không cho cất vào)
        if toStashConfig.takeOnly or toStashConfig.onlyWithdraw or toStashConfig.canDeposit == false then
            TriggerClientEvent('ox_lib:notify', payload.source, {
                title = 'Thông báo',
                description = Config.Notifications.cannotDeposit or "Kho đồ này chỉ cho phép lấy ra, không thể cất vào!",
                type = 'error'
            })
            return false -- Hủy hành động di chuyển item
        end

        -- Nếu kho đồ có cấu hình whitelist
        if toStashConfig.whitelist then
            local itemName = payload.fromSlot.name
            if not isItemWhitelisted(itemName, toStashConfig.whitelist) then
                -- Thông báo cho người chơi
                TriggerClientEvent('ox_lib:notify', payload.source, {
                    title = 'Thông báo',
                    description = Config.Notifications.notWhitelisted or "Vật phẩm này không được phép cất vào kho này!",
                    type = 'error'
                })
                return false -- Hủy hành động di chuyển item
            end
        end
    end
    
    -- 2. KIỂM TRA TRƯỜNG HỢP SWAP ĐÈ ITEM (Kéo từ kho đè vào ô đã có item trong túi đồ => item trong túi sẽ bị đẩy ngược vào kho)
    if type(payload.toSlot) == 'table' and payload.toSlot.name then
        local fromStashConfig = getStashConfig(payload.fromInventory)
        if fromStashConfig then
            -- Nếu kho xuất phát là takeOnly thì không cho phép swap đè (tránh bị đẩy item túi vào kho)
            if fromStashConfig.takeOnly or fromStashConfig.onlyWithdraw or fromStashConfig.canDeposit == false then
                TriggerClientEvent('ox_lib:notify', payload.source, {
                    title = 'Thông báo',
                    description = Config.Notifications.cannotDeposit or "Kho đồ này chỉ cho phép lấy ra, không thể cất/đổi đồ vào!",
                    type = 'error'
                })
                return false
            end

            -- Nếu kho xuất phát có whitelist, kiểm tra item trong túi bị đẩy ngược vào kho có nằm trong whitelist không
            if fromStashConfig.whitelist then
                local pushedItemName = payload.toSlot.name
                if not isItemWhitelisted(pushedItemName, fromStashConfig.whitelist) then
                    TriggerClientEvent('ox_lib:notify', payload.source, {
                        title = 'Thông báo',
                        description = Config.Notifications.notWhitelisted or "Vật phẩm đổi ngược vào kho không nằm trong danh sách cho phép!",
                        type = 'error'
                    })
                    return false
                end
            end
        end
    end
    
    return true
end)
