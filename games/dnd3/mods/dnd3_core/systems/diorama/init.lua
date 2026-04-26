local modpath = dnd3.modpath

dnd3.diorama = dnd3.diorama or {
	version = "0.1.0",
}

dnd3._state.diorama = dnd3._state.diorama or {
	chunk_cache = {},
	converted_chunks = {},
}

local function get_setting(key)
	local s = core.settings
	if not s then
		return nil
	end
	if s:get("dnd3_diorama_" .. key) ~= nil then
		return s:get("dnd3_diorama_" .. key)
	end
	if s:get("render." .. key) ~= nil then
		return s:get("render." .. key)
	end
	return nil
end

function dnd3.diorama.get_bool(key, default)
	local v = get_setting(key)
	if v == nil then
		return default
	end
	return core.is_yes(v)
end

function dnd3.diorama.get_number(key, default)
	local v = get_setting(key)
	if v == nil then
		return default
	end
	local n = tonumber(v)
	if n == nil then
		return default
	end
	return n
end

function dnd3.diorama.enabled()
	return dnd3.diorama.get_bool("enabled", true)
end

dofile(modpath .. "/systems/diorama/terrain_conversion.lua")

core.log("action", "[dnd3_core] diorama initialized v" .. dnd3.diorama.version)
