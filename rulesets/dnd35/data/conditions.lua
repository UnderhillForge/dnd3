-- D&D 3.5e SRD Conditions
-- Open Game Content, licensed under OGL v1.0a

dnd35 = dnd35 or {}
dnd35.CONDITIONS = {}

local function def(id, label, effects)
    dnd35.CONDITIONS[id] = {
        id      = id,
        label   = label,
        effects = effects,  -- table of {key, value} mechanical modifiers
    }
end

-- Ability Damaged: ability score temporarily reduced
def("ability_damaged", "Ability Damaged", {
    {key="note", value="Ability score temporarily reduced by damage amount; heals at 1/day naturally"},
})

-- Ability Drained: permanent reduction until magically restored
def("ability_drained", "Ability Drained", {
    {key="note", value="Permanent reduction to ability score until restored by magic (e.g. restoration)"},
})

-- Blinded
def("blinded", "Blinded", {
    {key="ac_penalty",           value=-2},
    {key="lose_dex_bonus_to_ac", value=true},
    {key="attack_penalty",       value=-2},
    {key="move_speed_fraction",  value=0.5},
    {key="opponents_have_total_concealment", value=true},
    {key="spot_disabled",        value=true},
})

-- Blown Away (wind/forced movement)
def("blown_away", "Blown Away", {
    {key="note", value="Knocked down and rolled 1d4x10 feet, taking 1d4 subdual per 10 feet"},
})

-- Checked (prevented from moving by wind)
def("checked", "Checked", {
    {key="note", value="Cannot move forward against wind; may move sideways or backward"},
})

-- Confused
def("confused", "Confused", {
    {key="note", value="Roll d100 each round: 1-10 attack caster, 11-20 act normally, 21-50 do nothing, 51-70 flee, 71-100 attack nearest"},
    {key="cannot_make_attacks_of_opportunity", value=true},
})

-- Cowering
def("cowering", "Cowering", {
    {key="ac_penalty",           value=-2},
    {key="lose_dex_bonus_to_ac", value=true},
    {key="cannot_act",           value=true},
})

-- Dazed
def("dazed", "Dazed", {
    {key="cannot_act",                       value=true},
    {key="can_defend_normally",              value=true},
    {key="cannot_make_attacks_of_opportunity", value=true},
})

-- Dazzled
def("dazzled", "Dazzled", {
    {key="attack_penalty", value=-1},
})

-- Dead
def("dead", "Dead", {
    {key="hp",         value=-10},
    {key="note",       value="Soul departed; cannot be raised without appropriate magic"},
})

-- Deafened
def("deafened", "Deafened", {
    {key="initiative_penalty",         value=-4},
    {key="spell_failure_verbal_chance", value=20},
    {key="listen_disabled",            value=true},
    {key="note",                       value="20% chance verbal-component spells fail"},
})

-- Disabled
def("disabled", "Disabled", {
    {key="hp",                   value=0},
    {key="can_act",              value=true},
    {key="note",                 value="Only one move or standard action per round; taking standard action deals 1 damage"},
})

-- Dying
def("dying", "Dying", {
    {key="hp_range",      value="-9 to -1"},
    {key="unconscious",   value=true},
    {key="note",          value="Lose 1 HP/round; DC 10 CON check to stabilize; others can stabilize with DC 15 Heal check"},
})

-- Energy Drained
def("energy_drained", "Energy Drained", {
    {key="negative_levels_penalty", value=-1},
    {key="note", value="Each negative level: -1 to all skill checks, -1 to all ability checks, -1 to attack rolls, -1 to saving throws, -5 max HP, -1 effective level for spells (per negative level)"},
})

-- Entangled
def("entangled", "Entangled", {
    {key="move_speed",                          value=0},
    {key="attack_penalty",                      value=-2},
    {key="str_check_dc",                        value=15},
    {key="escape_artist_dc",                    value=15},
    {key="spell_failure_concentration_dc_bonus", value=15},
    {key="note", value="Cannot move; -2 attack; must make Concentration check (DC 15) to cast spells"},
})

-- Exhausted
def("exhausted", "Exhausted", {
    {key="str_penalty", value=-6},
    {key="dex_penalty", value=-6},
    {key="move_speed_fraction", value=0.5},
    {key="note", value="Cannot charge or run; becomes fatigued if condition is removed"},
})

-- Fascinated
def("fascinated", "Fascinated", {
    {key="cannot_act",                 value=true},
    {key="reactive_skill_check_penalty", value=-4},
    {key="note", value="Stands/sits and watches the fascinating effect; potential threats grant new save"},
})

-- Fatigued
def("fatigued", "Fatigued", {
    {key="str_penalty",       value=-2},
    {key="dex_penalty",       value=-2},
    {key="cannot_charge",     value=true},
    {key="cannot_run",        value=true},
    {key="note", value="Becomes exhausted if fatigued again; rest 8 hours to remove"},
})

-- Flat-Footed
def("flat_footed", "Flat-Footed", {
    {key="lose_dex_bonus_to_ac", value=true},
    {key="note", value="Cannot use Combat Reflexes until first action taken in combat; rogues can sneak attack"},
})

-- Frightened
def("frightened", "Frightened", {
    {key="attack_penalty",    value=-2},
    {key="saving_throw_penalty", value=-2},
    {key="skill_check_penalty",  value=-2},
    {key="ability_check_penalty", value=-2},
    {key="flees_if_possible", value=true},
    {key="note", value="Flees from source of fear; may fight if cornered; stacks like shaken except flees"},
})

-- Grappling
def("grappling", "Grappling", {
    {key="lose_dex_bonus_to_ac", value=true},
    {key="note", value="No threatened squares; cannot make attacks of opportunity; -4 penalty to Dex for AC purposes per SRD grapple rules"},
})

-- Helpless
def("helpless", "Helpless", {
    {key="dex_score",            value=0},
    {key="lose_dex_bonus_to_ac", value=true},
    {key="melee_ac_penalty",     value=-4},
    {key="coup_de_grace_possible", value=true},
    {key="note", value="Dex treated as 0; coup de grace attacks are possible; melee attackers get +4 to attack"},
})

-- Incorporeal
def("incorporeal", "Incorporeal", {
    {key="immune_nonmagical_weapons",    value=true},
    {key="immune_natural_weapons",       value=true},
    {key="50pct_chance_ignore_magic",    value=true},
    {key="can_pass_through_objects",     value=true},
    {key="own_attacks_deal_half_damage_to_corporeal", value=true},
    {key="touch_attacks_deal_full_damage", value=true},
})

-- Invisible
def("invisible", "Invisible", {
    {key="impossible_to_see_without_special_ability", value=true},
    {key="attack_bonus",             value=2},
    {key="opponents_lose_dex_to_ac", value=true},
    {key="hide_check_bonus",         value=40},
    {key="note", value="+2 attack; opponents lose DEX bonus to AC; can still be heard/smelled"},
})

-- Knocked Down
def("knocked_down", "Knocked Down", {
    {key="prone",  value=true},
    {key="note",   value="See Prone condition"},
})

-- Nauseated
def("nauseated", "Nauseated", {
    {key="note", value="Can only take one move action per round; cannot attack, cast spells, concentrate, or use any special ability"},
})

-- Panicked
def("panicked", "Panicked", {
    {key="attack_penalty",      value=-2},
    {key="saving_throw_penalty", value=-2},
    {key="skill_check_penalty",  value=-2},
    {key="ability_check_penalty", value=-2},
    {key="flees_wildly",         value=true},
    {key="drops_held_items",     value=true},
    {key="note", value="Drops everything; flees at full speed from source; may cower if cornered"},
})

-- Paralyzed
def("paralyzed", "Paralyzed", {
    {key="str_score",       value=0},
    {key="dex_score",       value=0},
    {key="helpless",        value=true},
    {key="can_breathe",     value=true},
    {key="note", value="STR and DEX treated as 0; treated as helpless; coup de grace possible"},
})

-- Petrified
def("petrified", "Petrified", {
    {key="turned_to_stone",   value=true},
    {key="unconscious",       value=true},
    {key="note", value="Turned to stone; treated as unconscious; still alive; must be reversed before raise dead"},
})

-- Pinned
def("pinned", "Pinned", {
    {key="helpless",              value=true},
    {key="note", value="Held immobile in grapple; can still try to break free; takes -4 penalty to Dex"},
})

-- Prone
def("prone", "Prone", {
    {key="melee_attack_penalty",   value=-4},
    {key="ranged_attack_penalty",  value=-4},
    {key="melee_attack_bonus_vs",  value=4},
    {key="ranged_attack_bonus_vs", value=-4},
    {key="note", value="-4 melee attacks; -4 vs ranged; melee attackers get +4; ranged attackers take -4; standing up is move action"},
})

-- Shaken
def("shaken", "Shaken", {
    {key="attack_penalty",       value=-2},
    {key="saving_throw_penalty", value=-2},
    {key="skill_check_penalty",  value=-2},
    {key="ability_check_penalty", value=-2},
})

-- Sickened
def("sickened", "Sickened", {
    {key="attack_penalty",        value=-2},
    {key="weapon_damage_penalty", value=-2},
    {key="saving_throw_penalty",  value=-2},
    {key="skill_check_penalty",   value=-2},
    {key="ability_check_penalty", value=-2},
})

-- Stable
def("stable", "Stable", {
    {key="unconscious",         value=true},
    {key="no_longer_dying",     value=true},
    {key="note", value="No longer losing HP; regains consciousness in 1 hour on DC 10 CON check"},
})

-- Staggered
def("staggered", "Staggered", {
    {key="hp",                   value=0},
    {key="note", value="Only one move or standard action per round (same as disabled when at exactly 0 HP)"},
})

-- Stunned
def("stunned", "Stunned", {
    {key="cannot_act",            value=true},
    {key="lose_dex_bonus_to_ac",  value=true},
    {key="ac_penalty",            value=-2},
    {key="drops_held_items",      value=true},
    {key="cannot_make_attacks_of_opportunity", value=true},
})

-- Turned
def("turned", "Turned", {
    {key="flees_from_cleric",    value=true},
    {key="cannot_attack",        value=true},
    {key="note", value="Undead creature flees cleric; if cornered, cowers; duration: 10 rounds"},
})

-- Unconscious
def("unconscious", "Unconscious", {
    {key="hp_range",             value="<= 0"},
    {key="helpless",             value=true},
    {key="lose_dex_bonus_to_ac", value=true},
    {key="note", value="Helpless; HP at -1 to -9 = dying; HP at 0 = disabled; HP at -10 = dead"},
})

-- Delegates to dnd3.character core API which owns condition storage.

--- Check if a token has an active condition.
--- @param token_id    string
--- @param condition_id string
--- @return boolean
function dnd35.has_condition(token_id, condition_id)
    return dnd3.character.has_condition(token_id, condition_id)
end

--- Apply a condition to a token (validates against known SRD conditions).
--- @param token_id    string
--- @param condition_id string
--- @return boolean, string|nil  success, error_message
function dnd35.apply_condition(token_id, condition_id)
    if not dnd35.CONDITIONS[condition_id] then
        return false, "unknown condition: " .. tostring(condition_id)
    end
    dnd3.character.apply_condition(token_id, condition_id)
    return true
end

--- Remove a condition from a token.
--- @param token_id    string
--- @param condition_id string
function dnd35.remove_condition(token_id, condition_id)
    dnd3.character.remove_condition(token_id, condition_id)
end

--- Return an array of active condition ids for a token.
--- @param token_id string
--- @return table
function dnd35.get_conditions(token_id)
    local sheet = dnd3.character.get(token_id)
    if not sheet then return {} end
    local result = {}
    for _, cid in ipairs(sheet.conditions or {}) do
        table.insert(result, cid)
    end
    return result
end
