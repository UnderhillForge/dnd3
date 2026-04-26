-- systems/diorama_studio/tools.lua  (Phase 1 – fully working)
-- Four physical in-hand tools registered as Luanti tools:
--   dnd3:studio_add_tool     – left-click to place vox node
--   dnd3:studio_remove_tool  – left-click to erase vox node
--   dnd3:studio_paint_tool   – left-click to repaint vox node
--   dnd3:studio_select_tool  – click A then B to select a box; /studio_move to shift it
--
-- All tools respect session.brush_radius and session.paint_node.
-- Editing is restricted to dnd3_vox-group nodes so world cannot be damaged.

local Studio = dnd3.diorama_studio

-- ── Session helpers ─────────────────────────────────────────────────────────

local function get_session(name)
	return Studio.sessions[name]
end

local function can_edit(name)
	return dnd3.can and dnd3.can(name, "map_edit")
end

local function require_session(user)
	if not user then return nil, "user missing" end
	local name = user:get_player_name()
	if not can_edit(name) then return nil, "Permission denied (requires GM role)." end
	local s = get_session(name)
	if not s or not s.active then
		return nil, "Studio not active. Use /studio first."
	end
	return s, name
end

-- ── Vox helpers ─────────────────────────────────────────────────────────────

local function is_editable(nodename)
	if not nodename then return false end
	if nodename == "air" then return true end
	local def = core.registered_nodes[nodename]
	if not def then return false end
	return def.groups and (def.groups.dnd3_vox ~= nil)
end

local function resolve_paint_node(s)
	local raw = s.paint_node or "stone"
	local from_palette = dnd3.studio_palette_node and dnd3.studio_palette_node(raw)
	if from_palette then return from_palette end
	if core.registered_nodes[raw] then return raw end
	return "dnd3:vox_stone"
end

local function mark_dirty(pos)
	if dnd3.studio_canvas_dirty then dnd3.studio_canvas_dirty(pos) end
end

-- ── Brush helper ─────────────────────────────────────────────────────────────

local function each_in_radius(center, r, fn)
	for dx = -r, r do
		for dy = -r, r do
			for dz = -r, r do
				if math.abs(dx) + math.abs(dy) + math.abs(dz) <= r then
					fn({ x = center.x + dx, y = center.y + dy, z = center.z + dz })
				end
			end
		end
	end
end

-- ── ADD tool ─────────────────────────────────────────────────────────────────

local function on_use_add(itemstack, user, pointed_thing)
	local s, name = require_session(user)
	if not s then core.chat_send_player(user:get_player_name(), "[studio] " .. name); return itemstack end
	if not pointed_thing or pointed_thing.type ~= "node" then return itemstack end
	local node_name = resolve_paint_node(s)
	local r = math.max(0, (s.brush_radius or 1) - 1)
	each_in_radius(pointed_thing.above, r, function(p)
		core.set_node(p, { name = node_name })
		mark_dirty(p)
	end)
	return itemstack
end

core.register_tool("dnd3:studio_add_tool", {
	description = "Studio Add Tool – left-click surface to place voxel",
	inventory_image = "[fill:16x16:#55ff55",
	on_use           = on_use_add,
	on_secondary_use = on_use_add,
})

-- ── REMOVE tool ──────────────────────────────────────────────────────────────

local function on_use_remove(itemstack, user, pointed_thing)
	local s, name = require_session(user)
	if not s then core.chat_send_player(user:get_player_name(), "[studio] " .. name); return itemstack end
	if not pointed_thing or pointed_thing.type ~= "node" then return itemstack end
	local target = pointed_thing.under
	if not is_editable(core.get_node(target).name) then
		core.chat_send_player(user:get_player_name(), "[studio] Only dnd3 vox nodes can be removed.")
		return itemstack
	end
	local r = math.max(0, (s.brush_radius or 1) - 1)
	each_in_radius(target, r, function(p)
		local n = core.get_node(p).name
		if is_editable(n) and n ~= "air" then
			core.remove_node(p)
			mark_dirty(p)
		end
	end)
	return itemstack
end

core.register_tool("dnd3:studio_remove_tool", {
	description = "Studio Remove Tool – left-click voxel to erase",
	inventory_image = "[fill:16x16:#ff5555",
	on_use           = on_use_remove,
	on_secondary_use = on_use_remove,
})

-- ── PAINT tool ────────────────────────────────────────────────────────────────

local function on_use_paint(itemstack, user, pointed_thing)
	local s, name = require_session(user)
	if not s then core.chat_send_player(user:get_player_name(), "[studio] " .. name); return itemstack end
	if not pointed_thing or pointed_thing.type ~= "node" then return itemstack end
	local target = pointed_thing.under
	if not is_editable(core.get_node(target).name) then
		core.chat_send_player(user:get_player_name(), "[studio] Only dnd3 vox nodes can be painted.")
		return itemstack
	end
	local node_name = resolve_paint_node(s)
	local r = math.max(0, (s.brush_radius or 1) - 1)
	each_in_radius(target, r, function(p)
		local n = core.get_node(p).name
		if is_editable(n) and n ~= "air" then
			core.set_node(p, { name = node_name })
			mark_dirty(p)
		end
	end)
	return itemstack
end

core.register_tool("dnd3:studio_paint_tool", {
	description = "Studio Paint Tool – left-click voxel to repaint",
	inventory_image = "[fill:16x16:#5599ff",
	on_use           = on_use_paint,
	on_secondary_use = on_use_paint,
})

-- ── SELECT tool ───────────────────────────────────────────────────────────────
-- First click  → corner A
-- Second click → corner B  (completes selection, shows bounds)
-- Right-click  → clear selection

local function on_use_select(itemstack, user, pointed_thing)
	local s, name = require_session(user)
	if not s then core.chat_send_player(user:get_player_name(), "[studio] " .. name); return itemstack end
	if not pointed_thing or pointed_thing.type ~= "node" then return itemstack end
	local p = pointed_thing.under
	if not s.sel_a then
		s.sel_a = p; s.sel_b = nil
		core.chat_send_player(name, string.format(
			"[studio] Corner A: (%d,%d,%d). Click corner B.", p.x, p.y, p.z))
	else
		s.sel_b = p
		local a, b = s.sel_a, s.sel_b
		local vol = (math.abs(b.x-a.x)+1) * (math.abs(b.y-a.y)+1) * (math.abs(b.z-a.z)+1)
		core.chat_send_player(name, string.format(
			"[studio] Selection: (%d,%d,%d)→(%d,%d,%d) [%d nodes]. /studio_move dx dy dz to shift.",
			a.x, a.y, a.z, b.x, b.y, b.z, vol))
	end
	return itemstack
end

local function on_secondary_select(itemstack, user, pointed_thing)
	local s, name = require_session(user)
	if not s then return itemstack end
	s.sel_a = nil; s.sel_b = nil
	core.chat_send_player(name, "[studio] Selection cleared.")
	return itemstack
end

core.register_tool("dnd3:studio_select_tool", {
	description = "Studio Select Tool – click A then B; right-click to clear",
	inventory_image = "[fill:16x16:#ffcc00",
	on_use           = on_use_select,
	on_secondary_use = on_secondary_select,
})

-- ── /studio_move ──────────────────────────────────────────────────────────────

core.register_chatcommand("studio_move", {
	params      = "<dx> <dy> <dz>",
	description = "Move Studio selection by offset",
	func = function(name, param)
		if not can_edit(name) then return false, "Permission denied." end
		local s = get_session(name)
		if not s or not s.active then return false, "Studio not active." end
		if not s.sel_a or not s.sel_b then return false, "No selection. Use the Select tool first." end
		local dx, dy, dz = param:match("^(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)$")
		if not dx then return false, "Usage: /studio_move <dx> <dy> <dz>" end
		dx, dy, dz = tonumber(dx), tonumber(dy), tonumber(dz)
		local a, b = s.sel_a, s.sel_b
		local minp = { x=math.min(a.x,b.x), y=math.min(a.y,b.y), z=math.min(a.z,b.z) }
		local maxp = { x=math.max(a.x,b.x), y=math.max(a.y,b.y), z=math.max(a.z,b.z) }
		-- Capture
		local captured = {}
		for x = minp.x, maxp.x do for y = minp.y, maxp.y do for z = minp.z, maxp.z do
			local node = core.get_node({x=x,y=y,z=z})
			if node.name ~= "air" then
				captured[#captured+1] = { from={x=x,y=y,z=z}, node=node }
			end
		end end end
		-- Erase source
		for x = minp.x, maxp.x do for y = minp.y, maxp.y do for z = minp.z, maxp.z do
			local n = core.get_node({x=x,y=y,z=z}).name
			if is_editable(n) then core.remove_node({x=x,y=y,z=z}) end
		end end end
		-- Place at destination
		for _, e in ipairs(captured) do
			core.set_node({x=e.from.x+dx, y=e.from.y+dy, z=e.from.z+dz}, e.node)
		end
		s.sel_a = {x=minp.x+dx, y=minp.y+dy, z=minp.z+dz}
		s.sel_b = {x=maxp.x+dx, y=maxp.y+dy, z=maxp.z+dz}
		return true, string.format("Moved %d nodes by (%d,%d,%d).", #captured, dx, dy, dz)
	end,
})

-- ── Give / take ───────────────────────────────────────────────────────────────

local STUDIO_TOOLS = {
	"dnd3:studio_add_tool",
	"dnd3:studio_remove_tool",
	"dnd3:studio_paint_tool",
	"dnd3:studio_select_tool",
}

function Studio.give_tools(name)
	local player = core.get_player_by_name(name)
	if not player then return false end
	local inv = player:get_inventory()
	if not inv then return false end
	for _, tool in ipairs(STUDIO_TOOLS) do
		if not inv:contains_item("main", tool) then
			inv:add_item("main", tool)
		end
	end
	return true
end

function Studio.take_tools(name)
	local player = core.get_player_by_name(name)
	if not player then return false end
	local inv = player:get_inventory()
	if not inv then return false end
	for _, tool in ipairs(STUDIO_TOOLS) do
		inv:remove_item("main", tool)
	end
	return true
end
