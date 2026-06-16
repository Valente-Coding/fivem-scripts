fx_version 'cerulean'
game 'gta5'

author 'Converted'
description 'Vehicle Flipper Script - Steal vehicles for profit'
version '2.0.0'

shared_scripts {
    'config.lua',
}

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'my_money',
    'my_vehicles',
    'my_inventory'
}
