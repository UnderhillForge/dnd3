-- D&D 3.5e Formula Helpers - Combat
-- Open Game Content, licensed under OGL v1.0a

dnd35 = dnd35 or {}
dnd35.formulas = dnd35.formulas or {}

local function n(v, d)
	return tonumber(v) or d or 0
end

function dnd35.formulas.ac_breakdown(sheet)
	return {
		base = 10,
		armor = n(sheet.armor_bonus),
		shield = n(sheet.shield_bonus),
		dex = n(sheet.dex_mod),
		natural = n(sheet.natural_armor),
		deflection = n(sheet.deflection_bonus),
		size = n(sheet.size_modifier),
		total = n(sheet.ac, 10),
		touch = n(sheet.ac_touch, 10),
		flat_footed = n(sheet.ac_flat_footed, 10),
	}
end

function dnd35.formulas.attack_block(sheet)
	return {
		bab = n(sheet.bab),
		melee_attack = n(sheet.melee_attack_bonus),
		ranged_attack = n(sheet.ranged_attack_bonus),
		melee_damage = n(sheet.melee_damage_bonus),
		two_handed_damage = n(sheet.two_handed_damage_bonus),
		offhand_damage = n(sheet.offhand_damage_bonus),
	}
end
