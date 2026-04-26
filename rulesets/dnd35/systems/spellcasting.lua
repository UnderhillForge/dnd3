-- D&D 3.5e SRD Spellcasting System
-- Open Game Content, licensed under OGL v1.0a
--
-- Implements slot tracking and concentration helpers.
-- Slot progression itself is intentionally data-driven:
--   - `spell_slots_base` holds per-class base slots/day (set by UI/GM/tools)
--   - this module computes bonus slots from key casting ability
--   - total/remaining slots are then consumed by cast helpers

dnd35 = dnd35 or {}
dnd35.spell = dnd35.spell or {}
dnd3.dnd35 = dnd3.dnd35 or {}

local RS = "dnd35"

-- Raw / computed sheet fields for spellcasting.
dnd3.register_sheet_field(RS, {
	id = "spell_slots_base", type = "table", default = {},
	label = "Spell Slots Base",
})
dnd3.register_sheet_field(RS, {
	id = "spell_slots_bonus", type = "table", default = {},
	label = "Spell Slots Bonus",
})
dnd3.register_sheet_field(RS, {
	id = "spell_slots_total", type = "table", default = {},
	label = "Spell Slots Total",
})
dnd3.register_sheet_field(RS, {
	id = "spell_slots_used", type = "table", default = {},
	label = "Spell Slots Used",
})
dnd3.register_sheet_field(RS, {
	id = "prepared_spells", type = "table", default = {},
	label = "Prepared Spells",
})
dnd3.register_sheet_field(RS, {
	id = "concentration_misc", type = "number", default = 0,
	label = "Concentration Misc",
})
dnd3.register_sheet_field(RS, {
	id = "concentration_total", type = "number", default = 0,
	label = "Concentration Total",
})

local function clamp_nonneg_int(v)
	return math.max(0, math.floor(tonumber(v) or 0))
end

local function shallow_copy(t)
	local out = {}
	for k, v in pairs(t or {}) do out[k] = v end
	return out
end

local function get_sheet(token_id)
	local sheet = dnd3.character.get(token_id)
	if not sheet then
		return nil, "token has no character sheet"
	end
	if sheet.ruleset_id and sheet.ruleset_id ~= RS then
		return nil, "token ruleset is not dnd35"
	end
	return sheet
end

local function normalize_level_map(level_map)
	local out = {}
	for k, v in pairs(level_map or {}) do
		local lvl = tonumber(k)
		if lvl then
			out[math.floor(lvl)] = clamp_nonneg_int(v)
		end
	end
	return out
end

local function get_level(sheet, class_id)
	local class_levels = sheet.class_levels or {}
	return clamp_nonneg_int(class_levels[class_id])
end

local function get_class(class_id)
	return dnd35.CLASSES and dnd35.CLASSES[class_id] or nil
end

local function class_is_caster(class_id)
	local class_def = get_class(class_id)
	return class_def and class_def.spell_ability ~= nil
end

local function class_can_cast_now(sheet, class_id)
	local class_def = get_class(class_id)
	if not class_def or not class_def.spell_ability then
		return false
	end
	local lvl = get_level(sheet, class_id)
	local start = clamp_nonneg_int(class_def.spell_start_level or 1)
	return lvl >= start
end

local function get_class_slot_map(map, class_id)
	local cls = map and map[class_id]
	if type(cls) ~= "table" then
		return {}
	end
	return normalize_level_map(cls)
end

local function set_class_slot_map(map, class_id, level_map)
	map = shallow_copy(map)
	map[class_id] = normalize_level_map(level_map)
	return map
end

local function compute_bonus_slots_for_class(sheet, class_id, base_map)
	local class_def = get_class(class_id)
	if not class_def or not class_def.spell_ability then
		return {}
	end
	if not class_can_cast_now(sheet, class_id) then
		return {}
	end

	local ability_score = clamp_nonneg_int(sheet[class_def.spell_ability] or 10)
	local bonus = {}
	for spell_level, base_count in pairs(base_map) do
		spell_level = clamp_nonneg_int(spell_level)
		base_count = clamp_nonneg_int(base_count)
		if spell_level > 0 and base_count > 0 then
			bonus[spell_level] = dnd3.dnd35.bonus_spells(ability_score, spell_level)
		end
	end
	return bonus
end

local function compute_spellcasting(sheet)
	local slots_base = sheet.spell_slots_base or {}
	local slots_bonus = {}
	local slots_total = {}

	for class_id, class_map in pairs(slots_base) do
		if class_is_caster(class_id) then
			local base = normalize_level_map(class_map)
			local bonus = compute_bonus_slots_for_class(sheet, class_id, base)
			local total = {}
			for lvl, count in pairs(base) do
				total[lvl] = clamp_nonneg_int(count) + clamp_nonneg_int(bonus[lvl])
			end
			slots_bonus[class_id] = bonus
			slots_total[class_id] = total
		end
	end

	sheet.spell_slots_bonus = slots_bonus
	sheet.spell_slots_total = slots_total
	sheet.concentration_total = clamp_nonneg_int(sheet.skill_concentration_total) + clamp_nonneg_int(sheet.concentration_misc)
end

-- Priority 30: runs after ability/skill/combat hooks.
dnd3.character.register_compute_hook(function(sheet, ruleset_id)
	if ruleset_id ~= RS then return end
	compute_spellcasting(sheet)
end, 30)

--- Return slot state for a given caster class on a token.
--- Returns: {base, bonus, total, used, remaining, class_level, spell_ability}
function dnd35.spell.get_slots(token_id, class_id)
	local sheet, err = get_sheet(token_id)
	if not sheet then return nil, err end
	local class_def = get_class(class_id)
	if not class_def then return nil, "unknown class: " .. tostring(class_id) end
	if not class_def.spell_ability then return nil, "class is not a spellcaster" end

	local base = get_class_slot_map(sheet.spell_slots_base, class_id)
	local bonus = get_class_slot_map(sheet.spell_slots_bonus, class_id)
	local total = get_class_slot_map(sheet.spell_slots_total, class_id)
	local used = get_class_slot_map(sheet.spell_slots_used, class_id)
	local remaining = {}
	for lvl, t in pairs(total) do
		remaining[lvl] = math.max(0, clamp_nonneg_int(t) - clamp_nonneg_int(used[lvl]))
	end

	return {
		base = base,
		bonus = bonus,
		total = total,
		used = used,
		remaining = remaining,
		class_level = get_level(sheet, class_id),
		spell_ability = class_def.spell_ability,
	}
end

--- Set base slots/day table for one casting class.
--- slots_by_level example: { [0]=4, [1]=3, [2]=2 }
function dnd35.spell.set_base_slots(token_id, class_id, slots_by_level)
	local sheet, err = get_sheet(token_id)
	if not sheet then return false, err end
	if not class_is_caster(class_id) then
		return false, "class is not a spellcaster"
	end

	local base = set_class_slot_map(sheet.spell_slots_base or {}, class_id, slots_by_level or {})
	dnd3.character.set(token_id, "spell_slots_base", base)
	dnd3.character.compute(token_id)
	return true
end

--- Reset used spell slots. If class_id is nil, reset all classes.
function dnd35.spell.reset_slots(token_id, class_id)
	local sheet, err = get_sheet(token_id)
	if not sheet then return false, err end

	local used = shallow_copy(sheet.spell_slots_used or {})
	if class_id then
		used[class_id] = {}
	else
		used = {}
	end
	dnd3.character.set(token_id, "spell_slots_used", used)
	dnd3.character.compute(token_id)
	return true
end

--- Consume one slot of class_id / spell_level.
function dnd35.spell.consume_slot(token_id, class_id, spell_level, count)
	local sheet, err = get_sheet(token_id)
	if not sheet then return false, err end
	spell_level = clamp_nonneg_int(spell_level)
	count = clamp_nonneg_int(count or 1)
	if count < 1 then return false, "count must be >= 1" end

	local slots, serr = dnd35.spell.get_slots(token_id, class_id)
	if not slots then return false, serr end
	local rem = clamp_nonneg_int(slots.remaining[spell_level])
	if rem < count then
		return false, "not enough slots remaining"
	end

	local used_all = shallow_copy(sheet.spell_slots_used or {})
	local used_class = get_class_slot_map(used_all, class_id)
	used_class[spell_level] = clamp_nonneg_int(used_class[spell_level]) + count
	used_all[class_id] = used_class

	dnd3.character.set(token_id, "spell_slots_used", used_all)
	dnd3.character.compute(token_id)
	return true
end

--- Checks whether a token can cast a specific spell through class_id.
--- opts: { ignore_slots = boolean }
function dnd35.spell.can_cast(token_id, spell_id, class_id, opts)
	opts = opts or {}
	local sheet, err = get_sheet(token_id)
	if not sheet then return false, err end

	local spell_def = dnd35.SPELLS and dnd35.SPELLS[spell_id]
	if not spell_def then
		return false, "unknown spell: " .. tostring(spell_id)
	end

	if not class_can_cast_now(sheet, class_id) then
		return false, "class cannot cast spells at current level"
	end

	local spell_level = spell_def.level and spell_def.level[class_id]
	if spell_level == nil then
		return false, "spell is not on that class list"
	end
	spell_level = clamp_nonneg_int(spell_level)

	if not opts.ignore_slots then
		local slots, serr = dnd35.spell.get_slots(token_id, class_id)
		if not slots then return false, serr end
		if clamp_nonneg_int(slots.remaining[spell_level]) < 1 then
			return false, "no spell slots remaining"
		end
	end

	return true, nil, {
		spell_id = spell_id,
		class_id = class_id,
		spell_level = spell_level,
	}
end

--- Cast a spell by consuming a slot.
--- Returns { ok=true, spell_id, class_id, spell_level } or false, err.
function dnd35.spell.cast(token_id, spell_id, class_id, opts)
	opts = opts or {}
	local ok, err, ctx = dnd35.spell.can_cast(token_id, spell_id, class_id, opts)
	if not ok then return false, err end

	if not opts.ignore_slots then
		local c_ok, c_err = dnd35.spell.consume_slot(token_id, class_id, ctx.spell_level, 1)
		if not c_ok then return false, c_err end
	end

	return {
		ok = true,
		spell_id = ctx.spell_id,
		class_id = ctx.class_id,
		spell_level = ctx.spell_level,
	}
end

--- Concentration DC helper for damage while casting/maintaining.
--- Standard SRD case: 10 + damage_dealt + spell_level.
function dnd35.spell.concentration_dc_from_damage(damage_dealt, spell_level)
	return 10 + clamp_nonneg_int(damage_dealt) + clamp_nonneg_int(spell_level)
end

--- Perform concentration check: d20 + concentration_total + opts.misc vs dc.
--- opts: { misc = number }
function dnd35.spell.concentration_check(token_id, dc, opts)
	opts = opts or {}
	local sheet, err = get_sheet(token_id)
	if not sheet then return nil, err end
	dc = clamp_nonneg_int(dc)

	local roll = dnd3.roll("1d20", { token_id = token_id })
	local bonus = clamp_nonneg_int(sheet.concentration_total) + clamp_nonneg_int(opts.misc)
	local total = roll.total + bonus

	return {
		dc = dc,
		roll = roll.total,
		bonus = bonus,
		total = total,
		success = total >= dc,
	}
end

--- Convenience helper: concentration check from damage and spell level.
function dnd35.spell.concentration_check_from_damage(token_id, damage_dealt, spell_level, opts)
	local dc = dnd35.spell.concentration_dc_from_damage(damage_dealt, spell_level)
	return dnd35.spell.concentration_check(token_id, dc, opts)
end
