-- Rock / terrain-prop prefabs

dnd3.register_prefab({
	name          = "Mossy Boulder",
	type          = "terrain_prop",
	mesh          = "diorama_rock_large.glb",
	textures      = { "diorama_rock_mossy_128.png" },
	visual_scale  = 1.2,
	collision_box = { -1.2, 0, -1.1, 1.3, 1.8, 1.2 },
})
