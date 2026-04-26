local HT = dnd3.hybrid_terrain

local AIR = core.get_content_id("air")
local IGNORE = core.get_content_id("ignore")

local function is_walkable_cid(cid)
	if cid == AIR or cid == IGNORE then
		return false
	end
	local name = core.get_name_from_content_id(cid)
	local def = name and core.registered_nodes[name]
	return def and def.walkable and not def.liquidtype
end

local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function normalize_pos(p)
	return {
		x = math.floor(p.x + 0.5),
		y = math.floor(p.y + 0.5),
		z = math.floor(p.z + 0.5),
	}
end

function HT.get_surface_height(x, z, min_y, max_y)
	local minp = { x = x, y = min_y, z = z }
	local maxp = { x = x, y = max_y, z = z }
	local vm = VoxelManip()
	local emin, emax = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })
	local data = vm:get_data()

	for y = max_y, min_y, -1 do
		local vi = area:index(x, y, z)
		if is_walkable_cid(data[vi]) then
			return y
		end
	end
	return nil
end

local function build_heightmap(minp, maxp)
	local heights = {}
	for z = minp.z, maxp.z do
		heights[z] = {}
		for x = minp.x, maxp.x do
			heights[z][x] = HT.get_surface_height(x, z, minp.y, maxp.y)
		end
	end
	return heights
end

local function classify_ramp(heights, x, z, max_step)
	local h = heights[z][x]
	if not h then
		return nil
	end

	local e = heights[z][x + 1]
	local w = heights[z][x - 1]
	local n = heights[z - 1] and heights[z - 1][x]
	local s = heights[z + 1] and heights[z + 1][x]
	if not (e and w and n and s) then
		return nil
	end

	local de = e - h
	local dw = w - h
	local dn = n - h
	local ds = s - h

	local function gentle(delta)
		return delta >= 0 and delta <= max_step
	end

	if gentle(de) and dw <= 0 and dn <= 0 and ds <= 0 and de > 0 then
		return 1 -- ascending east
	end
	if gentle(dw) and de <= 0 and dn <= 0 and ds <= 0 and dw > 0 then
		return 3 -- ascending west
	end
	if gentle(ds) and de <= 0 and dn <= 0 and dw <= 0 and ds > 0 then
		return 2 -- ascending south
	end
	if gentle(dn) and de <= 0 and ds <= 0 and dw <= 0 and dn > 0 then
		return 0 -- ascending north
	end
	return nil
end

-- Simple stepped wedge used as a runtime visual slope primitive.
core.register_node("dnd3:slope_ramp", {
	description = "dnd3 Hybrid Slope Ramp",
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	use_texture_alpha = "clip",
	groups = { cracky = 1, oddly_breakable_by_hand = 1, dnd3_hybrid = 1 },
	tiles = { "unknown_node.png" },
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, -0.5, 0.5, -0.375, -0.375 },
			{ -0.5, -0.5, -0.375, 0.5, -0.25, -0.25 },
			{ -0.5, -0.5, -0.25, 0.5, -0.125, -0.125 },
			{ -0.5, -0.5, -0.125, 0.5, 0.0, 0.0 },
			{ -0.5, -0.5, 0.0, 0.5, 0.125, 0.125 },
			{ -0.5, -0.5, 0.125, 0.5, 0.25, 0.25 },
			{ -0.5, -0.5, 0.25, 0.5, 0.375, 0.375 },
			{ -0.5, -0.5, 0.375, 0.5, 0.5, 0.5 },
		},
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, -0.5, 0.5, -0.375, -0.375 },
			{ -0.5, -0.5, -0.375, 0.5, -0.25, -0.25 },
			{ -0.5, -0.5, -0.25, 0.5, -0.125, -0.125 },
			{ -0.5, -0.5, -0.125, 0.5, 0.0, 0.0 },
			{ -0.5, -0.5, 0.0, 0.5, 0.125, 0.125 },
			{ -0.5, -0.5, 0.125, 0.5, 0.25, 0.25 },
			{ -0.5, -0.5, 0.25, 0.5, 0.375, 0.375 },
			{ -0.5, -0.5, 0.375, 0.5, 0.5, 0.5 },
		},
	},
})

function HT.generate_slopes(pos1, pos2, opts)
	if not HT.enabled() then
		return 0, "hybrid terrain disabled"
	end

	opts = opts or {}
	local minp = normalize_pos(pos1)
	local maxp = normalize_pos(pos2)
	if minp.x > maxp.x then minp.x, maxp.x = maxp.x, minp.x end
	if minp.y > maxp.y then minp.y, maxp.y = maxp.y, minp.y end
	if minp.z > maxp.z then minp.z, maxp.z = maxp.z, minp.z end

	local max_step = clamp(math.floor(tonumber(opts.max_step) or HT.get_number("max_slope_step", 1)), 1, 2)
	local heights = build_heightmap(minp, maxp)
	local placed = 0

	for z = minp.z + 1, maxp.z - 1 do
		for x = minp.x + 1, maxp.x - 1 do
			local h = heights[z][x]
			if h and h >= minp.y and h <= maxp.y then
				local facedir = classify_ramp(heights, x, z, max_step)
				if facedir then
					local top = { x = x, y = h + 1, z = z }
					if core.get_node(top).name == "air" then
						core.set_node({ x = x, y = h, z = z }, {
							name = "dnd3:slope_ramp",
							param2 = facedir,
						})
						placed = placed + 1
					end
				end
			end
		end
	end

	return placed
end

core.register_chatcommand("dnd3_hybrid_slopes", {
	params = "<radius>",
	description = "Generate basic slope ramps in an area around player (GM)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end

		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end

		local radius = clamp(math.floor(tonumber(param) or 12), 2, 64)
		local p = vector.round(player:get_pos())
		local pos1 = { x = p.x - radius, y = p.y - 8, z = p.z - radius }
		local pos2 = { x = p.x + radius, y = p.y + 8, z = p.z + radius }
		local count, err = HT.generate_slopes(pos1, pos2)
		if not count then
			return false, tostring(err)
		end
		return true, string.format("Hybrid slopes generated: %d", count)
	end,
})
