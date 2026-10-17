

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name '1307_CayDongHo'
author '1307 Coding'
version '1.0.0'
description '1307 Cậy Đồng Hồ, được viết lại và sửa bởi 1307 Coding'

shared_scripts {
	'@ox_lib/init.lua',
	'config.lua'
}

client_scripts {
	'client/main.lua',
}

server_scripts {
	'server/server.lua'
}
 
dependency 'oxmysql'