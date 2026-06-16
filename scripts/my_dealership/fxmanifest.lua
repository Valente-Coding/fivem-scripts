fx_version 'cerulean'
game 'gta5'

author 'BareBones Framework'
description 'Custom dealership system with my_money and my_vehicles integration'
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
    'html/script.js',
    'html/images/*.jpg'
}

dependencies {
    'my_datamanager',
    'my_money',
    'my_vehicles',
    'my_licenses'
}
