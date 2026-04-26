local modpath = dnd3.modpath

dnd3.hybrid_terrain = dnd3.hybrid_terrain or {
	version = "0.1.0",
}

-- Namespaced setting lookup for the hybrid architecture.
-- Uses dnd3.* keys first, then falls back to render.* aliases where relevant.
local function get_setting(name)
	local s = core.settings
	if not s then
		return nil
	end
	if s:get("dnd3_hybrid_" .. name) ~= nil then
		return s:get("dnd3_hybrid_" .. name)
	end
	if s:get("render." .. name) ~= nil then
		return s:get("render." .. name)
	end
	return nil
end

function dnd3.hybrid_terrain.get_bool(name, default)
	local v = get_setting(name)
	if v == nil then
		return default
	end
	return core.is_yes(v)
end

function dnd3.hybrid_terrain.get_number(name, default)
	local v = get_setting(name)
	if v == nil then
		return default
	end
	local n = tonumber(v)
	if n == nil then
		return default
	end
	return n
end

function dnd3.hybrid_terrain.enabled()
	return dnd3.hybrid_terrain.get_bool("enabled", true)
end

dofile(modpath .. "/systems/hybrid_terrain/slope_generator.lua")
dofile(modpath .. "/systems/hybrid_terrain/voxel_to_mesh.lua")
dofile(modpath .. "/systems/hybrid_terrain/navmesh.lua")

core.log("action", "[dnd3_core] hybrid_terrain initialized v" .. dnd3.hybrid_terrain.version)
