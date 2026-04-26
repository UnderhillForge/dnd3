local function sorted_entries()
	local entries = {}
	for token, score in pairs(dnd3._state.initiative.entries) do
		entries[#entries + 1] = { token = token, score = score }
	end
	table.sort(entries, function(a, b)
		if a.score == b.score then
			return a.token < b.token
		end
		return a.score > b.score
	end)
	return entries
end

function dnd3.initiative_set(token, score)
	dnd3._state.initiative.entries[token] = score
	return true
end

function dnd3.initiative_remove(token)
	dnd3._state.initiative.entries[token] = nil
	if dnd3._state.initiative.turn_index > 0 then
		dnd3._state.initiative.turn_index = math.max(1, dnd3._state.initiative.turn_index - 1)
	end
	return true
end

function dnd3.initiative_list()
	return sorted_entries()
end

function dnd3.initiative_next()
	local entries = sorted_entries()
	if #entries == 0 then
		return nil, "initiative is empty"
	end
	local idx = dnd3._state.initiative.turn_index + 1
	if idx > #entries then
		idx = 1
	end
	dnd3._state.initiative.turn_index = idx
	return entries[idx]
end

core.register_chatcommand("dnd3_init_add", {
	params = "<token> <score>",
	description = "Add or update an initiative entry",
	func = function(name, param)
		if not dnd3.can(name, "initiative_edit") then
			return false, "You are not allowed to edit initiative"
		end
		local token, score_s = param:match("^(%S+)%s+([%-]?%d+)$")
		if not token then
			return false, "Usage: /dnd3_init_add <token> <score>"
		end
		dnd3.initiative_set(token, tonumber(score_s))
		return true, "Initiative updated for " .. token
	end,
})

core.register_chatcommand("dnd3_init_next", {
	description = "Advance initiative to the next token",
	func = function(name)
		if not dnd3.can(name, "initiative_edit") then
			return false, "You are not allowed to advance initiative"
		end
		local next_entry, err = dnd3.initiative_next()
		if not next_entry then
			return false, err
		end
		local msg = string.format("[dnd3] Initiative turn: %s (%d)", next_entry.token, next_entry.score)
		core.chat_send_all(msg)
		return true, msg
	end,
})
