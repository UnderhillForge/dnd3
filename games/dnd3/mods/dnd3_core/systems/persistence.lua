local storage = core.get_mod_storage()

local function stable_ordered_keys(t)
	local out = {}
	for k in pairs(t) do
		out[#out + 1] = k
	end
	table.sort(out)
	return out
end

function dnd3.export_state()
	local payload = {
		version = dnd3.version,
		session = dnd3._state.session,
		initiative = dnd3._state.initiative,
		rulesets = dnd3.list_rulesets(),
		sheet_fields = dnd3._state.sheet_fields,
		tokens = dnd3.token_list(),
	}
	return payload
end

function dnd3.save_session_snapshot(name)
	if type(name) ~= "string" or name == "" then
		return nil, "snapshot name is required"
	end
	local snapshots = core.parse_json(storage:get_string("snapshots") or "")
	if type(snapshots) ~= "table" then
		snapshots = {}
	end
	snapshots[name] = dnd3.export_state()
	storage:set_string("snapshots", core.write_json(snapshots))
	return true
end

function dnd3.list_session_snapshots()
	local snapshots = core.parse_json(storage:get_string("snapshots") or "")
	if type(snapshots) ~= "table" then
		return {}
	end
	return stable_ordered_keys(snapshots)
end

core.register_chatcommand("dnd3_session_save", {
	params = "<snapshot_name>",
	description = "Save a lightweight dnd3 session snapshot",
	func = function(name, param)
		if not dnd3.can(name, "ruleset_switch") then
			return false, "You are not allowed to save session snapshots"
		end
		local snapshot = param:match("^(%S+)$")
		if not snapshot then
			return false, "Usage: /dnd3_session_save <snapshot_name>"
		end
		local ok, err = dnd3.save_session_snapshot(snapshot)
		if not ok then
			return false, err
		end
		return true, "Snapshot saved: " .. snapshot
	end,
})

core.register_chatcommand("dnd3_session_list", {
	description = "List saved dnd3 session snapshots",
	func = function()
		local snapshots = dnd3.list_session_snapshots()
		if #snapshots == 0 then
			return true, "No snapshots"
		end
		return true, "Snapshots: " .. table.concat(snapshots, ", ")
	end,
})
