-- D&D 3.5e SRD Classes
-- Open Game Content, licensed under OGL v1.0a
--
-- BAB progressions (base attack bonus per level):
--   good    = level * 1         (Fighter, Barbarian, Paladin, Ranger)
--   average = floor(level * 3/4) (Bard, Cleric, Druid, Monk, Rogue)
--   poor    = floor(level / 2)  (Sorcerer, Wizard)
--
-- Save progressions (base save bonus per level):
--   good = 2 + floor(level / 2)
--   poor = floor(level / 3)

dnd35 = dnd35 or {}
dnd35.CLASSES = {}

local function class(def)
    dnd35.CLASSES[def.id] = def
end

-- ── BAB / Save computation helpers ─────────────────────────────────────────

function dnd35.bab(progression, level)
    if progression == "good" then
        return level
    elseif progression == "average" then
        return math.floor(level * 3 / 4)
    else -- "poor"
        return math.floor(level / 2)
    end
end

function dnd35.base_save(progression, level)
    if progression == "good" then
        return 2 + math.floor(level / 2)
    else -- "poor"
        return math.floor(level / 3)
    end
end

-- ── Class Definitions ───────────────────────────────────────────────────────

class({
    id             = "barbarian",
    label          = "Barbarian",
    alignment      = "Any nonlawful",
    hit_die        = 12,
    bab            = "good",
    fort_save      = "good",
    ref_save       = "poor",
    will_save      = "poor",
    skill_points   = 4,
    spell_ability  = nil,
    class_skills   = {
        "climb", "craft", "handle_animal", "intimidate",
        "jump", "listen", "ride", "survival", "swim",
    },
    features = {
        [1]  = {"fast_movement", "illiteracy", "rage"},
        [2]  = {"uncanny_dodge"},
        [3]  = {"trap_sense_1"},
        [4]  = {"rage_2_day"},
        [5]  = {"improved_uncanny_dodge"},
        [7]  = {"damage_reduction_1"},
        [10] = {"damage_reduction_2"},
        [11] = {"greater_rage"},
        [13] = {"damage_reduction_3"},
        [14] = {"indomitable_will"},
        [16] = {"damage_reduction_4"},
        [17] = {"tireless_rage"},
        [19] = {"damage_reduction_5"},
        [20] = {"mighty_rage"},
    },
})

class({
    id             = "bard",
    label          = "Bard",
    alignment      = "Any nonlawful",
    hit_die        = 6,
    bab            = "average",
    fort_save      = "poor",
    ref_save       = "good",
    will_save      = "good",
    skill_points   = 6,
    spell_ability  = "cha",
    class_skills   = {
        "appraise", "balance", "bluff", "climb", "concentration", "craft",
        "decipher_script", "diplomacy", "disguise", "escape_artist",
        "gather_information", "hide", "jump", "knowledge", "listen",
        "move_silently", "perform", "profession", "sense_motive",
        "sleight_of_hand", "speak_language", "spellcraft", "swim",
        "tumble", "use_magic_device",
    },
    features = {
        [1]  = {"bardic_music", "bardic_knowledge", "countersong",
                "fascinate", "inspire_courage_1"},
        [3]  = {"inspire_competence"},
        [6]  = {"suggestion"},
        [8]  = {"inspire_courage_2"},
        [9]  = {"inspire_greatness"},
        [12] = {"song_of_freedom"},
        [14] = {"inspire_courage_3"},
        [15] = {"inspire_heroics"},
        [18] = {"mass_suggestion"},
        [20] = {"inspire_courage_4"},
    },
})

class({
    id             = "cleric",
    label          = "Cleric",
    alignment      = "Within one step of deity",
    hit_die        = 8,
    bab            = "average",
    fort_save      = "good",
    ref_save       = "poor",
    will_save      = "good",
    skill_points   = 2,
    spell_ability  = "wis",
    class_skills   = {
        "concentration", "craft", "diplomacy", "heal", "knowledge",
        "profession", "spellcraft",
    },
    features = {
        [1] = {"turn_or_rebuke_undead", "domains"},
    },
})

class({
    id             = "druid",
    label          = "Druid",
    alignment      = "Neutral (must include neutral component)",
    hit_die        = 8,
    bab            = "average",
    fort_save      = "good",
    ref_save       = "poor",
    will_save      = "good",
    skill_points   = 4,
    spell_ability  = "wis",
    class_skills   = {
        "concentration", "craft", "diplomacy", "handle_animal", "heal",
        "knowledge", "listen", "profession", "ride", "spellcraft",
        "spot", "survival", "swim",
    },
    features = {
        [1]  = {"animal_companion", "nature_sense", "wild_empathy"},
        [2]  = {"woodland_stride"},
        [3]  = {"trackless_step"},
        [4]  = {"resist_natures_lure"},
        [5]  = {"wild_shape_1day"},
        [6]  = {"wild_shape_2day"},
        [7]  = {"wild_shape_3day"},
        [8]  = {"wild_shape_large"},
        [9]  = {"venom_immunity"},
        [10] = {"wild_shape_4day"},
        [11] = {"wild_shape_tiny"},
        [12] = {"wild_shape_plant"},
        [13] = {"thousand_faces"},
        [14] = {"wild_shape_5day"},
        [15] = {"timeless_body", "wild_shape_huge"},
        [16] = {"wild_shape_elemental_1day"},
        [18] = {"wild_shape_6day", "wild_shape_elemental_2day"},
        [20] = {"wild_shape_elemental_3day", "wild_shape_huge_elemental"},
    },
})

class({
    id             = "fighter",
    label          = "Fighter",
    alignment      = "Any",
    hit_die        = 10,
    bab            = "good",
    fort_save      = "good",
    ref_save       = "poor",
    will_save      = "poor",
    skill_points   = 2,
    spell_ability  = nil,
    class_skills   = {
        "climb", "craft", "handle_animal", "intimidate", "jump", "ride", "swim",
    },
    features = {
        [1]  = {"bonus_feat"},
        [2]  = {"bonus_feat"},
        [4]  = {"bonus_feat"},
        [6]  = {"bonus_feat"},
        [8]  = {"bonus_feat"},
        [10] = {"bonus_feat"},
        [12] = {"bonus_feat"},
        [14] = {"bonus_feat"},
        [16] = {"bonus_feat"},
        [18] = {"bonus_feat"},
        [20] = {"bonus_feat"},
    },
})

class({
    id             = "monk",
    label          = "Monk",
    alignment      = "Any lawful",
    hit_die        = 8,
    bab            = "average",
    fort_save      = "good",
    ref_save       = "good",
    will_save      = "good",
    skill_points   = 4,
    spell_ability  = nil,
    class_skills   = {
        "balance", "climb", "concentration", "craft", "diplomacy",
        "escape_artist", "hide", "jump", "knowledge", "listen",
        "move_silently", "perform", "profession", "sense_motive",
        "spot", "swim", "tumble",
    },
    features = {
        [1]  = {"bonus_feat", "flurry_of_blows", "unarmed_strike"},
        [2]  = {"bonus_feat", "evasion"},
        [3]  = {"fast_movement", "still_mind"},
        [4]  = {"ki_strike_magic", "slow_fall_20"},
        [5]  = {"purity_of_body"},
        [6]  = {"bonus_feat", "slow_fall_30"},
        [7]  = {"wholeness_of_body"},
        [9]  = {"improved_evasion"},
        [10] = {"ki_strike_lawful", "slow_fall_50"},
        [11] = {"diamond_body", "greater_flurry"},
        [12] = {"abundant_step", "slow_fall_60"},
        [13] = {"diamond_soul"},
        [15] = {"quivering_palm"},
        [16] = {"ki_strike_adamantine", "slow_fall_80"},
        [17] = {"timeless_body", "tongue_of_sun_and_moon"},
        [19] = {"empty_body"},
        [20] = {"perfect_self"},
    },
    -- Unarmed damage by level bracket (Medium monk)
    unarmed_damage = {
        [1]=  "1d6",  [4]= "1d8",  [8]= "1d10",
        [12]= "2d6",  [16]= "2d8", [20]= "2d10",
    },
    ac_bonus_levels = {[1]=0, [5]=1, [10]=2, [15]=3, [20]=4},
})

class({
    id             = "paladin",
    label          = "Paladin",
    alignment      = "Lawful good",
    hit_die        = 10,
    bab            = "good",
    fort_save      = "good",
    ref_save       = "poor",
    will_save      = "poor",
    skill_points   = 2,
    spell_ability  = "wis",
    spell_start_level = 4,
    class_skills   = {
        "concentration", "craft", "diplomacy", "handle_animal", "heal",
        "knowledge", "profession", "ride", "sense_motive",
    },
    features = {
        [1]  = {"aura_of_good", "detect_evil", "smite_evil_1day"},
        [2]  = {"divine_grace", "lay_on_hands"},
        [3]  = {"aura_of_courage", "divine_health"},
        [4]  = {"turn_undead"},
        [5]  = {"smite_evil_2day", "special_mount"},
        [6]  = {"remove_disease_1week"},
        [9]  = {"remove_disease_2week"},
        [10] = {"smite_evil_3day"},
        [12] = {"remove_disease_3week"},
        [15] = {"remove_disease_4week", "smite_evil_4day"},
        [18] = {"remove_disease_5week"},
        [20] = {"smite_evil_5day"},
    },
})

class({
    id             = "ranger",
    label          = "Ranger",
    alignment      = "Any",
    hit_die        = 8,
    bab            = "good",
    fort_save      = "good",
    ref_save       = "good",
    will_save      = "poor",
    skill_points   = 6,
    spell_ability  = "wis",
    spell_start_level = 4,
    class_skills   = {
        "climb", "concentration", "craft", "handle_animal", "heal", "hide",
        "jump", "knowledge", "listen", "move_silently", "profession", "ride",
        "search", "spot", "survival", "swim", "use_rope",
    },
    features = {
        [1]  = {"favored_enemy_1", "track", "wild_empathy"},
        [2]  = {"combat_style"},
        [3]  = {"endurance"},
        [4]  = {"animal_companion"},
        [5]  = {"favored_enemy_2"},
        [6]  = {"improved_combat_style"},
        [7]  = {"woodland_stride"},
        [8]  = {"swift_tracker"},
        [9]  = {"evasion"},
        [10] = {"favored_enemy_3"},
        [11] = {"combat_style_mastery"},
        [13] = {"camouflage"},
        [15] = {"favored_enemy_4"},
        [17] = {"hide_in_plain_sight"},
        [20] = {"favored_enemy_5"},
    },
})

class({
    id             = "rogue",
    label          = "Rogue",
    alignment      = "Any",
    hit_die        = 6,
    bab            = "average",
    fort_save      = "poor",
    ref_save       = "good",
    will_save      = "poor",
    skill_points   = 8,
    spell_ability  = nil,
    class_skills   = {
        "appraise", "balance", "bluff", "climb", "craft", "decipher_script",
        "diplomacy", "disable_device", "disguise", "escape_artist", "forgery",
        "gather_information", "hide", "intimidate", "jump", "knowledge",
        "listen", "move_silently", "open_lock", "perform", "profession",
        "search", "sense_motive", "sleight_of_hand", "spot", "swim",
        "tumble", "use_magic_device", "use_rope",
    },
    features = {
        [1]  = {"sneak_attack_1d6", "trapfinding"},
        [2]  = {"evasion"},
        [3]  = {"sneak_attack_2d6", "trap_sense_1"},
        [4]  = {"uncanny_dodge"},
        [5]  = {"sneak_attack_3d6"},
        [6]  = {"trap_sense_2"},
        [7]  = {"sneak_attack_4d6"},
        [8]  = {"improved_uncanny_dodge"},
        [9]  = {"sneak_attack_5d6", "trap_sense_3"},
        [10] = {"sneak_attack_6d6", "special_ability"},
        [11] = {"sneak_attack_6d6"},
        [12] = {"trap_sense_4"},
        [13] = {"sneak_attack_7d6", "special_ability"},
        [15] = {"sneak_attack_8d6", "trap_sense_5"},
        [16] = {"special_ability"},
        [17] = {"sneak_attack_9d6"},
        [18] = {"trap_sense_6"},
        [19] = {"sneak_attack_10d6", "special_ability"},
    },
})

class({
    id             = "sorcerer",
    label          = "Sorcerer",
    alignment      = "Any",
    hit_die        = 4,
    bab            = "poor",
    fort_save      = "poor",
    ref_save       = "poor",
    will_save      = "good",
    skill_points   = 2,
    spell_ability  = "cha",
    class_skills   = {
        "bluff", "concentration", "craft", "knowledge", "profession", "spellcraft",
    },
    features = {
        [1] = {"summon_familiar"},
    },
})

class({
    id             = "wizard",
    label          = "Wizard",
    alignment      = "Any",
    hit_die        = 4,
    bab            = "poor",
    fort_save      = "poor",
    ref_save       = "poor",
    will_save      = "good",
    skill_points   = 2,
    spell_ability  = "int",
    class_skills   = {
        "concentration", "craft", "decipher_script", "knowledge",
        "profession", "spellcraft",
    },
    features = {
        [1]  = {"summon_familiar", "scribe_scroll"},
        [5]  = {"bonus_feat"},
        [10] = {"bonus_feat"},
        [15] = {"bonus_feat"},
        [20] = {"bonus_feat"},
    },
})

-- ── Query helpers ────────────────────────────────────────────────────────────

-- Returns true if skill_id is a class skill for the given class_id
function dnd35.is_class_skill(class_id, skill_id)
    local cls = dnd35.CLASSES[class_id]
    if not cls then return false end
    for _, s in ipairs(cls.class_skills) do
        if s == skill_id then return true end
    end
    return false
end

-- Returns the BAB for a character with the given class levels table.
-- class_levels: {barbarian=5, wizard=3, ...}
function dnd35.total_bab(class_levels)
    local total = 0
    for cid, lvl in pairs(class_levels) do
        local cls = dnd35.CLASSES[cid]
        if cls then
            total = total + dnd35.bab(cls.bab, lvl)
        end
    end
    return total
end

-- Returns {fort, ref, will} for the given class levels table.
function dnd35.total_saves(class_levels)
    local fort, ref, will = 0, 0, 0
    for cid, lvl in pairs(class_levels) do
        local cls = dnd35.CLASSES[cid]
        if cls then
            fort = fort + dnd35.base_save(cls.fort_save, lvl)
            ref  = ref  + dnd35.base_save(cls.ref_save,  lvl)
            will = will + dnd35.base_save(cls.will_save,  lvl)
        end
    end
    return fort, ref, will
end

-- Returns total character level from class_levels table.
function dnd35.total_level(class_levels)
    local total = 0
    for _, lvl in pairs(class_levels) do
        total = total + lvl
    end
    return total
end
