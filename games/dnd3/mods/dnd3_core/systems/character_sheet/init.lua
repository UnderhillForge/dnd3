dnd3.character_sheet = dnd3.character_sheet or {}

local modpath = core.get_modpath(core.get_current_modname())
local base = modpath .. "/systems/character_sheet"

dnd3._state.character_sheet = dnd3._state.character_sheet or {
	ruleset_specs = {},
	open = {},          -- player_name -> { token_id, tab }
	viewers = {},       -- token_id -> { [player_name] = true }
	preview = {},       -- player_name -> { yaw, pitch }
}

dofile(base .. "/api.lua")
dofile(base .. "/persistence.lua")
dofile(base .. "/preview.lua")
dofile(base .. "/ui.lua")
