# dnd3 Lua API Reference

This document covers all public Lua functions and tables exposed by the **dnd3_core** mod and the **dnd35** ruleset.  All functions are available from within mods, rulesets, and the server console after `dnd3_core` has loaded.

---

## Table of Contents

1. [Core — Rulesets](#core--rulesets)
2. [Core — Character Sheets](#core--character-sheets)
3. [Core — Tokens](#core--tokens)
4. [Core — Dice](#core--dice)
5. [Core — Initiative](#core--initiative)
6. [Core — Permissions](#core--permissions)
7. [Core — Map Editing](#core--map-editing)
8. [Core — Fog of War](#core--fog-of-war)
9. [Core — Visibility](#core--visibility)
10. [Core — Grid](#core--grid)
11. [Core — Prefabs](#core--prefabs)
12. [Core — Session / Persistence](#core--session--persistence)
13. [Core — UI Panel](#core--ui-panel)
14. [Core — Diorama Studio](#core--diorama-studio)

---

15. [Core — Time of Day](#core--time-of-day)

16. [Core — Weather](#core--weather)

17. [Core — Audio](#core--audio)

18. [dnd35 — Abilities](#dnd35--abilities)

19. [dnd35 — Skills](#dnd35--skills)

20. [dnd35 — Conditions](#dnd35--conditions)
21. [dnd35 — Classes](#dnd35--classes)
22. [dnd35 — Feats](#dnd35--feats)
23. [dnd35 — Spells](#dnd35--spells)

---

## Core — Rulesets



### `dnd3.register_ruleset(def)`



Registers a ruleset so it can be selected for a session.



| Field     | Type    | Required | Description                        |

|-----------|---------|----------|------------------------------------|

| `id`      | string  | ✓        | Unique identifier, e.g. `"dnd35"` |

| `title`   | string  | ✓        | Human-readable name               |

| `version` | string  |          | Version string                    |

| `ogl`     | boolean |          | `true` if content is OGL          |



### `dnd3.get_ruleset(id) → def | nil`



Returns the registered ruleset definition for `id`, or `nil` if not found.



### `dnd3.list_rulesets() → { id, ... }`



Returns a sorted list of all registered ruleset IDs.



---



## Core — Character Sheets



### `dnd3.register_sheet_field(ruleset_id, field)`



Registers a sheet field definition for the given ruleset.



| Field       | Type   | Description                         |

|-------------|--------|-------------------------------------|

| `id`        | string | Field key used in `sheet.*`         |

| `label`     | string | Display name                        |

| `default`   | any    | Default value for new characters    |

| `type`      | string | `"number"`, `"string"`, `"table"`   |


### `dnd3.get_sheet_fields(ruleset_id) → { field, ... }`

Returns all field definitions registered for the given ruleset.

### `dnd3.character.create(token_id, ruleset_id) → sheet`

Creates a new character sheet for the token and populates defaults from the ruleset's registered fields.


### `dnd3.character.get(token_id) → sheet | nil`



Returns the character sheet table for the given token, or `nil`.


### `dnd3.character.delete(token_id)`

Removes the character sheet and all associated data for the token.

### `dnd3.character.set(token_id, field, value)`

Sets a single field on the sheet and persists it.

### `dnd3.character.get_field(token_id, field) → value | nil`

Returns the value of a single sheet field.

### `dnd3.character.compute(token_id)`

Runs all registered compute hooks in priority order against the token's sheet, recomputing derived values (saves, BAB, skill totals, etc.).

### `dnd3.character.register_compute_hook(fn, priority)`

Registers a function to be called during `compute`.  Lower `priority` numbers run first.

```lua
dnd3.character.register_compute_hook(function(sheet)
    -- mutate sheet fields in place
end, 10)
```

### `dnd3.character.apply_condition(token_id, cond_id)`

Appends `cond_id` to the token's `sheet.conditions` array if not already present.

### `dnd3.character.remove_condition(token_id, cond_id)`

Removes `cond_id` from the token's `sheet.conditions` array.

### `dnd3.character.has_condition(token_id, cond_id) → boolean`

Returns `true` if the token currently has the given condition.

### `dnd3.character.list() → { token_id, ... }`

Returns the IDs of all tokens that have an active character sheet.

---

## Core — Tokens

Tokens are the on-map representation of characters, monsters, and objects.

### `dnd3.token_set(id, def)`

Creates or replaces a token definition.

| Field    | Type   | Description                   |
|----------|--------|-------------------------------|
| `id`     | string | Unique token ID               |
| `label`  | string | Display name                  |
| `pos`    | table  | `{x, y, z}` world position   |
| `size`   | number | Token size in grid squares    |
| `sprite` | string | Texture name                  |

### `dnd3.token_get(id) → def | nil`

Returns the token definition, or `nil`.

### `dnd3.token_move(id, pos)`

Moves the token to `pos = {x, y, z}`.

### `dnd3.token_transform(id, transform)`

Applies a transform table to the token's visual properties.

### `dnd3.token_list() → { id, ... }`

Returns a list of all registered token IDs.

### `dnd3.token_remove(id)`

Removes a token from the world.

### `dnd3.token_spawn(token_id)`

Spawns the token entity into the world at its current `pos`.

### `dnd3.token_despawn(token_id)`

Removes the entity from the world without deleting the token definition.

### `dnd3.token_select(player_name, token_id)`

Sets the active selection for a player.

### `dnd3.token_deselect(player_name)`

Clears the player's current selection.

### `dnd3.token_get_selected(player_name) → token_id | nil`

Returns the ID of the currently selected token for the player.

---

## Core — Dice

### `dnd3.roll(expression, opts) → result`

Rolls a dice expression and returns a result table.

```lua
local r = dnd3.roll("2d6+3", { player_name = "Alice" })
-- r.total   number  -- final sum
-- r.terms   table   -- per-term roll details
-- r.expression string -- original expression
```

`opts` (optional):

| Key        | Type    | Description                                |
|------------|---------|--------------------------------------------|
| `advantage`| boolean | Roll twice, take higher                    |
| `disadvantage` | boolean | Roll twice, take lower                 |
| `player_name` | string | Player used for visual dice throws (dice_api) |
| `token_id` | string | Resolves owning player from token for visual throws |
| `visual` | boolean | Set `false` to disable visual throw for this roll |

When `dice_api` and a compatible dice pack (for example `dice_classic`) are loaded,
`dnd3.roll` will also throw physical visual dice for each dice term in the
expression. Numeric results are still returned immediately by `dnd3.roll` and are
authoritative for game logic.

---

## Core — Initiative

### `dnd3.initiative_set(token, score)`

Sets the initiative score for a token.

### `dnd3.initiative_remove(token)`

Removes a token from the initiative order.

### `dnd3.initiative_list() → { {token, score}, ... }`

Returns the current initiative order, sorted descending by score.

### `dnd3.initiative_next() → token_id | nil`

Advances to the next turn and returns the active token ID.

---

## Core — Permissions

### `dnd3.get_role(player_name) → role`

Returns the player's role.  Built-in roles: `"dm"`, `"player"`, `"spectator"`.

### `dnd3.set_role(player_name, role)`

Assigns a role to the player.

### `dnd3.can(player_name, action) → boolean`

Returns `true` if the player's role permits `action`.  Actions: `"edit_map"`, `"move_any_token"`, `"dm_tools"`, etc.

---

## Core — Map Editing

### `dnd3.map_fill(pos1, pos2, nodename)`

Fills a bounding box with the given node type.

### `dnd3.map_raise(pos1, pos2, delta)`

Raises or lowers the terrain in a region by `delta` nodes.

---

## Core — Fog of War

### `dnd3.fog_render_fill(pos1, pos2)`

Fills a region with fog.

### `dnd3.fog_render_reveal(pos1, pos2)`

Reveals a rectangular region to all DM-side players.

### `dnd3.fog_render_reveal_los(player_name, center)`

Reveals nodes within line-of-sight from `center` for the given player.

---

## Core — Visibility

Per-player visibility tracking (independent of fog rendering).

### `dnd3.visibility_reveal(name, pos)`

Marks `pos` as visible for player `name`.

### `dnd3.visibility_hide(name, pos)`

Marks `pos` as hidden for player `name`.

### `dnd3.visibility_clear(name)`

Resets all visibility data for the player.

### `dnd3.visibility_set_los(name, radius)`

Sets the line-of-sight reveal radius (in nodes) for the player.

### `dnd3.visibility_get(name) → table`

Returns the full visibility state table for the player.

---

## Core — Grid

### `dnd3.grid_world_paint(pos1, pos2)`

Paints grid lines over a region.

### `dnd3.grid_world_clear(pos1, pos2)`

Removes grid lines from a region.

### `dnd3.grid_overlay_is_enabled(player_name) → boolean`

Returns `true` if the HUD grid overlay is shown for the player.

### `dnd3.grid_overlay_set(player_name, enabled)`

Shows or hides the HUD grid overlay.

### `dnd3.grid_overlay_toggle(player_name)`

Toggles the HUD grid overlay.

---

## Core — Hybrid Terrain

The hybrid terrain system keeps voxels as canonical data and adds runtime
visual/movement helpers for smoother slopes and pathing.

### `dnd3.hybrid_terrain.generate_slopes(pos1, pos2[, opts]) -> count | nil, err`

Generates basic runtime slope ramps in the given volume.

- `opts.max_step` (`1` or `2`): maximum neighbor height delta considered a slope.

### `dnd3.hybrid_terrain.voxel_to_mesh_descriptor(pos1, pos2[, opts]) -> descriptor | nil, err`

Bakes an exposed-face descriptor from voxel data for later mesh conversion.

- `opts.force = true` bypasses descriptor cache.
- Returns fields: `nodes_processed`, `exposed_faces`, `quads`, `bounds`.

### `dnd3.hybrid_terrain.build_navmesh(pos1, pos2[, opts]) -> navmesh | nil, err`

Builds a lightweight 2D walkability graph from voxel surface heights.

### `dnd3.hybrid_terrain.find_path(navmesh, start_pos, goal_pos) -> path | nil, err`

Runs A* on a navmesh generated by `build_navmesh`.

### Chat Commands

- `/dnd3_hybrid_slopes <radius>`: generate slope ramps around player.
- `/dnd3_hybrid_bake <radius>`: bake mesh descriptor around player.
- `/dnd3_hybrid_navmesh <radius>`: build and cache navmesh around player.
- `/dnd3_hybrid_path <x> <z>`: pathfind to target using cached navmesh.

---

## Core — Prefabs

### `dnd3.prefab_capture(id, minp, maxp)`

Captures the nodes and token definitions in a bounding box and stores them as prefab `id`.

### `dnd3.prefab_stamp(id, origin)`

Pastes a saved prefab at `origin`.

### `dnd3.prefab_list() → { id, ... }`

Returns all saved prefab IDs.

---

## Core — Session / Persistence

### `dnd3.get_active_ruleset() → id | nil`

Returns the ID of the currently active ruleset for this session.

### `dnd3.set_active_ruleset(id)`

Sets the active ruleset.  Triggers compute hooks for all existing characters.

### `dnd3.set_session_name(name)`

Sets a human-readable name for the current session.

### `dnd3.export_state() → string`

Serialises the entire session state (tokens, sheets, initiative, fog) to a JSON string.

### `dnd3.save_session_snapshot(name)`

Saves the current state as a named snapshot in mod_storage.

### `dnd3.list_session_snapshots() → { name, ... }`

Returns a list of saved snapshot names.

### `dnd3.apply_effect(target, effect)`

Applies a generic effect table to a target token.  `effect` fields are ruleset-defined.

---

## Core — UI Panel

### `dnd3.open_panel(player_name)`

Opens the dnd3 HUD panel for the player.

### `dnd3.set_grid_overlay(player_name, enabled)`

Alias for `dnd3.grid_overlay_set`.

### `dnd3.toggle_grid_overlay(player_name)`

Alias for `dnd3.grid_overlay_toggle`.

---

## Core — Diorama Studio

### `dnd3.open_diorama_studio(player_name) -> bool, err?`

Opens Diorama Studio for the player.

Notes:

- Requires map editing permissions (GM role).
- Also available via chat commands: `/studio` and `/dnd3_studio`.

### `dnd3.close_diorama_studio(player_name) -> bool`

Closes Diorama Studio session state for the player.

### `dnd3.register_prefab(id, def) -> def | nil, err`

Registers a Studio prefab in the Studio prefab registry.

Common fields in `def`:

- `id` (string)
- `size` (table)
- `nodes` (table)
- `mesh` (string)
- `textures` (string)

### `dnd3.get_registered_prefab(id) -> def | nil`

Returns a Studio-registered prefab definition.

### `dnd3.list_registered_prefabs() -> { id, ... }`

Returns sorted list of Studio-registered prefab IDs.

---

## Core — Time of Day

### `dnd3.tod.get() → number`

Returns the current time as a fraction `0.0–1.0` (0 = midnight, 0.5 = noon).

### `dnd3.tod.set(t)`

Sets the time of day.

### `dnd3.tod.freeze(frozen)`

Freezes or unfreezes the time cycle.

### `dnd3.tod.is_frozen() → boolean`

### `dnd3.tod.set_speed(speed)`

Sets the time multiplier (1.0 = real-time dnd3 default).

### `dnd3.tod.get_speed() → number`

### `dnd3.tod.register_tick_hook(fn)`

Registers a function called each time-of-day tick.  `fn(t)` receives the current time.

### `dnd3.tod.to_hhmm(t) → string`

Converts a `0.0–1.0` time value to a `"HH:MM"` string.

### `dnd3.tod.period(t) → string`

Returns the named period: `"night"`, `"dawn"`, `"morning"`, `"noon"`, `"afternoon"`, `"dusk"`.

---

## Core — Weather

### `dnd3.weather.register_type(def)`

Registers a custom weather type.

| Field       | Type   | Description                          |
|-------------|--------|--------------------------------------|
| `id`        | string | Unique identifier                    |
| `label`     | string | Display name                         |
| `particles` | table  | Particle spawner definition          |
| `skybox`    | table  | Optional sky override                |

### `dnd3.weather.get_type(id) → def | nil`

### `dnd3.weather.list_types() → { id, ... }`

### `dnd3.weather.set_global(id)`

Sets weather for all players not overridden individually.

### `dnd3.weather.get_global() → id | nil`

### `dnd3.weather.set_player(player_name, id)`

Overrides weather for a single player.

### `dnd3.weather.get_player(player_name) → id | nil`

### `dnd3.weather.region_paint(wid, pos1, pos2)`

Paints a weather region.  Players entering the region receive weather `wid`.

### `dnd3.weather.region_clear(pos1, pos2)`

Removes weather region data from an area.

### `dnd3.weather.at_pos(pos) → id | nil`

Returns the weather type at a world position.

### `dnd3.weather.status() → table`

Returns a debug table of all active weather state.

---

## Core — Audio

### `dnd3.audio.stream(def) → id`

Starts an audio stream.

| Field      | Type    | Description                               |
|------------|---------|-------------------------------------------|
| `file`     | string  | Sound file path                           |
| `loop`     | boolean | Loop indefinitely                         |
| `gain`     | number  | Volume, `0.0–1.0`                         |
| `player`   | string  | Target player (nil = all)                 |

Returns a stream `id` used by subsequent calls.

### `dnd3.audio.stream_stop(id)`

Stops and removes a stream.

### `dnd3.audio.stream_fade_out(id, seconds)`

Fades a stream to silence over `seconds` seconds, then removes it.

### `dnd3.audio.stream_stop_all()`

Stops all active streams.

### `dnd3.audio.stream_list() → { id, ... }`

### `dnd3.audio.stream_get(id) → def | nil`

### `dnd3.audio.emitter_add(id, def)`

Registers a positional audio emitter.

| Field   | Type   | Description                  |
|---------|--------|------------------------------|
| `pos`   | table  | `{x, y, z}` world position  |
| `file`  | string | Sound file path              |
| `gain`  | number | Volume                       |
| `range` | number | Audible radius in nodes      |

### `dnd3.audio.emitter_remove(id)`

### `dnd3.audio.emitter_list() → { id, ... }`

### `dnd3.audio.emitter_get(id) → def | nil`

### `dnd3.audio.emitters_restart()`

Restarts all positional emitters (e.g. after a server reload).

---

## dnd35 — Abilities

These functions live under the `dnd3.dnd35` namespace.

### `dnd3.dnd35.ability_mod(score) → number`

Returns the D&D 3.5e ability modifier for an ability score.

```lua
dnd3.dnd35.ability_mod(14)  -- → 2
dnd3.dnd35.ability_mod(8)   -- → -1
```

Formula: `math.floor((score - 10) / 2)`

### `dnd3.dnd35.bonus_spells(score, spell_level) → number`

Returns the number of bonus spells per day for a caster stat of `score` at `spell_level`.  Returns `0` for ability scores below 10 or for cantrips (`spell_level == 0`).

---

## dnd35 — Skills

### `dnd3.dnd35.max_class_skill_rank(level) → number`

Returns the maximum rank in a class skill at character `level`.  Formula: `level + 3`.

### `dnd3.dnd35.max_cross_class_rank(level) → number`

Returns the maximum rank in a cross-class skill.  Formula: `math.floor((level + 3) / 2)`.

### `dnd3.dnd35.can_use_skill(sheet, skill_id) → boolean`

Returns `true` if the character may attempt the skill untrained, or has at least 1 rank.

### `dnd3.dnd35.synergy_bonus(sheet, target_skill_id) → number`

Returns the total synergy bonus to `target_skill_id` from other skills at 5+ ranks.

### `dnd3.dnd35.skill_check(sheet, skill_id, roll, situation_mod) → total`

Computes a skill check total.

| Param          | Type   | Description                                    |
|----------------|--------|------------------------------------------------|
| `sheet`        | table  | Character sheet                                |
| `skill_id`     | string | Skill identifier, e.g. `"hide"`               |
| `roll`         | number | d20 result                                     |
| `situation_mod`| number | Circumstance/situational modifier (may be 0)  |

Returns the final integer check total.

### `dnd35.SKILL_SYNERGIES`

Table of synergy rules: `dnd35.SKILL_SYNERGIES[source_skill] = { {target, min_ranks}, ... }`.

---

## dnd35 — Conditions

### `dnd35.CONDITIONS`

Table of all 37 SRD conditions keyed by ID.

```lua
-- dnd35.CONDITIONS["blinded"] = {
--   id       string
--   label    string
--   summary  string
--   effects  table   -- penalty tables applied by the compute hook
-- }
```

### `dnd35.has_condition(token_id, condition_id) → boolean`

Returns `true` if the token currently has the condition.  Delegates to `dnd3.character.has_condition`.

### `dnd35.apply_condition(token_id, condition_id)`

Adds the condition and triggers a recompute.  Delegates to `dnd3.character.apply_condition`.

### `dnd35.remove_condition(token_id, condition_id)`

Removes the condition and triggers a recompute.  Delegates to `dnd3.character.remove_condition`.

### `dnd35.get_conditions(token_id) → { condition_id, ... }`

Returns a copy of the token's current conditions array.

---

## dnd35 — Classes

### `dnd35.CLASSES`

Table of all SRD base classes keyed by ID (`"barbarian"`, `"bard"`, `"cleric"`, `"druid"`, `"fighter"`, `"monk"`, `"paladin"`, `"ranger"`, `"rogue"`, `"sorcerer"`, `"wizard"`).

```lua
-- dnd35.CLASSES["fighter"] = {
--   id           string
--   label        string
--   hit_die      number   -- e.g. 10
--   bab          string   -- "full" | "three_quarter" | "half"
--   fort         string   -- "good" | "poor"
--   ref          string   -- "good" | "poor"
--   will         string   -- "good" | "poor"
--   skills_per_level  number
--   class_skills table   -- set of skill IDs
-- }
```

### `dnd35.bab(progression, level) → number`

Returns the base attack bonus.

| `progression` | Formula               |
|---------------|-----------------------|
| `"full"`      | `level`               |
| `"three_quarter"` | `math.floor(level * 3 / 4)` |
| `"half"`      | `math.floor(level / 2)` |

### `dnd35.base_save(progression, level) → number`

Returns the base save bonus.

| `progression` | Formula                        |
|---------------|--------------------------------|
| `"good"`      | `2 + math.floor(level / 2)`   |
| `"poor"`      | `math.floor(level / 3)`       |

### `dnd35.is_class_skill(class_id, skill_id) → boolean`

Returns `true` if `skill_id` is a class skill for `class_id`.

### `dnd35.total_bab(class_levels) → number`

Returns the total BAB across multiple classes.

```lua
-- class_levels = { fighter = 5, wizard = 3 }
dnd35.total_bab({ fighter = 5, wizard = 3 })  -- → 5 + 1 = 6
```

### `dnd35.total_saves(class_levels) → { fort, ref, will }`

Returns the combined base saves for a multiclass character.

### `dnd35.total_level(class_levels) → number`

Returns the sum of all class levels (character level).

---

## dnd35 — Feats

### `dnd35.FEATS`

Table of all 110 SRD feats keyed by ID.

```lua
-- dnd35.FEATS["power_attack"] = {
--   id         string
--   label      string
--   type       string   -- "general" | "fighter" | "item_creation" | "metamagic" | "special"
--   prereqs    table    -- { str = 13, ... } or {}
--   benefit    string   -- rules text
--   repeatable boolean
--   stacks     boolean
--   slot_cost  number   -- feat slots consumed (usually 1)
-- }
```

### `dnd35.list_feats() → { feat, ... }`

Returns a list of all feat definition tables, sorted by `id`.

### `dnd35.feats_by_type(feat_type) → { feat, ... }`

Returns all feats of the given type, sorted by `id`.

```lua
dnd35.feats_by_type("fighter")      -- all fighter bonus feats
dnd35.feats_by_type("metamagic")    -- Empower Spell, Quicken Spell, etc.
dnd35.feats_by_type("item_creation")
```

---

## dnd35 — Spells

### `dnd35.SPELLS`

Table of all SRD spells keyed by ID.

```lua
-- dnd35.SPELLS["fireball"] = {
--   id      string
--   label   string
--   school  string   -- "abjuration" | "conjuration" | "divination" |
--                    --  "enchantment" | "evocation" | "illusion" |
--                    --  "necromancy" | "transmutation" | "universal"
--   level   table    -- { bard=N, cleric=N, druid=N, paladin=N,
--                    --   ranger=N, sor=N, wiz=N, <domain>=N, ... }
--   summary string
-- }
```

Domain keys follow the SRD domain names in lowercase: `air`, `animal`, `chaos`, `death`, `destruction`, `earth`, `evil`, `fire`, `good`, `healing`, `knowledge`, `law`, `luck`, `magic`, `plant`, `protection`, `strength`, `sun`, `travel`, `trickery`, `war`, `water`.

### `dnd35.list_spells() → { spell, ... }`

Returns a list of all spell definition tables, sorted by `id`.

### `dnd35.spells_by_class(class_id, level) → { spell, ... }`

Returns all spells available to `class_id`, sorted by `id`.  If `level` is provided, only spells of that exact spell level are returned.

```lua
dnd35.spells_by_class("wizard")       -- all wizard spells
dnd35.spells_by_class("cleric", 3)    -- cleric 3rd-level spells only
dnd35.spells_by_class("fire", 2)      -- Fire domain 2nd-level spell
```

### `dnd35.spells_by_school(school) → { spell, ... }`

Returns all spells of the given school, sorted by `id`.

```lua
dnd35.spells_by_school("evocation")
dnd35.spells_by_school("necromancy")
```

---

## Phase 3 — Combat System

### `dnd3.combat` — Turn & Action Economy

Ruleset-agnostic tracking of combat rounds and per-turn action budgets.

| Symbol | Type | Description |
|--------|------|-------------|
| `dnd3._state.combat.active` | boolean | True while combat is running |
| `dnd3._state.combat.round`  | number  | Current round number |
| `dnd3._state.combat.turns`  | table   | `turns[token_id].budget` action table |
| `dnd3._state.combat.aoo_limits` | table | `aoo_limits[token_id]` = max AoOs per round |

#### `dnd3.combat.start()`

Begin a new combat encounter.  Resets round to 1, clears all turn and AoO data.

#### `dnd3.combat.end_combat()`

End the current encounter.  Clears all combat state.

#### `dnd3.combat.turn_start(token_id)`

Reset the action budget for `token_id` at the start of their turn:

```
{ standard=1, move=1, swift=1, free=3, full_round=1, aoo=<aoo_limit> }
```

#### `dnd3.combat.use_action(token_id, action_type) → ok, err`

Consume one action of `action_type` (`"standard"`, `"move"`, `"swift"`, `"free"`, `"full_round"`).

- `"full_round"` requires both a standard and a move action to be available; consumes both.
- Returns `true` on success, `false, message` on failure.

#### `dnd3.combat.actions_remaining(token_id) → table`

Returns a copy of the current budget table for the token.

#### `dnd3.combat.use_aoo(token_id) → ok, err`

Consume one attack of opportunity.  Returns `false, message` if none remain.

#### `dnd3.combat.aoo_remaining(token_id) → number`

Returns the remaining AoO count for this turn.

#### `dnd3.combat.set_aoo_limit(token_id, n)`

Override the AoO limit for a token (e.g. Combat Reflexes feat: `1 + dex_mod`).

#### `dnd3.combat.next_round() → number`

Advance to the next round.  Returns the new round number.

**Chat commands** (DM only): `dnd3_combat_start`, `dnd3_combat_end`, `dnd3_next_round`.

---

### `dnd35.WEAPONS` — SRD Weapon Definitions

All weapons from SRD Table 7-5 (Player's Handbook chapter 7).

```lua
-- dnd35.WEAPONS["longsword"] = {
--   id           string   -- unique key
--   label        string   -- display name
--   category     string   -- "simple" | "martial" | "exotic"
--   wtype        string   -- "melee" | "ranged" | "thrown"
--   hands        string   -- "light" | "one_hand" | "two_hand"
--   damage_s     string   -- damage dice for Small wielder (e.g. "1d6")
--   damage_m     string   -- damage dice for Medium wielder (e.g. "1d8")
--   crit_range   number   -- minimum d20 to threaten crit (20 = 20 only, 19 = 19-20)
--   crit_mult    number   -- crit damage multiplier (×2, ×3, ×4)
--   range_inc    number   -- range increment in feet; nil for non-ranged
--   damage_type  string   -- "B"|"P"|"S"|"BP"|"BS"|"PS"|"BPS"
--   special      table    -- array: "reach","brace","trip","disarm",
--                         --       "double","nonlethal","monk","finesse","entangle"
--   double_secondary table  -- for double weapons only: second-end stats
-- }
```

#### `dnd35.weapons_by_category(category) → { weapon, ... }`

Returns all weapons of `"simple"`, `"martial"`, or `"exotic"`, sorted by `id`.

#### `dnd35.weapon_damage_for_size(weapon_id, size) → dice_string`

Returns `damage_s` for Small-or-smaller, `damage_m` for Medium-or-larger.

---

### `dnd35` — Combat System (systems/combat.lua)

#### Derived sheet fields (written by compute hook priority 20)

| Field | Formula |
|-------|---------|
| `melee_attack_bonus` | BAB + STR mod + size modifier + attack_misc |
| `ranged_attack_bonus` | BAB + DEX mod + size modifier + attack_misc |
| `melee_damage_bonus` | STR mod + damage_misc |
| `two_handed_damage_bonus` | ⌊STR mod × 1.5⌋ + damage_misc |
| `offhand_damage_bonus` | ⌊STR mod × 0.5⌋ + damage_misc (negative STR applied in full) |
| `hp_status` | `"alive"`, `"disabled"`, `"dying"`, `"stable"`, or `"dead"` |

#### Raw sheet fields registered by combat.lua

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `hp_current` | number | 0 | Current hit points |
| `hp_nonlethal` | number | 0 | Accumulated nonlethal damage |
| `hp_stable` | boolean | false | Dying character has been stabilised |
| `attack_misc` | number | 0 | Miscellaneous attack bonus |
| `damage_misc` | number | 0 | Miscellaneous damage bonus |
| `equipped_weapon` | string | `"unarmed_strike"` | Primary weapon ID |
| `equipped_offhand` | string | `""` | Off-hand weapon ID |
| `size` | string | `"medium"` | Creature size category (for weapon damage table lookup) |
| `feats` | table | `{}` | Array of feat IDs (used for TWF penalty calculation) |

#### `dnd35.hp_status(sheet) → string`

Returns the HP status based on `sheet.hp_current`, `sheet.hp_stable`, and `sheet.con`.

| Status | Condition |
|--------|-----------|
| `"dead"` | hp ≤ –10 or hp ≤ –CON (whichever is lower) |
| `"dying"` | hp < 0 and `hp_stable == false` |
| `"stable"` | hp < 0 and `hp_stable == true` |
| `"disabled"` | hp == 0 |
| `"alive"` | hp > 0 |

#### `dnd35.attack(attacker_id, target_id, opts) → result`

Resolve a single attack roll.

**opts:**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `weapon_id` | string | `equipped_weapon` | Weapon to attack with |
| `attack_bonus_misc` | number | 0 | Situational bonus (flanking, etc.) |
| `damage_bonus_misc` | number | 0 | Situational damage bonus |
| `is_touch` | boolean | false | Use `ac_touch` |
| `is_flat_footed` | boolean | false | Use `ac_flat_footed` |
| `is_two_handed` | boolean | per weapon | Override grip for damage bonus |
| `is_offhand` | boolean | false | Use off-hand damage bonus |
| `iterative_penalty` | number | 0 | Cumulative iterative penalty (0, –5, –10, –15) |
| `sneak_attack_dice` | number | 0 | Extra d6 sneak attack dice |

**result:**

| Key | Type | Description |
|-----|------|-------------|
| `hit` | boolean | Whether the attack connected |
| `roll` | number | Raw d20 result |
| `total_attack` | number | d20 + all attack bonuses |
| `ac_used` | number | Target AC used |
| `crit_threat` | boolean | True if d20 ≥ weapon crit range |
| `crit_confirmed` | boolean | True if threat was confirmed |
| `damage` | number | Total damage dealt (0 if miss) |
| `damage_roll` | string | Dice expression used |
| `damage_type` | string | Weapon damage type |
| `sneak_damage` | number | Sneak attack portion |
| `sneak_roll` | string | Sneak dice expression |
| `outcome` | string | `"HIT"`, `"MISS"`, `"CRITICAL HIT"`, `"MISS (natural 1)"` |
| `log` | table | Human-readable string array |

**Rules applied:** natural 1 always misses; natural 20 always hits; critical dice are multiplied and bonuses added once.

#### `dnd35.full_attack(attacker_id, target_id, opts) → { result, ... }`

Resolve a complete full-attack action.

Additional opts beyond those for `attack()`:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `offhand_id` | string | `equipped_offhand` | Off-hand weapon for TWF |
| `is_twf` | boolean | auto | Force TWF mode |

Iterative attacks are generated automatically from BAB (BAB 6 → –5 penalty, BAB 11 → –10, BAB 16 → –15).  TWF penalties follow SRD Table 8-7; the feat `"two_weapon_fighting"` in the `feats` array reduces penalties.

Each result has an added `hand` key (`"primary"` or `"offhand"`) and `attack_number`.

#### `dnd35.apply_damage(token_id, amount, dmg_type, nonlethal) → new_hp`

Apply `amount` damage to a token.  If `nonlethal` is true, adds to `hp_nonlethal`; otherwise subtracts from `hp_current` and clears `hp_stable`.  Calls `dnd3.character.compute()` after.  Returns the new `hp_current`.

#### `dnd35.heal(token_id, amount) → new_hp`

Restore hit points (capped at `hp_max`).  Returns new `hp_current`.

#### `dnd35.heal_nonlethal(token_id, amount) → new_hp_nonlethal`

Reduce accumulated nonlethal damage.  Returns new `hp_nonlethal`.

#### `dnd35.stabilize(token_id) → ok, err`

Mark a dying character as stable.  Returns `false, message` if the character is not currently dying.

---

## Phase 3.2 — Spellcasting System

### `dnd35.spell` — Slot Tracking, Casting, and Concentration

Spellcasting is slot-driven and class-aware.

`spell_slots_base` is the authoritative per-class base slots/day table (normally set by UI/GM tooling).
The system computes:

- `spell_slots_bonus` from the class key ability (`INT`, `WIS`, `CHA`) using `dnd3.dnd35.bonus_spells`
- `spell_slots_total = base + bonus`
- `concentration_total = skill_concentration_total + concentration_misc`

#### Spellcasting fields (sheet)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `spell_slots_base` | table | `{}` | Base slots/day by class and spell level |
| `spell_slots_bonus` | table | `{}` | Computed bonus slots/day |
| `spell_slots_total` | table | `{}` | Computed total slots/day |
| `spell_slots_used` | table | `{}` | Spent slots by class and spell level |
| `prepared_spells` | table | `{}` | Reserved for prepared spell tracking |
| `concentration_misc` | number | `0` | Misc bonus to concentration |
| `concentration_total` | number | `0` | Computed concentration check bonus |

Expected nested table shape:

```lua
sheet.spell_slots_base = {
    cleric = { [0]=5, [1]=4, [2]=3, [3]=2 },
    wizard = { [0]=4, [1]=3, [2]=2 },
}
```

#### `dnd35.spell.get_slots(token_id, class_id) → slot_state`

Returns:

```lua
{
    base = {...},
    bonus = {...},
    total = {...},
    used = {...},
    remaining = {...},
    class_level = number,
    spell_ability = "int"|"wis"|"cha"
}
```

#### `dnd35.spell.set_base_slots(token_id, class_id, slots_by_level) → ok, err`

Sets base slots/day for one caster class and recomputes derived slot tables.

#### `dnd35.spell.reset_slots(token_id, class_id?) → ok, err`

Resets spent slots for one class or all classes (if `class_id` omitted).

#### `dnd35.spell.consume_slot(token_id, class_id, spell_level, count?) → ok, err`

Consumes slot(s) after checking remaining availability.

#### `dnd35.spell.can_cast(token_id, spell_id, class_id, opts?) → ok, err, ctx`

Validates class access and slot availability for a spell.

`opts`:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `ignore_slots` | boolean | `false` | If true, only validates class/list access |

Returns `ctx = { spell_id, class_id, spell_level }` on success.

#### `dnd35.spell.cast(token_id, spell_id, class_id, opts?) → result | false, err`

Performs cast validation and consumes one slot unless `ignore_slots=true`.

Result:

```lua
{ ok = true, spell_id = "...", class_id = "...", spell_level = N }
```

#### `dnd35.spell.concentration_dc_from_damage(damage_dealt, spell_level) → dc`

Returns standard concentration DC for damage disruption:

$$DC = 10 + \text{damage dealt} + \text{spell level}$$

#### `dnd35.spell.concentration_check(token_id, dc, opts?) → check_result`

Rolls concentration check (`1d20 + concentration_total + misc`) and returns:

```lua
{ dc, roll, bonus, total, success }
```

#### `dnd35.spell.concentration_check_from_damage(token_id, damage_dealt, spell_level, opts?) → check_result`

Convenience helper: computes DC from damage/level and performs the concentration check.

---

*All SRD content (dnd35 ruleset) is Open Game Content licensed under the Open Game License v1.0a.  See `COPYING.LESSER` and the OGL notice in `rulesets/dnd35/init.lua` for details.*
