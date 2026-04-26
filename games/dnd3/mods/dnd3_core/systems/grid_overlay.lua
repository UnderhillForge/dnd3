local storage = core.get_mod_storage()
local prefs_blob = storage:get_string("grid_overlay")
local prefs = {}

if prefs_blob and prefs_blob ~= "" then
	local parsed = core.parse_json(prefs_blob)
	if type(parsed) == "table" then
		prefs = parsed
	end
end

local hud_ids = {}
local update_accum = 0

local function persist()
	storage:set_string("grid_overlay", core.write_json(prefs))
end

function dnd3.grid_overlay_is_enabled(player_name)
	return prefs[player_name] == true
end

local function grid_label(player)
	local pos = player:get_pos()
	local gx = math.floor((pos.x / 5) + 0.5)
	local gz = math.floor((pos.z / 5) + 0.5)
	local gy = math.floor((pos.y / 5) + 0.5)
	return string.format("Grid cell: (%d,%d,%d)  World: (%.1f,%.1f,%.1f)", gx, gy, gz, pos.x, pos.y, pos.z)
end

local function ensure_hud(player)
	local name = player:get_player_name()
	if not dnd3.grid_overlay_is_enabled(name) then
		if hud_ids[name] then
			player:hud_remove(hud_ids[name])
			hud_ids[name] = nil
		end
		return
	end

	if not hud_ids[name] then
		hud_ids[name] = player:hud_add({
			hud_elem_type = "text",
			position = { x = 0.5, y = 0.02 },
			offset = { x = 0, y = 0 },
			alignment = { x = 0, y = 0 },
			scale = { x = 100, y = 20 },
			number = 0xD0D0D0,
			text = grid_label(player),
		})
	else
		player:hud_change(hud_ids[name], "text", grid_label(player))
	end
end

function dnd3.grid_overlay_set(player_name, enabled)
	prefs[player_name] = enabled == true
	persist()
	local player = core.get_player_by_name(player_name)
	if player then
		ensure_hud(player)
	end
	return prefs[player_name]
end

function dnd3.grid_overlay_toggle(player_name)
	return dnd3.grid_overlay_set(player_name, not dnd3.grid_overlay_is_enabled(player_name))
end

core.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if prefs[name] == nil then
		prefs[name] = false
		persist()
	end
	ensure_hud(player)
end)

core.register_on_leaveplayer(function(player)
	hud_ids[player:get_player_name()] = nil
end)

core.register_globalstep(function(dtime)
	update_accum = update_accum + dtime
	if update_accum < 0.3 then
		return
	end
	update_accum = 0
	for _, player in ipairs(core.get_connected_players()) do
		ensure_hud(player)
	end
end)

core.register_chatcommand("dnd3_grid", {
	params = "[on|off|toggle]",
	description = "Toggle tactical grid cell HUD readout",
	func = function(name, param)
		local mode = (param or "toggle"):gsub("^%s+", ""):gsub("%s+$", "")
		if mode == "" then
			mode = "toggle"
		end
		if mode == "on" then
			dnd3.grid_overlay_set(name, true)
		elseif mode == "off" then
			dnd3.grid_overlay_set(name, false)
		elseif mode == "toggle" then
			dnd3.grid_overlay_toggle(name)
		else
			return false, "Usage: /dnd3_grid [on|off|toggle]"
		end
		return true, "Grid overlay: " .. (dnd3.grid_overlay_is_enabled(name) and "on" or "off")
	end,
})
