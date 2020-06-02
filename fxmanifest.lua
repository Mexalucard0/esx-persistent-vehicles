fx_version 'adamant'

game 'gta5'

description 'Persistent Vehicles Mod - @github: '

version '1.0.0'

client_scripts {
	'config.lua',
	'client.lua',
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@async/async.lua',
	'config.lua',
	'server.lua',
}

dependencies {
	'esx_vehicleshop',
}
