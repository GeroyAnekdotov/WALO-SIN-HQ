# WALO SIN HQ development rules

## Project

- Stable release metadata lives in `VERSION.json`; the current release is 2.0.1, following the internally tested `2.0.1-test.2` build. Preserve unique versioned packages and independent optional-component histories.
- Target Anomaly GAMMA, WALO 1.6.11 and UNISG Command & Operations v1.0.3. Do not change working gameplay during documentation or packaging tasks.
- All external installations, MO2 profiles, Overwrite, upstream distributions, the shared reference library and the sibling UNISG project are read-only. Write only in this repository.
- Never stage, commit, tag, push, change repository visibility or publish without explicit approval. Preserve pre-existing work and historical releases.

## Sources and public contents

- The external reference library is `../_shared_reference/`; begin with its `INDEX.md` and `environments/GAMMA/ENVIRONMENT.md`. Do not invent missing references or copy them into the repository.
- Local source maps and diagnostic paths are in ignored `_reference/ENVIRONMENT.md`. Historical development material is preserved locally under ignored `_reference/`; maintain it only when explicitly requested.
- The installable payload is `gamedata/`. Keep references, upstream distributions, local paths, personal data, MO2 metadata, saves, logs, dumps, temporary diagnostic components and old test ZIPs out of public commits and release assets.
- Public verification uses `RELEASE_FILES_SHA256.txt`, `tests/import_baseline_sha256.txt` and the maintained runners in `tools/`. Historical import hashes are evidence, not a manifest to rewrite after gameplay changes.

## Integration boundaries

- `warfare.script` is the combined WALO/UNISG/SIN full override. Preserve UNISG's mode checks, HQ restoration and new-game seeding. Never replace it wholesale with stock WALO or another version.
- Preserve SIN's `greh` faction ID, mine `red_smart_terrain_3_2`, surface `red_smart_terrain_4_2`, native named services, task IDs, saved keys and private furniture identities.
- The addon requires Warfare ON / Story Mode OFF. Reuse Core `enabled()` and its two-phase mode check. Preserve cleanup/restoration on unsupported-mode startup; do not remove stock Story/Mortal Sin or DRX content.
- WALO owns population, service spawning, capture/recapture and resurrection. Do not add a parallel squad spawner or alter shared spawn positions to fix NPC jobs.
- Keep the medic and bartender exclusive jobs scoped to exact generated SIN services on the greh-owned mine. Medic restoration belongs at the assigned-smart spawn entry, which can bypass `xr_logic.initialize_obj`. Preserve previous-handler delegation and repeated-load idempotence.
- Do not move tested furniture or workbench poses, alter bypass vertex 5182, reset unrelated NPCs, add repeated teleportation or disable collision without a specific authorized task.
- Preserve native GAMMA workshop/sleep behavior, tagged-object duplicate prevention and delayed-use save-boundary checks. Preserve the bounded DAO creation filter; do not delete saved anomalies or alter DRX quests.
- Inspect the whole wrapper chain before changing shared trade, toolkit, smart-property or AI methods. Keep companion science-bunker trade and UNISG behavior intact.

## Validation and release

- For relevant gameplay failures, read actual runtime logs through the ignored environment map; check sizes, times and session/package correlation. Never modify originals or claim a cause from filenames or missing errors. Inspect dumps only with suitable tools and matching build evidence.
- Use targeted checks for small changes and all three maintained suites for releases. Lua checks require Lupa `lua51` and external reference scripts; see `DEVELOPMENT.md`. X-Ray's controller dialect is verified by hash.
- The author confirmed the final HQ gameplay on the tested prerelease. Do not claim a complete Story Mode or DRX playthrough or compatibility with every external mod/version.
- Build with `python tools/build_release.py`; verify runtime allowlist, configuration integrity, archive CRC and source equality. Do not add a LICENSE or relicense upstream work without confirmed rights and a chosen license.
- Report to the owner in Russian, concisely, separating source checks from actual gameplay observations and unresolved limitations.
