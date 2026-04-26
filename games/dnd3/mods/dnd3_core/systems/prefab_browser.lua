-- systems/prefab_browser.lua
-- In-game Prefab Placement Browser
--
-- Opens via:  /prefabs          (standalone)
--             /prefabs <search> (pre-filtered)
--             dnd3.open_prefab_browser(player_name)
--
-- The browser shows entity-visual prefabs (register_prefab) in the left pane
-- and node-layout blueprints (register_static_prefab) in the right pane.
-- Selecting an entry and pressing Place:
--   • Entity prefab  → creates a token + spawns its world entity at player feet
--   • Node blueprint → stamps the voxel layout at player feet

-- ── State ─────────────────────────────────────────────────────────────────

local sessions = {}   -- player_name -> session

local TYPE_COLORS = {
    character    = "#d4a060",
    monster      = "#d46060",
    weapon       = "#8888dd",
    item         = "#88cc88",
    container    = "#c0a060",
    furniture    = "#aaaaaa",
    structural   = "#778899",
    terrain_prop = "#80a870",
    prop         = "#999999",
}

local CATEGORIES = {
    "all", "character", "monster", "weapon", "item",
    "container", "furniture", "structural", "terrain_prop", "prop",
}

local function esc(s)
    return core.formspec_escape(tostring(s or ""))
end

local function default_session()
    return {
        tab         = 1,   -- 1=entity, 2=blueprint
        search      = "",
        category    = "all",
        entity_idx  = 1,
        bp_idx      = 1,
        status      = "Ready.",
        last_placed = nil,
    }
end

local function get_session(name)
    if not sessions[name] then
        sessions[name] = default_session()
    end
    return sessions[name]
end

-- ── Helpers ────────────────────────────────────────────────────────────────

local function player_feet(name)
    local player = core.get_player_by_name(name)
    if not player then return nil end
    local p = player:get_pos()
    return { x = math.floor(p.x + 0.5), y = math.floor(p.y), z = math.floor(p.z + 0.5) }
end

--- Filter entity-visual prefabs by search string and category.
local function filtered_entity_prefabs(search, category)
    local needle = (search or ""):lower()
    local out = {}
    for _, id in ipairs(dnd3.prefab_def_list()) do
        local def = dnd3.prefab_def_get(id)
        if not def then goto continue end
        if category ~= "all" and def.type ~= category then goto continue end
        if needle ~= "" then
            local hay = (def.name .. " " .. def.type .. " " .. table.concat(def.tags or {}, " ")):lower()
            if not hay:find(needle, 1, true) then goto continue end
        end
        out[#out + 1] = def
        ::continue::
    end
    return out
end

--- Filter node-layout blueprints by search string.
local function filtered_blueprints(search)
    local needle = (search or ""):lower()
    local out = {}
    -- prefab_list() returns only runtime-captured prefabs stored in mod_storage.
    -- Static ones registered via register_static_prefab are also in the same
    -- internal table (accessed via prefab_stamp/prefab_list).
    for _, id in ipairs(dnd3.prefab_list()) do
        if needle == "" or id:lower():find(needle, 1, true) then
            out[#out + 1] = id
        end
    end
    return out
end

--- Build the textlist string for entity prefabs.
local function entity_list_str(defs)
    local parts = {}
    for _, def in ipairs(defs) do
        local col = TYPE_COLORS[def.type] or "#999999"
        -- textlist doesn't support per-row colour in vanilla formspec; include type prefix
        parts[#parts + 1] = string.format("[%s] %s", def.type:sub(1,3):upper(), def.name)
    end
    return table.concat(parts, ",")
end

--- Build the textlist string for node blueprints.
local function bp_list_str(ids)
    return table.concat(ids, ",")
end

-- ── Detail panel ───────────────────────────────────────────────────────────

local function entity_detail(def)
    if not def then return "No prefab selected." end
    local lines = {
        "Name:  " .. def.name,
        "Type:  " .. def.type,
        "ID:    " .. def.id,
        "Mesh:  " .. (def.mesh or "(none)"),
        "Scale: " .. tostring(def.visual_scale or 1.0),
    }
    if def.tags and #def.tags > 0 then
        lines[#lines+1] = "Tags:  " .. table.concat(def.tags, ", ")
    end
    if def.animation then
        local anims = {}
        for k in pairs(def.animation) do anims[#anims+1] = k end
        lines[#lines+1] = "Anim:  " .. table.concat(anims, ", ")
    end
    if def.bevel     then lines[#lines+1] = "Bevel: yes" end
    if def.wind_sway then lines[#lines+1] = "Sway:  yes" end
    return table.concat(lines, "\n")
end

-- ── Formspec ───────────────────────────────────────────────────────────────

local FORMNAME = "dnd3:prefab_browser"
local TAB_LABELS = "Entity Prefabs,Node Blueprints"

local function build_formspec(name)
    local s = get_session(name)
    local parts = {
        "formspec_version[6]",
        "size[20,13]",
        "bgcolor[#0d0d0dee;true]",
        -- title bar
        "label[0.4,0.35;Prefab Browser]",
        string.format("tabheader[3,0.3;pb_tab;%s;%d;true;false]", TAB_LABELS, s.tab),
        "button_exit[18.2,0.1;1.6,0.75;pb_close;Close]",
        -- search bar
        "label[0.4,1.15;Search:]",
        string.format('field[1.4,0.9;6,0.75;pb_search;;%s]', esc(s.search)),
        "button[7.5,0.9;1.6,0.75;pb_search_btn;Search]",
        "button[9.2,0.9;1.6,0.75;pb_clear;Clear]",
    }

    if s.tab == 1 then
        -- ── Entity Prefabs tab ─────────────────────────────────────────────
        local defs = filtered_entity_prefabs(s.search, s.category)
        local idx = math.max(1, math.min(#defs, s.entity_idx))
        s.entity_idx = idx

        -- Category filter
        local cat_parts = {}
        for i, c in ipairs(CATEGORIES) do
            cat_parts[#cat_parts+1] = c
        end
        local cat_idx = 1
        for i, c in ipairs(CATEGORIES) do
            if c == s.category then cat_idx = i; break end
        end
        parts[#parts+1] = "label[0.4,1.95;Category:]"
        parts[#parts+1] = string.format("dropdown[1.6,1.75;4,0.75;pb_category;%s;%d;false]",
            table.concat(cat_parts, ","), cat_idx)

        -- List (left column)
        parts[#parts+1] = string.format(
            "textlist[0.4,2.6;7.5,8.0;pb_entity_list;%s;%d]",
            esc(entity_list_str(defs)), idx)

        -- Detail panel (right column)
        local sel = defs[idx]
        parts[#parts+1] = "box[8.2,2.6;11.4,8.0;#161616]"
        parts[#parts+1] = string.format("textarea[8.4,2.7;11,5.5;_;Details;%s]",
            esc(entity_detail(sel)))

        -- Model preview (if mesh assigned)
        if sel and sel.mesh then
            local tex = (sel.textures and #sel.textures > 0) and
                table.concat(sel.textures, ",") or "blank.png"
            parts[#parts+1] = string.format(
                "model[8.4,5.9;5,4.5;pb_model;%s;%s;0,20;false;true;0,0;15]",
                esc(sel.mesh), esc(tex))
        end

        -- Action buttons
        parts[#parts+1] = "button[14.0,8.2;2.6,0.9;pb_place_entity;Place at Feet]"
        parts[#parts+1] = "button[16.7,8.2;2.6,0.9;pb_place_entity_look;Place Ahead]"

    else
        -- ── Node Blueprints tab ────────────────────────────────────────────
        local ids = filtered_blueprints(s.search)
        local idx = math.max(1, math.min(math.max(#ids, 1), s.bp_idx))
        s.bp_idx = idx

        parts[#parts+1] = string.format(
            "textlist[0.4,2.0;7.5,8.6;pb_bp_list;%s;%d]",
            esc(bp_list_str(ids)), idx)

        local sel_id = ids[idx]
        parts[#parts+1] = "box[8.2,2.0;11.4,8.6;#161616]"
        if sel_id then
            parts[#parts+1] = string.format("label[8.6,2.4;Blueprint: %s]", esc(sel_id))
            parts[#parts+1] = string.format(
                "label[8.6,3.0;Stamp will place nodes starting at your feet.]")
        else
            parts[#parts+1] = "label[8.6,2.4;No blueprints registered yet.]"
            parts[#parts+1] = "label[8.6,3.0;Capture one with /dnd3_prefab_capture]"
        end

        parts[#parts+1] = "button[14.0,9.7;2.6,0.9;pb_stamp;Stamp at Feet]"
        parts[#parts+1] = "button[16.7,9.7;2.6,0.9;pb_stamp_look;Stamp Ahead]"
    end

    -- Status bar
    parts[#parts+1] = "box[0,12.2;20,0.8;#111111]"
    parts[#parts+1] = string.format("label[0.5,12.45;%s]", esc(s.status))

    return table.concat(parts, "")
end

-- ── Public API ─────────────────────────────────────────────────────────────

function dnd3.open_prefab_browser(player_name, search)
    if not dnd3.can(player_name, "map_edit") then
        return false, "Permission denied (requires GM role)."
    end
    local s = get_session(player_name)
    if search and search ~= "" then
        s.search = search
        s.entity_idx = 1
        s.bp_idx = 1
    end
    core.show_formspec(player_name, FORMNAME, build_formspec(player_name))
    return true
end

function dnd3.close_prefab_browser(player_name)
    core.close_formspec(player_name, FORMNAME)
end

-- ── Placement helpers ──────────────────────────────────────────────────────

--- pos 1 node ahead of where player is looking (horizontal only).
local function pos_ahead(name)
    local player = core.get_player_by_name(name)
    if not player then return nil end
    local p = player:get_pos()
    local dir = player:get_look_dir()
    return {
        x = math.floor(p.x + dir.x * 2 + 0.5),
        y = math.floor(p.y),
        z = math.floor(p.z + dir.z * 2 + 0.5),
    }
end

local function place_entity_prefab(name, def, pos)
    if not pos then return false, "Could not determine position." end
    local token_id = def.id .. "_" .. tostring(os.time())
    local tok, err = dnd3.token_set(token_id, {
        pos   = pos,
        label = def.name,
        meta  = { prefab = def.id },
    })
    if not tok then return false, err end
    local ent, eerr = dnd3.token_spawn(token_id)
    if not ent then
        return false, "Token created but entity spawn failed: " .. tostring(eerr)
    end
    return true, string.format("Placed '%s' (token id: %s)", def.name, token_id)
end

local function stamp_blueprint(name, bp_id, pos)
    if not pos then return false, "Could not determine position." end
    local ok, err = dnd3.prefab_stamp(bp_id, pos)
    if not ok then return false, err end
    return true, string.format("Stamped blueprint '%s'.", bp_id)
end

-- ── Field handler ──────────────────────────────────────────────────────────

core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= FORMNAME then return false end

    local name = player:get_player_name()
    local s    = get_session(name)

    if fields.pb_close or fields.quit then
        return true
    end

    -- Tab switch
    if fields.pb_tab then
        local idx = tonumber(fields.pb_tab)
        if idx then s.tab = idx end
    end

    -- Search
    if fields.pb_search ~= nil then
        s.search = fields.pb_search
    end
    if fields.pb_search_btn or fields.key_enter_field == "pb_search" then
        s.entity_idx = 1
        s.bp_idx = 1
    end
    if fields.pb_clear then
        s.search = ""
        s.entity_idx = 1
        s.bp_idx = 1
    end

    -- Category dropdown (entity tab)
    if fields.pb_category then
        s.category = fields.pb_category
        s.entity_idx = 1
    end

    -- List selection
    if fields.pb_entity_list then
        local ev = core.explode_textlist_event(fields.pb_entity_list)
        if ev.type == "CHG" or ev.type == "DCL" then
            s.entity_idx = ev.index
        end
    end
    if fields.pb_bp_list then
        local ev = core.explode_textlist_event(fields.pb_bp_list)
        if ev.type == "CHG" or ev.type == "DCL" then
            s.bp_idx = ev.index
        end
    end

    -- ── Placement actions ─────────────────────────────────────────────────

    if fields.pb_place_entity or fields.pb_place_entity_look then
        local defs = filtered_entity_prefabs(s.search, s.category)
        local def  = defs[math.max(1, math.min(#defs, s.entity_idx))]
        if def then
            local pos = fields.pb_place_entity and player_feet(name) or pos_ahead(name)
            local ok, msg = place_entity_prefab(name, def, pos)
            s.status = ok and ("✓ " .. msg) or ("✗ " .. msg)
        else
            s.status = "No prefab selected."
        end
    end

    if fields.pb_stamp or fields.pb_stamp_look then
        local ids = filtered_blueprints(s.search)
        local bp_id = ids[math.max(1, math.min(#ids, s.bp_idx))]
        if bp_id then
            local pos = fields.pb_stamp and player_feet(name) or pos_ahead(name)
            local ok, msg = stamp_blueprint(name, bp_id, pos)
            s.status = ok and ("✓ " .. msg) or ("✗ " .. msg)
        else
            s.status = "No blueprint selected."
        end
    end

    -- Re-render
    core.show_formspec(name, FORMNAME, build_formspec(name))
    return true
end)

-- ── Chat commands ───────────────────────────────────────────────────────────

core.register_chatcommand("prefabs", {
    params      = "[<search>]",
    description = "Open the Prefab Browser (GM only)",
    func = function(name, param)
        local ok, err = dnd3.open_prefab_browser(name, param)
        if not ok then return false, err end
        return true, "Prefab Browser opened."
    end,
})

core.register_chatcommand("dnd3_prefab_browser", {
    params      = "[<search>]",
    description = "Open the Prefab Browser (alias)",
    func = function(name, param)
        local ok, err = dnd3.open_prefab_browser(name, param)
        if not ok then return false, err end
        return true
    end,
})
