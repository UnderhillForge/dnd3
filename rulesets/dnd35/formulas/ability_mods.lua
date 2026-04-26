-- D&D 3.5e Formula Helpers - Ability Mods
-- Open Game Content, licensed under OGL v1.0a

dnd35 = dnd35 or {}
dnd35.formulas = dnd35.formulas or {}

function dnd35.formulas.ability_mod(score)
	if dnd3.dnd35 and dnd3.dnd35.ability_mod then
		return dnd3.dnd35.ability_mod(score)
	end
	return math.floor(((tonumber(score) or 10) - 10) / 2)
end

function dnd35.formulas.ability_block(sheet)
	return {
		str = tonumber(sheet.str_mod) or dnd35.formulas.ability_mod(sheet.str),
		dex = tonumber(sheet.dex_mod) or dnd35.formulas.ability_mod(sheet.dex),
		con = tonumber(sheet.con_mod) or dnd35.formulas.ability_mod(sheet.con),
		int = tonumber(sheet.int_mod) or dnd35.formulas.ability_mod(sheet.int),
		wis = tonumber(sheet.wis_mod) or dnd35.formulas.ability_mod(sheet.wis),
		cha = tonumber(sheet.cha_mod) or dnd35.formulas.ability_mod(sheet.cha),
	}
end
