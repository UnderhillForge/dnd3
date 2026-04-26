-- Prefab: trees/oak
-- Node-layout blueprint: a 3×5×3 oak tree (trunk + leafy crown).
-- Origin is the base of the trunk.

dnd3.register_static_prefab("trees/oak", {
	size = { x = 3, y = 5, z = 3 },
	nodes = {
		-- Trunk y=0..2 (center column)
		{ rel = { x = 1, y = 0, z = 1 }, node = { name = "default:tree",    param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 1, z = 1 }, node = { name = "default:tree",    param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 2, z = 1 }, node = { name = "default:tree",    param1 = 0, param2 = 0 } },
		-- Crown base y=3 (3x3 leaves)
		{ rel = { x = 0, y = 3, z = 0 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 3, z = 0 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
		{ rel = { x = 2, y = 3, z = 0 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
		{ rel = { x = 0, y = 3, z = 1 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 3, z = 1 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
		{ rel = { x = 2, y = 3, z = 1 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
		{ rel = { x = 0, y = 3, z = 2 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 3, z = 2 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
		{ rel = { x = 2, y = 3, z = 2 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
		-- Crown top y=4 (cross pattern)
		{ rel = { x = 1, y = 4, z = 0 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
		{ rel = { x = 0, y = 4, z = 1 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 4, z = 1 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
		{ rel = { x = 2, y = 4, z = 1 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 4, z = 2 }, node = { name = "default:leaves",  param1 = 0, param2 = 0 } },
	},
})

-- Entity-visual template: mesh-based diorama prop.
-- Link a token to this by setting meta.prefab = "oak_tree" when creating the token.

dnd3.register_prefab({
	name          = "Oak Tree",
	type          = "prop",
	tags          = { "tree", "nature", "outdoor" },
	mesh          = "diorama_tree_oak.glb",
	textures      = {
		"diorama_tree_bark_128.png",
		"diorama_tree_leaves_128.png",
	},
	visual_scale  = 1.4,
	collision_box = { -0.4, 0, -0.4, 0.4, 4.5, 0.4 },
	bevel         = true,
	wind_sway     = true,
})
