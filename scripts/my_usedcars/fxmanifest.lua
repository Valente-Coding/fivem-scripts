fx_version 'cerulean'
game 'gta5'

author 'BareBones Framework'
description 'Used Cars Marketplace System'
version '2.0.0'
lua54 'yes'

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
    'my_datamanager',
    'my_money',
    'my_vehicles',
    'my_dealership',
    'my_licenses'
}
