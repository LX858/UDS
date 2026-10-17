local function notify(source, title, description, type)
    if GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = title,
            description = description,
            type = type or 'inform'
        })
    end
end

-- Hàm hỗ trợ xóa item tương thích với ox_inventory, qbx_core và qb-core
local function removeItem(source, item, count)
    count = count or 1
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:RemoveItem(source, item, count)
    elseif GetResourceState('qbx_core') == 'started' and exports.qbx_core.RemoveItem then
        return exports.qbx_core:RemoveItem(source, item, count)
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore and QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.Functions.RemoveItem(item, count)
        end
    end
    return false
end

exports.qbx_core:CreateUseableItem('dinhsat', function(source)
    TriggerClientEvent('xn_dinhsat:client:useDinhsat', source)
end)

RegisterNetEvent('xn_dinhsat:server:burstTires', function(netId, tireIndex)
    local source = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        notify(source, 'Dinhsat', 'Khong tim thay xe.', 'error')
        return
    end

    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)
    local vehicleCoords = GetEntityCoords(vehicle)
    if #(playerCoords - vehicleCoords) > 8.0 then
        notify(source, 'Dinhsat', 'Xe qua xa.', 'error')
        return
    end

    TriggerClientEvent('xn_dinhsat:client:burstTireSync', -1, netId, tireIndex)

    -- Tính tỷ lệ: 40% làm mất item, 60% giữ lại item
    local chance = math.random(1, 100)
    if chance <= 40 then
        removeItem(source, 'dinhsat', 1)
        notify(source, 'Dinhsat', 'Đã tróc lốp thành công! (Đinh sắt đã bị hỏng/mất)', 'error')
    else
        notify(source, 'Dinhsat', 'Đã tróc thành công lốp xe! (Đinh sắt còn nguyên)', 'success')
    end
end)
