-- systems/diorama_studio/palette.lua
-- Registers dnd3:vox_* nodes used as the Studio sculpting palette.
-- These are simple coloured full-blocks designed for diorama work.
-- Each has a flat colour tile, cast/receive shadows normally, are
-- diggable only by Studio tools (group dnd3_vox = 1).

local PALETTE = {
    { "stone",     "Stone",      "#777777" },
    { "darkstone", "Dark Stone", "#555555" },
    { "dirt",      "Dirt",       "#8b5a2b" },
    { "grass",     "Grass",      "#3d8c2f" },
    { "sand",      "Sand",       "#e0d080" },
    { "wood",      "Wood",       "#a67c4d" },
    { "planks",    "Planks",     "#c9a56f" },
    { "leaves",    "Leaves",     "#2e8c3a" },
    { "brick",     "Brick",      "#b44a2a" },
    { "metal",     "Metal",      "#6b7a8c" },
    { "gold",      "Gold",       "#e0b030" },
    { "snow",      "Snow",       "#f0f0f8" },
    { "obsidian",  "Obsidian",   "#1f0f2e" },
    { "glowstone", "Glowstone",  "#ffe050" },
    { "water",     "Water",      "#3060c0" },
    { "lava",      "Lava",       "#e05010" },
}

dnd3.studio_palette = {}

for _, entry in ipairs(PALETTE) do
    local id, desc, hex = entry[1], entry[2], entry[3]
    local nodename = "dnd3:vox_" .. id

    core.register_node(nodename, {
        description = "Diorama " .. desc,
        drawtype = "normal",
        tiles = { "[fill:128x128:" .. hex },        -- Use 128x128 for better diorama feel
        groups = { dnd3_vox = 1, snappy = 3, oddly_breakable_by_hand = 3, dig_by_studio = 1 },
        is_ground_content = false,
        paramtype = "light",
        sunlight_propagates = false,
        sounds = {},
    })

    table.insert(dnd3.studio_palette, {
        id     = id,
        name   = desc,
        node   = nodename,
        colour = hex,
    })
end

function dnd3.studio_palette_node(id)
    for _, e in ipairs(dnd3.studio_palette) do
        if e.id == id then return e.node end
    end
    return "dnd3:vox_stone"   -- safe fallback
end

-- (dnd3:grid_floor is registered in systems/grid_world.lua)
