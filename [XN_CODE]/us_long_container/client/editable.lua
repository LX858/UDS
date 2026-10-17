-- Chỉnh hàm này nếu muốn giới hạn job, gang, item hoặc điều kiện phía client.
-- Lưu ý: quyền quan trọng vẫn phải kiểm tra lại trong server/editable.lua.
function CanUseLongContainer(containerId, desiredState)
    return true
end
