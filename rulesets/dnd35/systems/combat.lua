-- D&D 3.5e SRD Combat System
-- Open Game Content, licensed under OGL v1.0a
--
-- Handles attack resolution, damage application, and HP state management.
-- Registers a compute hook (priority 20) that derives combat bonuses from the
-- base ability/class values computed at priority 10.
--
-- ── New raw sheet fields (registered below) ───────────────────────────────────
--   hp_current       number   current hit points
--   hp_nonlethal     number   nonlethal damage accumulated
--   hp_stable        boolean  true when a dying character has been stabilised
--   attack_misc      number   miscellaneous attack bonus (feats, magic, etc.)
--   damage_misc      number   miscellaneous damage bonus
--   equipped_weapon  string   weapon ID from dnd35.WEAPONS
--   equipped_offhand string   off-hand weapon ID (two-weapon fighting)
--   size             string   creature size category (default "medium")
--   feats            table    array of feat IDs (used for TWF penalty detection)
--
-- ── Derived fields written by compute hook (priority 20) ─────────────────────
--   melee_attack_bonus       total melee attack modifier
--   ranged_attack_bonus      total ranged attack modifier
--   melee_damage_bonus       STR mod + damage_misc (one-hand grip)
--   two_handed_damage_bonus  floor(STR×1.5) + damage_misc
--   offhand_damage_bonus     floor(STR×0.5) + damage_misc (negative STR kept)
--   hp_status                "alive"|"disabled"|"dying"|"dead"|"stable"
--
-- ── Public API ───────────────────────────────────────────────────────────────
--   dnd35.attack(attacker_id, target_id, opts)       -> result
--   dnd35.full_attack(attacker_id, target_id, opts)  -> { result, ... }
--   dnd35.apply_damage(token_id, amount, dmg_type, nonlethal) -> new hp_current
--   dnd35.heal(token_id, amount)                     -> new hp_current
--   dnd35.heal_nonlethal(token_id, amount)           -> new hp_nonlethal
--   dnd35.stabilize(token_id)                        -> ok, err
--   dnd35.hp_status(sheet)                           -> string
--
-- ── opts table for attack() ───────────────────────────────────────────────────
--   weapon_id          string   key from dnd35.WEAPONS (default: equipped_weapon)
--   attack_bonus_misc  number   situational bonus (flanking +2, feat, etc.)
--   damage_bonus_misc  number   situational damage bonus
--   is_touch           boolean  ignore armor/shield/natural AC; use ac_touch
--   is_flat_footed     boolean  target loses DEX to AC; use ac_flat_footed
--   is_two_handed      boolean  grip overrides weapon.hands for damage bonus
--   is_offhand         boolean  off-hand attack (half STR to damage)
--   iterative_penalty  number   cumulative iterative attack penalty (0/-5/-10/-15)
--   sneak_attack_dice  number   number of extra d6 sneak attack dice

dnd35 = dnd35 or {}

-- ── Sheet field registration ──────────────────────────────────────────────────

local COMBAT_FIELDS = {
	{ id="hp_current",      default=0,             type="number"  },
	{ id="hp_nonlethal",    default=0,             type="number"  },
	{ id="hp_stable",       default=false,         type="boolean" },
	{ id="attack_misc",     default=0,             type="number"  },
	{ id="damage_misc",     default=0,             type="number"  },
	{ id="equipped_weapon", default="unarmed_strike", type="string" },
	{ id="equipped_offhand",default="",            type="string"  },
	{ id="size",            default="medium",      type="string"  },
	{ id="feats",           default={},            type="table"   },
}
for _, f in ipairs(COMBAT_FIELDS) do
	dnd3.register_sheet_field("dnd35", f)
end

-- ── Size attack modifier table (SRD Table 8-6) ───────────────────────────────
-- Used for both attack rolls and AC.
local SIZE_MOD = {
	fine        =  8,
	diminutive  =  4,
	tiny        =  2,
	small       =  1,
	medium      =  0,
	large       = -1,
	huge        = -2,
	gargantuan  = -4,
	colossal    = -8,
}

-- ── HP status ────────────────────────────────────────────────────────────────

--- Returns the HP status string for a character sheet.
--- Dead threshold: hp ≤ –10  (SRD uses –10 for most; strict SRD: –CON score)
function dnd35.hp_status(sheet)
	local hp     = tonumber(sheet.hp_current) or 0
	local stable = sheet.hp_stable or false
	local con    = tonumber(sheet.con) or 10
	local death  = math.min(-10, -con)   -- –10 or –CON, whichever is lower
	if hp <= death then
		return "dead"
	elseif hp < 0 then
		return stable and "stable" or "dying"
	elseif hp == 0 then
		return "disabled"
	else
		return "alive"
	end
end

-- ── Compute hook: combat-derived fields (priority 20) ────────────────────────
-- Runs after the base compute hook (priority 10) which sets bab, str_mod, etc.

dnd3.character.register_compute_hook(function(sheet)
	local bab      = tonumber(sheet.bab)     or 0
	local str_mod  = tonumber(sheet.str_mod) or 0
	local dex_mod  = tonumber(sheet.dex_mod) or 0
	-- size_modifier is the integer field from character_compute (raw input: +1 small, -1 large)
	-- We also look at sheet.size (string) for SIZE_MOD lookup; prefer SIZE_MOD when available.
	local size_str  = sheet.size or "medium"
	local size_atk  = SIZE_MOD[size_str] or (tonumber(sheet.size_modifier) or 0)
	local atk_misc  = tonumber(sheet.attack_misc) or 0
	local dmg_misc  = tonumber(sheet.damage_misc) or 0

	sheet.melee_attack_bonus     = bab + str_mod + size_atk + atk_misc
	sheet.ranged_attack_bonus    = bab + dex_mod + size_atk + atk_misc

	-- Strength damage bonus variants
	sheet.melee_damage_bonus     = str_mod + dmg_misc
	sheet.two_handed_damage_bonus = math.floor(str_mod * 1.5) + dmg_misc
	-- Off-hand: positive STR gets halved; negative STR applies in full (SRD p. 140)
	if str_mod >= 0 then
		sheet.offhand_damage_bonus = math.floor(str_mod * 0.5) + dmg_misc
	else
		sheet.offhand_damage_bonus = str_mod + dmg_misc
	end

	-- HP status
	sheet.hp_status = dnd35.hp_status(sheet)
end, 20)

-- ── Internal helpers ─────────────────────────────────────────────────────────

local function has_feat(sheet, feat_id)
	local feats = sheet.feats or {}
	for _, fid in ipairs(feats) do
		if fid == feat_id then return true end
	end
	return false
end

local function resolve_weapon(sheet, weapon_id)
	local wid = weapon_id or sheet.equipped_weapon or "unarmed_strike"
	local w   = dnd35.WEAPONS and dnd35.WEAPONS[wid]
	if not w then
		wid = "unarmed_strike"
		w   = dnd35.WEAPONS and dnd35.WEAPONS["unarmed_strike"]
	end
	return wid, w
end

-- ── Attack resolution ────────────────────────────────────────────────────────

--- Resolve a single attack roll against a target.
--- Returns a result table; never errors.
function dnd35.attack(attacker_id, target_id, opts)
	opts = opts or {}
	local log = {}

	local atk_sheet = dnd3.character.get(attacker_id)
	local def_sheet = dnd3.character.get(target_id)
	if not atk_sheet then
		return { hit=false, log={"attacker " .. tostring(attacker_id) .. " has no character sheet"} }
	end
	if not def_sheet then
		return { hit=false, log={"target " .. tostring(target_id) .. " has no character sheet"} }
	end

	-- ── Weapon ───────────────────────────────────────────────────────────────
	local weapon_id, weapon = resolve_weapon(atk_sheet, opts.weapon_id)
	if not weapon then
		return { hit=false, log={"weapon not found: " .. tostring(opts.weapon_id)} }
	end

	local is_ranged     = (weapon.wtype == "ranged")
	local is_thrown     = (weapon.wtype == "thrown")
	local is_offhand    = opts.is_offhand    or false
	local is_two_handed = opts.is_two_handed or (weapon.hands == "two_hand")
	local iter_penalty  = opts.iterative_penalty or 0

	-- ── Attack bonus ─────────────────────────────────────────────────────────
	local base_atk
	if is_ranged or is_thrown then
		base_atk = tonumber(atk_sheet.ranged_attack_bonus) or 0
	else
		base_atk = tonumber(atk_sheet.melee_attack_bonus)  or 0
	end
	local misc_atk  = opts.attack_bonus_misc or 0
	local total_atk = base_atk + misc_atk + iter_penalty
	table.insert(log, ("Attack bonus: %+d (base %+d, misc %+d, iter %d)"):format(
		total_atk, base_atk, misc_atk, iter_penalty))

	-- ── Target AC ────────────────────────────────────────────────────────────
	local target_ac
	if opts.is_touch then
		target_ac = tonumber(def_sheet.ac_touch)        or 10
	elseif opts.is_flat_footed then
		target_ac = tonumber(def_sheet.ac_flat_footed)  or 10
	else
		target_ac = tonumber(def_sheet.ac)              or 10
	end
	table.insert(log, ("Target AC: %d"):format(target_ac))

	-- ── d20 roll ─────────────────────────────────────────────────────────────
	local d20      = dnd3.roll("1d20", { token_id = attacker_id }).total
	local atk_total = d20 + total_atk
	table.insert(log, ("d20: %d → attack total: %d"):format(d20, atk_total))

	-- ── Hit determination ────────────────────────────────────────────────────
	local nat_miss    = (d20 == 1)
	local nat_hit     = (d20 == 20)
	local crit_range  = weapon.crit_range or 20
	local crit_threat = (d20 >= crit_range)
	local hit         = nat_hit or (not nat_miss and atk_total >= target_ac)

	-- ── Critical confirmation ─────────────────────────────────────────────────
	local crit_confirmed = false
	if crit_threat and hit then
		local conf_d20 = dnd3.roll("1d20", { token_id = attacker_id }).total
		local conf_total = conf_d20 + total_atk
		crit_confirmed = (conf_total >= target_ac)
		table.insert(log, ("Crit confirm: %d+(%+d)=%d vs %d — %s"):format(
			conf_d20, total_atk, conf_total, target_ac,
			crit_confirmed and "CONFIRMED" or "not confirmed"))
	end

	-- ── Damage ───────────────────────────────────────────────────────────────
	local total_damage  = 0
	local damage_expr   = ""
	local sneak_damage  = 0
	local sneak_expr    = ""

	if hit then
		-- Weapon dice (size-adjusted)
		local size      = atk_sheet.size or "medium"
		local dice_expr = dnd35.weapon_damage_for_size(weapon_id, size) or "1d3"
		if dice_expr == "-" then dice_expr = "0" end

		-- Ability damage bonus
		local dmg_bonus
		if is_ranged then
			-- Ranged: no STR (composite bow STR bonus handled as attack_misc)
			dmg_bonus = 0
		elseif is_offhand then
			dmg_bonus = tonumber(atk_sheet.offhand_damage_bonus) or 0
		elseif is_two_handed then
			dmg_bonus = tonumber(atk_sheet.two_handed_damage_bonus) or 0
		else
			dmg_bonus = tonumber(atk_sheet.melee_damage_bonus) or 0
		end
		dmg_bonus = dmg_bonus + (opts.damage_bonus_misc or 0)

		-- Roll dice
		local base_roll  = dnd3.roll(dice_expr, { token_id = attacker_id }).total
		local crit_mult  = crit_confirmed and (weapon.crit_mult or 2) or 1
		-- SRD: crits multiply weapon dice only; bonus damage added once
		total_damage = math.max(1, base_roll * crit_mult + dmg_bonus)
		damage_expr  = ("%s×%d%s%d"):format(
			dice_expr, crit_mult, dmg_bonus >= 0 and "+" or "", dmg_bonus)
		table.insert(log, ("Damage: %d (%s)"):format(total_damage, damage_expr))

		-- Sneak attack
		local sneak_dice = opts.sneak_attack_dice or 0
		if sneak_dice > 0 then
			sneak_damage = dnd3.roll(sneak_dice .. "d6", { token_id = attacker_id }).total
			sneak_expr   = sneak_dice .. "d6"
			total_damage = total_damage + sneak_damage
			table.insert(log, ("Sneak attack: +%d (%s)"):format(sneak_damage, sneak_expr))
		end
	end

	local outcome
	if nat_miss then
		outcome = "MISS (natural 1)"
	elseif not hit then
		outcome = "MISS"
	elseif crit_confirmed then
		outcome = "CRITICAL HIT"
	else
		outcome = "HIT"
	end
	table.insert(log, outcome)

	return {
		hit            = hit,
		roll           = d20,
		total_attack   = atk_total,
		ac_used        = target_ac,
		crit_threat    = crit_threat,
		crit_confirmed = crit_confirmed,
		damage         = total_damage,
		damage_roll    = damage_expr,
		damage_type    = weapon.damage_type,
		sneak_damage   = sneak_damage,
		sneak_roll     = sneak_expr,
		outcome        = outcome,
		log            = log,
	}
end

--- Resolve a full attack action (all iterative attacks + optional TWF offhand).
--- Returns an array of individual result tables, each with an added `hand` field.
---
--- Extra opts:
---   offhand_id  string   weapon ID for the off-hand (triggers TWF)
---   is_twf      boolean  explicitly enable TWF even if offhand_id matches equipped_offhand
function dnd35.full_attack(attacker_id, target_id, opts)
	opts = opts or {}
	local atk_sheet = dnd3.character.get(attacker_id)
	if not atk_sheet then return {} end

	local bab = tonumber(atk_sheet.bab) or 0
	local results = {}

	-- Iterative attacks (one per 5 BAB above 1st)
	local penalties = { 0 }
	if bab >= 6  then table.insert(penalties, -5)  end
	if bab >= 11 then table.insert(penalties, -10) end
	if bab >= 16 then table.insert(penalties, -15) end

	-- TWF primary-hand penalty
	local offhand_id = opts.offhand_id or
		(atk_sheet.equipped_offhand ~= "" and atk_sheet.equipped_offhand or nil)
	local is_twf = opts.is_twf or (offhand_id ~= nil and offhand_id ~= "")
	local twf_primary_pen = 0
	local twf_offhand_pen = 0
	if is_twf then
		local has_twf = has_feat(atk_sheet, "two_weapon_fighting")
		local offhand_w = offhand_id and dnd35.WEAPONS and dnd35.WEAPONS[offhand_id]
		local light_offhand = offhand_w and (offhand_w.hands == "light")
		-- SRD TWF penalties (Table 8-7):
		--                    Normal  Light off-hand
		-- Primary penalty:     -6         -4
		-- Off-hand penalty:    -10        -8
		-- With TWF feat:
		-- Primary penalty:     -4         -2
		-- Off-hand penalty:    -4         -2  (same both hands with feat)
		if has_twf and light_offhand then
			twf_primary_pen = -2; twf_offhand_pen = -2
		elseif has_twf then
			twf_primary_pen = -4; twf_offhand_pen = -4
		elseif light_offhand then
			twf_primary_pen = -4; twf_offhand_pen = -8
		else
			twf_primary_pen = -6; twf_offhand_pen = -10
		end
	end

	for i, pen in ipairs(penalties) do
		local iter_opts = {}
		for k, v in pairs(opts) do iter_opts[k] = v end
		iter_opts.iterative_penalty = (opts.iterative_penalty or 0) + pen + twf_primary_pen
		iter_opts.is_offhand = false
		local r = dnd35.attack(attacker_id, target_id, iter_opts)
		r.attack_number = i
		r.hand = "primary"
		table.insert(results, r)
	end

	-- Off-hand attack (only one at BAB, regardless of iterative count)
	if is_twf and offhand_id then
		local off_opts = {}
		for k, v in pairs(opts) do off_opts[k] = v end
		off_opts.weapon_id         = offhand_id
		off_opts.is_offhand        = true
		off_opts.iterative_penalty = twf_offhand_pen
		local r = dnd35.attack(attacker_id, target_id, off_opts)
		r.attack_number = #results + 1
		r.hand = "offhand"
		table.insert(results, r)
	end

	return results
end

-- ── HP management ────────────────────────────────────────────────────────────

--- Apply damage to a token.  Returns new hp_current, or nil if no sheet.
--- @param token_id  string
--- @param amount    number  damage amount (positive integer)
--- @param dmg_type  string  damage type string (informational only, e.g. "S","fire")
--- @param nonlethal boolean if true, adds to hp_nonlethal instead of subtracting hp
function dnd35.apply_damage(token_id, amount, dmg_type, nonlethal)
	local sheet = dnd3.character.get(token_id)
	if not sheet then return nil end
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	if amount == 0 then return tonumber(sheet.hp_current) or 0 end

	if nonlethal then
		local nl = (tonumber(sheet.hp_nonlethal) or 0) + amount
		dnd3.character.set(token_id, "hp_nonlethal", nl)
	else
		local hp = (tonumber(sheet.hp_current) or 0) - amount
		dnd3.character.set(token_id, "hp_current", hp)
		-- Taking lethal damage clears stable status
		dnd3.character.set(token_id, "hp_stable", false)
	end

	dnd3.character.compute(token_id)
	local new_sheet = dnd3.character.get(token_id)
	return new_sheet and (tonumber(new_sheet.hp_current) or 0)
end

--- Restore hit points.  Capped at hp_max.  Returns new hp_current.
function dnd35.heal(token_id, amount)
	local sheet = dnd3.character.get(token_id)
	if not sheet then return nil end
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	local hp_max = tonumber(sheet.hp_max) or 0
	local hp     = math.min(hp_max, (tonumber(sheet.hp_current) or 0) + amount)
	dnd3.character.set(token_id, "hp_current", hp)
	-- Healing wakes a stable or disabled character; not a dying one without positive hp
	dnd3.character.compute(token_id)
	local new_sheet = dnd3.character.get(token_id)
	return new_sheet and (tonumber(new_sheet.hp_current) or 0)
end

--- Reduce accumulated nonlethal damage.  Returns new hp_nonlethal.
function dnd35.heal_nonlethal(token_id, amount)
	local sheet = dnd3.character.get(token_id)
	if not sheet then return nil end
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	local nl = math.max(0, (tonumber(sheet.hp_nonlethal) or 0) - amount)
	dnd3.character.set(token_id, "hp_nonlethal", nl)
	dnd3.character.compute(token_id)
	local new_sheet = dnd3.character.get(token_id)
	return new_sheet and (tonumber(new_sheet.hp_nonlethal) or 0)
end

--- Mark a dying character as stable (no more death saves each round).
function dnd35.stabilize(token_id)
	local sheet = dnd3.character.get(token_id)
	if not sheet then return false, "token has no character sheet" end
	if dnd35.hp_status(sheet) ~= "dying" then
		return false, "character is not dying (status: " .. dnd35.hp_status(sheet) .. ")"
	end
	dnd3.character.set(token_id, "hp_stable", true)
	dnd3.character.compute(token_id)
	return true
end
