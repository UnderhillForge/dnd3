-- dnd_magic: Spells, spell slots, and the spell compendium.

-- ── Built-in spells ───────────────────────────────────────────────────────

dnd.register_spell("magic_missile", {
    name        = "Magic Missile",
    level       = 1,
    school      = "evocation",
    description = "Three darts of magical force, each dealing 1d4+1 force damage.",
    cast = function(caster_char, target_char)
        local total = 0
        for _ = 1, 3 do
            total = total + dnd.roll(4) + 1
        end
        return total, string.format("Magic Missile hits for %d force damage!", total)
    end,
})

dnd.register_spell("cure_wounds", {
    name        = "Cure Wounds",
    level       = 1,
    school      = "evocation",
    description = "Touch a creature to restore 1d8 + WIS modifier hit points.",
    cast = function(caster_char, target_char)
        local healed = dnd.roll(8) + dnd.modifier(caster_char.scores.wis)
        healed = math.max(1, healed)
        return healed, string.format("Cure Wounds restores %d HP!", healed)
    end,
})

dnd.register_spell("fireball", {
    name        = "Fireball",
    level       = 3,
    school      = "evocation",
    description = "A bright streak detonates into 8d6 fire damage (DEX save DC 8+INT mod+prof).",
    cast = function(caster_char, target_char)
        local dmg = dnd.roll_multi(8, 6)
        local dc  = 8 + dnd.modifier(caster_char.scores.int) +
                    (caster_char.proficiency_bonus or 2)
        local saved, _ = dnd.saving_throw(
            target_char.scores.dex, false, 0, dc)
        if saved then dmg = math.floor(dmg / 2) end
        return dmg, string.format(
            "Fireball deals %d fire damage%s!",
            dmg, saved and " (halved — save succeeded)" or "")
    end,
})

dnd.register_spell("shield", {
    name        = "Shield",
    level       = 1,
    school      = "abjuration",
    description = "Reaction: +5 AC until the start of your next turn.",
    cast = function(caster_char, _)
        return 0, "Shield raises your AC by 5 until your next turn."
    end,
})

-- ── Spell-slot management ─────────────────────────────────────────────────

-- Simple 5e-style slots for levels 1–5 at character level 1.
local BASE_SLOTS = { [1]=2, [2]=0, [3]=0, [4]=0, [5]=0 }

local function get_slots(char)
    if not char.spell_slots then
        char.spell_slots = {}
        for lvl, count in pairs(BASE_SLOTS) do
            char.spell_slots[lvl] = count
        end
    end
    return char.spell_slots
end

--- Cast a spell by name.
-- @param caster_name string  Casting player name.
-- @param target_name string  Target player name (may equal caster for self-spells).
-- @param spell_name  string  Registered spell identifier.
-- @return boolean, string    success, message.
function dnd.cast_spell(caster_name, target_name, spell_name)
    local spell = dnd.spells[spell_name]
    if not spell then
        return false, "Unknown spell: " .. spell_name
    end

    local caster = dnd.get_character(caster_name)
    if not caster then return false, "You have no character." end

    local target = dnd.get_character(target_name)
    if not target then return false, target_name .. " has no character." end

    local slots = get_slots(caster)
    local lvl   = spell.level or 0

    if lvl > 0 then
        if (slots[lvl] or 0) < 1 then
            return false, "No level-" .. lvl .. " spell slots remaining."
        end
        slots[lvl] = slots[lvl] - 1
    end

    local result, msg = spell.cast(caster, target)
    dnd.emit("spell_cast", {
        caster = caster_name,
        target = target_name,
        spell  = spell_name,
        result = result,
    })
    return true, msg
end

-- ── Commands ──────────────────────────────────────────────────────────────

minetest.register_chatcommand("dnd_cast", {
    params = "<spell> <target>",
    description = "Cast a spell at a target player.  e.g. /dnd_cast magic_missile Steve",
    func = function(name, param)
        local spell, target = param:match("^(%S+)%s+(%S+)$")
        if not spell or not target then
            return false, "Usage: /dnd_cast <spell> <target>"
        end
        local ok, msg = dnd.cast_spell(name, target, spell)
        if ok then
            minetest.chat_send_player(target,
                string.format("%s casts %s on you — %s", name, spell, msg))
        end
        return ok, msg
    end,
})

minetest.register_chatcommand("dnd_spells", {
    description = "List all registered spells.",
    func = function(_, _)
        local names = {}
        for k, v in pairs(dnd.spells) do
            table.insert(names, string.format("%s (lv%d %s)", v.name, v.level, v.school))
        end
        table.sort(names)
        return true, "Spells:\n" .. table.concat(names, "\n")
    end,
})

minetest.log("action", "[dnd_magic] loaded")
