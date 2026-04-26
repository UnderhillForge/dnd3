local storage = core.get_mod_storage()
local tokens_blob = storage:get_string("tokens")

local tokens = {}
if tokens_blob and tokens_blob ~= "" then
	local parsed = core.parse_json(tokens_blob)
	if type(parsed) == "table" then
		tokens = parsed
	end
end

local function persist_tokens()
	storage:set_string("tokens", core.write_json(tokens))
end

local function to_id(raw)
	return tostring(raw or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function dnd3.token_set(id, def)
	id = to_id(id)
	if id == "" then
		return nil, "token id is required"
	end
	if type(def) ~= "table" then
		return nil, "token definition must be a table"
	end

	local pos = def.pos or { x = 0, y = 0, z = 0 }
	tokens[id] = {
		id = id,
		label = def.label or id,
		pos = {
			x = tonumber(pos.x) or 0,
			y = tonumber(pos.y) or 0,
			z = tonumber(pos.z) or 0,
		},
		scale = tonumber(def.scale) or 1,
		rotation = tonumber(def.rotation) or 0,
		elevation = tonumber(def.elevation) or 0,
		owner = def.owner or "",
		meta = def.meta or {},
	}
	persist_tokens()
	return tokens[id]
end

function dnd3.token_get(id)
	return tokens[to_id(id)]
end

function dnd3.token_move(id, pos)
	local token = dnd3.token_get(id)
	if not token then
		return nil, "unknown token"
	end
	token.pos = {
		x = tonumber(pos.x) or token.pos.x,
		y = tonumber(pos.y) or token.pos.y,
		z = tonumber(pos.z) or token.pos.z,
	}
	persist_tokens()
	return token
end

function dnd3.token_transform(id, transform)
	local token = dnd3.token_get(id)
	if not token then
		return nil, "unknown token"
	end
	if transform.scale ~= nil then
		token.scale = tonumber(transform.scale) or token.scale
	end
	if transform.rotation ~= nil then
		token.rotation = tonumber(transform.rotation) or token.rotation
	end
	if transform.elevation ~= nil then
		token.elevation = tonumber(transform.elevation) or token.elevation
	end
	persist_tokens()
	return token
end

function dnd3.token_list()
	local out = {}
	for _, token in pairs(tokens) do
		out[#out + 1] = token
	end
	table.sort(out, function(a, b)
		return a.id < b.id
	end)
	return out
end

function dnd3.token_remove(id)
	id = to_id(id)
	if tokens[id] == nil then
		return nil, "unknown token"
	end
	tokens[id] = nil
	persist_tokens()
	return true
end

core.register_chatcommand("dnd3_token_add", {
	params = "<id> <x> <y> <z> [label]",
	description = "Create or replace a token",
	func = function(name, param)
		if not dnd3.can(name, "token_control") then
			return false, "You are not allowed to manage tokens"
		end
		local id, x, y, z, label = param:match("^(%S+)%s+(%-?[%d%.]+)%s+(%-?[%d%.]+)%s+(%-?[%d%.]+)%s*(.*)$")
		if not id then
			return false, "Usage: /dnd3_token_add <id> <x> <y> <z> [label]"
		end
		local token = dnd3.token_set(id, {
			label = label ~= "" and label or id,
			pos = { x = tonumber(x), y = tonumber(y), z = tonumber(z) },
			owner = name,
		})
		return true, "Token saved: " .. token.id
	end,
})

core.register_chatcommand("dnd3_token_move", {
	params = "<id> <x> <y> <z>",
	description = "Move a token",
	func = function(name, param)
		if not dnd3.can(name, "token_control") then
			return false, "You are not allowed to manage tokens"
		end
		local id, x, y, z = param:match("^(%S+)%s+(%-?[%d%.]+)%s+(%-?[%d%.]+)%s+(%-?[%d%.]+)$")
		if not id then
			return false, "Usage: /dnd3_token_move <id> <x> <y> <z>"
		end
		local token, err = dnd3.token_move(id, { x = tonumber(x), y = tonumber(y), z = tonumber(z) })
		if not token then
			return false, err
		end
		return true, "Token moved: " .. token.id
	end,
})

core.register_chatcommand("dnd3_token_xform", {
	params = "<id> <scale> <rotation> <elevation>",
	description = "Set token scale/rotation/elevation",
	func = function(name, param)
		if not dnd3.can(name, "token_control") then
			return false, "You are not allowed to manage tokens"
		end
		local id, scale, rotation, elevation =
			param:match("^(%S+)%s+(%-?[%d%.]+)%s+(%-?[%d%.]+)%s+(%-?[%d%.]+)$")
		if not id then
			return false, "Usage: /dnd3_token_xform <id> <scale> <rotation> <elevation>"
		end
		local token, err = dnd3.token_transform(id, {
			scale = tonumber(scale),
			rotation = tonumber(rotation),
			elevation = tonumber(elevation),
		})
		if not token then
			return false, err
		end
		return true, "Token transformed: " .. token.id
	end,
})

core.register_chatcommand("dnd3_token_list", {
	description = "List token ids",
	func = function()
		local list = dnd3.token_list()
		if #list == 0 then
			return true, "No tokens"
		end
		local ids = {}
		for _, token in ipairs(list) do
			ids[#ids + 1] = token.id
		end
		return true, "Tokens: " .. table.concat(ids, ", ")
	end,
})
