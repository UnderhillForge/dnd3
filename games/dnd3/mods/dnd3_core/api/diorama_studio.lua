if not dnd3.open_diorama_studio then
	function dnd3.open_diorama_studio(player_name)
		return false, "Diorama Studio not loaded"
	end
end

if not dnd3.close_diorama_studio then
	function dnd3.close_diorama_studio(player_name)
		return true
	end
end

function dnd3.register_prefab(id, def)
	if type(id) ~= "string" or id == "" then
		return nil, "prefab id required"
	end
	if type(def) ~= "table" then
		return nil, "prefab def must be a table"
	end
	dnd3._studio_prefabs = dnd3._studio_prefabs or {}
	dnd3._studio_prefabs[id] = def
	if dnd3.diorama_studio and dnd3.diorama_studio.save_prefabs then
		dnd3.diorama_studio.save_prefabs()
	end
	return dnd3._studio_prefabs[id]
end

function dnd3.get_registered_prefab(id)
	if not dnd3._studio_prefabs then
		return nil
	end
	return dnd3._studio_prefabs[id]
end

function dnd3.list_registered_prefabs()
	local out = {}
	for id in pairs(dnd3._studio_prefabs or {}) do
		out[#out + 1] = id
	end
	table.sort(out)
	return out
end
