-- dnd_core: Shared utilities, registries, and event hooks
-- All other dnd3 mods depend on this one.

dnd = dnd or {}

-- ── Dice ──────────────────────────────────────────────────────────────────

--- Roll an n-sided die.
-- @param sides integer  Number of sides (e.g. 20 for a d20).
-- @return integer       Result in [1, sides].
function dnd.roll(sides)
    return math.random(1, sides)
end

--- Roll multiple dice and sum the results.
-- @param count  integer  Number of dice.
-- @param sides  integer  Number of sides per die.
-- @return integer        Sum of all rolls.
function dnd.roll_multi(count, sides)
    local total = 0
    for _ = 1, count do
        total = total + dnd.roll(sides)
    end
    return total
end

--- Return the ability-score modifier for a raw score (D&D 5e formula).
-- @param score integer  Raw ability score (3–20+).
-- @return integer       Modifier value.
function dnd.modifier(score)
    return math.floor((score - 10) / 2)
end

-- ── Event bus ─────────────────────────────────────────────────────────────

dnd._handlers = dnd._handlers or {}

--- Register a listener for a named event.
-- @param event   string    Event name.
-- @param handler function  Callback(data).
function dnd.on(event, handler)
    dnd._handlers[event] = dnd._handlers[event] or {}
    table.insert(dnd._handlers[event], handler)
end

--- Fire a named event, calling every registered handler.
-- @param event string  Event name.
-- @param data  table   Payload passed to every handler.
function dnd.emit(event, data)
    if dnd._handlers[event] then
        for _, handler in ipairs(dnd._handlers[event]) do
            handler(data)
        end
    end
end

-- ── Registries ────────────────────────────────────────────────────────────

dnd.races    = {}
dnd.classes  = {}
dnd.spells   = {}

--- Register a race definition.
-- @param name string  Internal race identifier.
-- @param def  table   Race definition table.
function dnd.register_race(name, def)
    dnd.races[name] = def
end

--- Register a class definition.
-- @param name string  Internal class identifier.
-- @param def  table   Class definition table.
function dnd.register_class(name, def)
    dnd.classes[name] = def
end

--- Register a spell definition.
-- @param name string  Internal spell identifier.
-- @param def  table   Spell definition table.
function dnd.register_spell(name, def)
    dnd.spells[name] = def
end

minetest.log("action", "[dnd_core] loaded")
