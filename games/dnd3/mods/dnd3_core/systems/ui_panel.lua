local function esc(s)
	return core.formspec_escape(tostring(s or ""))
end

local function role_options(current)
	local roles = { "gm", "player", "observer" }
	local idx = 2
	for i, role in ipairs(roles) do
		if role == current then
			idx = i
			break
		end
	end
	return table.concat(roles, ","), idx
end

local function panel_formspec(player_name)
	local role = dnd3.get_role(player_name)
	local rs = dnd3.get_active_ruleset()
	local grid_on = dnd3.grid_overlay_is_enabled(player_name)
	local role_items, role_idx = role_options(role)

	return table.concat({
		"formspec_version[6]",
		"size[13,9]",
		"label[0.4,0.4;dnd3 Control Panel]",
		"box[0.3,0.8;12.4,0.1;#666666]",
		"label[0.4,1.2;Player: ", esc(player_name), "]",
		"label[0.4,1.8;Role: ", esc(role), "]",
		"label[0.4,2.4;Ruleset: ", esc(rs), "]",
		"label[0.4,3.2;Grid Overlay: ", grid_on and "on" or "off", "]",
		"button[0.4,4.0;3.2,0.9;toggle_grid;Toggle Grid]",
		"button[3.9,4.0;3.2,0.9;show_rulesets;List Rulesets]",
		"button[7.4,4.0;2.8,0.9;show_tokens;List Tokens]",
		"button[10.5,4.0;2.2,0.9;show_init;Initiative]",
		"label[0.4,5.3;GM quick role update]",
		"field[0.7,6.4;4.2,0.9;target_player;Player;]",
		"dropdown[5.1,6.05;3.0,0.9;target_role;", role_items, ";", tostring(role_idx), "]",
		"button[8.4,5.9;2.6,0.9;set_role;Apply Role]",
		"button_exit[10.9,7.8;1.8,0.9;close;Close]",
	}, "")
end

function dnd3._show_panel(player_name)
	core.show_formspec(player_name, "dnd3:control_panel", panel_formspec(player_name))
end

core.register_chatcommand("dnd3_panel", {
	description = "Open the dnd3 control panel",
	func = function(name)
		dnd3._show_panel(name)
		return true, "Opened dnd3 panel"
	end,
})

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "dnd3:control_panel" then
		return
	end

	local name = player:get_player_name()

	if fields.toggle_grid then
		dnd3.grid_overlay_toggle(name)
		dnd3._show_panel(name)
		return true
	end

	if fields.show_rulesets then
		local ids = {}
		for _, rs in ipairs(dnd3.list_rulesets()) do
			ids[#ids + 1] = rs.id
		end
		core.chat_send_player(name, "[dnd3] Rulesets: " .. table.concat(ids, ", "))
		dnd3._show_panel(name)
		return true
	end

	if fields.show_tokens then
		local ids = {}
		for _, token in ipairs(dnd3.token_list()) do
			ids[#ids + 1] = token.id
		end
		core.chat_send_player(name, "[dnd3] Tokens: " .. (#ids > 0 and table.concat(ids, ", ") or "none"))
		dnd3._show_panel(name)
		return true
	end

	if fields.show_init then
		local entries = dnd3.initiative_list()
		if #entries == 0 then
			core.chat_send_player(name, "[dnd3] Initiative is empty")
		else
			local parts = {}
			for _, entry in ipairs(entries) do
				parts[#parts + 1] = entry.token .. "=" .. tostring(entry.score)
			end
			core.chat_send_player(name, "[dnd3] Initiative: " .. table.concat(parts, ", "))
		end
		dnd3._show_panel(name)
		return true
	end

	if fields.set_role then
		if not dnd3.can(name, "ruleset_switch") then
			core.chat_send_player(name, "[dnd3] You are not allowed to change roles")
			dnd3._show_panel(name)
			return true
		end

		local target = (fields.target_player or ""):gsub("^%s+", ""):gsub("%s+$", "")
		local role = (fields.target_role or ""):match("^(%a+)")
		if target == "" or not role then
			core.chat_send_player(name, "[dnd3] Enter player and role")
			dnd3._show_panel(name)
			return true
		end
		local ok, err = dnd3.set_role(target, role)
		if not ok then
			core.chat_send_player(name, "[dnd3] " .. err)
		else
			core.chat_send_player(name, "[dnd3] Role updated: " .. target .. " -> " .. role)
		end
		dnd3._show_panel(name)
		return true
	end

	return false
end)
