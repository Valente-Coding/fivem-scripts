fx_version "cerulean"
game "gta5"

lua54 "yes"

author "TheF3nt0n"
description "Vapid Speedo Express"

files {
    "data/**/*.meta",
    "audio/**/*.dat54.rel",
    "audio/**/*.dat151.rel",
    "audio/**/*.awc",
}

-- Meta
data_file "HANDLING_FILE" "data/**/handling*.meta"
data_file "VEHICLE_METADATA_FILE" "data/**/vehicles*.meta"
data_file 'CARCOLS_FILE' "data/**/carcols.meta"
data_file "VEHICLE_VARIATION_FILE" "data/**/carvariations*.meta"

-- Audio 
data_file "AUDIO_GAMEDATA" "audio/nspeedo_game.dat"
data_file "AUDIO_SOUNDDATA" "audio/nspeedo_sounds.dat"
data_file "AUDIO_WAVEPACK" "audio/sfx/dlc_nspeedo"

-- Names
client_scripts {
    "vehicle_names.lua",
}

-- Escrow
escrow_ignore {
    "data/*.meta",
    "vehicle_names.lua",
    "stream/*.ytd",
}
dependency '/assetpacks'