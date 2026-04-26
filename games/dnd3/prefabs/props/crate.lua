-- Prefab: props/crate
-- A single wooden crate (1x1x1).
-- Origin is the crate position.

dnd3.register_static_prefab("props/crate", {
	size = { x = 1, y = 1, z = 1 },
	nodes = {
		{ rel = { x = 0, y = 0, z = 0 }, node = { name = "default:chest",   param1 = 0, param2 = 0 } },
	},
})
