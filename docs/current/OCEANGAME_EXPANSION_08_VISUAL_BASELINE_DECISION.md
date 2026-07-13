# OceanGame Expansion 08 Visual Baseline Decision

Date: 2026-07-13

Issue: #842 `Capture and technically review the Expansion 08 bloom`

## Decision

**Technical GO** for the focused daily-condition presentation. Do not replace any accepted production-slice baseline in this issue.

The `--capture-expansion-08-daily-condition` command rendered and verified two states at 1280x720 and 1920x1080:

- day-one night debrief forecasting `Tomorrow: Southwest jellyfish bloom`
- day-two southwest pocket with the active migration patrol, uncollected bonus coil, diver, and compact condition line

The four PNGs under `visual_captures/expansion_08_daily_condition/` were local review evidence and remain uncommitted. No baseline `accept` command ran.

## Intentional Differences

- The debrief adds one forecast immediately before `N: Start day 2`; it wraps without clipping at 1280x720 and remains compact at 1920x1080.
- The bloom frame adds the condition line, one jellyfish patrol, and one green conductive-coil crate in the existing southwest pocket.
- The diver, patrol lane, and bonus material remain visible together at both viewports. The capture setup leaves the material uncollected.
- No blank region, overlapping UI, cropped subject, or terrain artifact appears in the focused captures.

This is a technical rendering decision. Automation and image review do not prove that a player understands the forecast, values the opportunity, or wants to plan another day.

## Baseline Result

`compare-all` rendered all four standard production-slice review sheets. Direct pixel comparison reported 21/21 configured current captures exactly matching their accepted baselines:

- slice 01: 6/6
- slice 02: 5/5
- slice 03: 5/5
- slice 04: 5/5

Accepted directories passed `check-clean --all-slices`. Generated comparison sheets, focused captures, and `.import` sidecars are not part of this commit.

## Stable Areas

- terrain topology, collision, tiles, camera tests, and route geometry
- diver, boat, standard salvage, survey, eel, current, and unrelated hazard presentation
- standard HUD framing outside the focused condition and forecast lines
- all accepted production-slice baselines

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 40 --capture-expansion-08-daily-condition
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Exact-SHA public Web verification and technical milestone closeout remain scoped to #843.
