-- Time-of-Day cycle engine.
--
-- Time is stored as a float in [0, 1):
--   0.0  = midnight
--   0.25 = sunrise  (~6:00)
--   0.5  = noon     (~12:00)
--   0.75 = sunset   (~18:00)
--
-- dnd3's core.get_timeofday() / core.set_timeofday() use the same [0,1) range.
-- The cycle runs at a configurable speed multiplier relative to real time.
-- 1× speed → 1 in-game day = 24 real minutes (1440s → same as dnd3 default).
-- GMs can freeze time, set it directly, or change the speed multiplier.
--
-- Sky and lighting are updated every TICK_INTERVAL seconds by adjusting each
-- connected player's sky via player:set_sky() and player:set_sun/moon/stars()
-- (dnd3 5.8+ API).  Colour grading is applied as a set of interpolated
-- sky colour stops keyed to time-of-day.
--
-- External hooks:
--   dnd3.tod.register_tick_hook(fn)  -- fn(time_fraction) called each tick
--   Used by weather/ to blend fog/cloud colours.

local TICK_INTERVAL  = 2      -- seconds between visual updates
local DEFAULT_SPEED  = 1.0    -- 1× = real dnd3 day speed
local DAY_SECONDS    = 1440   -- real seconds per in-game day at 1× speed

-- ─────────────────────────────────────────────────────────────────────────────
-- Sky colour table  (time → {sky_top, sky_horizon, sun_tint, ambient_light})
-- Values are {r,g,b} normalised to [0,1].  Interpolated between stops.
-- ─────────────────────────────────────────────────────────────────────────────
local SKY_STOPS = {
	-- midnight
	{ t = 0.00, sky_top = {0.01,0.01,0.06}, sky_hor = {0.02,0.02,0.08},
	  fog = {0.02,0.02,0.05}, sun_scale = 0, moon_scale = 1.0 },
	-- pre-dawn
	{ t = 0.20, sky_top = {0.03,0.03,0.12}, sky_hor = {0.08,0.04,0.10},
	  fog = {0.05,0.04,0.10}, sun_scale = 0, moon_scale = 0.8 },
	-- sunrise
	{ t = 0.25, sky_top = {0.40,0.20,0.10}, sky_hor = {0.90,0.50,0.20},
	  fog = {0.80,0.45,0.20}, sun_scale = 1.0, moon_scale = 0 },
	-- morning
	{ t = 0.33, sky_top = {0.30,0.55,0.90}, sky_hor = {0.70,0.80,0.95},
	  fog = {0.65,0.75,0.90}, sun_scale = 1.0, moon_scale = 0 },
	-- noon
	{ t = 0.50, sky_top = {0.18,0.48,0.90}, sky_hor = {0.55,0.75,0.95},
	  fog = {0.55,0.72,0.95}, sun_scale = 1.0, moon_scale = 0 },
	-- afternoon
	{ t = 0.65, sky_top = {0.20,0.50,0.88}, sky_hor = {0.60,0.75,0.90},
	  fog = {0.58,0.72,0.88}, sun_scale = 1.0, moon_scale = 0 },
	-- sunset
	{ t = 0.75, sky_top = {0.35,0.18,0.08}, sky_hor = {0.90,0.48,0.16},
	  fog = {0.80,0.42,0.15}, sun_scale = 0.6, moon_scale = 0.2 },
	-- dusk
	{ t = 0.80, sky_top = {0.05,0.04,0.12}, sky_hor = {0.18,0.10,0.18},
	  fog = {0.10,0.07,0.14}, sun_scale = 0, moon_scale = 0.7 },
	-- night
	{ t = 0.90, sky_top = {0.01,0.01,0.07}, sky_hor = {0.02,0.02,0.09},
	  fog = {0.02,0.02,0.06}, sun_scale = 0, moon_scale = 1.0 },
	-- midnight (wrap)
	{ t = 1.00, sky_top = {0.01,0.01,0.06}, sky_hor = {0.02,0.02,0.08},
	  fog = {0.02,0.02,0.05}, sun_scale = 0, moon_scale = 1.0 },
}

local function lerp(a, b, f)
	return a + (b - a) * f
end

local function lerp_rgb(a, b, f)
	return {
		r = math.floor(lerp(a[1], b[1], f) * 255 + 0.5),
		g = math.floor(lerp(a[2], b[2], f) * 255 + 0.5),
		b = math.floor(lerp(a[3], b[3], f) * 255 + 0.5),
		a = 255,
	}
end

-- Sample the sky colour table at time fraction t.
local function sample_sky(t)
	t = t % 1.0
	local prev = SKY_STOPS[#SKY_STOPS - 1]
	local next = SKY_STOPS[#SKY_STOPS]
	for i = 1, #SKY_STOPS - 1 do
		if t >= SKY_STOPS[i].t and t < SKY_STOPS[i + 1].t then
			prev = SKY_STOPS[i]
			next = SKY_STOPS[i + 1]
			break
		end
	end
	local span = next.t - prev.t
	local f    = (span > 0) and ((t - prev.t) / span) or 0
	return {
		sky_top  = lerp_rgb(prev.sky_top, next.sky_top, f),
		sky_hor  = lerp_rgb(prev.sky_hor, next.sky_hor, f),
		fog      = lerp_rgb(prev.fog, next.fog, f),
		sun_scale  = lerp(prev.sun_scale,  next.sun_scale,  f),
		moon_scale = lerp(prev.moon_scale, next.moon_scale, f),
	}
end

-- ─────────────────────────────────────────────────────────────────────────────
-- State
-- ─────────────────────────────────────────────────────────────────────────────

local tod_state = {
	frozen        = false,
	speed         = DEFAULT_SPEED,  -- multiplier
	accum         = 0,              -- accumulator since last tick
	tick_hooks    = {},             -- registered external hooks
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Sky application
-- ─────────────────────────────────────────────────────────────────────────────

local function apply_sky_to_player(player, sky)
	-- Sky colours
	local ok_sky, err_sky = pcall(player.set_sky, player, {
		type      = "regular",
		sky_color = {
			day_sky      = sky.sky_top,
			day_horizon  = sky.sky_hor,
			dawn_sky     = sky.sky_top,
			dawn_horizon = sky.sky_hor,
			night_sky    = sky.sky_top,
			night_horizon = sky.sky_hor,
			indoors      = { r=100, g=100, b=128, a=255 },
		},
		clouds = true,
	})
	if not ok_sky then
		-- dnd3 build pre-dates set_sky colour struct — silently skip
	end

	-- Sun
	pcall(player.set_sun, player, {
		visible    = (sky.sun_scale > 0),
		scale      = math.max(0.01, sky.sun_scale),
		sunrise_visible = true,
	})

	-- Moon
	pcall(player.set_moon, player, {
		visible = (sky.moon_scale > 0),
		scale   = math.max(0.01, sky.moon_scale),
	})

	-- Stars — visible only at night (sun_scale < 0.3)
	pcall(player.set_stars, player, {
		visible = (sky.sun_scale < 0.3),
		count   = 1000,
		star_color = { r=220, g=220, b=255, a=200 },
	})
end

local function apply_sky_to_all(t)
	local sky = sample_sky(t)
	for _, player in ipairs(core.get_connected_players()) do
		apply_sky_to_player(player, sky)
	end
	-- Call external hooks (weather, etc.)
	for _, fn in ipairs(tod_state.tick_hooks) do
		pcall(fn, t, sky)
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Main loop via register_globalstep
-- ─────────────────────────────────────────────────────────────────────────────

core.register_globalstep(function(dtime)
	if tod_state.frozen then return end

	tod_state.accum = tod_state.accum + dtime

	if tod_state.accum < TICK_INTERVAL then return end
	tod_state.accum = 0

	-- Advance dnd3's internal time of day
	local current = core.get_timeofday()
	local advance = (TICK_INTERVAL * tod_state.speed) / DAY_SECONDS
	local new_t   = (current + advance) % 1.0
	core.set_timeofday(new_t)

	-- Apply sky to all players
	apply_sky_to_all(new_t)
end)

-- Reapply sky whenever a player joins so they see correct colours immediately.
core.register_on_joinplayer(function(player)
	local t   = core.get_timeofday()
	local sky = sample_sky(t)
	core.after(1, function()
		if player and player:get_pos() then
			apply_sky_to_player(player, sky)
		end
	end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

--- Get current time fraction [0,1).
function dnd3.tod.get()
	return core.get_timeofday()
end

--- Set time directly.  Clamps to [0,1).
--- @param t number  0=midnight, 0.25=sunrise, 0.5=noon, 0.75=sunset
function dnd3.tod.set(t)
	t = (tonumber(t) or 0) % 1.0
	core.set_timeofday(t)
	apply_sky_to_all(t)
	return t
end

--- Freeze or unfreeze the cycle.
--- @param frozen boolean
function dnd3.tod.freeze(frozen)
	tod_state.frozen = (frozen ~= false)
	return tod_state.frozen
end

--- Return whether time is frozen.
function dnd3.tod.is_frozen()
	return tod_state.frozen
end

--- Set the speed multiplier.  1.0 = real dnd3 default, 0 = effectively frozen.
--- @param speed number  positive multiplier (0 allowed, equals freeze)
function dnd3.tod.set_speed(speed)
	speed = math.max(0, tonumber(speed) or 1.0)
	tod_state.speed = speed
	return speed
end

--- Get the current speed multiplier.
function dnd3.tod.get_speed()
	return tod_state.speed
end

--- Register an external tick hook called every TICK_INTERVAL seconds.
--- Signature: fn(time_fraction, sky_sample)
--- where sky_sample has fields: sky_top, sky_hor, fog, sun_scale, moon_scale.
--- @param fn function
function dnd3.tod.register_tick_hook(fn)
	if type(fn) ~= "function" then return end
	tod_state.tick_hooks[#tod_state.tick_hooks + 1] = fn
end

--- Convert time fraction to a human-readable HH:MM string (24h).
--- @param t number  [0,1) — defaults to current time
--- @return string  e.g. "14:35"
function dnd3.tod.to_hhmm(t)
	t = (tonumber(t) or core.get_timeofday()) % 1.0
	local total_minutes = math.floor(t * 1440)
	local hh = math.floor(total_minutes / 60)
	local mm = total_minutes % 60
	return string.format("%02d:%02d", hh, mm)
end

--- Return the named period for a time fraction:
--- "night" | "dawn" | "morning" | "day" | "afternoon" | "dusk" | "evening"
--- @param t number  [0,1)
--- @return string
function dnd3.tod.period(t)
	t = (tonumber(t) or core.get_timeofday()) % 1.0
	if     t < 0.21 then return "night"
	elseif t < 0.26 then return "dawn"
	elseif t < 0.38 then return "morning"
	elseif t < 0.62 then return "day"
	elseif t < 0.72 then return "afternoon"
	elseif t < 0.78 then return "dusk"
	elseif t < 0.85 then return "evening"
	else                  return "night"
	end
end
