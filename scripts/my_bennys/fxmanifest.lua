fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description "Benny's Vehicle Customization"
version '1.0.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/compat.lua',
    'client/zones.lua',
}

server_scripts {
    'server.lua',
}

files {
    'client/dragcam.lua',
    'client/menus/main.lua',
    'client/menus/performance.lua',
    'client/menus/parts.lua',
    'client/menus/colors.lua',
    'client/menus/extras.lua',
    'client/menus/wheels.lua',
    'client/menus/neon.lua',
    'client/menus/paint.lua',
    'client/utils/installMod.lua',
    'client/utils/getModLabel.lua',
    'client/utils/vehicleProps.lua',
    'client/utils/enums/VehicleClass.lua',
    'client/utils/enums/WheelType.lua',
    'client/options/dashboard.lua',
    'client/options/interior.lua',
    'client/options/livery.lua',
    'client/options/pearlescent.lua',
    'client/options/plateindex.lua',
    'client/options/tyresmoke.lua',
    'client/options/wheelcolor.lua',
    'client/options/windowtint.lua',
    'client/options/xenon.lua',
    'web/index.html',
    'web/style.css',
    'web/script.js',
}

ui_page 'web/index.html'

dependencies {
    'my_money',
    'my_vehicles',
}
