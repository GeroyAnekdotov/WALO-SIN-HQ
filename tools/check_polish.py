"""Lua 5.1 checks for SIN's service jobs and bounded DAO creation filter.

Does not run X-Ray or write to the game. --dao-script optionally exercises the
installed DAO caller/creator read-only; it must be the version audited here.
"""
import argparse
import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "_reference/python-test-deps"))
from lupa.lua51 import LuaRuntime  # noqa: E402


def sections(path):
    result, current = {}, None
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.split(";", 1)[0].strip().lstrip("!")
        if line.startswith("["):
            current = line[1:line.index("]")]
            result[current] = {}
        elif "=" in line and current:
            key, value = line.split("=", 1)
            result[current][key.strip()] = value.strip()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dao-script", type=Path)
    parser.add_argument("--beh-script", type=Path,
                        help="Optional read-only audited GAMMA axr_beh.script for native waypoint parsing")
    args = parser.parse_args()
    lua = LuaRuntime(unpack_returned_tuples=True)
    compile_lua = lua.eval("function(s,n) local f,e=loadstring(s,n); assert(f,e) end")
    sources = {}
    for key, filename in {
        "core": "zzzzzz_walo_sin_hq_core.script",
        "layout": "zzzzzz_walo_sin_hq_interior_layout.script",
        "guard": "zzzzzz_walo_sin_hq_dao_guard.script",
        "services": "zzzzzz_walo_sin_hq_services.script",
    }.items():
        sources[key] = (ROOT / "gamedata/scripts" / filename).read_text(encoding="utf-8")
        compile_lua(sources[key], "@" + filename)
        print("SYNTAX PASS:", filename, flush=True)
    reference = ROOT.parent / "_shared_reference/upstream/Anomaly_unpacked/scripts/xr_logic.script"
    sources["logic"] = reference.read_text(encoding="cp1251")
    start = re.search(r"^function initialize_obj\(", sources["logic"], re.M).start()
    stop = re.search(r"^function ", sources["logic"][start + 1:], re.M)
    sources["logic_initialize"] = sources["logic"][start:start + 1 + stop.start()]
    smart = (reference.parent / "smart_terrain.script").read_text(encoding="cp1251")
    start = re.search(r"^function setup_gulag_and_logic_on_spawn\(", smart, re.M).start()
    stop = re.search(r"^function ", smart[start + 1:], re.M)
    sources["smart_initialize"] = smart[start:start + 1 + stop.start()]
    jobs = sections(ROOT / "gamedata/configs/scripts/red_forest/walo_sin_hq_services.ltx")
    sources["jobs"] = lua.table_from({k: lua.table_from(v) for k, v in jobs.items()})
    patch = sections(ROOT / "gamedata/configs/scripts/red_forest/smart/mod_red_smart_terrain_3_2_sin_hq_services.ltx")
    assert set(patch) == {"exclusive"}
    assert patch["exclusive"] == {key: r"red_forest\walo_sin_hq_services.ltx"
                                  for key in ("walo_sin_hq_medic", "walo_sin_hq_barman")}
    print("STATIC PASS: additive DLTX patch contains only two private exclusive keys", flush=True)
    if args.dao_script:
        content = args.dao_script.read_bytes()
        expected = "8391acc8416fa58b70eb1727369ebe4202ca5636251dc4e37664b2fd9163da8c"
        # A hash mismatch requires source review, never silently use another DAO.
        actual = hashlib.sha256(content).hexdigest()
        if actual != expected:
            raise ValueError(f"DAO differs from audited source: {actual}")
        text = content.decode("utf-8-sig")
        for key, name in {"dao_caller": "drx_da_spawn_anomaly_on_smart",
                          "dao_creator": "drx_da_spawn_anomaly"}.items():
            start = re.search(r"^function " + name + r"\(", text, re.M).start()
            stop = re.search(r"^function ", text[start + 1:], re.M)
            sources[key] = text[start:start + 1 + stop.start()] if stop else text[start:]
            compile_lua(sources[key], "@audited_DAO_" + name)
        print("INTEGRITY PASS: optional DAO input matches the audited installed source", flush=True)
    if args.beh_script:
        content = args.beh_script.read_bytes()
        expected = "0fc7882daa037516626b4f07fb3a98d9a936546c1ca7abdff9ea1e9c1c99266f"
        actual = hashlib.sha256(content).hexdigest()
        if actual != expected:
            raise ValueError(f"beh differs from audited source: {actual}")
        try:
            text = content.decode("utf-8-sig")
        except UnicodeDecodeError:
            text = content.decode("cp1251")
        route = []
        for name in ("get_current_waypoint", "set_desired_target", "beh_path",
                     "next_waypoint_index", "increment_waypoint_index", "finalize"):
            start = re.search(r"^function action_beh:" + name + r"\(", text, re.M).start()
            stop = re.search(r"^function ", text[start + 1:], re.M)
            function = text[start:start + 1 + stop.start()] if stop else text[start:]
            compile_lua(function, "@audited_axr_beh_" + name)
            route.append(function)
            if name == "get_current_waypoint":
                sources["beh_waypoint"] = function
        sources["beh_route"] = "\n".join(route)
        print("INTEGRITY PASS: optional beh input matches the audited installed source", flush=True)
    lua.globals().sources = lua.table_from(sources)
    passed = lua.execute((ROOT / "tests/polish_spec.lua").read_text(encoding="utf-8"))
    print(f"PASS: {passed} polishing scenario groups (mocked engine; no in-game validation).", flush=True)


if __name__ == "__main__":
    main()
