local storage = core.get_mod_storage()
local role_blob = storage:get_string("roles")
local roles = {}

if role_blob and role_blob ~= "" then
	local parsed = core.parse_json(role_blob)
	if type(parsed) == "table" then
		roles = parsed
	end
end

local VALID_ROLES = {
	gm = true,
	player = true,
	observer = true,
}

local PERMISSIONS = {
	map_edit = { gm = true },
	token_control = { gm = true, player = true },
	initiative_edit = { gm = true },
	fog_control = { gm = true },
	ruleset_switch = { gm = true },
	dice_roll = { gm = true, player = true, observer = true },
}

local function persist_roles()
	storage:set_string("roles", core.write_json(roles))
end

local function is_server_privileged(player_name)
	if not player_name or player_name == "" then
		return false
	end
	local ok, has = pcall(core.check_player_privs, player_name, { server = true })
	return ok and has == true
end

function dnd3.get_role(player_name)
	if is_server_privileged(player_name) then
		return "gm"
	end
	return roles[player_name] or "player"
end

function dnd3.set_role(player_name, role)
	if not VALID_ROLES[role] then
		return false, "invalid role"
	end
	roles[player_name] = role
	persist_roles()
	return true
end

function dnd3.can(player_name, action)
	local policy = PERMISSIONS[action]
	if not policy then
		return false
	end
	local role = dnd3.get_role(player_name)
	return policy[role] == true
end

core.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if is_server_privileged(name) then
		if roles[name] ~= "gm" then
			roles[name] = "gm"
			persist_roles()
		end
		return
	end
	if not roles[name] then
		roles[name] = "player"
		persist_roles()
	end
end)

core.register_chatcommand("dnd3_role", {
	params = "<player> <gm|player|observer>",
	description = "Set a dnd3 role for a connected or known player",
	privs = { server = true },
	func = function(_, param)
		local target, role = param:match("^(%S+)%s+(%S+)$")
		if not target or not role then
			return false, "Usage: /dnd3_role <player> <gm|player|observer>"
		end
		local ok, err = dnd3.set_role(target, role)
		if not ok then
			return false, err
		end
		return true, "Role set: " .. target .. " -> " .. role
	end,
})
