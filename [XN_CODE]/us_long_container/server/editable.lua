-- Chỉnh hàm này nếu muốn giới hạn job, gang, item hoặc quyền phía server.
-- source: server ID người chơi.
-- containerId: ID trong Config.Containers.
-- desiredState: true = mở, false = đóng.
function CanPlayerUseLongContainer(source, containerId, desiredState)
    return true
end
