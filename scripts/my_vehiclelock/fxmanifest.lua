fx_version 'cerulean'
game 'gta5'

author 'BareBones Framework'
description 'Vehicle Lock/Unlock System - Persistent lock state via global_vehicles.json'
version '1.0.0'

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}

dependencies {
    'my_datamanager',
    'my_vehicles'
}
