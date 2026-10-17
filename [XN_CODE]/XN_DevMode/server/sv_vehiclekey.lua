-- Server side cho event đánh chìa khóa xe

-- Config các job được phép sử dụng lệnh
local allowedJobs = {
    'police',
    -- 'ambulance',  -- Bỏ comment nếu muốn EMS cũng dùng được
    -- 'mechanic',   -- Bỏ comment nếu muốn thợ máy cũng dùng được
}

-- Function kiểm tra job
local function IsJobAllowed(jobName)
    for _, job in ipairs(allowedJobs) do
        if job == jobName then
            return true
        end
    end
    return false
end

-- Event lấy danh sách xe của người chơi và hiển thị menu
RegisterNetEvent('vehiclekey:requestVehicleList', function()
    local source = source
    
    -- Kiểm tra player có tồn tại không
    local player = exports.qbx_core:GetPlayer(source)
    if not player then
        TriggerClientEvent('vehiclekey:notify', source, 'Không thể xác định thông tin người chơi!', 'error')
        return
    end
    
    -- -- Kiểm tra job có được phép sử dụng không
    -- if not IsJobAllowed(player.PlayerData.job.name) then
    --     TriggerClientEvent('vehiclekey:notify', source, 'Chỉ có công an mới được sử dụng chức năng này!', 'error')
    --     return
    -- end
    
    -- Lấy danh sách xe từ database
    local citizenid = player.PlayerData.citizenid
    local vehicles = exports.oxmysql:executeSync('SELECT plate, vehicle FROM player_vehicles WHERE citizenid = ?', {citizenid})
    
    if not vehicles or #vehicles == 0 then
        TriggerClientEvent('vehiclekey:notify', source, 'Bạn không có xe nào trong garage!', 'inform')
        return
    end
    
    -- Gửi danh sách xe về client để hiển thị menu
    TriggerClientEvent('vehiclekey:openMenu', source, vehicles)
end)

-- Event xử lý việc tự đánh chìa khóa cho mình
RegisterNetEvent('vehiclekey:giveKeyToSelf', function(plate)
    local source = source
    
    -- Kiểm tra player có tồn tại không
    local player = exports.qbx_core:GetPlayer(source)
    if not player then
        TriggerClientEvent('vehiclekey:notify', source, 'Không thể xác định thông tin người chơi!', 'error')
        return
    end
    
    -- -- Kiểm tra job có được phép sử dụng không
    -- if not IsJobAllowed(player.PlayerData.job.name) then
    --     TriggerClientEvent('vehiclekey:notify', source, 'Chỉ có công an mới được sử dụng lệnh này!', 'error')
    --     return
    -- end
    
    -- Kiểm tra số tiền của người chơi
    local keyPrice = 2000
    if player.PlayerData.money.cash < keyPrice and player.PlayerData.money.bank < keyPrice then
        TriggerClientEvent('vehiclekey:notify', source, 'Bạn không đủ tiền để đánh chìa khóa! Cần $' .. keyPrice, 'error')
        return
    end
    
    -- Trừ tiền (ưu tiên trừ tiền mặt trước, nếu không đủ thì trừ bank)
    if player.PlayerData.money.cash >= keyPrice then
        player.Functions.RemoveMoney('cash', keyPrice, 'vehiclekey-crafting')
    else
        player.Functions.RemoveMoney('bank', keyPrice, 'vehiclekey-crafting')
    end
    
    -- Đánh chìa khóa cho chính người chơi
    exports['Renewed-Vehiclekeys']:addKey(source, plate)
    
    -- Thông báo cho người chơi
    TriggerClientEvent('vehiclekey:notify', source, 'Đã đánh chìa khóa xe biển số ' .. plate .. ' thành công! Phí: $' .. keyPrice, 'success')
    
    -- Log để admin theo dõi (optional)
    print(('[VehicleKey] Police %s đã tự đánh chìa khóa xe %s'):format(
        GetPlayerName(source),
        plate
    ))
end)

-- Event xử lý việc đánh chìa khóa cho người khác (giữ lại nếu cần)
RegisterNetEvent('vehiclekey:giveKey', function(targetId, plate)
    local source = source
    
    -- Kiểm tra target player có tồn tại không
    local targetPlayer = exports.qbx_core:GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('vehiclekey:notify', source, 'Người chơi không tồn tại hoặc không online!', 'error')
        return
    end
    
    -- Kiểm tra khoảng cách giữa 2 người chơi (optional - có thể bỏ nếu không cần)
    local sourceCoords = GetEntityCoords(GetPlayerPed(source))
    local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
    local distance = #(sourceCoords - targetCoords)
    
    if distance > 10.0 then -- 10 mét
        TriggerClientEvent('vehiclekey:notify', source, 'Người chơi quá xa! Cần ở gần hơn.', 'error')
        return
    end
    
    -- Đánh chìa khóa cho người chơi target
    exports['Renewed-Vehiclekeys']:addKey(targetId, plate)
    
    -- Thông báo cho cả hai người chơi
    TriggerClientEvent('vehiclekey:notify', source, 'Đã đánh chìa khóa xe biển số ' .. plate .. ' cho ' .. targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname, 'success')
    TriggerClientEvent('vehiclekey:notify', targetId, 'Bạn đã nhận được chìa khóa xe biển số ' .. plate, 'success')
    
    -- Log để admin theo dõi (optional)
    print(('[VehicleKey] %s đã đánh chìa khóa xe %s cho %s'):format(
        GetPlayerName(source),
        plate,
        GetPlayerName(targetId)
    ))
end)
