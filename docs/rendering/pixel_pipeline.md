# dnd3 Pixel Pipeline (Hybrid Architecture)

This page documents the pixel-art rendering controls introduced for the
"Voxel Soul + Pixel Art Body" hybrid architecture.

## Goals

- Keep voxel grid gameplay canonical (`1 node = 5 ft`).
- Improve visual readability and perceived detail.
- Preserve crisp pixels (nearest-neighbor) at all zoom levels.

## Key Settings

### Visual scale

- `voxel_visual_scale` (legacy key)
- `render.voxel_visual_scale` (preferred namespaced key)

Both control clip-space visual scale only. Physics and collision stay unchanged.
If both are set, `render.voxel_visual_scale` is used.

Recommended values:

- `0.50` to `0.60`: strong diorama look
- `0.75`: balanced default
- `1.00`: classic full-size look

### Texel density

- `render.voxel_texel_density` (default `128`)

Use `128` or `256` textures in world packs and keep filtering nearest to avoid blur.

### Pixel snapping

- `render.pixel_scale` (default `2.0`)

Used by second-stage post-processing to snap UV sampling to a stable pixel grid.
Higher values increase snapping strength.

### Cel shading and outlines

- `pixel_art_cel_shading`
- `pixel_art_cel_shading_steps`
- `pixel_art_outlines`
- `pixel_art_outline_strength`

These provide banded lighting and hard silhouettes for a pixel-art aesthetic.

## Hybrid Terrain Runtime Systems

`dnd3_core` now includes `systems/hybrid_terrain/`:

- `slope_generator.lua`: runtime slope placement from voxel height deltas
- `voxel_to_mesh.lua`: exposed-face descriptor baking for later mesh upload
- `navmesh.lua`: lightweight walkability graph + A* path sampling

This keeps voxel data as source of truth while enabling smooth visual/movement layers.

## Test Checklist

1. Start world with `dnd3_hybrid_enabled = true`.
2. Run `/dnd3_hybrid_slopes 16` near uneven terrain.
3. Run `/dnd3_hybrid_bake 16` and confirm non-zero exposed face count.
4. Run `/dnd3_hybrid_navmesh 20` then `/dnd3_hybrid_path <x> <z>`.
5. Toggle `render.voxel_visual_scale` between `0.5`, `0.75`, `1.0` and compare visuals.
6. Toggle `pixel_art_outlines` and confirm silhouette sharpening.

## Screenshot Guidance

Capture A/B shots from the same camera position:

- A: `render.voxel_visual_scale = 1.0`, outlines off
- B: `render.voxel_visual_scale = 0.6`, outlines on, cel shading on

Target result: B should look less chunky, with crisper small-scale forms and
clear voxel silhouettes.
