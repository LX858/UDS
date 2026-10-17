-- -- Hàm xóa tất cả props đang cầm
-- local function ClearCarriedProps()
--     local playerPed = PlayerPedId()
    
--     -- Xóa prop trên tay phải
--     if DoesEntityExist(playerPed) then
--         -- Detach tất cả objects
--         DetachEntity(playerPed, true, false)
        
--         -- Xóa tất cả props đang cầm
--         ClearPedTasksImmediately(playerPed)
        
--         -- Xóa các objects gần người chơi
--         local coords = GetEntityCoords(playerPed)
--         local objects = GetGamePool('CObject')
        
--         for i = 1, #objects do
--             local obj = objects[i]
--             if DoesEntityExist(obj) then
--                 local objCoords = GetEntityCoords(obj)
--                 local distance = #(coords - objCoords)
                
--                 -- Nếu object ở gần người chơi (trong vòng 2m)
--                 if distance < 2.0 then
--                     -- Kiểm tra xem object có attached vào người chơi không
--                     if IsEntityAttachedToEntity(obj, playerPed) then
--                         DeleteEntity(obj)
--                     end
--                 end
--             end
--         end
        
--         lib.notify({
--             title = 'Prop Fix',
--             description = 'Đã xóa tất cả props trên tay!',
--             type = 'success'
--         })
--     end
-- end

-- -- Lệnh /propfix
-- RegisterCommand('propfix', function()
--     ClearCarriedProps()
-- end, false)

-- -- Ngăn chặn xe bay khi mang prop lên xe (TẮT TẠM)
-- --[[
-- lib.onCache('vehicle', function(vehicle)
--     if vehicle then
--         local playerPed = PlayerPedId()
--         local coords = GetEntityCoords(playerPed)
--         local objects = GetGamePool('CObject')
--         local hasDeletedProp = false
        
--         for i = 1, #objects do
--             local obj = objects[i]
--             if DoesEntityExist(obj) and IsEntityAttachedToEntity(obj, playerPed) then
--                 -- Tự động xóa prop khi lên xe
--                 DeleteEntity(obj)
--                 ClearPedTasksImmediately(playerPed)
--                 hasDeletedProp = true
--             end
--         end
        
--         if hasDeletedProp then
--             lib.notify({
--                 title = 'Cảnh báo',
--                 description = 'Prop đã được tự động loại bỏ khi lên xe!',
--                 type = 'warning'
--             })
            
--             -- Reset vật lý xe để tránh bay
--             if DoesEntityExist(vehicle) then
--                 SetVehicleOnGroundProperly(vehicle)
--             end
--         end
--     end
-- end)
-- --]]