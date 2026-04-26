-- systems/diorama_studio/preview.lua
-- Manages the Studio "canvas" – the bounded region in the world where the
-- player sculpts, and the per-player HUD that shows live node counts.
--
-- Canvas design:
--   • A 16×16×16 vox region is reserved at a fixed offset near the player
--     when Studio opens (or the player can set a custom anchor with
--     /studio_canvas <x> <y> <z>).
--   • dnd3.studio_canvas_dirty(pos) is called by tools.lua on every edit;
--     here we debounce and update the HUD element.
--   • On Save, we snapshot the canvas voxels into a node-layout prefab via
--     dnd3.register_static_prefab() and write the .lua file to
--     worlds/<world>/prefabs/<id>.lua so it persists across restarts.

local Studio = dnd3.diorama_studio

-- ── Constants ────────────────────────────────────────────────────────────────

local CANVAS_SIZE   = 16   -- full side length of the sculpt region
local CANVAS_HALF   = math.floor(CANVAS_SIZE / 2)
local HUD_UPDATE_INTERVAL = 0.5   -- seconds between HUD refreshes

-- ── Canvas state per player ──────────────────────────────────────────────────
-- Stored inside Studio.sessions[name].canvas = { anchor, hud_id, dirty, timer }

local function get_session(name)
	return Studio.sessions[name]
end

-- ── Anchor helpers ───────────────────────────────────────────────────────────

--- Returns the minp/maxp of the canvas centred on anchor.
local function canvas_bounds(anchor)
	return
		{ x = anchor.x - CANVAS_HALF, y = anchor.y,            z = anchor.z - CANVAS_HALF },
		{ x = anchor.x + CANVAS_HALF, y = anchor.y + CANVAS_SIZE - 1, z = anchor.z + CANVAS_HALF }
end

--- True if pos is inside (inclusive) the canvas bounds.
local function in_canvas(anchor, pos)
	local minp, maxp = canvas_bounds(anchor)
	return pos.x >= minp.x and pos.x <= maxp.x
	   and pos.y >= minp.y and pos.y <= maxp.y
	   and pos.z >= minp.z and pos.z <= maxp.z
end

-- ── HUD ──────────────────────────────────────────────────────────────────────

local function update_hud(name)
	local player = core.get_player_by_name(name)
	if not player then return end
	local s = get_session(name)
	if not s or not s.canvas then return end

	local anchor = s.canvas.anchor
	local minp, maxp = canvas_bounds(anchor)

	-- Count non-air vox nodes in the canvas
	local count = 0
	for x = minp.x, maxp.x do
		for y = minp.y, maxp.y do
			for z = minp.z, maxp.z do
				local n = core.get_node({x=x,y=y,z=z}).name
				if n ~= "air" and n ~= "ignore" then
					count = count + 1
				end
			end
		end
	end

	local text = string.format(
		"[STUDIO]  anchor (%d,%d,%d)  |  voxels: %d / %d  |  palette: %s",
		anchor.x, anchor.y, anchor.z,
		count, CANVAS_SIZE^3,
		tostring(s.paint_node or "stone"))

	if s.canvas.hud_id then
		player:hud_change(s.canvas.hud_id, "text", text)
	else
		s.canvas.hud_id = player:hud_add({
			type    = "text",
			pos     = { x = 0.5, y = 0.02 },
			align   = { x = 0,   y = 1    },
			offset  = { x = 0,   y = 0    },
			text    = text,
			number  = 0xffffff,
			scale   = { x = 100, y = 100 },
			z_index = 100,
		})
	end
end

local function remove_hud(name)
	local player = core.get_player_by_name(name)
	if not player then return end
	local s = get_session(name)
	if not s or not s.canvas then return end
	if s.canvas.hud_id then
		player:hud_remove(s.canvas.hud_id)
		s.canvas.hud_id = nil
	end
end

-- ── Public API ───────────────────────────────────────────────────────────────

--- Called by tools.lua when a vox is placed/removed/painted.
function dnd3.studio_canvas_dirty(pos)
	-- Mark all sessions whose canvas contains this pos as dirty.
	for name, s in pairs(Studio.sessions) do
		if s.active and s.canvas and s.canvas.anchor then
			if in_canvas(s.canvas.anchor, pos) then
				s.canvas.dirty = true
			end
		end
	end
end

--- Open / initialise the canvas for a player.
--- anchor = world pos that becomes the bottom-centre of the canvas.
--- If nil, places the canvas 4 nodes in front of the player.
function dnd3.studio_canvas_open(name, anchor)
	local player = core.get_player_by_name(name)
	if not player then return false, "player not found" end

	local s = get_session(name)
	if not s then return false, "no session" end

	if not anchor then
		local p   = player:get_pos()
		local dir = player:get_look_dir()
		anchor = {
			x = math.floor(p.x + dir.x * (CANVAS_HALF + 4) + 0.5),
			y = math.floor(p.y + 0.5),
			z = math.floor(p.z + dir.z * (CANVAS_HALF + 4) + 0.5),
		}
	end

	s.canvas = {
		anchor  = anchor,
		hud_id  = nil,
		dirty   = false,
		timer   = 0,
	}

	-- Place a thin floor of grid markers so the player can see the canvas area
	local minp, maxp = canvas_bounds(anchor)
	local floor_y = minp.y - 1
	for x = minp.x, maxp.x do
		for z = minp.z, maxp.z do
			local fp = { x = x, y = floor_y, z = z }
			if core.get_node(fp).name == "air" then
				core.set_node(fp, { name = "dnd3:grid_floor" })
			end
		end
	end

	update_hud(name)
	core.chat_send_player(name, string.format(
		"[studio] Canvas opened at (%d,%d,%d). Size: %dx%dx%d.",
		anchor.x, anchor.y, anchor.z, CANVAS_SIZE, CANVAS_SIZE, CANVAS_SIZE))
	return true
end

--- Close the canvas (remove HUD; leave world nodes as-is).
function dnd3.studio_canvas_close(name)
	remove_hud(name)
	local s = get_session(name)
	if s then s.canvas = nil end
end

--- Snapshot current canvas voxels and save as a static prefab + .lua file.
--- id = prefab id string (e.g. "my_tree")
function dnd3.studio_canvas_save(name, id)
	local s = get_session(name)
	if not s or not s.canvas or not s.canvas.anchor then
		return false, "No canvas open."
	end
	if type(id) ~= "string" or id:match("^%s*$") then
		id = "studio_" .. tostring(os.time())
	end
	-- Sanitise: keep alnum, dash, underscore, slash (for category/id)
	id = id:gsub("[^%w%-_/]", "_")

	local anchor = s.canvas.anchor
	local minp, maxp = canvas_bounds(anchor)

	-- Collect non-air nodes relative to minp
	local nodes = {}
	for x = minp.x, maxp.x do
		for y = minp.y, maxp.y do
			for z = minp.z, maxp.z do
				local node = core.get_node({x=x,y=y,z=z})
				if node.name ~= "air" and node.name ~= "ignore"
				   and node.name ~= "dnd3:grid_floor" then
					nodes[#nodes+1] = {
						rel  = { x = x - minp.x, y = y - minp.y, z = z - minp.z },
						node = node,
					}
				end
			end
		end
	end

	if #nodes == 0 then
		return false, "Canvas is empty – nothing to save."
	end

	local size = { x = CANVAS_SIZE, y = CANVAS_SIZE, z = CANVAS_SIZE }

	-- Register in the runtime prefab table
	dnd3.register_static_prefab(id, { size = size, nodes = nodes })

	-- Write a .lua file to worlds/<world>/prefabs/ so it survives restarts
	local world_path = core.get_worldpath()
	local prefabs_dir = world_path .. "/prefabs"

	-- Derive subdirectory from id (e.g. "trees/my_oak" → prefabs/trees/)
	local sub_id   = id:match("^(.+)/[^/]+$") or ""
	local file_dir = (sub_id ~= "") and (prefabs_dir .. "/" .. sub_id) or prefabs_dir

	-- Try to create directory via loadfile+io trick (insecure env preferred)
	local insecure = core.request_insecure_environment and core.request_insecure_environment()
	local io_open  = (insecure and insecure.io and insecure.io.open) or io.open

	-- Build Lua source
	local lines = {
		"-- Auto-saved by Diorama Studio",
		string.format("-- Saved: %s  |  Voxels: %d", os.date(), #nodes),
		"",
		string.format("dnd3.register_static_prefab(%q, {", id),
		string.format("\tsize  = { x = %d, y = %d, z = %d },", size.x, size.y, size.z),
		"\tnodes = {",
	}
	for _, e in ipairs(nodes) do
		lines[#lines+1] = string.format(
			"\t\t{ rel = {x=%d,y=%d,z=%d}, node = {name=%q,param1=%d,param2=%d} },",
			e.rel.x, e.rel.y, e.rel.z,
			e.node.name, e.node.param1 or 0, e.node.param2 or 0)
	end
	lines[#lines+1] = "\t},"
	lines[#lines+1] = "})"
	lines[#lines+1] = ""

	local src = table.concat(lines, "\n")

	-- Ensure directory exists (mkdir -p equivalent via os.execute if available)
	if insecure and insecure.os and insecure.os.execute then
		insecure.os.execute('mkdir -p "' .. file_dir .. '"')
	end

	local fname     = id:match("[^/]+$") or id
	local filepath  = file_dir .. "/" .. fname .. ".lua"
	local fh, ferr  = io_open(filepath, "w")
	if fh then
		fh:write(src)
		fh:close()
		core.log("action", "[dnd3_studio] Saved prefab file: " .. filepath)
	else
		core.log("warning", "[dnd3_studio] Could not write prefab file: " .. tostring(ferr)
			.. " — prefab is registered in memory only (will not persist).")
	end

	return true, string.format("Saved prefab '%s' (%d nodes). Stamp with /dnd3_prefab_stamp %s x y z",
		id, #nodes, id)
end

-- ── /studio_canvas and /studio_save commands ─────────────────────────────────

core.register_chatcommand("studio_canvas", {
	params      = "[<x> <y> <z>]",
	description = "Set or reset the Studio canvas anchor (GM only)",
	func = function(name, param)
		if not (dnd3.can and dnd3.can(name, "map_edit")) then
			return false, "Permission denied."
		end
		local s = get_session(name)
		if not s or not s.active then return false, "Studio not active." end
		local anchor
		local x, y, z = param:match("^(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)$")
		if x then
			anchor = { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
		end
		local ok, err = dnd3.studio_canvas_open(name, anchor)
		if not ok then return false, err end
		return true
	end,
})

core.register_chatcommand("studio_save", {
	params      = "[<id>]",
	description = "Save current Studio canvas as a prefab",
	func = function(name, param)
		if not (dnd3.can and dnd3.can(name, "map_edit")) then
			return false, "Permission denied."
		end
		local id = param:match("^%s*(.-)%s*$")
		local ok, msg = dnd3.studio_canvas_save(name, id ~= "" and id or nil)
		if not ok then return false, msg end
		return true, msg
	end,
})

-- ── Globalstep: debounced HUD refresh ────────────────────────────────────────

core.register_globalstep(function(dtime)
	for name, s in pairs(Studio.sessions) do
		if s.active and s.canvas then
			s.canvas.timer = (s.canvas.timer or 0) + dtime
			if s.canvas.dirty and s.canvas.timer >= HUD_UPDATE_INTERVAL then
				s.canvas.timer = 0
				s.canvas.dirty = false
				update_hud(name)
			end
		end
	end
end)
