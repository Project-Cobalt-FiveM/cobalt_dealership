fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'cobalt_dealership'
author 'Citgo'
description 'Vehicle dealership: showroom, purchases and weekly finance'
version '1.0.0'

dependencies {
    'cobalt_mysql',
    'ox_lib',
    'cobalt_core',
    'cobalt_banking',
}

shared_script '@ox_lib/init.lua'

client_script 'client/init.lua'

server_scripts {
    '@cobalt_mysql/lib/MySQL.lua',
    '@cobalt_core/server/migrationgate.lua',
    'server/init.lua',
}

ui_page '_nui/build/index.html'

files {
    'config.lua',
    'client/*.lua',
    '_nui/build/index.html',
    '_nui/build/assets/*',
}
