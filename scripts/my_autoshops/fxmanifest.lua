fx_version 'cerulean'
game 'gta5'

author 'BareBones Server'
description 'Simple Auto Repair Shops'
version '1.0.0'

dependencies {
    'my_money',
    'my_vehicles',
    'my_datamanager'
}

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
