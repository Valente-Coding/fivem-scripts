fx_version 'cerulean'
game 'gta5'

author 'BareBones Server'
description 'Tracks player Engine, Transmission, Clutch and Suspension skill levels'
version '1.0.0'

dependencies {
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
