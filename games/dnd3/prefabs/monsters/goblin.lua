-- Prefab: monsters/goblin
-- Entity-visual template for a Forest Goblin encounter token.
-- Spawn via: /dnd3_token_spawn <id>  (token must have meta.prefab = "forest_goblin")

dnd3.register_prefab({
	name         = "Forest Goblin",
	type         = "monster",
	mesh         = "character_goblin.glb",
	textures     = { "goblin_skin_128.png", "goblin_armor_128.png" },
	visual_scale = 0.85,
	animation    = {
		idle   = { start =  0, stop =  30 },
		walk   = { start = 40, stop =  70 },
		attack = { start = 80, stop = 110 },
	},
})
