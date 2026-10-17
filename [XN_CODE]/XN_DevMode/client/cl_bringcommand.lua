-- Client event xử lý teleport cho command bring
RegisterNetEvent('XN_DevMode:client:TeleportToCoords', function(coords)
    if not coords then return end
    
    local ped = PlayerPedId()
    
    -- Đặt player vào trạng thái không va chạm
    SetEntityCollision(ped, false, false)
    
    -- Teleport
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    
    -- Set heading nếu có
    if coords.w then
        SetEntityHeading(ped, coords.w)
    end
    
    -- Đợi một chút để đảm bảo đã tele xong
    Wait(500)
    
    -- Bật lại va chạm
    SetEntityCollision(ped, true, true)
    
    -- Freeze một chút để tránh rơi
    FreezeEntityPosition(ped, true)
    Wait(100)
    FreezeEntityPosition(ped, false)
end)
