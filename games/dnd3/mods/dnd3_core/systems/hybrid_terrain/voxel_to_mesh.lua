local HT = dnd3.hybrid_terrain

dnd3._state.hybrid_mesh_cache = dnd3._state.hybrid_mesh_cache or {}

local AIR = core.get_content_id("air")
local IGNORE = core.get_content_id("ignore")

local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function normalize_box(pos1, pos2)
	local minp = vector.round(pos1)
	local maxp = vector.round(pos2)
	if minp.x > maxp.x then minp.x, maxp.x = maxp.x, minp.x end
	if minp.y > maxp.y then minp.y, maxp.y = maxp.y, minp.y end
	if minp.z > maxp.z then minp.z, maxp.z = maxp.z, minp.z end
	return minp, maxp
end

local function chunk_key(minp, maxp)
	return table.concat({ minp.x, minp.y, minp.z, maxp.x, maxp.y, maxp.z }, ":")
end

local function is_solid_cid(cid)
	if cid == AIR or cid == IGNORE then
		return false
	end
	local name = core.get_name_from_content_id(cid)
	local def = name and core.registered_nodes[name]
	return def and def.walkable
end

local function add_quad(out, axis, x, y, z, nx, ny, nz, node_name)
	out[#out + 1] = {
		axis = axis,
		origin = { x = x, y = y, z = z },
		normal = { x = nx, y = ny, z = nz },
		node = node_name,
	}
end

-- Produces a lightweight exposed-face descriptor from voxels.
-- This is phase-1 data for later mesh baking / GPU upload.
function HT.voxel_to_mesh_descriptor(pos1, pos2, opts)
	opts = opts or {}
	if not HT.enabled() then
		return nil, "hybrid terrain disabled"
	end

	local minp, maxp = normalize_box(pos1, pos2)
	local key = chunk_key(minp, maxp)
	local cached = dnd3._state.hybrid_mesh_cache[key]
	if cached and not opts.force then
		return cached
	end

	local vm = VoxelManip()
	local emin, emax = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })
	local data = vm:get_data()

	local descriptor = {
		bounds = { min = minp, max = maxp },
		generated_at = os.time(),
		quads = {},
		nodes_processed = 0,
		exposed_faces = 0,
	}

	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			for x = minp.x, maxp.x do
				local vi = area:index(x, y, z)
				local cid = data[vi]
				if is_solid_cid(cid) then
					descriptor.nodes_processed = descriptor.nodes_processed + 1
					local node_name = core.get_name_from_content_id(cid)

					local function exposed(nx, ny, nz)
						local nvi = area:index(x + nx, y + ny, z + nz)
						return not is_solid_cid(data[nvi])
					end

					if exposed(0, 1, 0) then
						add_quad(descriptor.quads, "top", x, y + 0.5, z, 0, 1, 0, node_name)
						descriptor.exposed_faces = descriptor.exposed_faces + 1
					end
					if exposed(0, -1, 0) then
						add_quad(descriptor.quads, "bottom", x, y - 0.5, z, 0, -1, 0, node_name)
						descriptor.exposed_faces = descriptor.exposed_faces + 1
					end
					if exposed(1, 0, 0) then
						add_quad(descriptor.quads, "east", x + 0.5, y, z, 1, 0, 0, node_name)
						descriptor.exposed_faces = descriptor.exposed_faces + 1
					end
					if exposed(-1, 0, 0) then
						add_quad(descriptor.quads, "west", x - 0.5, y, z, -1, 0, 0, node_name)
						descriptor.exposed_faces = descriptor.exposed_faces + 1
					end
					if exposed(0, 0, 1) then
						add_quad(descriptor.quads, "south", x, y, z + 0.5, 0, 0, 1, node_name)
						descriptor.exposed_faces = descriptor.exposed_faces + 1
					end
					if exposed(0, 0, -1) then
						add_quad(descriptor.quads, "north", x, y, z - 0.5, 0, 0, -1, node_name)
						descriptor.exposed_faces = descriptor.exposed_faces + 1
					end
				end
			end
		end
	end

	dnd3._state.hybrid_mesh_cache[key] = descriptor
	return descriptor
end

function HT.clear_mesh_cache()
	dnd3._state.hybrid_mesh_cache = {}
end

core.register_chatcommand("dnd3_hybrid_bake", {
	params = "<radius>",
	description = "Bake a hybrid mesh descriptor around player (GM)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end

		local player = core.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end

		local radius = clamp(math.floor(tonumber(param) or 16), 4, 64)
		local p = vector.round(player:get_pos())
		local minp = { x = p.x - radius, y = p.y - 16, z = p.z - radius }
		local maxp = { x = p.x + radius, y = p.y + 16, z = p.z + radius }
		local descriptor, err = HT.voxel_to_mesh_descriptor(minp, maxp, { force = true })
		if not descriptor then
			return false, tostring(err)
		end

		return true, string.format(
			"Hybrid bake complete: nodes=%d, exposed_faces=%d, quads=%d",
			descriptor.nodes_processed,
			descriptor.exposed_faces,
			#descriptor.quads
		)
	end,
})
