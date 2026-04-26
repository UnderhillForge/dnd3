local storage = core.get_mod_storage()
local prefabs_blob = storage:get_string("prefabs")

local prefabs = {}
if prefabs_blob and prefabs_blob ~= "" then
	local parsed = core.parse_json(prefabs_blob)
	if type(parsed) == "table" then
		prefabs = parsed
	end
end

local function persist_prefabs()
	storage:set_string("prefabs", core.write_json(prefabs))
end

-- ── Entity-visual template registry ───────────────────────────────────────
-- register_prefab stores mesh/texture/animation templates for diorama entities.
-- Templates are keyed by a sanitised form of def.name and are NOT persisted to
-- mod_storage – they reload from prefab definition files on each server start.

local prefab_defs = {}

local function name_to_id(name)
	return tostring(name or ""):lower():gsub("%s+", "_"):gsub("[^%w_]", "")
end

--- Register an entity-visual template.
--- def fields:
---   name (required)  – human-readable name; also forms the lookup key
---   type             – "prop" | "monster" | "npc"  (default "prop")
---   tags             – list of string tags
---   mesh             – .glb/.x/.obj filename (looked up in media paths)
---   textures         – ordered list of texture filenames
---   visual_scale     – uniform scale factor (default 1.0)
---   collision_box    – {xmin,ymin,zmin,xmax,ymax,zmax}
---   animation        – map of name → {start,stop[,speed]}
---   bevel            – boolean rendering hint
---   wind_sway        – if true and animation.sway exists, loops it on spawn
function dnd3.register_prefab(def)
	assert(type(def) == "table", "[dnd3] register_prefab: def must be a table")
	assert(type(def.name) == "string" and def.name ~= "", "[dnd3] register_prefab: name required")
	-- Allow caller to supply an explicit id; otherwise derive from name.
	local id = (type(def.id) == "string" and def.id ~= "") and def.id or name_to_id(def.name)
	prefab_defs[id] = {
		id            = id,
		name          = def.name,
		type          = def.type          or "prop",
		tags          = def.tags          or {},
		mesh          = def.mesh,
		textures      = def.textures      or {},
		visual_scale  = tonumber(def.visual_scale) or 1.0,
		collision_box = def.collision_box,
		animation     = def.animation,
		bevel         = def.bevel         or false,
		wind_sway     = def.wind_sway     or false,
	}
	return prefab_defs[id]
end

--- Retrieve an entity-visual template by name or sanitised id.
function dnd3.prefab_def_get(id_or_name)
	local id = name_to_id(tostring(id_or_name or ""))
	return prefab_defs[id]
end

--- List all registered entity-visual template ids.
function dnd3.prefab_def_list()
	local out = {}
	for id in pairs(prefab_defs) do out[#out + 1] = id end
	table.sort(out)
	return out
end

-- ── Node-layout blueprint registry ─────────────────────────────────────────
-- Register a static (design-time) prefab from a definition table.
-- def = { size={x,y,z}, nodes=[{rel={x,y,z}, node={name,param1,param2}}, ...] }
-- Static prefabs are not persisted to mod_storage; they reload from files on each start.
function dnd3.register_static_prefab(id, def)
	assert(type(id) == "string" and id ~= "", "[dnd3] register_static_prefab: id required")
	assert(type(def) == "table", "[dnd3] register_static_prefab: def must be a table")
	prefabs[id] = {
		id     = id,
		size   = def.size   or { x = 1, y = 1, z = 1 },
		nodes  = def.nodes  or {},
		static = true,
	}
end

local function pos_key(pos)
	return string.format("%d,%d,%d", pos.x, pos.y, pos.z)
end

function dnd3.prefab_capture(id, minp, maxp)
	if type(id) ~= "string" or id == "" then
		return nil, "prefab id is required"
	end

	local nodes = {}
	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			for x = minp.x, maxp.x do
				local pos = { x = x, y = y, z = z }
				nodes[#nodes + 1] = {
					rel = { x = x - minp.x, y = y - minp.y, z = z - minp.z },
					node = core.get_node(pos),
				}
			end
		end
	end

	prefabs[id] = {
		id = id,
		size = {
			x = maxp.x - minp.x + 1,
			y = maxp.y - minp.y + 1,
			z = maxp.z - minp.z + 1,
		},
		nodes = nodes,
	}
	persist_prefabs()
	return prefabs[id]
end

function dnd3.prefab_stamp(id, origin)
	local prefab = prefabs[id]
	if not prefab then
		return nil, "unknown prefab"
	end

	for _, entry in ipairs(prefab.nodes) do
		local p = {
			x = origin.x + entry.rel.x,
			y = origin.y + entry.rel.y,
			z = origin.z + entry.rel.z,
		}
		core.set_node(p, entry.node)
	end
	return true
end

function dnd3.prefab_list()
	local out = {}
	for id in pairs(prefabs) do
		out[#out + 1] = id
	end
	table.sort(out)
	return out
end

core.register_chatcommand("dnd3_prefab_capture", {
	params = "<id> <x1> <y1> <z1> <x2> <y2> <z2>",
	description = "Capture a map area as a prefab",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "You are not allowed to edit the map"
		end
		local id, x1, y1, z1, x2, y2, z2 =
			param:match("^(%S+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)$")
		if not id then
			return false, "Usage: /dnd3_prefab_capture <id> <x1> <y1> <z1> <x2> <y2> <z2>"
		end
		local minp = {
			x = math.min(tonumber(x1), tonumber(x2)),
			y = math.min(tonumber(y1), tonumber(y2)),
			z = math.min(tonumber(z1), tonumber(z2)),
		}
		local maxp = {
			x = math.max(tonumber(x1), tonumber(x2)),
			y = math.max(tonumber(y1), tonumber(y2)),
			z = math.max(tonumber(z1), tonumber(z2)),
		}
		local prefab, err = dnd3.prefab_capture(id, minp, maxp)
		if not prefab then
			return false, err
		end
		return true, "Captured prefab " .. prefab.id .. " with " .. #prefab.nodes .. " nodes"
	end,
})

core.register_chatcommand("dnd3_prefab_stamp", {
	params = "<id> <x> <y> <z>",
	description = "Stamp a prefab at origin",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "You are not allowed to edit the map"
		end
		local id, x, y, z = param:match("^(%S+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)$")
		if not id then
			return false, "Usage: /dnd3_prefab_stamp <id> <x> <y> <z>"
		end
		local ok, err = dnd3.prefab_stamp(id, { x = tonumber(x), y = tonumber(y), z = tonumber(z) })
		if not ok then
			return false, err
		end
		return true, "Prefab stamped: " .. id
	end,
})

core.register_chatcommand("dnd3_prefab_list", {
	description = "List prefab ids",
	func = function()
		local list = dnd3.prefab_list()
		if #list == 0 then
			return true, "No prefabs"
		end
		return true, "Prefabs: " .. table.concat(list, ", ")
	end,
})
