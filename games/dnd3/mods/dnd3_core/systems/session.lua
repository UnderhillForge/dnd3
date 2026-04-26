local storage = core.get_mod_storage()
local session_blob = storage:get_string("session")

if session_blob and session_blob ~= "" then
	local parsed = core.parse_json(session_blob)
	if type(parsed) == "table" then
		dnd3._state.session = parsed
	end
end

local function persist_session()
	storage:set_string("session", core.write_json(dnd3._state.session))
end

function dnd3.get_active_ruleset()
	return dnd3._state.session.active_ruleset
end

function dnd3.set_active_ruleset(id)
	if not dnd3.get_ruleset(id) then
		return false, "ruleset is not registered: " .. id
	end
	dnd3._state.session.active_ruleset = id
	persist_session()
	return true
end

function dnd3.set_session_name(name)
	if type(name) ~= "string" or name == "" then
		return false, "session name must be a non-empty string"
	end
	dnd3._state.session.session_name = name
	persist_session()
	return true
end

core.register_chatcommand("dnd3_ruleset", {
	params = "[list|set <id>|current]",
	description = "List or switch active dnd3 ruleset",
	func = function(name, param)
		param = (param or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if param == "" or param == "list" then
			local ids = {}
			for _, rs in ipairs(dnd3.list_rulesets()) do
				ids[#ids + 1] = rs.id
			end
			return true, "Rulesets: " .. table.concat(ids, ", ")
		end
		if param == "current" then
			return true, "Active ruleset: " .. dnd3.get_active_ruleset()
		end
		local target = param:match("^set%s+(%S+)$")
		if not target then
			return false, "Usage: /dnd3_ruleset [list|set <id>|current]"
		end
		if not dnd3.can(name, "ruleset_switch") then
			return false, "You are not allowed to switch rulesets"
		end
		local ok, err = dnd3.set_active_ruleset(target)
		if not ok then
			return false, err
		end
		core.chat_send_all("[dnd3] Active ruleset switched to " .. target)
		return true, "Active ruleset switched to " .. target
	end,
})
