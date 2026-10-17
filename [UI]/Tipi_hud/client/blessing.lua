-- Blessing: chỉ lưu giá trị 0-100 và gửi lên NUI qua getBlessing().
-- Nguồn dữ liệu do bạn tự xử lý — cập nhật bằng event hoặc export bên dưới.

local blessing = 0

function getBlessing()
    return blessing
end

local function setBlessingValue(value)
    blessing = math.max(0, math.min(100, tonumber(value) or 0))
end

RegisterNetEvent('tipi-hud:setBlessing', function(value)
    setBlessingValue(value)
end)

exports('SetBlessing', setBlessingValue)
exports('GetBlessing', function()
    return blessing
end)
