-- D&D 3.5e SRD Character Compute Hook
-- Open Game Content, licensed under OGL v1.0a
--
-- Registered as a compute hook with the dnd3_core character system.
-- When dnd3.character.compute(token_id) is called, this function runs and
-- populates all derived fields from the raw sheet fields set by the GM/player.
--
-- Raw fields expected on the sheet (set manually or via UI):
--   str, dex, con, int, wis, cha         (ability scores, integers)
--   class_levels                          (JSON object: {class_id: level, ...})
--   hp_max_base                           (integer, before CON mod)
--   armor_bonus                           (integer AC from worn armor)
--   shield_bonus                          (integer AC from shield)
--   natural_armor                         (integer)
--   deflection_bonus                      (integer)
--   size_modifier                         (integer, +1 small, -1 large, etc.)
--   initiative_misc                       (integer misc initiative bonus)
--   skill_{id}_ranks                      (integer ranks in each skill)
--   skill_{id}_misc                       (integer misc modifier for each skill)
--
-- Derived fields written by this hook:
--   str_mod, dex_mod, con_mod, int_mod, wis_mod, cha_mod
--   bab                                   (base attack bonus)
--   fort_save, ref_save, will_save        (total saves incl. ability mod)
--   ac                                    (full AC)
--   ac_touch                              (touch AC)
--   ac_flat_footed                        (flat-footed AC)
--   initiative                            (total initiative bonus)
--   hp_max                                (max HP = hp_max_base + CON mod × level)
--   skill_{id}_total                      (total skill check modifier)
--   skill_{id}_synergy                    (synergy bonus applied)

dnd35 = dnd35 or {}

local SKILL_IDS = {
    "appraise", "balance", "bluff", "climb", "concentration",
    "craft", "decipher_script", "diplomacy", "disable_device",
    "disguise", "escape_artist", "forgery", "gather_information",
    "handle_animal", "heal", "hide", "intimidate", "jump",
    "knowledge", "listen", "move_silently", "open_lock",
    "perform", "profession", "ride", "search", "sense_motive",
    "sleight_of_hand", "speak_language", "spellcraft", "spot",
    "survival", "swim", "tumble", "use_magic_device", "use_rope",
}

-- Ability id → key used in sheets
local ABILITY_IDS = {"str", "dex", "con", "int", "wis", "cha"}

-- Skill id → governing ability id
local SKILL_ABILITY = {
    appraise          = "int",
    balance           = "dex",
    bluff             = "cha",
    climb             = "str",
    concentration     = "con",
    craft             = "int",
    decipher_script   = "int",
    diplomacy         = "cha",
    disable_device    = "int",
    disguise          = "cha",
    escape_artist     = "dex",
    forgery           = "int",
    gather_information= "cha",
    handle_animal     = "cha",
    heal              = "wis",
    hide              = "dex",
    intimidate        = "cha",
    jump              = "str",
    knowledge         = "int",
    listen            = "wis",
    move_silently     = "dex",
    open_lock         = "dex",
    perform           = "cha",
    profession        = "wis",
    ride              = "dex",
    search            = "int",
    sense_motive      = "wis",
    sleight_of_hand   = "dex",
    speak_language    = nil,   -- no ability, no check
    spellcraft        = "int",
    spot              = "wis",
    survival          = "wis",
    swim              = "str",
    tumble            = "dex",
    use_magic_device  = "cha",
    use_rope          = "dex",
}

-- Synergy table: {source_skill, min_ranks, target_skill, bonus}
-- Derived from SRD skill descriptions.
local SYNERGIES = {
    {source="bluff",          min=5, target="diplomacy",       bonus=2},
    {source="bluff",          min=5, target="intimidate",      bonus=2},
    {source="bluff",          min=5, target="sleight_of_hand", bonus=2},
    {source="decipher_script",min=5, target="use_magic_device",bonus=2},
    {source="escape_artist",  min=5, target="use_rope",        bonus=2},
    {source="handle_animal",  min=5, target="ride",            bonus=2},
    {source="jump",           min=5, target="tumble",          bonus=2},
    {source="knowledge",      min=5, target="spellcraft",      bonus=2},  -- arcana
    {source="knowledge",      min=5, target="search",          bonus=2},  -- architecture
    {source="knowledge",      min=5, target="survival",        bonus=2},  -- geography/nature/dungeoneering/planes
    {source="knowledge",      min=5, target="gather_information", bonus=2}, -- local
    {source="knowledge",      min=5, target="diplomacy",       bonus=2},  -- nobility
    {source="search",         min=5, target="survival",        bonus=2},  -- tracking
    {source="sense_motive",   min=5, target="diplomacy",       bonus=2},
    {source="spellcraft",     min=5, target="use_magic_device",bonus=2},
    {source="survival",       min=5, target="knowledge",       bonus=2},  -- nature
    {source="tumble",         min=5, target="balance",         bonus=2},
    {source="tumble",         min=5, target="jump",            bonus=2},
    {source="use_magic_device",min=5,target="spellcraft",      bonus=2},
    {source="use_rope",       min=5, target="climb",           bonus=2},
    {source="use_rope",       min=5, target="escape_artist",   bonus=2},
}

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function get_num(sheet, key, default)
    local v = sheet[key]
    return (type(v) == "number") and v or (tonumber(v) or default or 0)
end

local function get_class_levels(sheet)
    local cl = sheet.class_levels
    if type(cl) == "table" then return cl end
    return {}
end

-- Total character level across all classes
local function char_level(class_levels)
    local total = 0
    for _, lvl in pairs(class_levels) do
        total = total + (tonumber(lvl) or 0)
    end
    return total
end

-- ── Main compute hook ─────────────────────────────────────────────────────────

local function dnd35_compute(sheet, ruleset_id)
    if ruleset_id ~= "dnd35" then return end

    -- 1. Ability modifiers
    local mods = {}
    for _, ab in ipairs(ABILITY_IDS) do
        local score = get_num(sheet, ab, 10)
        local mod   = math.floor((score - 10) / 2)
        sheet[ab .. "_mod"] = mod
        mods[ab]            = mod
    end

    -- 2. BAB and saves
    local class_levels = get_class_levels(sheet)
    local total_bab    = 0
    local fort, ref, will = 0, 0, 0

    for cid, lvl_raw in pairs(class_levels) do
        local lvl = tonumber(lvl_raw) or 0
        local cls = dnd35.CLASSES and dnd35.CLASSES[cid]
        if cls then
            total_bab = total_bab + dnd35.bab(cls.bab, lvl)
            fort = fort + dnd35.base_save(cls.fort_save, lvl)
            ref  = ref  + dnd35.base_save(cls.ref_save,  lvl)
            will = will + dnd35.base_save(cls.will_save,  lvl)
        end
    end
    sheet.bab       = total_bab
    sheet.fort_save = fort + mods.con
    sheet.ref_save  = ref  + mods.dex
    sheet.will_save = will + mods.wis

    -- 3. AC
    local armor     = get_num(sheet, "armor_bonus")
    local shield    = get_num(sheet, "shield_bonus")
    local nat_armor = get_num(sheet, "natural_armor")
    local deflect   = get_num(sheet, "deflection_bonus")
    local size_mod  = get_num(sheet, "size_modifier")
    local dex_mod   = mods.dex

    sheet.ac            = 10 + armor + shield + dex_mod + nat_armor + deflect + size_mod
    sheet.ac_touch      = 10 + dex_mod + deflect + size_mod
    sheet.ac_flat_footed = 10 + armor + shield + nat_armor + deflect + size_mod

    -- 4. Initiative
    local init_misc = get_num(sheet, "initiative_misc")
    sheet.initiative = dex_mod + init_misc

    -- 5. HP  (hp_max = base + CON mod × total character level)
    local level    = char_level(class_levels)
    local hp_base  = get_num(sheet, "hp_max_base")
    local con_per_level = mods.con * math.max(level, 1)
    sheet.hp_max   = hp_base + con_per_level

    -- 6. Skill synergies (compute before totals so totals can include synergy)
    --    Clear all existing synergy fields.
    for _, syn in ipairs(SYNERGIES) do
        sheet["skill_" .. syn.target .. "_synergy"] = 0
    end
    for _, syn in ipairs(SYNERGIES) do
        local src_ranks = get_num(sheet, "skill_" .. syn.source .. "_ranks")
        if src_ranks >= syn.min then
            local key = "skill_" .. syn.target .. "_synergy"
            sheet[key] = (sheet[key] or 0) + syn.bonus
        end
    end

    -- 7. Skill totals
    for _, sid in ipairs(SKILL_IDS) do
        if sid ~= "speak_language" then
            local ab      = SKILL_ABILITY[sid]
            local ab_mod  = ab and (mods[ab] or 0) or 0
            local ranks   = get_num(sheet, "skill_" .. sid .. "_ranks")
            local misc    = get_num(sheet, "skill_" .. sid .. "_misc")
            local synergy = get_num(sheet, "skill_" .. sid .. "_synergy")
            sheet["skill_" .. sid .. "_total"] = ranks + ab_mod + misc + synergy
        end
    end
end

-- Register at priority 10 so it runs early; ruleset data files loaded first
dnd3.character.register_compute_hook(dnd35_compute, 10)
