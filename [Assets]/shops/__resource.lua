resource_manifest_version "44febabe-d386-4d18-afbe-5e627f4af937"

client_script "@srp-errorlog/client/cl_errorlog.lua"
client_script{'client.lua',
	'gui.lua',
}

server_script 'server.lua'
