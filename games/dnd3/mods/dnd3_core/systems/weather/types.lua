-- Weather type registry.
-- Each weather type is a descriptor table that drives:
--   - particle spawner parameters (rain drops, snow flakes, etc.)
--   - sky colour tint blended on top of the ToD sky via tod.register_tick_hook
--   - ambient sound played while this weather is active
--   - optional ruleset effect hook identifier (for Phase 2 mechanical effects)
--
-- Built-in types are registered here.  Modders/rulesets can call
-- dnd3.weather.register_type(def) to add their own.
--
-- Weather type definition fields:
-- {
--   id            = "rain",          -- required, unique string
--   label         = "Rain",          -- display name
--   particles     = { ... },         -- particle_spawner parameters (or nil = no particles)
--   sky_tint      = {r,g,b,a},       -- RGBA 0-255 overlay blended on ToD sky (or nil)
--   sky_tint_str  = 0.3,             -- blend strength 0-1 (default 0)
--   fog_range     = nil,             -- override fog distance (nil = no change)
--   light_reduce  = 0,               -- reduce max light level 0-10 (default 0)
--   sound         = nil,             -- ambient sound name (without .ogg) (or nil)
--   sound_gain    = 0.5,             -- gain for ambient sound
--   ruleset_hook  = nil,             -- string key passed to ruleset weather callbacks
-- }

local WEATHER_TYPES = {}

function dnd3.weather.register_type(def)
	if type(def) ~= "table" or not def.id then
		error("[dnd3] weather.register_type: def.id required")
	end
	WEATHER_TYPES[def.id] = {
		id           = def.id,
		label        = def.label or def.id,
		particles    = def.particles,
		sky_tint     = def.sky_tint,
		sky_tint_str = tonumber(def.sky_tint_str) or 0,
		fog_range    = tonumber(def.fog_range),
		light_reduce = math.max(0, math.min(10, tonumber(def.light_reduce) or 0)),
		sound        = def.sound,
		sound_gain   = tonumber(def.sound_gain) or 0.5,
		ruleset_hook = def.ruleset_hook,
	}
end

function dnd3.weather.get_type(id)
	return WEATHER_TYPES[id]
end

function dnd3.weather.list_types()
	local list = {}
	for _, def in pairs(WEATHER_TYPES) do list[#list + 1] = def end
	table.sort(list, function(a, b) return a.id < b.id end)
	return list
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Built-in weather types
-- ─────────────────────────────────────────────────────────────────────────────

-- Shared particle helper: upward-offset rain drop
local function rain_particles(density)
	return {
		amount          = density,
		time            = 0,           -- infinite
		minpos          = { x = -15, y =  8, z = -15 },
		maxpos          = { x =  15, y = 12, z =  15 },
		minvel          = { x = -0.5, y = -12, z = -0.5 },
		maxvel          = { x =  0.5, y =  -8, z =  0.5 },
		minacc          = { x = 0, y = -0.5, z = 0 },
		maxacc          = { x = 0, y =  0,   z = 0 },
		minexptime      = 1.0,
		maxexptime      = 2.0,
		minsize         = 0.3,
		maxsize         = 0.5,
		collisiondetection = true,
		collision_removal  = true,
		vertical        = false,
		texture         = "[fill:1x8:#88AAFFB0",
		glow            = 0,
	}
end

local function snow_particles(density)
	return {
		amount          = density,
		time            = 0,
		minpos          = { x = -15, y =  8, z = -15 },
		maxpos          = { x =  15, y = 12, z =  15 },
		minvel          = { x = -1,  y = -2, z = -1  },
		maxvel          = { x =  1,  y = -1, z =  1  },
		minacc          = { x = -0.2, y = 0, z = -0.2 },
		maxacc          = { x =  0.2, y = 0, z =  0.2 },
		minexptime      = 2.0,
		maxexptime      = 4.0,
		minsize         = 0.5,
		maxsize         = 1.2,
		collisiondetection = true,
		collision_removal  = true,
		vertical        = false,
		texture         = "[fill:4x4:#EEEEFFD0",
		glow            = 1,
	}
end

dnd3.weather.register_type({
	id       = "clear",
	label    = "Clear",
})

dnd3.weather.register_type({
	id           = "overcast",
	label        = "Overcast",
	sky_tint     = { r = 60, g = 65, b = 80, a = 255 },
	sky_tint_str = 0.35,
	light_reduce = 1,
	sound        = "dnd3_wind_soft",
	sound_gain   = 0.3,
	ruleset_hook = "overcast",
})

dnd3.weather.register_type({
	id           = "rain",
	label        = "Rain",
	particles    = rain_particles(80),
	sky_tint     = { r = 50, g = 60, b = 80, a = 255 },
	sky_tint_str = 0.45,
	light_reduce = 2,
	sound        = "dnd3_rain",
	sound_gain   = 0.7,
	ruleset_hook = "rain",
})

dnd3.weather.register_type({
	id           = "heavy_rain",
	label        = "Heavy Rain",
	particles    = rain_particles(200),
	sky_tint     = { r = 35, g = 40, b = 60, a = 255 },
	sky_tint_str = 0.60,
	fog_range    = 60,
	light_reduce = 3,
	sound        = "dnd3_rain_heavy",
	sound_gain   = 0.9,
	ruleset_hook = "heavy_rain",
})

dnd3.weather.register_type({
	id           = "storm",
	label        = "Storm",
	particles    = rain_particles(300),
	sky_tint     = { r = 20, g = 22, b = 35, a = 255 },
	sky_tint_str = 0.75,
	fog_range    = 40,
	light_reduce = 5,
	sound        = "dnd3_storm",
	sound_gain   = 1.0,
	ruleset_hook = "storm",
})

dnd3.weather.register_type({
	id           = "snow",
	label        = "Snow",
	particles    = snow_particles(60),
	sky_tint     = { r = 200, g = 210, b = 230, a = 255 },
	sky_tint_str = 0.30,
	light_reduce = 1,
	sound        = "dnd3_wind_cold",
	sound_gain   = 0.5,
	ruleset_hook = "snow",
})

dnd3.weather.register_type({
	id           = "blizzard",
	label        = "Blizzard",
	particles    = snow_particles(250),
	sky_tint     = { r = 220, g = 225, b = 240, a = 255 },
	sky_tint_str = 0.70,
	fog_range    = 30,
	light_reduce = 4,
	sound        = "dnd3_blizzard",
	sound_gain   = 1.0,
	ruleset_hook = "blizzard",
})

dnd3.weather.register_type({
	id           = "fog",
	label        = "Fog",
	sky_tint     = { r = 160, g = 165, b = 175, a = 255 },
	sky_tint_str = 0.55,
	fog_range    = 25,
	light_reduce = 1,
	sound        = "dnd3_wind_soft",
	sound_gain   = 0.2,
	ruleset_hook = "fog",
})

dnd3.weather.register_type({
	id           = "ash",
	label        = "Ashfall",
	particles    = {
		amount     = 40,
		time       = 0,
		minpos     = { x = -15, y = 8, z = -15 },
		maxpos     = { x =  15, y =12, z =  15 },
		minvel     = { x = -1, y = -1, z = -1  },
		maxvel     = { x =  1, y = -0.3, z = 1 },
		minacc     = { x = 0,  y = 0,  z = 0   },
		maxacc     = { x = 0,  y = 0,  z = 0   },
		minexptime = 3.0,
		maxexptime = 6.0,
		minsize    = 0.3,
		maxsize    = 0.8,
		collisiondetection = true,
		collision_removal  = true,
		texture    = "[fill:4x4:#666060A0",
		glow       = 0,
	},
	sky_tint     = { r = 80, g = 70, b = 60, a = 255 },
	sky_tint_str = 0.40,
	light_reduce = 3,
	sound        = "dnd3_wind_soft",
	sound_gain   = 0.3,
	ruleset_hook = "ash",
})
