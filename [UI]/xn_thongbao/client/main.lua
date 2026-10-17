local QBCore = exports['qb-core']:GetCoreObject()

-- Event mở dialog để nhập thông báo
RegisterNetEvent('xn_thongbao:client:openDialog', function()
    local input = lib.inputDialog('Gửi Thông Báo', {
        {
            type = 'textarea',
            label = 'Nội dung thông báo',
            description = 'Nhập nội dung thông báo bạn muốn gửi đến tất cả người chơi',
            placeholder = 'Nhập nội dung thông báo...',
            required = true,
            min = 1,
            max = 500
        }
    })

    if input and input[1] then
        TriggerServerEvent('xn_thongbao:server:sendFromDialog', input[1])
    end
end)

-- Event để hiển thị thông báo
RegisterNetEvent('xn_thongbao:client:showAnnouncement', function(data)
    SendNUIMessage({
        action = 'showAnnouncement',
        title = data.title or 'ALL STARS VIETNAM',
        message = data.message or 'Chào mừng bạn đến với server!',
        duration = data.duration or 5000,
        type = data.type or 'info', -- info, success, warning, error
        logo = data.logo -- URL của logo mới
    })
end)

-- Event để ẩn thông báo
RegisterNetEvent('xn_thongbao:client:hideAnnouncement', function()
    SendNUIMessage({
        action = 'hideAnnouncement'
    })
end)

-- -- Command test thông báo
-- RegisterCommand('testannounce', function(source, args, rawCommand)
--     local message = table.concat(args, ' ') or 'Đây là tin nhắn test!'
--     TriggerEvent('xn_thongbao:client:showAnnouncement', {
--         title = 'ADMIN',
--         message = message,
--         duration = 10000,
--         type = 'info'
--     })
-- end, false)

-- -- Command test với logo tùy chỉnh
-- RegisterCommand('testlogo', function(source, args, rawCommand)
--     local logoUrl = args[1] or 'https://raw.githubusercontent.com/xuannguyen995/clothing2/refs/heads/main/female_11_1.webp'
--     local message = table.concat(args, ' ', 2) or 'Test thông báo với logo tùy chỉnh!'
    
--     TriggerEvent('xn_thongbao:client:showAnnouncement', {
--         title = 'LOGO TEST',
--         message = message,
--         duration = 8000000,
--         type = 'success',
--         logo = logoUrl
--     })
-- end, false)

-- -- Command test animation text dài
-- RegisterCommand('testscroll', function(source, args, rawCommand)
--     TriggerEvent('xn_thongbao:client:showAnnouncement', {
--         title = 'ADMIN',
--         message = 'Đây là một thông báo rất dài đểssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss test tính năng scroll text từ phải qua trái khi nội dung vượt quá giới hạn cho phép của container',
--         duration = 15000000,
--         type = 'info'
--     })
-- end, false)

-- Function để gửi thông báo từ client
function SendAnnouncement(title, message, duration, type, logo)
    TriggerEvent('xn_thongbao:client:showAnnouncement', {
        title = title,
        message = message,
        duration = duration,
        type = type,
        logo = logo
    })
end

-- Function để gửi thông báo đặc biệt (đỏ + pháo hoa)
function SendSpecialAnnouncement(title, message, duration, logo)
    TriggerEvent('xn_thongbao:client:showAnnouncement', {
        title = title,
        message = message,
        duration = duration or 10000,
        type = 'special',
        logo = logo
    })
end

-- Export functions
exports('SendAnnouncement', SendAnnouncement)
exports('SendSpecialAnnouncement', SendSpecialAnnouncement)
