RegisterNetEvent('suaxenghanh:purchaseTicket', function(job)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    -- Kiểm tra job của player
    if Player.PlayerData.job.name ~= job then
        TriggerClientEvent('suaxenghanh:notify', src, 'error', 'Lỗi', 'Bạn không thuộc nghành này!')
        return
    end
    
    local playerCash = Player.Functions.GetMoney('cash')
    
    -- Kiểm tra tiền mặt của player
    if playerCash < 100 then
        TriggerClientEvent('suaxenghanh:notify', src, 'error', 'Không đủ tiền', 'Bạn cần 100$ tiền mặt để mua phiếu!')
        return
    end
    
    -- -- Lấy số dư quỹ nghành
    -- local accountName = job
    -- local accountMoney = exports['Renewed-Banking']:getAccountMoney(accountName)

    -- if not accountMoney or accountMoney < 900 then
    --     TriggerClientEvent('suaxenghanh:notify', src, 'error', 'Quỹ không đủ', 'Quỹ nghành không đủ 900$ để mua phiếu!')
    --     return
    -- end
    
    -- -- Trừ tiền quỹ nghành
    -- local removeJobMoney = exports['Renewed-Banking']:removeAccountMoney(accountName, 900)
    
    -- if not removeJobMoney then
    --     TriggerClientEvent('suaxenghanh:notify', src, 'error', 'Lỗi', 'Không thể trừ tiền từ quỹ nghành!')
    --     return
    -- end
    
    -- Trừ tiền mặt của player
    local removedCash = Player.Functions.RemoveMoney('cash', 100, 'Mua phiếu sửa xe')
    
    if not removedCash then
        -- Hoàn tiền quỹ nghành nếu trừ tiền player thất bại
        -- exports['Renewed-Banking']:addAccountMoney(accountName, 900)
        TriggerClientEvent('suaxenghanh:notify', src, 'error', 'Lỗi', 'Không thể trừ tiền mặt!')
        return
    end
    
    -- Thêm item vào inventory
    local addedItem = exports.ox_inventory:AddItem(src, 'vesuaxenghanh', 1)
    
    if addedItem then
        TriggerClientEvent('suaxenghanh:notify', src, 'success', 'Thành công', 'Đã mua phiếu sửa xe! (-100$ tiền mặt, -900$ quỹ nghành)')
    else
        -- Hoàn tiền nếu thêm item thất bại
        Player.Functions.AddMoney('cash', 100, 'Hoàn tiền mua phiếu sửa xe')
        -- exports['Renewed-Banking']:addAccountMoney(accountName, 900)
        TriggerClientEvent('suaxenghanh:notify', src, 'error', 'Lỗi', 'Không thể thêm phiếu vào túi đồ!')
    end
end)
