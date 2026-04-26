-- Prefab: props/barrel
-- A single barrel (1x1x1 using a stone-like placeholder until dnd3:barrel is defined).
-- Replace "default:cobble" with the actual barrel node once registered.

dnd3.register_static_prefab("props/barrel", {
	size = { x = 1, y = 1, z = 1 },
	nodes = {
		{ rel = { x = 0, y = 0, z = 0 }, node = { name = "default:cobble",  param1 = 0, param2 = 0 } },
	},
})
