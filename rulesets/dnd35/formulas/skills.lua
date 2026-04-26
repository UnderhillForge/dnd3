-- D&D 3.5e Formula Helpers - Skills
-- Open Game Content, licensed under OGL v1.0a

dnd35 = dnd35 or {}
dnd35.formulas = dnd35.formulas or {}

function dnd35.formulas.skill_total(sheet, skill_id)
	local key = "skill_" .. tostring(skill_id) .. "_total"
	return tonumber(sheet[key]) or 0
end

function dnd35.formulas.skill_breakdown(sheet, skill_id)
	local prefix = "skill_" .. tostring(skill_id)
	return {
		ranks = tonumber(sheet[prefix .. "_ranks"]) or 0,
		misc = tonumber(sheet[prefix .. "_misc"]) or 0,
		synergy = tonumber(sheet[prefix .. "_synergy"]) or 0,
		total = tonumber(sheet[prefix .. "_total"]) or 0,
	}
end

function dnd35.formulas.skill_snapshot(sheet, skill_ids)
	local out = {}
	for _, skill_id in ipairs(skill_ids or {}) do
		out[skill_id] = dnd35.formulas.skill_total(sheet, skill_id)
	end
	return out
end
