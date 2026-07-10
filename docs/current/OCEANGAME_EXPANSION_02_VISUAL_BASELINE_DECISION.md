# OceanGame Expansion 02 Visual Baseline Decision

Date: 2026-07-09

Issue: #693 `Add focused Expedition Day review captures and visual decision`

## Decision

Do not replace any accepted production-slice baseline for Expansion 02.

Approve the compact daylight line, open-surface context, boat end-day action, and night debrief only as intentional presentation in the dedicated review captures:

- `visual_captures/expedition_day/production_slice_01_day_surface_refill.png`
- `visual_captures/expedition_day/production_slice_01_day_boat_offload.png`
- `visual_captures/expedition_day/production_slice_01_night_debrief.png`

These generated files are local review evidence and remain uncommitted. No baseline `accept` command ran.

## Review Evidence

The surface frame keeps `00:58 DUSK`, `Dive 1`, `Surface O2`, held cargo, and oxygen together without overlap. The boat frame changes only the intended context: cargo is banked and `Boat N End` becomes available. The debrief replaces the active HUD with one compact summary of dives, banked cargo/value, discoveries, and the next-day action.

All three states were rendered and inspected at 1280x720 and 1920x1080. Text stays inside its panel at both sizes, the boat remains visible, and the world framing remains coherent.

An initial debrief capture exposed black out-of-bounds camera regions. That review artifact was rejected and fixed by using an explicit in-bounds debrief camera position; it was not retained or accepted.

## Stable Areas

`compare-all` reports every accepted/current production-slice pair clean:

- `production_slice_01`: clean
- `production_slice_02`: clean
- `production_slice_03`: clean
- `production_slice_04`: clean

Terrain, collision, diver, boat, relay, props, connectors, anomaly presentation, source-authored camera tests, and all accepted baseline directories remain unchanged.

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-expedition-day
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --resolution 1920x1080 --quit-after 20 --capture-expedition-day
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Public Web verification remains scoped to #694.
