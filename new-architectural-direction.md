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


Approval Statement
This hybrid approach gives us:

80–90% of the visual quality we want (crisp 3D pixel art, smooth terrain)
While preserving the best parts of the current engine for VTT use
