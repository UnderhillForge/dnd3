-- D&D 3.5e Character Sheet Definition
-- Open Game Content, licensed under OGL v1.0a

dnd35 = dnd35 or {}
dnd3.dnd35 = dnd3.dnd35 or {}

local RS = "dnd35"
local BASE = dnd3.rulesets_path .. "/dnd35"

local function read_json(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local raw = f:read("*a")
	f:close()
	if not raw or raw == "" then return nil end
	local parsed = core.parse_json(raw)
	if type(parsed) ~= "table" then return nil end
	return parsed
end

local equipment_slots = read_json(BASE .. "/data/equipment_slots.json") or {
	{ id = "head", label = "Head", x = 0.9, y = 0.8 },
	{ id = "cloak", label = "Cloak", x = 0.4, y = 2.0 },
	{ id = "chest", label = "Chest", x = 1.0, y = 2.4 },
	{ id = "hands", label = "Hands", x = 0.2, y = 3.2 },
	{ id = "main_hand", label = "Main", x = 0.2, y = 4.0 },
	{ id = "off_hand", label = "Off", x = 2.7, y = 4.0 },
	{ id = "belt", label = "Belt", x = 1.1, y = 4.3 },
	{ id = "legs", label = "Legs", x = 1.0, y = 5.0 },
	{ id = "feet", label = "Feet", x = 1.0, y = 5.7 },
}

dnd3.register_sheet_field(RS, {
	id = "name", type = "string", default = "", label = "Name",
})
dnd3.register_sheet_field(RS, {
	id = "race", type = "string", default = "human", label = "Race",
})
dnd3.register_sheet_field(RS, {
	id = "alignment", type = "string", default = "neutral", label = "Alignment",
})
dnd3.register_sheet_field(RS, {
	id = "portrait_texture", type = "string", default = "", label = "Portrait Texture",
})
dnd3.register_sheet_field(RS, {
	id = "avatar_mesh", type = "string", default = "character.b3d", label = "Avatar Mesh",
})
dnd3.register_sheet_field(RS, {
	id = "avatar_base_texture", type = "string", default = "character.png", label = "Avatar Base Texture",
})
dnd3.register_sheet_field(RS, {
	id = "equipment", type = "table", default = {}, label = "Equipment",
})
dnd3.register_sheet_field(RS, {
	id = "notes", type = "string", default = "", label = "Notes",
})

if dnd3.character_sheet and dnd3.character_sheet.register_ruleset_spec then
	dnd3.character_sheet.register_ruleset_spec(RS, {
		mesh = "character.b3d",
		base_texture = "character.png",
		idle_anim = { x = 1, y = 80, speed = 24 },
		equipment_slots = equipment_slots,
		render_order = {
			"chest", "legs", "feet", "hands", "head", "cloak", "main_hand", "off_hand",
		},
		tabs = {
			"core", "skills", "combat", "inventory", "spells", "feats", "notes",
		},
	})
end

core.log("action", "[dnd35] character sheet definition loaded")
