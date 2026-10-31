# WALO SIN HQ 2.0.1

SIN HQ moves WALO's SIN headquarters into the old mine in the Red Forest (`red_smart_terrain_3_2`) and gives it a furnished, usable interior. It is built for S.T.A.L.K.E.R. Anomaly GAMMA with **WALO 1.6.11** and **UNISG Command & Operations v1.0.3**.

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
- **UNISG Command & Operations v1.0.3**, enabled as a separate mod.

The package includes a combined `warfare.script` for these specific WALO and UNISG versions. It is not a standalone replacement for another WALO version. The UNISG menu and other UNISG files come from the separate UNISG mod. Other versions and modpacks have not been established as compatible.

## Installation with Mod Organizer 2

1. Back up your saves. Keep the previous working package for rollback.
2. Install `WALO_SIN_HQ_2.0.1_FULL_MO2.zip` through MO2. The archive has `gamedata/` directly at its root.
3. Disable older SIN HQ packages, including v1.3, development builds, position patches and diagnostic patches. Enable only this full SIN HQ package.
4. Keep WALO 1.6.11 and UNISG Command & Operations v1.0.3 enabled. Give SIN HQ higher file priority than both, so its combined `warfare.script` wins.
5. For the additional HQ mechanics, use **Warfare ON and Story Mode OFF**. Restart the game after replacing a package, then load a copy of your save or start a new game.

No manual changes to GAMMA files, MO2 profiles or squad spawn points are needed. Updating from the tested `2.0.1-test.2` build does not require a new game. Older v1.3 saves are not automatically migrated.

## Warfare, Story Mode and DRX

The added HQ mechanics are enabled only with **Warfare ON / Story Mode OFF**. The existing Core mode check handles both new-game settings and ordinary save loading. The HQ changes are not limited to a SIN player character; the toolkit bridge retains its existing SIN actor restriction.

With Story Mode enabled, or Warfare disabled, the addon does not activate its HQ relocation, furnishing, custom service jobs, trade routing, toolkit bridge or new PDA markers. It does not replace the original SIN Story/Mortal Sin characters, dialogue or quest chains. DRX storyline definitions are not modified. The addon's own medical-kit task is mode-gated; if an older save contains a pending copy in an unsupported mode, normal task handling ends that addon task as failed.

This isolation is checked in source and mocked Lua scenarios. The author's final gameplay confirmation covers the HQ, services, furniture, crafting, sleeping, navigation, level transitions and save/load. A complete Story Mode or SIN DRX storyline playthrough is **not claimed** by this release.

## Compatibility and saved games

- Other mods overriding `warfare.script` require a deliberate merge. Changing MO2 priority cannot combine two different controllers.
- Science Bunker Trade Inheritance v1.4 remains an optional separate companion. SIN's private trader profile does not replace global GAMMA trader files.
- Core recognizes the audited ReDone North squad-target signature and disables HQ changes for that case. This is not a compatibility guarantee for every ReDone North version or every inherited module; do not assume the combination is supported.
- Furniture and other spawned objects can persist in saves. Removing the mod does not remove its saved objects or roll back older NPCs, toolkit flags or serialized PDA markers. Keep a pre-installation save.
- The crafting bench uses the installed GAMMA workshop and its tool rules. Giving tools to Dazhbog does not automatically supply tools to the bench.

## Source, credits and validation

The installable source is under `gamedata/`. The combined controller preserves the WALO/UNISG integration; the SIN lifecycle calls are additive. Credit belongs to the WALO, UNISG, Anomaly, GAMMA and companion-mod contributors for their respective work. See [third-party notices](THIRD_PARTY_NOTICES.md).

See [CHANGELOG.md](CHANGELOG.md) for this release and [DEVELOPMENT.md](DEVELOPMENT.md) for the packaging command and verification limits. Maintainer tests are kept out of the MO2 archive. Local references, logs, saves and historical test packages are not part of the public source tree or release asset.
