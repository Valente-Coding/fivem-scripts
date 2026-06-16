fx_version 'cerulean'
game 'gta5'

author 'BareBones Server'
description 'Permadeath - Full data wipe on death (with whitelist support)'
version '2.1.0'

dependencies {
    'my_money',
    'my_inventory',
    'my_datamanager',
    'my_vehicles',
    'my_housing',
    'my_energy',
    'my_business',
    'my_drugdealer',
    'my_stocks',
    'my_position'
}

ui_page 'html/index.html'

files {
    'html/index.html'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}
