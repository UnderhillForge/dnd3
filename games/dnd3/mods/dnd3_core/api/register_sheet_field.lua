function dnd3.register_sheet_field(ruleset_id, field)
	if type(ruleset_id) ~= "string" or ruleset_id == "" then
		error("dnd3.register_sheet_field: ruleset_id must be a non-empty string")
	end
	if type(field) ~= "table" then
		error("dnd3.register_sheet_field: field must be a table")
	end
	if type(field.id) ~= "string" or field.id == "" then
		error("dnd3.register_sheet_field: field.id must be a non-empty string")
	end

	local bucket = dnd3._state.sheet_fields[ruleset_id]
	if not bucket then
		bucket = {}
		dnd3._state.sheet_fields[ruleset_id] = bucket
	end

	bucket[field.id] = field
	return field
end

function dnd3.get_sheet_fields(ruleset_id)
	return dnd3._state.sheet_fields[ruleset_id] or {}
end
