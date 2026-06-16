fx_version 'cerulean'
game 'gta5'

name 'my_housing'
description 'Housing System'
author 'Custom'
version '2.1.0'

lua54 'yes'

dependencies {
    'my_datamanager',
    'my_money',
    'my_inventory',
    'my_energy',
    'my_time',
    'my_vehicles'
}

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
