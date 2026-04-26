-- Weather engine.
-- Manages per-player active weather state, particle spawning, ambient sound
-- handles, and sky-tint blending via the ToD tick hook.
--
-- Architecture:
--   - Global weather (applies to all players): dnd3.weather.set_global(id)
--   - Per-player override:                     dnd3.weather.set_player(name, id)
--   - Regional weather (by cell):              dnd3.weather.region_paint/clear()
--
-- Resolution order: per-player override > regional cell > global
--
-- Each TICK_INTERVAL the engine:
--   1. Determines the effective weather id for each online player
--   2. If changed: stops old particle spawner, starts new one; swaps ambient sound
--   3. Applies sky tint (blended on top of ToD sky colours) via set_sky
--   4. Fires ruleset_hook callback if any ruleset is listening

local TICK_INTERVAL   = 4      -- seconds between weather ticks
local REGION_SCALE    = 20     -- nodes per weather region cell (4 map cells)

-- ─────────────────────────────────────────────────────────────────────────────
-- State
-- ─────────────────────────────────────────────────────────────────────────────

local global_weather = "clear"  -- current global weather id

-- player_name -> weather id override (nil = use regional/global)
local player_overrides = {}

-- "x,z" cell key -> weather id  (coarse regional grid)
local region_weather = {}

-- per-player live state: player_name -> { weather_id, ps_id, sound_handle }
local player_state = {}

local accum = 0

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function region_key(pos)
	local rx = math.floor(pos.x / REGION_SCALE)
	local rz = math.floor(pos.z / REGION_SCALE)
	return rx .. "," .. rz
end

local function effective_weather(player)
	local name = player:get_player_name()
	if player_overrides[name] then
		return player_overrides[name]
	end
	local key = region_key(player:get_pos())
	if region_weather[key] then
		return region_weather[key]
	end
	return global_weather
end

-- Stop particles and sound for a player state entry.
local function clear_player_state(ps)
	if ps.ps_id then
		pcall(core.delete_particlespawner, ps.ps_id)
		ps.ps_id = nil
	end
	if ps.sound_handle then
		pcall(core.sound_stop, ps.sound_handle)
		ps.sound_handle = nil
	end
end

-- Apply weather to a single player.
local function apply_weather_to_player(player, wid)
	local name  = player:get_player_name()
	local wtype = dnd3.weather.get_type(wid) or dnd3.weather.get_type("clear")
	local ps    = player_state[name] or {}
	player_state[name] = ps

	-- Only change if weather type changed
	if ps.weather_id == wtype.id then return end
	clear_player_state(ps)
	ps.weather_id = wtype.id

	-- Particles (attached to player so they follow them)
	if wtype.particles then
		local pdef = {}
		for k, v in pairs(wtype.particles) do pdef[k] = v end
		pdef.attached = player:get_pos()  -- re-anchor relative; positional
		-- Use player-relative spawn: offset by player pos each tick (engine handles globally)
		-- For simplicity use a global spawner near this player; re-issue each tick
		local ok, id = pcall(core.add_particlespawner, pdef)
		if ok and id then
			ps.ps_id = id
		end
	end

	-- Ambient sound
	if wtype.sound and wtype.sound ~= "" then
		local ok, handle = pcall(core.sound_play, wtype.sound, {
			to_player = name,
			gain      = wtype.sound_gain or 0.5,
			loop      = true,
		})
		if ok and handle then
			ps.sound_handle = handle
		end
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ToD sky-tint hook (registered after tod subsystem is available)
-- ─────────────────────────────────────────────────────────────────────────────

-- Called by time_of_day/cycle.lua every TICK_INTERVAL seconds.
-- We blend the weather sky_tint over the ToD base colours per-player.
local function weather_tod_hook(t, base_sky)
	for _, player in ipairs(core.get_connected_players()) do
		local name  = player:get_player_name()
		local wid   = effective_weather(player)
		local wtype = dnd3.weather.get_type(wid) or dnd3.weather.get_type("clear")

		if wtype.sky_tint and wtype.sky_tint_str and wtype.sky_tint_str > 0 then
			local f   = wtype.sky_tint_str
			local wt  = wtype.sky_tint

			local function blend(base_chan, w_chan)
				return math.max(0, math.min(255, math.floor(base_chan * (1 - f) + w_chan * f + 0.5)))
			end

			local tinted_top = {
				r = blend(base_sky.sky_top.r, wt.r),
				g = blend(base_sky.sky_top.g, wt.g),
				b = blend(base_sky.sky_top.b, wt.b),
				a = 255,
			}
			local tinted_hor = {
				r = blend(base_sky.sky_hor.r, wt.r),
				g = blend(base_sky.sky_hor.g, wt.g),
				b = blend(base_sky.sky_hor.b, wt.b),
				a = 255,
			}

			pcall(player.set_sky, player, {
				type      = "regular",
				sky_color = {
					day_sky       = tinted_top,
					day_horizon   = tinted_hor,
					dawn_sky      = tinted_top,
					dawn_horizon  = tinted_hor,
					night_sky     = tinted_top,
					night_horizon = tinted_hor,
					indoors       = { r=90, g=90, b=110, a=255 },
				},
				clouds = (wid ~= "blizzard" and wid ~= "fog"),
			})
		end
	end
end

-- Register hook once tod subsystem is loaded.  tod is loaded before weather
-- in init.lua, so dnd3.tod is available here.
if dnd3.tod and dnd3.tod.register_tick_hook then
	dnd3.tod.register_tick_hook(weather_tod_hook)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Global step: tick weather per-player
-- ─────────────────────────────────────────────────────────────────────────────

core.register_globalstep(function(dtime)
	accum = accum + dtime
	if accum < TICK_INTERVAL then return end
	accum = 0

	for _, player in ipairs(core.get_connected_players()) do
		local wid = effective_weather(player)
		apply_weather_to_player(player, wid)
	end
end)

-- Clean up when player leaves
core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	local ps   = player_state[name]
	if ps then
		clear_player_state(ps)
		player_state[name] = nil
	end
end)

-- Apply weather immediately when player joins (after short delay for load)
core.register_on_joinplayer(function(player)
	core.after(2, function()
		if player and player:get_pos() then
			local wid = effective_weather(player)
			apply_weather_to_player(player, wid)
		end
	end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

--- Set global weather for all players (no per-player or regional override).
--- @param id string  weather type id
--- @return string|nil, string|nil  final id or nil+err
function dnd3.weather.set_global(id)
	if not dnd3.weather.get_type(id) then
		return nil, "unknown weather type: " .. tostring(id)
	end
	global_weather = id
	-- Re-apply to all players immediately
	for _, player in ipairs(core.get_connected_players()) do
		player_state[player:get_player_name()] = player_state[player:get_player_name()] or {}
		player_state[player:get_player_name()].weather_id = nil  -- force refresh
		apply_weather_to_player(player, effective_weather(player))
	end
	return id
end

--- Get current global weather id.
function dnd3.weather.get_global()
	return global_weather
end

--- Set a per-player weather override.
--- @param player_name string
--- @param id string  weather type id, or nil to clear override
--- @return string|nil, string|nil
function dnd3.weather.set_player(player_name, id)
	if id ~= nil and not dnd3.weather.get_type(id) then
		return nil, "unknown weather type: " .. tostring(id)
	end
	player_overrides[player_name] = id
	local player = core.get_player_by_name(player_name)
	if player then
		local ps = player_state[player_name] or {}
		player_state[player_name] = ps
		ps.weather_id = nil  -- force refresh
		apply_weather_to_player(player, effective_weather(player))
	end
	return id or global_weather
end

--- Get the per-player weather override (or nil if none).
function dnd3.weather.get_player(player_name)
	return player_overrides[player_name]
end

--- Paint a weather type onto a rectangular region (region-grid snapped).
--- pos1/pos2 define the XZ footprint; Y is ignored for regional lookup.
--- @param wid string  weather type id
--- @param pos1 table  {x,y,z}
--- @param pos2 table  {x,y,z}
--- @return number  count of region cells painted
function dnd3.weather.region_paint(wid, pos1, pos2)
	if not dnd3.weather.get_type(wid) then return 0 end
	local minrx = math.floor(math.min(pos1.x, pos2.x) / REGION_SCALE)
	local maxrx = math.floor(math.max(pos1.x, pos2.x) / REGION_SCALE)
	local minrz = math.floor(math.min(pos1.z, pos2.z) / REGION_SCALE)
	local maxrz = math.floor(math.max(pos1.z, pos2.z) / REGION_SCALE)
	local count = 0
	for rx = minrx, maxrx do
		for rz = minrz, maxrz do
			region_weather[rx .. "," .. rz] = wid
			count = count + 1
		end
	end
	return count
end

--- Clear regional weather from a rectangular footprint.
--- @param pos1 table  {x,y,z}
--- @param pos2 table  {x,y,z}
--- @return number  count of region cells cleared
function dnd3.weather.region_clear(pos1, pos2)
	local minrx = math.floor(math.min(pos1.x, pos2.x) / REGION_SCALE)
	local maxrx = math.floor(math.max(pos1.x, pos2.x) / REGION_SCALE)
	local minrz = math.floor(math.min(pos1.z, pos2.z) / REGION_SCALE)
	local maxrz = math.floor(math.max(pos1.z, pos2.z) / REGION_SCALE)
	local count = 0
	for rx = minrx, maxrx do
		for rz = minrz, maxrz do
			local k = rx .. "," .. rz
			if region_weather[k] then
				region_weather[k] = nil
				count = count + 1
			end
		end
	end
	return count
end

--- Return the effective weather id for a world position (regional lookup only).
--- Returns global weather if no regional override at that cell.
--- @param pos table  {x,y,z}
--- @return string  weather id
function dnd3.weather.at_pos(pos)
	return region_weather[region_key(pos)] or global_weather
end

--- Return a summary of the current weather state.
function dnd3.weather.status()
	return {
		global          = global_weather,
		player_overrides = player_overrides,
		region_cells    = region_weather,
	}
end
