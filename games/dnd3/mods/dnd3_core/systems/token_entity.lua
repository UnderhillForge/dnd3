-- Token entity system: spawns live `dnd3:token_entity` objects in the world.
-- Supports right-click selection and drag-drop movement via grid_world.lua or
-- the /dnd3_token_drop command.
--
-- Interaction workflow:
--   1. GM spawns token: /dnd3_token_spawn <id>
--   2. Player right-clicks entity  → token becomes "selected" for that player
--   3. Player right-clicks a grid_floor node (or uses /dnd3_token_drop x y z)
--      → selected token moves to that position
--   4. /dnd3_token_deselect clears selection

-- Per-player selection: player_name -> token_id or nil
local selection = {}

-- Live entity refs: token_id -> ObjectRef (cleared on removal/reload)
local live_entities = {}

--- Returns the token ID currently selected by player_name, or nil.
function dnd3.token_get_selected(player_name)
	return selection[player_name]
end

--- Select a token for movement.  Does not validate permissions (caller's responsibility).
function dnd3.token_select(player_name, token_id)
	selection[player_name] = token_id
end

--- Clear the active selection for player_name.
function dnd3.token_deselect(player_name)
	selection[player_name] = nil
end

--- Sync a live entity position to its token data record.
--- Called after token_move so the visual moves immediately.
function dnd3._token_entity_sync(token_id)
	local token = dnd3.token_get(token_id)
	if not token then return end
	local ent = live_entities[token_id]
	if ent and ent:get_pos() then
		ent:set_pos(token.pos)
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Prefab visual helper
-- ─────────────────────────────────────────────────────────────────────────────

--- Apply mesh/texture/scale/collision from a registered prefab_def to an entity.
--- Safe to call when no prefab is linked (does nothing).
local function apply_prefab_visuals(obj, token)
	local pname = token.meta and token.meta.prefab
	if not pname then return end
	local def = dnd3.prefab_def_get(pname)
	if not def or not def.mesh then return end

	local props = {
		visual      = "mesh",
		mesh        = def.mesh,
		textures    = def.textures,
		visual_size = { x = def.visual_scale, y = def.visual_scale },
	}
	if def.collision_box then
		props.collisionbox = def.collision_box
	end
	obj:set_properties(props)

	-- Loop wind-sway animation when requested and an animation range is provided
	if def.wind_sway and def.animation and def.animation.sway then
		local s = def.animation.sway
		obj:set_animation({ x = s.start, y = s.stop }, s.speed or 15, 0, true)
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Entity definition
-- ─────────────────────────────────────────────────────────────────────────────

core.register_entity("dnd3:token_entity", {
	initial_properties = {
		visual          = "upright_sprite",
		textures        = { "[fill:16x16:#CC4444FF" },
		visual_size     = { x = 0.9, y = 0.9 },
		collisionbox    = { -0.45, -0.5, -0.45, 0.45, 0.45, 0.45 },
		selectionbox    = { -0.45, -0.5, -0.45, 0.45, 0.5, 0.45 },
		physical        = false,
		pointable       = true,
		static_save     = true,
	},

	_token_id = nil,

	on_activate = function(self, staticdata, dtime_s)
		if staticdata and staticdata ~= "" then
			local data = core.parse_json(staticdata)
			if data and data.token_id then
				self._token_id = data.token_id
				live_entities[data.token_id] = self.object
				local token = dnd3.token_get(data.token_id)
				if token then
					self.object:set_pos(token.pos)
					apply_prefab_visuals(self.object, token)
					self.object:set_properties({ nametag = token.label or data.token_id })
				end
			end
		end
	end,

	get_staticdata = function(self)
		return core.write_json({ token_id = self._token_id })
	end,

	-- Right-click: select this token (GM or owner only)
	on_rightclick = function(self, clicker)
		if not clicker then return end
		local name = clicker:get_player_name()
		local tid  = self._token_id
		if not tid then
			core.chat_send_player(name, "[dnd3] This token entity has no registered ID.")
			return
		end
		local token = dnd3.token_get(tid)
		if not token then
			core.chat_send_player(name, "[dnd3] Token record not found for ID '" .. tid .. "'.")
			return
		end
		if not dnd3.can(name, "token_control") and token.owner ~= name then
			core.chat_send_player(name, "[dnd3] Permission denied – you don't own this token.")
			return
		end
		dnd3.token_select(name, tid)
		core.chat_send_player(name, string.format(
			"[dnd3] Selected '%s'. Right-click a grid cell or use /dnd3_token_drop <x> <y> <z>.",
			token.label or tid))
	end,

	-- Punch: GM can remove the entity (does not delete token data record)
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if not puncher then return end
		local name = puncher:get_player_name()
		if not dnd3.can(name, "map_edit") then
			core.chat_send_player(name, "[dnd3] Only GMs can remove token entities.")
			return
		end
		local tid = self._token_id
		if tid then
			live_entities[tid] = nil
			core.chat_send_player(name, "[dnd3] Removed entity for token '" .. tid .. "'.")
		end
		self.object:remove()
	end,
})

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

--- Spawn a world entity for an existing token data record.
--- @param token_id string
--- @return ObjectRef|nil, string|nil error
function dnd3.token_spawn(token_id)
	local token = dnd3.token_get(token_id)
	if not token then
		return nil, "unknown token: " .. tostring(token_id)
	end
	-- Despawn existing entity first
	local existing = live_entities[token_id]
	if existing and existing:get_pos() then
		existing:remove()
	end
	local ent = core.add_entity(token.pos, "dnd3:token_entity",
		core.write_json({ token_id = token_id }))
	if not ent then
		return nil, "engine failed to create entity"
	end
	live_entities[token_id] = ent
	apply_prefab_visuals(ent, token)
	ent:set_properties({ nametag = token.label or token_id })
	return ent
end

--- Remove the world entity for a token (does not delete token data).
--- @param token_id string
--- @return boolean
function dnd3.token_despawn(token_id)
	local ent = live_entities[token_id]
	if ent and ent:get_pos() then
		ent:remove()
		live_entities[token_id] = nil
		return true
	end
	live_entities[token_id] = nil
	return false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Chat commands
-- ─────────────────────────────────────────────────────────────────────────────

core.register_chatcommand("dnd3_token_spawn", {
	params = "<id>",
	description = "Spawn a world entity for a registered token (GM only)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local id = param:match("^%s*(.-)%s*$")
		if id == "" then return false, "Usage: /dnd3_token_spawn <id>" end
		local ent, err = dnd3.token_spawn(id)
		if not ent then return false, "Error: " .. tostring(err) end
		return true, "Spawned entity for token '" .. id .. "'."
	end,
})

core.register_chatcommand("dnd3_token_despawn", {
	params = "<id>",
	description = "Remove the world entity for a token (GM only, preserves data)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local id = param:match("^%s*(.-)%s*$")
		if id == "" then return false, "Usage: /dnd3_token_despawn <id>" end
		if dnd3.token_despawn(id) then
			return true, "Removed entity for token '" .. id .. "'."
		else
			return false, "No live entity found for token '" .. id .. "'."
		end
	end,
})

core.register_chatcommand("dnd3_token_select", {
	params = "<id>",
	description = "Select a token for movement (GM or owner)",
	func = function(name, param)
		local id = param:match("^%s*(.-)%s*$")
		if id == "" then return false, "Usage: /dnd3_token_select <id>" end
		local token = dnd3.token_get(id)
		if not token then return false, "Unknown token: " .. id end
		if not dnd3.can(name, "token_control") and token.owner ~= name then
			return false, "Permission denied."
		end
		dnd3.token_select(name, id)
		return true, string.format("Selected token '%s'. Use /dnd3_token_drop <x> <y> <z> to move it.",
			token.label or id)
	end,
})

core.register_chatcommand("dnd3_token_drop", {
	params = "<x> <y> <z>",
	description = "Move the selected token to world coordinates",
	func = function(name, param)
		local sel = dnd3.token_get_selected(name)
		if not sel then
			return false, "No token selected. Use /dnd3_token_select <id> first."
		end
		local xs, ys, zs = param:match("^(-?[%d%.]+)%s+(-?[%d%.]+)%s+(-?[%d%.]+)$")
		if not xs then
			return false, "Usage: /dnd3_token_drop <x> <y> <z>"
		end
		local pos = { x = tonumber(xs), y = tonumber(ys), z = tonumber(zs) }
		local token, err = dnd3.token_move(sel, pos)
		if not token then return false, "Move failed: " .. tostring(err) end
		dnd3._token_entity_sync(sel)
		dnd3.token_deselect(name)
		return true, string.format("Moved token '%s' to (%.1f, %.1f, %.1f).",
			sel, pos.x, pos.y, pos.z)
	end,
})

core.register_chatcommand("dnd3_token_deselect", {
	params = "",
	description = "Deselect the currently selected token",
	func = function(name, param)
		dnd3.token_deselect(name)
		return true, "Token deselected."
	end,
})
