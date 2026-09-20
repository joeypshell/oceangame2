"""Check LE07 local review evidence; never accept a visual baseline."""

from __future__ import annotations

import hashlib
import json
import struct
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "visual_captures/living_expedition_07"
CHECKPOINTS = {
    "living_expedition_07_refuge": (
        "refuge_closed", "unadapted_ready", "refuge_digging", "refuge_retreat", "pending_return",
    ),
    "living_expedition_07_night": ("night_choice",),
    "living_expedition_07_pin": ("adapted_ready", "pin_held", "pin_released"),
}
SIZES = {"1280x720": (1280, 720), "mobile_844x390": (693, 390)}


def source_fingerprint() -> str:
    digest = hashlib.sha256()
    paths = [ROOT / "project.godot"]
    for folder, pattern in (("scripts", "*.gd"), ("scenes", "*.tscn"), ("maps", "*.json")):
        paths.extend((ROOT / folder).rglob(pattern))
    for path in sorted(paths):
        digest.update(path.relative_to(ROOT).as_posix().encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def check() -> None:
    run = json.loads((OUTPUT / "run.json").read_text())
    require(run["source_fingerprint"] == source_fingerprint(), "stale source evidence: regenerate")
    require(run["baseline_accepted"] is False, "unexpected baseline acceptance")
    captures = {}
    expected_files = set()
    for checkpoint, states in CHECKPOINTS.items():
        manifest = json.loads((OUTPUT / f"{checkpoint}.json").read_text())
        require(manifest.get("bounds_verified") is True, f"{checkpoint}: runtime bounds failed")
        require(manifest.get("baseline_accepted") is False, "baseline acceptance in checkpoint")
        expected = {f"{state}_{size}.png" for state in states for size in SIZES}
        require({row["file"] for row in manifest["captures"]} == expected, "incomplete checkpoint captures")
        require(len(manifest["captures"]) == len(expected), "duplicate capture record")
        expected_files.update(expected)
        for row in manifest["captures"]:
            name = row["file"]
            path = OUTPUT / name
            raw = path.read_bytes()
            require(raw[:8] == b"\x89PNG\r\n\x1a\n", f"{name}: invalid PNG")
            size_id = next(size for size in SIZES if name.endswith(f"_{size}.png"))
            require(tuple(row["size"]) == struct.unpack(">II", raw[16:24]) == SIZES[size_id], f"{name}: wrong dimensions")
            require(len(raw) > 4096, f"{name}: suspiciously small image")
            require(run["images"].get(name) == hashlib.sha256(raw).hexdigest(), f"{name}: image replaced after capture")
            require(row["checkpoint"] == checkpoint and row["individual_id"] == "silt_hound_juvenile_01", f"{name}: identity drift")
            require(row["map_id"] == "production_level_01" and row["main_scene"] == "res://scenes/main/Main.tscn", f"{name}: not actual Main")
            require(row["baseline_accepted"] is False, f"{name}: accepted baseline")
            require(row["logical_size"] == [1280, 720], f"{name}: logical coordinate contract changed")
            require(bool(row["hud_bounds"]), f"{name}: HUD bounds missing")
            if size_id.startswith("mobile"):
                require({"bond", "tool", "use"} <= row["hud_bounds"].keys(), f"{name}: touch controls absent")
            state = row["state"]
            if state == "night_choice":
                require("Root Claws" in row["night_text"] and bool(row["night_bounds"]), "missing night choice")
            else:
                require({"diver", "Marl", "eel", "refuge"} == row["subjects"].keys(), f"{name}: incomplete subjects")
                adapted = checkpoint.endswith("_pin")
                require(row["presentation"]["root_claws_visible"] == adapted, f"{name}: wrong fin silhouette")
                require(row["presentation"]["six_fin_count"] == 6, f"{name}: species drift")
                require(row["adaptation_id"] == ("root_claws" if adapted else ""), f"{name}: wrong adaptation")
                if state == "pin_held":
                    require(row["pin"]["state"] == "holding", "capture fabricated hold")
                if state == "pin_released":
                    require(row["presentation"]["release_visible"] and row["pin"]["cooldown_seconds"] > 0, "release absent")
                if state == "refuge_digging":
                    require(row["presentation"]["excavate_state"] == "digging", "dig absent")
                if state == "pending_return":
                    require(row["refuge"]["sheltered"] and "surface boat" in row["guidance"], "pending feedback absent")
            captures[(state, size_id)] = row
    require({p.name for p in OUTPUT.glob("*.png")} == expected_files, "unexpected/missing images")
    for size in SIZES:
        before, after = (captures[(state, size)] for state in ("unadapted_ready", "adapted_ready"))
        require(before["camera_position"] == after["camera_position"] and before["zoom"] == after["zoom"], "before/after framing changed")
    tracked = subprocess.check_output(["git", "ls-files", "--", "visual_captures/living_expedition_07"], cwd=ROOT)
    require(not tracked.strip(), "generated evidence is tracked")
    require(subprocess.run(["git", "check-ignore", "--quiet", str(OUTPUT / "run.json")], cwd=ROOT).returncode == 0, "output not ignored")
    print(f"PASS: LE07 {len(expected_files)} images, real Main, 3 isolated checkpoints, matched framing, desktop/mobile, source+image provenance, baseline_accepted=false")


if __name__ == "__main__":
    try:
        check()
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        raise SystemExit(f"FAIL: {error}") from error
