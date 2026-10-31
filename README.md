# WALO SIN HQ 2.0.2

SIN HQ moves WALO's SIN headquarters into the old mine in the Red Forest (`red_smart_terrain_3_2`) and gives it a furnished, usable interior. It is built for S.T.A.L.K.E.R. Anomaly GAMMA with **WALO 1.6.11**; **UNISG Command & Operations v1.0.3 is optional**.

Stable 2.0.2 uses the same gameplay files as the tested 2.0.2-test.1 build. The author confirmed correct operation with WALO + SIN without UNISG, and with WALO + both HQ mods. Existing SIN HQ gameplay remains operational.

## What is included

- Trader and technician support through WALO's native service system, plus a seated medic and a bartender with dedicated work positions.
- A functional GAMMA crafting workbench, a furnished medical area and bar, and sleeping at the mine's existing mattress.
- A measured route around the medic's table and restoration of his sitting job after loading a save inside the HQ.
- SIN trade routing and PDA service markers, Dazhbog toolkit support, and a medical-kit task with English and Russian text.
- A bounded filter preventing new DAO dynamic anomalies from spawning in the occupied lower mine. Existing saved anomalies and stock anomaly fields are not removed.

WALO still controls squad spawning, population, ownership, capture and service replacement. SIN HQ uses its existing systems rather than spawning a parallel set of service squads. The surface SIN camp becomes a resource point while the mine is the HQ.

## Requirements

- S.T.A.L.K.E.R. Anomaly with GAMMA and its DLTX, workshop and task systems.
- **Warfare ALife Overhaul 1.6.11.**
- Optional: **UNISG Command & Operations v1.0.3**. It is not needed to use SIN HQ.

SIN no longer ships `warfare.script`. A private lifecycle bridge delegates to the controller supplied by WALO, or by UNISG when it is installed. It applies SIN classification before initial seeding and restores SIN after native load initialization. UNISG retains its own controller and native seeding without changes. Other WALO/UNISG versions and modpacks have not been established as compatible.

## Installation with Mod Organizer 2

1. Back up your saves. Keep the previous working package for rollback.
2. Install `WALO_SIN_HQ_2.0.2_FULL_MO2.zip` through MO2. The archive has `gamedata/` directly at its root.
3. Disable older SIN HQ packages, including v1.3, development builds, position patches and diagnostic patches. Enable only this full SIN HQ package.
4. Keep WALO 1.6.11 enabled. If using UNISG v1.0.3, keep its normal priority over WALO so its own `warfare.script` wins. SIN has no competing controller file. Its relative priority against UNISG does not select the controller; UNISG must still win that file against WALO.
5. For the additional HQ mechanics, use **Warfare ON and Story Mode OFF**. Restart the game after replacing a package, then load a copy of your save or start a new game.

Install this version into a **fresh MO2 mod directory** and disable the entire previous SIN package. Do not merge/extract over v2.0.1: its obsolete `warfare.script` could remain and defeat the separation.

No manual GAMMA or squad spawn edits are needed. SIN save identifiers, furniture identities and NPC jobs are unchanged; no save migration or object deletion is performed. Back up saves before upgrading. No new game is required when updating from 2.0.2-test.1, whose gameplay files are identical. A save made with the old combined controller can already contain UNISG NPCs or its opt-in marker even if the separate UNISG package was absent. Those saved objects/flags are not automatically removed. Older v1.3 saves are not automatically migrated.

## Warfare, Story Mode and DRX

The added HQ mechanics are enabled only with **Warfare ON / Story Mode OFF**. The existing Core mode check handles both new-game settings and ordinary save loading. The HQ changes are not limited to a SIN player character; the toolkit bridge retains its existing SIN actor restriction.

With Story Mode enabled, or Warfare disabled, the addon does not activate its HQ relocation, furnishing, custom service jobs, trade routing, toolkit bridge or new PDA markers. It does not replace the original SIN Story/Mortal Sin characters, dialogue or quest chains. DRX storyline definitions are not modified. The addon's own medical-kit task is mode-gated; if an older save contains a pending copy in an unsupported mode, normal task handling ends that addon task as failed.

This isolation is checked in source and mocked Lua scenarios. The author's final gameplay confirmation covers the HQ, services, furniture, crafting, sleeping, navigation, level transitions and save/load. A complete Story Mode or SIN DRX storyline playthrough is **not claimed** by this release.

## Compatibility and saved games

- SIN no longer replaces `warfare.script`. Its bridge is verified against WALO 1.6.11 and the UNISG v1.0.3 controller. Other controller replacements or later wrappers need their own compatibility check.
- Science Bunker Trade Inheritance v1.4 remains an optional separate companion. SIN's private trader profile does not replace global GAMMA trader files.
- Core recognizes the audited ReDone North squad-target signature and disables HQ changes for that case. This is not a compatibility guarantee for every ReDone North version or every inherited module; do not assume the combination is supported.
- Furniture and other spawned objects can persist in saves. Removing the mod does not remove its saved objects or roll back older NPCs, toolkit flags or serialized PDA markers. Keep a pre-installation save.
- The crafting bench uses the installed GAMMA workshop and its tool rules. Giving tools to Dazhbog does not automatically supply tools to the bench.

## Source, credits and validation

The installable source is under `gamedata/`. SIN integrates with the WALO lifecycle without bundling UNISG implementation or a full controller override. Credit belongs to the WALO, UNISG, Anomaly, GAMMA and companion-mod contributors for their respective work. See [third-party notices](THIRD_PARTY_NOTICES.md).

See [CHANGELOG.md](CHANGELOG.md) for this release and [DEVELOPMENT.md](DEVELOPMENT.md) for the packaging command and verification limits. Maintainer tests are kept out of the MO2 archive. Local references, logs, saves and historical test packages are not part of the public source tree or release asset.

## Independent-installation validation

Integration regression checks run the audited WALO and UNISG startup, load and initial-fill functions with mocked engine APIs. Gameplay confirmation below was supplied by the author on 2.0.2-test.1:

| Configuration | Controller provider | Gameplay status of this integration change |
|---|---|---|
| WALO + SIN | WALO 1.6.11 | Confirmed in game by the author |
| WALO + UNISG | UNISG v1.0.3; no SIN loaded | Existing external mod unchanged; no new gameplay test claimed |
| WALO + both | UNISG v1.0.3 + SIN bridge | Confirmed in game by the author |

The regression suite covers fresh starts, ordinary and repeated loads, random-start exits, population changes, startup order and inactive modes. With both HQs it checks native UNISG seeding and restoration without duplicate squads alongside SIN. These code checks do not establish full Story/DRX playthrough coverage, which is not claimed.
