fx_version 'cerulean'
game 'gta5'

author 'BareBones Framework'
description 'Hotel/Motel system - sleep and fast forward time'
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
    'my_time',
    'my_energy'
}
