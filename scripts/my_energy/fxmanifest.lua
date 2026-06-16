fx_version 'cerulean'
game 'gta5'

author 'BareBones Server'
description 'Energy system with HUD bar and replenish API'
version '1.0.0'

dependencies {
    'my_datamanager'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
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
