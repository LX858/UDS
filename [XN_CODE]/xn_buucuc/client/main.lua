local QBX = exports.qbx_core

exports.ox_target:addSphereZone({
    coords = Config.StorageLocation,
    radius = Config.Target.distance,
    options = {
        {
            name = 'personal_storage',
            icon = Config.Target.icon,
            label = Config.Target.label,
            onSelect = function()
                openPersonalStorage()
            end,
            canInteract = function()
                -- Chỉ cho phép tương tác khi player ở gần
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - Config.StorageLocation)
                return distance <= Config.Target.distance
            end
        },
        {
            name = 'clear_storage',
            icon = 'fas fa-trash',
            label = 'Xóa kho đồ',
            onSelect = function()
                clearPersonalStorage()
            end,
            canInteract = function()
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - Config.StorageLocation)
                return distance <= Config.Target.distance
            end
        }
    }
})

RegisterNetEvent('xn_buucuc:openbuucuc', function()
    Wait(500)
    openPersonalStorage()
end)
    
-- Hàm mở kho cá nhân
function openPersonalStorage()
    local playerData = QBX:GetPlayerData()
    
    if not playerData or not playerData.citizenid then
        lib.notify({
            title = 'Lỗi',
            description = 'Không thể xác định thông tin người chơi',
            type = 'error'
        })
        return
    end
    
    -- Tạo stash ID theo format: buucuc_citizenid
    local stashId = 'buucuc_' .. playerData.citizenid
    
    if Config.Debug then
        print('[XN_BUUCUC] Opening storage for player: ' .. playerData.citizenid)
        print('[XN_BUUCUC] Stash ID: ' .. stashId)
    end
    
    -- Gửi event tới server để đăng ký stash nếu chưa có
    TriggerServerEvent('xn_buucuc:server:registerStash', stashId)
    
    -- Đợi một chút rồi mở kho
    Wait(100)
    
    -- Mở kho bằng ox_inventory
    exports.ox_inventory:openInventory('stash', stashId)
end

-- Hàm xóa kho cá nhân
function clearPersonalStorage()
    local playerData = QBX:GetPlayerData()
    
    if not playerData or not playerData.citizenid then
        lib.notify({
            title = 'Lỗi',
            description = 'Không thể xác định thông tin người chơi',
            type = 'error'
        })
        return
    end
    
    -- Hiển thị dialog xác nhận
    local alert = lib.alertDialog({
        header = 'Xóa kho đồ',
        content = 'Bạn có chắc chắn muốn xóa toàn bộ đồ trong kho cá nhân?\n\n⚠️ Hành động này không thể hoàn tác!',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Đồng ý',
            cancel = 'Hủy bỏ'
        }
    })
    
    if alert == 'confirm' then
        -- Gửi event đến server để xóa kho
        TriggerServerEvent('xn_buucuc:server:clearStorage')
    else
        lib.notify({
            title = 'Kho cá nhân',
            description = 'Đã hủy xóa kho',
            type = 'info'
        })
    end
end

-- Event để nhận thông báo từ server
RegisterNetEvent('xn_buucuc:client:notify', function(data)
    lib.notify(data)
end)

-- Debug command (chỉ hoạt động khi debug = true)
if Config.Debug then
    RegisterCommand('buucuc_debug', function()
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = #(playerCoords - Config.StorageLocation)
        
        print('Player coords: ' .. tostring(playerCoords))
        print('Storage coords: ' .. tostring(Config.StorageLocation))
        print('Distance: ' .. tostring(distance))
        
        local playerData = QBX:GetPlayerData()
        if playerData and playerData.citizenid then
            print('Citizen ID: ' .. playerData.citizenid)
            print('Stash ID would be: buucuc_' .. playerData.citizenid)
        end
    end, false)
end