-- =======================================================
-- ACID & TRIP SYSTEM (Server-side)
-- =======================================================

local acidRateLimits = {}
local ACID_COOLDOWN = 3000 -- 3 giây cooldown giữa mỗi lần dùng

local function CheckAcidRateLimit(src)
    local now = GetGameTimer()
    if acidRateLimits[src] and (now - acidRateLimits[src]) < ACID_COOLDOWN then
        return false
    end
    acidRateLimits[src] = now
    return true
end

AddEventHandler('playerDropped', function()
    local src = source
    acidRateLimits[src] = nil
end)

-- Hàm xử lý sử dụng chất gây nghiện & Trip
local function UseDrugItem(src, itemName, itemLabel, addictionChance, slot)
    if not CheckAcidRateLimit(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Vui lòng đợi trước khi dùng tiếp!',
            type = 'error'
        })
        return false
    end

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return false end

    local count = exports.ox_inventory:GetItemCount(src, itemName)
    if not count or count < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            description = string.format('Bạn không có %s!', itemLabel or itemName),
            type = 'error'
        })
        return false
    end

    -- Trừ 1 item
    local removed = exports.ox_inventory:RemoveItem(src, itemName, 1, nil, slot)
    if not removed then
        TriggerClientEvent('ox_lib:notify', src, {
            description = string.format('Không thể sử dụng %s!', itemLabel or itemName),
            type = 'error'
        })
        return false
    end

    -- Xử lý nghiện nếu hệ thống nghiện được bật
    if Config.Addiction and Config.Addiction.enabled then
        local chance = addictionChance or Config.AcidAddictionChance or 90
        local roll = math.random(1, 100)

        local metadata = Player.PlayerData.metadata.ladudu_addiction or {
            isAddicted = false,
            minutesOnlineSinceLastUse = 0,
            withdrawalActive = false
        }

        if roll <= chance then
            -- GÂY NGHIỆN
            metadata.isAddicted = true
            metadata.minutesOnlineSinceLastUse = 0
            metadata.withdrawalActive = false
            Player.Functions.SetMetaData('ladudu_addiction', metadata)

            -- Kích hoạt theo dõi nghiện trên client
            TriggerClientEvent('F7_ladudu_addiction:client:startAddictionMonitor', src)

            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Ảo Giác & Nghiện',
                description = string.format('Bạn cảm thấy thực tại bị bẻ cong... Bạn đã dính nghiện %s (%d%%)!', itemLabel or itemName, chance),
                type = 'error',
                duration = 6000
            })
        else
            -- Không dính nghiện
            if metadata.isAddicted then
                metadata.minutesOnlineSinceLastUse = 0
                metadata.withdrawalActive = false
                Player.Functions.SetMetaData('ladudu_addiction', metadata)
                TriggerClientEvent('F7_ladudu_addiction:client:startAddictionMonitor', src)
            end

            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Ảo Giác',
                description = string.format('Bạn đã dùng %s, cảm giác bay bổng bắt đầu xuất hiện...', itemLabel or itemName),
                type = 'inform',
                duration = 5000
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Ảo Giác',
            description = string.format('Bạn đã dùng %s, cảm giác bay bổng bắt đầu xuất hiện...', itemLabel or itemName),
            type = 'inform',
            duration = 5000
        })
    end

    -- Kích hoạt animation và hiệu ứng Trip trên client
    local drugConfig = Config.Acid or {
        name = itemLabel or 'Acid',
        type = 'trip',
        quality = 1.0,
        instant = false,
        sober = false,
        effects = {}
    }
    
    TriggerClientEvent('mini_hethongnghien:client:consumeDrug', src, drugConfig, math.random(1, 10000))
    return true
end

-- Backward compatible alias
local function UseAcid(src, slot)
    return UseDrugItem(src, Config.AcidItem or 'acid', 'Acid', Config.AcidAddictionChance or 90, slot)
end

-- Qbox usable item hooks (Tự động đăng ký trực tiếp cho qbx_core / ox_inventory)
exports.qbx_core:CreateUseableItem(Config.AcidItem or 'acid', function(source, item)
    UseDrugItem(source, Config.AcidItem or 'acid', 'Acid', Config.AcidAddictionChance or 90, item and item.slot)
end)

exports.qbx_core:CreateUseableItem('heroin', function(source, item)
    UseDrugItem(source, 'heroin', 'Heroin', 90, item and item.slot)
end)

-- Event khi client gọi dùng Acid
RegisterNetEvent('mini_hethongnghien:server:useAcid', function(slot)
    local src = source
    UseAcid(src, slot)
end)

-- ox_inventory server-side export hook
exports('UseAcidServer', function(event, item, inventory, slot, data)
    local src = inventory.id
    if event == 'usingItem' then
        UseAcid(src, slot)
    end
    return true
end)

-- =======================================================
-- EXPORTS & BACKWARD COMPATIBILITY
-- =======================================================

exports('Trip', function(targetSource, quality, duration)
    local drugConfig = {
        name = 'Acid Trip',
        type = 'trip',
        quality = quality or 1.0,
        instant = false,
        sober = false,
        effects = {}
    }
    if duration then
        drugConfig.effect_timeout = duration
    end
    TriggerClientEvent('mini_hethongnghien:client:consumeDrug', targetSource, drugConfig, math.random(1, 10000))
end)

exports('ConsumeDrug', function(targetSource, drugConfig)
    if not drugConfig then drugConfig = Config.Acid end
    TriggerClientEvent('mini_hethongnghien:client:consumeDrug', targetSource, drugConfig, math.random(1, 10000))
end)

-- Event Drugs:Consume từ các resource khác
AddEventHandler('Drugs:Consume', function(source, item)
    if type(source) == 'number' then
        local drugItem = item
        if type(item) == 'string' and item == 'acid' then
            drugItem = Config.Acid
        elseif type(item) ~= 'table' then
            drugItem = Config.Acid
        end
        TriggerClientEvent('mini_hethongnghien:client:consumeDrug', source, drugItem, math.random(1, 10000))
    end
end)

AddEventHandler('Drugs:Create', function(callback, opts)
    if type(callback) == 'function' then
        callback({
            name = (opts and opts.name or 'Acid'),
            type = (opts and opts.type or 'trip'),
            quality = (opts and opts.quality or 1.0),
            instant = (opts and opts.instant or false),
            sober = (opts and opts.sober or false),
            effects = (opts and opts.effects or {}),
            animation = (opts and opts.animation or Config.Acid.animation)
        })
    end
end)
