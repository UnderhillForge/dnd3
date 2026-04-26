-- systems/diorama_studio/init.lua

local modpath = dnd3.modpath
local storage = core.get_mod_storage()

dnd3._studio_prefabs = dnd3._studio_prefabs or {}

local prefabs_blob = storage:get_string("diorama_studio_prefabs")
if prefabs_blob and prefabs_blob ~= "" then
	local parsed = core.parse_json(prefabs_blob)
	if type(parsed) == "table" then
		dnd3._studio_prefabs = parsed
	end
end

dnd3.diorama_studio = dnd3.diorama_studio or {
	version  = "0.1.0",
	sessions = {},
}

function dnd3.diorama_studio.save_prefabs()
	storage:set_string("diorama_studio_prefabs", core.write_json(dnd3._studio_prefabs))
end

dofile(modpath .. "/systems/diorama_studio/palette.lua")
dofile(modpath .. "/systems/diorama_studio/tools.lua")
dofile(modpath .. "/systems/diorama_studio/ui.lua")
dofile(modpath .. "/systems/diorama_studio/preview.lua")

core.log("action", "[dnd3_core] diorama_studio initialized v" .. dnd3.diorama_studio.version)
