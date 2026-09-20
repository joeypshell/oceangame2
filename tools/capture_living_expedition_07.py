"""Render only Marl's LE07 review states through actual Main and normal commands."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess

from check_living_expedition_07_captures import CHECKPOINTS, OUTPUT, ROOT, check, source_fingerprint


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=shutil.which("godot") or shutil.which("godot4"))
    args = parser.parse_args()
    if not args.godot:
        parser.error("provide --godot with the local console executable")
    fingerprint = source_fingerprint()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    # A failed attempt must not reuse an older successful run's provenance.
    (OUTPUT / "run.json").unlink(missing_ok=True)
    for checkpoint in CHECKPOINTS:
        command = [args.godot, "--path", str(ROOT), "--fixed-fps", "60", "--script",
                   "res://scripts/main/captures/living_expedition_07_capture_runner.gd", "--",
                   f"--review-checkpoint={checkpoint}", "--show-mobile-controls"]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=120)
        output = result.stdout + result.stderr
        print(output)
        if result.returncode or "SCRIPT ERROR" in output or "ERROR:" in output:
            raise SystemExit(f"FAIL: capture {checkpoint}")
    if source_fingerprint() != fingerprint:
        raise SystemExit("FAIL: source changed while capturing")
    run = {
        "source_fingerprint": fingerprint,
        "head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "baseline_accepted": False,
        "images": {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUTPUT.glob("*.png"))},
    }
    (OUTPUT / "run.json").write_text(json.dumps(run, indent=2) + "\n", encoding="utf-8")
    check()


if __name__ == "__main__":
    main()
