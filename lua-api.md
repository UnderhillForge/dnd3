# dnd3 Lua API Reference

Version: 0.1.0-dnd3
Status: Phase 1 (core VTT foundation)

## Documentation Policy

This file is the authoritative Lua API and command reference for dnd3 modders.

Update requirements for contributors:
- Any new public API function in `dnd3.*` must be documented here in the same change.
- Any new chat command must be documented here in the same change.
- Any signature, return format, or permission change must update this file.
- Deprecated APIs and commands must be marked with a migration note.

## Scope and Modularity Rules

- Core shared systems live in `games/dnd3/mods/dnd3_core` and must remain ruleset-agnostic.
- Ruleset-specific logic belongs in `rulesets/<system>/`.
- Public API surface is exposed via the global `dnd3` table.

## Data Structures

### Ruleset Definition

```lua
{
  id = "dnd35",               -- required
  title = "Dungeons and Dragons 3.5e", -- required
  version = "0.1.0-dnd3",     -- optional
  source = "builtin_placeholder", -- optional
  meta = {}                     -- optional
}
```

### Token Definition

```lua
{
  label = "Goblin A",         -- optional
  pos = { x = 0, y = 0, z = 0 }, -- optional
  scale = 1,                    -- optional
  rotation = 0,                 -- optional
  elevation = 0,                -- optional
  owner = "playername",        -- optional
  meta = {}                     -- optional
}
```

## Public Lua API

### Rulesets and Sheets

#### dnd3.register_ruleset(def)
Registers or replaces a ruleset descriptor.

Parameters:
- `def` (table): ruleset definition

Returns:
- ruleset table on success

Errors:
- Throws Lua error when required fields are missing

#### dnd3.get_ruleset(id)
Returns one ruleset descriptor.

Parameters:
- `id` (string)

Returns:
- ruleset table or `nil`

#### dnd3.list_rulesets()
Returns all registered rulesets sorted by id.

Returns:
- array of ruleset tables

#### dnd3.register_sheet_field(ruleset_id, field)
Registers a ruleset sheet field definition.

Parameters:
- `ruleset_id` (string)
- `field` (table) with required `field.id`

Returns:
- `field`

Errors:
- Throws Lua error on invalid args

#### dnd3.get_sheet_fields(ruleset_id)
Returns sheet fields for a ruleset.

Parameters:
- `ruleset_id` (string)

Returns:
- table keyed by field id

### Dice and Effects

#### dnd3.roll(expression, opts)
Rolls a dice expression.

Supported expression examples:
- `1d20+5`
- `4d6dl1`
- `2d8+3`
- `1d6!` (exploding)

Supported keep/drop suffixes:
- `khN`, `klN`, `dhN`, `dlN`

Optional `opts`:
- `{ advantage = true }`
- `{ disadvantage = true }`

Returns:
- result table on success
- `nil, err` on failure

#### dnd3.apply_effect(target, effect)
Placeholder core effect application hook.

Parameters:
- `target` (any)
- `effect` (any)

Returns:
- table with fields: `applied`, `target`, `effect`, `timestamp`

### Map Editing

#### dnd3.map_fill(pos1, pos2, nodename)
Fills the rectangular area with a node.

Parameters:
- `pos1`, `pos2` tables `{x,y,z}`
- `nodename` (string)

Returns:
- count (number of nodes changed)
- or `nil, err`

#### dnd3.map_raise(pos1, pos2, delta)
Shifts all columns in area by a height delta.

Parameters:
- `pos1`, `pos2` tables `{x,y,z}`
- `delta` integer (`!= 0`)

Returns:
- count (number of nodes shifted)
- or `nil, err`

#### dnd3.map_edit_fill(pos1, pos2, nodename)
API wrapper around `dnd3.map_fill`.

#### dnd3.map_edit_raise(pos1, pos2, delta)
API wrapper around `dnd3.map_raise`.

### Tokens

#### dnd3.token_set(id, def)
Creates or replaces token data.

Returns:
- token table or `nil, err`

#### dnd3.token_get(id)
Gets one token by id.

Returns:
- token table or `nil`

#### dnd3.token_move(id, pos)
Updates token position.

Returns:
- token table or `nil, err`

#### dnd3.token_transform(id, transform)
Updates any of `scale`, `rotation`, `elevation`.

Returns:
- token table or `nil, err`

#### dnd3.token_list()
Lists all tokens sorted by id.

Returns:
- array of token tables

#### dnd3.token_remove(id)
Removes a token.

Returns:
- `true` or `nil, err`

#### dnd3.register_token(id, def)
API wrapper around `dnd3.token_set`.

#### dnd3.move_token(id, pos)
API wrapper around `dnd3.token_move`.

#### dnd3.transform_token(id, transform)
API wrapper around `dnd3.token_transform`.

### Initiative

#### dnd3.initiative_set(token, score)
Adds or updates initiative score.

Returns:
- `true`

#### dnd3.initiative_remove(token)
Removes initiative entry.

Returns:
- `true`

#### dnd3.initiative_list()
Returns sorted initiative entries (highest score first).

Returns:
- array of `{ token, score }`

#### dnd3.initiative_next()
Advances turn index with wrap-around.

Returns:
- `{ token, score }` or `nil, err`

### Visibility and Fog State

#### dnd3.visibility_reveal(name, pos)
Marks one fog cell as revealed for player.

Returns:
- `true`

#### dnd3.visibility_hide(name, pos)
Hides one fog cell for player.

Returns:
- `true`

#### dnd3.visibility_clear(name)
Clears all revealed cells for player.

Returns:
- `true`

#### dnd3.visibility_set_los(name, radius)
Sets per-player LOS radius metadata.

Returns:
- final LOS radius (integer)

#### dnd3.visibility_get(name)
Returns per-player visibility state.

Returns:
- table: `{ revealed_cells = {...}, los_radius = N }`

### Prefabs

#### dnd3.prefab_capture(id, minp, maxp)
Captures a map volume into prefab storage.

Returns:
- prefab table or `nil, err`

#### dnd3.prefab_stamp(id, origin)
Stamps captured prefab at origin.

Returns:
- `true` or `nil, err`

#### dnd3.prefab_list()
Returns sorted prefab ids.

Returns:
- array of strings

### Session and Persistence

#### dnd3.get_active_ruleset()
Returns active ruleset id.

#### dnd3.set_active_ruleset(id)
Switches active ruleset (must be registered).

Returns:
- `true` or `false, err`

#### dnd3.set_session_name(name)
Sets session display name.

Returns:
- `true` or `false, err`

#### dnd3.export_state()
Exports lightweight session payload.

Returns:
- table containing `version`, `session`, `initiative`, `rulesets`, `sheet_fields`, `tokens`

#### dnd3.save_session_snapshot(name)
Saves named snapshot to mod storage.

Returns:
- `true` or `nil, err`

#### dnd3.list_session_snapshots()
Lists saved snapshot names.

Returns:
- array of strings

### Roles and Permissions

#### dnd3.get_role(player_name)
Returns player role.

Returns:
- `gm`, `player`, or `observer` (default `player`)

#### dnd3.set_role(player_name, role)
Sets player role.

Returns:
- `true` or `false, err`

#### dnd3.can(player_name, action)
Permission check for action names.

Current actions:
- `map_edit`
- `token_control`
- `initiative_edit`
- `fog_control`
- `ruleset_switch`
- `dice_roll`

Returns:
- boolean

### UI and Overlay

#### dnd3.grid_overlay_is_enabled(player_name)
Returns if tactical grid readout is enabled.

Returns:
- boolean

#### dnd3.grid_overlay_set(player_name, enabled)
Sets tactical grid readout state.

Returns:
- final enabled state (boolean)

#### dnd3.grid_overlay_toggle(player_name)
Toggles tactical grid readout state.

Returns:
- final enabled state (boolean)

#### dnd3.open_panel(player_name)
Opens the dnd3 control panel formspec.

Returns:
- `true` when panel function is available
- `false` when panel system is unavailable

#### dnd3.set_grid_overlay(player_name, enabled)
API wrapper around `dnd3.grid_overlay_set`.

#### dnd3.toggle_grid_overlay(player_name)
API wrapper around `dnd3.grid_overlay_toggle`.

### World-Space Grid (`grid_world.lua`)

Registers the `dnd3:grid_floor` node (semi-transparent thin slab at floor level).
Right-clicking a `dnd3:grid_floor` node while a token is selected moves that token to
the cell.  One grid cell = 5 nodes = 5 feet.

#### dnd3.grid_world_paint(pos1, pos2)
Places `dnd3:grid_floor` nodes across a rectangular region.
Coordinates are snapped to the nearest 5-node cell boundary.
Uses the minimum Y of pos1/pos2 as the floor level.

Parameters:
- `pos1`, `pos2` – tables `{x,y,z}` (opposite corners)

Returns:
- count of grid cells placed

#### dnd3.grid_world_clear(pos1, pos2)
Removes `dnd3:grid_floor` nodes from a rectangular region.

Parameters:
- `pos1`, `pos2` – tables `{x,y,z}`

Returns:
- count of grid cells removed

### Fog of War Rendering (`fog_render.lua`)

Registers the `dnd3:fog` node (dark, semi-transparent column, walkable=false).
Fog is **global** (same for all players) in Phase 1; per-player LOS requires C++
rendering hooks (deferred to Phase 3).
Uses `fog_control` permission (GM only).

#### dnd3.fog_render_fill(pos1, pos2)
Places `dnd3:fog` columns across a rectangular region.

Returns:
- count of cells filled

#### dnd3.fog_render_reveal(pos1, pos2)
Removes `dnd3:fog` columns from a rectangular region.

Returns:
- count of cells revealed

#### dnd3.fog_render_reveal_los(player_name, center)
Reveals fog within the player's `los_radius` (from `visibility.lua`) around `center`.

Parameters:
- `player_name` (string)
- `center` – table `{x,y,z}`

Returns:
- count of cells revealed

### Token Entities (`token_entity.lua`)

Spawns live `dnd3:token_entity` objects that map to data records in `tokens.lua`.
Right-click an entity to select it; then right-click a `dnd3:grid_floor` node or
use `/dnd3_token_drop` to move it.  Punch an entity (GM only) to despawn it.

#### dnd3.token_spawn(token_id)
Spawns a world entity for an existing token data record.

Returns:
- `ObjectRef` or `nil, err`

#### dnd3.token_despawn(token_id)
Removes the world entity (does not delete the data record).

Returns:
- `true` if an entity was removed, `false` otherwise

#### dnd3.token_select(player_name, token_id)
Sets the active token selection for a player.  No permission check – caller is
responsible for authorisation before calling.

#### dnd3.token_deselect(player_name)
Clears the active token selection for a player.

#### dnd3.token_get_selected(player_name)
Returns the token_id currently selected by the player, or `nil`.

#### dnd3._token_entity_sync(token_id)
Internal helper – teleports the live entity to match `token.pos` after a data move.
Called automatically by `/dnd3_token_drop` and the grid-cell right-click handler.

### Audio – Sound Emitters (`audio/emitters.lua`)

Persistent world-space sound emitters. Each emitter loops a named sound file at a
fixed position and survives server restarts.  All emitters are re-started when any
player joins.  Requires `map_edit` permission (GM only) to add/remove.

#### dnd3.audio.emitter_add(id, def)
Place or replace a looping sound emitter.

`def` fields:
- `sound` (string, required) — sound name without `.ogg`
- `pos` (`{x,y,z}`, required) — world position
- `gain` (number, 0–1, default 1.0)
- `radius` (number, nodes, default 32)
- `pitch` (number, 0.1–4.0, default 1.0)
- `loop` (boolean, default true)

Returns:
- emitter record table, or `nil, err`

#### dnd3.audio.emitter_remove(id)
Stop and remove a sound emitter.

Returns:
- `true` or `false, err`

#### dnd3.audio.emitter_list()
Returns all emitter records sorted by id.

Returns:
- array of emitter tables

#### dnd3.audio.emitter_get(id)
Returns one emitter record or `nil`.

#### dnd3.audio.emitters_restart()
Stops all live handles and replays every registered emitter.  Call after world
reload or when players report missing audio.

### Audio – GM Streaming (`audio/streaming.lua`)

One-shot or looping audio broadcast to all players, a named player list, or a
positional radius.  Multiple named streams can run concurrently.  Fade-in and
fade-out are supported.  Requires `fog_control` permission (GM only) to start/stop.

#### dnd3.audio.stream(def)
Start an audio stream.  Stops any existing stream with the same id first.

`def` fields:
- `id` (string, required) — unique stream id
- `sound` (string, required) — sound name without `.ogg`
- `target` (string, default `"all"`) — `"all"` | `"players"` | `"radius"`
- `players` (string[], used when target=`"players"`) — player name list
- `pos` (`{x,y,z}`, used when target=`"radius"`) — anchor position
- `radius` (number, nodes, default 48) — hear distance for radius target
- `gain` (number, 0–1, default 0.8)
- `pitch` (number, 0.1–4.0, default 1.0)
- `loop` (boolean, default false)
- `fade_in` (number, seconds, default 0) — ramp gain from 0 to target

Returns:
- stream id string, or `nil, err`

#### dnd3.audio.stream_stop(id)
Stop a stream immediately.

Returns:
- `true` or `false` (not found)

#### dnd3.audio.stream_fade_out(id, seconds)
Fade out and stop a stream.

Parameters:
- `id` (string)
- `seconds` (number, default 2)

Returns:
- `true` or `false` (not found)

#### dnd3.audio.stream_stop_all()
Stop all active streams.

#### dnd3.audio.stream_list()
Returns array of active stream ids (strings), sorted.

#### dnd3.audio.stream_get(id)
Returns info table `{ id, sound, target, gain, loop }` or `nil`.

### Time of Day (`time_of_day/cycle.lua`)

Drives dnd3's internal time-of-day with a configurable speed multiplier and applies
per-player sky/sun/moon/star settings every 2 seconds via interpolated colour stops.
External systems (weather, lighting) subscribe via `dnd3.tod.register_tick_hook`.

Time is a float in **[0, 1)**: `0.0` = midnight · `0.25` = sunrise · `0.5` = noon · `0.75` = sunset.

#### dnd3.tod.get()
Returns current time fraction.

#### dnd3.tod.set(t)
Sets time directly and applies sky immediately to all players.

Parameters:
- `t` number – [0, 1)

Returns:
- final clamped time fraction

#### dnd3.tod.freeze(frozen)
Freeze (`true`) or unfreeze (`false`) the cycle.

Returns:
- current frozen state (boolean)

#### dnd3.tod.is_frozen()
Returns whether the cycle is frozen (boolean).

#### dnd3.tod.set_speed(speed)
Set cycle speed multiplier. `1.0` = dnd3 default (1 day per 24 real minutes).
`0` pauses advancement (equivalent to freeze).

Returns:
- final speed value

#### dnd3.tod.get_speed()
Returns current speed multiplier (number).

#### dnd3.tod.register_tick_hook(fn)
Register an external callback fired every tick (every 2 seconds of real time).

Signature: `fn(time_fraction, sky_sample)`

`sky_sample` fields (all `{r,g,b,a}` colour tables + numbers):
- `sky_top`, `sky_hor`, `fog` – interpolated RGB colours
- `sun_scale`, `moon_scale` – [0, 1] scale values

Used by `weather/` to blend fog/cloud colours into the current sky.

#### dnd3.tod.to_hhmm(t)
Convert time fraction to `"HH:MM"` string (24h).

Parameters:
- `t` number – defaults to current time if omitted

Returns:
- string e.g. `"14:35"`

#### dnd3.tod.period(t)
Return named period string for a time fraction.

Returns one of: `"night"` · `"dawn"` · `"morning"` · `"day"` · `"afternoon"` · `"dusk"` · `"evening"`

### Weather (`weather/types.lua` + `weather/engine.lua`)

Dynamic weather system.  Weather is resolved per-player in priority order:
**per-player override > regional cell > global**.  Each weather type drives
particles, sky tint (blended on top of ToD colours via `tod.register_tick_hook`),
ambient sound, and an optional `ruleset_hook` key for Phase 2 mechanical effects.

#### Weather Type Definition

```lua
{
  id           = "rain",        -- required, unique string
  label        = "Rain",        -- display name
  particles    = { ... },       -- particle_spawner table (nil = no particles)
  sky_tint     = {r,g,b,a},    -- RGBA 0-255 colour overlay (nil = no tint)
  sky_tint_str = 0.45,          -- blend strength 0-1 (default 0)
  fog_range    = 60,            -- override fog distance in nodes (nil = no change)
  light_reduce = 2,             -- reduce max light 0-10 (default 0)
  sound        = "dnd3_rain",   -- ambient loop sound (nil = none)
  sound_gain   = 0.7,           -- gain 0-1
  ruleset_hook = "rain",        -- string key for ruleset callbacks (nil = none)
}
```

**Built-in types:** `clear` · `overcast` · `rain` · `heavy_rain` · `storm` · `snow` · `blizzard` · `fog` · `ash`

#### dnd3.weather.register_type(def)
Register a new weather type.  Throws on missing `def.id`.

#### dnd3.weather.get_type(id)
Returns weather type table or `nil`.

#### dnd3.weather.list_types()
Returns all registered weather types sorted by id.

Returns:
- array of weather type tables

#### dnd3.weather.set_global(id)
Set global weather for all players (no override active).  Forces immediate refresh.

Returns:
- weather id string, or `nil, err`

#### dnd3.weather.get_global()
Returns current global weather id (string).

#### dnd3.weather.set_player(player_name, id)
Set a per-player weather override.  Pass `nil` as `id` to clear the override.

Returns:
- effective weather id, or `nil, err`

#### dnd3.weather.get_player(player_name)
Returns per-player weather override id or `nil` if none.

#### dnd3.weather.region_paint(wid, pos1, pos2)
Paint a weather type onto the regional grid cells covering the XZ footprint of
`pos1`/`pos2`.  One region cell = 20 nodes.  Y is ignored.

Returns:
- count of cells painted (0 if unknown weather type)

#### dnd3.weather.region_clear(pos1, pos2)
Clear regional weather overrides from the XZ footprint.

Returns:
- count of cells cleared

#### dnd3.weather.at_pos(pos)
Return the effective weather id at a world position (regional lookup, fallback to global).

Returns:
- weather id string

#### dnd3.weather.status()
Return a snapshot of the full weather state.

Returns:
- table: `{ global, player_overrides, region_cells }`

## Chat Commands

### Roles and Session
- `/dnd3_role <player> <gm|player|observer>`
- `/dnd3_ruleset [list|set <id>|current]`
- `/dnd3_session_save <snapshot_name>`
- `/dnd3_session_list`

### Dice and Initiative
- `/dnd3_roll <expression>`
- `/dnd3_init_add <token> <score>`
- `/dnd3_init_next`

### Map, Tokens, Fog
- `/dnd3_map_fill <x1> <y1> <z1> <x2> <y2> <z2> <nodename>`
- `/dnd3_map_raise <x1> <y1> <z1> <x2> <y2> <z2> <delta>`
- `/dnd3_token_add <id> <x> <y> <z> [label]`
- `/dnd3_token_move <id> <x> <y> <z>`
- `/dnd3_token_xform <id> <scale> <rotation> <elevation>`
- `/dnd3_token_list`
- `/dnd3_fog_reveal <player> <x> <y> <z>`
- `/dnd3_fog_hide <player> <x> <y> <z>`
- `/dnd3_fog_clear <player>`

### World Grid (requires GM role)
- `/dnd3_grid_paint <radius>` – paint grid floor nodes in a square radius (in cells) around you
- `/dnd3_grid_clear_world <radius>` – remove grid floor nodes

### Fog Rendering (requires GM role)
- `/dnd3_fog_fill <radius>` – fill fog columns in a square radius (in cells) around you
- `/dnd3_fog_reveal_area <radius>` – remove fog in a square radius around you
- `/dnd3_fog_reveal_los [<player>]` – reveal fog within a player's LOS radius

### Token Entities (spawn/despawn requires GM; select/drop requires token_control or ownership)
- `/dnd3_token_spawn <id>` – spawn a world entity for a registered token
- `/dnd3_token_despawn <id>` – remove a token's world entity (data preserved)
- `/dnd3_token_select <id>` – select a token for movement
- `/dnd3_token_drop <x> <y> <z>` – move selected token to coordinates and deselect
- `/dnd3_token_deselect` – cancel current token selection

### Prefabs and UI
- `/dnd3_prefab_capture <id> <x1> <y1> <z1> <x2> <y2> <z2>`
- `/dnd3_prefab_stamp <id> <x> <y> <z>`
- `/dnd3_prefab_list`
- `/dnd3_panel`
- `/dnd3_grid [on|off|toggle]`

### Audio – Sound Emitters (requires GM / `map_edit` permission)
- `/dnd3_emitter_add <id> <sound> [gain] [radius] [pitch]` — place looping emitter at your position
- `/dnd3_emitter_remove <id>` — remove emitter and stop playback
- `/dnd3_emitter_list` — list all registered emitters
- `/dnd3_emitter_restart` — restart all emitters (use after world reload)

### Audio – GM Streaming (requires GM / `fog_control` permission)
- `/dnd3_stream <id> <sound> [target] [gain] [pitch] [loop] [fade_in]`
  - `target`: `all` | `players:Alice,Bob` | `radius:48`
  - `loop`: `true`/`false`, `fade_in`: seconds
- `/dnd3_stream_stop <id>` — stop stream immediately
- `/dnd3_stream_fade <id> [seconds]` — fade out and stop (default 2s)
- `/dnd3_stream_stop_all` — stop every active stream
- `/dnd3_stream_list` — list active streams

### Time of Day (requires GM / `map_edit` permission for set/freeze/speed)
- `/dnd3_time` — show current time, period, speed, frozen state (all roles)
- `/dnd3_time_set <HH:MM | fraction>` — set time directly (e.g. `14:30` or `0.6`)
- `/dnd3_time_freeze [on|off|toggle]` — freeze/unfreeze the cycle
- `/dnd3_time_speed <multiplier>` — set cycle speed (1.0=default, 0=pause, 10=10×)
- `/dnd3_time_ff <hours>` — fast-forward N in-game hours then freeze

### Weather
- `/dnd3_weather` — show current weather status (all roles)
- `/dnd3_weather_list` — list all registered weather types (all roles)
- `/dnd3_weather_set <id>` — set global weather for all players (GM)
- `/dnd3_weather_player <player> <id|clear>` — set or clear per-player weather override (GM)
- `/dnd3_weather_paint <id> [radius_cells]` — paint regional weather around GM position (GM)
- `/dnd3_weather_clear_region [radius_cells]` — clear regional weather cells around GM position (GM)

## Known Current Limitations (Phase 1)

- Fog is global (same view for all players). Per-player LOS requires C++ rendering hooks (Phase 3).
- Token visuals are placeholder upright sprites; proper pixel-art sprites are Phase 2/3 artwork.
- Panel UI is command/formspec based and will evolve into richer VTT UX.
- Weather particle spawners are global positional; per-player particle tracking is Phase 3.

## Changelog Notes

- 0.1.0-dnd3 Phase 1: Introduced core API baseline, commands, world-space grid, fog rendering, token entity selection/drag workflow, audio foundation (sound emitters + GM streaming), time-of-day cycle with GM controls, and active weather system (types registry, tick engine, regional overrides, GM controls).
