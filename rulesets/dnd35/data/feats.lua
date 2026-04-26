-- D&D 3.5e SRD Feat Definitions
-- Open Game Content, licensed under OGL v1.0a
--
-- dnd35.FEATS[id] = {
--   id          string
--   label       string
--   type        "general"|"fighter"|"item_creation"|"metamagic"|"special"
--   prereqs     table  (list of string descriptors, informational)
--   benefit     string (short mechanical summary)
--   repeatable  bool   (can take multiple times, default false)
--   stacks      bool   (repeated benefits stack, default false)
--   slot_cost   int    (metamagic: extra spell slots consumed, nil otherwise)
-- }
--
-- Note: prereqs are stored as human-readable strings for display/validation
-- reference. Programmatic prerequisite checking is handled by the character
-- validation layer (Phase 3).

dnd35 = dnd35 or {}
dnd35.FEATS = {}

local function feat(def)
    dnd35.FEATS[def.id] = def
end

-- ── General Feats ─────────────────────────────────────────────────────────────

feat { id="acrobatic",      label="Acrobatic",      type="general",
    benefit="+2 on Jump checks and Tumble checks." }

feat { id="agile",          label="Agile",          type="general",
    benefit="+2 on Balance checks and Escape Artist checks." }

feat { id="alertness",      label="Alertness",      type="general",
    benefit="+2 on Listen checks and Spot checks." }

feat { id="animal_affinity", label="Animal Affinity", type="general",
    benefit="+2 on Handle Animal checks and Ride checks." }

feat { id="armor_prof_heavy", label="Armor Proficiency (Heavy)", type="general",
    prereqs={"Armor Proficiency (light)", "Armor Proficiency (medium)"},
    benefit="Wear heavy armor without non-proficiency penalties." }

feat { id="armor_prof_light", label="Armor Proficiency (Light)", type="general",
    benefit="Armor check penalty applies only to movement-based skills." }

feat { id="armor_prof_medium", label="Armor Proficiency (Medium)", type="general",
    prereqs={"Armor Proficiency (light)"},
    benefit="Wear medium armor without non-proficiency penalties." }

feat { id="athletic",       label="Athletic",       type="general",
    benefit="+2 on Climb checks and Swim checks." }

feat { id="augment_summoning", label="Augment Summoning", type="general",
    prereqs={"Spell Focus (conjuration)"},
    benefit="Summoned creatures gain +4 enhancement to Strength and Constitution." }

feat { id="blind_fight",    label="Blind-Fight",    type="fighter",
    benefit="Reroll miss chance from concealment in melee; invisible attackers get no melee benefits vs. you; half speed penalty in darkness." }

feat { id="cleave",         label="Cleave",         type="fighter",
    prereqs={"Str 13", "Power Attack"},
    benefit="After dropping a foe, gain one extra melee attack (same weapon, same bonus) against an adjacent target. Once per round." }

feat { id="combat_casting", label="Combat Casting",  type="general",
    benefit="+4 on Concentration checks to cast defensively or while grappling/pinned." }

feat { id="combat_expertise", label="Combat Expertise", type="fighter",
    prereqs={"Int 13"},
    benefit="Take up to -5 on attack roll; gain equal dodge bonus to AC (max = BAB). Lasts until next action." }

feat { id="combat_reflexes", label="Combat Reflexes", type="fighter",
    benefit="Make extra attacks of opportunity equal to Dex bonus per round; may make AoO while flat-footed." }

feat { id="deceitful",      label="Deceitful",      type="general",
    benefit="+2 on Disguise checks and Forgery checks." }

feat { id="deflect_arrows", label="Deflect Arrows",  type="fighter",
    prereqs={"Dex 13", "Improved Unarmed Strike"},
    benefit="Once per round, deflect one ranged weapon attack (must be aware, not flat-footed)." }

feat { id="deft_hands",     label="Deft Hands",     type="general",
    benefit="+2 on Sleight of Hand checks and Use Rope checks." }

feat { id="diehard",        label="Diehard",        type="general",
    prereqs={"Endurance"},
    benefit="Automatically stable at -1 to -9 HP. May choose to act as disabled instead of dying." }

feat { id="diligent",       label="Diligent",       type="general",
    benefit="+2 on Appraise checks and Decipher Script checks." }

feat { id="dodge",          label="Dodge",          type="fighter",
    prereqs={"Dex 13"},
    benefit="+1 dodge bonus to AC against one designated opponent per action." }

feat { id="endurance",      label="Endurance",      type="general",
    benefit="+4 on swim checks vs. nonlethal damage, Con checks for running/forced march/holding breath/starvation, Fort saves vs. environment/suffocation. Sleep in light or medium armor without fatigue." }

feat { id="eschew_materials", label="Eschew Materials", type="general",
    benefit="Cast spells with material components costing 1 gp or less without those components." }

feat { id="exotic_weapon_prof", label="Exotic Weapon Proficiency", type="fighter",
    prereqs={"Base attack bonus +1"},
    benefit="Proficiency with one chosen exotic weapon. (Bastard sword or dwarven waraxe also requires Str 13.)",
    repeatable=true }

feat { id="extra_turning",  label="Extra Turning",  type="general",
    prereqs={"Ability to turn or rebuke creatures"},
    benefit="+4 uses per day for each turn/rebuke ability.",
    repeatable=true, stacks=true }

feat { id="far_shot",       label="Far Shot",       type="fighter",
    prereqs={"Point Blank Shot"},
    benefit="Projectile weapon range increment ×1.5; thrown weapon range increment ×2." }

feat { id="great_cleave",   label="Great Cleave",   type="fighter",
    prereqs={"Str 13", "Cleave", "Power Attack", "Base attack bonus +4"},
    benefit="Like Cleave but unlimited times per round." }

feat { id="great_fortitude", label="Great Fortitude", type="general",
    benefit="+2 on all Fortitude saving throws." }

feat { id="greater_spell_focus", label="Greater Spell Focus", type="general",
    prereqs={"Spell Focus (chosen school)"},
    benefit="+1 to DC for saving throws against spells of chosen school (stacks with Spell Focus).",
    repeatable=true }

feat { id="greater_spell_penetration", label="Greater Spell Penetration", type="general",
    prereqs={"Spell Penetration"},
    benefit="+2 on caster level checks to overcome spell resistance (stacks with Spell Penetration)." }

feat { id="greater_two_weapon_fighting", label="Greater Two-Weapon Fighting", type="fighter",
    prereqs={"Dex 19", "Improved Two-Weapon Fighting", "Two-Weapon Fighting", "Base attack bonus +11"},
    benefit="Third attack with off-hand weapon at -10 penalty." }

feat { id="greater_weapon_focus", label="Greater Weapon Focus", type="fighter",
    prereqs={"Proficiency with weapon", "Weapon Focus (weapon)", "Fighter level 8th"},
    benefit="+1 on attack rolls with chosen weapon (stacks with Weapon Focus).",
    repeatable=true }

feat { id="greater_weapon_specialization", label="Greater Weapon Specialization", type="fighter",
    prereqs={"Proficiency with weapon", "Greater Weapon Focus (weapon)", "Weapon Focus (weapon)", "Weapon Specialization (weapon)", "Fighter level 12th"},
    benefit="+2 on damage rolls with chosen weapon (stacks with Weapon Specialization).",
    repeatable=true }

feat { id="improved_bull_rush", label="Improved Bull Rush", type="fighter",
    prereqs={"Str 13", "Power Attack"},
    benefit="No attack of opportunity when bull rushing; +4 on opposed Strength check." }

feat { id="improved_counterspell", label="Improved Counterspell", type="general",
    benefit="Counterspell with any spell of the same school that is at least one level higher." }

feat { id="improved_critical", label="Improved Critical", type="fighter",
    prereqs={"Proficiency with weapon", "Base attack bonus +8"},
    benefit="Double threat range with chosen weapon. Does not stack with other threat-range effects.",
    repeatable=true }

feat { id="improved_disarm", label="Improved Disarm", type="fighter",
    prereqs={"Int 13", "Combat Expertise"},
    benefit="No attack of opportunity when disarming; opponent can't disarm you; +4 on opposed roll." }

feat { id="improved_familiar", label="Improved Familiar", type="general",
    prereqs={"Ability to acquire a new familiar", "Compatible alignment", "Sufficient caster level"},
    benefit="Choose familiar from expanded nonstandard list (e.g., shocker lizard, stirge, imp, pseudodragon, quasit, small elementals, celestial/fiendish animals)." }

feat { id="improved_feint", label="Improved Feint", type="fighter",
    prereqs={"Int 13", "Combat Expertise"},
    benefit="Make a Bluff check to feint in combat as a move action (normally a standard action)." }

feat { id="improved_grapple", label="Improved Grapple", type="fighter",
    prereqs={"Dex 13", "Improved Unarmed Strike"},
    benefit="No attack of opportunity on touch attack to initiate grapple; +4 on all grapple checks." }

feat { id="improved_initiative", label="Improved Initiative", type="fighter",
    benefit="+4 bonus on initiative checks." }

feat { id="improved_overrun", label="Improved Overrun", type="fighter",
    prereqs={"Str 13", "Power Attack"},
    benefit="Target may not choose to avoid overrun attempt; +4 on Strength check to knock down." }

feat { id="improved_precise_shot", label="Improved Precise Shot", type="fighter",
    prereqs={"Dex 19", "Point Blank Shot", "Precise Shot", "Base attack bonus +11"},
    benefit="Ranged attacks ignore AC/miss bonuses from less than total cover/concealment; automatically hit chosen target in a grapple." }

feat { id="improved_shield_bash", label="Improved Shield Bash", type="fighter",
    prereqs={"Shield Proficiency"},
    benefit="Retain shield's AC bonus when performing a shield bash." }

feat { id="improved_sunder", label="Improved Sunder", type="fighter",
    prereqs={"Str 13", "Power Attack"},
    benefit="No attack of opportunity when striking held/carried objects; +4 on attack roll to sunder." }

feat { id="improved_trip", label="Improved Trip", type="fighter",
    prereqs={"Int 13", "Combat Expertise"},
    benefit="No attack of opportunity when tripping unarmed; +4 on Strength check; immediate melee attack after successful trip." }

feat { id="improved_turning", label="Improved Turning", type="general",
    prereqs={"Ability to turn or rebuke creatures"},
    benefit="Turn/rebuke as if one class level higher." }

feat { id="improved_two_weapon_fighting", label="Improved Two-Weapon Fighting", type="fighter",
    prereqs={"Dex 17", "Two-Weapon Fighting", "Base attack bonus +6"},
    benefit="Second off-hand attack at -5 penalty (in addition to the standard first off-hand attack)." }

feat { id="improved_unarmed_strike", label="Improved Unarmed Strike", type="fighter",
    benefit="Considered armed even when unarmed; unarmed strikes deal lethal or nonlethal damage (your choice)." }

feat { id="investigator",   label="Investigator",   type="general",
    benefit="+2 on Gather Information checks and Search checks." }

feat { id="iron_will",      label="Iron Will",      type="general",
    benefit="+2 on all Will saving throws." }

feat { id="leadership",     label="Leadership",     type="general",
    prereqs={"Character level 6th"},
    benefit="Attract a cohort (up to 2 levels below you) and followers (low-level NPCs). Score = level + Cha modifier, modified by reputation and actions." }

feat { id="lightning_reflexes", label="Lightning Reflexes", type="general",
    benefit="+2 on all Reflex saving throws." }

feat { id="magical_aptitude", label="Magical Aptitude", type="general",
    benefit="+2 on Spellcraft checks and Use Magic Device checks." }

feat { id="manyshot",       label="Manyshot",       type="fighter",
    prereqs={"Dex 17", "Point Blank Shot", "Rapid Shot", "Base attack bonus +6"},
    benefit="Fire 2 arrows at one target within 30 ft as a standard action, -4 attack. +1 arrow per +5 BAB above +6 (max 4), each additional arrow adds -2." }

feat { id="martial_weapon_prof", label="Martial Weapon Proficiency", type="general",
    benefit="Proficiency with one chosen martial weapon.",
    repeatable=true }

feat { id="mobility",       label="Mobility",       type="fighter",
    prereqs={"Dex 13", "Dodge"},
    benefit="+4 dodge bonus to AC against attacks of opportunity triggered by movement." }

feat { id="mounted_archery", label="Mounted Archery", type="fighter",
    prereqs={"Ride 1 rank", "Mounted Combat"},
    benefit="Halve ranged weapon penalty while mounted (-2 at double move, -4 at run; normally -4/-8)." }

feat { id="mounted_combat", label="Mounted Combat",  type="fighter",
    prereqs={"Ride 1 rank"},
    benefit="Once per round, attempt a Ride check to negate a hit on your mount." }

feat { id="natural_spell",  label="Natural Spell",   type="general",
    prereqs={"Wis 13", "Wild shape class feature"},
    benefit="Cast spells with verbal, somatic, and accessible material components while in wild shape." }

feat { id="negotiator",     label="Negotiator",     type="general",
    benefit="+2 on Diplomacy checks and Sense Motive checks." }

feat { id="nimble_fingers", label="Nimble Fingers",  type="general",
    benefit="+2 on Disable Device checks and Open Lock checks." }

feat { id="persuasive",     label="Persuasive",     type="general",
    benefit="+2 on Bluff checks and Intimidate checks." }

feat { id="point_blank_shot", label="Point Blank Shot", type="fighter",
    benefit="+1 on attack and damage rolls with ranged weapons at ranges up to 30 feet." }

feat { id="power_attack",   label="Power Attack",   type="fighter",
    prereqs={"Str 13"},
    benefit="Before attacking, subtract up to BAB from attack rolls; add same amount to melee damage (×2 for two-handed weapon). Not usable with light weapons." }

feat { id="precise_shot",   label="Precise Shot",   type="fighter",
    prereqs={"Point Blank Shot"},
    benefit="No -4 penalty when shooting into melee." }

feat { id="quick_draw",     label="Quick Draw",     type="fighter",
    prereqs={"Base attack bonus +1"},
    benefit="Draw weapon as free action; draw hidden weapon as move action; throw weapons at full attack rate." }

feat { id="rapid_reload",   label="Rapid Reload",   type="fighter",
    prereqs={"Weapon Proficiency (crossbow type)"},
    benefit="Reload hand/light crossbow as free action; heavy crossbow as move action.",
    repeatable=true }

feat { id="rapid_shot",     label="Rapid Shot",     type="fighter",
    prereqs={"Dex 13", "Point Blank Shot"},
    benefit="One extra ranged attack per round at highest BAB with full attack action; all attacks in that round take -2." }

feat { id="ride_by_attack", label="Ride-By Attack",  type="fighter",
    prereqs={"Ride 1 rank", "Mounted Combat"},
    benefit="On a mounted charge, move, attack, then continue moving (total ≤ double mounted speed). No AoO from target." }

feat { id="run",            label="Run",             type="general",
    benefit="Run at ×5 speed (or ×4 in heavy armor/heavy load). +4 on Jump after running start. Retain Dex bonus to AC while running." }

feat { id="self_sufficient", label="Self-Sufficient", type="general",
    benefit="+2 on Heal checks and Survival checks." }

feat { id="shield_proficiency", label="Shield Proficiency", type="general",
    benefit="Use a shield and take only standard penalties." }

feat { id="shot_on_the_run", label="Shot on the Run", type="fighter",
    prereqs={"Dex 13", "Dodge", "Mobility", "Point Blank Shot", "Base attack bonus +4"},
    benefit="With attack action (ranged weapon), move before and after attacking (total ≤ speed)." }

feat { id="simple_weapon_prof", label="Simple Weapon Proficiency", type="general",
    benefit="Proficiency with all simple weapons." }

feat { id="skill_focus",    label="Skill Focus",    type="general",
    benefit="+3 on all checks with chosen skill.",
    repeatable=true }

feat { id="snatch_arrows",  label="Snatch Arrows",  type="fighter",
    prereqs={"Dex 15", "Deflect Arrows", "Improved Unarmed Strike"},
    benefit="When deflecting a ranged attack, catch the weapon instead. Thrown weapons may be immediately thrown back." }

feat { id="spell_focus",    label="Spell Focus",    type="general",
    benefit="+1 to DC for saving throws against spells of chosen school.",
    repeatable=true }

feat { id="spell_mastery",  label="Spell Mastery",  type="special",
    prereqs={"Wizard level 1st"},
    benefit="Prepare a number of chosen spells (equal to Int modifier) without a spellbook.",
    repeatable=true }

feat { id="spell_penetration", label="Spell Penetration", type="general",
    benefit="+2 on caster level checks (1d20 + caster level) to overcome spell resistance." }

feat { id="spirited_charge", label="Spirited Charge", type="fighter",
    prereqs={"Ride 1 rank", "Mounted Combat", "Ride-By Attack"},
    benefit="Deal double damage on a mounted charge (triple with a lance)." }

feat { id="spring_attack",  label="Spring Attack",  type="fighter",
    prereqs={"Dex 13", "Dodge", "Mobility", "Base attack bonus +4"},
    benefit="With melee attack action, move before and after attacking (total ≤ speed). No AoO from attacked target. Not usable in heavy armor." }

feat { id="stealthy",       label="Stealthy",       type="general",
    benefit="+2 on Hide checks and Move Silently checks." }

feat { id="stunning_fist",  label="Stunning Fist",  type="fighter",
    prereqs={"Dex 13", "Wis 13", "Improved Unarmed Strike", "Base attack bonus +8"},
    benefit="Declare before attack roll. On hit, target makes Fortitude save (DC 10 + ½ level + Wis mod) or stunned 1 round. Usable once per day per 4 levels." }

feat { id="toughness",      label="Toughness",      type="general",
    benefit="+3 hit points.",
    repeatable=true, stacks=true }

feat { id="tower_shield_prof", label="Tower Shield Proficiency", type="general",
    prereqs={"Shield Proficiency"},
    benefit="Use a tower shield and take only standard penalties." }

feat { id="track",          label="Track",          type="general",
    benefit="Use Survival to find and follow tracks beyond DC 10. Must make checks as conditions warrant." }

feat { id="trample",        label="Trample",        type="fighter",
    prereqs={"Ride 1 rank", "Mounted Combat"},
    benefit="Target may not avoid mounted overrun. Mount makes a hoof attack against knocked-down target." }

feat { id="two_weapon_defense", label="Two-Weapon Defense", type="fighter",
    prereqs={"Dex 15", "Two-Weapon Fighting"},
    benefit="+1 shield bonus to AC when wielding two weapons or a double weapon (+2 when fighting defensively or using total defense)." }

feat { id="two_weapon_fighting", label="Two-Weapon Fighting", type="fighter",
    prereqs={"Dex 15"},
    benefit="Primary hand attack penalty reduced by 2, off-hand penalty reduced by 6 (standard TWF penalties: -6/-10; light off-hand: -4/-8)." }

feat { id="weapon_finesse", label="Weapon Finesse",  type="fighter",
    prereqs={"Base attack bonus +1"},
    benefit="Use Dex modifier instead of Str modifier on attack rolls with light weapons, rapier, whip, or spiked chain. Natural weapons always qualify." }

feat { id="weapon_focus",   label="Weapon Focus",   type="fighter",
    prereqs={"Proficiency with weapon", "Base attack bonus +1"},
    benefit="+1 on all attack rolls with chosen weapon.",
    repeatable=true }

feat { id="weapon_specialization", label="Weapon Specialization", type="fighter",
    prereqs={"Proficiency with weapon", "Weapon Focus (weapon)", "Fighter level 4th"},
    benefit="+2 on all damage rolls with chosen weapon.",
    repeatable=true }

feat { id="whirlwind_attack", label="Whirlwind Attack", type="fighter",
    prereqs={"Dex 13", "Int 13", "Combat Expertise", "Dodge", "Mobility", "Spring Attack", "Base attack bonus +4"},
    benefit="With full attack action, give up normal attacks to make one melee attack at full BAB against every opponent within reach." }

-- ── Item Creation Feats ───────────────────────────────────────────────────────

feat { id="brew_potion",    label="Brew Potion",    type="item_creation",
    prereqs={"Caster level 3rd"},
    benefit="Create potions of 3rd-level or lower spells that target creatures. Cost: spell level × caster level × 50 gp (half in materials, 1/25 in XP)." }

feat { id="craft_magic_arms", label="Craft Magic Arms and Armor", type="item_creation",
    prereqs={"Caster level 5th"},
    benefit="Create and enhance magic weapons, armor, and shields. 1 day per 1,000 gp; cost: half price in materials, 1/25 in XP." }

feat { id="craft_rod",      label="Craft Rod",      type="item_creation",
    prereqs={"Caster level 9th"},
    benefit="Create any rod whose prerequisites you meet. 1 day per 1,000 gp; cost: half in materials, 1/25 in XP." }

feat { id="craft_staff",    label="Craft Staff",    type="item_creation",
    prereqs={"Caster level 12th"},
    benefit="Create any staff whose prerequisites you meet. 1 day per 1,000 gp; new staff has 50 charges." }

feat { id="craft_wand",     label="Craft Wand",     type="item_creation",
    prereqs={"Caster level 5th"},
    benefit="Create wands of 4th-level or lower spells. Base price: caster level × spell level × 750 gp; new wand has 50 charges." }

feat { id="craft_wondrous_item", label="Craft Wondrous Item", type="item_creation",
    prereqs={"Caster level 3rd"},
    benefit="Create any wondrous item whose prerequisites you meet. 1 day per 1,000 gp; half price in materials, 1/25 in XP." }

feat { id="forge_ring",     label="Forge Ring",     type="item_creation",
    prereqs={"Caster level 12th"},
    benefit="Create any ring whose prerequisites you meet. 1 day per 1,000 gp; half in materials, 1/25 in XP." }

feat { id="scribe_scroll",  label="Scribe Scroll",  type="item_creation",
    prereqs={"Caster level 1st"},
    benefit="Create scrolls of spells you know. Base price: spell level × caster level × 25 gp; half in materials, 1/25 in XP." }

-- ── Metamagic Feats ──────────────────────────────────────────────────────────

feat { id="empower_spell",  label="Empower Spell",  type="metamagic", slot_cost=2,
    benefit="All variable, numeric effects increased by 50%. Saving throws and opposed rolls unaffected." }

feat { id="enlarge_spell",  label="Enlarge Spell",  type="metamagic", slot_cost=1,
    benefit="Double the range of a spell with close, medium, or long range." }

feat { id="extend_spell",   label="Extend Spell",   type="metamagic", slot_cost=1,
    benefit="Double the duration of a spell (not instantaneous, concentration, or permanent)." }

feat { id="heighten_spell", label="Heighten Spell",  type="metamagic",
    benefit="Raise a spell's effective level up to 9th; all level-dependent effects (DC, penetration) recalculate. Slot cost varies by desired level." }

feat { id="maximize_spell", label="Maximize Spell",  type="metamagic", slot_cost=3,
    benefit="Maximize all variable, numeric effects of a spell." }

feat { id="quicken_spell",  label="Quicken Spell",   type="metamagic", slot_cost=4,
    benefit="Cast a spell as a free action. Limit: one quickened spell per round. Cannot be used spontaneously." }

feat { id="silent_spell",   label="Silent Spell",    type="metamagic", slot_cost=1,
    benefit="Cast a spell with no verbal component. Cannot apply to bard spells." }

feat { id="still_spell",    label="Still Spell",     type="metamagic", slot_cost=1,
    benefit="Cast a spell with no somatic component." }

feat { id="widen_spell",    label="Widen Spell",     type="metamagic", slot_cost=3,
    benefit="Double the area of a burst, emanation, line, or spread-shaped spell." }

-- ── Query helpers ─────────────────────────────────────────────────────────────

--- Return an array of all feat definitions.
--- @return table
function dnd35.list_feats()
    local out = {}
    for _, f in pairs(dnd35.FEATS) do
        out[#out + 1] = f
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

--- Return only feats of a given type.
--- @param feat_type string  "general"|"fighter"|"item_creation"|"metamagic"|"special"
--- @return table
function dnd35.feats_by_type(feat_type)
    local out = {}
    for _, f in pairs(dnd35.FEATS) do
        if f.type == feat_type then
            out[#out + 1] = f
        end
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end
