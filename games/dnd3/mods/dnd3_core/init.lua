local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)

dnd3 = rawget(_G, "dnd3") or {}
dnd3.version = "0.1.0-dnd3"
dnd3.modpath = modpath

dnd3._state = dnd3._state or {
	rulesets = {},
	sheet_fields = {},
	initiative = {
		entries = {},
		turn_index = 0,
	},
	session = {
		active_ruleset = "dnd35",
		session_name = "default",
	},
}

dofile(modpath .. "/systems/mapgen.lua")
dofile(modpath .. "/systems/permissions.lua")
dofile(modpath .. "/systems/dice.lua")
dofile(modpath .. "/systems/initiative.lua")
dofile(modpath .. "/systems/session.lua")
dofile(modpath .. "/systems/map_editor.lua")
dofile(modpath .. "/systems/tokens.lua")
dofile(modpath .. "/systems/visibility.lua")
dofile(modpath .. "/systems/prefabs.lua")
dofile(modpath .. "/systems/persistence.lua")
dofile(modpath .. "/systems/grid_overlay.lua")
dofile(modpath .. "/systems/grid_world.lua")
dofile(modpath .. "/systems/fog_render.lua")
dofile(modpath .. "/systems/token_entity.lua")
dofile(modpath .. "/systems/hybrid_terrain/init.lua")
dofile(modpath .. "/systems/diorama/init.lua")
dofile(modpath .. "/systems/diorama_studio/init.lua")
dofile(modpath .. "/systems/prefab_browser.lua")
dofile(modpath .. "/systems/audio/init.lua")
dofile(modpath .. "/systems/time_of_day/init.lua")
dofile(modpath .. "/systems/weather/init.lua")
dofile(modpath .. "/systems/character.lua")
dofile(modpath .. "/systems/character_sheet/init.lua")
dofile(modpath .. "/systems/combat_state.lua")
dofile(modpath .. "/systems/ui_panel.lua")

dofile(modpath .. "/api/register_ruleset.lua")
dofile(modpath .. "/api/register_sheet_field.lua")
dofile(modpath .. "/api/roll.lua")
dofile(modpath .. "/api/apply_effect.lua")
dofile(modpath .. "/api/map.lua")
dofile(modpath .. "/api/token.lua")
dofile(modpath .. "/api/ui.lua")
dofile(modpath .. "/api/diorama_studio.lua")

-- ── Ruleset loader ─────────────────────────────────────────────────────────
-- Rulesets live in <workspace_root>/rulesets/<id>/init.lua, outside the mod
-- directory.  Derive workspace root from modpath pattern.
do
	local workspace_root = modpath:match("^(.*)/games/[^/]+")
	if workspace_root then
		dnd3.rulesets_path = workspace_root .. "/rulesets"
		local rs_init = dnd3.rulesets_path .. "/dnd35/init.lua"
		local insecure = core.request_insecure_environment and core.request_insecure_environment()
		local io_open = io.open
		if insecure and insecure.io and insecure.io.open then
			io_open = insecure.io.open
		end

		local function load_ruleset_file(path)
			local chunk, load_err
			if insecure and insecure.loadfile then
				chunk, load_err = insecure.loadfile(path)
			else
				chunk, load_err = loadfile(path)
			end
			if not chunk then
				return false, load_err
			end
			local ok, run_err = pcall(chunk)
			if not ok then
				return false, run_err
			end
			return true
		end

		local fallback_reason
		local ok_open, file_or_err = pcall(io_open, rs_init, "r")
		if ok_open and file_or_err then
			file_or_err:close()
			local ok_load, load_err = load_ruleset_file(rs_init)
			if not ok_load then
				fallback_reason = tostring(load_err)
			end
		else
			fallback_reason = tostring(file_or_err)
		end

		if fallback_reason then
			core.log("warning", "[dnd3_core] could not load ruleset init: " .. rs_init
				.. " (" .. fallback_reason .. ")"
				.. " — falling back to stub registration. "
				.. "If using external rulesets, set secure.enable_security=false for local dev "
				.. "or trust this mod and use request_insecure_environment.")
			dnd3.register_ruleset({
				id      = "dnd35",
				title   = "Dungeons and Dragons 3.5e",
				version = "0.1.0-dnd3",
			})
		end
	else
		core.log("warning", "[dnd3_core] could not derive workspace root from modpath '"
			.. tostring(modpath) .. "'")
	end
end

-- ── Static prefab loader ───────────────────────────────────────────────────
-- Prefab definition files live in <game_dir>/prefabs/<category>/<name>.lua
-- Each file calls dnd3.register_static_prefab(id, def) to register at startup.
do
	local game_dir = modpath:match("^(.*)/mods/[^/]+$")
	if game_dir then
		dnd3.prefabs_path = game_dir .. "/prefabs"
		local prefab_files = {
			"trees/oak.lua",
			"trees/pine.lua",
			"rocks/boulder.lua",
			"props/crate.lua",
			"props/barrel.lua",
			"monsters/goblin.lua",
			"kaykit/init.lua",
		}
		for _, rel in ipairs(prefab_files) do
			local path = dnd3.prefabs_path .. "/" .. rel
			local chunk, err = loadfile(path)
			if chunk then
				local ok, run_err = pcall(chunk)
				if not ok then
					core.log("warning", "[dnd3_core] static prefab " .. rel .. " error: " .. tostring(run_err))
				end
			else
				core.log("warning", "[dnd3_core] static prefab " .. rel .. " not found: " .. tostring(err))
			end
		end
	end
end

core.log("action", "[dnd3_core] initialized v" .. dnd3.version)
