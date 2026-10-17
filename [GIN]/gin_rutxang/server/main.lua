RegisterNetEvent('gin_rutxang:server:siphonFuel', function(netId, clientFuel)
    local src = source

    -- 1. Kiểm tra xem người chơi có bình xăng rỗng hay không
    local itemCount = exports.ox_inventory:Search(src, 'count', Config.EmptyItem)
    if not itemCount or itemCount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Rút Xăng',
            description = 'Bạn không có bình xăng rỗng!',
            type = 'error'
        })
        return
    end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        -- 2. Trừ xăng của xe về 0.0 và đồng bộ StateBag toàn server (replicated = true)
        Entity(vehicle).state:set('fuel', 0.0, true)

        -- Hỗ trợ các export server-side của các script xăng phổ biến
        if GetResourceState('ox_fuel') == 'started' and exports.ox_fuel then
            pcall(function() exports.ox_fuel:SetFuel(vehicle, 0.0) end)
        end
        if GetResourceState('LegacyFuel') == 'started' then
            pcall(function() exports['LegacyFuel']:SetFuel(vehicle, 0.0) end)
        end
        if GetResourceState('ps-fuel') == 'started' then
            pcall(function() exports['ps-fuel']:SetFuel(vehicle, 0.0) end)
        end
        if GetResourceState('cdn-fuel') == 'started' then
            pcall(function() exports['cdn-fuel']:SetFuel(vehicle, 0.0) end)
        end
        if GetResourceState('qb-fuel') == 'started' then
            pcall(function() exports['qb-fuel']:SetFuel(vehicle, 0.0) end)
        end

        -- Broadcast Event cho tất cả người chơi
        TriggerClientEvent('gin_rutxang:client:syncFuel', -1, netId, 0.0)

        -- 3. Xóa 1 bình xăng rỗng khỏi túi đồ
        local removed = exports.ox_inventory:RemoveItem(src, Config.EmptyItem, 1)
        if removed then
            local amt = math.floor(tonumber(clientFuel) or 0)
            if amt < 0 then amt = 0 end
            if amt > 100 then amt = 100 end

            -- 4. Khởi tạo metadata thông tin xăng đã rút được theo yêu cầu
            local itemInfo = { cdn_fuel = tostring(amt), gasamount = amt, fuel = amt }

            -- 5. Thêm 1 bình xăng có xăng vào túi đồ với metadata tương ứng
            local itemAdded = exports.ox_inventory:AddItem(src, Config.FilledItem, 1, itemInfo)

            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Rút Xăng',
                description = string.format('Bạn đã rút %d%% xăng từ xe vào bình thành công!', amt),
                type = 'success'
            })
        end
    end
end)

-- Kiểm tra job của người chơi trên server (Hỗ trợ QBCore, ESX, ox_core)
local function hasRequiredJob(src)
    if not Config.RequiredJob then return true end

    -- QBCore / qbx_core
    if GetResourceState('qb-core') == 'started' or GetResourceState('qbx_core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        if QBCore then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player and Player.PlayerData and Player.PlayerData.job then
                return Player.PlayerData.job.name == Config.RequiredJob
            end
        end
    end

    -- ESX
    if GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        if ESX then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer and xPlayer.getJob then
                return xPlayer.getJob().name == Config.RequiredJob
            end
        end
    end

    -- ox_core
    if GetResourceState('ox_core') == 'started' and exports.ox_core then
        local player = exports.ox_core:GetPlayer(src)
        if player and player.getGroup then
            return player:getGroup(Config.RequiredJob) ~= nil
        end
    end

    return true
end

-- Event đổi vỏ chai lấy bình xăng rỗng tại Kho lưu trữ cây xăng
RegisterNetEvent('gin_rutxang:server:exchangeEmptyCans', function(amount)
    local src = source
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end

    -- Kiểm tra Job người chơi
    if not hasRequiredJob(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Kho Lưu Trữ Cây Xăng',
            description = 'Chỉ có nhân viên Cây Xăng (cayxang) mới được phép đổi bình xăng rỗng!',
            type = 'error'
        })
        return
    end

    local ratio = Config.ExchangeRatio or 10
    local bottleItem = Config.BottleItem or 'vochai'
    local emptyItem = Config.EmptyItem or 'canxangrong'

    local neededBottles = amount * ratio
    local bottleCount = exports.ox_inventory:Search(src, 'count', bottleItem) or 0

    if bottleCount < neededBottles then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Kho Lưu Trữ Cây Xăng',
            description = string.format('Bạn không đủ vỏ chai! Cần %d %s (bạn hiện có %d).', neededBottles, bottleItem, bottleCount),
            type = 'error'
        })
        return
    end

    -- Xóa vỏ chai khỏi túi đồ
    local removed = exports.ox_inventory:RemoveItem(src, bottleItem, neededBottles)
    if removed then
        -- Thêm bình xăng rỗng vào túi đồ
        local added = exports.ox_inventory:AddItem(src, emptyItem, amount)
        if added then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Kho Lưu Trữ Cây Xăng',
                description = string.format('Đã đổi thành công %d %s lấy %d bình xăng rỗng!', neededBottles, bottleItem, amount),
                type = 'success'
            })
        end
    end
end)
