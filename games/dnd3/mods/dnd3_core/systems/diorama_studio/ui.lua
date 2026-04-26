local Studio = dnd3.diorama_studio

local function esc(s)
	return core.formspec_escape(tostring(s or ""))
end

local TABS = {
	"Voxel Sculpt",
	"Mesh Refine",
	"Animation",
}

-- Live palette from palette.lua (populated at load time)
local function get_palette()
	if dnd3.studio_palette and #dnd3.studio_palette > 0 then
		return dnd3.studio_palette
	end
	-- Fallback if palette.lua hasn't run yet (shouldn't happen)
	return {
		{ id = "stone",  name = "Stone",  colour = "#888888", node = "dnd3:vox_stone"  },
		{ id = "dirt",   name = "Dirt",   colour = "#8B5E3C", node = "dnd3:vox_dirt"   },
		{ id = "grass",  name = "Grass",  colour = "#4CAF50", node = "dnd3:vox_grass"  },
	}
end

local function get_setting(name, default)
	local s = core.settings
	if not s then
		return default
	end
	local v = s:get(name)
	if v == nil or v == "" then
		return default
	end
	return v
end

local function get_render_profile_summary()
	local camera_mode = get_setting("dnd3_diorama_camera_mode", "isometric")
	local diorama_scale = get_setting("render.diorama_visual_scale", get_setting("render.voxel_visual_scale", "0.55"))
	local texel_density = get_setting("render.voxel_texel_density", "128")
	local pixel_scale = get_setting("render.pixel_scale", "2.0")
	return string.format("Camera: %s | Visual Scale: %s | Texel: %s | Pixel Snap: %s", camera_mode, diorama_scale, texel_density, pixel_scale)
end

local function default_session()
	return {
		active = true,
		tab = 1,
		selected_tool = "Voxel",
		paint_node = get_setting("dnd3_studio_default_paint_node", "stone"),
		brush_radius = tonumber(get_setting("dnd3_studio_default_brush_radius", "1")) or 1,
		preview_mesh = get_setting("dnd3_studio_preview_mesh", "floorDecoration_tilesLarge.gltf.glb"),
		preview_textures = get_setting("dnd3_studio_preview_textures", ""),
		preview_frame_start = tonumber(get_setting("dnd3_studio_preview_frame_start", "0")) or 0,
		preview_frame_end = tonumber(get_setting("dnd3_studio_preview_frame_end", "79")) or 79,
		preview_fps = tonumber(get_setting("dnd3_studio_preview_fps", "15")) or 15,
		live_preview = core.is_yes(get_setting("dnd3_studio_realtime_preview", "true")),
		last_preview_at = 0,
		search = "",
		asset_idx = 1,
	}
end

local function get_session(name)
	if not Studio.sessions[name] then
		Studio.sessions[name] = default_session()
	end
	return Studio.sessions[name]
end

local function filtered_assets(search)
	local palette = get_palette()
	local out = {}
	local needle = (search or ""):lower()
	for _, e in ipairs(palette) do
		if needle == "" or e.name:lower():find(needle, 1, true) then
			out[#out + 1] = { name = e.name, mesh = nil, textures = nil, nodename = e.node, colour = e.colour, id = e.id }
		end
	end
	if #out == 0 then
		out = {}
		for _, e in ipairs(palette) do
			out[#out+1] = { name = e.name, mesh = nil, textures = nil, nodename = e.node, colour = e.colour, id = e.id }
		end
	end
	return out
end

local function formspec_asset_list(assets)
	local labels = {}
	for _, a in ipairs(assets) do
		labels[#labels + 1] = a.name
	end
	return table.concat(labels, ",")
end

local function player_pos(name)
	local player = core.get_player_by_name(name)
	if not player then
		return nil
	end
	local p = player:get_pos()
	return {
		x = math.floor(p.x + 0.5),
		y = math.floor(p.y + 0.5),
		z = math.floor(p.z + 0.5),
	}
end

local function run_refine_pass(name)
	local p = player_pos(name)
	if not p then
		return false, "Player not found"
	end
	if dnd3.diorama and dnd3.diorama.convert_region then
		local r = 20
		local out = dnd3.diorama.convert_region(
			{ x = p.x - r, y = p.y - 8, z = p.z - r },
			{ x = p.x + r, y = p.y + 8, z = p.z + r }
		)
		if out and out.summary then
			core.chat_send_player(name, string.format("[studio] diorama slopes=%d bevels=%d", out.summary.slope_count, out.summary.bevel_count))
		end
	end
	if dnd3.hybrid_terrain and dnd3.hybrid_terrain.generate_slopes then
		local r = 20
		dnd3.hybrid_terrain.generate_slopes(
			{ x = p.x - r, y = p.y - 8, z = p.z - r },
			{ x = p.x + r, y = p.y + 8, z = p.z + r }
		)
	end
	return true
end

function Studio.formspec(name)
	local s = get_session(name)
	local assets = filtered_assets(s.search)
	local asset_idx = math.max(1, math.min(#assets, s.asset_idx or 1))
	s.asset_idx = asset_idx

	return table.concat({
		"formspec_version[6]",
		"size[18,12]",
		"bgcolor[#0f0f0fee;true]",
		"label[0.4,0.3;Diorama Studio]",
		"tabheader[2.3,0.35;studio_tab;Voxel Sculpt,Mesh Refine,Animation;", tostring(s.tab), ";true;false]",
		"button_exit[14.0,0.1;1.8,0.8;studio_close;Exit Studio]",
		"button[15.9,0.1;1.8,0.8;save_prefab;Save Prefab]",
		"box[0,0.95;2,11.05;#2a2a2a]",
		"label[0.35,1.2;Tools]",
		"button[0.2,1.7;1.6,0.9;btn_voxel;Voxel]",
		"button[0.2,2.8;1.6,0.9;btn_mesh;Mesh]",
		"button[0.2,3.9;1.6,0.9;btn_paint;Paint]",
		"button[0.2,5.0;1.6,0.9;btn_anim;Anim]",
		"button[0.2,6.1;1.6,0.9;btn_stamp;Stamp]",
		"button[0.2,7.1;1.6,0.9;btn_prefabs;Prefabs…]",
		"label[0.35,7.5;Palette]",
		-- Active colour swatch + active id label
		(function()
			local palette = get_palette()
			local active_id  = s.paint_node or "stone"
			local active_col = "#888888"
			for _, e in ipairs(palette) do
				if e.id == active_id or e.node == active_id then
					active_col = e.colour or active_col
					active_id  = e.id
					break
				end
			end
			-- Two rows of coloured buttons (up to 15 swatches, 7 wide, 2 rows)
			local btns = {}
			local cols = 7
			local bw, bh = 0.22, 0.22
			local gx, gy = 0.25, 7.95
			for i, e in ipairs(palette) do
				local row = math.floor((i-1)/cols)
				local col = (i-1) % cols
				local x = gx + col * (bw + 0.02)
				local y = gy + row * (bh + 0.05)
				local border = (e.id == active_id) and "#ffffff" or e.colour
				btns[#btns+1] = string.format("box[%.2f,%.2f;%.2f,%.2f;%s]", x-0.01, y-0.01, bw+0.02, bh+0.02, border)
				btns[#btns+1] = string.format("image_button[%.2f,%.2f;%.2f,%.2f;[fill:1x1:%s;pal_%s;]",
					x, y, bw, bh, e.colour, e.id)
			end
			-- Show active swatch label
			btns[#btns+1] = string.format("box[0.25,9.2;1.65,0.22;%s]", active_col)
			btns[#btns+1] = string.format("label[0.3,9.27;%s]", esc(active_id))
			return table.concat(btns, "")
		end)(),
		"label[0.35,9.55;Brush]",
		"scrollbar[0.25,9.75;1.6,0.35;horizontal;brush_slider;" .. tostring(math.max(1, math.min(5, s.brush_radius or 1)) - 1) .. "]",
		"label[0.25,10.15;R=" .. tostring(s.brush_radius or 1) .. "]",
		"box[2.2,0.95;10.6,10.7;#1b1b1b]",
		"label[2.6,1.2;3D Preview Area]",
		"model[2.5,1.6;10,9.6;preview_model;",
			esc(s.preview_mesh), ";",
			esc(s.preview_textures),
			";0,25;true;true;",
			tostring(s.preview_frame_start), ",", tostring(s.preview_frame_end), ";",
			tostring(s.preview_fps),
		"]",
		"label[2.7,11.0;", esc(get_render_profile_summary()), "]",
		"box[13,0.95;5,11.05;#1f1f1f]",
		"label[13.4,1.2;Asset Browser]",
		"textlist[13.4,1.6;4.2,5.6;asset_list;", esc(formspec_asset_list(assets)), ";", tostring(asset_idx), "]",
		"field[13.4,7.8;4.2,0.8;asset_search;Search;", esc(s.search), "]",
		"button[13.4,8.5;4.2,0.8;btn_load;Load Selected]",
		"button[13.4,9.4;4.2,0.8;btn_save;Save as Prefab]",
		"button[13.4,10.3;4.2,0.8;btn_stamp_apply;Stamp Selected]",
		"box[0,11.1;18,0.9;#111111]",
		"label[0.6,11.35;Current Tool: ", esc(s.selected_tool), "  |  Active Tab: ", esc(TABS[s.tab] or TABS[1]), "  |  Grid Snap: On]",
	}, "")
end

function Studio.show(name)
	core.show_formspec(name, "dnd3:diorama_studio", Studio.formspec(name))
end

function dnd3.open_diorama_studio(player_name)
	if not dnd3.can(player_name, "map_edit") then
		return false, "Permission denied (requires GM role)."
	end
	local s = get_session(player_name)
	s.active = true
	Studio.give_tools(player_name)
	-- Open the canvas (places grid floor in world near player)
	if dnd3.studio_canvas_open then
		dnd3.studio_canvas_open(player_name)
	end
	Studio.show(player_name)
	return true
end

function dnd3.close_diorama_studio(player_name)
	local s = Studio.sessions[player_name]
	if s then
		s.active = false
	end
	if dnd3.studio_canvas_close then
		dnd3.studio_canvas_close(player_name)
	end
	if Studio.take_tools then
		Studio.take_tools(player_name)
	end
	return true
end

core.register_chatcommand("studio", {
	description = "Open Diorama Studio",
	func = function(name)
		local ok, err = dnd3.open_diorama_studio(name)
		if not ok then
			return false, err
		end
		return true, "Diorama Studio opened"
	end,
})

core.register_chatcommand("dnd3_studio", {
	description = "Open Diorama Studio",
	func = function(name)
		local ok, err = dnd3.open_diorama_studio(name)
		if not ok then
			return false, err
		end
		return true, "Diorama Studio opened"
	end,
})

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "dnd3:diorama_studio" then
		return false
	end

	local name = player:get_player_name()
	local s = get_session(name)
	local assets = filtered_assets(s.search)

	if fields.studio_close then
		dnd3.close_diorama_studio(name)
		return true
	end

	if fields.studio_tab then
		local idx = tonumber(fields.studio_tab)
		if idx and idx >= 1 and idx <= #TABS then
			s.tab = idx
		end
	end

	if fields.paint_node and fields.paint_node ~= "" then
		s.paint_node = fields.paint_node
	end
	if fields.brush_radius and fields.brush_radius ~= "" then
		s.brush_radius = tonumber(fields.brush_radius) or s.brush_radius
	end
	if fields.asset_search and fields.asset_search ~= nil then
		s.search = fields.asset_search
		s.asset_idx = 1
		assets = filtered_assets(s.search)
	end

	if fields.asset_list then
		local ev = core.explode_textlist_event(fields.asset_list)
		if ev.type == "CHG" or ev.type == "DCL" then
			s.asset_idx = ev.index
		end
	end

	if fields.btn_voxel then
		s.selected_tool = "Voxel"
	end
	if fields.btn_mesh then
		s.selected_tool = "Mesh"
		run_refine_pass(name)
	end
	if fields.btn_paint then
		s.selected_tool = "Paint"
	end
	if fields.btn_anim then
		s.selected_tool = "Anim"
	end
	if fields.btn_stamp then
		s.selected_tool = "Stamp"
	end
	if fields.btn_prefabs then
		-- Open the prefab browser as a separate formspec on top
		dnd3.open_prefab_browser(name)
		return true  -- don't re-render Studio while browser is open
	end

	-- Palette swatch clicks
	do
		local palette = get_palette()
		for _, e in ipairs(palette) do
			if fields["pal_" .. e.id] then
				s.paint_node = e.id
				core.chat_send_player(name, "[studio] Palette: " .. (e.name or e.id))
				break
			end
		end
	end

	-- Brush radius scrollbar
	if fields.brush_slider then
		local ev = core.explode_scrollbar_event(fields.brush_slider)
		if ev then
			s.brush_radius = math.max(1, math.min(5, math.floor(ev.value + 1.5)))
		end
	end

	if fields.btn_load then
		local idx = math.max(1, math.min(#assets, s.asset_idx or 1))
		local asset = assets[idx]
		if asset then
			s.preview_mesh = asset.mesh
			s.preview_textures = asset.textures
			s.paint_node = asset.nodename or s.paint_node
			core.chat_send_player(name, "[studio] Loaded asset: " .. asset.name)
		end
	end

	if fields.save_prefab or fields.btn_save then
		-- Use canvas save if a canvas is open; otherwise fall back to region capture.
		if dnd3.studio_canvas_save and s.canvas and s.canvas.anchor then
			local id = "studio_" .. os.time()
			local ok, msg = dnd3.studio_canvas_save(name, id)
			core.chat_send_player(name, "[studio] " .. tostring(msg))
		else
			local p = player_pos(name)
			if p then
				local id = "studio_" .. os.time()
				local minp = { x = p.x - 4, y = p.y - 2, z = p.z - 4 }
				local maxp = { x = p.x + 4, y = p.y + 2, z = p.z + 4 }
				local prefab, err = dnd3.prefab_capture and dnd3.prefab_capture(id, minp, maxp)
				if prefab then
					core.chat_send_player(name, "[studio] Prefab saved: " .. id)
				else
					core.chat_send_player(name, "[studio] Save failed: " .. tostring(err))
				end
			end
		end
	end

	if fields.btn_stamp_apply then
		local ids = dnd3.list_registered_prefabs and dnd3.list_registered_prefabs() or {}
		if #ids == 0 then
			core.chat_send_player(name, "[studio] No registered studio prefabs to stamp.")
		else
			local id = ids[#ids]
			local p = player_pos(name)
			if p and dnd3.prefab_stamp then
				local ok, err = dnd3.prefab_stamp(id, p)
				if ok then
					core.chat_send_player(name, "[studio] Stamped prefab: " .. id)
				else
					core.chat_send_player(name, "[studio] Stamp failed: " .. tostring(err))
				end
			end
		end
	end

	Studio.show(name)
	return true
end)

core.register_globalstep(function(dtime)
	local now = core.get_gametime()
	for name, s in pairs(Studio.sessions) do
		if s.active and s.live_preview then
			if now - (s.last_preview_at or 0) >= 1.0 then
				s.last_preview_at = now
				local player = core.get_player_by_name(name)
				if player then
					Studio.show(name)
				end
			end
		end
	end
end)
