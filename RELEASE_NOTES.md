# WALO SIN HQ 2.0.2 — Independent release

SIN HQ works with **WALO 1.6.11 without UNISG installed**. UNISG Command & Operations v1.0.3 is an optional independent addition.

The author successfully tested WALO + SIN alone and WALO + both HQ mods on 2.0.2-test.1. Existing SIN HQ gameplay remains operational. Stable 2.0.2 contains exactly the same gameplay files; this promotion changes documentation and release metadata only.

## Install and upgrade

Install `WALO_SIN_HQ_2.0.2_FULL_MO2.zip` through MO2 and disable previous SIN packages. For an upgrade from 2.0.1, use a fresh mod directory: merging over the old package could leave its obsolete combined `warfare.script` behind.

Keep WALO enabled. When using both HQ mods, UNISG's own `warfare.script` must win against WALO. SIN ships no controller override, so its relative priority against UNISG does not choose that file. No new game is required when upgrading from 2.0.2-test.1. Back up saves before updating.

SIN's added mechanics require Warfare ON / Story Mode OFF. NPC jobs, furnishing, navigation, save identifiers and Story Mode protections are unchanged. Existing objects or UNISG markers from older combined-controller saves are not deleted or migrated. Complete Story Mode/DRX playthrough coverage is not claimed.

Targeted integration regression checks use audited native WALO/UNISG functions with mocked engine APIs. The installable ZIP is checked for required files, correct root paths, archive integrity, source equality and absence of `gamedata/scripts/warfare.script`.

Assets: `WALO_SIN_HQ_2.0.2_FULL_MO2.zip` and its `.sha256` sidecar. The published 2.0.1 release and tag are unchanged. Nothing is committed, tagged, pushed or published by the local build command.
