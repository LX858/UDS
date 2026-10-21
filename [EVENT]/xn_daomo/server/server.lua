local config = lib.require 'config'

lib.callback.register('lonf_fruitpick:server:giveItem', function(source)
    local src = source
    local rewardConfig = config.tokenReward or {
        item = 'event_token',
        chance = 50,
        amount = 1,
        emptyNotify = true
    }

    local roll = math.random(1, 100)
    local chance = rewardConfig.chance or 50

    if roll <= chance then
        local item = rewardConfig.item or 'event_token'
        local amount = 1

        if type(rewardConfig.amount) == 'table' then
            local min = rewardConfig.amount.min or 1
            local max = rewardConfig.amount.max or min
            amount = math.random(min, max)
        elseif type(rewardConfig.amount) == 'number' then
            amount = rewardConfig.amount
        end

        local success = exports.ox_inventory:AddItem(src, item, amount)
        if not success and rewardConfig.emptyNotify then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Đào mộ',
                description = 'Túi đồ của bạn đã đầy!',
                type = 'error'
            })
        end
        return success
    else
        if rewardConfig.emptyNotify then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Đào mộ',
                description = 'Bạn không tìm thấy gì trong ngôi mộ này!',
                type = 'inform'
            })
        end
        return false
    end
end)

lib.callback.register('lonf:server:getNumCops', function(source)
    return exports.qbx_core:GetDutyCountType('leo')
end)

RegisterNetEvent('lonf:sell', function (item, price, count)
    if not config.enableShop then return end
    local src = source
    if not item or not price or not count then return end

    local countCheck = exports.ox_inventory:GetItemCount(src, item)
    if countCheck >= count then  

        exports.ox_inventory:RemoveItem(src, item, count)
        
        local profit = price * count
        exports.ox_inventory:AddItem(src, 'money', profit)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { 'Sistema', 'Você não tem itens suficientes!' } })
    end
end)