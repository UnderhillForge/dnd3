local HT = dnd3.hybrid_terrain

local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function key(x, z)
	return x .. ":" .. z
end

local function parse_key(k)
	local x, z = k:match("^(%-?%d+):(%-?%d+)$")
	return tonumber(x), tonumber(z)
end

-- Build a lightweight 2D navmesh from voxel surface heights.
-- Walkability is controlled by max_slope_step (node height delta).
function HT.build_navmesh(pos1, pos2, opts)
	opts = opts or {}
	if not HT.enabled() then
		return nil, "hybrid terrain disabled"
	end

	local minp = vector.round(pos1)
	local maxp = vector.round(pos2)
	if minp.x > maxp.x then minp.x, maxp.x = maxp.x, minp.x end
	if minp.y > maxp.y then minp.y, maxp.y = maxp.y, minp.y end
	if minp.z > maxp.z then minp.z, maxp.z = maxp.z, minp.z end

	local max_step = clamp(math.floor(tonumber(opts.max_step) or HT.get_number("max_slope_step", 1)), 1, 2)
	local nodes = {}

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local y = HT.get_surface_height(x, z, minp.y, maxp.y)
			if y then
				nodes[key(x, z)] = {
					x = x,
					y = y,
					z = z,
					neighbors = {},
				}
			end
		end
	end

	local dirs = {
		{ 1, 0 },
		{ -1, 0 },
		{ 0, 1 },
		{ 0, -1 },
	}

	for k, n in pairs(nodes) do
		for _, d in ipairs(dirs) do
			local nk = key(n.x + d[1], n.z + d[2])
			local nn = nodes[nk]
			if nn and math.abs(nn.y - n.y) <= max_step then
				n.neighbors[#n.neighbors + 1] = nk
			end
		end
	end

	return {
		bounds = { min = minp, max = maxp },
		max_step = max_step,
		nodes = nodes,
	}
end

local function heuristic(a, b)
	return math.abs(a.x - b.x) + math.abs(a.z - b.z)
end

function HT.find_path(navmesh, start_pos, goal_pos)
	if not navmesh then
		return nil, "navmesh required"
	end

	local sx = math.floor(start_pos.x + 0.5)
	local sz = math.floor(start_pos.z + 0.5)
	local gx = math.floor(goal_pos.x + 0.5)
	local gz = math.floor(goal_pos.z + 0.5)
	local start_k = key(sx, sz)
	local goal_k = key(gx, gz)

	if not navmesh.nodes[start_k] then
		return nil, "start not on navmesh"
	end
	if not navmesh.nodes[goal_k] then
		return nil, "goal not on navmesh"
	end

	local open = { [start_k] = true }
	local came_from = {}
	local g_score = { [start_k] = 0 }
	local f_score = {
		[start_k] = heuristic(navmesh.nodes[start_k], navmesh.nodes[goal_k]),
	}

	local function pop_lowest_f()
		local best_k, best_f
		for k in pairs(open) do
			local f = f_score[k] or math.huge
			if not best_f or f < best_f then
				best_f = f
				best_k = k
			end
		end
		if best_k then
			open[best_k] = nil
		end
		return best_k
	end

	while true do
		local current = pop_lowest_f()
		if not current then
			break
		end
		if current == goal_k then
			local path = {}
			local c = current
			while c do
				local x, z = parse_key(c)
				local nn = navmesh.nodes[c]
				path[#path + 1] = { x = x, y = nn.y + 1, z = z }
				c = came_from[c]
			end
			for i = 1, math.floor(#path / 2) do
				path[i], path[#path - i + 1] = path[#path - i + 1], path[i]
			end
			return path
		end

		local cur_node = navmesh.nodes[current]
		for _, nk in ipairs(cur_node.neighbors) do
			local tentative = (g_score[current] or math.huge) + 1
			if tentative < (g_score[nk] or math.huge) then
				came_from[nk] = current
				g_score[nk] = tentative
				f_score[nk] = tentative + heuristic(navmesh.nodes[nk], navmesh.nodes[goal_k])
				open[nk] = true
			end
		end
	end

	return nil, "no path"
end

core.register_chatcommand("dnd3_hybrid_navmesh", {
	params = "<radius>",
	description = "Build a hybrid navmesh around player and report walkable cells (GM)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end

		local radius = clamp(math.floor(tonumber(param) or 20), 4, 96)
		local p = vector.round(player:get_pos())
		local navmesh, err = HT.build_navmesh(
			{ x = p.x - radius, y = p.y - 8, z = p.z - radius },
			{ x = p.x + radius, y = p.y + 8, z = p.z + radius }
		)
		if not navmesh then
			return false, tostring(err)
		end

		local count = 0
		for _ in pairs(navmesh.nodes) do
			count = count + 1
		end
		dnd3._state.hybrid_navmesh = navmesh
		return true, string.format("Hybrid navmesh built: %d walkable cells", count)
	end,
})

core.register_chatcommand("dnd3_hybrid_path", {
	params = "<x> <z>",
	description = "Find A* path on cached hybrid navmesh from player to <x z> (GM)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local x, z = param:match("^(%-?%d+)%s+(%-?%d+)$")
		if not x then
			return false, "Usage: /dnd3_hybrid_path <x> <z>"
		end
		local navmesh = dnd3._state.hybrid_navmesh
		if not navmesh then
			return false, "No navmesh cache. Run /dnd3_hybrid_navmesh first."
		end
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end

		local path, err = HT.find_path(navmesh, player:get_pos(), { x = tonumber(x), z = tonumber(z) })
		if not path then
			return false, tostring(err)
		end
		return true, string.format("Hybrid path found: %d waypoints", #path)
	end,
})
