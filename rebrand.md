# dnd3 Rebrand & Architecture Outline

## 1. Project Renaming & Rebranding

### 1.1 Identity and Versioning
- Rebrand entire project from **dnd3 / dnd3** to **dnd3**.
- Keep license unchanged: **LGPL-2.1**.
- Set baseline version to **0.1.0-dnd3**.
- Set default game to **games/dnd3/**.
- Set default ruleset to **rulesets/dnd35/**.

### 1.2 Canonical Naming Map
- Engine name: **dnd3**
- Core runtime module: **dnd3_core**
- Default ruleset: **dnd35**
- Public API namespace: **dnd3.***
- Primary binaries: **dnd3**, **dnd3server**
- Config baseline: **dnd3.conf.example** (with migration support for legacy names)

### 1.3 Rename Coverage (Repository-Wide)
- File and folder names
- CMake project and install targets
- Config files and defaults
- Docs and manuals
- UI strings and localization keys
- Packaging metadata (desktop/mobile/manifests)
- Binary output names
- In-code symbols, constants, protocol labels
- Branding assets (icons/logo/splash)

### 1.4 Compatibility and Migration
- Add transition aliases for old config keys and legacy paths.
- Add startup migration step for:
  - Legacy world/session identifiers
  - Legacy game ID mapping to `dnd3`
- Emit one-time migration logs.
- Define network/protocol policy clearly:
  - either maintain protocol compatibility for first forked release,
  - or bump protocol and provide explicit migration guidance.

### 1.5 Rebrand Aesthetic Direction
- Visual style: **dark fantasy + crisp retro 3D pixel art**.
- Logo concept: **glowing low-res d20 above a voxel grid**.
- UI direction: high contrast, readable fantasy styling with pixel accents.
- Asset deliverables:
  - App icon set
  - Splash/loading art
  - Main menu art/theme
  - Pixel UI icon atlas

### 1.6 Execution Sequence
1. Branding and metadata pass
2. Build/package identity pass
3. Source symbol pass
4. Content layout pass (core/ruleset split)
5. Migration/compatibility pass
6. Build and runtime verification pass

---

## 2. Core Vision: Modular 3D Pixel-Art Voxel VTT

- Build an immersive voxel VTT inspired by FoundryVTT + Tabletop Simulator + retro 3D pixel games.
- Keep the engine core fully ruleset-agnostic.
- Implement D&D 3.5e as default ruleset module, not hardcoded engine behavior.
- Allow plug-in rulesets (Pathfinder, 5e, OSR, custom systems, non-fantasy RPGs).
- Keep reusable shared VTT systems in core: map tools, tokens, dice, fog, initiative, persistence, multiplayer.

---

## 3. Full Proposed Directory Structure (Modularity First)

```text
CMakeLists.txt
CMakePresets.json
LICENSE.txt
COPYING.LESSER
README.md

src/
  engine/
    render/
      pixel_pipeline/
      shaders/
      camera/
    net/
    world/
    entity/
    io/
    platform/
  vtt_core_bridge/
  ruleset_runtime/

mods/
  dnd3_core/
    init.lua
    api/
      register_ruleset.lua
      register_sheet_field.lua
      roll.lua
      apply_effect.lua
    systems/
      grid/
      tokens/
      initiative/
      fog_of_war/
      los/
      dice/
      prefabs/
      permissions/
      session/
    ui/
      panels/
      widgets/
    net/
    data_schemas/
    doc/

rulesets/
  _template/
    ruleset.json
    init.lua
    data/
    sheets/
    formulas/
    hooks/
    doc/
  dnd35/
    ruleset.json
    init.lua
    data/
      classes.json
      races.json
      skills.json
      feats.json
      spells.json
      items.json
      conditions.json
      monsters.json
    sheets/
      character.lua
      npc.lua
      monster.lua
    formulas/
      attacks.lua
      saves.lua
      skills.lua
      encumbrance.lua
    combat/
      automation.lua
    hooks/
      events.lua
    doc/

games/
  dnd3/
    game.conf
    mods/
    worldgen/
    assets/
    doc/

content/
  ruleset_packs/
  prefab_packs/
  texture_packs/
  audio_packs/

assets/
shaders/
textures/

docs/
  architecture/
    core_vs_ruleset.md
    api_surface.md
  rulesets/
    template_guide.md
    dnd35_data_model.md
  rendering/
    pixel_pipeline.md
  modding/
    registering_rulesets.md
  migration/
    minetest_to_dnd3.md

sessions/
  <session_id>/
    session.json
    map/
    entities/
    fog/
    initiative/
    chat/
    ruleset_state/

worlds/

android/
client/
server/
builtin/
tools/
tests/
third_party/
```

### 3.1 Separation Rules (Hard Requirements)
- `mods/dnd3_core/`: shared VTT systems only, no D&D-specific mechanics.
- `rulesets/<system>/`: all system-specific data and logic.
- `games/dnd3/`: default packaged experience and bootstrap configuration.

### 3.2 API Surface (Core to Rulesets)
- `dnd3.register_ruleset()`
- `dnd3.register_sheet_field()`
- `dnd3.roll()`
- `dnd3.apply_effect()`

### 3.3 Tech Rules
- Prefer Lua for gameplay logic.
- Extend C++ for rendering/performance/core systems.
- Store sheet/inventory/map/session data in ruleset-compatible formats.

---

## 4. Technical Plan: Crisp 3D Pixel-Art Rendering Pipeline

### 4.1 Rendering Objectives
- Crisp voxels at all practical zoom ranges.
- No texture blur; preserve pixel edges.
- Retro visual identity with configurable quality/performance.
- Stable visuals suitable for tactical VTT readability.

### 4.2 Pipeline Stages
1. Geometry pass (world, entities, tokens)
2. Stylized lighting pass (cel quantization)
3. Edge/outline pass
4. Palette/post pass
5. Final nearest-neighbor upscale pass

Profiles:
- Pixel Retro
- Pixel Retro Plus
- Clean HD Pixel

### 4.3 Pixel Density and Internal Resolution
- Render scene to low-resolution offscreen target (configurable scale such as 0.5/0.67/1.0).
- Upscale to display resolution using **nearest-neighbor only**.
- Add optional camera/object pixel snapping to reduce shimmer.
- Allow per-camera strict retro vs smoother cinematic behavior.

### 4.4 Texture and Sampling Policy
- Enforce nearest-neighbor filtering globally.
- Disable trilinear blur.
- Use nearest mip selection (or sharpened mips where needed).
- Use atlas padding and UV snapping to prevent bleeding.
- Validate imports to reject disallowed filter modes in strict profiles.

### 4.5 Voxel Detail Strategy
- Keep gameplay voxel units stable while increasing visual texel density.
- Support high-detail voxel material atlases.
- Optional face overlays (cracks/runes/height cues) while preserving hard silhouettes.

### 4.6 Stylized Lighting and Shadows
- Cel-shaded directional/local lights with discrete bands.
- Hard-shadow profile with configurable bias and crisp edge controls.
- Optional dither transitions between light bands.
- Per-material style modes (stylized, flat, hybrid).

### 4.7 Outlines and Readability
- Combine normal-based + depth-based edge detection.
- Configurable outline thickness in internal pixel space.
- Selection/team outlines for token readability.
- Separate GM-only mask outlines for hidden information control.

### 4.8 Palette and Grading
- Optional palette quantization post-process.
- LUT profiles (Dungeon, Overworld, Underdark, etc.).
- Exclude UI from destructive palette reduction unless explicitly enabled.

### 4.9 Camera Modes
- Top-down orthographic (tactical precision)
- Isometric (tactical-cinematic)
- First-person and third-person (immersive roleplay)
- Per-camera-mode rendering overrides (shadow distance, outline width, pixel scale)

### 4.10 VTT Overlay Integration
- Pixel-locked world-space grid overlay (5-ft squares default).
- Fog-of-war masks with sharp thresholded edges and optional soft profile.
- LOS stencil controls for per-player visibility.
- Overlay layers for initiative/target markers and elevation indicators.

### 4.11 Performance Plan
- Chunk culling and stylized LOD strategy.
- Instancing for repeated assets.
- Dynamic resolution fallback with nearest-neighbor upscale preserved.
- Independent quality knobs:
  - internal render scale
  - shadow resolution
  - outline quality
  - light count

### 4.12 Rendering/Gameplay Settings
- `render.pixel_scale`
- `render.upscale_filter=nearest`
- `render.palette_profile`
- `render.cel_shading_enabled`
- `render.outline_enabled`
- `render.shadow_style=hard`
- `camera.mode=topdown_ortho` (default)
- `vtt.grid.square_size_ft=5`
- `ruleset.default=dnd35`
- `game.default=dnd3`

### 4.13 Rendering Milestones
1. R1: low-res internal render + nearest upscale + global nearest filter enforcement
2. R2: cel lighting + hard shadows + outlines
3. R3: palette quantization + LUT profiles + camera mode profile overrides
4. R4: grid/fog/LOS visual integration polish
5. R5: optimization and presets for desktop + Android

---

## 5. Feature Roadmap (Priority Order)

### Phase 1: Core VTT Engine (Rules-Agnostic)
- Multiplayer with GM/player permissions
- Advanced voxel map editor with 5-ft grid
- Dynamic lighting + LOS + GM fog controls
- Flexible token/entity manipulation
- Modular initiative tracker
- 3D tumbling dice + rich dice expression parser
- Prefab/stamp library
- Persistent world/session saving

### Phase 2: Ruleset System (Default dnd35)
- Data-driven ruleset loader (JSON + Lua)
- D&D 3.5e SRD integration in `rulesets/dnd35/`
- Character sheets with auto-calculation
- Inventory + encumbrance
- Spellbook + FX hooks
- Bestiary + NPC tools
- Combat automation (attacks, damage, saves, criticals)

### Phase 3: GM Tools and Polish
- Monster spawner, loot tables, random encounters, time/weather controls
- Sound/music/particle layers
- Chat with `/roll`, whispers, emotes
- Modding API expansion and docs
- One-click "New Session" with ruleset selection

### Phase 4: Extensibility and Ecosystem
- Publish rulesets/prefabs/textures/systems via ContentDB
- Official ruleset template and guides
- External data import interfaces (community integrations)

---

## 6. Guardrails for Implementation

- Keep `dnd3_core` fully ruleset-agnostic at all times.
- Keep project compiling and runnable after each major module change.
- Add strong developer docs alongside each new subsystem.
- Keep `lua-api.md` updated in every PR that adds or changes dnd3 Lua APIs or chat commands.
- Favor additive compatibility during early rebrand and migration.
- Treat rendering changes as configurable profiles, not hardcoded single-mode behavior.
