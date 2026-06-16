fx_version 'cerulean'
game 'gta5'

author 'BareBones Server'
description 'Full clothing customization shop - browse and purchase individual clothing pieces'
version '1.0.0'

dependencies {
    'my_datamanager',
    'my_money',
    'NativeUI'
}

shared_scripts {
    'config.lua'
}

client_scripts {
    '@NativeUI/NativeUI.lua',
    'client.lua'
}

server_scripts {
    'server.lua'
}
