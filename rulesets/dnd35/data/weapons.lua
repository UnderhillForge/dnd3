-- D&D 3.5e SRD Weapons
-- Open Game Content, licensed under OGL v1.0a
--
-- All SRD weapon definitions from Table 7-5 (PHB).
--
-- dnd35.WEAPONS[id] = {
--   id            string   unique key
--   label         string   display name
--   category      string   "simple" | "martial" | "exotic"
--   wtype         string   "melee" | "ranged" | "thrown"
--                          (thrown weapons can be used as melee OR ranged)
--   hands         string   "light" | "one_hand" | "two_hand"
--   damage_s      string   damage dice for Small wielder
--   damage_m      string   damage dice for Medium wielder
--   crit_range    number   minimum d20 roll that threatens a critical (e.g. 19 → 19–20)
--   crit_mult     number   critical hit damage multiplier (×2, ×3, ×4)
--   range_inc     number   range increment in feet (nil = non-ranged/non-thrown)
--   damage_type   string   "B" | "P" | "S" | "BP" | "BS" | "PS" | "BPS"
--   special       table    array of strings: "reach" "brace" "trip" "disarm"
--                          "double" "nonlethal" "monk" "finesse" "entangle"
--   double_secondary table for double weapons: { damage_s, damage_m, crit_range,
--                          crit_mult, damage_type } describing the off-end

dnd35 = dnd35 or {}
dnd35.WEAPONS = {}

local function weapon(def)
	def.special = def.special or {}
	dnd35.WEAPONS[def.id] = def
end

-- ── Unarmed ───────────────────────────────────────────────────────────────────
weapon({ id="unarmed_strike",            label="Unarmed Strike",               category="simple",  wtype="melee",   hands="light",    damage_s="1d2",  damage_m="1d3",  crit_range=20, crit_mult=2, damage_type="B",  special={"nonlethal","monk"} })

-- ── Simple — Light ───────────────────────────────────────────────────────────
weapon({ id="dagger",                    label="Dagger",                       category="simple",  wtype="thrown",  hands="light",    damage_s="1d3",  damage_m="1d4",  crit_range=19, crit_mult=2, range_inc=10,  damage_type="PS", special={"finesse"} })
weapon({ id="dagger_punching",           label="Punching Dagger",              category="simple",  wtype="melee",   hands="light",    damage_s="1d3",  damage_m="1d4",  crit_range=20, crit_mult=3, damage_type="P"  })
weapon({ id="gauntlet",                  label="Gauntlet",                     category="simple",  wtype="melee",   hands="light",    damage_s="1d2",  damage_m="1d3",  crit_range=20, crit_mult=2, damage_type="B"  })
weapon({ id="spiked_gauntlet",           label="Spiked Gauntlet",              category="simple",  wtype="melee",   hands="light",    damage_s="1d3",  damage_m="1d4",  crit_range=20, crit_mult=2, damage_type="P"  })

-- ── Simple — One-Handed ──────────────────────────────────────────────────────
weapon({ id="club",                      label="Club",                         category="simple",  wtype="thrown",  hands="one_hand", damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=2, range_inc=10,  damage_type="B"  })
weapon({ id="heavy_mace",                label="Heavy Mace",                   category="simple",  wtype="melee",   hands="one_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=2, damage_type="B"  })
weapon({ id="light_mace",                label="Light Mace",                   category="simple",  wtype="melee",   hands="light",    damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=2, damage_type="B"  })
weapon({ id="morningstar",               label="Morningstar",                  category="simple",  wtype="melee",   hands="one_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=2, damage_type="BP" })
weapon({ id="shortspear",                label="Shortspear",                   category="simple",  wtype="thrown",  hands="one_hand", damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=2, range_inc=20,  damage_type="P"  })

-- ── Simple — Two-Handed ──────────────────────────────────────────────────────
weapon({ id="longspear",                 label="Longspear",                    category="simple",  wtype="melee",   hands="two_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=3, damage_type="P",  special={"reach","brace"} })
weapon({ id="quarterstaff",              label="Quarterstaff",                 category="simple",  wtype="melee",   hands="two_hand", damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=2, damage_type="B",  special={"double","monk"}, double_secondary={ damage_s="1d4", damage_m="1d6", crit_range=20, crit_mult=2, damage_type="B" } })
weapon({ id="spear",                     label="Spear",                        category="simple",  wtype="thrown",  hands="two_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=3, range_inc=20,  damage_type="P",  special={"brace"} })

-- ── Simple — Ranged ──────────────────────────────────────────────────────────
weapon({ id="heavy_crossbow",            label="Heavy Crossbow",               category="simple",  wtype="ranged",  hands="two_hand", damage_s="1d8",  damage_m="1d10", crit_range=19, crit_mult=2, range_inc=120, damage_type="P"  })
weapon({ id="light_crossbow",            label="Light Crossbow",               category="simple",  wtype="ranged",  hands="two_hand", damage_s="1d6",  damage_m="1d8",  crit_range=19, crit_mult=2, range_inc=80,  damage_type="P"  })
weapon({ id="dart",                      label="Dart",                         category="simple",  wtype="thrown",  hands="light",    damage_s="1d3",  damage_m="1d4",  crit_range=20, crit_mult=2, range_inc=20,  damage_type="P"  })
weapon({ id="javelin",                   label="Javelin",                      category="simple",  wtype="thrown",  hands="one_hand", damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=2, range_inc=30,  damage_type="P"  })
weapon({ id="sling",                     label="Sling",                        category="simple",  wtype="ranged",  hands="light",    damage_s="1d3",  damage_m="1d4",  crit_range=20, crit_mult=2, range_inc=50,  damage_type="B"  })

-- ── Martial — Light ──────────────────────────────────────────────────────────
weapon({ id="handaxe",                   label="Handaxe",                      category="martial", wtype="melee",   hands="light",    damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=3, damage_type="S"  })
weapon({ id="light_hammer",              label="Light Hammer",                 category="martial", wtype="thrown",  hands="light",    damage_s="1d3",  damage_m="1d4",  crit_range=20, crit_mult=2, range_inc=20,  damage_type="B"  })
weapon({ id="light_pick",                label="Light Pick",                   category="martial", wtype="melee",   hands="light",    damage_s="1d3",  damage_m="1d4",  crit_range=20, crit_mult=4, damage_type="P"  })
weapon({ id="sap",                       label="Sap",                          category="martial", wtype="melee",   hands="light",    damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=2, damage_type="B",  special={"nonlethal"} })
weapon({ id="shortsword",                label="Shortsword",                   category="martial", wtype="melee",   hands="light",    damage_s="1d4",  damage_m="1d6",  crit_range=19, crit_mult=2, damage_type="P",  special={"finesse"} })

-- ── Martial — One-Handed ─────────────────────────────────────────────────────
weapon({ id="battleaxe",                 label="Battleaxe",                    category="martial", wtype="melee",   hands="one_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=3, damage_type="S"  })
weapon({ id="flail",                     label="Flail",                        category="martial", wtype="melee",   hands="one_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=2, damage_type="B",  special={"disarm","trip"} })
weapon({ id="heavy_pick",                label="Heavy Pick",                   category="martial", wtype="melee",   hands="one_hand", damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=4, damage_type="P"  })
weapon({ id="longsword",                 label="Longsword",                    category="martial", wtype="melee",   hands="one_hand", damage_s="1d6",  damage_m="1d8",  crit_range=19, crit_mult=2, damage_type="S"  })
weapon({ id="rapier",                    label="Rapier",                       category="martial", wtype="melee",   hands="one_hand", damage_s="1d4",  damage_m="1d6",  crit_range=18, crit_mult=2, damage_type="P",  special={"finesse"} })
weapon({ id="scimitar",                  label="Scimitar",                     category="martial", wtype="melee",   hands="one_hand", damage_s="1d4",  damage_m="1d6",  crit_range=18, crit_mult=2, damage_type="S"  })
weapon({ id="trident",                   label="Trident",                      category="martial", wtype="thrown",  hands="one_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=2, range_inc=10,  damage_type="P",  special={"brace"} })
weapon({ id="warhammer",                 label="Warhammer",                    category="martial", wtype="melee",   hands="one_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=3, damage_type="B"  })

-- ── Martial — Two-Handed ─────────────────────────────────────────────────────
weapon({ id="falchion",                  label="Falchion",                     category="martial", wtype="melee",   hands="two_hand", damage_s="1d6",  damage_m="2d4",  crit_range=18, crit_mult=2, damage_type="S"  })
weapon({ id="glaive",                    label="Glaive",                       category="martial", wtype="melee",   hands="two_hand", damage_s="1d8",  damage_m="1d10", crit_range=20, crit_mult=3, damage_type="S",  special={"reach"} })
weapon({ id="great_club",                label="Greatclub",                    category="martial", wtype="melee",   hands="two_hand", damage_s="1d8",  damage_m="1d10", crit_range=20, crit_mult=2, damage_type="B"  })
weapon({ id="greataxe",                  label="Greataxe",                     category="martial", wtype="melee",   hands="two_hand", damage_s="1d10", damage_m="1d12", crit_range=20, crit_mult=3, damage_type="S"  })
weapon({ id="greatsword",                label="Greatsword",                   category="martial", wtype="melee",   hands="two_hand", damage_s="1d10", damage_m="2d6",  crit_range=19, crit_mult=2, damage_type="S"  })
weapon({ id="guisarme",                  label="Guisarme",                     category="martial", wtype="melee",   hands="two_hand", damage_s="1d6",  damage_m="2d4",  crit_range=20, crit_mult=3, damage_type="S",  special={"reach","trip"} })
weapon({ id="halberd",                   label="Halberd",                      category="martial", wtype="melee",   hands="two_hand", damage_s="1d8",  damage_m="1d10", crit_range=20, crit_mult=3, damage_type="PS", special={"brace","trip"} })
weapon({ id="lance",                     label="Lance",                        category="martial", wtype="melee",   hands="two_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=3, damage_type="P",  special={"reach"} })
weapon({ id="ranseur",                   label="Ranseur",                      category="martial", wtype="melee",   hands="two_hand", damage_s="1d6",  damage_m="2d4",  crit_range=20, crit_mult=3, damage_type="P",  special={"reach","disarm"} })
weapon({ id="scythe",                    label="Scythe",                       category="martial", wtype="melee",   hands="two_hand", damage_s="1d6",  damage_m="2d4",  crit_range=20, crit_mult=4, damage_type="PS", special={"trip"} })

-- ── Martial — Ranged ─────────────────────────────────────────────────────────
weapon({ id="shortbow",                  label="Shortbow",                     category="martial", wtype="ranged",  hands="two_hand", damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=3, range_inc=60,  damage_type="P"  })
weapon({ id="shortbow_composite",        label="Shortbow (Composite)",         category="martial", wtype="ranged",  hands="two_hand", damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=3, range_inc=70,  damage_type="P"  })
weapon({ id="longbow",                   label="Longbow",                      category="martial", wtype="ranged",  hands="two_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=3, range_inc=100, damage_type="P"  })
weapon({ id="longbow_composite",         label="Longbow (Composite)",          category="martial", wtype="ranged",  hands="two_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=3, range_inc=110, damage_type="P"  })
weapon({ id="throwing_axe",              label="Throwing Axe",                 category="martial", wtype="thrown",  hands="light",    damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=2, range_inc=10,  damage_type="S"  })

-- ── Exotic — Light ────────────────────────────────────────────────────────────
weapon({ id="kama",                      label="Kama",                         category="exotic",  wtype="melee",   hands="light",    damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=2, damage_type="S",  special={"monk","trip"} })
weapon({ id="nunchaku",                  label="Nunchaku",                     category="exotic",  wtype="melee",   hands="light",    damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=2, damage_type="B",  special={"monk","disarm"} })
weapon({ id="sai",                       label="Sai",                          category="exotic",  wtype="thrown",  hands="light",    damage_s="1d3",  damage_m="1d4",  crit_range=20, crit_mult=2, range_inc=10,  damage_type="B",  special={"monk","disarm"} })
weapon({ id="siangham",                  label="Siangham",                     category="exotic",  wtype="melee",   hands="light",    damage_s="1d4",  damage_m="1d6",  crit_range=20, crit_mult=2, damage_type="P",  special={"monk"} })

-- ── Exotic — One-Handed ───────────────────────────────────────────────────────
weapon({ id="bastard_sword",             label="Bastard Sword",                category="exotic",  wtype="melee",   hands="one_hand", damage_s="1d8",  damage_m="1d10", crit_range=19, crit_mult=2, damage_type="S"  })
weapon({ id="dwarven_waraxe",            label="Dwarven Waraxe",               category="exotic",  wtype="melee",   hands="one_hand", damage_s="1d8",  damage_m="1d10", crit_range=20, crit_mult=3, damage_type="S"  })
weapon({ id="whip",                      label="Whip",                         category="exotic",  wtype="melee",   hands="one_hand", damage_s="1d2",  damage_m="1d3",  crit_range=20, crit_mult=2, damage_type="S",  special={"reach","disarm","nonlethal"} })

-- ── Exotic — Two-Handed ───────────────────────────────────────────────────────
weapon({ id="dwarven_urgrosh",           label="Dwarven Urgrosh",              category="exotic",  wtype="melee",   hands="two_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=3, damage_type="PS", special={"double","brace"},   double_secondary={ damage_s="1d4", damage_m="1d6", crit_range=20, crit_mult=3, damage_type="S"  } })
weapon({ id="gnome_hooked_hammer",       label="Gnome Hooked Hammer",          category="exotic",  wtype="melee",   hands="two_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=3, damage_type="B",  special={"double","trip"},    double_secondary={ damage_s="1d3", damage_m="1d4", crit_range=20, crit_mult=4, damage_type="P"  } })
weapon({ id="orc_double_axe",            label="Orc Double Axe",               category="exotic",  wtype="melee",   hands="two_hand", damage_s="1d6",  damage_m="1d8",  crit_range=20, crit_mult=3, damage_type="S",  special={"double"},           double_secondary={ damage_s="1d6", damage_m="1d8", crit_range=20, crit_mult=3, damage_type="S"  } })
weapon({ id="spiked_chain",              label="Spiked Chain",                 category="exotic",  wtype="melee",   hands="two_hand", damage_s="1d6",  damage_m="2d4",  crit_range=20, crit_mult=2, damage_type="P",  special={"reach","disarm","trip"} })
weapon({ id="two_bladed_sword",          label="Two-Bladed Sword",             category="exotic",  wtype="melee",   hands="two_hand", damage_s="1d6",  damage_m="1d8",  crit_range=19, crit_mult=2, damage_type="S",  special={"double"},           double_secondary={ damage_s="1d6", damage_m="1d8", crit_range=19, crit_mult=2, damage_type="S"  } })

-- ── Exotic — Ranged ───────────────────────────────────────────────────────────
weapon({ id="bolas",                     label="Bolas",                        category="exotic",  wtype="thrown",  hands="one_hand", damage_s="1d3",  damage_m="1d4",  crit_range=20, crit_mult=2, range_inc=10,  damage_type="B",  special={"trip","nonlethal"} })
weapon({ id="hand_crossbow",             label="Hand Crossbow",                category="exotic",  wtype="ranged",  hands="light",    damage_s="1d3",  damage_m="1d4",  crit_range=19, crit_mult=2, range_inc=30,  damage_type="P"  })
weapon({ id="net",                       label="Net",                          category="exotic",  wtype="ranged",  hands="two_hand", damage_s="-",    damage_m="-",    crit_range=20, crit_mult=2, range_inc=10,  damage_type="-",  special={"entangle"} })
weapon({ id="repeating_heavy_crossbow",  label="Repeating Heavy Crossbow",     category="exotic",  wtype="ranged",  hands="two_hand", damage_s="1d8",  damage_m="1d10", crit_range=19, crit_mult=2, range_inc=120, damage_type="P"  })
weapon({ id="repeating_light_crossbow",  label="Repeating Light Crossbow",     category="exotic",  wtype="ranged",  hands="two_hand", damage_s="1d6",  damage_m="1d8",  crit_range=19, crit_mult=2, range_inc=80,  damage_type="P"  })
weapon({ id="shuriken",                  label="Shuriken",                     category="exotic",  wtype="thrown",  hands="light",    damage_s="1d1",  damage_m="1d2",  crit_range=20, crit_mult=2, range_inc=10,  damage_type="P",  special={"monk"} })

-- ── Helper functions ──────────────────────────────────────────────────────────

--- Returns all weapons of a given category, sorted by id.
function dnd35.weapons_by_category(category)
	local out = {}
	for _, w in pairs(dnd35.WEAPONS) do
		if w.category == category then
			table.insert(out, w)
		end
	end
	table.sort(out, function(a, b) return a.id < b.id end)
	return out
end

--- Returns the appropriate damage dice string for a weapon given the wielder's size.
--- Uses damage_s for Small or smaller, damage_m for Medium or larger.
--- (Full SRD size scaling — Fine through Colossal — is handled by combat.lua.)
function dnd35.weapon_damage_for_size(weapon_id, size)
	local w = dnd35.WEAPONS[weapon_id]
	if not w then return nil end
	if size == "small" or size == "tiny" or size == "diminutive" or size == "fine" then
		return w.damage_s
	end
	return w.damage_m
end
