-- ==================== VEHICLE IMPOUND CLIENT ====================
-- Client-side NUI callbacks cho quản lý xe bị tạm giam

-- Lấy danh sách xe đang giam
RegisterNUICallback('getActiveImpounds', function(data, cb)
    local result = lib.callback.await('mini-mdt:getActiveImpounds', false)
    cb(result)
end)

-- Tìm kiếm theo PID chủ xe
RegisterNUICallback('searchImpoundByOwnerPID', function(data, cb)
    local result = lib.callback.await('mini-mdt:searchImpoundByOwnerPID', false, data)
    cb(result)
end)

-- Tìm kiếm theo PID cảnh sát
RegisterNUICallback('searchImpoundByOfficerPID', function(data, cb)
    local result = lib.callback.await('mini-mdt:searchImpoundByOfficerPID', false, data)
    cb(result)
end)
