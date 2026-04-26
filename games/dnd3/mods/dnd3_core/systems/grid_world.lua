-- World-space tactical grid rendered as thin node-box slabs.
-- One grid cell = GRID_SCALE nodes = 5 feet.
-- Nodes are placed one level below the player's feet so they sit on the floor.
-- Right-clicking a grid_floor node while a token is selected moves that token there.

local GRID_SCALE = 5  -- 1 cell = 5 nodes (5 ft)

core.register_node("dnd3:grid_floor", {
	description = "Grid Floor Marker",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, -0.42, 0.5 },
	},
	tiles = { "[fill:16x16:#44CC4460" },
	use_texture_alpha = "blend",
	walkable = false,
	pointable = true,
	diggable = false,
	buildable_to = true,
	sunlight_propagates = true,
	paramtype = "light",
	groups = { not_in_creative_inventory = 1, dnd3_grid = 1 },
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local name = clicker:get_player_name()
		-- token_entity.lua functions are all resolved at call-time (global table)
		local sel = dnd3.token_get_selected and dnd3.token_get_selected(name)
		if not sel then
			return itemstack
		end
		-- Centre the token on the grid cell, just above the floor slab
		local drop_pos = { x = pos.x, y = pos.y + 1, z = pos.z }
		local token, err = dnd3.token_move(sel, drop_pos)
		if token then
			if dnd3._token_entity_sync then
				dnd3._token_entity_sync(sel)
			end
			core.chat_send_player(name, string.format(
				"[dnd3] Moved token '%s' to (%d, %d, %d).",
				sel, drop_pos.x, drop_pos.y, drop_pos.z))
			if dnd3.token_deselect then
				dnd3.token_deselect(name)
			end
		else
			core.chat_send_player(name, "[dnd3] Move failed: " .. tostring(err))
		end
		return itemstack
	end,
})

-- Paint grid floor nodes across a region at a fixed Y level.
-- pos1/pos2 are opposite corners; the min Y is used as the floor.
function dnd3.grid_world_paint(pos1, pos2)
	local minx = math.floor(math.min(pos1.x, pos2.x) / GRID_SCALE) * GRID_SCALE
	local maxx = math.floor(math.max(pos1.x, pos2.x) / GRID_SCALE) * GRID_SCALE
	local minz = math.floor(math.min(pos1.z, pos2.z) / GRID_SCALE) * GRID_SCALE
	local maxz = math.floor(math.max(pos1.z, pos2.z) / GRID_SCALE) * GRID_SCALE
	local y    = math.floor(math.min(pos1.y, pos2.y))

	local count = 0
	for gx = minx, maxx, GRID_SCALE do
		for gz = minz, maxz, GRID_SCALE do
			core.set_node({ x = gx, y = y, z = gz }, { name = "dnd3:grid_floor" })
			count = count + 1
		end
	end
	return count
end

-- Remove grid floor nodes from a region.
function dnd3.grid_world_clear(pos1, pos2)
	local minx = math.floor(math.min(pos1.x, pos2.x) / GRID_SCALE) * GRID_SCALE
	local maxx = math.floor(math.max(pos1.x, pos2.x) / GRID_SCALE) * GRID_SCALE
	local minz = math.floor(math.min(pos1.z, pos2.z) / GRID_SCALE) * GRID_SCALE
	local maxz = math.floor(math.max(pos1.z, pos2.z) / GRID_SCALE) * GRID_SCALE
	local y    = math.floor(math.min(pos1.y, pos2.y))

	local count = 0
	for gx = minx, maxx, GRID_SCALE do
		for gz = minz, maxz, GRID_SCALE do
			local p = { x = gx, y = y, z = gz }
			if core.get_node(p).name == "dnd3:grid_floor" then
				core.remove_node(p)
				count = count + 1
			end
		end
	end
	return count
end

core.register_chatcommand("dnd3_grid_paint", {
	params = "<radius>",
	description = "Paint world-space grid cells in a square <radius> around you (GM only, radius in cells)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local radius_cells = math.max(1, math.min(50, tonumber(param) or 10))
		local player = core.get_player_by_name(name)
		if not player then return false, "Player not found." end
		local pos  = player:get_pos()
		local span = radius_cells * GRID_SCALE
		local floor_y = math.floor(pos.y) - 1
		local pos1 = { x = pos.x - span, y = floor_y, z = pos.z - span }
		local pos2 = { x = pos.x + span, y = floor_y, z = pos.z + span }
		local count = dnd3.grid_world_paint(pos1, pos2)
		return true, string.format("Painted %d grid cells (radius %d cells).", count, radius_cells)
	end,
})

core.register_chatcommand("dnd3_grid_clear_world", {
	params = "<radius>",
	description = "Remove world-space grid cells in a square <radius> around you (GM only)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local radius_cells = math.max(1, math.min(50, tonumber(param) or 10))
		local player = core.get_player_by_name(name)
		if not player then return false, "Player not found." end
		local pos  = player:get_pos()
		local span = radius_cells * GRID_SCALE
		local floor_y = math.floor(pos.y) - 1
		local pos1 = { x = pos.x - span, y = floor_y, z = pos.z - span }
		local pos2 = { x = pos.x + span, y = floor_y, z = pos.z + span }
		local count = dnd3.grid_world_clear(pos1, pos2)
		return true, string.format("Cleared %d grid cells.", count)
	end,
})
