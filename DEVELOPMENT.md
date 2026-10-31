# Development and release checks

`gamedata/` is the installable source. Preserve its encodings and bytes; the Russian XML declares Windows-1251. SIN ships no `warfare.script`. Integration checks hash-pin the external WALO and UNISG controllers and execute their relevant functions with mocked engine APIs; full controller dialects are not rewritten for testing.

## Build

```text
python tools/build_release.py
```

The builder uses `VERSION.json`, checks an explicit runtime-file allowlist and writes the MO2 ZIP and its checksum under ignored `dist/`. It also writes `RELEASE_FILES_SHA256.txt` for the exact packaged sources. It refuses to overwrite a different archive at an existing version. It does not commit, tag, push or publish.

## Lua checks

The maintained runners require Lupa's `lua51` backend. Local test dependencies may be placed in ignored `_reference/python-test-deps/`. Story/service checks read preserved Anomaly scripts from the external shared reference library; that library and upstream distributions are deliberately not bundled. They must be supplied separately to reproduce those checks.

```text
python tools/check_story_mode.py
python tools/check_interior.py
python tools/check_polish.py
python tools/check_warfare_bridge.py --unisg PATH_TO_UNISG_WARFARE_SCRIPT
```

`check_story_mode.py --reference-scripts PATH` selects preserved Anomaly scripts. Its optional `--baseline-root PATH` verifies comparison inputs against the historical hashes in `tests/import_baseline_sha256.txt`. `check_polish.py` also supports `--beh-script PATH` and `--dao-script PATH`; those optional installed sources must match the audited hashes before their functions are used in tests.

The tests mock X-Ray objects. They exercise mode gates, private task effects, native service-job routing, saved-job restoration, callback/wrapper idempotence, furniture identity, crafting/sleep delegation and scoped anomaly filtering. They do not validate a running MO2 VFS, DLTX load order, engine animation or full quest progression.

Before publishing, review `git diff`, run all three suites with the relevant reference inputs, build the package, and verify the public file set. The intended stable tag is `v2.0.2`; creating it and publishing require the owner's approval. Keep the tested prerelease ZIPs locally for rollback.

The bridge suite checks WALO+SIN, WALO+UNISG and both together, both bootstrap orders, random-start exits, repeated loads, inactive modes, late wrappers, delegated errors and legacy saves with UNISG markers. Install the candidate as a fresh MO2 directory; remove old SIN controller providers from the active profile manually. Never overwrite the published 2.0.1 archive or tag.
