-- Character sheet system.
-- Ruleset-agnostic storage and computation pipeline for character sheets.
-- Sheets are keyed by a token_id string and stored as JSON in mod_storage.
--
-- A "sheet" is a flat key→value map of field values (ability scores, skill
-- ranks, HP, conditions, etc.) plus a __meta sub-table (ruleset_id, token_id).
--
-- Ruleset modules contribute two things:
--   1. Field definitions (via dnd3.register_sheet_field) describing each field
--      and its default value.
--   2. Compute hooks (via dnd3.character.register_compute_hook) that derive
--      calculated fields from raw fields each time dnd3.character.compute() is
--      called.
--
-- Compute hooks run in priority order (lower = earlier).
--
-- Public API:
--   dnd3.character.create(token_id, ruleset_id)     -> sheet
--   dnd3.character.get(token_id)                    -> sheet or nil
--   dnd3.character.delete(token_id)
--   dnd3.character.set(token_id, field, value)      -> sheet
--   dnd3.character.get_field(token_id, field)       -> value or nil
--   dnd3.character.compute(token_id)                -> sheet
--   dnd3.character.apply_condition(token_id, cond_id)
--   dnd3.character.remove_condition(token_id, cond_id)
--   dnd3.character.has_condition(token_id, cond_id) -> bool
--   dnd3.character.list()                           -> array of {token_id, ruleset_id}
--   dnd3.character.register_compute_hook(fn, priority)

dnd3.character = dnd3.character or {}

local STORAGE_PREFIX = "character."

local storage = core.get_mod_storage()

-- ─────────────────────────────────────────────────────────────────────────────
-- Compute hook registry
-- ─────────────────────────────────────────────────────────────────────────────

local compute_hooks = {}   -- array of {fn, priority}

--- Register a function called during dnd3.character.compute(token_id).
--- fn(sheet, ruleset_id) -- modifies sheet in-place (derived fields only)
--- @param fn function
--- @param priority number  lower runs first (default 50)
function dnd3.character.register_compute_hook(fn, priority)
	if type(fn) ~= "function" then
		error("[dnd3] character.register_compute_hook: fn must be a function")
	end
	compute_hooks[#compute_hooks + 1] = { fn = fn, priority = tonumber(priority) or 50 }
	table.sort(compute_hooks, function(a, b) return a.priority < b.priority end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function sheet_key(token_id)
	return STORAGE_PREFIX .. token_id
end

local function load_sheet(token_id)
	local raw = storage:get_string(sheet_key(token_id))
	if not raw or raw == "" then return nil end
	local ok, t = pcall(core.parse_json, raw)
	if not ok or type(t) ~= "table" then return nil end
	return t
end

local function save_sheet(token_id, sheet)
	local ok, encoded = pcall(core.write_json, sheet)
	if not ok then
		core.log("error", "[dnd3] character: failed to serialise sheet for token " .. tostring(token_id))
		return
	end
	storage:set_string(sheet_key(token_id), encoded)
end

-- Build default field values from all registered sheet fields for a ruleset.
local function default_sheet(token_id, ruleset_id)
	local fields = dnd3.get_sheet_fields(ruleset_id)
	local sheet = {
		__meta = { token_id = token_id, ruleset_id = ruleset_id },
		conditions = {},
	}
	for fid, fdef in pairs(fields) do
		if fdef.default ~= nil then
			sheet[fid] = fdef.default
		end
	end
	return sheet
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

--- Create a new character sheet for a token.  Overwrites any existing sheet.
--- @param token_id   string
--- @param ruleset_id string  must match a registered ruleset
--- @return table  the new sheet
function dnd3.character.create(token_id, ruleset_id)
	if not token_id or token_id == "" then
		error("[dnd3] character.create: token_id required")
	end
	local rs = dnd3.get_ruleset(ruleset_id)
	if not rs then
		error("[dnd3] character.create: unknown ruleset '" .. tostring(ruleset_id) .. "'")
	end
	local sheet = default_sheet(token_id, ruleset_id)
	save_sheet(token_id, sheet)
	return sheet
end

--- Retrieve an existing sheet.
--- @param token_id string
--- @return table|nil
function dnd3.character.get(token_id)
	return load_sheet(token_id)
end

--- Delete a character sheet.
--- @param token_id string
function dnd3.character.delete(token_id)
	storage:set_string(sheet_key(token_id), "")
end

--- Set a field value on a sheet and persist it.
--- @param token_id string
--- @param field    string  field id
--- @param value    any
--- @return table  the updated sheet
function dnd3.character.set(token_id, field, value)
	local sheet = load_sheet(token_id)
	if not sheet then
		error("[dnd3] character.set: no sheet for token '" .. tostring(token_id) .. "'")
	end
	sheet[field] = value
	save_sheet(token_id, sheet)
	return sheet
end

--- Get a single field value.
--- @param token_id string
--- @param field    string
--- @return any
function dnd3.character.get_field(token_id, field)
	local sheet = load_sheet(token_id)
	if not sheet then return nil end
	return sheet[field]
end

--- Run all compute hooks to derive calculated fields.
--- Results are persisted back.
--- @param token_id string
--- @return table  the fully computed sheet
function dnd3.character.compute(token_id)
	local sheet = load_sheet(token_id)
	if not sheet then
		error("[dnd3] character.compute: no sheet for token '" .. tostring(token_id) .. "'")
	end
	local ruleset_id = sheet.__meta and sheet.__meta.ruleset_id
	for _, hook in ipairs(compute_hooks) do
		local ok, err = pcall(hook.fn, sheet, ruleset_id)
		if not ok then
			core.log("warning", "[dnd3] character.compute hook error: " .. tostring(err))
		end
	end
	save_sheet(token_id, sheet)
	return sheet
end

--- Add a condition to a character sheet.
--- @param token_id string
--- @param cond_id  string  condition identifier (e.g. "frightened")
function dnd3.character.apply_condition(token_id, cond_id)
	local sheet = load_sheet(token_id)
	if not sheet then return end
	sheet.conditions = sheet.conditions or {}
	-- avoid duplicates
	for _, v in ipairs(sheet.conditions) do
		if v == cond_id then return end
	end
	sheet.conditions[#sheet.conditions + 1] = cond_id
	save_sheet(token_id, sheet)
end

--- Remove a condition from a character sheet.
--- @param token_id string
--- @param cond_id  string
function dnd3.character.remove_condition(token_id, cond_id)
	local sheet = load_sheet(token_id)
	if not sheet then return end
	sheet.conditions = sheet.conditions or {}
	local new = {}
	for _, v in ipairs(sheet.conditions) do
		if v ~= cond_id then new[#new + 1] = v end
	end
	sheet.conditions = new
	save_sheet(token_id, sheet)
end

--- Check whether a character has an active condition.
--- @param token_id string
--- @param cond_id  string
--- @return boolean
function dnd3.character.has_condition(token_id, cond_id)
	local sheet = load_sheet(token_id)
	if not sheet then return false end
	sheet.conditions = sheet.conditions or {}
	for _, v in ipairs(sheet.conditions) do
		if v == cond_id then return true end
	end
	return false
end

--- List all character sheets.
--- @return table  array of {token_id, ruleset_id}
function dnd3.character.list()
	local result = {}
	local prefix = STORAGE_PREFIX
	-- iterate all storage keys that start with our prefix
	-- dnd3 mod_storage doesn't expose an iterator, so we rely on the token
	-- registry maintained by the tokens subsystem.  Walk known tokens instead.
	if dnd3.token_list then
		for tid, _ in pairs(dnd3.token_list()) do
			local raw = storage:get_string(sheet_key(tid))
			if raw and raw ~= "" then
				local ok, t = pcall(core.parse_json, raw)
				if ok and t and t.__meta then
					result[#result + 1] = { token_id = tid, ruleset_id = t.__meta.ruleset_id }
				end
			end
		end
	end
	return result
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Chat commands
-- ─────────────────────────────────────────────────────────────────────────────

core.register_chatcommand("dnd3_char_create", {
	params = "<token_id> [ruleset_id]",
	description = "Create a character sheet for a token (GM)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied."
		end
		local tid, rid = param:match("^(%S+)%s*(%S*)$")
		if not tid or tid == "" then
			return false, "Usage: /dnd3_char_create <token_id> [ruleset_id]"
		end
		if not rid or rid == "" then
			rid = dnd3.session and dnd3.session.get_ruleset and dnd3.session.get_ruleset() or "dnd35"
		end
		local ok, err = pcall(dnd3.character.create, tid, rid)
		if not ok then return false, tostring(err) end
		local ok2 = pcall(dnd3.character.compute, tid)
		return true, string.format("Sheet created for token '%s' (ruleset: %s).", tid, rid)
	end,
})

core.register_chatcommand("dnd3_char_set", {
	params = "<token_id> <field> <value>",
	description = "Set a field on a character sheet (GM)",
	func = function(name, param)
		if not dnd3.can(name, "map_edit") then
			return false, "Permission denied."
		end
		local tid, field, value = param:match("^(%S+)%s+(%S+)%s+(.+)$")
		if not tid then
			return false, "Usage: /dnd3_char_set <token_id> <field> <value>"
		end
		-- try to coerce to number
		local v = tonumber(value) or value
		local ok, err = pcall(dnd3.character.set, tid, field, v)
		if not ok then return false, tostring(err) end
		pcall(dnd3.character.compute, tid)
		return true, string.format("'%s'.%s = %s", tid, field, tostring(v))
	end,
})

core.register_chatcommand("dnd3_char_show", {
	params = "<token_id>",
	description = "Show a character sheet",
	func = function(name, param)
		local tid = param:match("^%s*(.-)%s*$")
		if not tid or tid == "" then
			return false, "Usage: /dnd3_char_show <token_id>"
		end
		local sheet = dnd3.character.get(tid)
		if not sheet then
			return false, "No sheet found for token '" .. tid .. "'."
		end
		local lines = { string.format("=== %s (%s) ===", tid, (sheet.__meta or {}).ruleset_id or "?") }
		-- Sort keys for readability, skip __meta
		local keys = {}
		for k in pairs(sheet) do
			if k ~= "__meta" then keys[#keys + 1] = k end
		end
		table.sort(keys)
		for _, k in ipairs(keys) do
			local v = sheet[k]
			if type(v) == "table" then
				lines[#lines + 1] = string.format("  %s: [%s]", k, table.concat(v, ", "))
			else
				lines[#lines + 1] = string.format("  %s: %s", k, tostring(v))
			end
		end
		return true, table.concat(lines, "\n")
	end,
})

core.register_chatcommand("dnd3_char_condition", {
	params = "<token_id> <add|remove|list> [cond_id]",
	description = "Manage conditions on a character sheet",
	func = function(name, param)
		local tid, action, cond = param:match("^(%S+)%s+(%S+)%s*(%S*)$")
		if not tid then
			return false, "Usage: /dnd3_char_condition <token_id> <add|remove|list> [cond_id]"
		end
		if action == "list" then
			local sheet = dnd3.character.get(tid)
			if not sheet then return false, "No sheet for '" .. tid .. "'." end
			local conds = sheet.conditions or {}
			if #conds == 0 then return true, tid .. ": no active conditions." end
			return true, tid .. " conditions: " .. table.concat(conds, ", ")
		elseif action == "add" then
			if not dnd3.can(name, "map_edit") then return false, "Permission denied." end
			if not cond or cond == "" then return false, "cond_id required." end
			dnd3.character.apply_condition(tid, cond)
			return true, string.format("Condition '%s' applied to '%s'.", cond, tid)
		elseif action == "remove" then
			if not dnd3.can(name, "map_edit") then return false, "Permission denied." end
			if not cond or cond == "" then return false, "cond_id required." end
			dnd3.character.remove_condition(tid, cond)
			return true, string.format("Condition '%s' removed from '%s'.", cond, tid)
		else
			return false, "Unknown action '" .. action .. "'. Use add, remove, or list."
		end
	end,
})
