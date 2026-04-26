-- dnd_characters: Character creation, ability scores, races, and classes.

local storage = minetest.get_mod_storage()

-- ── Built-in races ────────────────────────────────────────────────────────

dnd.register_race("human", {
    description = "Versatile and ambitious, humans adapt to any role.",
    ability_bonuses = { str=1, dex=1, con=1, int=1, wis=1, cha=1 },
    speed = 30,
})

dnd.register_race("elf", {
    description = "Graceful and long-lived, elves excel at magic and archery.",
    ability_bonuses = { dex=2 },
    speed = 35,
})

dnd.register_race("dwarf", {
    description = "Stout and resilient, dwarves endure hardships others cannot.",
    ability_bonuses = { con=2 },
    speed = 25,
})

dnd.register_race("halfling", {
    description = "Small but nimble, halflings are surprisingly lucky.",
    ability_bonuses = { dex=2 },
    speed = 25,
})

-- ── Built-in classes ──────────────────────────────────────────────────────

dnd.register_class("fighter", {
    description = "Masters of martial combat with unparalleled combat skill.",
    hit_die = 10,
    primary_ability = "str",
    saving_throws = { "str", "con" },
})

dnd.register_class("wizard", {
    description = "Scholars of arcane magic who reshape reality with spells.",
    hit_die = 6,
    primary_ability = "int",
    saving_throws = { "int", "wis" },
})

dnd.register_class("rogue", {
    description = "Experts in stealth and precision, rogues strike from the shadows.",
    hit_die = 8,
    primary_ability = "dex",
    saving_throws = { "dex", "int" },
})

dnd.register_class("cleric", {
    description = "Divine servants who wield the power of their deity.",
    hit_die = 8,
    primary_ability = "wis",
    saving_throws = { "wis", "cha" },
})

-- ── Character data ────────────────────────────────────────────────────────

local ABILITIES = { "str", "dex", "con", "int", "wis", "cha" }

--- Roll 4d6, drop the lowest, return the total (standard array generation).
local function roll_ability()
    local rolls = {}
    for i = 1, 4 do rolls[i] = dnd.roll(6) end
    table.sort(rolls)
    return rolls[2] + rolls[3] + rolls[4]
end

--- Generate a fresh set of ability scores.
local function generate_scores()
    local scores = {}
    for _, ab in ipairs(ABILITIES) do
        scores[ab] = roll_ability()
    end
    return scores
end

--- Apply racial ability bonuses to a score table.
local function apply_racial_bonuses(scores, race_name)
    local race = dnd.races[race_name]
    if not race then return scores end
    for ab, bonus in pairs(race.ability_bonuses or {}) do
        scores[ab] = (scores[ab] or 10) + bonus
    end
    return scores
end

--- Calculate derived stats for a character.
local function derive_stats(char)
    local class = dnd.classes[char.class] or {}
    char.max_hp   = (class.hit_die or 8) + dnd.modifier(char.scores.con)
    char.hp       = char.max_hp
    char.level    = char.level or 1
    char.xp       = char.xp   or 0
    char.proficiency_bonus = 2  -- proficiency bonus at level 1
    return char
end

--- Create a new character for a player.
-- @param player_name string  Minetest player name.
-- @param race_name   string  Race identifier.
-- @param class_name  string  Class identifier.
-- @return table              Character table.
function dnd.create_character(player_name, race_name, class_name)
    local scores = generate_scores()
    scores = apply_racial_bonuses(scores, race_name)

    local char = {
        player = player_name,
        race   = race_name,
        class  = class_name,
        scores = scores,
    }
    derive_stats(char)

    storage:set_string(player_name, minetest.serialize(char))
    dnd.emit("character_created", { player = player_name, char = char })
    return char
end

--- Load the stored character for a player (or nil if none exists).
-- @param player_name string
-- @return table|nil
function dnd.get_character(player_name)
    local raw = storage:get_string(player_name)
    if raw and raw ~= "" then
        return minetest.deserialize(raw)
    end
    return nil
end

-- ── Commands ──────────────────────────────────────────────────────────────

minetest.register_chatcommand("dnd_create", {
    params = "<race> <class>",
    description = "Create your D&D character.  e.g. /dnd_create elf wizard",
    func = function(name, param)
        local race, class = param:match("^(%S+)%s+(%S+)$")
        if not race or not class then
            return false, "Usage: /dnd_create <race> <class>"
        end
        if not dnd.races[race] then
            local keys = {}
            for k in pairs(dnd.races) do table.insert(keys, k) end
            table.sort(keys)
            return false, "Unknown race: " .. race ..
                ".  Available: " .. table.concat(keys, ", ")
        end
        if not dnd.classes[class] then
            return false, "Unknown class: " .. class
        end
        local char = dnd.create_character(name, race, class)
        return true, string.format(
            "Character created!  %s %s — HP %d | STR %d DEX %d CON %d INT %d WIS %d CHA %d",
            race, class, char.max_hp,
            char.scores.str, char.scores.dex, char.scores.con,
            char.scores.int, char.scores.wis, char.scores.cha)
    end,
})

minetest.register_chatcommand("dnd_sheet", {
    description = "Display your character sheet.",
    func = function(name, _)
        local char = dnd.get_character(name)
        if not char then
            return false, "You don't have a character yet.  Use /dnd_create <race> <class>."
        end
        return true, string.format(
            "[%s] Lv%d %s %s — HP %d/%d | XP %d | STR %d DEX %d CON %d INT %d WIS %d CHA %d",
            name, char.level, char.race, char.class,
            char.hp, char.max_hp, char.xp,
            char.scores.str, char.scores.dex, char.scores.con,
            char.scores.int, char.scores.wis, char.scores.cha)
    end,
})

minetest.log("action", "[dnd_characters] loaded")
