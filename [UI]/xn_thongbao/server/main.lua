local QBCore = exports['qb-core']:GetCoreObject()

-- Event để gửi thông báo đến tất cả người chơi
RegisterNetEvent('xn_thongbao:server:sendToAll', function(data)
    TriggerClientEvent('xn_thongbao:client:showAnnouncement', -1, data)
end)

-- Event để gửi thông báo đến người chơi cụ thể
RegisterNetEvent('xn_thongbao:server:sendToPlayer', function(playerId, data)
    TriggerClientEvent('xn_thongbao:client:showAnnouncement', playerId, data)
end)

QBCore.Commands.Add('thongbao', 'Gửi thông báo đến tất cả người chơi (Admin/Mod)', {}, false, function(source, args, rawCommand)
    TriggerClientEvent('xn_thongbao:client:openDialog', source)
end, 'mod')

-- Command test thông báo thường
QBCore.Commands.Add('testthongbao', 'Test thông báo thường (Admin)', {
    {name = 'message', help = 'Nội dung thông báo (tuỳ chọn)'}
}, false, function(source, args)
    local message = table.concat(args, ' ')
    if message == '' then message = 'Đây là thông báo test từ Admin!' end
    TriggerClientEvent('xn_thongbao:client:showAnnouncement', -1, {
        title = 'ADMIN',
        message = message,
        duration = 10000,
        type = 'info'
    })
    TriggerClientEvent('QBCore:Notify', source, 'Đã gửi test thông báo thường.', 'success')
end, 'admin')

-- Command test thông báo đặc biệt (đỏ + pháo hoa)
QBCore.Commands.Add('testspecial', 'Test thông báo đặc biệt đỏ + pháo hoa (Admin)', {
    {name = 'message', help = 'Nội dung thông báo (tuỳ chọn)'}
}, false, function(source, args)
    local message = table.concat(args, ' ')
    if message == '' then message = 'Chúc mừng bạn đã trúng giải thưởng đặc biệt!' end
    TriggerClientEvent('xn_thongbao:client:showAnnouncement', -1, {
        title = 'THÔNG BÁO ĐẶC BIỆT',
        message = message,
        duration = 12000,
        type = 'special'
    })
    TriggerClientEvent('QBCore:Notify', source, 'Đã gửi test thông báo đặc biệt.', 'success')
end, 'admin')

-- Event nhận dữ liệu từ dialog và gửi thông báo
RegisterNetEvent('xn_thongbao:server:sendFromDialog', function(message)
    local src = source
    if message and message ~= '' then
        TriggerClientEvent('xn_thongbao:client:showAnnouncement', -1, {
            title = 'ADMIN',
            message = message,
            duration = 30000,
            type = 'info'
        })
        TriggerClientEvent('QBCore:Notify', src, 'Đã gửi thông báo: ' .. message, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Vui lòng nhập nội dung thông báo!', 'error')
    end
end)

-- Command admin để gửi thông báo với logo tùy chỉnh
QBCore.Commands.Add('announcelogo', 'Gửi thông báo với logo tùy chỉnh (Admin Only)', {
    {name = 'logo_url', help = 'URL của logo'},
    {name = 'title', help = 'Tiêu đề thông báo'},
    {name = 'message', help = 'Nội dung thông báo'}
}, true, function(source, args)
    local logoUrl = args[1]
    local title = args[2] or 'ADMIN'
    local message = table.concat(args, ' ', 3)
    
    if logoUrl and message and message ~= '' then
        TriggerClientEvent('xn_thongbao:client:showAnnouncement', -1, {
            title = title,
            message = message,
            duration = 10000,
            type = 'info',
            logo = logoUrl or 'https://github.com/xuannguyen995/prime_item/blob/main/logo_png.png?raw=true'
        })
        TriggerClientEvent('QBCore:Notify', source, 'Đã gửi thông báo với logo: ' .. message, 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'Sử dụng: /announcelogo [logo_url] [title] [message]', 'error')
    end
end, 'admin')

-- Command welcome cho người chơi mới
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    Wait(5000) -- Đợi 5 giây để người chơi load xong
    TriggerClientEvent('xn_thongbao:client:showAnnouncement', src, {
        title = 'XIN CHÀO MỪNG MỌI NGƯỜI ĐẾN VỚI ALL STARS VIỆT NAM',
        message = 'Chúc bạn có những trải nghiệm tuyệt vời tại server của chúng tôi!',
        duration = 15000,
        type = 'success'
    })
end)

-- Function để gửi thông báo từ server
function SendAnnouncementToAll(title, message, duration, type, logo)
    TriggerClientEvent('xn_thongbao:client:showAnnouncement', -1, {
        title = title,
        message = message,
        duration = duration,
        type = type,
        logo = logo
    })
end

function SendAnnouncementToPlayer(playerId, title, message, duration, type, logo)
    TriggerClientEvent('xn_thongbao:client:showAnnouncement', playerId, {
        title = title,
        message = message,
        duration = duration,
        type = type,
        logo = logo
    })
end

-- Function để gửi thông báo đặc biệt (đỏ + pháo hoa) đến tất cả
function SendSpecialAnnouncementToAll(title, message, duration, logo)
    TriggerClientEvent('xn_thongbao:client:showAnnouncement', -1, {
        title = title,
        message = message,
        duration = duration or 10000,
        type = 'special',
        logo = logo
    })
end

-- Function để gửi thông báo đặc biệt đến người chơi cụ thể
function SendSpecialAnnouncementToPlayer(playerId, title, message, duration, logo)
    TriggerClientEvent('xn_thongbao:client:showAnnouncement', playerId, {
        title = title,
        message = message,
        duration = duration or 10000,
        type = 'special',
        logo = logo
    })
end

-- Export functions
exports('SendAnnouncementToAll', SendAnnouncementToAll)
exports('SendAnnouncementToPlayer', SendAnnouncementToPlayer)
exports('SendSpecialAnnouncementToAll', SendSpecialAnnouncementToAll)
exports('SendSpecialAnnouncementToPlayer', SendSpecialAnnouncementToPlayer)
