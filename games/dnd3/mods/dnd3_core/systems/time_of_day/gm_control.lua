-- GM Time-of-Day controls: set, freeze, speed, fast-forward.
-- All commands require map_edit permission (GM role).

core.register_chatcommand("dnd3_time_set", {
	params = "<HH:MM | fraction>",
	description = "GM: set time of day. '14:30' or fraction '0.5' for noon.",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		param = param:match("^%s*(.-)%s*$")
		if param == "" then
			return false, "Usage: /dnd3_time_set <HH:MM | fraction>"
		end

		local t
		-- Try HH:MM
		local hh, mm = param:match("^(%d+):(%d+)$")
		if hh then
			local total = tonumber(hh) * 60 + tonumber(mm)
			t = (total % 1440) / 1440
		else
			t = tonumber(param)
			if not t then
				return false, "Invalid time. Use HH:MM (e.g. '14:30') or fraction (e.g. '0.5')."
			end
		end

		local final = dnd3.tod.set(t)
		return true, string.format("Time set to %s (fraction=%.4f, period=%s).",
			dnd3.tod.to_hhmm(final), final, dnd3.tod.period(final))
	end,
})

core.register_chatcommand("dnd3_time_freeze", {
	params = "[on|off|toggle]",
	description = "GM: freeze or unfreeze the day/night cycle",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		param = (param or ""):match("^%s*(.-)%s*$"):lower()
		local state
		if param == "on" then
			state = true
		elseif param == "off" then
			state = false
		else
			state = not dnd3.tod.is_frozen()
		end
		dnd3.tod.freeze(state)
		return true, "Day/night cycle: " .. (state and "FROZEN" or "RUNNING") .. "."
	end,
})

core.register_chatcommand("dnd3_time_speed", {
	params = "<multiplier>",
	description = "GM: set day/night cycle speed. 1.0=default, 0=freeze, 10=10× fast",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local speed = tonumber(param)
		if not speed then
			return false, "Usage: /dnd3_time_speed <number>  (e.g. 2.0 for 2× speed)"
		end
		dnd3.tod.set_speed(speed)
		return true, string.format("Day/night speed set to %.2f×.", speed)
	end,
})

core.register_chatcommand("dnd3_time_ff", {
	params = "<hours>",
	description = "GM: fast-forward time by N in-game hours (freezes after)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local hours = tonumber(param)
		if not hours then
			return false, "Usage: /dnd3_time_ff <hours>"
		end
		local current = dnd3.tod.get()
		local delta   = (hours / 24) % 1.0
		local target  = (current + delta) % 1.0

		-- Animate: run at high speed until target reached, then freeze
		local saved_speed  = dnd3.tod.get_speed()
		local saved_frozen = dnd3.tod.is_frozen()
		dnd3.tod.set_speed(60)  -- 60× fast-forward
		dnd3.tod.freeze(false)

		-- Estimate real seconds needed at 60× speed
		-- 1 in-game day = 1440 real seconds at 1×; at 60× = 24 real seconds
		local in_game_fraction = delta
		local real_seconds = in_game_fraction * (1440 / 60)

		core.after(real_seconds, function()
			dnd3.tod.set(target)
			dnd3.tod.set_speed(saved_speed)
			dnd3.tod.freeze(saved_frozen)
			-- Notify GM if still online
			local player = core.get_player_by_name(name)
			if player then
				core.chat_send_player(name, string.format(
					"[dnd3] Fast-forward complete. Time is now %s (%s).",
					dnd3.tod.to_hhmm(target), dnd3.tod.period(target)))
			end
		end)

		return true, string.format("Fast-forwarding %.1f hours to %s. Please wait...",
			hours, dnd3.tod.to_hhmm(target))
	end,
})

core.register_chatcommand("dnd3_time", {
	params = "",
	description = "Show current time of day, speed, and frozen state",
	func = function(name, param)
		local t   = dnd3.tod.get()
		local spd = dnd3.tod.get_speed()
		local frz = dnd3.tod.is_frozen()
		return true, string.format(
			"Time: %s  fraction=%.4f  period=%s  speed=%.2f×  frozen=%s",
			dnd3.tod.to_hhmm(t), t, dnd3.tod.period(t), spd, tostring(frz))
	end,
})
