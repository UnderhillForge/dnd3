local function validate_ruleset(def)
	if type(def) ~= "table" then
		return false, "ruleset definition must be a table"
	end
	if type(def.id) ~= "string" or def.id == "" then
		return false, "ruleset.id must be a non-empty string"
	end
	if type(def.title) ~= "string" or def.title == "" then
		return false, "ruleset.title must be a non-empty string"
	end
	return true
end

function dnd3.register_ruleset(def)
	local ok, err = validate_ruleset(def)
	if not ok then
		error("dnd3.register_ruleset: " .. err)
	end

	dnd3._state.rulesets[def.id] = {
		id = def.id,
		title = def.title,
		version = def.version or "0.1.0-dnd3",
		source = def.source or "unknown",
		meta = def.meta or {},
	}

	return dnd3._state.rulesets[def.id]
end

function dnd3.get_ruleset(id)
	return dnd3._state.rulesets[id]
end

function dnd3.list_rulesets()
	local out = {}
	for _, ruleset in pairs(dnd3._state.rulesets) do
		out[#out + 1] = ruleset
	end
	table.sort(out, function(a, b)
		return a.id < b.id
	end)
	return out
end
