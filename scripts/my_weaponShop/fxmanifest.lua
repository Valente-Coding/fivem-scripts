fx_version 'cerulean'
game 'gta5'

author 'BareBones Server'
description 'Weapon Shop'
version '1.0.0'

dependencies {
    'my_money',
    'my_datamanager',
    'my_licenses'
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
    'html/script.js',
    'html/img/BaseballBat.png',
    'html/img/CarbineRifle.png',
    'html/img/MicroSMG.png',
    'html/img/Pistol.png',
    'html/img/Armor.png'
}
