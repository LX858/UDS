return {
    statusIntervalSeconds = 3, --Tần suất kiểm tra tình trạng đói/khát để loại bỏ sức khỏe nếu 0.
    loadingModelsTimeout = 60000, -- Waiting time for ox_lib to load the models before throws an error, for low specs pc

    pauseMapText = 'UNDERSTAR', -- Text shown above the map when ESC is pressed. If left empty 'FiveM' will appear

    characters = {
        useExternalCharacters = true, -- Cho dù bạn có tài nguyên quản lý nhân vật bên ngoài. (Nếu đúng, hãy vô hiệu hóa việc quản lý nhân vật bên trong lõi)
        enableDeleteButton = false, -- Liệu người chơi có thể tự xóa các nhân vật hay không.
        startingApartment = false, -- Nếu được đặt thành sai, hãy bỏ qua lựa chọn căn hộ ngay từ đầu (yêu cầu qbx_spawn nếu đúng)

        dateFormat = 'YYYY-MM-DD',
        dateMin = '1900-01-01', -- Has to be in the same format as the dateFormat config
        dateMax = '2008-12-31', -- Has to be in the same format as the dateFormat config

        limitNationalities = true, -- Đặt điều này thành sai sẽ cho phép mọi người nhập bất cứ điều gì họ muốn vào lĩnh vực quốc tịch (để chỉnh sửa danh sách các quốc tịch, hướng đến dữ liệu/quốc tịch.LUA)

        profanityWords = {
            ['bad word'] = true
        },

        locations = { -- Spawn locations for multichar, these are chosen randomly
            {
                pedCoords = vec4(969.25, 72.61, 116.18, 276.55),
                camCoords = vec4(972.2, 72.9, 116.68, 97.27),
            },
            {
                pedCoords = vec4(1104.49, 195.9, -49.44, 44.22),
                camCoords = vec4(1102.29, 198.14, -48.86, 225.07),
            },
            {
                pedCoords = vec4(-2163.87, 1134.51, -24.37, 310.05),
                camCoords = vec4(-2161.7, 1136.4, -23.77, 131.52),
            },
            {
                pedCoords = vec4(-996.71, -68.07, -99.0, 57.61),
                camCoords = vec4(-999.90, -66.30, -98.45, 241.68),
            },
            {
                pedCoords = vec4(-1023.45, -418.42, 67.66, 205.69),
                camCoords = vec4(-1021.8, -421.7, 68.14, 27.11),
            },
            {
                pedCoords = vec4(2265.27, 2925.02, -84.8, 267.77),
                camCoords = vec4(2268.24, 2925.02, -84.36, 90.88),
            },
            {
                pedCoords = vec4(-1004.5, -478.51, 50.03, 28.19),
                camCoords = vec4(-1006.36, -476.19, 50.50, 210.38),
            }
        },
    },

    discord = {
        enabled = false, -- Điều này sẽ cho phép hoặc vô hiệu hóa sự hiện diện phong phú được xây dựng.

        appId = '1024981890798731345', -- This is the Application ID (Replace this with you own)

        largeIcon = { -- To set this up, visit https://forum.cfx.re/t/how-to-updated-discord-rich-presence-custom-image/157686
            icon = 'duck', -- Here you will have to put the image name for the 'large' icon.
            text = 'Qbox Ducky', -- Here you can add hover text for the 'large' icon.
        },

        smallIcon = {
            icon = 'logo_name', -- Here you will have to put the image name for the 'small' icon.
            text = 'This is a small icon with text', -- Here you can add hover text for the 'small' icon.
        },

        firstButton = {
            text = 'Qbox Discord',
            link = 'https://discord.gg/Z6Whda5hHA',
        },

        secondButton = {
            text = 'Main Website',
            link = 'https://www.qbox.re/',
        }
    },

    --- Only used by QB bridge
    hasKeys = function(plate, vehicle)
        return exports.qbx_vehiclekeys:HasKeys(vehicle)
    end,
}
