fx_version 'cerulean'
game 'gta5'

author 'Antigravity'
description 'Hệ thống sử dụng thẻ đổi tên nhân vật cho QB/QBX kết hợp Ox Lib và Ox Inventory'
version '1.0.0'

-- dependencies {
--     'ox_lib'
-- }

shared_scripts {
	'@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Nạp thư viện SQL nếu cần sử dụng MySQL.update trực tiếp
    'server.lua'
}
