fx_version 'cerulean'
game 'gta5'

author 'BareBones Server'
description 'Clean owned vehicles with /cleancar command'
version '1.0.0'

dependencies {
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
