local WebHook = {
    trom_nap_cong = '',
}
local logger = require '@qbx_core.modules.logger'
QBCore = exports["qb-core"]:GetCoreObject()
-- Initialize GlobalState on server start
GlobalState['Block_Spam_Nap_Cong'] = false
GlobalState['ActiveRobber'] = 0
GlobalState['RobStartTime'] = 0
GlobalState['delay_failed_cuop_nap_cong'] = 0

Time = 0
function formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    return string.format("%d phút %d giây", minutes, remainingSeconds)
end

-- Auto cleanup khi player disconnect
AddEventHandler('playerDropped', function(reason)
    if GlobalState['ActiveRobber'] == source then
        GlobalState['Block_Spam_Nap_Cong'] = false
        GlobalState['ActiveRobber'] = 0
        GlobalState['RobStartTime'] = 0
        print('[TromNapCong] Player '..source..' disconnect, đã reset GlobalState')
    end
end)

-- local function logEvent(Player, eventName, message, webhook)
--     logger.log({
--         source = eventName,
--         webhook = webhook,
--         event = eventName,
--         color = 'orange',
--         message = '\n- Tên nhân vật: `'..Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname..
--                   '`\n- citizenid: `'..Player.PlayerData.citizenid..
--                   '`\n- ID hiện tại: `'..Player.PlayerData.source.. 
--                   '`\n- `'..message..'`',
--     })
-- end


RegisterNetEvent('1307_TromNapCong:server:delay_failed', function()
    GlobalState['delay_failed_cuop_nap_cong'] = os.time() + 10
    GlobalState['Block_Spam_Nap_Cong'] = false
    GlobalState['ActiveRobber'] = 0
    GlobalState['RobStartTime'] = 0
end)

-- RegisterNetEvent('1307_TromNapCong:server:active_only_player', function()
--     -- GlobalState đã được set trong callback CheckCanRob (atomic)
--     -- Event này giữ lại để tương thích code cũ
-- end)

RegisterNetEvent('1307_TromNapCong:server:Reset_Only', function()
    GlobalState['Block_Spam_Nap_Cong'] = false
    GlobalState['ActiveRobber'] = 0
    GlobalState['RobStartTime'] = 0
end)

lib.callback.register('1307_TromNapCong:sv:CheckCanRob', function(source)
    -- Check cooldown global
    if os.time() <= Time then
        local timeLeft = Time - os.time()  
        local formattedTime = formatTime(timeLeft)
        exports.qbx_core:Notify(source, 'Vui lòng đợi thêm ' .. formattedTime, 'info')
        return false
    end
    
    -- Check timeout (auto reset nếu stuck)
    if GlobalState['Block_Spam_Nap_Cong'] and GlobalState['RobStartTime'] > 0 then
        if os.time() - GlobalState['RobStartTime'] > Config.TimeoutAuto then
            -- Timeout → Auto reset
            GlobalState['Block_Spam_Nap_Cong'] = false
            GlobalState['ActiveRobber'] = 0
            GlobalState['RobStartTime'] = 0
            print('[TromNapCong] Timeout auto reset')
        end
    end
    
    -- Check GlobalState (critical section)
    if GlobalState['Block_Spam_Nap_Cong'] then
        exports.qbx_core:Notify(source, 'Ai đó đang cướp', 'error')
        return false
    end
    
    -- ATOMIC: Set ngay để chặn người khác (chống race condition)
    GlobalState['Block_Spam_Nap_Cong'] = true
    GlobalState['ActiveRobber'] = source
    GlobalState['RobStartTime'] = os.time()
    
    return true
end)

lib.callback.register('1307_TromNapCong:sv:CheckCanRob_Failed', function(source)
    if GlobalState['delay_failed_cuop_nap_cong'] == nil then 
        GlobalState['delay_failed_cuop_nap_cong'] = 0 
    end
    
    -- Kiểm tra xem có phải người đang cướp không
    if GlobalState['ActiveRobber'] ~= source then
        exports.qbx_core:Notify(source, 'Ai đó đang cướp', 'error')
        return false
    end
    
    if os.time() > tonumber(GlobalState['delay_failed_cuop_nap_cong']) then
        return true
    else
        -- Reset GlobalState nếu fail cooldown
        GlobalState['Block_Spam_Nap_Cong'] = false
        GlobalState['ActiveRobber'] = 0
        GlobalState['RobStartTime'] = 0
        
        local timeLeft = tonumber(GlobalState['delay_failed_cuop_nap_cong']) - os.time()  
        local formattedTime = formatTime(timeLeft)
        exports.qbx_core:Notify(source, 'Vui lòng đợi thêm ' .. formattedTime, 'info')
        return false
    end
end)



RegisterServerEvent('1307_TromNapCong:server:1I1i01I1')
AddEventHandler('1307_TromNapCong:server:1I1i01I1', function(count)
    local src = source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    local Chance = math.random(1, 100) 
    local mathrandom = math.random(1, 2)
    local tile2 = math.random(1, 100)
    GlobalState['Block_Spam_Nap_Cong'] = false
    if exports.ox_inventory:RemoveItem(src, Config.Xa_Beng, 1) then
        if exports.ox_inventory:CanCarryItem(src, 'nap_cong', 1) then
        else
            exports.qbx_core:Notify(src, 'Bạn không đủ chỗ trong hành trang để chứa nắp cống', 'error')
            return
        end
        exports.ox_inventory:AddItem(src, 'nap_cong', 1)
        xPlayer.Functions.SetMetaData("stress", 30.0)
        -- Hệ thống phần thưởng đặc biệt
        if Config.Event and Config.Event.enabled then
            if math.random(1, 100) <= Config.Event.chance then
                local roll = math.random(1, 100)
                local cumulativeChance = 0
                for _, reward in ipairs(Config.Event.rewards) do
                    cumulativeChance = cumulativeChance + reward.chance
                    if roll <= cumulativeChance then
                        exports.ox_inventory:AddItem(src, reward.item, 1)
                        break
                    end
                end
            end
        end
        --logEvent(xPlayer, '1307_TromNapCong | CAY DONG HO', 'Nhận Được: '..exports.ox_inventory:Items('nap_cong').label..' 1x', WebHook.trom_nap_cong)
        exports.qbx_core:Notify(src, 'Bạn đã trộm được 1 '..exports.ox_inventory:Items('nap_cong').label..'', 'success', 2500)

        Time = os.time() + 60 * Config.CooldownThanhCong
    end
end)

exports.qbx_core:CreateUseableItem(Config.Xa_Beng, function(source, item)
    local src = source
    --print('1')
    TriggerClientEvent('1307_TromNapCong:client:Xa_Beng', src)
end)

-- Bán nap_cong
lib.callback.register('1307_TromNapCong:sv:BanNapCong', function(source)
    local src = source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    if not xPlayer then return false end

    local item = exports.ox_inventory:GetItem(src, 'nap_cong', nil, true)
    if not item or item < 1 then
        exports.qbx_core:Notify(src, 'Bạn không có nắp cống để bán', 'error')
        return false
    end

    -- Tính giá ngẫu nhiên dựa trên os.time
    math.randomseed(os.time())
    local price = math.random(Config.ViTriBan.minPrice, Config.ViTriBan.maxPrice)
    local soLuong = item
    local tongTien = price * soLuong

    if exports.ox_inventory:RemoveItem(src, 'nap_cong', soLuong) then
        exports.qbx_core:AddMoney(src, 'cash', tongTien, 'sold-nap-cong')
        exports.qbx_core:Notify(src, 'Bạn đã bán '..soLuong..' nắp cống với giá $'..price..'/cái (Tổng: $'..tongTien..')', 'success')
        --logEvent(xPlayer, '1307_TromNapCong | BÁN NẮP CỐNG', 'Bán '..soLuong..' nắp cống với giá $'..tongTien, WebHook.trom_nap_cong)
        return true
    end
    return false
end)

-- Admin command to reset GlobalState
RegisterCommand('resetnapcongglobal', function(source, args, rawCommand)
    if source == 0 or exports.qbx_core:HasPermission(source, 'admin') then
        GlobalState['Block_Spam_Nap_Cong'] = false
        GlobalState['ActiveRobber'] = 0
        GlobalState['RobStartTime'] = 0
        GlobalState['delay_failed_cuop_nap_cong'] = 0
        Time = 0
        if source ~= 0 then
            exports.qbx_core:Notify(source, 'GlobalState đã được reset', 'success')
        else
            print('GlobalState reset successfully')
        end
    else
        exports.qbx_core:Notify(source, 'Bạn không có quyền sử dụng lệnh này', 'error')
    end
end, false)