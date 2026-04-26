# dnd3 Game Package

This is the default game package for dnd3.

It currently loads the ruleset-agnostic `dnd3_core` module and provides the
initial Phase 1 VTT scaffolding:

- GM/Player role and permission controls
- Core initiative tracker state
- Dice expression roller API
- Session and active-ruleset state hooks
- Map editor primitives (fill and height shift)
- Token registration, movement, and transforms
- Fog/visibility per-player state controls
- Prefab capture/stamp workflow
- Session snapshot export hooks
- Role-aware in-game control panel
- Tactical grid cell HUD overlay

Ruleset-specific logic should live under `rulesets/<system>/`.

Public API and command documentation for modders is tracked in `lua-api.md` at the repository root and must be updated alongside feature changes.

## Phase 1 Commands (Current)

- `/dnd3_role <player> <gm|player|observer>`
- `/dnd3_roll <expression>`
- `/dnd3_init_add <token> <score>`
- `/dnd3_init_next`
- `/dnd3_ruleset [list|set <id>|current]`
- `/dnd3_map_fill <x1> <y1> <z1> <x2> <y2> <z2> <nodename>`
- `/dnd3_map_raise <x1> <y1> <z1> <x2> <y2> <z2> <delta>`
- `/dnd3_token_add <id> <x> <y> <z> [label]`
- `/dnd3_token_move <id> <x> <y> <z>`
- `/dnd3_token_xform <id> <scale> <rotation> <elevation>`
- `/dnd3_token_list`
- `/dnd3_fog_reveal <player> <x> <y> <z>`
- `/dnd3_fog_hide <player> <x> <y> <z>`
- `/dnd3_fog_clear <player>`
- `/dnd3_prefab_capture <id> <x1> <y1> <z1> <x2> <y2> <z2>`
- `/dnd3_prefab_stamp <id> <x> <y> <z>`
- `/dnd3_prefab_list`
- `/dnd3_session_save <snapshot_name>`
- `/dnd3_session_list`
- `/dnd3_panel`
- `/dnd3_grid [on|off|toggle]`
