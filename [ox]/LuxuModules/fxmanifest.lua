fx_version 'cerulean'
game 'gta5'
lua54 'yes'
version '1.3.2'
author 'Luxu.gg'
description 'LuxuModules - A library from Luxu.gg scripts'

node_version "22"

shared_scripts { '@ox_lib/init.lua', 'config.lua', "init.lua" }

ui_page 'nui/index.html'

files { 'nui/index.html', 'nui/**/*', 'nui/*', 'shared/*', 'init.lua' }

client_scripts { 'client/tools.lua', 'client/cl_utils.lua', 'client/client.lua',
    'client/resource.lua', 'client/events.lua' }

server_scripts { '@mysql-async/lib/MySQL.lua', 'server/index.js', 'server/sv_utils.lua', 'server/server.lua', 'server/resource.lua', 'server/events.lua' }

dependencies {
    'ox_lib',
    '/onesync',
    '/server:6464'
}
