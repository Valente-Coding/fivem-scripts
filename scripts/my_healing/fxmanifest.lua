fx_version 'cerulean'
game 'gta5'

author 'BareBones Server'
description 'Simple Healing Station'
version '1.0.0'

dependencies {
    'my_money',
    'my_datamanager'
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
