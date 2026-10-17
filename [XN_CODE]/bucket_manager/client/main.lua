local QBCore = exports['qb-core']:GetCoreObject()

-- Event để nhận thông báo từ server và hiển thị bằng ox_lib
RegisterNetEvent('bucket_manager:client:showNotification', function(data)
    lib.notify(data)
end)

-- Event để nhận thông tin bucket từ server
RegisterNetEvent('bucket_manager:client:receiveBucket', function(bucket)
    lib.notify({
        title = 'Bucket Manager',
        description = 'Bucket hiện tại của bạn: ' .. bucket,
        type = 'inform',
        duration = 5000
    })
end)

-- Event khi bucket được reset
RegisterNetEvent('bucket_manager:client:bucketReset', function(oldBucket, newBucket)
    lib.notify({
        title = 'Bucket Manager',
        description = 'Đã reset bucket từ ' .. oldBucket .. ' về ' .. newBucket,
        type = 'success',
        duration = 5000
    })
end)

-- Function để lấy bucket hiện tại (có thể sử dụng từ client)
function GetCurrentBucket()
    TriggerServerEvent('bucket_manager:server:getBucket')
end

-- Function để reset bucket (có thể sử dụng từ client)
function ResetBucket()
    TriggerServerEvent('bucket_manager:server:resetBucket')
end

-- Export functions để các resource khác có thể sử dụng
exports('GetCurrentBucket', GetCurrentBucket)
exports('ResetBucket', ResetBucket)
