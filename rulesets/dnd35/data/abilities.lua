-- D&D 3.5e SRD -- Ability Scores
-- Open Game Content under OGL v1.0a.
--
-- Registers the six core ability score sheet fields and provides the
-- central modifier-computation function used throughout the ruleset.

local RS = "dnd35"

-- ─────────────────────────────────────────────────────────────────────────────
-- Core ability score definitions
-- ─────────────────────────────────────────────────────────────────────────────

local ABILITIES = {
	{
		id      = "str",
		label   = "Strength",
		abbrev  = "STR",
		default = 10,
		desc    = "Measures physical power.  Applies to melee attacks, melee "
		          .. "damage, Climb/Jump/Swim checks, and Strength checks.",
	},
	{
		id      = "dex",
		label   = "Dexterity",
		abbrev  = "DEX",
		default = 10,
		desc    = "Measures agility.  Applies to ranged attacks, AC, Reflex "
		          .. "saves, and Dex-based skills.",
	},
	{
		id      = "con",
		label   = "Constitution",
		abbrev  = "CON",
		default = 10,
		desc    = "Measures health and stamina.  Applies to HP per hit die, "
		          .. "Fortitude saves, and Concentration checks.",
	},
	{
		id      = "int",
		label   = "Intelligence",
		abbrev  = "INT",
		default = 10,
		desc    = "Measures reasoning.  Applies to skill points per level, "
		          .. "extra languages, and Int-based skills.",
	},
	{
		id      = "wis",
		label   = "Wisdom",
		abbrev  = "WIS",
		default = 10,
		desc    = "Measures perception and intuition.  Applies to Will saves "
		          .. "and Wis-based skills.",
	},
	{
		id      = "cha",
		label   = "Charisma",
		abbrev  = "CHA",
		default = 10,
		desc    = "Measures force of personality.  Applies to turning undead "
		          .. "and Cha-based skills.",
	},
}

for _, ab in ipairs(ABILITIES) do
	dnd3.register_sheet_field(RS, {
		id      = ab.id,
		label   = ab.label,
		abbrev  = ab.abbrev,
		default = ab.default,
		min     = 1,
		max     = 100,
		desc    = ab.desc,
		type    = "number",
		category = "ability_score",
	})
	-- Derived modifier field (computed, default 0)
	dnd3.register_sheet_field(RS, {
		id      = ab.id .. "_mod",
		label   = ab.label .. " Modifier",
		default = 0,
		type    = "number",
		computed = true,
		category = "ability_modifier",
	})
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Utility: ability modifier formula (SRD p.8)
-- ─────────────────────────────────────────────────────────────────────────────

--- Compute the ability modifier for a raw ability score.
--- Formula: floor((score - 10) / 2)
--- @param score number  raw ability score (1-based, min 1)
--- @return number  modifier (-5 for score 1, 0 for 10-11, +5 for 20-21, …)
function dnd3.dnd35.ability_mod(score)
	return math.floor((score - 10) / 2)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Bonus spell table (SRD p.8)
-- spells_per_level[score_mod + 4][spell_level]  → bonus spells
-- Score mods tracked: -4 to +10 (scores 2-3 to 28-29)
-- ─────────────────────────────────────────────────────────────────────────────
-- Bonus spells are granted to spellcasters whose key ability score (INT for
-- wizards, WIS for clerics/druids/paladins/rangers, CHA for sorcerers/bards)
-- exceeds 10.  The table below maps ability score to bonus slots per spell
-- level 1–9.  A score of 10 or 11 grants no bonus spells (score mod 0).

-- bonus_spells[score_mod][spell_level] = bonus_spell_slots
-- score_mod ranges 1..10 (score 12-13 → mod 1, …, score 28-29 → mod 10)
local BONUS_SPELLS = {
	-- mod=1 (score 12-13)
	[1]  = { [1]=1 },
	-- mod=2 (score 14-15)
	[2]  = { [1]=1, [2]=1 },
	-- mod=3 (score 16-17)
	[3]  = { [1]=1, [2]=1, [3]=1 },
	-- mod=4 (score 18-19)
	[4]  = { [1]=1, [2]=1, [3]=1, [4]=1 },
	-- mod=5 (score 20-21)
	[5]  = { [1]=2, [2]=1, [3]=1, [4]=1, [5]=1 },
	-- mod=6 (score 22-23)
	[6]  = { [1]=2, [2]=2, [3]=1, [4]=1, [5]=1, [6]=1 },
	-- mod=7 (score 24-25)
	[7]  = { [1]=2, [2]=2, [3]=2, [4]=1, [5]=1, [6]=1, [7]=1 },
	-- mod=8 (score 26-27)
	[8]  = { [1]=2, [2]=2, [3]=2, [4]=2, [5]=1, [6]=1, [7]=1, [8]=1 },
	-- mod=9 (score 28-29)
	[9]  = { [1]=3, [2]=2, [3]=2, [4]=2, [5]=2, [6]=1, [7]=1, [8]=1, [9]=1 },
	-- mod=10 (score 30-31)
	[10] = { [1]=3, [2]=3, [3]=2, [4]=2, [5]=2, [6]=2, [7]=1, [8]=1, [9]=1 },
}

--- Return the number of bonus spell slots at a given spell level for an
--- ability score.  Returns 0 if score mod is ≤ 0 or spell level > 9.
--- @param score      number  ability score
--- @param spell_level number  1–9
--- @return number  bonus spell slots
function dnd3.dnd35.bonus_spells(score, spell_level)
	local mod = dnd3.dnd35.ability_mod(score)
	if mod <= 0 then return 0 end
	local row = BONUS_SPELLS[mod]
	if not row then return 0 end
	return row[spell_level] or 0
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Register: ability score extra sheet fields
-- ─────────────────────────────────────────────────────────────────────────────

-- Temporary ability damage / drain (subtracted before computing modifier)
for _, ab in ipairs(ABILITIES) do
	dnd3.register_sheet_field(RS, {
		id      = ab.id .. "_damage",
		label   = ab.label .. " Damage",
		default = 0,
		min     = 0,
		type    = "number",
		computed = false,
		category = "ability_score_damage",
	})
	dnd3.register_sheet_field(RS, {
		id      = ab.id .. "_drain",
		label   = ab.label .. " Drain",
		default = 0,
		min     = 0,
		type    = "number",
		computed = false,
		category = "ability_score_drain",
	})
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Compute hook: derive *_mod fields from raw scores + damage/drain
-- Priority 10 — runs first so all later hooks can read ability mods.
-- ─────────────────────────────────────────────────────────────────────────────

local ABILITY_IDS = { "str", "dex", "con", "int", "wis", "cha" }

dnd3.character.register_compute_hook(function(sheet, ruleset_id)
	if ruleset_id ~= RS then return end
	for _, ab in ipairs(ABILITY_IDS) do
		local score   = tonumber(sheet[ab]) or 10
		local damage  = tonumber(sheet[ab .. "_damage"]) or 0
		local drain   = tonumber(sheet[ab .. "_drain"]) or 0
		local eff     = math.max(1, score - damage - drain)
		sheet[ab .. "_mod"] = dnd3.dnd35.ability_mod(eff)
	end
end, 10)
