local QBCore = exports['qb-core']:GetCoreObject()

-- Command để kiểm tra bucket hiện tại
lib.addCommand('bucket', {
    help = 'Kiểm tra bucket hiện tại của bạn',
    restricted = false
}, function(source, args, raw)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        return
    end
    
    -- Lấy bucket hiện tại của player
    local currentBucket = GetPlayerRoutingBucket(src)
    
    -- Gửi thông báo cho player
    TriggerClientEvent('bucket_manager:client:showNotification', src, {
        title = 'Bucket Manager',
        description = Config.Messages.BucketCheck:format(currentBucket),
        type = 'inform',
        duration = Config.Notifications.Duration
    })
    
    -- Log cho console
    if Config.Logging.EnableConsoleLog and Config.Logging.LogBucketCheck then
        print(('Player %s [%s] kiểm tra bucket: %s'):format(GetPlayerName(src), src, currentBucket))
    end
end)

-- Command để reset bucket về 0
lib.addCommand('resetbucket', {
    help = 'Reset bucket của bạn về 0',
    restricted = false
}, function(source, args, raw)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        return
    end
    
    -- Lấy bucket hiện tại trước khi reset
    local oldBucket = GetPlayerRoutingBucket(src)
    
    -- Reset bucket về 0
    SetPlayerRoutingBucket(src, Config.Bucket.DefaultBucket)
    
    -- Gửi thông báo thành công
    TriggerClientEvent('bucket_manager:client:showNotification', src, {
        title = 'Bucket Manager',
        description = Config.Messages.BucketReset:format(oldBucket, Config.Bucket.DefaultBucket),
        type = 'success',
        duration = Config.Notifications.Duration
    })
    
    -- Log cho console
    if Config.Logging.EnableConsoleLog and Config.Logging.LogBucketReset then
        print(('Player %s [%s] đã reset bucket từ %s về %s'):format(GetPlayerName(src), src, oldBucket, Config.Bucket.DefaultBucket))
    end
end)

-- Command admin để set bucket cho player khác (bonus)
lib.addCommand('setbucket', {
    help = 'Set bucket cho player khác (Admin only)',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'ID của player cần set bucket',
        },
        {
            name = 'bucket',
            type = 'number',
            help = 'Bucket ID (0-63)',
        }
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        return
    end
    
    -- Kiểm tra quyền admin
    if not QBCore.Functions.HasPermission(src, Config.Permissions.AdminCommand) then
        TriggerClientEvent('bucket_manager:client:showNotification', src, {
            title = 'Bucket Manager',
            description = Config.Messages.NoPermission,
            type = 'error',
            duration = Config.Notifications.Duration
        })
        return
    end
    
    local targetId = args.target
    local bucketId = args.bucket
    
    if not targetId or not bucketId then
        TriggerClientEvent('bucket_manager:client:showNotification', src, {
            title = 'Bucket Manager',
            description = Config.Messages.InvalidUsage,
            type = 'error',
            duration = Config.Notifications.Duration
        })
        return
    end
    
    -- Kiểm tra bucket ID hợp lệ
    if bucketId < 0 or bucketId > Config.Bucket.MaxBucket then
        TriggerClientEvent('bucket_manager:client:showNotification', src, {
            title = 'Bucket Manager',
            description = Config.Messages.InvalidBucket:format(Config.Bucket.MaxBucket),
            type = 'error',
            duration = Config.Notifications.Duration
        })
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('bucket_manager:client:showNotification', src, {
            title = 'Bucket Manager',
            description = Config.Messages.PlayerNotFound:format(targetId),
            type = 'error',
            duration = Config.Notifications.Duration
        })
        return
    end
    
    -- Set bucket cho target player
    SetPlayerRoutingBucket(tostring(targetId), bucketId)
    
    -- Thông báo cho admin
    TriggerClientEvent('bucket_manager:client:showNotification', src, {
        title = 'Bucket Manager',
        description = Config.Messages.BucketSet:format(bucketId, GetPlayerName(targetId)),
        type = 'success',
        duration = Config.Notifications.Duration
    })
    
    -- Thông báo cho target player
    TriggerClientEvent('bucket_manager:client:showNotification', targetId, {
        title = 'Bucket Manager',
        description = Config.Messages.BucketSetReceived:format(bucketId),
        type = 'inform',
        duration = Config.Notifications.Duration
    })
    
    -- Log cho console
    if Config.Logging.EnableConsoleLog and Config.Logging.LogBucketSet then
        print(('Admin %s [%s] đã set bucket %s cho player %s [%s]'):format(
            GetPlayerName(src), src, bucketId, GetPlayerName(targetId), targetId))
    end
end)

-- Event để xử lý bucket từ client
RegisterNetEvent('bucket_manager:server:getBucket', function()
    local src = source
    local currentBucket = GetPlayerRoutingBucket(src)
    
    TriggerClientEvent('bucket_manager:client:receiveBucket', src, currentBucket)
end)

RegisterNetEvent('bucket_manager:server:resetBucket', function()
    local src = source
    local oldBucket = GetPlayerRoutingBucket(src)
    
    SetPlayerRoutingBucket(src, Config.Bucket.DefaultBucket)
    
    TriggerClientEvent('bucket_manager:client:bucketReset', src, oldBucket, Config.Bucket.DefaultBucket)
end)
