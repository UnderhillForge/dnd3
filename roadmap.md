1. Ready-to-Paste Prompt for Your Coding Agent
Markdown**SYSTEM PROMPT / TASK**

We are adopting a **Hybrid Architecture** for dnd3: keep the strong voxel foundation for editing, grid, and GM tools, while upgrading visuals and movement to achieve crisp 3D pixel art with smooth Zelda: A Link to the Past style terrain.

**Follow this exact Hybrid Architecture:**
dnd3 Hybrid Architecture – “Voxel Soul + Pixel Art Body”
Version: 1.0
Goal: Combine the strengths of a voxel engine (easy GM editing, tactical grid, fast prototyping, multiplayer sync) with the visual beauty and fluidity of a 3D pixel art engine (Zelda: A Link to the Past aesthetic, smooth movement, fine detail, no chunky Minecraft look).
We are not abandoning the current engine — we are surgically upgrading it.
1. Core Philosophy

Keep everything that makes a good VTT possible (grid, editing, persistence, Lua ecosystem).
Replace / Enhance the visual and movement layers to achieve crisp 3D pixel art.
Backwards compatibility with upstream Luanti is not required.

2. High-Level Architecture
textdnd3 Engine
├── World Storage (Keep)          → Chunk-based voxel data (1 node = 5 ft tactical grid)
├── Networking & Multiplayer (Keep)
├── Lua Modding Layer (Keep)      → dnd3_core + rulesets
├── Ruleset System (Keep)
│
├── Rendering Pipeline (NEW/MAJOR UPGRADE)
│   └── Pixel-Perfect 3D Renderer + Cel Shading + Outlines
│
├── Terrain System (Hybrid)
│   ├── Voxel Core (for editing & structure)
│   └── Mesh / Nodebox Layer (for visuals & smooth movement)
│
├── Physics & Movement (UPGRADED)
│   └── Navmesh + Slope Walking
│
└── Camera System (Flexible)
    └── Isometric / Top-Down / 3rd Person (Zelda-style supported)
3. Detailed Component Breakdown
A. World Storage (Unchanged Core)

Remains voxel-based (1×1×1 nodes).
Each node still represents a clean 5-ft tactical square.
GM map editor stays powerful and familiar.

B. Hybrid Terrain System (The Key Innovation)
Each map chunk will have two representations:

LayerPurposeTechnologyVisual / Movement BenefitVoxel LayerEditing, saving, fog of war, gridStandard Luanti nodesFast GM tools, tactical precisionVisual LayerWhat the player actually seesMesh / Nodebox / Baked meshesSmooth slopes, fine pixel detail, Zelda-like beautyCollision LayerMovement & physicsNavmesh + custom slopesWalk up hills naturally, no constant jumping
How it works in practice:

GM builds with normal voxels (fast).
At runtime (or on demand), the engine generates a visual mesh from the voxel data + slope rules.
Smooth slopes, rounded corners, detailed surfaces become possible.

C. New Rendering Pipeline (Major Upgrade)

Internal render resolution: Low (e.g. 960×540 or configurable) → nearest-neighbor upscale to screen.
Shaders: Cel shading, hard outlines, limited palette support, pixel snapping.
Textures: Default to 128×128 or 256×256 crisp pixel art.
Visual voxel scale: Nodes can be rendered at 0.4–0.75 size for finer appearance while keeping tactical grid at 1.0.

D. Movement & Physics

Character controller upgraded to support slope walking.
Use a lightweight navmesh on top of the voxel data for smooth pathing.
Avatars can walk up gentle hills naturally.

E. Camera Modes (All Supported)

Isometric / Zelda-style (primary recommended)
Top-down orthographic (classic VTT)
Third-person (immersive)

4. New Directory Structure Additions
textmods/dnd3_core/
  systems/
    hybrid_terrain/          # New
      voxel_to_mesh.lua
      slope_generator.lua
      navmesh.lua
    rendering/               # Major expansion
      pixel_pipeline.lua
      shaders/
        cel_shading.frag
        outline.vert
        pixel_snap.lua
    camera/                  # Flexible camera controller
5. Migration / Transition Strategy
Phase 1 (2–3 weeks)

Implement slope system + smooth movement on top of current voxels.

Phase 2 (3–4 weeks)

Build visual mesh generation + new pixel-art rendering pipeline.

Phase 3

Add hybrid terrain tools (voxel paint → mesh beautify).

Phase 4

Polish: 3D paper-doll avatars, dynamic weather, etc.

6. Risks & Mitigations

Risk: Performance drop from mesh generation → Mitigation: Generate meshes only for visible chunks + cache them.
Risk: Losing tactical precision → Mitigation: Always keep the 5-ft voxel grid as the source of truth.
Risk: Complexity → Mitigation: Keep voxel layer as the canonical data.

### Immediate Implementation Goals

1. **Hybrid Terrain System** (`mods/dnd3_core/systems/hybrid_terrain/`)
   - Keep voxel data as source of truth.
   - Generate smooth visual meshes + collision at runtime.
   - Add slope system so characters can walk up gentle hills naturally.

2. **New Pixel-Art Rendering Pipeline**
   - Low internal resolution → strict nearest-neighbor upscale.
   - Cel shading, hard outlines, pixel snapping.
   - Support 128x128+ textures by default.
   - Add `render.voxel_visual_scale` (default 0.5–0.6).

3. **Camera & Movement Upgrades**
   - Support isometric (Zelda-style) camera.
   - Smooth character controller with slope walking.

**Development Rules**
- Keep all existing `dnd3_core` systems (character sheets, dice, initiative, rulesets, etc.) fully working.
- Do **not** break the 5-ft tactical grid.
- Make everything configurable.
- Keep the project compiling and runnable after every major step.

**First Step (Start Here):**
Create the `hybrid_terrain` module with basic slope generation and visual mesh conversion. Then implement the new rendering pipeline settings.

Output:
- Summary of files you will create/modify
- Complete code for new files
- Updated config options (`dnd3.conf.example`)
- Testing instructions

Begin now.

2. Detailed 6–8 Week Hybrid Roadmap
Overall Goal: A beautiful, smooth 3D pixel-art VTT that still feels excellent to run D&D 3.5e games in.
Weeks 1–2: Foundation & Smooth Movement (Functional Core)

WeekFocusKey Deliverables1Hybrid Terrain Core• Slope node library (nodebox + mesh)
• Basic natural slope generator
• Smooth character walking (no more constant jumping)2Pixel Rendering Pipeline v1• Low-res render target + nearest-neighbor upscale
• Global nearest filtering + 128x128 default textures
• render.voxel_visual_scale setting
• First playtest with improved visuals
Milestone: You can walk smoothly around a map that already looks noticeably less chunky.

Weeks 3–4: Visual Polish & Camera

WeekFocusKey Deliverables3Advanced Rendering• Cel shading + hard outlines
• Pixel snapping & anti-shimmer
• Isometric camera mode (Zelda-style)4Hybrid Terrain Tools• Voxel → Mesh conversion system
• GM tools to "beautify" terrain (convert rough voxels to smooth slopes)
• Prefab system updated for hybrid
Milestone: The game looks like real 3D pixel art. GM can still edit easily.

Weeks 5–6: Combat & Rules Integration

WeekFocusKey Deliverables5Character Sheet + Avatars• Full character sheet with 3D paper-doll preview
• Equipped items visible on avatar6Combat Loop• Dice + Initiative + Attack automation
• Conditions & visual effects on tokens
• Fog of war on hybrid terrain
Milestone: You can run a full short combat encounter in a beautiful world.

Weeks 7–8: Immersion & Polish (Stretch / Optional)

WeekFocusKey Deliverables7Audio & Environment• Sound painting + GM music streaming
• Dynamic weather + day/night cycle8Final Polish & Testing• Performance optimization
• GM toolbox expansion
• Short playtest session + documentation
Final Milestone (End of Week 8): A polished, good-looking VTT where you can comfortably run 2–4 hour D&D sessions with friends.

Recommended Daily/Weekly Workflow

60% Functional / Systems work
40% Visual / Hybrid improvements
End every week with a short playtest (even if rough)
