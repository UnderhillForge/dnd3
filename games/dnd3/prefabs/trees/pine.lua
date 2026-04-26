-- Prefab: trees/pine
-- A narrow 1x7 pine tree (trunk + stacked shrinking leaf tiers).
-- Origin is the base of the trunk.

dnd3.register_static_prefab("trees/pine", {
	size = { x = 3, y = 7, z = 3 },
	nodes = {
		-- Trunk y=0..2
		{ rel = { x = 1, y = 0, z = 1 }, node = { name = "default:pine_tree",   param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 1, z = 1 }, node = { name = "default:pine_tree",   param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 2, z = 1 }, node = { name = "default:pine_tree",   param1 = 0, param2 = 0 } },
		-- Lower canopy y=3 (3x3)
		{ rel = { x = 0, y = 3, z = 0 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 3, z = 0 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		{ rel = { x = 2, y = 3, z = 0 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		{ rel = { x = 0, y = 3, z = 1 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 3, z = 1 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		{ rel = { x = 2, y = 3, z = 1 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		{ rel = { x = 0, y = 3, z = 2 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 3, z = 2 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		{ rel = { x = 2, y = 3, z = 2 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		-- Mid canopy y=4..5 (cross)
		{ rel = { x = 1, y = 4, z = 0 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		{ rel = { x = 0, y = 4, z = 1 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 4, z = 1 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		{ rel = { x = 2, y = 4, z = 1 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 4, z = 2 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		{ rel = { x = 1, y = 5, z = 1 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
		-- Tip y=6
		{ rel = { x = 1, y = 6, z = 1 }, node = { name = "default:pine_needles", param1 = 0, param2 = 0 } },
	},
})
