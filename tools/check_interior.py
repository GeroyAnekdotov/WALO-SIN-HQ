"""Lua 5.1 tests for the first furnishing pass; no X-Ray game is launched."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "_reference/python-test-deps"))
from lupa.lua51 import LuaRuntime  # noqa: E402

runtime = LuaRuntime(unpack_returned_tuples=True)
sources = {}
for name, filename in {
    "core": "zzzzzz_walo_sin_hq_core.script",
    "layout": "zzzzzz_walo_sin_hq_interior_layout.script",
    "interior": "zzzzzz_walo_sin_hq_interior.script",
}.items():
    text = (ROOT / "gamedata/scripts" / filename).read_text(encoding="utf-8")
    runtime.eval("function(s,n) local f,e=loadstring(s,n); assert(f,e) end")(text, "@" + filename)
    print("SYNTAX PASS:", filename, flush=True)
    sources[name] = text
runtime.globals().sources = runtime.table_from(sources)
passed = runtime.execute((ROOT / "tests/interior_spec.lua").read_text(encoding="utf-8"))
print(f"PASS: {passed} interior scenario groups (mocked APIs; no in-game validation).", flush=True)
