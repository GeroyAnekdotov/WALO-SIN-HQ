# SIN HQ 2.0 Core: development baseline and integration audit

Prepared on **28 October 2026** from the installed `WALO_Sin_HQ_2.0_Core_TEST_MO2` test package. Its original README dates the package to 27 October 2026. This is a source/setup audit, not a final release or an in-game test report.

## Import and provenance

The eight gameplay files were copied byte for byte, preserving the MO2 `gamedata/` layout:

| Path relative to `gamedata/` | Role |
|---|---|
| `scripts/warfare.script` | WALO/UNISG controller plus three SIN calls |
| `scripts/zzzzzz_walo_sin_hq_core.script` | HQ relocation, mode guard, properties, service minima and capacity |
| `scripts/zzzzz_walo_greh_mine_trade_spots.script` | Trade routing, science-bunker compatibility and medic/barman map spots |
| `scripts/zzzzzz_walo_sin_hq_toolkit_bridge.script` | Dazhbog toolkit condition and infoportion bridge |
| `configs/items/trade/trade_walo_greh_mine_trader.ltx` | Private SIN trader profile |
| `configs/misc/task/mod_task_manager_walo_sin_hq.ltx` | DLTX medic drugkit task |
| `configs/text/eng/walo_sin_hq_start.xml` | Five English task strings, UTF-8 |
| `configs/text/rus/walo_sin_hq_start.xml` | Five Russian task strings, Windows-1251 |

The original test checklist remains at `../TESTING_RU.md`. The original integration patch is retained in this directory. The installed README was preserved as `INSTALLED_README.md`; the old manifest was renamed `INSTALLED_SHA256_MANIFEST.txt`. Its paths describe the original package, so its `README.md` entry now maps to `INSTALLED_README.md`, not the new repository README. Its `TESTING_RU.md` and `gamedata/` entries retain their repository-relative locations.

`BASELINE_GAME_FILES_SHA256.txt` records the actual eight imported gameplay files. `.gitattributes` prevents Git newline conversion for the imported payload and original package notes. MO2 `meta.ini` was inspected but excluded because it contains local installation metadata. No shared-library contents or UNISG files were imported.

## Baselines and shared controller

The installed WALO metadata reports `1.6.11.0`; all three controllers identify their WALO base as `1.6.11`. The installed WALO controller matches the preserved shared-library WALO source. The installed UNISG controller matches the sibling UNISG repository; all **37** UNISG gameplay files also match their installed counterparts.

| Controller | SHA-256 of bytes read |
|---|---|
| WALO 1.6.11 | `535053db40f6b926f22f7a7946c0d23ab0a9c80da3ff7acc1855e7deb55fb70c` |
| UNISG v1.0.3 | `83e3c20480c5fb0c1c29543cd3dbcf517fb4e4df7785db56ecf922d5b4c877ba` |
| Combined SIN test build | `1d54b521ca3b6971255dbe1e3bab36555c0aed61925433f5e2fbb2fd85c502a5` |

Comparison of SIN against UNISG found exactly **six added lines: three comments and three calls**, with no removed or changed UNISG lines. Removing precisely those six lines reconstructed the UNISG file exactly. The retained `UNISG_1.0.3_to_UNISG_plus_Sin_warfare.patch` describes the same additions.

| SIN call in the imported `warfare.script` | Timing |
|---|---|
| `apply_loaded()` at line 492 | After `unisg_hq_restore()`, before the first Warfare world update |
| `apply_new_game()` at line 1094 | After the initial-fill guard, before WALO's ownership/spawn pass and random-start return |
| `on_walo_start()` at line 1687 | At startup, before UNISG reset and ordinary callback initialization; must remain reachable for inactive modes |

The inherited UNISG extension includes its two-stage mode gate, `jup_b208` registration, native service slots, effective capacity, new-game squad seeding and the `walo_unisg_hq_native_v03` save key. These remain present unchanged. This proves preservation of that source code; it does not prove its runtime behavior in the combined installation.

The external UNISG `ui_mm_faction_select.script` consumes `new_game_faction` during loading and later handles `new_game_story_mode` / `story_mode_disabled` (lines 188-287). Its menu stores the initial values at lines 1730 and 1740. This ordering explains why the new-game check cannot simply be replaced by a saved-state check.

## Selected MO2 profile and expected winner

The requested directory name `GAMMA` was not found. Reading MO2's selected-profile setting confirmed **G.A.M.M.A**. That existing profile was used for analysis without changing it. Absolute paths and provider records are stored only in ignored `_reference/` notes; the shared environment map supplies the external source paths.

The actual `modlist.txt` has the following enabled entries, from higher to lower file priority:

| Mod | Line in `modlist.txt` | Supplies `warfare.script` |
|---|---:|---|
| SIN HQ 2.0 Core TEST | 2 | Yes: expected winner |
| UNISG Command & Operations v1.0.3 | 3 | Yes |
| Science Bunker Trade Inheritance v1.4 | 4 | No |
| Warfare ALife Overhaul | 19 | Yes |

All enabled mod directories were checked for the combined controller, the three SIN modules, the private trader profile and the task overlay. Only the three listed controller providers were found; the other five checked paths were supplied by SIN alone. None of these six paths existed in Overwrite or the game's loose `gamedata/` directory. This does not inspect every config fragment or archived game file.

This establishes **expected loose-file winners**. A running MO2 VFS, effective DLTX sections and runtime Lua handler order were not inspected. Enabled mods do not establish Warfare/Story settings inside a save.

## SIN Core behavior relevant to future isolation

The following line references are to the unchanged `zzzzzz_walo_sin_hq_core.script`:

- `mode()` (28-44) requires Warfare, excludes the recognized ReDone North signature, then uses either the new-game menu choice or the saved Story-OFF state. An unchecked new-game Story checkbox is represented by nil, matching the UNISG/menu convention; it must not be reinterpreted as an unknown saved-state value.
- `register_base()` / `reset_base()` (101-133) move the Greh HQ between `red_smart_terrain_4_2` and `red_smart_terrain_3_2` through WALO's registry. The mine's original `travel_hub = 1` is carried through activation and restoration. WALO's matching `configs/misc/warfare_smarts.ltx` defines the surface HQ at 148-151 and the mine hub at 153-154.
- Property changes and the `simulation_objects.get_props` wrapper (60-99) affect only the two named smarts while registered and enabled. They are in-memory changes; this package supplies no global HQ/population LTX overlay.
- Service registration (135-172) sets four native minima and remembers prior values. WALO's `smart_terrain_warfare.check_unique_npcs()` manages actual NPC spawning. Existing named trader/mechanic recognition and respawn behavior need game checks; comments describing them are not proof of observed spawns.
- Capacity (174-196) uses `4 / population_factor` so WALO's scaling can produce four effective slots. Later changes to the population factor need separate verification.
- `apply_new_game()` and `apply_loaded()` (221-230) distinguish menu context from a saved game. SIN has no equivalent of UNISG's opt-in save marker in this baseline and can apply to an existing eligible Warfare save.
- `on_walo_start()` (270-277) restores prior live properties/capacity, registry and service minima even when the next save is Story/non-Warfare. Restoration is conditional and must respect other mods' changes. It restores Lua metadata, not historical A-Life objects or all saved effects.

There is no separate SIN spawner in the Core. Keep WALO responsible for ownership, production and service spawning. Do not disable Warfare itself as a way to disable SIN HQ.

## Confirmed gaps and next implementation scope

The package's advertised Warfare-only/Story-OFF scope is not consistently applied across its inherited modules:

| Entry point | Current condition | What remains to investigate/implement |
|---|---|---|
| Core relocation / service minima / capacity | Core `mode()` | Preserve new-game/load distinction and inactive-mode restoration |
| Medic task availability | `walo_sin_hq_mode_enabled()`; task LTX line 11, Core lines 232-237 | Covers availability; already accepted tasks, completion and prior reward flags are not thereby disabled |
| Trade router and scientific supply sync | Trade module `enabled()` at 27-29: Warfare + actor | No Story or ReDone North gate; trader routing applies faction-wide, not only in the mine |
| Medic/barman PDA spots | Same trade module gate; `update_spots()` at 213 | No Story gate; inactive-mode removal of already created spots is not established |
| Dazhbog toolkit condition and flag sync | Toolkit `enabled()` at 10-13: Warfare + greh actor | No Story or ReDone North gate; `sync_existing_story_unlocks()` can write WALO tier infoportions |
| Installed wrappers and cached data | Separate installation/reset rules in each module | Repeated loads, switching saves and external handler replacement need analysis; skipping callbacks alone is insufficient evidence of cleanup |

These are static findings, not reproduced game failures. No fix was applied during preparation. A future isolation task should use a consistent mode policy for SIN-owned side effects, retain cleanup in inactive modes, and review effects already present in a save. Do not assume a single extra guard in `warfare.script` will cover trade, markers, toolkits and tasks.

Keep player-faction restrictions separate: the HQ Core serves the simulation independently of the actor's faction, while the existing toolkit bridge requires a Greh actor. Any change to that scope needs an explicit design decision.

## Other dependencies and compatibility boundaries

- **GAMMA trade/task/NPC systems and DLTX:** the private trader profile includes the existing trade discount/preset files; the medic task uses native fetch/reward functors, `itm_drugkit`, `sim_default_greh_medic_drugkit_done` and the existing task dialogue. Effective merged configs have not been validated here.
- **Science Bunker Trade Inheritance v1.4:** enabled separately. SIN excludes `yan_smart_terrain_6_4` and `jup_b41` from its faction-wide trader replacement, and adjusts the cached scientific supply condition for the current trader faction. Both addons wrap trade initialization/update; their runtime composition and restock behavior still require checks.
- **Dazhbog:** the bridge connects `red_greh_tech` to `sim_default_greh_mechanic_upgrade_tier_1..3`. Preserve existing handlers and story flags; do not create new story progression to imitate toolkit completion.
- **ReDone North:** Core detection uses `kat_greh_trader_squad.target_smart == katacomb_smart_terrain` (20-24). This is a compatibility signature, not a verified inventory of every ReDone version or proof of complete module shutdown.
- **SIN HQ v1.3:** do not stack it with 2.0. Old population overlays, squads and saved effects are not undone by this import.
- **Other versions:** precise GAMMA/Anomaly/EXE/DLTX versions remain unresolved as described in the shared environment map. Do not infer them from a WALO package requirement. Furniture, DAO and campfire systems are not current SIN Core features.

## Verification performed and remaining scenarios

Performed during preparation:

- Compared all eight imported gameplay files with the installed source by SHA-256; preserved their bytes and directory layout.
- Verified all ten entries in the original installed manifest with the documented README path mapping, and checked the retained integration patch with `git apply --reverse --check` without applying it.
- Compared the three controller baselines; reconstructed UNISG exactly by removing the six SIN additions; checked WALO's supporting smart-terrain script against the preserved source.
- Compared all 37 sibling UNISG gameplay files with the installed v1.0.3 copy.
- Parsed both localized XML files using their declared encodings and checked their five unique IDs.
- Inspected the selected profile and targeted loose-file providers; reviewed repository documentation, links and the diff.
- Rechecked the installed SIN package's 13 files, the sibling UNISG project's 48 non-Git files, MO2's configuration and the selected modlist for unchanged hashes. No files were staged, committed or pushed.

No new Lua interpreter check or in-game test was performed. The original README's texlua statement is historical. The old Russian checklist remains a proposed checklist.

For the authorized Story Mode implementation, record actual results for the relevant scenarios:

1. Fresh Warfare ON / Story OFF, with Greh and another actor faction: mine HQ, four effective slots, original services, native medic/barman timing, trade, toolkit/drugkit task and PDA.
2. Fresh Warfare ON / Story ON and ordinary loads: no SIN addon side effects; native Warfare and Story/Mortal Sin progression remain usable.
3. Warfare OFF with Story ON and OFF: normal NPCs, tasks and simulation remain intact.
4. Repeated reloads and switching between those saves within the same process: registry, capacity, service minima, wrappers, cached trade state, markers and task flags do not leak between saves.
5. Existing Warfare and older v1.3 saves on copies: identify what can be disabled safely without deleting saved objects or silently migrating progression.
6. Random starts, population changes, capture/recapture, service deaths/respawn, UNISG `jup_b208` and scientific bunker capture/trade; recognized ReDone North setup if available.

**Readiness:** the repository now has the intact installed baseline, read-only shared references, integration evidence and a defined Story Mode work area. It is ready for implementation; complete Story Mode safety and unchanged Warfare behavior require subsequent development and game testing.
