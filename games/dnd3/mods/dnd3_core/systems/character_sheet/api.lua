local STATE = dnd3._state.character_sheet

local function ensure_sheet(token_id)
	local sheet = dnd3.character.get(token_id)
	if sheet then
		return sheet
	end
	local session_ruleset = (dnd3.get_active_ruleset and dnd3.get_active_ruleset()) or "dnd35"
	return dnd3.character.create(token_id, session_ruleset)
end

local function can_access_token(player_name, token_id)
	local token = dnd3.token_get and dnd3.token_get(token_id)
	if not token then
		return false, "unknown token"
	end
	if dnd3.can(player_name, "map_edit") then
		return true
	end
	if token.owner == player_name then
		return true
	end
	return false, "token is not owned by player"
end

local function clear_viewer(player_name)
	local open = STATE.open[player_name]
	if not open then return end
	local viewers = STATE.viewers[open.token_id]
	if viewers then
		viewers[player_name] = nil
		if next(viewers) == nil then
			STATE.viewers[open.token_id] = nil
		end
	end
end

local function set_viewer(player_name, token_id)
	STATE.viewers[token_id] = STATE.viewers[token_id] or {}
	STATE.viewers[token_id][player_name] = true
end

function dnd3.character_sheet.register_ruleset_spec(ruleset_id, spec)
	if type(ruleset_id) ~= "string" or ruleset_id == "" then
		error("dnd3.character_sheet.register_ruleset_spec: ruleset_id must be a non-empty string")
	end
	if type(spec) ~= "table" then
		error("dnd3.character_sheet.register_ruleset_spec: spec must be a table")
	end
	STATE.ruleset_specs[ruleset_id] = spec
	return spec
end

function dnd3.character_sheet.get_ruleset_spec(ruleset_id)
	return STATE.ruleset_specs[ruleset_id]
end

function dnd3.character_sheet.get_token_viewers(token_id)
	local out = {}
	local viewers = STATE.viewers[token_id] or {}
	for player_name in pairs(viewers) do
		out[#out + 1] = player_name
	end
	table.sort(out)
	return out
end

function dnd3.character_sheet.get_open_state(player_name)
	return STATE.open[player_name]
end

function dnd3.character_sheet.open(player_name, token_id, tab)
	local ok, err = can_access_token(player_name, token_id)
	if not ok then return false, err end

	local sheet = ensure_sheet(token_id)
	if not sheet then return false, "could not create sheet" end

	clear_viewer(player_name)
	STATE.open[player_name] = {
		token_id = token_id,
		tab = tab or "core",
	}
	set_viewer(player_name, token_id)

	if dnd3.character_sheet._show then
		dnd3.character_sheet._show(player_name)
	end
	return true
end

function dnd3.character_sheet.close(player_name)
	clear_viewer(player_name)
	STATE.open[player_name] = nil
	core.close_formspec(player_name, "dnd3:character_sheet")
end

function dnd3.character_sheet.refresh_player(player_name)
	if dnd3.character_sheet._show and STATE.open[player_name] then
		dnd3.character_sheet._show(player_name)
	end
end

function dnd3.character_sheet.refresh_token(token_id)
	local viewers = STATE.viewers[token_id] or {}
	for player_name in pairs(viewers) do
		dnd3.character_sheet.refresh_player(player_name)
	end
end

function dnd3.character_sheet.set_tab(player_name, tab)
	local open = STATE.open[player_name]
	if not open then return false, "character sheet not open" end
	open.tab = tab
	if dnd3.character_sheet.prefs_set then
		dnd3.character_sheet.prefs_set(player_name, "tab", tab)
	end
	dnd3.character_sheet.refresh_player(player_name)
	return true
end

function dnd3.character_sheet.get_tab(player_name)
	local open = STATE.open[player_name]
	if open and open.tab then
		return open.tab
	end
	if dnd3.character_sheet.prefs_get then
		return dnd3.character_sheet.prefs_get(player_name, "tab", "core")
	end
	return "core"
end

function dnd3.character_sheet.set_portrait(token_id, texture)
	local sheet = ensure_sheet(token_id)
	if not sheet then return false, "could not create sheet" end
	dnd3.character.set(token_id, "portrait_texture", texture or "")
	dnd3.character_sheet.refresh_token(token_id)
	return true
end

function dnd3.character_sheet.get_portrait(token_id)
	local sheet = dnd3.character.get(token_id)
	if not sheet then return "" end
	return tostring(sheet.portrait_texture or "")
end

function dnd3.character_sheet.get_equipment(token_id)
	local sheet = dnd3.character.get(token_id)
	if not sheet then return {} end
	local eq = sheet.equipment
	if type(eq) ~= "table" then
		return {}
	end
	return eq
end

function dnd3.character_sheet.set_equipment_item(token_id, slot_id, item_name)
	local sheet = ensure_sheet(token_id)
	if not sheet then return false, "could not create sheet" end
	local eq = type(sheet.equipment) == "table" and sheet.equipment or {}
	eq[slot_id] = item_name or ""
	dnd3.character.set(token_id, "equipment", eq)
	dnd3.character.compute(token_id)
	dnd3.character_sheet.refresh_token(token_id)
	return true
end

function dnd3.character_sheet.clear_equipment_item(token_id, slot_id)
	return dnd3.character_sheet.set_equipment_item(token_id, slot_id, "")
end

function dnd3.character_sheet.recalculate(token_id)
	local sheet = dnd3.character.compute(token_id)
	dnd3.character_sheet.refresh_token(token_id)
	return sheet
end

core.register_chatcommand("dnd3_sheet", {
	params = "<token_id>",
	description = "Open character sheet for a token",
	func = function(name, param)
		local token_id = (param or ""):match("^%s*(.-)%s*$")
		if token_id == "" then
			local selected = dnd3.token_get_selected and dnd3.token_get_selected(name)
			if selected then
				token_id = selected
			end
		end
		if token_id == "" then
			return false, "Usage: /dnd3_sheet <token_id>"
		end
		local ok, err = dnd3.character_sheet.open(name, token_id)
		if not ok then
			return false, err
		end
		return true, "Opened character sheet: " .. token_id
	end,
})

core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	clear_viewer(name)
	STATE.open[name] = nil
	if dnd3.character_sheet._drop_detached then
		dnd3.character_sheet._drop_detached(name)
	end
end)
