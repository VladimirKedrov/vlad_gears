fx_version 'adamant'

game 'gta5'

author 'vladimirkedrov'

description 'Manual transmission + Clutch control'

version '8.7.0'

shared_script 'config.lua'

server_script 'server.lua'

client_script 'client.lua'
client_script 'events.lua'

lua54 'yes'

escrow_ignore {
    'client.lua',
    'server.lua',
    'events.lua',
    'config.lua',
    'readme.md'
}

