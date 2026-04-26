local function normalize_pos(p)
	return {
		x = math.floor(p.x + 0.5),
		y = math.floor(p.y + 0.5),
		z = math.floor(p.z + 0.5),
	}
end

local function validate_nodename(nodename)
	if type(nodename) ~= "string" or nodename == "" then
		return false
	end
	return core.registered_nodes[nodename] ~= nil
end

function dnd3.map_fill(pos1, pos2, nodename)
	pos1 = normalize_pos(pos1)
	pos2 = normalize_pos(pos2)
	if not validate_nodename(nodename) then
		return nil, "unknown node: " .. tostring(nodename)
	end

	local minp = vector.new(
		math.min(pos1.x, pos2.x),
		math.min(pos1.y, pos2.y),
		math.min(pos1.z, pos2.z)
	)
	local maxp = vector.new(
		math.max(pos1.x, pos2.x),
		math.max(pos1.y, pos2.y),
		math.max(pos1.z, pos2.z)
	)

	local count = 0
	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			for x = minp.x, maxp.x do
				core.set_node({ x = x, y = y, z = z }, { name = nodename })
				count = count + 1
			end
		end
	end
	return count
end

function dnd3.map_raise(pos1, pos2, delta)
	pos1 = normalize_pos(pos1)
	pos2 = normalize_pos(pos2)
	delta = math.floor(tonumber(delta) or 0)
	if delta == 0 then
		return nil, "delta must be non-zero"
	end

	local minp = vector.new(math.min(pos1.x, pos2.x), math.min(pos1.y, pos2.y), math.min(pos1.z, pos2.z))
	local maxp = vector.new(math.max(pos1.x, pos2.x), math.max(pos1.y, pos2.y), math.max(pos1.z, pos2.z))

	local ops = 0
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local column = {}
			for y = minp.y, maxp.y do
				column[#column + 1] = core.get_node({ x = x, y = y, z = z })
				core.remove_node({ x = x, y = y, z = z })
			end
			for idx, node in ipairs(column) do
				local y = minp.y + idx - 1 + delta
				core.set_node({ x = x, y = y, z = z }, node)
				ops = ops + 1
			end
		end
	end
	return ops
end

core.register_chatcommand("dnd3_map_fill", {
	params = "<x1> <y1> <z1> <x2> <y2> <z2> <nodename>",
	description = "Fill an area with a node",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "You are not allowed to edit the map"
		end
		local x1, y1, z1, x2, y2, z2, node =
			param:match("^(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%S+)$")
		if not node then
			return false, "Usage: /dnd3_map_fill <x1> <y1> <z1> <x2> <y2> <z2> <nodename>"
		end

		local count, err = dnd3.map_fill(
			{ x = tonumber(x1), y = tonumber(y1), z = tonumber(z1) },
			{ x = tonumber(x2), y = tonumber(y2), z = tonumber(z2) },
			node
		)
		if not count then
			return false, err
		end
		return true, "Filled " .. count .. " nodes"
	end,
})

core.register_chatcommand("dnd3_map_raise", {
	params = "<x1> <y1> <z1> <x2> <y2> <z2> <delta>",
	description = "Raise or lower columns in an area by delta",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "You are not allowed to edit the map"
		end
		local x1, y1, z1, x2, y2, z2, delta =
			param:match("^(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)$")
		if not delta then
			return false, "Usage: /dnd3_map_raise <x1> <y1> <z1> <x2> <y2> <z2> <delta>"
		end

		local moved, err = dnd3.map_raise(
			{ x = tonumber(x1), y = tonumber(y1), z = tonumber(z1) },
			{ x = tonumber(x2), y = tonumber(y2), z = tonumber(z2) },
			tonumber(delta)
		)
		if not moved then
			return false, err
		end
		return true, "Shifted " .. moved .. " nodes"
	end,
})
