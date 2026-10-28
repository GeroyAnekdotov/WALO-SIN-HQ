# WALO SIN HQ 2.0 Core - Test Development Baseline

This repository contains the installed **SIN HQ 2.0 Core test build**, dated 27 October 2026, prepared for further development on 28 October 2026. **This is a test version, not a final release.**

All eight files under `gamedata/` were imported unchanged from `WALO_Sin_HQ_2.0_Core_TEST_MO2` and checked by SHA-256. Repository preparation did not change gameplay or deploy anything to GAMMA.

## Current scope

The Core module is designed for **Warfare ON / Story Mode OFF**. It relocates the native WALO SIN headquarters from the Red Forest surface camp (`red_smart_terrain_4_2`) to the mine (`red_smart_terrain_3_2`) through temporary Lua state. It requests four effective squad slots and native trader, mechanic, medic and barman service minima. WALO controls service spawning and timing.

The test package also contains SIN trading, PDA service markers, Dazhbog toolkit compatibility, and a medic drugkit task with English and Russian text. It does not add furniture, seated AI jobs, beds, lights, sleep markers, DAO features or campfire extras.

**Story Mode isolation is unfinished.** The HQ Core and medic task have a Story Mode check, but the inherited trade/marker and toolkit modules do not use that check. They can still act in Warfare with Story Mode enabled when their other conditions match. This is a code finding; its in-game consequences have not been tested here. Developing complete SIN HQ disabling in Story Mode is the next task.

## Dependencies and MO2 layout

The current combined test setup uses S.T.A.L.K.E.R. Anomaly GAMMA, **Warfare ALife Overhaul 1.6.11**, **UNISG Command & Operations v1.0.3**, and DLTX support. It relies on existing GAMMA trade, task, NPC and toolkit systems. Compatibility with other versions has not been established.

For a future test installation:

1. Keep the older SIN HQ v1.3 disabled; do not stack it with 2.0.
2. Enable the matching WALO and UNISG versions.
3. Give SIN HQ higher MO2 file priority than both, so its combined `gamedata/scripts/warfare.script` wins. MO2 usually shows higher-priority mods lower in its left pane.
4. Keep Science Bunker Trade Inheritance v1.4 as a separate mod if it is used. It is not embedded here. ReDone North is excluded by the Core's compatibility check; complete package isolation with it remains unverified.
5. Back up saves and start testing with a fresh game before using long-term saves.

The installable payload is `gamedata/` at the archive root. Do not package `.git/`, `_reference/`, the shared library, or MO2's local metadata. No installation or profile change was performed during this preparation.

The existing `warfare.script` is **WALO + UNISG + SIN**, not a standalone SIN script. Comparison against v1.0.3 found only three added SIN calls and three accompanying comments; UNISG's existing code is preserved. Replacing it with stock WALO would lose UNISG integration. The UNISG menu remains supplied by the separate UNISG mod.

## Files and development references

| Location | Purpose |
|---|---|
| `gamedata/scripts/warfare.script` | Combined WALO/UNISG controller with three SIN lifecycle calls |
| `gamedata/scripts/zzzzzz_walo_sin_hq_core.script` | Mode checks, HQ relocation, properties, capacity and service restoration |
| `gamedata/scripts/zzzzz_walo_greh_mine_trade_spots.script` | SIN trade routing, bunker compatibility and PDA service markers |
| `gamedata/scripts/zzzzzz_walo_sin_hq_toolkit_bridge.script` | Dazhbog toolkit compatibility |
| `gamedata/configs/` | Trader stock, medic task and two localized string tables |
| [AGENTS.md](AGENTS.md) | Development rules and read-only shared-library entry points |
| [Development baseline](INTEGRATION/DEVELOPMENT_BASELINE.md) | Source comparison, dependencies, Story Mode gaps and next-step checks |
| [Gameplay checksums](INTEGRATION/BASELINE_GAME_FILES_SHA256.txt) | Exact imported gameplay baseline; not a claim of game testing |
| [Original package README](INTEGRATION/INSTALLED_README.md) | Preserved historical test-build notes |
| [TESTING_RU.md](TESTING_RU.md) | Original Russian scenario checklist; not completed test results |

The shared reference library stays outside this repository at `../_shared_reference/`. Read its `INDEX.md` and `environments/GAMMA/ENVIRONMENT.md` through the rules in `AGENTS.md`; it is not bundled with this mod. Machine-specific paths and the current profile audit are kept in ignored `_reference/` notes.

## Verification and limits

Preparation verified the import hashes, the exact additive SIN/UNISG comparison, both XML files using their declared encodings, and relevant file providers in the selected MO2 profile. The imported Russian XML remains Windows-1251.

**No game was launched and no in-game tests were performed.** The historical package README mentions an earlier Lua syntax check; that check was not repeated here. Profile order identifies expected file winners, but does not verify a running MO2 virtual filesystem, DLTX results or Lua wrapper order.

The repository is ready to develop Story Mode isolation while preserving Warfare. It is not a validated Story Mode compatibility fix. Existing saves may contain NPCs or effects from older versions; this baseline does not remove objects or migrate saves. No commit or push was made.
