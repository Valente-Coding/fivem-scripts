fx_version 'cerulean'
game 'gta5'

author 'BareBones Server'
description 'Fast Travel Taxi System'
version '1.0.0'

dependencies {
    'my_money'
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
