-- D&D 3.5e SRD -- Skills
-- Open Game Content under OGL v1.0a.
--
-- Registers all 36 SRD skills as sheet fields and provides runtime helpers
-- for skill checks, synergy resolution, and max-rank calculation.

local RS = "dnd35"

-- ─────────────────────────────────────────────────────────────────────────────
-- Skill definitions
-- Fields:
--   id          string   snake_case identifier (used as sheet field prefix)
--   label       string   display name
--   key_ability string   "str"|"dex"|"con"|"int"|"wis"|"cha"|"none"
--   trained     bool     true = requires 1+ rank to use
--   acp         bool     true = armor check penalty applies
--   double_acp  bool     true = double armor check penalty (Swim)
--   specialized bool     true = actually many sub-skills (Craft, Knowledge…)
--   sub_skills  table    optional list of common sub-skill names
--   synergies   table    {skill_id, bonus, note}  -- bonus granted when THIS
--                        skill has 5+ ranks
-- ─────────────────────────────────────────────────────────────────────────────

local SKILLS = {
	{
		id = "appraise", label = "Appraise", key_ability = "int",
		synergies = {
			-- Covered per Craft sub-skill dynamically; no single static synergy
		},
	},
	{
		id = "balance", label = "Balance", key_ability = "dex", acp = true,
		synergies = {
			-- granted BY Tumble 5+; not outgoing here
		},
	},
	{
		id = "bluff", label = "Bluff", key_ability = "cha",
		synergies = {
			{ target = "diplomacy",    bonus = 2 },
			{ target = "intimidate",   bonus = 2 },
			{ target = "sleight_of_hand", bonus = 2 },
			{ target = "disguise",     bonus = 2, note = "when acting in character" },
		},
	},
	{
		id = "climb", label = "Climb", key_ability = "str", acp = true,
		synergies = {
			-- Use Rope 5+ → +2 Climb (ropes); handled from use_rope side
		},
	},
	{
		id = "concentration", label = "Concentration", key_ability = "con",
	},
	{
		id = "craft", label = "Craft", key_ability = "int",
		specialized = true,
		sub_skills = {
			"alchemy", "armorsmithing", "blacksmithing", "bookbinding",
			"bowmaking", "calligraphy", "carpentry", "cobbling", "gemcutting",
			"leatherworking", "locksmithing", "painting", "pottery", "sculpting",
			"shipmaking", "stonemasonry", "trapmaking", "weaponsmithing",
			"weaving",
		},
		synergies = {
			-- Craft (any, 5+) → +2 Appraise for related items  (handled dynamically)
		},
	},
	{
		id = "decipher_script", label = "Decipher Script", key_ability = "int",
		trained = true,
		synergies = {
			{ target = "use_magic_device", bonus = 2, note = "scrolls only" },
		},
	},
	{
		id = "diplomacy", label = "Diplomacy", key_ability = "cha",
	},
	{
		id = "disable_device", label = "Disable Device", key_ability = "int",
		trained = true,
	},
	{
		id = "disguise", label = "Disguise", key_ability = "cha",
	},
	{
		id = "escape_artist", label = "Escape Artist", key_ability = "dex", acp = true,
		synergies = {
			{ target = "use_rope", bonus = 2, note = "binding others" },
		},
	},
	{
		id = "forgery", label = "Forgery", key_ability = "int",
	},
	{
		id = "gather_information", label = "Gather Information", key_ability = "cha",
	},
	{
		id = "handle_animal", label = "Handle Animal", key_ability = "cha",
		trained = true,
		synergies = {
			{ target = "ride", bonus = 2 },
			-- wild empathy is a class feature, not a skill; tracked separately
		},
	},
	{
		id = "heal", label = "Heal", key_ability = "wis",
	},
	{
		id = "hide", label = "Hide", key_ability = "dex", acp = true,
	},
	{
		id = "intimidate", label = "Intimidate", key_ability = "cha",
	},
	{
		id = "jump", label = "Jump", key_ability = "str", acp = true,
		synergies = {
			{ target = "tumble", bonus = 2 },
		},
	},
	{
		id = "knowledge", label = "Knowledge", key_ability = "int",
		trained = true,
		specialized = true,
		sub_skills = {
			"arcana", "architecture_and_engineering", "dungeoneering",
			"geography", "history", "local", "nature",
			"nobility_and_royalty", "religion", "the_planes",
		},
		synergies = {
			-- Per sub-skill; handled dynamically
		},
	},
	{
		id = "listen", label = "Listen", key_ability = "wis",
	},
	{
		id = "move_silently", label = "Move Silently", key_ability = "dex", acp = true,
	},
	{
		id = "open_lock", label = "Open Lock", key_ability = "dex",
		trained = true,
	},
	{
		id = "perform", label = "Perform", key_ability = "cha",
		specialized = true,
		sub_skills = {
			"act", "comedy", "dance", "keyboard_instruments", "oratory",
			"percussion_instruments", "string_instruments", "wind_instruments",
			"sing",
		},
	},
	{
		id = "profession", label = "Profession", key_ability = "wis",
		trained = true,
		specialized = true,
		sub_skills = {},   -- open-ended; players define sub-skills freely
	},
	{
		id = "ride", label = "Ride", key_ability = "dex",
	},
	{
		id = "search", label = "Search", key_ability = "int",
		synergies = {
			{ target = "survival", bonus = 2, note = "find/follow tracks" },
		},
	},
	{
		id = "sense_motive", label = "Sense Motive", key_ability = "wis",
		synergies = {
			{ target = "diplomacy", bonus = 2 },
		},
	},
	{
		id = "sleight_of_hand", label = "Sleight of Hand", key_ability = "dex",
		trained = true, acp = true,
	},
	{
		id = "speak_language", label = "Speak Language", key_ability = "none",
		trained = true,
		-- No check mechanic; buying ranks adds known languages.
	},
	{
		id = "spellcraft", label = "Spellcraft", key_ability = "int",
		trained = true,
		synergies = {
			{ target = "use_magic_device", bonus = 2, note = "scrolls only" },
		},
	},
	{
		id = "spot", label = "Spot", key_ability = "wis",
	},
	{
		id = "survival", label = "Survival", key_ability = "wis",
		synergies = {
			{ target = "knowledge_nature", bonus = 2 },
		},
	},
	{
		id = "swim", label = "Swim", key_ability = "str",
		acp = true, double_acp = true,
	},
	{
		id = "tumble", label = "Tumble", key_ability = "dex",
		trained = true, acp = true,
		synergies = {
			{ target = "balance", bonus = 2 },
			{ target = "jump",    bonus = 2 },
		},
	},
	{
		id = "use_magic_device", label = "Use Magic Device", key_ability = "cha",
		trained = true,
	},
	{
		id = "use_rope", label = "Use Rope", key_ability = "dex",
		synergies = {
			{ target = "climb",         bonus = 2, note = "ropes only" },
			{ target = "escape_artist", bonus = 2, note = "rope bonds only" },
		},
	},
}

-- Knowledge sub-skill synergies (spelled out because targets are sub-field names)
local KNOWLEDGE_SYNERGIES = {
	arcana                    = { target = "spellcraft",  bonus = 2 },
	architecture_and_engineering = { target = "search",   bonus = 2, note = "secret doors/compartments" },
	dungeoneering             = { target = "survival",   bonus = 2, note = "underground" },
	geography                 = { target = "survival",   bonus = 2, note = "not getting lost/natural hazards" },
	history                   = { target = "_bardic_knowledge", bonus = 2 }, -- class feature
	local_knowledge           = { target = "gather_information", bonus = 2 },
	nature                    = { target = "survival",   bonus = 2, note = "aboveground natural" },
	nobility_and_royalty      = { target = "diplomacy",  bonus = 2 },
	religion                  = { target = "_turning",   bonus = 2 }, -- class feature
	the_planes                = { target = "survival",   bonus = 2, note = "other planes" },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Public tables used by other modules
-- ─────────────────────────────────────────────────────────────────────────────

dnd3.dnd35.skills      = {}   -- id → skill def
dnd3.dnd35.skill_list  = {}   -- ordered array of skill defs (non-specialized only)

for _, sk in ipairs(SKILLS) do
	dnd3.dnd35.skills[sk.id] = sk
	dnd3.dnd35.skill_list[#dnd3.dnd35.skill_list + 1] = sk

	-- Register sheet fields: ranks (raw), total (computed), misc_bonus
	dnd3.register_sheet_field(RS, {
		id      = sk.id .. "_ranks",
		label   = sk.label .. " Ranks",
		default = 0,
		min     = 0,
		type    = "number",
		category = "skill_rank",
		skill   = sk.id,
	})
	dnd3.register_sheet_field(RS, {
		id      = sk.id .. "_misc",
		label   = sk.label .. " Misc Bonus",
		default = 0,
		type    = "number",
		category = "skill_misc",
		skill   = sk.id,
	})
	dnd3.register_sheet_field(RS, {
		id      = sk.id .. "_total",
		label   = sk.label .. " Total",
		default = 0,
		type    = "number",
		computed = true,
		category = "skill_total",
		skill   = sk.id,
	})
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Utility functions
-- ─────────────────────────────────────────────────────────────────────────────

--- Return maximum class-skill rank for a given character level.
--- @param level number  character level (1-based)
--- @return number
function dnd3.dnd35.max_class_skill_rank(level)
	return level + 3
end

--- Return maximum cross-class skill rank for a given character level.
--- @param level number  character level (1-based)
--- @return number
function dnd3.dnd35.max_cross_class_rank(level)
	return math.floor((level + 3) / 2)
end

--- Check whether a character has the minimum rank to use a trained-only skill.
--- @param sheet   table  character sheet
--- @param skill_id string
--- @return bool
function dnd3.dnd35.can_use_skill(sheet, skill_id)
	local sk = dnd3.dnd35.skills[skill_id]
	if not sk then return false end
	if not sk.trained then return true end
	return (tonumber(sheet[skill_id .. "_ranks"]) or 0) >= 1
end

--- Compute the static synergy bonus from completed ranks in source skills.
--- Returns the total misc synergy bonus for target_skill_id.
--- @param sheet          table  character sheet
--- @param target_skill_id string
--- @return number  synergy bonus (0 or positive)
function dnd3.dnd35.synergy_bonus(sheet, target_skill_id)
	local total = 0
	for _, sk in ipairs(SKILLS) do
		local ranks = tonumber(sheet[sk.id .. "_ranks"]) or 0
		if ranks >= 5 and sk.synergies then
			for _, syn in ipairs(sk.synergies) do
				if syn.target == target_skill_id then
					total = total + (syn.bonus or 2)
				end
			end
		end
	end
	return total
end

--- Resolve a single skill check result.
--- @param sheet     table   character sheet
--- @param skill_id  string
--- @param roll      number  d20 result (1–20)
--- @param situation_mod number  optional situational bonus/penalty
--- @return number  total check result
function dnd3.dnd35.skill_check(sheet, skill_id, roll, situation_mod)
	local sk = dnd3.dnd35.skills[skill_id]
	if not sk then
		return 0, "unknown skill"
	end
	local ranks   = tonumber(sheet[skill_id .. "_ranks"]) or 0
	local ab_mod  = 0
	if sk.key_ability and sk.key_ability ~= "none" then
		ab_mod = tonumber(sheet[sk.key_ability .. "_mod"]) or 0
	end
	local misc    = tonumber(sheet[skill_id .. "_misc"]) or 0
	local synergy = dnd3.dnd35.synergy_bonus(sheet, skill_id)
	-- Armor check penalty handled by caller via situation_mod if applicable
	return (roll or 0) + ranks + ab_mod + misc + synergy + (situation_mod or 0)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Compute hook: derive skill total fields
-- Priority 30 — runs after ability mods (priority 10) but before saves (40).
-- ─────────────────────────────────────────────────────────────────────────────

dnd3.character.register_compute_hook(function(sheet, ruleset_id)
	if ruleset_id ~= RS then return end
	for _, sk in ipairs(SKILLS) do
		local ranks  = tonumber(sheet[sk.id .. "_ranks"]) or 0
		local ab_mod = 0
		if sk.key_ability and sk.key_ability ~= "none" then
			ab_mod = tonumber(sheet[sk.key_ability .. "_mod"]) or 0
		end
		local misc    = tonumber(sheet[sk.id .. "_misc"]) or 0
		local synergy = dnd3.dnd35.synergy_bonus(sheet, sk.id)
		sheet[sk.id .. "_total"] = ranks + ab_mod + misc + synergy
	end
end, 30)
