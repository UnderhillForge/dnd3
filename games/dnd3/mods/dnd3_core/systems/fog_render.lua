-- GM-controlled global fog-of-war rendered as opaque dark nodes.
-- Fog covers unrevealed cells as a column of `dnd3:fog` nodes.
-- GM removes fog nodes to reveal areas for all players simultaneously.
-- Per-player vision is deferred to Phase 3 (requires C++ rendering hooks).
--
-- NOTE: fog nodes are shared world state (same view for all players).

local GRID_SCALE = 5   -- 1 cell = 5 nodes
local FOG_HEIGHT = 3   -- column height in nodes (covers standing character)

core.register_node("dnd3:fog", {
	description = "Fog of War",
	drawtype = "glasslike",
	tiles = { "[fill:16x16:#060610C8" },
	use_texture_alpha = "blend",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	sunlight_propagates = false,
	paramtype = "light",
	light_source = 0,
	groups = { not_in_creative_inventory = 1, dnd3_fog = 1 },
})

-- Place fog columns across a rectangular region.
-- pos1/pos2 define opposite corners; min Y is used as the base row.
function dnd3.fog_render_fill(pos1, pos2)
	local minx = math.floor(math.min(pos1.x, pos2.x) / GRID_SCALE) * GRID_SCALE
	local maxx = math.floor(math.max(pos1.x, pos2.x) / GRID_SCALE) * GRID_SCALE
	local minz = math.floor(math.min(pos1.z, pos2.z) / GRID_SCALE) * GRID_SCALE
	local maxz = math.floor(math.max(pos1.z, pos2.z) / GRID_SCALE) * GRID_SCALE
	local base_y = math.floor(math.min(pos1.y, pos2.y))

	local count = 0
	for gx = minx, maxx, GRID_SCALE do
		for gz = minz, maxz, GRID_SCALE do
			for dy = 0, FOG_HEIGHT - 1 do
				core.set_node({ x = gx, y = base_y + dy, z = gz }, { name = "dnd3:fog" })
			end
			count = count + 1
		end
	end
	return count
end

-- Remove fog columns from a rectangular region.
function dnd3.fog_render_reveal(pos1, pos2)
	local minx = math.floor(math.min(pos1.x, pos2.x) / GRID_SCALE) * GRID_SCALE
	local maxx = math.floor(math.max(pos1.x, pos2.x) / GRID_SCALE) * GRID_SCALE
	local minz = math.floor(math.min(pos1.z, pos2.z) / GRID_SCALE) * GRID_SCALE
	local maxz = math.floor(math.max(pos1.z, pos2.z) / GRID_SCALE) * GRID_SCALE
	local base_y = math.floor(math.min(pos1.y, pos2.y))

	local count = 0
	for gx = minx, maxx, GRID_SCALE do
		for gz = minz, maxz, GRID_SCALE do
			for dy = 0, FOG_HEIGHT - 1 do
				local p = { x = gx, y = base_y + dy, z = gz }
				if core.get_node(p).name == "dnd3:fog" then
					core.remove_node(p)
				end
			end
			count = count + 1
		end
	end
	return count
end

-- Reveal cells within a player's LOS radius around a centre position.
-- Uses the per-player LOS radius stored by visibility.lua.
function dnd3.fog_render_reveal_los(player_name, center)
	local vis = dnd3.visibility_get(player_name)
	local r   = ((vis and vis.los_radius) or 12) * GRID_SCALE
	local pos1 = { x = center.x - r, y = center.y, z = center.z - r }
	local pos2 = { x = center.x + r, y = center.y, z = center.z + r }
	return dnd3.fog_render_reveal(pos1, pos2)
end

core.register_chatcommand("dnd3_fog_fill", {
	params = "<radius>",
	description = "Fill fog of war in a square <radius> (cells) around you (GM only)",
	func = function(name, param)
		if not dnd3.can(name, "fog_control") then
			return false, "Permission denied (requires GM role)."
		end
		local radius_cells = math.max(1, math.min(50, tonumber(param) or 10))
		local player = core.get_player_by_name(name)
		if not player then return false, "Player not found." end
		local pos  = player:get_pos()
		local span = radius_cells * GRID_SCALE
		local pos1 = { x = pos.x - span, y = math.floor(pos.y), z = pos.z - span }
		local pos2 = { x = pos.x + span, y = math.floor(pos.y), z = pos.z + span }
		local count = dnd3.fog_render_fill(pos1, pos2)
		return true, string.format("Placed fog over %d cells (radius %d cells).", count, radius_cells)
	end,
})

core.register_chatcommand("dnd3_fog_reveal_area", {
	params = "<radius>",
	description = "Reveal fog in a square <radius> (cells) around you (GM only)",
	func = function(name, param)
		if not dnd3.can(name, "fog_control") then
			return false, "Permission denied (requires GM role)."
		end
		local radius_cells = math.max(1, math.min(50, tonumber(param) or 10))
		local player = core.get_player_by_name(name)
		if not player then return false, "Player not found." end
		local pos  = player:get_pos()
		local span = radius_cells * GRID_SCALE
		local pos1 = { x = pos.x - span, y = math.floor(pos.y), z = pos.z - span }
		local pos2 = { x = pos.x + span, y = math.floor(pos.y), z = pos.z + span }
		local count = dnd3.fog_render_reveal(pos1, pos2)
		return true, string.format("Revealed %d cells (radius %d cells).", count, radius_cells)
	end,
})

core.register_chatcommand("dnd3_fog_reveal_los", {
	params = "[<player>]",
	description = "Reveal fog using a player's LOS radius around their position (GM only)",
	func = function(name, param)
		if not dnd3.can(name, "fog_control") then
			return false, "Permission denied (requires GM role)."
		end
		local target_name = (param ~= "" and param) or name
		local target = core.get_player_by_name(target_name)
		if not target then
			return false, "Player '" .. target_name .. "' not found or offline."
		end
		local count = dnd3.fog_render_reveal_los(target_name, target:get_pos())
		return true, string.format("Revealed LOS area for '%s' (%d cells).", target_name, count)
	end,
})
