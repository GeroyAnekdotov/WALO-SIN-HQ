"""Run Lua 5.1 checks with mocked engine APIs; never launch or modify the game.

Requires Lupa with its lua51 backend. Test dependencies can be kept in ignored
_reference/python-test-deps; none belong in the installable gamedata payload.
"""

import argparse
import hashlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "_reference" / "python-test-deps"))
from lupa.lua51 import LuaRuntime  # noqa: E402


def read_task(path):
    return {
        key.strip(): value.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if "=" in line and not line.lstrip().startswith(";")
        for key, value in [line.split("=", 1)]
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--reference-scripts", type=Path,
        default=ROOT.parent / "_shared_reference/upstream/Anomaly_unpacked/scripts",
        help="Read-only preserved Anomaly scripts (xr_logic.script is required).",
    )
    parser.add_argument(
        "--baseline-root", type=Path,
        help="Optional unchanged test package root for Warfare comparison probes.",
    )
    args = parser.parse_args()
    runtime = LuaRuntime(unpack_returned_tuples=True)
    compile_lua = runtime.eval(
        "function(s,n) local f,e=loadstring(s,n); assert(f,e); return true end"
    )
    sources = {}
    for key, filename in {
        "core": "zzzzzz_walo_sin_hq_core.script",
        "trade": "zzzzz_walo_greh_mine_trade_spots.script",
        "toolkit": "zzzzzz_walo_sin_hq_toolkit_bridge.script",
    }.items():
        path = ROOT / "gamedata/scripts" / filename
        sources[key] = path.read_text(encoding="utf-8")
        compile_lua(sources[key], "@" + filename)
        print("SYNTAX PASS:", filename)

    assert not (ROOT / "gamedata/scripts/warfare.script").exists()
    compile_lua((ROOT / "gamedata/scripts/zzzzzzz_walo_sin_hq_warfare_bridge.script").read_text(),
                "@zzzzzzz_walo_sin_hq_warfare_bridge.script")
    print("INTEGRITY PASS: independent lifecycle bridge; no controller override")

    sources["logic"] = (args.reference_scripts / "xr_logic.script").read_text(encoding="cp1251")
    sources["task"] = runtime.table_from(read_task(
        ROOT / "gamedata/configs/misc/task/mod_task_manager_walo_sin_hq.ltx"
    ))
    if args.baseline_root:
        for line in (ROOT / "tests/import_baseline_sha256.txt").read_text().splitlines():
            digest, relative = line.split(maxsplit=1)
            path = args.baseline_root / relative.strip()
            if hashlib.sha256(path.read_bytes()).hexdigest() != digest:
                raise ValueError(f"Comparison source does not match the imported baseline: {relative}")
        print("INTEGRITY PASS: all eight comparison inputs match the imported baseline")
        baseline = {}
        for key in ("core", "trade", "toolkit"):
            name = {"core": "zzzzzz_walo_sin_hq_core.script",
                    "trade": "zzzzz_walo_greh_mine_trade_spots.script",
                    "toolkit": "zzzzzz_walo_sin_hq_toolkit_bridge.script"}[key]
            baseline[key] = (args.baseline_root / "gamedata/scripts" / name).read_text(encoding="utf-8")
        baseline["task"] = runtime.table_from(read_task(
            args.baseline_root / "gamedata/configs/misc/task/mod_task_manager_walo_sin_hq.ltx"
        ))
        sources["baseline"] = runtime.table_from(baseline)
    runtime.globals().sources = runtime.table_from(sources)
    passed = runtime.execute((ROOT / "tests/story_mode_spec.lua").read_text(encoding="utf-8"))
    print(f"PASS: {passed} scenario groups; engine APIs were mocked, no in-game tests.")


if __name__ == "__main__":
    main()
