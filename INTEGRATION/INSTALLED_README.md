# WALO Sin HQ 2.0 Core - TEST BUILD (27 October 2026)

The first milestone of Sin HQ 2.0: Warfare-only/Story-OFF mine HQ, no furniture yet.

## Installation (MO2)
1. Disable and REMOVE the old `WALO Sin HQ v1.3` mod from the active MO2 profile. Do not stack it with 2.0.
2. Enable `Warfare ALife Overhaul 1.6.11` and `WALO UNISG Command and Operations 1.0.3`.
3. Install this ZIP as a separate MO2 mod; set priority **after both**, so its `gamedata/scripts/warfare.script` wins.
4. Do not replace/remove Science Bunker Trade Inheritance v1.4 if you already have it.
5. Back up the saves. Test on a NEW Warfare/Story OFF game before using long-term saves.

Only three small call sites were added to the existing UNISG-enhanced `warfare.script`; audit their diff in `INTEGRATION`.
UNISG `ui_mm_faction_select.script` is reused unchanged from the installed UNISG mod.
No extra Sin start was added: GAMMA already has the original `red_forest_old_mine` start location.

## Gated features
- Only if `IsWarfare()` is true AND Story Mode is explicitly OFF: move Greh HQ from surface smart `red_smart_terrain_4_2` to the underground mine `red_smart_terrain_3_2` in the WALO in-memory registry.
- Swap the mine and surface smart role properties in memory, not in global LTX.
- Four service role minima in WALO's native uniqueness table, and four effective squad slots.
- Retain the v1.3 trader, medic/barman map markers, Dazhbog toolkit compatibility and medic drugkit task; the latter is Story gated.
- The original mine travel_hub = 1 is preserved in both enabled and disabled modes.
- ReDone North is explicitly excluded as in v1.3.

## NOT in this ZIP
- Furniture, seated AI jobs, bed, lights, sleep map spot, DAO and campfire extras. These are later milestones.
- The separate Science Bunker v1.4 plugin is not embedded or modified.

## Important limitations
- Lua syntax verified with texlua; the X-Ray runtime/game engine is NOT available in this environment.
- Existing saves created with the old 1.3 DLTX population overlay may already have irreversible simulation effects. This build does not undo historical game state or delete squads.
- Test fresh new game, existing Warfare save, Warfare+Story and plain Story before enabling this on main saves.
- Do not run simultaneous conflicting modifications of warfare.script (MO2's final version must be the one from this build).
- WALO native service NPCs may spawn on their normal timer (not immediately).

## Useful debug logs
Search the xray log for `[Sin HQ 2.0 Core]` and `[WALO UNISG native]`.
