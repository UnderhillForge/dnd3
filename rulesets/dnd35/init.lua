-- D&D 3.5e SRD Ruleset — Entry Point
-- Open Game Content, licensed under OGL v1.0a
--
-- Loaded by dnd3_core after all core APIs are available.
-- Establishes the `dnd35` global namespace and loads all data/system files.

dnd35 = dnd35 or {}
dnd3.dnd35 = dnd3.dnd35 or {}

-- Path to this ruleset directory (set by dnd3_core before calling dofile).
local BASE = dnd3.rulesets_path .. "/dnd35"

local insecure = core.request_insecure_environment and core.request_insecure_environment()

local function rs_dofile(path)
	if insecure and insecure.loadfile then
		local chunk, load_err = insecure.loadfile(path)
		if not chunk then
			error(load_err)
		end
		local ok, run_err = pcall(chunk)
		if not ok then
			error(run_err)
		end
		return
	end
	dofile(path)
end

-- ── Data files (order matters: abilities before skills before compute) ───────
rs_dofile(BASE .. "/data/abilities.lua")
rs_dofile(BASE .. "/data/skills.lua")
rs_dofile(BASE .. "/data/conditions.lua")
rs_dofile(BASE .. "/data/classes.lua")

-- ── Sheet definition ─────────────────────────────────────────────────────────
rs_dofile(BASE .. "/sheets/character.lua")

-- ── Formula helpers ──────────────────────────────────────────────────────────
rs_dofile(BASE .. "/formulas/ability_mods.lua")
rs_dofile(BASE .. "/formulas/combat.lua")
rs_dofile(BASE .. "/formulas/skills.lua")

-- ── System files ─────────────────────────────────────────────────────────────
rs_dofile(BASE .. "/systems/character_compute.lua")

-- ── SRD data ─────────────────────────────────────────────────────────────────
rs_dofile(BASE .. "/data/feats.lua")
rs_dofile(BASE .. "/data/spells.lua")
rs_dofile(BASE .. "/data/weapons.lua")

-- ── Combat system ────────────────────────────────────────────────────────────
rs_dofile(BASE .. "/systems/combat.lua")

-- ── Spellcasting system ─────────────────────────────────────────────────────
rs_dofile(BASE .. "/systems/spellcasting.lua")

-- ── Register ruleset with core ───────────────────────────────────────────────
dnd3.register_ruleset({
	id      = "dnd35",
	title   = "Dungeons and Dragons 3.5e",
	version = "3.5",
	ogl     = true,
})

core.log("action", "[dnd35] ruleset loaded (D&D 3.5e SRD)")
