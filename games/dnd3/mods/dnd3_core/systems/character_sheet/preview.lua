local STATE = dnd3._state.character_sheet

local DEFAULT_SLOTS = {
	{ id = "head", label = "Head", x = 0.9, y = 0.8 },
	{ id = "cloak", label = "Cloak", x = 0.4, y = 2.0 },
	{ id = "chest", label = "Chest", x = 1.0, y = 2.4 },
	{ id = "hands", label = "Hands", x = 0.2, y = 3.2 },
	{ id = "main_hand", label = "Main", x = 0.2, y = 4.0 },
	{ id = "off_hand", label = "Off", x = 2.7, y = 4.0 },
	{ id = "belt", label = "Belt", x = 1.1, y = 4.3 },
	{ id = "legs", label = "Legs", x = 1.0, y = 5.0 },
	{ id = "feet", label = "Feet", x = 1.0, y = 5.7 },
}

local function get_spec(token_id)
	local sheet = dnd3.character.get(token_id)
	local ruleset_id = sheet and sheet.__meta and sheet.__meta.ruleset_id or "dnd35"
	return dnd3.character_sheet.get_ruleset_spec(ruleset_id) or {}
end

local function item_texture(item_name)
	if not item_name or item_name == "" then
		return nil
	end
	local def = core.registered_items[item_name]
	if not def then return nil end
	if type(def.inventory_image) == "string" and def.inventory_image ~= "" then
		return def.inventory_image
	end
	if type(def.wield_image) == "string" and def.wield_image ~= "" then
		return def.wield_image
	end
	if type(def.tiles) == "table" and type(def.tiles[1]) == "string" and def.tiles[1] ~= "" then
		return def.tiles[1]
	end
	return nil
end

function dnd3.character_sheet.get_equipment_slots(token_id)
	local spec = get_spec(token_id)
	if type(spec.equipment_slots) == "table" and #spec.equipment_slots > 0 then
		return spec.equipment_slots
	end
	return DEFAULT_SLOTS
end

function dnd3.character_sheet.preview_get_pose(player_name)
	STATE.preview[player_name] = STATE.preview[player_name] or {
		yaw = tonumber(dnd3.character_sheet.prefs_get(player_name, "preview_yaw", 180)) or 180,
		pitch = tonumber(dnd3.character_sheet.prefs_get(player_name, "preview_pitch", 0)) or 0,
	}
	return STATE.preview[player_name]
end

function dnd3.character_sheet.preview_rotate(player_name, delta)
	local pose = dnd3.character_sheet.preview_get_pose(player_name)
	pose.yaw = (tonumber(pose.yaw) or 180) + (tonumber(delta) or 0)
	while pose.yaw < 0 do pose.yaw = pose.yaw + 360 end
	while pose.yaw >= 360 do pose.yaw = pose.yaw - 360 end
	dnd3.character_sheet.prefs_set(player_name, "preview_yaw", pose.yaw)
	dnd3.character_sheet.refresh_player(player_name)
end

function dnd3.character_sheet.build_avatar_preview(token_id, player_name)
	local sheet = dnd3.character.get(token_id) or {}
	local spec = get_spec(token_id)
	local mesh = tostring(sheet.avatar_mesh or spec.mesh or "character.b3d")
	local base = tostring(sheet.avatar_base_texture or spec.base_texture or "character.png")
	local equipment = type(sheet.equipment) == "table" and sheet.equipment or {}
	local overlays = {}

	local render_order = spec.render_order
	if type(render_order) ~= "table" or #render_order == 0 then
		render_order = {
			"chest", "legs", "feet", "hands", "head", "cloak", "main_hand", "off_hand",
		}
	end

	for _, slot_id in ipairs(render_order) do
		local item_name = equipment[slot_id]
		local tex = item_texture(item_name)
		if tex then
			overlays[#overlays + 1] = tex
		end
	end

	local texture = base
	for _, tex in ipairs(overlays) do
		texture = texture .. "^" .. tex
	end

	local pose = dnd3.character_sheet.preview_get_pose(player_name)
	local idle = spec.idle_anim or { x = 1, y = 80, speed = 24 }
	return {
		mesh = mesh,
		texture = texture,
		yaw = pose.yaw,
		pitch = pose.pitch,
		anim = idle,
	}
end
