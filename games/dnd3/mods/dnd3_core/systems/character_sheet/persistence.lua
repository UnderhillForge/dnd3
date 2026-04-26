local storage = core.get_mod_storage()

local function key(player_name)
	return "character_sheet.prefs." .. player_name
end

local function read_prefs(player_name)
	local raw = storage:get_string(key(player_name))
	if raw == "" then
		return {}
	end
	local parsed = core.parse_json(raw)
	if type(parsed) ~= "table" then
		return {}
	end
	return parsed
end

local function write_prefs(player_name, prefs)
	storage:set_string(key(player_name), core.write_json(prefs or {}))
end

function dnd3.character_sheet.prefs_get(player_name, field, default)
	local prefs = read_prefs(player_name)
	if prefs[field] == nil then
		return default
	end
	return prefs[field]
end

function dnd3.character_sheet.prefs_set(player_name, field, value)
	local prefs = read_prefs(player_name)
	prefs[field] = value
	write_prefs(player_name, prefs)
end
