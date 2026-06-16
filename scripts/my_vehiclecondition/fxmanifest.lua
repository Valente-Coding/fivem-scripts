fx_version 'cerulean'
game 'gta5'

author 'BareBones Framework'
description 'Vehicle Condition Check - Press H near an owned vehicle to check Engine/Brakes/Clutch/Suspension condition'
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
