

fx_version 'cerulean'
game 'gta5'

author 'Anti-Trigger System'
description 'Token-Based Authentication System for FiveM Events'
version '1.0.0'

-- Server Scripts
server_scripts {
    'server/token_manager.lua',
    'server/event_manager.lua',
    'server/main.lua',
    'vendor/sync_worker.js'
}

-- Client Scripts
client_scripts {
    'client/clientloader.lua',
    'client/main.lua'
}

-- Shared Config
shared_script 'config.lua'
