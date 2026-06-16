fx_version 'cerulean'
game 'gta5'

author 'BareBones Server'
description 'Drug Selling System with Street Customers'
version '1.0.0'

dependencies {
    'my_money',
    'my_inventory',
    'my_drugdealer'
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
