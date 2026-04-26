-- Combat state: turn action economy and combat round tracking.
-- Ruleset-agnostic.  Rulesets set per-token AoO limits via set_aoo_limit().
--
-- Public API:
--   dnd3.combat.is_active()                        -> boolean
--   dnd3.combat.start()                            start combat, reset round to 1
--   dnd3.combat.end_combat()                       clear all combat state
--   dnd3.combat.get_round()                        -> number
--   dnd3.combat.next_round()                       -> new round number
--   dnd3.combat.turn_start(token_id)               reset action budget for token
--   dnd3.combat.use_action(token_id, action_type)  -> ok, err
--   dnd3.combat.actions_remaining(token_id)        -> table  (copy)
--   dnd3.combat.use_aoo(token_id)                  -> ok, err
--   dnd3.combat.aoo_remaining(token_id)            -> number
--   dnd3.combat.set_aoo_limit(token_id, n)         override AoO limit this round
--
-- action_type values: "standard", "move", "swift", "free", "full_round"
-- full_round consumes both the standard and move slot simultaneously.

dnd3.combat = dnd3.combat or {}

dnd3._state.combat = dnd3._state.combat or {
	active     = false,
	round      = 0,
	turns      = {},    -- [token_id] -> budget table
	aoo_limits = {},    -- [token_id] -> max AoO per round (overrides default of 1)
}

local COMBAT = dnd3._state.combat

local DEFAULT_FREE = 3   -- reasonable cap on free actions per turn

local VALID_ACTIONS = {
	standard   = true,
	move       = true,
	swift      = true,
	free       = true,
	full_round = true,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Combat lifecycle
-- ─────────────────────────────────────────────────────────────────────────────

function dnd3.combat.is_active()
	return COMBAT.active
end

function dnd3.combat.start()
	COMBAT.active     = true
	COMBAT.round      = 1
	COMBAT.turns      = {}
	COMBAT.aoo_limits = {}
	core.log("action", "[dnd3] combat started (round 1)")
end

function dnd3.combat.end_combat()
	COMBAT.active     = false
	COMBAT.round      = 0
	COMBAT.turns      = {}
	COMBAT.aoo_limits = {}
	core.log("action", "[dnd3] combat ended")
end

function dnd3.combat.get_round()
	return COMBAT.round
end

function dnd3.combat.next_round()
	if not COMBAT.active then
		return false, "combat is not active"
	end
	COMBAT.round = COMBAT.round + 1
	core.log("action", "[dnd3] combat round " .. COMBAT.round)
	return COMBAT.round
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Turn action budget
-- ─────────────────────────────────────────────────────────────────────────────

--- Reset a token's action budget for the start of its turn.
function dnd3.combat.turn_start(token_id)
	local aoo_limit = COMBAT.aoo_limits[token_id] or 1
	COMBAT.turns[token_id] = {
		standard   = 1,
		move       = 1,
		swift      = 1,
		free       = DEFAULT_FREE,
		full_round = 1,
		aoo        = aoo_limit,
	}
	return COMBAT.turns[token_id]
end

--- Consume one action of the given type for a token.
--- full_round requires both standard and move to be available; consumes both.
--- Returns true on success, false + error string on failure.
function dnd3.combat.use_action(token_id, action_type)
	if not VALID_ACTIONS[action_type] then
		return false, "unknown action type: " .. tostring(action_type)
	end

	local t = COMBAT.turns[token_id]
	if not t then
		-- Auto-initialise if turn_start was not explicitly called.
		dnd3.combat.turn_start(token_id)
		t = COMBAT.turns[token_id]
	end

	if action_type == "full_round" then
		if t.standard < 1 or t.move < 1 then
			return false, "full-round action requires both standard and move actions"
		end
		t.standard = 0
		t.move     = 0
		return true
	end

	if t[action_type] <= 0 then
		return false, action_type .. " action already spent this turn"
	end
	t[action_type] = t[action_type] - 1
	return true
end

--- Returns a copy of the token's current action budget, or nil.
function dnd3.combat.actions_remaining(token_id)
	local t = COMBAT.turns[token_id]
	if not t then return nil end
	local out = {}
	for k, v in pairs(t) do out[k] = v end
	return out
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Attacks of Opportunity
-- ─────────────────────────────────────────────────────────────────────────────

--- Consume one AoO for a token.  Default limit = 1 per round (DEX mod if
--- Combat Reflexes feat — rulesets should call set_aoo_limit accordingly).
function dnd3.combat.use_aoo(token_id)
	local t = COMBAT.turns[token_id]
	if not t then
		dnd3.combat.turn_start(token_id)
		t = COMBAT.turns[token_id]
	end
	if t.aoo <= 0 then
		return false, "no attacks of opportunity remaining this round"
	end
	t.aoo = t.aoo - 1
	return true
end

function dnd3.combat.aoo_remaining(token_id)
	local t = COMBAT.turns[token_id]
	if not t then return 0 end
	return t.aoo
end

--- Override the AoO limit for a token (call from a compute hook or feat handler).
function dnd3.combat.set_aoo_limit(token_id, n)
	n = math.max(0, math.floor(n))
	COMBAT.aoo_limits[token_id] = n
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Chat commands (DM-only)
-- ─────────────────────────────────────────────────────────────────────────────

core.register_chatcommand("dnd3_combat_start", {
	description = "Start combat (round 1)",
	privs = {},
	func = function(name)
		if not dnd3.can(name, "dm_tools") then
			return false, "DM access required"
		end
		dnd3.combat.start()
		return true, "Combat started — round 1"
	end,
})

core.register_chatcommand("dnd3_combat_end", {
	description = "End combat",
	privs = {},
	func = function(name)
		if not dnd3.can(name, "dm_tools") then
			return false, "DM access required"
		end
		dnd3.combat.end_combat()
		return true, "Combat ended"
	end,
})

core.register_chatcommand("dnd3_next_round", {
	description = "Advance to the next combat round",
	privs = {},
	func = function(name)
		if not dnd3.can(name, "dm_tools") then
			return false, "DM access required"
		end
		local round, err = dnd3.combat.next_round()
		if not round then return false, err end
		return true, "Round " .. round
	end,
})
