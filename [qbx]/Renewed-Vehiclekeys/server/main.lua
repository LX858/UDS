local utils = require 'utils.server'
local data = require 'data'

-- Cooldown map cho thông báo lockpick (5 phút mỗi biển số)
local lockpickNotifyCooldown = {}

RegisterNetEvent('Renewed-Vehiclekeys:server:updateLocal', function(netId)
    local entity = utils.getEntityFromNetId(netId)

    if entity and #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(entity)) < 10 then
        local state = Entity(entity).state
        
        -- Xe đã bị lockpick hoặc hotwire thì KHÔNG random lock
        if state.isLockpicked or state.isHotwired then
            -- Xe bị lockpick phải luôn mở khóa
            if state.isLockpicked and not state.vehicleLock then
                state:set('vehicleLock', {
                    lock = 1  -- Luôn unlocked
                }, true)
            end
            return
        end
        
        local lockChance = GetPedInVehicleSeat(entity, -1) ~= 0 and data.lockChance or data.lockChanceAI

        if not state.vehicleLock then
            state:set('vehicleLock', {
                lock = math.random() <= lockChance and 2 or 1
            }, true)
        end
    end
end)

RegisterNetEvent('Renewed-Vehiclekeys:server:toggleLock', function(netId)
    local vehicle = utils.getEntityFromNetId(netId)

    if vehicle > 0 and utils.hasKey(source, GetVehicleNumberPlateText(vehicle)) then
        local state = Entity(vehicle).state

        local vehiclelock = state?.vehicleLock?.lock or 1

        local newLock = vehiclelock < 2 and 2 or 1

        if newLock == vehiclelock then
            state:set('vehicleLock', false, true)
        end

        state:set('vehicleLock', {
            lock = vehiclelock < 2 and 2 or 1,
            sound = true
        }, true)
    end
end)

RegisterNetEvent('Renewed-Vehiclekeys:server:setVehicleUnlocked', function(netId)
    local vehicle = utils.getEntityFromNetId(netId)

    if vehicle > 0 and utils.hasKey(source, GetVehicleNumberPlateText(vehicle)) then
        Entity(vehicle).state:set('vehicleLock', {
            lock = 1,
        }, true)
    end
end)

RegisterNetEvent('Renewed-Vehiclekeys:server:toggleLights', function(netId)
    local vehicle = utils.getEntityFromNetId(netId)

    if vehicle then
        TriggerClientEvent('Renewed-Vehiclekeys:client:toggleLights', NetworkGetEntityOwner(vehicle), netId)
    end
end)

RegisterNetEvent('Renewed-Vehiclekeys:server:searchVehicle', function()
    local src = source
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(src), false)

    if vehicle > 0 and DoesEntityExist(vehicle) then
        local state = Entity(vehicle).state

        if not state.searched then
            state:set('searched', true, true)

            if math.random() < data.searchPercent then
                local item = data.rewards[math.random(#data.rewards)]

                if item.name == 'key' then
                    utils.addKey(src, GetVehicleNumberPlateText(vehicle))
                else
                    exports.ox_inventory:AddItem(src, item.name, item.amount)
                end
            else
                utils.notify(src, 'error', locale('found_nothing'))
            end
        end
    end
end)


-- Event để xử lý khi lockpick bị gãy
RegisterNetEvent('Renewed-Vehiclekeys:server:breakLockpick', function(slot, item)
    local src = source
    local slotItem = slot and exports.ox_inventory:GetSlot(src, slot)

    if not slotItem or slotItem.name ~= item then return end

    -- Xóa lockpick khi gãy
    utils.removeItem(src, item, slot)
end)

RegisterNetEvent('Renewed-Vehiclekeys:server:lockpickDoor', function(netId, slot, item, degrade)
    local src = source
    local vehicle = utils.getEntityFromNetId(netId)
    if not vehicle or vehicle == 0 then return end

    local plate = utils.formatPlate(GetVehicleNumberPlateText(vehicle))
    if plate == 'XEBAN999' then return end

    local slotItem = slot and exports.ox_inventory:GetSlot(src, slot)

    if not slotItem or slotItem.name ~= item then return end

    local success = lib.callback.await('Renewed-Vehiclekeys:client:lockPickCar', src, netId, item)

    if success then
        -- -- Chỉ degrade khi thành công
        -- if degrade then
        --     local minus = math.random(degrade.min, degrade.max)
        --     if minus > 0 then
        --         local newAmount = (slotItem?.metadata?.durability or 100) - minus

        --         if newAmount > 0 then
        --             utils.setDurability(src, slot, newAmount)
        --         else
        --             utils.removeItem(src, item, slot)
        --         end
        --     end
        -- end
    else
        -- Nếu thất bại, lockpick bị gãy
        local tyle = math.random(1, 100)
        if tyle > 1 and tyle < 30 then
            utils.removeItem(src, item, slot)
        end
    end

    if success then
        local state = Entity(vehicle).state

        if state?.vehicleLock == 1 then
            state:set('vehicleLock', false, true)
        end

        state:set('vehicleLock', {
            lock = 1,
        }, true)
        
        -- Đánh dấu xe đã bị lockpick
        state:set('isLockpicked', true, true)
    end
end)

RegisterNetEvent('Renewed-Vehiclekeys:server:StealCandyFromKid', function(deadPed, Vehicle)
    -- Tính năng lấy chìa khóa từ NPC chết đã bị tắt
    return
    
    --[[ DISABLED
    local src = source

    local ped, vehicle = utils.getEntityFromNetId(deadPed), utils.getEntityFromNetId(Vehicle)

    if ped == 0 or vehicle == 0 then return end

    if IsPedAPlayer(ped) then return end

    local pedCoords = GetEntityCoords(GetPlayerPed(src))

    if #(pedCoords - GetEntityCoords(ped)) > 10 or #(pedCoords - GetEntityCoords(vehicle)) > 20 then return end

    if lib.callback.await('Renewed-Vehiclekeys:client:stealFromPed', src, deadPed) then
        utils.addKey(src, GetVehicleNumberPlateText(vehicle))

        Entity(vehicle).state:set('vehicleLock', {
            lock = 1,
        }, true)
    end
    --]]
end)

RegisterNetEvent('Renewed-Vehiclekeys:server:robPedKeys', function(robbedPed, Vehicle)
    local src = source

    local ped, vehicle = utils.getEntityFromNetId(robbedPed), utils.getEntityFromNetId(Vehicle)

    if ped == 0 or vehicle == 0 or IsPedAPlayer(ped) then return end

    local pedCoords = GetEntityCoords(GetPlayerPed(src))

    if #(pedCoords - GetEntityCoords(ped)) < 10 and #(pedCoords - GetEntityCoords(vehicle)) < 10 then
        local freeze = GetEntitySpeed(vehicle) < 0.5 and math.random() <= 0.90 -- 10% chance to not freeze, which would cause the ped to drive off

        FreezeEntityPosition(vehicle, freeze)

        local success = lib.callback.await('Renewed-Vehiclekeys:client:robPedKeys', src, robbedPed, Vehicle)

        if freeze then
            FreezeEntityPosition(vehicle, false)
        end

        if success then
            utils.addKey(src, GetVehicleNumberPlateText(vehicle))

            Entity(vehicle).state:set('vehicleLock', {
                lock = 1,
            }, true)
        end
    end
end)

lib.callback.register('Renewed-Vehiclekeys:server:getKeys', function(source)
    return utils.getKeys(source)
end)

lib.callback.register('Renewed-Vehiclekeys:server:hasKey', function(source, plate)
    return utils.hasKey(source, plate)
end)

-- Kéo player khác ra khỏi ghế lái
RegisterNetEvent('Renewed-Vehiclekeys:server:dragOutDriver', function(driverNetId, vehicleNetId)
    local src = source
    local vehicle = utils.getEntityFromNetId(vehicleNetId)

    if not vehicle or vehicle == 0 then return end

    -- Kiểm tra khoảng cách người gửi đến xe (tối đa 10m)
    local srcPed = GetPlayerPed(src)
    if #(GetEntityCoords(srcPed) - GetEntityCoords(vehicle)) > 10 then return end

    -- Kiểm tra người gửi có chìa khóa xe không
    local plate = GetVehicleNumberPlateText(vehicle)
    if not data.immune[GetEntityModel(vehicle)] and not utils.hasKey(src, plate) then return end

    -- Lấy driver ped từ netId
    local driverPed = utils.getEntityFromNetId(driverNetId)
    if not driverPed or driverPed == 0 then return end

    -- Kiểm tra driver thực sự đang ngồi ghế lái của xe đó
    if GetPedInVehicleSeat(vehicle, -1) ~= driverPed then return end

    -- Tìm player sở hữu ped đó và gửi lệnh thoát xe
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if GetPlayerPed(pid) == driverPed then
            TriggerClientEvent('Renewed-Vehiclekeys:client:forceExitVehicle', pid, vehicleNetId)
            return
        end
    end
end)

RegisterNetEvent('Renewed-Vehiclekeys:server:hotwireVehicle', function(netId)
    local src = source
    local vehicle = utils.getEntityFromNetId(netId)
    
    if not vehicle or vehicle == 0 then 
        print('[Vehiclekeys] Hotwire: Vehicle not found')
        return 
    end
    
    -- Kiểm tra xe có owner và gửi thông báo cho chủ xe
    local plate = GetVehicleNumberPlateText(vehicle)
    if plate then
        plate = plate:gsub('%s', ''):upper() -- Format plate
        print('[Vehiclekeys] Hotwire detected - Plate: ' .. plate)
        
        -- Check cooldown (5 phút = 300 giây)
        local currentTime = os.time()
        if not lockpickNotifyCooldown[plate] or (currentTime - lockpickNotifyCooldown[plate]) >= 300 then
            -- Query database để lấy owner
            local result = MySQL.single.await('SELECT citizenid FROM player_vehicles WHERE plate = ? LIMIT 1', {plate})
            
            if result and result.citizenid then
                local ownerCitizenid = result.citizenid
                print('[Vehiclekeys] Owner found: ' .. ownerCitizenid)
                
                -- Lấy source của người hotwire
                local hotwirerPlayer = exports.qbx_core:GetPlayer(src)
                local hotwirerCitizenid = hotwirerPlayer and hotwirerPlayer.PlayerData.citizenid
                
                print('[Vehiclekeys] Hotwirer: ' .. (hotwirerCitizenid or 'unknown'))
                
                -- Chỉ gửi thông báo nếu người hotwire KHÔNG phải chủ xe
                if hotwirerCitizenid ~= ownerCitizenid then
                    -- Tìm owner player đang online
                    local Players = exports.qbx_core:GetQBPlayers()
                    for k, v in pairs(Players) do
                        if v.PlayerData.citizenid == ownerCitizenid then
                            local ownerSource = v.PlayerData.source
                            
                            print('[Vehiclekeys] Sending notification to owner (source: ' .. ownerSource .. ')')
                            
                            -- Gửi thông báo cho chủ xe
                            TriggerClientEvent('ox_lib:notify', ownerSource, {
                                title = '⚠️ CẢNH BÁO BẢO MẬT',
                                description = 'Xe của bạn (biển số: **' .. plate .. '**) đang có người đấu dây khởi động!',
                                type = 'error',
                                duration = 10000,
                                position = 'top'
                            })
                            
                            -- Set cooldown 5 phút cho biển số này
                            lockpickNotifyCooldown[plate] = currentTime
                            break
                        end
                    end
                else
                    print('[Vehiclekeys] Hotwirer is the owner - No notification sent')
                end
            else
                print('[Vehiclekeys] No owner found in database for plate: ' .. plate)
            end
        else
            print('[Vehiclekeys] Cooldown active for plate: ' .. plate)
        end
    end
end)



