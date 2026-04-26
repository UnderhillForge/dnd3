Goal by End of Week 2
You can:

Create/load a character
Join a multiplayer session
Roll dice (with advantage/disadvantage)
Use initiative tracker
Move tokens on a map
Run basic combat (attack rolls → damage → apply effects)
GM can control fog of war and spawn enemies


Week 1: Core Systems & Character Foundation (Days 1–7)
Focus: Get the skeleton of a working VTT.





















































DayGoalKey DeliverablesPriority1Project Setup & Character Sheet CoreFinish renaming cleanup
Create mods/dnd3_core/systems/character_sheet/ (api + persistence)Must2Basic Character Sheet UI + dnd35 IntegrationImplement simple tabbed formspec sheet
Register dnd35 character sheet with ability scores, HP, ACMust3Dice Roller (Core + UI)Rich dice parser (/roll 1d20+5, advantage, private rolls)
3D tumbling dice (optional, can be basic first)Must4Initiative TrackerTurn order list, add/remove, auto-sort by initiative
Round counterMust5Token System + Basic MovementPlace/move/scale/rotate tokens
Link tokens to character sheetsMust6Fog of War + Basic GM ToolsReveal/hide areas
GM vs Player visibilityHigh7Integration & First PlaytestPut it all together in one world
Run a 5-minute combat test (yourself or with 1 friend)Must
End of Week 1 Target: You can create characters, roll dice, track turns, and move tokens around a map.

Week 2: Combat Loop & Polish (Days 8–14)
Focus: Make combat feel like real D&D.













































DayGoalKey Deliverables8Combat Automation BasicsAttack rolls linked to weapons
Damage application to HP9Conditions & EffectsBasic condition tracker (Prone, Poisoned, etc.) + visual indicators on tokens10Inventory + EquippingSimple drag-and-drop inventory
Equip weapons/armor that affect stats11Spells & CastingSpell list browser + basic "cast" button (rolls + visual feedback)12Multiplayer Sync & PolishTest 2–3 players + GM
Fix desync issues13GM ToolboxQuick monster spawn, basic loot, lighting controls14Playtest + DocumentationRun a full short session (Level 1 combat)
Write quick "How to Play" guide
Record a short demo video
End of Week 2 Target: You can run a real 1–2 hour playtest session with friends.

Daily Workflow Recommendation

Morning (1–2 hrs): Implement new feature
Afternoon (1–2 hrs): Test + fix bugs
Evening (30–60 min): Update docs/lua-api.md and commit

Total estimated effort: 4–6 hours per day (very doable for one developer).

Success Criteria (What “Done” Looks Like)
By Day 14 you should be able to:

Start a new session
Players create/import characters
GM places tokens + monsters
Run 3–4 rounds of combat with dice, attacks, damage, and conditions
Everyone has fun and it feels like D&D (even if visuals are still basic)


Would you like me to expand this into a more detailed daily task list with specific prompts you can give your coding agent each day? I can also include:

Checklist template
Testing criteria per day
Prioritized stretch goals (e.g. 3D avatar preview, slopes, sound)
