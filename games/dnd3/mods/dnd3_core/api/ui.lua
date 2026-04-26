function dnd3.open_panel(player_name)
	if dnd3._show_panel then
		dnd3._show_panel(player_name)
		return true
	end
	return false
end

function dnd3.set_grid_overlay(player_name, enabled)
	return dnd3.grid_overlay_set(player_name, enabled)
end

function dnd3.toggle_grid_overlay(player_name)
	return dnd3.grid_overlay_toggle(player_name)
end
