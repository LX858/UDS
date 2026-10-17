local QBCore = exports['qb-core']:GetCoreObject()

-- Command test cửa hàng (chỉ để debug)
-- RegisterCommand('testshop', function()
--     if Config.Debug then
--         print("=== TESTING SHOP CONFIG ===")
        
--         if FarmShop then
--             print("FarmShop exists")
--             if FarmShop.Items then
--                 print("FarmShop.Items exists with", #FarmShop.Items, "items")
--                 for i, item in ipairs(FarmShop.Items) do
--                     print(string.format("Item %d: %s (price: %d)", i, item.label or "NO_LABEL", item.price or 0))
--                 end
--             else
--                 print("ERROR: FarmShop.Items is nil")
--             end
--         else
--             print("ERROR: FarmShop is nil")
--         end
        
--         print("=== END TEST ===")
--     end
    
--     -- Force reset trạng thái trước khi mở
--     isShopOpen = false
--     TriggerEvent('xn_farming:openShop')
-- end, false)

-- Command để reset shop state (để debug)
-- RegisterCommand('resetshop', function()
--     isShopOpen = false
--     lib.hideContext()
--     QBCore.Functions.Notify('Shop state đã được reset', 'success')
--     if Config.Debug then
--         print("Shop state reset to false")
--     end
-- end, false)

-- -- Command để kiểm tra trạng thái hiện tại
-- RegisterCommand('shopstate', function()
--     local stateText = isShopOpen and "OPEN" or "CLOSED"
--     QBCore.Functions.Notify('Shop state: ' .. stateText, 'primary')
--     if Config.Debug then
--         print("Current shop state - isShopOpen:", isShopOpen)
--     end
-- end, false)
