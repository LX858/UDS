local QBCore = exports['qb-core']:GetCoreObject()

-- Biến để theo dõi trạng thái menu
local isShopOpen = false

-- Không spawn NPC riêng nữa vì sử dụng chung với farm_rental
-- Event mở cửa hàng
RegisterNetEvent('xn_farming:openShop')
AddEventHandler('xn_farming:openShop', function()
    if isShopOpen then 
        if Config.Debug then
            print("Shop menu is already open, ignoring request")
        end
        return 
    end
    
    -- Kiểm tra config tồn tại
    if not FarmShop or not FarmShop.Items then
        QBCore.Functions.Notify('Lỗi: Không tìm thấy cấu hình cửa hàng', 'error')
        if Config.Debug then
            print("Error: FarmShop config not found")
        end
        return
    end
    
    isShopOpen = true
    
    if Config.Debug then
        print("Opening shop menu with", #FarmShop.Items, "items")
    end
    
    local options = {}
    
    -- Tạo options cho từng item
    for i, itemData in ipairs(FarmShop.Items) do
        if Config.Debug then
            print("Adding item:", itemData.label, "price:", itemData.price)
        end
        
        table.insert(options, {
            title = itemData.label,
            description = string.format("%s - Giá: $%d", itemData.description, itemData.price),
            icon = 'fas fa-shopping-basket',
            onSelect = function()
                -- Hiển thị input trực tiếp để nhập số lượng
                local input = lib.inputDialog(string.format('Mua %s', itemData.label), {
                    {
                        type = 'number',
                        label = 'Số lượng muốn mua',
                        description = string.format('Giá: $%d/cái', itemData.price),
                        required = true,
                        min = 1,
                        max = 100,
                        default = 1
                    }
                })
                
                if input and input[1] then
                    local quantity = tonumber(input[1])
                    if quantity and quantity > 0 and quantity <= 100 then
                        BuyItem(itemData.item, quantity, itemData.price, itemData.label)
                    else
                        QBCore.Functions.Notify('Số lượng không hợp lệ (1-100)!', 'error')
                        -- Reset và mở lại menu khi số lượng không hợp lệ
                        isShopOpen = false
                        Wait(100)
                        TriggerEvent('xn_farming:openShop')
                    end
                else
                    -- Player hủy input dialog - reset trạng thái và mở lại menu
                    isShopOpen = false
                    Wait(100)
                    TriggerEvent('xn_farming:openShop')
                end
            end
        })
    end
    
    -- Thêm option đóng
    table.insert(options, {
        title = 'Đóng Cửa Hàng',
        description = 'Thoát khỏi cửa hàng',
        icon = 'fas fa-times',
        onSelect = function()
            CloseShop()
        end
    })
    
    -- Hiển thị menu
    lib.registerContext({
        id = 'farm_shop_main',
        title = 'Cửa Hàng Nông Nghiệp',
        options = options,
        onExit = function()
            CloseShop()
        end
    })
    lib.showContext('farm_shop_main')
end)

-- Function đóng cửa hàng
function CloseShop()
    isShopOpen = false
    lib.hideContext()
    if Config.Debug then
        print("Shop closed")
    end
end

-- Function mua item
function BuyItem(item, quantity, unitPrice, itemLabel)
    local totalPrice = unitPrice * quantity
    
    -- Hiển thị progress bar
    if lib.progressBar({
        duration = 2000,
        label = string.format('Đang mua %dx %s...', quantity, itemLabel),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a',
            flag = 1,
        }
    }) then
        -- Gọi server để xử lý mua hàng
        QBCore.Functions.TriggerCallback('xn_farming:buyItem', function(success, message)
            if success then
                QBCore.Functions.Notify(message, 'success')
            else
                QBCore.Functions.Notify(message, 'error')
            end
            
            -- Reset trạng thái shop trước khi mở lại menu
            isShopOpen = false
            Wait(500)
            TriggerEvent('xn_farming:openShop')
        end, item, quantity, totalPrice)
    else
        -- Player hủy progress bar - reset trạng thái và mở lại menu
        QBCore.Functions.Notify('Đã hủy giao dịch', 'error')
        isShopOpen = false
        Wait(100)
        TriggerEvent('xn_farming:openShop')
    end
end

-- Event để đóng menu khi player rời xa hoặc disconnect
RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    CloseShop()
end)

-- Cleanup khi resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    CloseShop()
end)
