fx_version 'cerulean'
game 'gta5'

author 'BareBones Framework'
description 'Sandy Shores Car Lot - Player-owned vehicle sales lot'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'my_money',
    'my_datamanager',
    'my_vehicles',
    'my_dealership'
}
