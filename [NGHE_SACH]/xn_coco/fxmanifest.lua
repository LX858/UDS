fx_version 'cerulean'

game 'gta5'

description 'Coconut Picking'

lua54 'yes'

version '1.1.0'

this_is_a_map 'yes'

files {
    'nui_ckg_quanpho_int.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'nui_ckg_quanpho_int.ytyp'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/index.js',
    'html/index.css',
    'html/reset.css'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

shared_scripts { '@qb-core/shared/locale.lua', '@ox_lib/init.lua', 'config.lua' }
escrow_ignore {
    'config.lua',
    'client/client.lua',
    'server/server.lua'
}
