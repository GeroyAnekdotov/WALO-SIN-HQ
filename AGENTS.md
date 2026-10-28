# Working Rules for WALO SIN HQ 2.0

## Project and Change Boundaries

- Current baseline: **SIN HQ 2.0 Core TEST**, package dated 27 October 2026, targeting S.T.A.L.K.E.R. Anomaly GAMMA + WALO 1.6.11 + UNISG Command & Operations v1.0.3. Do not describe it as a final release or change its version without a specific task.
- External GAMMA, MO2, mods, profiles, Overwrite and game directories are **read-only sources**, regardless of location. Do not install, create files, change settings or run write-producing operations there.
- The sibling UNISG project is a read-only integration reference. A SIN task does not authorize changes to UNISG.
- Keep changes and generated outputs inside this repository and within the task's scope. Do not change Lua, XML, LTX or gameplay during documentation or setup work. Record discovered implementation gaps instead of fixing them without authorization.
- Do not commit, push, stage files, deploy or publish unless the user explicitly requests that action. Preserve pre-existing changes.
- Keep `/_reference/` and `/_shared_reference/` ignored. Do not force-add local notes or reference material. Do not copy the shared library into the repository or a test/release archive.
- Keep absolute machine-specific paths, profile contents and local audit data out of published documentation. The installable payload is the root `gamedata/` directory; MO2 `meta.ini` is local installation metadata and is not part of the imported payload.

## Sources and Investigation Workflow

- The external shared library is `../_shared_reference/`, used **for reading only**. Start at `../_shared_reference/INDEX.md` and `../_shared_reference/environments/GAMMA/ENVIRONMENT.md`; consult `../_shared_reference/projects/SIN_HQ.md` and the source-resolution tools when needed. These files may be absent in another clone; never invent their contents.
- Library maintenance requires an explicit user task. Older library notes predate the creation of this repository; that historical absence does not mean this repository is missing now. Keep task-specific local evidence in ignored `_reference/` and do not update the library as a side effect.
- Use `INTEGRATION/DEVELOPMENT_BASELINE.md` for this import's findings and `INTEGRATION/BASELINE_GAME_FILES_SHA256.txt` for its eight original gameplay files. The installed package's original checksum list is preserved separately; its `README.md` entry refers to `INTEGRATION/INSTALLED_README.md` here.
- Reuse audits while the source versions, file set and profile remain unchanged. Start with affected files, matching upstream sources and their direct callers/callees; expand by specific symbols rather than scanning the entire installation unnecessarily.
- Confirm the selected MO2 profile from its configuration. Setup found the actual profile name **G.A.M.M.A**, whereas the requested `GAMMA` directory did not exist. Do not create or rename profiles to resolve that spelling difference; recheck the selected profile if configuration changes.
- Distinguish installed files, preserved WALO/Anomaly sources, expected MO2 winners, running VFS, DLTX application and Lua execution order. A profile listing alone does not validate the runtime. Missing loose files can come from game archives.
- Separate confirmed facts, intended behavior, inferences and untested risks. Cite file/function names and relevant line numbers. Preserve original encodings and line endings, particularly the Windows-1251 Russian XML.

## Shared Files and Integration

- `gamedata/scripts/warfare.script` is a **combined WALO 1.6.11 / UNISG v1.0.3 / SIN** full-file override. Never replace it with stock WALO, an older SIN file, or a different upstream version as a shortcut.
- The baseline adds only `zzzzzz_walo_sin_hq_core.apply_loaded()`, `apply_new_game()` and `on_walo_start()` to UNISG's controller, with three comments. Preserve their timing and UNISG's existing mode checks, HQ registration, capacity, ownership, native spawning and restoration.
- Before modifying this file, compare against the corresponding WALO and UNISG versions, inspect the existing integration patch and check active MO2 providers and priorities. Port targeted changes when changing baselines; do not copy a complete override over another version.
- Preserve UNISG's `jup_b208`, `isg_sim_squad_novice` and save key `walo_unisg_hq_native_v03`, plus all unrelated UNISG code and state. New-game squad seeding must not be repeated during loading.
- The separate UNISG mod supplies its menu and other gameplay files. Do not add another faction-selection override or a new SIN start during setup. The package reuses `red_forest_old_mine`.
- Preserve WALO's public HQ registry, native unique-service loop, capture/recapture, population scaling, ownership and resurrection systems. Do not introduce a parallel NPC/squad spawner to replace them without an explicit task.
- Inspect the whole wrapper chain when affecting `simulation_objects.get_props`, `trade_manager.trade_init`, `trade_manager.update` or `xr_conditions.toolkit_task_done`. Preserve previous-handler delegation, scope restrictions and other mods' changes; examine repeated loads and wrapper installation within one process.
- Science Bunker Trade Inheritance v1.4 remains a separate optional companion. Preserve scientific trade at `yan_smart_terrain_6_4` and `jup_b41`, including its supply selection. Do not replace global GAMMA trader files to fix SIN's private profile.
- Check DLTX task/section collisions and real application order. A unique filename does not prove that section IDs or global state are isolated.

## SIN, Warfare and Story Mode

- SIN's internal faction ID is **`greh`**. The mine is `red_smart_terrain_3_2`; the surface camp is `red_smart_terrain_4_2`. Do not rename these IDs or confuse them with UNISG's `isg`.
- Intended HQ mechanics require **Warfare ON / Story Mode OFF**. Preserve the two-stage check: new-game menu state in `axr_main.config` before the saved infoportion exists, then `story_mode_disabled` together with `not IsStoryMode()` on ordinary loads. Both stages also require Warfare.
- Core HQ changes are not player-faction restricted. The existing toolkit bridge additionally requires a `greh` actor. Player-faction and game-mode checks serve different purposes; do not silently substitute one for the other.
- Full Story Mode isolation is **not yet implemented or validated**. Trade/marker `enabled()` checks Warfare and actor availability; toolkit `enabled()` also checks the actor faction. Neither uses the Core Story Mode/ReDone North check. The medic task's availability condition uses the Core check, but this does not prove cleanup of an already accepted task.
- When a task authorizes isolation work, cover all entry points and state: HQ registry, smart properties, capacity, service minima, trade/markers, toolkit infoportions, task availability and existing task state. Disabling this addon must leave native Warfare and stock Story/Mortal Sin NPCs and quests working.
- Keep `on_walo_start()` cleanup reachable in Story Mode and non-Warfare loads. Blocking all startup work behind the active-mode check would prevent restoration of changes left by an earlier save.
- Preserve restoration of the mine's original `travel_hub = 1`, the surface Greh HQ, prior properties/capacity and the service table. Respect external modifications; do not reset unrelated state to assumed defaults.
- The Core excludes ReDone North using its installed squad-target signature. Do not claim that this currently excludes every inherited module or every possible ReDone North version.
- Keep native spawning and original named SIN services distinct from addon behavior. Preserve `red_greh_trader`, `red_greh_tech`, `sim_default_greh_*`, task IDs and toolkit/drugkit infoportions. Do not delete story NPCs or squads to hide HQ features.
- Spawned A-Life objects and infoportions can remain in saves. Do not perform deletion, migration or rollback outside the task. Old v1.3 saves are not repaired automatically; recommend copies of saves or a pre-installation save for testing.
- Recheck random starts, late smart-property refreshes and population changes when related code changes. The SIN call occurs before WALO's random-start return, whereas UNISG's initial seeding occurs after it; their behavior must not be assumed identical.

## Validation and Reporting

- This preparation established file integrity and static integration facts. It did not run the game, validate the running VFS/DLTX, or repeat the historical Lua syntax check. Historical package notes and `TESTING_RU.md` are not new test results.
- For documentation/setup, review the diff, links, imported hashes and installable layout. For authorized gameplay changes, choose meaningful available checks and state which in-game scenarios still require the author. Never invent tests, observed behavior or compatibility guarantees.
- Apply scenarios appropriate to the change: fresh Warfare/Story OFF; Warfare/Story ON; Warfare OFF with Story ON and OFF; ordinary loads; repeated loads and switching saves without restarting; greh and other actor factions; random starts; population changes; capture/recapture; service respawn; trading; toolkit/drugkit tasks; PDA markers; UNISG HQ; science bunkers; ReDone North.
- Keep the import checksum manifest as historical baseline evidence. Do not rewrite it merely to make changed gameplay files pass an old-baseline check; record intentional differences when implementation is authorized.
- Explain results to the user in Russian and plain language: what changed, what was checked, dependencies, remaining uncertainty and readiness for the next task. Describe code risks as risks until reproduced in game.
