fx_version 'cerulean'
game 'gta5'

author 'BareBones Server'
description 'Money System with Cash, Bank and Dirty Money'
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

