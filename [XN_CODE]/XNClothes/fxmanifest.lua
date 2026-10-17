
fx_version "cerulean"
description "Clothesshop"
author "xuannguyen995"
version '1.91'
lua54 'yes'
games {
  "gta5"
}

escrow_ignore {
  'config/*',
  "client/*.lua",
  "web/**/*",
  "web/src/**/*",
  "server/*.lua"
}

shared_scripts {
  'config/config.lua',            -- Main config (MUST be loaded first)
  'config/configbalo.lua',        -- Bag/Inventory config
  'config/config_blacklist.lua',  -- Blacklist config
  'config/config_dohiem.lua',     -- Rarity (Độ Hiếm) config
  'config/config_job.lua', -- Job clothing config
  'config/config_tradeshop.lua',  -- Trade shop config
  "@ox_lib/init.lua"
}

ui_page 'web/build/index.html'

client_scripts {
  "client/main.lua",
  "client/client.lua",
  "client/jobclothing.lua",
  "client/tunel.lua",
  "client/inventoryslot.lua",
}

server_scripts {
  "@oxmysql/lib/MySQL.lua",
  "server/*.lua"
}

files {
  'web/build/index.html',
  'web/build/**/*',
  'web/public/images/*.png'
}

dependencies {
  "ox_lib",
  "screenshot-basic"
}
