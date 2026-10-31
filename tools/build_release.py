"""Validate and package the allowlisted release source. Never publish or modify Git."""
import hashlib
import io
import json
import re
from pathlib import Path
from xml.etree import ElementTree
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = (
    "gamedata/configs/items/trade/trade_walo_greh_mine_trader.ltx",
    "gamedata/configs/misc/task/mod_task_manager_walo_sin_hq.ltx",
    "gamedata/configs/mod_system_walo_sin_hq_interior.ltx",
    "gamedata/configs/scripts/red_forest/smart/mod_red_smart_terrain_3_2_sin_hq_services.ltx",
    "gamedata/configs/scripts/red_forest/walo_sin_hq_services.ltx",
    "gamedata/configs/text/eng/walo_sin_hq_start.xml",
    "gamedata/configs/text/rus/walo_sin_hq_start.xml",
    "gamedata/scripts/warfare.script",
    "gamedata/scripts/zzzzz_walo_greh_mine_trade_spots.script",
    "gamedata/scripts/zzzzzz_walo_sin_hq_core.script",
    "gamedata/scripts/zzzzzz_walo_sin_hq_dao_guard.script",
    "gamedata/scripts/zzzzzz_walo_sin_hq_interior.script",
    "gamedata/scripts/zzzzzz_walo_sin_hq_interior_layout.script",
    "gamedata/scripts/zzzzzz_walo_sin_hq_services.script",
    "gamedata/scripts/zzzzzz_walo_sin_hq_toolkit_bridge.script",
)
DOCS = ("README.md", "CHANGELOG.md", "VERSION.json", "THIRD_PARTY_NOTICES.md")


def validate():
    actual = {p.relative_to(ROOT).as_posix() for p in (ROOT / "gamedata").rglob("*") if p.is_file()}
    if actual != set(RUNTIME):
        raise ValueError(f"Runtime allowlist mismatch: missing={set(RUNTIME)-actual}; extra={actual-set(RUNTIME)}")
    payload = {}
    for name in (*RUNTIME, *DOCS):
        p = ROOT / name
        if p.is_symlink():
            raise ValueError(f"Symlinks are not release inputs: {name}")
        payload[name] = p.read_bytes()
    meta = json.loads(payload["VERSION.json"])
    version = meta["version"]
    if not re.fullmatch(r"\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?", version):
        raise ValueError("Invalid release version")
    if meta.get("tag") != "v" + version:
        raise ValueError("Version and intended tag differ")
    localized = []
    for name in RUNTIME:
        data = payload[name]
        if name.endswith(".xml"):
            tree = ElementTree.fromstring(data)
            ids = [e.attrib["id"] for e in tree.iter("string")]
            if len(ids) != len(set(ids)):
                raise ValueError(f"Duplicate string IDs: {name}")
            localized.append(set(ids))
        elif name.endswith(".ltx"):
            section, sections, keys = None, set(), set()
            for raw in data.decode("utf-8-sig").splitlines():
                line = raw.split(";", 1)[0].strip()
                header = re.match(r"!?\[([^]]+)\]", line)
                if header:
                    section = header[1]
                    if section in sections:
                        raise ValueError(f"Duplicate section {section}: {name}")
                    sections.add(section)
                elif section and "=" in line:
                    key = (section, line.split("=", 1)[0].strip())
                    if key in keys:
                        raise ValueError(f"Duplicate key {key}: {name}")
                    keys.add(key)
        elif name.endswith(".script"):
            text = data.decode("utf-8-sig")
            for module in re.findall(r"\b(z{5,}_walo_[A-Za-z0-9_]+)(?=\.)", text):
                if f"gamedata/scripts/{module}.script" not in actual:
                    raise ValueError(f"Missing private script dependency {module}: {name}")
            if "[Sin HQ medic load]" in text or "[Sin HQ medic seat]" in text:
                raise ValueError(f"Temporary diagnostic output remains: {name}")
    if len(localized) != 2 or localized[0] != localized[1]:
        raise ValueError("English/Russian string IDs differ")
    expected = "1d54b521ca3b6971255dbe1e3bab36555c0aed61925433f5e2fbb2fd85c502a5"
    if hashlib.sha256(payload["gamedata/scripts/warfare.script"]).hexdigest() != expected:
        raise ValueError("Combined WALO/UNISG controller differs from audited integration")
    return meta, payload


def main():
    meta, payload = validate()
    manifest = "".join(f"{hashlib.sha256(data).hexdigest()}  {name}\n" for name, data in sorted(payload.items()))
    payload["RELEASE_FILES_SHA256.txt"] = manifest.encode("utf-8")
    buffer = io.BytesIO()
    with ZipFile(buffer, "w", ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(payload.items()):
            entry = ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            entry.compress_type = ZIP_DEFLATED
            archive.writestr(entry, data, compresslevel=9)
    content = buffer.getvalue()
    with ZipFile(io.BytesIO(content)) as archive:
        if set(archive.namelist()) != set(payload) or len(archive.infolist()) != len(payload) or archive.testzip():
            raise ValueError("Archive integrity/path verification failed")
        for name, data in payload.items():
            if archive.read(name) != data:
                raise ValueError(f"Archive/source mismatch: {name}")
    path = ROOT / "dist" / f"WALO_SIN_HQ_{meta['version']}_FULL_MO2.zip"
    if path.exists() and path.read_bytes() != content:
        raise FileExistsError(f"Different content already exists at this version: {path.name}")
    path.parent.mkdir(exist_ok=True)
    if not path.exists():
        with path.open("xb") as output:
            output.write(content)
    (ROOT / "RELEASE_FILES_SHA256.txt").write_bytes(payload["RELEASE_FILES_SHA256.txt"])
    digest = hashlib.sha256(content).hexdigest()
    path.with_suffix(path.suffix + ".sha256").write_text(f"{digest}  {path.name}\n", encoding="utf-8")
    print(f"PASS: {len(RUNTIME)} runtime files; XML/LTX/private dependencies; controller hash; {len(payload)} ZIP entries; CRC and source equality")
    print(path)
    print(f"SHA256: {digest}")


if __name__ == "__main__":
    main()
