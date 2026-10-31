"""Run the three independent HQ combinations with audited controller functions.

The engine APIs are mocked. No game, MO2/profile changes or external writes.
"""
import argparse
import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "_reference/python-test-deps"))
from lupa.lua51 import LuaRuntime


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--walo", type=Path, default=ROOT.parent / "_shared_reference/upstream/WALO_1.6.11/src/gamedata/scripts/warfare.script")
    parser.add_argument("--unisg", type=Path, required=True, help="Read-only UNISG v1.0.3 warfare.script")
    args = parser.parse_args()
    lua = LuaRuntime(unpack_returned_tuples=True)
    compile_lua = lua.eval("function(s) local f,e=loadstring(s); assert(f,e) end")
    sources = {}
    for key, path, expected in (
        ("walo", args.walo, "535053db40f6b926f22f7a7946c0d23ab0a9c80da3ff7acc1855e7deb55fb70c"),
        ("unisg", args.unisg, "83e3c20480c5fb0c1c29543cd3dbcf517fb4e4df7785db56ecf922d5b4c877ba"),
    ):
        data = path.read_bytes()
        if hashlib.sha256(data).hexdigest() != expected:
            raise ValueError(f"{key} controller differs from audited source")
        text = data.decode("utf-8-sig")
        chunks = []
        if key == "unisg":
            # Keep the actual local HQ functions and their upvalues in one chunk.
            start = text.index('local UNISG_HQ_SMART =')
            end = text.index('function actor_on_first_update()', start)
            chunks.append(text[start:end])
        for name in ("actor_on_first_update", "fill_start_position", "on_game_start"):
            start = re.search(r"^function " + name + r"\(", text, re.M).start()
            stop = re.search(r"^function ", text[start+1:], re.M)
            chunks.append(text[start:start+1+stop.start()])
        sources[key] = "\n".join(chunks)
        compile_lua(sources[key])
        print(f"INTEGRITY PASS: {key}; actual startup/load/fill functions and UNISG HQ locals")
    for key, name in (("core", "zzzzzz_walo_sin_hq_core.script"), ("bridge", "zzzzzzz_walo_sin_hq_warfare_bridge.script")):
        sources[key] = (ROOT / "gamedata/scripts" / name).read_text()
        compile_lua(sources[key])
    if (ROOT / "gamedata/scripts/warfare.script").exists():
        raise ValueError("SIN must not ship a controller override")
    lua.globals().sources = lua.table_from(sources)
    count = lua.execute((ROOT / "tests/warfare_bridge_spec.lua").read_text())
    print(f"PASS: {count} integration groups; actual controllers with mocked engine APIs; no in-game validation.")


if __name__ == "__main__":
    main()
