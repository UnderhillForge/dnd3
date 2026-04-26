-- dnd_combat: Turn-influenced combat system.
-- Handles initiative, attack rolls, damage, and saving throws.

-- ── Combat state ──────────────────────────────────────────────────────────

-- Active combats keyed by a unique id string.
dnd.combats = dnd.combats or {}

local function new_combat_id()
    return tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
end

-- ── Core mechanics ────────────────────────────────────────────────────────

--- Roll initiative for a combatant.
-- @param dex_score integer  Dexterity score of the combatant.
-- @return integer           Initiative result.
function dnd.roll_initiative(dex_score)
    return dnd.roll(20) + dnd.modifier(dex_score)
end

--- Resolve an attack roll against a target's Armour Class.
-- @param attacker_str integer  Attacker's STR (or DEX for finesse).
-- @param proficient   boolean  Whether the attacker is proficient.
-- @param proficiency  integer  Proficiency bonus.
-- @param target_ac    integer  Target's Armour Class.
-- @return boolean, integer     hit (true/false), roll result.
function dnd.attack_roll(attacker_str, proficient, proficiency, target_ac)
    local roll   = dnd.roll(20)
    local total  = roll + dnd.modifier(attacker_str)
    if proficient then total = total + (proficiency or 2) end
    if roll == 20 then return true, total, true  end  -- critical hit
    if roll == 1  then return false, total, false end  -- critical miss
    return total >= target_ac, total, false
end

--- Roll damage for a weapon.
-- @param damage_dice string  Dice expression, e.g. "1d8" or "2d6".
-- @param str_score   integer Attacker's STR score (added as modifier).
-- @return integer            Total damage dealt.
function dnd.roll_damage(damage_dice, str_score)
    local count, sides = damage_dice:match("(%d+)d(%d+)")
    count = tonumber(count) or 1
    sides = tonumber(sides) or 6
    local dmg = dnd.roll_multi(count, sides) + dnd.modifier(str_score or 10)
    return math.max(1, dmg)  -- minimum 1 damage
end

--- Resolve a saving throw.
-- @param ability_score integer  Relevant ability score.
-- @param proficient    boolean  Proficient in this saving throw?
-- @param proficiency   integer  Proficiency bonus.
-- @param dc            integer  Difficulty class.
-- @return boolean, integer      success, roll total.
function dnd.saving_throw(ability_score, proficient, proficiency, dc)
    local roll  = dnd.roll(20)
    local total = roll + dnd.modifier(ability_score)
    if proficient then total = total + (proficiency or 2) end
    return total >= dc, total
end

-- ── Combat session ────────────────────────────────────────────────────────

--- Start a new combat encounter between two players.
-- @param attacker_name string  Name of the attacking player.
-- @param defender_name string  Name of the defending player.
-- @return table                Combat session table.
function dnd.start_combat(attacker_name, defender_name)
    local attacker_char = dnd.get_character(attacker_name)
    local defender_char = dnd.get_character(defender_name)

    if not attacker_char then
        return nil, attacker_name .. " has no character."
    end
    if not defender_char then
        return nil, defender_name .. " has no character."
    end

    local id = new_combat_id()
    local combat = {
        id        = id,
        attacker  = attacker_name,
        defender  = defender_name,
        round     = 1,
        log       = {},
    }

    -- Roll initiative
    local ai = dnd.roll_initiative(attacker_char.scores.dex)
    local di = dnd.roll_initiative(defender_char.scores.dex)
    combat.first  = ai >= di and attacker_name or defender_name
    combat.second = ai >= di and defender_name or attacker_name

    table.insert(combat.log, string.format(
        "Round 1 — %s (init %d) goes first, then %s (init %d).",
        combat.first, math.max(ai,di), combat.second, math.min(ai,di)))

    dnd.combats[id] = combat
    dnd.emit("combat_started", { id = id, combat = combat })
    return combat
end

-- ── Commands ──────────────────────────────────────────────────────────────

minetest.register_chatcommand("dnd_attack", {
    params = "<target>",
    description = "Start a combat encounter with another player.",
    func = function(name, target)
        target = target:match("^%S+$")
        if not target then return false, "Usage: /dnd_attack <player>" end

        local combat, err = dnd.start_combat(name, target)
        if not combat then return false, err end

        local msg = string.format("⚔ Combat started (id %s)!  %s",
            combat.id, table.concat(combat.log, "  "))
        minetest.chat_send_player(name,   msg)
        minetest.chat_send_player(target, msg)
        return true, ""
    end,
})

minetest.log("action", "[dnd_combat] loaded")
