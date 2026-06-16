fx_version 'cerulean'
game 'gta5'

author 'Warehouse Empire'
description 'Supply-chain warehouse management game for FiveM'
version '1.0.0'

dependencies {
    'my_datamanager',
    'my_money',
}

shared_scripts {
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

ui_page 'UI/index.html'

files {
    'UI/index.html',
    'UI/css/game.css',
    'UI/js/game.js',
    'Example/assets/plugins/bootstrap/css/bootstrap.min.css',
    'Example/assets/plugins/bootstrap/js/bootstrap.bundle.min.js',
    'Example/assets/plugins/fontawesome/js/all.min.js',
    'Example/assets/plugins/fontawesome/webfonts/*.woff2',
    'Example/assets/plugins/fontawesome/webfonts/*.ttf',
}
