-- Sound Painting: persistent world-space sound emitters.
-- Emitters survive server restarts (stored in mod_storage).
-- Each emitter loops a named sound file at a world position with configurable
-- gain and radius.  Players hear them via dnd3's positional sound API.
--
-- Emitter definition:
-- {
--   id      = "tavern_music",      -- unique string id (required)
--   sound   = "dnd3_ambient_fire", -- sound name (required, without .ogg)
--   pos     = {x, y, z},          -- world position (required)
--   gain    = 1.0,                 -- volume 0.0-1.0 (default 1.0)
--   radius  = 16,                  -- max_hear_distance in nodes (default 32)
--   loop    = true,                -- whether to loop (default true)
--   pitch   = 1.0,                 -- playback pitch (default 1.0)
-- }
--
-- Live emitters are started as server-side positioned sounds.
-- When a player joins, all emitters are replayed for them.

local storage      = core.get_mod_storage()
local STORAGE_KEY  = "audio_emitters"

-- Persisted emitter definitions: id -> def
local emitter_defs = {}

-- Live handles: id -> handle returned by core.sound_play
local emitter_handles = {}

local function persist()
	storage:set_string(STORAGE_KEY, core.write_json(emitter_defs))
end

local function load_storage()
	local blob = storage:get_string(STORAGE_KEY)
	if blob and blob ~= "" then
		local parsed = core.parse_json(blob)
		if type(parsed) == "table" then
			emitter_defs = parsed
		end
	end
end

load_storage()

-- Start a single live emitter (does not touch defs).
local function start_emitter(def)
	if emitter_handles[def.id] then
		core.sound_stop(emitter_handles[def.id])
		emitter_handles[def.id] = nil
	end
	local handle = core.sound_play(def.sound, {
		pos              = def.pos,
		gain             = tonumber(def.gain)   or 1.0,
		pitch            = tonumber(def.pitch)  or 1.0,
		max_hear_distance = tonumber(def.radius) or 32,
		loop             = (def.loop ~= false),  -- default true
	})
	if handle then
		emitter_handles[def.id] = handle
	end
	return handle
end

-- Stop a single live emitter (does not touch defs).
local function stop_emitter(id)
	if emitter_handles[id] then
		core.sound_stop(emitter_handles[id])
		emitter_handles[id] = nil
	end
end

-- Start all persisted emitters (called on server startup and after reload).
local function start_all_emitters()
	for id, def in pairs(emitter_defs) do
		start_emitter(def)
	end
end

start_all_emitters()

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

--- Add or replace a sound emitter.
--- @param id string  unique identifier
--- @param def table  emitter definition (see module header)
--- @return table|nil, string|nil  emitter record or nil + error
function dnd3.audio.emitter_add(id, def)
	id = tostring(id or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if id == "" then return nil, "emitter id required" end
	if type(def) ~= "table" then return nil, "def must be a table" end
	if not def.sound or def.sound == "" then return nil, "def.sound required" end
	if type(def.pos) ~= "table" then return nil, "def.pos required ({x,y,z})" end

	local record = {
		id     = id,
		sound  = tostring(def.sound),
		pos    = { x = tonumber(def.pos.x) or 0,
		           y = tonumber(def.pos.y) or 0,
		           z = tonumber(def.pos.z) or 0 },
		gain   = math.max(0, math.min(1, tonumber(def.gain)   or 1.0)),
		radius = math.max(1,             tonumber(def.radius) or 32),
		pitch  = math.max(0.1, math.min(4, tonumber(def.pitch) or 1.0)),
		loop   = (def.loop ~= false),
	}

	emitter_defs[id] = record
	persist()
	start_emitter(record)
	return record
end

--- Remove a sound emitter.
--- @param id string
--- @return boolean, string|nil
function dnd3.audio.emitter_remove(id)
	id = tostring(id or "")
	if not emitter_defs[id] then return false, "unknown emitter: " .. id end
	stop_emitter(id)
	emitter_defs[id] = nil
	persist()
	return true
end

--- Return all emitter records sorted by id.
--- @return table[]
function dnd3.audio.emitter_list()
	local list = {}
	for _, def in pairs(emitter_defs) do
		list[#list + 1] = def
	end
	table.sort(list, function(a, b) return a.id < b.id end)
	return list
end

--- Get a single emitter record.
--- @param id string
--- @return table|nil
function dnd3.audio.emitter_get(id)
	return emitter_defs[tostring(id or "")]
end

--- Restart all emitters (useful after a hot-reload or world load).
function dnd3.audio.emitters_restart()
	for id in pairs(emitter_handles) do
		stop_emitter(id)
	end
	start_all_emitters()
end

-- When a player joins, the server restarts all emitters so the new client
-- hears them.  (dnd3 delivers positioned sounds to all current players;
-- re-triggering ensures the joining player catches them.)
core.register_on_joinplayer(function(player)
	dnd3.audio.emitters_restart()
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Chat commands
-- ─────────────────────────────────────────────────────────────────────────────

core.register_chatcommand("dnd3_emitter_add", {
	params = "<id> <sound> [gain] [radius] [pitch]",
	description = "Place a looping sound emitter at your position (GM only). "
		.. "gain=0.0-1.0, radius=nodes, pitch=0.1-4.0",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local player = core.get_player_by_name(name)
		if not player then return false, "Player not found." end

		-- parse: id sound [gain] [radius] [pitch]
		local parts = {}
		for tok in param:gmatch("%S+") do parts[#parts + 1] = tok end
		if #parts < 2 then
			return false, "Usage: /dnd3_emitter_add <id> <sound> [gain] [radius] [pitch]"
		end
		local def = {
			sound  = parts[2],
			pos    = player:get_pos(),
			gain   = tonumber(parts[3]) or 1.0,
			radius = tonumber(parts[4]) or 32,
			pitch  = tonumber(parts[5]) or 1.0,
			loop   = true,
		}
		local record, err = dnd3.audio.emitter_add(parts[1], def)
		if not record then return false, "Error: " .. tostring(err) end
		return true, string.format(
			"Emitter '%s' placed (sound='%s', gain=%.2f, radius=%d, pitch=%.2f).",
			record.id, record.sound, record.gain, record.radius, record.pitch)
	end,
})

core.register_chatcommand("dnd3_emitter_remove", {
	params = "<id>",
	description = "Remove a sound emitter (GM only)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		local id = param:match("^%s*(.-)%s*$")
		if id == "" then return false, "Usage: /dnd3_emitter_remove <id>" end
		local ok, err = dnd3.audio.emitter_remove(id)
		if not ok then return false, tostring(err) end
		return true, "Emitter '" .. id .. "' removed."
	end,
})

core.register_chatcommand("dnd3_emitter_list", {
	params = "",
	description = "List all active sound emitters",
	func = function(name, param)
		local list = dnd3.audio.emitter_list()
		if #list == 0 then return true, "No sound emitters." end
		local lines = { "Sound emitters:" }
		for _, e in ipairs(list) do
			lines[#lines + 1] = string.format(
				"  [%s] sound='%s' pos=(%.0f,%.0f,%.0f) gain=%.2f radius=%d pitch=%.2f",
				e.id, e.sound, e.pos.x, e.pos.y, e.pos.z, e.gain, e.radius, e.pitch)
		end
		return true, table.concat(lines, "\n")
	end,
})

core.register_chatcommand("dnd3_emitter_restart", {
	params = "",
	description = "Restart all sound emitters (GM only, use after world reload)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied (requires GM role)."
		end
		dnd3.audio.emitters_restart()
		return true, "All sound emitters restarted."
	end,
})
