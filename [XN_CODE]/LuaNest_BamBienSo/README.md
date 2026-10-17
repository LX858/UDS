# Screens Script
With this script the opportunities are endless. You can create as many screens as you want with a single script.

## Description

- This particular script lets you create as many dui screens you want with 4 simple steps
- Steps
    - Create a ox lib polyzone around the room where the screen is present. 
    - Create a target boxzone for the screen to target on.
    - Go to the maps folder, look for the texture dictionary and texture name of the screen you want to use
    - Add all the information in client/zones.lua as I have done in the example

## Dependencies

- ox_lib
- qb-target/qtarget/ox_target

## Installation
- Download the script and put it in your resources folder
- Make sure the script is named `dui`. If its named `dui-main` or `dui-anything`, rename it to `dui`
- Add `ensure dui` to your server.cfg
- Make sure you have the dependencies installed
- You are good to go!!

## Support

- Discord: https://discord.gg/VGYkkAYVv2
- Website : https://snipe.tebex.io
- If you have a custom mlo and have a screen in there which you want to use with this script, make sure you make the polyzones and target before you ask in my discord on how to find texture dictionary and texture name. I can only help with the texture dictionaries and texture name if you do the other steps first.




lib.addCommand('addgiaytoxe', {
    help = 'Thêm giấy tờ xe cho người chơi',
    params = {
        {
            name = 'target',
            type = 'pid',
            help = 'PID người nhận giấy tờ xe',
        },
        {
            name = 'plate',
            type = 'string',
            help = 'Biển số xe',
        }
    }
}, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    print(('[LuaNest] Thêm giấy tờ xe cho PID: %s, Biển số: %s'):format(args.target, args.plate))

    -- Kiểm tra job và grade
    if Player.PlayerData.job.name ~= 'police' or Player.PlayerData.job.grade.level < 7 then
        QBCore.Functions.Notify(src, '❌ Bạn cần là công an từ cấp 7 trở lên để sử dụng lệnh này!', 'error')
        return
    end

    -- Tìm player theo PID bằng function có sẵn
    print('[DEBUG] Đang tìm PID:', args.target, 'Type:', type(args.target))
    local targetPlayer = exports.qbx_core:GetPlayer(tonumber(args.target))
    if not targetPlayer then
        print('[DEBUG] Không tìm thấy player với PID:', args.target)
        QBCore.Functions.Notify(src, '❌ Không tìm thấy người chơi', 'error')
        return
    end
    print('[DEBUG] Tìm thấy player - PID:', targetPlayer.PlayerData.pid, 'Source:', targetPlayer.PlayerData.source)

    -- Tạo giấy tờ xe trực tiếp
    local metadata = {
        plate = args.plate,
        tenchu = GetPlayerName(src),
        CCCD = targetPlayer.PlayerData.citizenid,
        model = "Unknown" -- Có thể để Unknown hoặc yêu cầu nhập thêm
    }

    local targetSource = targetPlayer.PlayerData.source
    exports.ox_inventory:AddItem(targetSource, 'giaytoxe', 1, metadata)
    QBCore.Functions.Notify(targetSource, '✅ Đã nhận giấy tờ xe vào túi đồ!', 'success')
    QBCore.Functions.Notify(src, '✅ Đã thêm giấy tờ xe cho người chơi PID: ' .. targetPlayer.PlayerData.pid .. ' (Source: ' .. targetSource .. ')', 'success')
end)