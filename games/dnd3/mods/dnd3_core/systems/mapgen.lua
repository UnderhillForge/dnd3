-- systems/mapgen.lua
-- Registers the terrain nodes that Luanti's mapgen requires as aliases, and
-- sets those aliases so world generation produces visible stone/water/filler.
--
-- Without these three aliases the engine still runs mapgen v7 but fills all
-- generated terrain with `ignore` (invisible) nodes, making new worlds appear
-- completely flat and empty.
--
-- These are SEPARATE from the dnd3:vox_* palette nodes used by Diorama Studio
-- so that terrain stone is not accidentally edited by the sculpt tools.

-- ── Terrain nodes ────────────────────────────────────────────────────────────

core.register_node("dnd3:stone", {
    description        = "Stone",
    tiles              = { "[fill:16x16:#888888" },
    groups             = { stone = 1, cracky = 3 },
    drop               = "dnd3:stone",
    is_ground_content  = true,
    sounds             = {},
})

core.register_node("dnd3:dirt", {
    description        = "Dirt",
    tiles              = { "[fill:16x16:#7a5c3a" },
    groups             = { crumbly = 3, soil = 1 },
    drop               = "dnd3:dirt",
    is_ground_content  = true,
    sounds             = {},
})

core.register_node("dnd3:sand", {
    description        = "Sand",
    tiles              = { "[fill:16x16:#d4c060" },
    groups             = { crumbly = 3, sand = 1 },
    drop               = "dnd3:sand",
    is_ground_content  = true,
    sounds             = {},
})

core.register_node("dnd3:gravel", {
    description        = "Gravel",
    tiles              = { "[fill:16x16:#8a8a7a" },
    groups             = { crumbly = 2 },
    drop               = "dnd3:gravel",
    is_ground_content  = true,
    sounds             = {},
})

core.register_node("dnd3:water_source", {
    description        = "Water",
    drawtype           = "liquid",
    tiles              = { "[fill:16x16:#2050d088" },
    use_texture_alpha  = "blend",
    paramtype          = "light",
    walkable           = false,
    pointable          = false,
    diggable           = false,
    buildable_to       = true,
    is_ground_content  = false,
    liquidtype         = "source",
    liquid_alternative_flowing = "dnd3:water_flowing",
    liquid_alternative_source  = "dnd3:water_source",
    liquid_viscosity   = 1,
    post_effect_color  = { a = 100, r = 20, g = 50, b = 130 },
    groups             = { water = 3, liquid = 3, puts_out_fire = 1, not_in_creative_inventory = 1 },
    sounds             = {},
})

core.register_node("dnd3:water_flowing", {
    description        = "Flowing Water",
    drawtype           = "flowingliquid",
    tiles              = { "[fill:16x16:#2050d088" },
    special_tiles      = { "[fill:16x16:#2050d088", "[fill:16x16:#2050d088" },
    use_texture_alpha  = "blend",
    paramtype          = "light",
    paramtype2         = "flowingliquid",
    walkable           = false,
    pointable          = false,
    diggable           = false,
    buildable_to       = true,
    is_ground_content  = false,
    liquidtype         = "flowing",
    liquid_alternative_flowing = "dnd3:water_flowing",
    liquid_alternative_source  = "dnd3:water_source",
    liquid_viscosity   = 1,
    post_effect_color  = { a = 100, r = 20, g = 50, b = 130 },
    groups             = { water = 3, liquid = 3, puts_out_fire = 1, not_in_creative_inventory = 1 },
    sounds             = {},
})

-- River water (mapgen v7 places this in riverbeds; can be the same as water)
core.register_alias("dnd3:river_water_source",  "dnd3:water_source")
core.register_alias("dnd3:river_water_flowing", "dnd3:water_flowing")

-- ── Mapgen aliases ───────────────────────────────────────────────────────────
-- These three are REQUIRED for any mapgen that generates terrain.
-- Without them the engine logs "Mapgen alias X is invalid" and fills
-- generated chunks with `ignore` nodes.

core.register_alias("mapgen_stone",              "dnd3:stone")
core.register_alias("mapgen_water_source",       "dnd3:water_source")
core.register_alias("mapgen_river_water_source", "dnd3:water_source")

-- Bonus: common aliases so mods that reference default:* don't crash
core.register_alias("default:stone",        "dnd3:stone")
core.register_alias("default:dirt",         "dnd3:dirt")
core.register_alias("default:sand",         "dnd3:sand")
core.register_alias("default:gravel",       "dnd3:gravel")
core.register_alias("default:water_source", "dnd3:water_source")
core.register_alias("default:water_flowing","dnd3:water_flowing")

core.log("action", "[dnd3_core] mapgen aliases registered (stone/water/river)")
