resource_manifest_version "44febabe-d386-4d18-afbe-5e627f4af937"

dependency "ghmattimysql"

client_script "@srp-errorlog/client/cl_errorlog.lua"

server_script "playermanager/server.lua"

-- INIT --
server_script "sh_init.lua"
client_script "sh_init.lua"

--[[=====EVENTS=====]]--
server_script "events/sv_events.lua"
client_script "events/cl_events.lua"

--[[=====CORE=====]]--
server_script "core/sh_core.lua"
server_script "core/sh_enums.lua"
-- utility  
server_script "utility/sh_util.lua"
-- database
server_script "database/sv_db.lua" 
server_script "core/sv_core.lua"  
server_script "core/sv_characters.lua"

client_script "core/sh_core.lua" 
client_script "core/sh_enums.lua"
-- utility
client_script "utility/sh_util.lua"
client_script "utility/cl_util.lua" 

client_script "core/cl_entitys.lua"
client_script "core/cl_core.lua"

--[[=====SPAWNMANAGER=====]]--
client_script "spawnmanager/cl_spawnmanager.lua"

--[[=====PLAYER=====]]--
server_script "player/sv_player.lua"
server_script "player/sv_controls.lua"
server_script "player/sv_settings.lua"

client_script "player/cl_player.lua"
client_script "player/cl_controls.lua"
client_script "player/cl_settings.lua"

--[[=====BLIPMANAGER=====]]--
client_script "blipmanager/cl_blipmanager.lua"
client_script "blipmanager/cl_blips.lua"

--[[=====GAMEPLAY=====]]--
client_script "gameplay/cl_gameplay.lua"

--[[=====COMMANDS=====]]--
client_script "commands/cl_commands.lua"
server_script "commands/sv_commands.lua"

exports {
    "getModule",
    "addModule",
    "GetRanks",
    "GetJobs",
    "FetchVehProps",
    "SetVehProps",
    "GetVehicles"
}
server_exports {
    "GetUser",
    "getModule",
    "getCharacterFromCid",
    "getCharacterNameFromSource",
    "addModule"
}