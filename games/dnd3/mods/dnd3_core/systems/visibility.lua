local storage = core.get_mod_storage()
local visibility_blob = storage:get_string("visibility")

local visibility = {}
if visibility_blob and visibility_blob ~= "" then
	local parsed = core.parse_json(visibility_blob)
	if type(parsed) == "table" then
		visibility = parsed
	end
end

local function persist_visibility()
	storage:set_string("visibility", core.write_json(visibility))
end

local function ensure_player(name)
	if not visibility[name] then
		visibility[name] = {
			revealed_cells = {},
			los_radius = 12,
		}
	end
	return visibility[name]
end

local function cell_key(x, y, z)
	return string.format("%d,%d,%d", x, y, z)
end

function dnd3.visibility_reveal(name, pos)
	local state = ensure_player(name)
	local key = cell_key(math.floor(pos.x), math.floor(pos.y), math.floor(pos.z))
	state.revealed_cells[key] = true
	persist_visibility()
	return true
end

function dnd3.visibility_hide(name, pos)
	local state = ensure_player(name)
	local key = cell_key(math.floor(pos.x), math.floor(pos.y), math.floor(pos.z))
	state.revealed_cells[key] = nil
	persist_visibility()
	return true
end

function dnd3.visibility_clear(name)
	local state = ensure_player(name)
	state.revealed_cells = {}
	persist_visibility()
	return true
end

function dnd3.visibility_set_los(name, radius)
	local state = ensure_player(name)
	state.los_radius = math.max(1, math.floor(tonumber(radius) or 12))
	persist_visibility()
	return state.los_radius
end

function dnd3.visibility_get(name)
	return ensure_player(name)
end

core.register_chatcommand("dnd3_fog_reveal", {
	params = "<player> <x> <y> <z>",
	description = "Reveal one fog cell for a player",
	func = function(name, param)
		if not dnd3.can(name, "fog_control") then
			return false, "You are not allowed to control fog"
		end
		local who, x, y, z = param:match("^(%S+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)$")
		if not who then
			return false, "Usage: /dnd3_fog_reveal <player> <x> <y> <z>"
		end
		dnd3.visibility_reveal(who, { x = tonumber(x), y = tonumber(y), z = tonumber(z) })
		return true, "Revealed cell for " .. who
	end,
})

core.register_chatcommand("dnd3_fog_hide", {
	params = "<player> <x> <y> <z>",
	description = "Hide one fog cell for a player",
	func = function(name, param)
		if not dnd3.can(name, "fog_control") then
			return false, "You are not allowed to control fog"
		end
		local who, x, y, z = param:match("^(%S+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)$")
		if not who then
			return false, "Usage: /dnd3_fog_hide <player> <x> <y> <z>"
		end
		dnd3.visibility_hide(who, { x = tonumber(x), y = tonumber(y), z = tonumber(z) })
		return true, "Hid cell for " .. who
	end,
})

core.register_chatcommand("dnd3_fog_clear", {
	params = "<player>",
	description = "Clear all revealed fog cells for a player",
	func = function(name, param)
		if not dnd3.can(name, "fog_control") then
			return false, "You are not allowed to control fog"
		end
		local who = param:match("^(%S+)$")
		if not who then
			return false, "Usage: /dnd3_fog_clear <player>"
		end
		dnd3.visibility_clear(who)
		return true, "Fog cleared for " .. who
	end,
})
