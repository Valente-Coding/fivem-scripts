fx_version 'cerulean'
game 'gta5'

author 'BareBones Server'
description 'Repair kit for owned vehicles'
version '1.0.0'

dependencies {
    'my_money',
    'my_vehicles'
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
