-- GM Audio Streaming: play music or SFX to all players, a named set, or a
-- positional radius.  Streams are one-shot or looping and can be faded.
--
-- A "stream" is a sound_play handle tracked in the live handle table.
-- Multiple named streams can run concurrently.
--
-- Stream definition (passed to dnd3.audio.stream):
-- {
--   id       = "battle_theme",   -- unique stream id (required)
--   sound    = "dnd3_music_01",  -- sound name without .ogg (required)
--   target   = "all",            -- "all" | "players" | "radius" (default "all")
--   players  = {"Alice","Bob"},  -- used when target=="players"
--   pos      = {x,y,z},          -- anchor for target=="radius"
--   radius   = 48,               -- nodes, used when target=="radius"
--   gain     = 0.8,              -- 0.0-1.0 (default 0.8)
--   pitch    = 1.0,              -- 0.1-4.0 (default 1.0)
--   loop     = false,            -- default false for streams
--   fade_in  = 0,                -- seconds to fade in (0 = instant)
-- }
--
-- Fade-out is achieved by calling dnd3.audio.stream_fade_out(id, seconds).
--
-- NOTE: dnd3's core.sound_play only supports positional or per-player
-- sounds (not "all players" natively for non-positional audio).  For
-- target=="all" and target=="players" we iterate connected players and issue
-- one per-player sound_play each.  For target=="radius" we use a single
-- positional sound_play with max_hear_distance.

local FADE_STEPS  = 10    -- granularity of fade steps
local FADE_TICK   = 0.05  -- seconds between fade steps

-- live_streams: id -> { handles = {}, def = def, gain = current_gain }
local live_streams = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

-- Stop all handles for a stream entry and remove it from live_streams.
local function kill_stream(id)
	local entry = live_streams[id]
	if not entry then return end
	for _, h in ipairs(entry.handles) do
		pcall(core.sound_stop, h)
	end
	live_streams[id] = nil
end

-- Play one sound spec to a single player (no positional anchor).
local function play_to_player(player_name, sound, gain, pitch, loop)
	return core.sound_play(sound, {
		to_player = player_name,
		gain      = gain,
		pitch     = pitch,
		loop      = loop,
	})
end

-- Start the actual audio handles for a validated stream def.
-- Returns an array of handles.
local function start_stream_handles(def, gain)
	local handles = {}
	local loop    = def.loop or false
	local pitch   = def.pitch or 1.0

	if def.target == "radius" then
		-- Single positional sound with max_hear_distance
		local h = core.sound_play(def.sound, {
			pos               = def.pos,
			gain              = gain,
			pitch             = pitch,
			max_hear_distance = tonumber(def.radius) or 48,
			loop              = loop,
		})
		if h then handles[#handles + 1] = h end

	elseif def.target == "players" and type(def.players) == "table" then
		for _, pname in ipairs(def.players) do
			local player = core.get_player_by_name(pname)
			if player then
				local h = play_to_player(pname, def.sound, gain, pitch, loop)
				if h then handles[#handles + 1] = h end
			end
		end

	else
		-- "all" — send to every connected player
		for _, player in ipairs(core.get_connected_players()) do
			local h = play_to_player(player:get_player_name(), def.sound, gain, pitch, loop)
			if h then handles[#handles + 1] = h end
		end
	end

	return handles
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

--- Start an audio stream.  Stops any existing stream with the same id first.
--- @param def table  stream definition (see module header)
--- @return string|nil id, string|nil err
function dnd3.audio.stream(def)
	if type(def) ~= "table" then return nil, "def must be a table" end
	local id = tostring(def.id or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if id == "" then return nil, "def.id required" end
	if not def.sound or def.sound == "" then return nil, "def.sound required" end
	if def.target == "radius" and type(def.pos) ~= "table" then
		return nil, "def.pos required when target=='radius'"
	end

	-- Stop any existing stream with this id
	kill_stream(id)

	local final_gain = clamp(tonumber(def.gain) or 0.8, 0, 1)
	local fade_in    = tonumber(def.fade_in) or 0

	-- Normalise def
	local clean_def = {
		id      = id,
		sound   = tostring(def.sound),
		target  = def.target or "all",
		players = def.players,
		pos     = def.pos,
		radius  = tonumber(def.radius) or 48,
		gain    = final_gain,
		pitch   = clamp(tonumber(def.pitch) or 1.0, 0.1, 4),
		loop    = (def.loop == true),
		fade_in = fade_in,
	}

	local start_gain = (fade_in > 0) and 0 or final_gain
	local handles    = start_stream_handles(clean_def, start_gain)

	if #handles == 0 then
		return nil, "no handles created (no matching players or positional play failed)"
	end

	live_streams[id] = {
		handles     = handles,
		def         = clean_def,
		gain        = start_gain,
		target_gain = final_gain,
	}

	-- Fade-in: increment gain over fade_in seconds using a simple timer loop
	if fade_in > 0 then
		local step_gain   = final_gain / FADE_STEPS
		local step_time   = fade_in / FADE_STEPS
		local step_count  = 0
		local function do_step(dtime)
			step_count = step_count + 1
			local entry = live_streams[id]
			if not entry then return end  -- stream was stopped mid-fade
			local new_gain = clamp(step_gain * step_count, 0, final_gain)
			entry.gain = new_gain
			-- Re-issue at new gain (dnd3 has no gain-change API for live handles)
			kill_stream(id)
			if step_count < FADE_STEPS then
				local new_handles = start_stream_handles(clean_def, new_gain)
				live_streams[id] = {
					handles     = new_handles,
					def         = clean_def,
					gain        = new_gain,
					target_gain = final_gain,
				}
				core.after(step_time, do_step)
			else
				-- Final step at full gain
				local new_handles = start_stream_handles(clean_def, final_gain)
				live_streams[id] = {
					handles     = new_handles,
					def         = clean_def,
					gain        = final_gain,
					target_gain = final_gain,
				}
			end
		end
		core.after(step_time, do_step)
	end

	return id
end

--- Stop a named stream immediately.
--- @param id string
--- @return boolean
function dnd3.audio.stream_stop(id)
	id = tostring(id or "")
	if not live_streams[id] then return false end
	kill_stream(id)
	return true
end

--- Fade out a stream and stop it.
--- @param id string
--- @param seconds number  fade duration
function dnd3.audio.stream_fade_out(id, seconds)
	id      = tostring(id or "")
	seconds = tonumber(seconds) or 2
	local entry = live_streams[id]
	if not entry then return false end

	local current_gain = entry.gain
	local step_gain    = current_gain / FADE_STEPS
	local step_time    = seconds / FADE_STEPS
	local step_count   = 0

	local function do_step()
		step_count = step_count + 1
		local e = live_streams[id]
		if not e then return end
		local new_gain = clamp(current_gain - step_gain * step_count, 0, 1)
		kill_stream(id)
		if new_gain > 0 and step_count < FADE_STEPS then
			local new_handles = start_stream_handles(e.def, new_gain)
			live_streams[id] = {
				handles     = new_handles,
				def         = e.def,
				gain        = new_gain,
				target_gain = 0,
			}
			core.after(step_time, do_step)
		end
		-- gain==0 or final step: stream is already killed, done.
	end
	core.after(step_time, do_step)
	return true
end

--- Stop all active streams.
function dnd3.audio.stream_stop_all()
	for id in pairs(live_streams) do
		kill_stream(id)
	end
end

--- List active stream ids.
--- @return string[]
function dnd3.audio.stream_list()
	local ids = {}
	for id in pairs(live_streams) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	return ids
end

--- Get info about an active stream.
--- @param id string
--- @return table|nil  { id, sound, target, gain, loop }
function dnd3.audio.stream_get(id)
	local entry = live_streams[tostring(id or "")]
	if not entry then return nil end
	return {
		id     = entry.def.id,
		sound  = entry.def.sound,
		target = entry.def.target,
		gain   = entry.gain,
		loop   = entry.def.loop,
	}
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Chat commands
-- ─────────────────────────────────────────────────────────────────────────────

core.register_chatcommand("dnd3_stream", {
	params = "<id> <sound> [all|players:<p1,p2>|radius:<r>] [gain] [pitch] [loop] [fade_in]",
	description = "GM: start an audio stream to all/specific players/radius. "
		.. "target examples: 'all', 'players:Alice,Bob', 'radius:48'",
	func = function(name, param)
		if not dnd3.can(name, "fog_control") then
			-- Reuse fog_control (GM only) — audio_control is a future permission
			return false, "Permission denied (requires GM role)."
		end
		local player = core.get_player_by_name(name)
		if not player then return false, "Player not found." end

		local parts = {}
		for tok in param:gmatch("%S+") do parts[#parts + 1] = tok end
		if #parts < 2 then
			return false, "Usage: /dnd3_stream <id> <sound> [target] [gain] [pitch] [loop] [fade_in]"
		end

		local def = {
			id     = parts[1],
			sound  = parts[2],
			target = "all",
			gain   = tonumber(parts[4]) or 0.8,
			pitch  = tonumber(parts[5]) or 1.0,
			loop   = (parts[6] == "true" or parts[6] == "1"),
			fade_in = tonumber(parts[7]) or 0,
		}

		-- Parse target token
		local target_tok = parts[3] or "all"
		if target_tok:sub(1, 8) == "players:" then
			def.target = "players"
			def.players = {}
			for p in target_tok:sub(9):gmatch("[^,]+") do
				def.players[#def.players + 1] = p
			end
		elseif target_tok:sub(1, 7) == "radius:" then
			def.target = "radius"
			def.radius = tonumber(target_tok:sub(8)) or 48
			def.pos    = player:get_pos()
		else
			def.target = "all"
		end

		local stream_id, err = dnd3.audio.stream(def)
		if not stream_id then return false, "Error: " .. tostring(err) end
		return true, string.format(
			"Stream '%s' started (sound='%s', target='%s', gain=%.2f, loop=%s).",
			stream_id, def.sound, def.target, def.gain, tostring(def.loop))
	end,
})

core.register_chatcommand("dnd3_stream_stop", {
	params = "<id>",
	description = "GM: stop a named audio stream immediately",
	func = function(name, param)
		if not dnd3.can(name, "fog_control") then
			return false, "Permission denied (requires GM role)."
		end
		local id = param:match("^%s*(.-)%s*$")
		if id == "" then return false, "Usage: /dnd3_stream_stop <id>" end
		if dnd3.audio.stream_stop(id) then
			return true, "Stream '" .. id .. "' stopped."
		end
		return false, "No active stream with id '" .. id .. "'."
	end,
})

core.register_chatcommand("dnd3_stream_fade", {
	params = "<id> [seconds]",
	description = "GM: fade out and stop a named audio stream (default 2s)",
	func = function(name, param)
		if not dnd3.can(name, "fog_control") then
			return false, "Permission denied (requires GM role)."
		end
		local parts = {}
		for tok in param:gmatch("%S+") do parts[#parts + 1] = tok end
		if #parts < 1 or parts[1] == "" then
			return false, "Usage: /dnd3_stream_fade <id> [seconds]"
		end
		if dnd3.audio.stream_fade_out(parts[1], tonumber(parts[2]) or 2) then
			return true, string.format("Fading out stream '%s' over %.1fs.", parts[1], tonumber(parts[2]) or 2)
		end
		return false, "No active stream '" .. parts[1] .. "'."
	end,
})

core.register_chatcommand("dnd3_stream_stop_all", {
	params = "",
	description = "GM: stop all active audio streams",
	func = function(name, param)
		if not dnd3.can(name, "fog_control") then
			return false, "Permission denied (requires GM role)."
		end
		dnd3.audio.stream_stop_all()
		return true, "All streams stopped."
	end,
})

core.register_chatcommand("dnd3_stream_list", {
	params = "",
	description = "List active audio streams",
	func = function(name, param)
		local ids = dnd3.audio.stream_list()
		if #ids == 0 then return true, "No active streams." end
		local lines = { "Active streams:" }
		for _, id in ipairs(ids) do
			local s = dnd3.audio.stream_get(id)
			if s then
				lines[#lines + 1] = string.format(
					"  [%s] sound='%s' target='%s' gain=%.2f loop=%s",
					s.id, s.sound, s.target, s.gain, tostring(s.loop))
			end
		end
		return true, table.concat(lines, "\n")
	end,
})
