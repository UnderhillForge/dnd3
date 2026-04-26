-- GM weather controls.
-- All commands require map_edit permission (GM role).

core.register_chatcommand("dnd3_weather", {
	params = "",
	description = "Show current weather status",
	func = function(name, param)
		local s   = dnd3.weather.status()
		local wt  = dnd3.weather.get_type(s.global)
		local lines = {
			string.format("Global weather: %s (%s)", s.global, wt and wt.label or "?"),
		}
		local overrides = {}
		for pname, wid in pairs(s.player_overrides) do
			overrides[#overrides + 1] = string.format("  %s → %s", pname, wid)
		end
		if #overrides > 0 then
			lines[#lines + 1] = "Player overrides:"
			for _, l in ipairs(overrides) do lines[#lines + 1] = l end
		end
		local rcells = {}
		for k, wid in pairs(s.region_cells) do
			rcells[#rcells + 1] = string.format("  cell[%s] → %s", k, wid)
		end
		if #rcells > 0 then
			lines[#lines + 1] = string.format("Regional cells (%d):", #rcells)
			for _, l in ipairs(rcells) do lines[#lines + 1] = l end
		end
		return true, table.concat(lines, "\n")
	end,
})

core.register_chatcommand("dnd3_weather_list", {
	params = "",
	description = "List all registered weather types",
	func = function(name, param)
		local types = dnd3.weather.list_types()
		if #types == 0 then return true, "No weather types registered." end
		local lines = { "Weather types:" }
		for _, wt in ipairs(types) do
			lines[#lines + 1] = string.format("  [%s] %s — sound=%s hook=%s",
				wt.id, wt.label,
				wt.sound or "none",
				wt.ruleset_hook or "none")
		end
		return true, table.concat(lines, "\n")
	end,
})

core.register_chatcommand("dnd3_weather_set", {
	params = "<weather_id>",
	description = "GM: set global weather for all players",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local wid = param:match("^%s*(.-)%s*$")
		if wid == "" then return false, "Usage: /dnd3_weather_set <weather_id>" end
		local ok, err = dnd3.weather.set_global(wid)
		if not ok then return false, tostring(err) end
		local wt = dnd3.weather.get_type(wid)
		return true, string.format("Global weather set to '%s' (%s).", wid, wt and wt.label or wid)
	end,
})

core.register_chatcommand("dnd3_weather_player", {
	params = "<player> <weather_id | clear>",
	description = "GM: set or clear per-player weather override",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local pname, wid = param:match("^(%S+)%s+(%S+)$")
		if not pname then
			return false, "Usage: /dnd3_weather_player <player> <weather_id | clear>"
		end
		local set_id = (wid == "clear") and nil or wid
		local ok, err = dnd3.weather.set_player(pname, set_id)
		if not ok then return false, tostring(err) end
		if set_id then
			return true, string.format("Weather override for '%s' set to '%s'.", pname, set_id)
		else
			return true, string.format("Weather override for '%s' cleared.", pname)
		end
	end,
})

core.register_chatcommand("dnd3_weather_paint", {
	params = "<weather_id> <radius_cells>",
	description = "GM: paint regional weather in a square radius around you",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local player = core.get_player_by_name(name)
		if not player then return false, "Player not found." end

		local wid, radius_str = param:match("^(%S+)%s*(%S*)$")
		if not wid or wid == "" then
			return false, "Usage: /dnd3_weather_paint <weather_id> [radius_cells]"
		end
		local radius = math.max(1, math.min(50, tonumber(radius_str) or 5))
		local pos    = player:get_pos()
		local span   = radius * 20   -- REGION_SCALE = 20
		local pos1   = { x = pos.x - span, y = pos.y, z = pos.z - span }
		local pos2   = { x = pos.x + span, y = pos.y, z = pos.z + span }
		local count  = dnd3.weather.region_paint(wid, pos1, pos2)
		if count == 0 then
			return false, "Unknown weather type '" .. wid .. "'. Use /dnd3_weather_list."
		end
		return true, string.format("Painted '%s' over %d region cells (radius %d).",
			wid, count, radius)
	end,
})

core.register_chatcommand("dnd3_weather_clear_region", {
	params = "<radius_cells>",
	description = "GM: clear regional weather in a square radius around you",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local player = core.get_player_by_name(name)
		if not player then return false, "Player not found." end
		local radius = math.max(1, math.min(50, tonumber(param) or 5))
		local pos    = player:get_pos()
		local span   = radius * 20
		local pos1   = { x = pos.x - span, y = pos.y, z = pos.z - span }
		local pos2   = { x = pos.x + span, y = pos.y, z = pos.z + span }
		local count  = dnd3.weather.region_clear(pos1, pos2)
		return true, string.format("Cleared %d regional weather cells (radius %d).", count, radius)
	end,
})
