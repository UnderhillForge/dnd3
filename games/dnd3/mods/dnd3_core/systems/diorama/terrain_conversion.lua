local D = dnd3.diorama

local AIR = core.get_content_id("air")
local IGNORE = core.get_content_id("ignore")
local CHUNK_SIZE = 16
local GRID_SCALE = 5 -- 1 tactical cell = 5 nodes (kept canonical)

local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function round_pos(p)
	return {
		x = math.floor(p.x + 0.5),
		y = math.floor(p.y + 0.5),
		z = math.floor(p.z + 0.5),
	}
end

local function floor_to_chunk(v)
	return math.floor(v / CHUNK_SIZE) * CHUNK_SIZE
end

local function chunk_key(minp)
	return string.format("%d:%d:%d", minp.x, minp.y, minp.z)
end

local function is_solid_cid(cid)
	if cid == AIR or cid == IGNORE then
		return false
	end
	local name = core.get_name_from_content_id(cid)
	local def = name and core.registered_nodes[name]
	if not def then
		return false
	end
	if def.walkable ~= true then
		return false
	end
	if def.liquidtype and def.liquidtype ~= "none" then
		return false
	end
	return true
end

local function sample_surface_height(x, z, min_y, max_y)
	local vm = VoxelManip()
	local minp = { x = x, y = min_y, z = z }
	local maxp = { x = x, y = max_y, z = z }
	local emin, emax = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })
	local data = vm:get_data()

	for y = max_y, min_y, -1 do
		local vi = area:index(x, y, z)
		if is_solid_cid(data[vi]) then
			return y
		end
	end
	return nil
end

local function build_heightmap(minp, maxp)
	local hm = {}
	for z = minp.z, maxp.z do
		hm[z] = {}
		for x = minp.x, maxp.x do
			hm[z][x] = sample_surface_height(x, z, minp.y, maxp.y)
		end
	end
	return hm
end

local function classify_slope(hm, x, z, max_step)
	local h = hm[z][x]
	if not h then
		return nil
	end
	local n = hm[z - 1] and hm[z - 1][x]
	local s = hm[z + 1] and hm[z + 1][x]
	local e = hm[z][x + 1]
	local w = hm[z][x - 1]
	if not (n and s and e and w) then
		return nil
	end

	local dn = n - h
	local ds = s - h
	local de = e - h
	local dw = w - h

	local function gentle(d)
		return d > 0 and d <= max_step
	end

	if gentle(dn) and ds <= 0 and de <= 0 and dw <= 0 then
		return "north"
	end
	if gentle(ds) and dn <= 0 and de <= 0 and dw <= 0 then
		return "south"
	end
	if gentle(de) and dn <= 0 and ds <= 0 and dw <= 0 then
		return "east"
	end
	if gentle(dw) and dn <= 0 and ds <= 0 and de <= 0 then
		return "west"
	end
	return nil
end

local function classify_bevel(hm, x, z)
	local h = hm[z][x]
	if not h then
		return nil
	end
	local n = hm[z - 1] and hm[z - 1][x]
	local s = hm[z + 1] and hm[z + 1][x]
	local e = hm[z][x + 1]
	local w = hm[z][x - 1]
	if not (n and s and e and w) then
		return nil
	end

	-- Simple chamfer candidates at convex corners (basic bevel pass).
	if n < h and w < h then return "nw" end
	if n < h and e < h then return "ne" end
	if s < h and w < h then return "sw" end
	if s < h and e < h then return "se" end
	return nil
end

function D.convert_region(pos1, pos2, opts)
	opts = opts or {}
	if not D.enabled() then
		return nil, "diorama disabled"
	end

	local minp = round_pos(pos1)
	local maxp = round_pos(pos2)
	if minp.x > maxp.x then minp.x, maxp.x = maxp.x, minp.x end
	if minp.y > maxp.y then minp.y, maxp.y = maxp.y, minp.y end
	if minp.z > maxp.z then minp.z, maxp.z = maxp.z, minp.z end

	local max_step = clamp(math.floor(tonumber(opts.max_slope_step) or D.get_number("max_slope_step", 1)), 1, 2)
	local hm = build_heightmap(minp, maxp)

	local slopes = {}
	local bevels = {}
	for z = minp.z + 1, maxp.z - 1 do
		for x = minp.x + 1, maxp.x - 1 do
			local y = hm[z][x]
			if y then
				local slope = classify_slope(hm, x, z, max_step)
				if slope then
					slopes[#slopes + 1] = { x = x, y = y, z = z, dir = slope }
				else
					local bevel = classify_bevel(hm, x, z)
					if bevel then
						bevels[#bevels + 1] = { x = x, y = y, z = z, corner = bevel }
					end
				end
			end
		end
	end

	return {
		bounds = { min = minp, max = maxp },
		surface_heightmap = hm,
		slopes = slopes,
		bevels = bevels,
		summary = {
			slope_count = #slopes,
			bevel_count = #bevels,
		},
	}
end

function D.convert_chunk(anchor)
	local base = {
		x = floor_to_chunk(anchor.x),
		y = floor_to_chunk(anchor.y),
		z = floor_to_chunk(anchor.z),
	}
	local minp = { x = base.x, y = base.y, z = base.z }
	local maxp = { x = base.x + CHUNK_SIZE - 1, y = base.y + CHUNK_SIZE - 1, z = base.z + CHUNK_SIZE - 1 }
	local descriptor, err = D.convert_region(minp, maxp)
	if not descriptor then
		return nil, err
	end

	local key = chunk_key(base)
	dnd3._state.diorama.chunk_cache[key] = descriptor
	dnd3._state.diorama.converted_chunks[key] = os.time()
	return descriptor
end

-- Optional helper for movement smoothing while preserving tactical grid logic.
-- This nudges player up by <= 1 node when walking into a gentle rise.
local function smooth_step_player(player, dtime)
	if not D.get_bool("smooth_movement", true) then
		return
	end

	local vel = player:get_velocity()
	local horiz = vector.new(vel.x, 0, vel.z)
	if vector.length(horiz) < 0.05 then
		return
	end

	local dir = vector.normalize(horiz)
	local pos = player:get_pos()
	local foot = { x = math.floor(pos.x + dir.x + 0.5), y = math.floor(pos.y - 1.1), z = math.floor(pos.z + dir.z + 0.5) }
	local head = { x = foot.x, y = foot.y + 1, z = foot.z }
	local up = { x = foot.x, y = foot.y + 1, z = foot.z }

	local foot_node = core.get_node(foot).name
	local head_node = core.get_node(head).name
	local up_node = core.get_node(up).name

	local foot_def = core.registered_nodes[foot_node]
	local head_def = core.registered_nodes[head_node]
	local up_def = core.registered_nodes[up_node]

	if foot_def and foot_def.walkable and head_def and not head_def.walkable and up_def and not up_def.walkable then
		local rise = D.get_number("smooth_max_step", 1.0)
		if rise > 0 then
			player:set_pos({ x = pos.x, y = pos.y + math.min(rise, 0.08), z = pos.z })
		end
	end
end

core.register_globalstep(function(dtime)
	if not D.enabled() then
		return
	end
	for _, player in ipairs(core.get_connected_players()) do
		smooth_step_player(player, dtime)
	end
end)

core.register_on_generated(function(minp, maxp, blockseed)
	if not D.enabled() then
		return
	end
	D.convert_chunk(minp)
end)

local function schedule_reconvert(pos)
	if not D.enabled() then
		return
	end
	core.after(0.1, function()
		D.convert_chunk(pos)
	end)
end

core.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	schedule_reconvert(pos)
end)

core.register_on_dignode(function(pos, oldnode, digger)
	schedule_reconvert(pos)
end)

core.register_chatcommand("dnd3_diorama_convert", {
	params = "<radius>",
	description = "Convert area into diorama descriptors (slope + bevel analysis) (GM)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end

		local r = clamp(math.floor(tonumber(param) or 20), 4, 96)
		local p = round_pos(player:get_pos())
		local desc, err = D.convert_region(
			{ x = p.x - r, y = p.y - 8, z = p.z - r },
			{ x = p.x + r, y = p.y + 8, z = p.z + r }
		)
		if not desc then
			return false, tostring(err)
		end

		return true, string.format(
			"Diorama conversion complete: slopes=%d, bevels=%d",
			desc.summary.slope_count,
			desc.summary.bevel_count
		)
	end,
})

core.register_chatcommand("dnd3_diorama_debug_chunk", {
	params = "",
	description = "Print current chunk diorama descriptor summary (GM)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end
		local p = round_pos(player:get_pos())
		local base = { x = floor_to_chunk(p.x), y = floor_to_chunk(p.y), z = floor_to_chunk(p.z) }
		local key = chunk_key(base)
		local c = dnd3._state.diorama.chunk_cache[key]
		if not c then
			return false, "No diorama descriptor cached for this chunk yet."
		end
		return true, string.format("Chunk %s slopes=%d bevels=%d", key, c.summary.slope_count, c.summary.bevel_count)
	end,
})

-- Utility API for tactical alignment: preserve 5-ft grid while allowing smooth visuals.
function D.snap_world_to_tactical_grid(pos)
	return {
		x = math.floor((pos.x / GRID_SCALE) + 0.5) * GRID_SCALE,
		y = pos.y,
		z = math.floor((pos.z / GRID_SCALE) + 0.5) * GRID_SCALE,
	}
end
