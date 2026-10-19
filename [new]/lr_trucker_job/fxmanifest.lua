fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'lr_trucker_job'
description 'Qbox team transport job with server-authoritative missions'
author 'Lorraxs'
version '2.0.0'
dependency '/onesync'
ui_page 'web/build/index.html'

files {
  'web/build/index.html',
  'web/build/**/*',
}

shared_scripts {
  'locales/L.lua',
  'locales/lang/*.lua',
  'utils/ms.lua',
  'config.lua',

  'shared/core/lr.lua',
  'shared/core/class.lua',
  'shared/core/logger_v2.lua',
  'shared/core/disposables.lua',
  'shared/core/module_registry.lua',
  'shared/core/application.lua',
  'shared/core/schema.lua',

  'shared/generated/contracts.lua',
  'shared/generated/contracts/*.lua',
}

client_scripts {
  'client/core/nui.lua',
  'client/core/net.lua',
  'client/core/public.lua',
  'client/core/application.lua',
  'client/bridges/framework.lua',
  'client/bridges/frameworks/*.lua',
  'client/generated/contracts.lua',
  'client/generated/contracts/*.lua',
  'client/classes/trucker/npc.lua',
  'client/classes/trucker/mission.lua',
  'client/services/trucker_service.lua',
  'client/modules/*.lua',
  'client/boot.lua',
}

server_scripts {
  'server/core/net.lua',
  'server/core/public.lua',
  'server/core/application.lua',
  'server/bridges/framework.lua',
  'server/bridges/frameworks/*.lua',
  'server/database.lua',
  'server/generated/contracts.lua',
  'server/generated/contracts/*.lua',
  'server/classes/trucker/order_board.lua',
  'server/classes/trucker/business_order_board.lua',
  'server/classes/trucker/team.lua',
  'server/classes/trucker/mission_session.lua',
  'server/services/trucker_service.lua',
  'server/modules/*.lua',
  'server/boot.lua',
}
