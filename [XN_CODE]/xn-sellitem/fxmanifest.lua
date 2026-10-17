--

-- shared_script "@dt_antidump/shared/clientloader.lua"

fx_version 'cerulean'
game 'gta5'
author 'D-TEAM - ROLEPLAY'
description 'Script Bán vật phẩm được viết và chỉnh sửa bởi D-TEAM'
version '0.1'

dependency 'monitors'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

-- client_script 'client/main.lua'

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua'
}
ui_page 'view/index.html'

files {
    'view/index.html',
    'view/phone.html',
    'view/assets/*.js',
    'view/assets/*.css',
    'view/img/*.png',
}

lua54 'yes'

server_exports {
    'GetDATA',
    'GetSellCategories',
    'GetCategoryCount',
    'GetLeaderboard',
    'xn_sellitem_leaderboard',
    'GetPlayerPoints',
    'NotifyLeaderboardUpdated',
}
