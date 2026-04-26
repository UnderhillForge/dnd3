local STATE = dnd3._state.character_sheet

local TAB_ORDER = { "core", "skills", "combat", "inventory", "spells", "feats", "notes" }
local TAB_LABELS = { "Core", "Skills", "Combat", "Inventory", "Spells", "Feats", "Notes" }
local DETACHED = {} -- player_name -> detached inventory name

local function esc(v)
	return core.formspec_escape(tostring(v or ""))
end

local function tab_index(tab)
	for i, id in ipairs(TAB_ORDER) do
		if id == tab then
			return i
		end
	end
	return 1
end

local function current_token(player_name)
	local open = STATE.open[player_name]
	return open and open.token_id or nil
end

local function can_access(player_name, token_id)
	local token = dnd3.token_get and dnd3.token_get(token_id)
	if not token then return false end
	if dnd3.can(player_name, "map_edit") then return true end
	return token.owner == player_name
end

local function detached_name(player_name)
	return "dnd3_character_sheet_" .. player_name
end

local function slot_id_from_listname(listname)
	return listname:match("^slot_(.+)$")
end

local function sync_slot_to_sheet(player_name, listname, inv)
	local token_id = current_token(player_name)
	if not token_id then return end
	if not can_access(player_name, token_id) then return end
	local slot_id = slot_id_from_listname(listname)
	if not slot_id then return end
	local stack = inv:get_stack(listname, 1)
	dnd3.character_sheet.set_equipment_item(token_id, slot_id, stack:get_name())
end

local function ensure_detached(player_name, token_id)
	local name = DETACHED[player_name]
	if not name then
		name = detached_name(player_name)
		DETACHED[player_name] = name
	end

	local slots = dnd3.character_sheet.get_equipment_slots(token_id)
	local existing = core.get_inventory({ type = "detached", name = name })
	if existing then
		for _, slot in ipairs(slots) do
			existing:set_size("slot_" .. slot.id, 1)
		end
		return existing, name
	end

	local inv = core.create_detached_inventory(name, {
		allow_put = function(_, listname, _, stack, player)
			if not player or player:get_player_name() ~= player_name then return 0 end
			if not slot_id_from_listname(listname) then return 0 end
			if not can_access(player_name, current_token(player_name) or "") then return 0 end
			return 1
		end,
		allow_take = function(_, listname, _, stack, player)
			if not player or player:get_player_name() ~= player_name then return 0 end
			if not slot_id_from_listname(listname) then return 0 end
			if not can_access(player_name, current_token(player_name) or "") then return 0 end
			return stack:get_count()
		end,
		allow_move = function(_, from_list, _, to_list, _, count, player)
			if not player or player:get_player_name() ~= player_name then return 0 end
			if not slot_id_from_listname(from_list) or not slot_id_from_listname(to_list) then return 0 end
			if not can_access(player_name, current_token(player_name) or "") then return 0 end
			return count
		end,
		on_put = function(inv_ref, listname)
			sync_slot_to_sheet(player_name, listname, inv_ref)
		end,
		on_take = function(inv_ref, listname)
			sync_slot_to_sheet(player_name, listname, inv_ref)
		end,
		on_move = function(inv_ref, from_list, _, to_list)
			sync_slot_to_sheet(player_name, from_list, inv_ref)
			sync_slot_to_sheet(player_name, to_list, inv_ref)
		end,
	})

	for _, slot in ipairs(slots) do
		inv:set_size("slot_" .. slot.id, 1)
	end
	return inv, name
end

local function populate_detached(player_name, token_id)
	local inv = ensure_detached(player_name, token_id)
	local eq = dnd3.character_sheet.get_equipment(token_id)
	for _, slot in ipairs(dnd3.character_sheet.get_equipment_slots(token_id)) do
		local item_name = eq[slot.id] or ""
		inv:set_stack("slot_" .. slot.id, 1, ItemStack(item_name))
	end
	return inv
end

local function left_pane(player_name, token_id, sheet)
	local slots = dnd3.character_sheet.get_equipment_slots(token_id)
	local portrait = dnd3.character_sheet.get_portrait(token_id)
	if portrait == "" then portrait = "no_texture.png" end
	local preview = dnd3.character_sheet.build_avatar_preview(token_id, player_name)
	local model = string.format(
		"model[0.3,0.6;4.7,6.7;dnd3_cs_avatar;%s;%s;0,%d;true;true;%d,%d;%d]",
		esc(preview.mesh), esc(preview.texture), tonumber(preview.yaw) or 180,
		tonumber(preview.anim.x) or 1, tonumber(preview.anim.y) or 80, tonumber(preview.anim.speed) or 24
	)

	local parts = {
		"box[0.2,0.2;5.2,11.4;#111a]",
		"label[0.4,0.25;Avatar Preview]",
		model,
		"button[0.5,7.15;1.0,0.7;dnd3_cs_rotate_left;<]",
		"button[3.9,7.15;1.0,0.7;dnd3_cs_rotate_right;>]",
		"image[0.35,7.95;2.2,2.2;", esc(portrait), "]",
		"field[2.7,8.7;2.6,0.8;dnd3_cs_portrait;Portrait Texture;;", esc(sheet.portrait_texture or ""), "]",
		"button[2.7,9.35;2.4,0.7;dnd3_cs_set_portrait;Set Portrait]",
		"label[0.3,10.2;Paper Doll Slots]",
	}

	for _, slot in ipairs(slots) do
		local listname = "slot_" .. slot.id
		parts[#parts + 1] = string.format("list[detached:%s;%s;%.2f,%.2f;1,1;]", esc(detached_name(player_name)), esc(listname), slot.x, slot.y)
		parts[#parts + 1] = string.format("tooltip[detached:%s;%s;slot: %s]", esc(detached_name(player_name)), esc(listname), esc(slot.label or slot.id))
	end

	return table.concat(parts, "")
end

local function right_header(player_name, token_id, sheet)
	local tab = dnd3.character_sheet.get_tab(player_name)
	local idx = tab_index(tab)
	return table.concat({
		"box[5.6,0.2;12.1,11.4;#161616d8]",
		"label[5.9,0.25;", esc((sheet.name and sheet.name ~= "") and sheet.name or token_id), "]",
		"label[5.9,0.6;Ruleset: ", esc(sheet.__meta and sheet.__meta.ruleset_id or "?"), "]",
		"tabheader[5.9,1.0;dnd3_cs_tab;", table.concat(TAB_LABELS, ","), ";", tostring(idx), ";false;false]",
		"button[16.2,0.5;1.2,0.7;dnd3_cs_recalc;Recalc]",
	})
end

local function core_tab(sheet)
	return table.concat({
		"label[6.0,1.7;Abilities]",
		string.format("label[6.0,2.1;STR %d (%+d)]", tonumber(sheet.str) or 10, tonumber(sheet.str_mod) or 0),
		string.format("label[8.0,2.1;DEX %d (%+d)]", tonumber(sheet.dex) or 10, tonumber(sheet.dex_mod) or 0),
		string.format("label[10.0,2.1;CON %d (%+d)]", tonumber(sheet.con) or 10, tonumber(sheet.con_mod) or 0),
		string.format("label[12.0,2.1;INT %d (%+d)]", tonumber(sheet.int) or 10, tonumber(sheet.int_mod) or 0),
		string.format("label[14.0,2.1;WIS %d (%+d)]", tonumber(sheet.wis) or 10, tonumber(sheet.wis_mod) or 0),
		string.format("label[16.0,2.1;CHA %d (%+d)]", tonumber(sheet.cha) or 10, tonumber(sheet.cha_mod) or 0),
		string.format("label[6.0,2.8;HP: %d / %d]", tonumber(sheet.hp_current) or 0, tonumber(sheet.hp_max) or 0),
		string.format("label[8.8,2.8;Status: %s]", esc(sheet.hp_status or "alive")),
		string.format("label[11.2,2.8;Init: %+d]", tonumber(sheet.initiative) or 0),
	})
end

local function skills_tab(sheet)
	return table.concat({
		"label[6.0,1.7;Skills]",
		string.format("label[6.0,2.2;Concentration: %+d]", tonumber(sheet.concentration_total) or 0),
		string.format("label[9.0,2.2;Spellcraft: %+d]", tonumber(sheet.spellcraft_total) or 0),
		string.format("label[12.0,2.2;Spot: %+d]", tonumber(sheet.spot_total) or 0),
		string.format("label[14.0,2.2;Listen: %+d]", tonumber(sheet.listen_total) or 0),
	})
end

local function combat_tab(sheet)
	return table.concat({
		"label[6.0,1.7;Combat]",
		string.format("label[6.0,2.2;BAB: %+d]", tonumber(sheet.bab) or 0),
		string.format("label[7.8,2.2;Melee Atk: %+d]", tonumber(sheet.melee_attack_bonus) or 0),
		string.format("label[10.4,2.2;Ranged Atk: %+d]", tonumber(sheet.ranged_attack_bonus) or 0),
		string.format("label[13.2,2.2;AC: %d]", tonumber(sheet.ac) or 10),
		string.format("label[14.8,2.2;Touch: %d]", tonumber(sheet.ac_touch) or 10),
		string.format("label[16.3,2.2;FF: %d]", tonumber(sheet.ac_flat_footed) or 10),
		string.format("label[6.0,2.8;Fort: %+d  Ref: %+d  Will: %+d]", tonumber(sheet.fort_save) or 0, tonumber(sheet.ref_save) or 0, tonumber(sheet.will_save) or 0),
	})
end

local function inventory_tab(player_name)
	return table.concat({
		"label[6.0,1.7;Inventory]",
		"list[current_player;main;6.0,2.2;8,4;]",
		"listring[current_player;main]",
	})
end

local function spells_tab(sheet)
	local conc = tonumber(sheet.concentration_total) or 0
	return table.concat({
		"label[6.0,1.7;Spells]",
		string.format("label[6.0,2.2;Concentration: %+d]", conc),
		"label[6.0,2.7;Spell slot tracking is ruleset-driven (dnd35.spell.* API).]",
	})
end

local function feats_tab(sheet)
	local feats = type(sheet.feats) == "table" and sheet.feats or {}
	local text = #feats > 0 and table.concat(feats, ", ") or "No feats listed"
	return table.concat({
		"label[6.0,1.7;Feats]",
		"textarea[6.0,2.1;11.2,3.2;dnd3_cs_feats;;", esc(text), "]",
	})
end

local function notes_tab(sheet)
	local notes = tostring(sheet.notes or "")
	return table.concat({
		"label[6.0,1.7;Notes]",
		"textarea[6.0,2.1;11.2,7.8;dnd3_cs_notes;;", esc(notes), "]",
		"button[15.5,10.2;1.6,0.7;dnd3_cs_save_notes;Save]",
	})
end

local function tab_body(player_name, sheet)
	local tab = dnd3.character_sheet.get_tab(player_name)
	if tab == "skills" then return skills_tab(sheet) end
	if tab == "combat" then return combat_tab(sheet) end
	if tab == "inventory" then return inventory_tab(player_name) end
	if tab == "spells" then return spells_tab(sheet) end
	if tab == "feats" then return feats_tab(sheet) end
	if tab == "notes" then return notes_tab(sheet) end
	return core_tab(sheet)
end

local function build_formspec(player_name)
	local token_id = current_token(player_name)
	if not token_id then
		return "formspec_version[6]size[8,3]label[0.4,1.2;No character sheet open.]"
	end

	local sheet = dnd3.character.get(token_id)
	if not sheet then
		return "formspec_version[6]size[8,3]label[0.4,1.2;Sheet not found for token.]"
	end

	populate_detached(player_name, token_id)

	return table.concat({
		"formspec_version[6]",
		"size[18.0,12.0]",
		"bgcolor[#0f1116ee;false]",
		left_pane(player_name, token_id, sheet),
		right_header(player_name, token_id, sheet),
		tab_body(player_name, sheet),
	})
end

function dnd3.character_sheet._show(player_name)
	core.show_formspec(player_name, "dnd3:character_sheet", build_formspec(player_name))
end

function dnd3.character_sheet._drop_detached(player_name)
	DETACHED[player_name] = nil
end

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "dnd3:character_sheet" then return false end
	local player_name = player:get_player_name()
	local token_id = current_token(player_name)
	if fields.quit then
		dnd3.character_sheet.close(player_name)
		return true
	end
	if not token_id then return true end

	if fields.dnd3_cs_rotate_left then
		dnd3.character_sheet.preview_rotate(player_name, -15)
		return true
	end
	if fields.dnd3_cs_rotate_right then
		dnd3.character_sheet.preview_rotate(player_name, 15)
		return true
	end
	if fields.dnd3_cs_recalc then
		dnd3.character_sheet.recalculate(token_id)
		return true
	end
	if fields.dnd3_cs_set_portrait then
		dnd3.character_sheet.set_portrait(token_id, fields.dnd3_cs_portrait or "")
		return true
	end
	if fields.dnd3_cs_save_notes then
		if can_access(player_name, token_id) then
			dnd3.character.set(token_id, "notes", fields.dnd3_cs_notes or "")
			dnd3.character_sheet.refresh_token(token_id)
		end
		return true
	end
	if fields.dnd3_cs_tab then
		local idx = tonumber(fields.dnd3_cs_tab)
		if idx and TAB_ORDER[idx] then
			dnd3.character_sheet.set_tab(player_name, TAB_ORDER[idx])
		end
		return true
	end

	return false
end)
